import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/data/drift_review_state_repository.dart';

/// Confirms the invariant docs/DATA_MODEL.md states explicitly: favouriting,
/// spaced-review confidence, and "mark as reviewed" never touch mastery
/// evidence or unit-progress state — they only ever write to
/// `vocabulary_review_state`/`grammar_review_state`.
void main() {
  late AppDatabase db;
  late DriftReviewStateRepository repo;
  late int learnerId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftReviewStateRepository(db);
    learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: 'learner-1',
            createdAt: DateTime.utc(2026, 9, 2),
          ),
        );
  });

  tearDown(() => db.close());

  test(
    'favouriting a word never writes to activity_attempts or unit_progress',
    () async {
      await repo.setVocabularyFavorite(
        learnerId: learnerId,
        lexiconId: 'A1.LEX.HELLO.INTJ',
        isFavorite: true,
      );

      expect(await db.select(db.activityAttempts).get(), isEmpty);
      expect(await db.select(db.unitProgress).get(), isEmpty);
    },
  );

  test('recording a spaced-review outcome never writes to activity_attempts '
      'or unit_progress', () async {
    await repo.upsertVocabularyReviewOutcome(
      learnerId: learnerId,
      lexiconId: 'A1.LEX.HELLO.INTJ',
      easeFactor: 2.5,
      intervalDays: 1,
      repetitions: 1,
      dueAt: DateTime.utc(2026, 9, 3),
      confidenceMarker: 'good',
    );

    expect(await db.select(db.activityAttempts).get(), isEmpty);
    expect(await db.select(db.unitProgress).get(), isEmpty);
  });

  test('marking a grammar item reviewed never writes to activity_attempts or '
      'unit_progress, and never touches vocabulary_review_state', () async {
    await repo.markGrammarReviewed(
      learnerId: learnerId,
      grammarId: 'A1.G.BE.I_AM',
    );

    expect(await db.select(db.activityAttempts).get(), isEmpty);
    expect(await db.select(db.unitProgress).get(), isEmpty);
    expect(await db.select(db.vocabularyReviewState).get(), isEmpty);

    final grammarState = await repo.grammarState(
      learnerId: learnerId,
      grammarId: 'A1.G.BE.I_AM',
    );
    expect(grammarState?.markedReviewedAt, isNotNull);
  });

  test(
    'favouriting grammar never writes to activity_attempts or unit_progress',
    () async {
      await repo.setGrammarFavorite(
        learnerId: learnerId,
        grammarId: 'A1.G.BE.I_AM',
        isFavorite: true,
      );

      expect(await db.select(db.activityAttempts).get(), isEmpty);
      expect(await db.select(db.unitProgress).get(), isEmpty);
    },
  );
}
