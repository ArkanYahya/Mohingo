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

  group('enrollVocabulary', () {
    final due = DateTime(2026, 9, 20);

    test('adds each new word and phrase to review, not yet recalled, due at '
        'the given time', () async {
      await repo.enrollVocabulary(
        learnerId: learnerId,
        lexiconIds: const ['A1.LEX.NAME.N01'],
        chunkIds: const ['A1.CHUNK.MY_NAME_IS'],
        dueAt: due,
      );

      final rows = await repo.allVocabularyState(learnerId: learnerId);
      expect(rows, hasLength(2));
      for (final row in rows) {
        expect(row.dueAt, due);
        expect(row.repetitions, 0);
        expect(row.isFavorite, isFalse);
      }
    });

    test('schedules a word that was only saved as a favourite, keeping the '
        'star', () async {
      await repo.setVocabularyFavorite(
        learnerId: learnerId,
        lexiconId: 'A1.LEX.NAME.N01',
        isFavorite: true,
      );

      await repo.enrollVocabulary(
        learnerId: learnerId,
        lexiconIds: const ['A1.LEX.NAME.N01'],
        chunkIds: const [],
        dueAt: due,
      );

      final row = await repo.vocabularyState(
        learnerId: learnerId,
        lexiconId: 'A1.LEX.NAME.N01',
      );
      expect(row!.dueAt, due);
      expect(row.isFavorite, isTrue);
    });

    test('never touches a word already in review — replaying a lesson '
        "doesn't reset its schedule", () async {
      final later = DateTime(2026, 10, 1);
      await repo.upsertVocabularyReviewOutcome(
        learnerId: learnerId,
        lexiconId: 'A1.LEX.NAME.N01',
        easeFactor: 2.6,
        intervalDays: 6,
        repetitions: 2,
        dueAt: later,
        confidenceMarker: 'good',
      );

      await repo.enrollVocabulary(
        learnerId: learnerId,
        lexiconIds: const ['A1.LEX.NAME.N01'],
        chunkIds: const [],
        dueAt: due,
      );

      final row = await repo.vocabularyState(
        learnerId: learnerId,
        lexiconId: 'A1.LEX.NAME.N01',
      );
      expect(row!.dueAt, later);
      expect(row.repetitions, 2);
    });
  });
}
