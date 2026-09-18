import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:mohingo/features/progress/providers/current_learner_provider.dart';
import 'package:mohingo/features/progress/providers/progress_providers.dart';

import 'review_test_harness.dart';

final _lex = reviewTestIndex.bundle.lexicon;
final _chunks = reviewTestIndex.bundle.chunks;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final now = DateTime.now();

  // Oldest due first: the word, then the phrase.
  Future<void> seedTwo(db, int id) async {
    await seedVocabulary(
      db,
      id,
      lexiconId: _lex[6].id,
      repetitions: 1,
      intervalDays: 1,
      dueAt: now.subtract(const Duration(days: 2)),
    );
    await seedVocabulary(
      db,
      id,
      chunkId: _chunks.first.id,
      dueAt: now.subtract(const Duration(hours: 1)),
    );
  }

  testWidgets('a card shows the word first; Show answer reveals its '
      'meaning, an example, and the three ratings with when each brings it '
      'back', (tester) async {
    final (_, _, l10n) = await pumpReview(
      tester,
      start: '/review/session',
      seed: seedTwo,
    );
    final word = _lex[6];

    expect(find.text(l10n.reviewSessionProgress(1, 2)), findsOneWidget);
    expect(find.text(word.headword), findsOneWidget);
    expect(find.text(l10n.reviewSessionWord.toUpperCase()), findsOneWidget);
    expect(find.text(word.arabic), findsNothing);
    expect(find.text(l10n.reviewQualityGood), findsNothing);

    await tester.tap(find.text(l10n.reviewShowAnswer));
    await tester.pumpAndSettle();

    expect(find.text(word.arabic), findsOneWidget);
    expect(find.text(word.examples.first), findsOneWidget);
    expect(find.text(l10n.reviewQualityAgain), findsOneWidget);
    // One repetition so far: Again brings it back tomorrow, Good in 6 days.
    expect(find.text(l10n.reviewSeeAgain(1)), findsOneWidget);
    expect(find.text(l10n.reviewSeeAgain(6)), findsWidgets);
  });

  testWidgets('rating a card saves it to the review schedule and moves on '
      'to the next', (tester) async {
    final (container, _, l10n) = await pumpReview(
      tester,
      start: '/review/session',
      seed: seedTwo,
    );

    await tester.tap(find.text(l10n.reviewShowAnswer));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.reviewQualityGood));
    await tester.pumpAndSettle();

    final learner = await container.read(currentLearnerProvider.future);
    final state = await container
        .read(reviewStateRepositoryProvider)
        .vocabularyState(learnerId: learner.id, lexiconId: _lex[6].id);
    expect(state!.repetitions, 2);
    expect(state.dueAt!.isAfter(DateTime.now()), isTrue);

    expect(find.text(l10n.reviewSessionProgress(2, 2)), findsOneWidget);
    expect(find.text(_chunks.first.text), findsOneWidget);
    expect(find.text(l10n.reviewSessionPhrase.toUpperCase()), findsOneWidget);
  });

  testWidgets('after the last card it sums up the session, and Done closes '
      'it', (tester) async {
    final (_, _, l10n) = await pumpReview(tester, seed: seedTwo);

    await tester.tap(find.text(l10n.reviewStartCta));
    await tester.pumpAndSettle();
    for (final quality in [l10n.reviewQualityEasy, l10n.reviewQualityAgain]) {
      await tester.tap(find.text(l10n.reviewShowAnswer));
      await tester.pumpAndSettle();
      await tester.tap(find.text(quality));
      await tester.pumpAndSettle();
    }

    expect(find.text(l10n.reviewSessionDoneTitle), findsOneWidget);
    expect(find.text(l10n.reviewSessionDoneBody(2)), findsOneWidget);
    expect(find.text(l10n.reviewNextIn(1)), findsOneWidget);

    await tester.tap(find.text(l10n.reviewSessionDoneCta));
    await tester.pumpAndSettle();
    // Back on the Review tab, which now has nothing due.
    expect(find.text(l10n.reviewCaughtUpTitle), findsOneWidget);
  });

  testWidgets('opened with nothing due, it says so', (tester) async {
    final (_, _, l10n) = await pumpReview(tester, start: '/review/session');

    expect(find.text(l10n.reviewSessionEmpty), findsOneWidget);
  });
}
