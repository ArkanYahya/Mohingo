import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mohingo/features/progress/providers/current_learner_provider.dart';
import 'package:mohingo/features/progress/providers/progress_providers.dart';

import 'vocabulary_test_harness.dart';

final _lex = reviewTestIndex.bundle.lexicon;
final _chunks = reviewTestIndex.bundle.chunks;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  // "goodbye" (interjection, productive, Unit 1 Lesson 1).
  final word = _lex[2];

  testWidgets('a word page: what kind of word, its audio, Arabic, what it '
      'is for, an example, and the lesson where you met it', (tester) async {
    final (_, l10n) = await pumpVocabulary(
      tester,
      start: '/review/vocabulary/${word.id}',
    );

    expect(
      find.text(
        '${l10n.reviewSessionWord} · ${l10n.partOfSpeechInterjection}'
            .toUpperCase(),
      ),
      findsOneWidget,
    );
    expect(find.text(word.headword), findsOneWidget);
    expect(find.text(word.arabic), findsOneWidget);
    expect(find.text(l10n.wordUsageProductive), findsOneWidget);
    expect(find.text(word.examples.first), findsOneWidget);
    expect(find.text(l10n.wordMetInOverline.toUpperCase()), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget); // A1-U0-L1's title
    expect(find.text(l10n.wordMetInMeta(1, 1)), findsOneWidget);
  });

  testWidgets('a word not in review yet says so and offers the rating; '
      'rating it adds it to the reviews', (tester) async {
    final (container, l10n) = await pumpVocabulary(
      tester,
      start: '/review/vocabulary/${word.id}',
    );

    expect(find.text(l10n.wordStatusNew), findsOneWidget);
    await tester.tap(find.text(l10n.reviewQualityGood));
    await tester.pumpAndSettle();

    final learner = await container.read(currentLearnerProvider.future);
    final state = await container
        .read(reviewStateRepositoryProvider)
        .vocabularyState(learnerId: learner.id, lexiconId: word.id);
    expect(state!.repetitions, 1);
    // Still on the page, now learning, with no rating to give.
    expect(find.text(word.headword), findsOneWidget);
    expect(find.text(l10n.reviewNextIn(1)), findsOneWidget);
    expect(find.text(l10n.reviewQualityGood), findsNothing);
  });

  testWidgets('a due word says so and offers the rating', (tester) async {
    final (_, l10n) = await pumpVocabulary(
      tester,
      start: '/review/vocabulary/${word.id}',
      seed: (db, id) => seedVocabulary(
        db,
        id,
        lexiconId: word.id,
        dueAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    );

    expect(find.text(l10n.wordStatusDue), findsOneWidget);
    expect(find.text(l10n.reviewQualityAgain), findsOneWidget);
  });

  testWidgets('a word scheduled ahead shows when, and no rating', (
    tester,
  ) async {
    final (_, l10n) = await pumpVocabulary(
      tester,
      start: '/review/vocabulary/${word.id}',
      seed: (db, id) => seedVocabulary(
        db,
        id,
        lexiconId: word.id,
        repetitions: 4,
        dueAt: DateTime.now().add(const Duration(days: 9, hours: 1)),
      ),
    );

    expect(find.text(l10n.vocabularyStateLearned), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data == l10n.reviewNextIn(9) || w.data == l10n.reviewNextIn(10)),
      ),
      findsOneWidget,
    );
    expect(find.text(l10n.reviewQualityGood), findsNothing);
  });

  testWidgets('the star saves and unsaves the word', (tester) async {
    final (container, l10n) = await pumpVocabulary(
      tester,
      start: '/review/vocabulary/${word.id}',
    );
    final learner = await container.read(currentLearnerProvider.future);

    await tester.tap(find.byTooltip(l10n.favoriteAddTooltip));
    await tester.pumpAndSettle();
    var state = await container
        .read(reviewStateRepositoryProvider)
        .vocabularyState(learnerId: learner.id, lexiconId: word.id);
    expect(state!.isFavorite, isTrue);

    await tester.tap(find.byTooltip(l10n.favoriteRemoveTooltip));
    await tester.pumpAndSettle();
    state = await container
        .read(reviewStateRepositoryProvider)
        .vocabularyState(learnerId: learner.id, lexiconId: word.id);
    expect(state!.isFavorite, isFalse);
  });

  testWidgets('a phrase page: PHRASE, the phrase, its Arabic, where you met '
      'it, and the rating while it is not in review', (tester) async {
    final chunk = _chunks.first;
    final (_, l10n) = await pumpVocabulary(
      tester,
      start: '/review/chunks/${chunk.id}',
    );

    expect(find.text(l10n.reviewSessionPhrase.toUpperCase()), findsOneWidget);
    expect(find.text(chunk.text), findsOneWidget);
    expect(find.text(chunk.arabic), findsOneWidget);
    expect(find.text(l10n.wordMetInOverline.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.reviewQualityEasy), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
