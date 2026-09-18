import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mohingo/data/local/database.dart';

import 'review_test_harness.dart';

final _lex = reviewTestIndex.bundle.lexicon;
final _chunks = reviewTestIndex.bundle.chunks;

Future<void> _markUnitInProgress(AppDatabase db, int learnerId) => db
    .into(db.unitProgress)
    .insert(
      UnitProgressCompanion.insert(
        uuid: 'u1',
        learnerId: learnerId,
        unitId: 'A1-U1',
        state: 'inProgress',
        updatedAt: DateTime.now(),
      ),
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final past = DateTime.now().subtract(const Duration(hours: 2));

  testWidgets('due words and phrases are the one highlighted card — how '
      'many, the first few, and Start review opens the session', (
    tester,
  ) async {
    final (_, _, l10n) = await pumpReview(
      tester,
      seed: (db, id) async {
        for (final w in _lex.take(4)) {
          await seedVocabulary(db, id, lexiconId: w.id, dueAt: past);
        }
        await seedVocabulary(db, id, chunkId: _chunks.first.id, dueAt: past);
        await seedVocabulary(
          db,
          id,
          lexiconId: _lex[10].id,
          dueAt: DateTime.now().add(const Duration(days: 3)),
        );
      },
    );

    expect(find.text(l10n.reviewDueOverline.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.reviewDueCount(5)), findsOneWidget);
    expect(find.textContaining(l10n.reviewDueMore(2)), findsOneWidget);

    await tester.tap(find.text(l10n.reviewStartCta));
    await tester.pumpAndSettle();
    expect(find.text(l10n.reviewSessionProgress(1, 5)), findsOneWidget);
  });

  testWidgets('with nothing due it says so, and when the next review is', (
    tester,
  ) async {
    final (_, _, l10n) = await pumpReview(
      tester,
      seed: (db, id) => seedVocabulary(
        db,
        id,
        lexiconId: _lex.first.id,
        dueAt: DateTime.now().add(const Duration(days: 2, hours: 1)),
      ),
    );

    expect(find.text(l10n.reviewCaughtUpTitle), findsOneWidget);
    expect(find.text(l10n.reviewStartCta), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data == l10n.reviewNextIn(2) || w.data == l10n.reviewNextIn(3)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a brand-new learner is told words will come back here', (
    tester,
  ) async {
    final (_, _, l10n) = await pumpReview(tester);

    expect(find.text(l10n.reviewCaughtUpEmpty), findsOneWidget);
  });

  testWidgets('weak spots are named by lesson, unit and skills — never by '
      'internal id — and open a practice activity', (tester) async {
    final (_, _, l10n) = await pumpReview(tester, seed: _markUnitInProgress);

    expect(find.textContaining('A1.U1.'), findsNothing);
    expect(
      find.text(l10n.reviewWeakSpotsOverline.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text('My Name'), findsOneWidget);

    await tester.tap(find.text('My Name'));
    await tester.pumpAndSettle();
    expect(find.textContaining('PRACTICE A1-U1-L1'), findsOneWidget);
  });

  testWidgets('only the first three weak spots show until All is tapped', (
    tester,
  ) async {
    final (_, _, l10n) = await pumpReview(tester, seed: _markUnitInProgress);
    // Unit 2's six goals are taught across four lessons.
    const total = 4;

    expect(find.text('Where Do You Live?'), findsOneWidget);
    expect(find.text('He and She'), findsNothing);

    await tester.tap(find.text(l10n.reviewShowAll(total)));
    await tester.pumpAndSettle();
    expect(find.text('He and She'), findsOneWidget);
    expect(find.text(l10n.reviewShowFewer), findsOneWidget);
  });

  testWidgets('the browse tiles open the words and grammar lists', (
    tester,
  ) async {
    final (_, _, l10n) = await pumpReview(tester);

    expect(
      find.text(l10n.reviewWordsTileMeta(0, _lex.length + _chunks.length)),
      findsOneWidget,
    );
    expect(
      find.text(
        l10n.reviewGrammarTileMeta(reviewTestIndex.bundle.grammar.length),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.reviewWordsTile));
    await tester.pumpAndSettle();
    expect(find.text('WORDS'), findsOneWidget);
  });

  testWidgets('saved words, phrases and grammar are listed and open their '
      'pages', (tester) async {
    final grammar = reviewTestIndex.bundle.grammar.first;
    final (_, _, l10n) = await pumpReview(
      tester,
      seed: (db, id) async {
        await seedVocabulary(
          db,
          id,
          lexiconId: _lex[2].id,
          dueAt: DateTime.now().add(const Duration(days: 4)),
          favorite: true,
        );
        await db
            .into(db.grammarReviewState)
            .insert(
              GrammarReviewStateCompanion.insert(
                uuid: 'g',
                learnerId: id,
                grammarId: grammar.id,
                isFavorite: const Value(true),
                updatedAt: DateTime.now(),
              ),
            );
      },
    );

    expect(find.text(l10n.reviewSavedOverline.toUpperCase()), findsOneWidget);
    expect(find.text(grammar.form), findsOneWidget);

    await tester.tap(find.text(_lex[2].headword));
    await tester.pumpAndSettle();
    expect(find.text('WORD ${_lex[2].id}'), findsOneWidget);
  });

  testWidgets('with nothing saved the saved section explains how to save', (
    tester,
  ) async {
    final (_, _, l10n) = await pumpReview(tester);

    expect(find.text(l10n.reviewNoFavorites), findsOneWidget);
  });
}
