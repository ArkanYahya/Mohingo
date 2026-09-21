import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mohingo/data/local/database.dart';

import 'review_test_harness.dart';

/// The Review tab is the one tab that must **not** follow the learner's
/// current level: a learner who moves to A2 keeps meeting A1's words in
/// spaced review, which is the moment they need them most. See
/// docs/adr/0006-multiple-levels.md.
final _a1Word = reviewTestIndex.bundle.lexicon.first;
final _a1Phrase = reviewTestIndex.bundle.chunks.first;
final _a2Word = reviewTestA2Index.bundle.lexicon.first;

Future<void> _markUnitInProgress(
  AppDatabase db,
  int learnerId,
  String unitId,
) => db
    .into(db.unitProgress)
    .insert(
      UnitProgressCompanion.insert(
        uuid: unitId,
        learnerId: learnerId,
        unitId: unitId,
        state: 'inProgress',
        updatedAt: DateTime.now(),
      ),
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final past = DateTime.now().subtract(const Duration(hours: 2));

  /// One A1 word, one A1 phrase and one A2 word, all due.
  Future<void> seedBothLevels(AppDatabase db, int learnerId) async {
    await seedVocabulary(
      db,
      learnerId,
      lexiconId: _a1Word.id,
      dueAt: past.subtract(const Duration(days: 1)),
    );
    await seedVocabulary(db, learnerId, chunkId: _a1Phrase.id, dueAt: past);
    await seedVocabulary(
      db,
      learnerId,
      lexiconId: _a2Word.id,
      dueAt: past.add(const Duration(minutes: 1)),
    );
  }

  testWidgets('a learner in A2 with items in both levels sees them all '
      'counted, and the count is exactly what Start review opens', (
    tester,
  ) async {
    final (_, _, l10n) = await pumpReview(
      tester,
      currentLevelId: 'a2',
      seed: seedBothLevels,
    );

    // The bug this pins: the count came from the whole schedule while the
    // session resolved A1's bundle alone, so the A2 word was counted here
    // and then missing from the session this button opened.
    expect(find.text(l10n.reviewDueCount(3)), findsOneWidget);

    await tester.tap(find.text(l10n.reviewStartCta));
    await tester.pumpAndSettle();
    expect(find.text(l10n.reviewSessionProgress(1, 3)), findsOneWidget);
  });

  testWidgets('the session reviews A1 and A2 items in one run', (tester) async {
    final (_, _, l10n) = await pumpReview(
      tester,
      start: '/review/session',
      currentLevelId: 'a2',
      seed: seedBothLevels,
    );

    // Oldest due first: the A1 word, the A1 phrase, then the A2 word.
    for (final expected in [
      _a1Word.headword,
      _a1Phrase.text,
      _a2Word.headword,
    ]) {
      expect(find.text(expected), findsOneWidget);
      await tester.tap(find.text(l10n.reviewShowAnswer));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.reviewQualityGood));
      await tester.pumpAndSettle();
    }

    expect(find.text(l10n.reviewSessionDoneBody(3)), findsOneWidget);
  });

  testWidgets('weak spots come from every level with a unit in progress, '
      'each labelled with its level so the unit number is never ambiguous', (
    tester,
  ) async {
    final (_, _, l10n) = await pumpReview(
      tester,
      currentLevelId: 'a2',
      seed: (db, id) async {
        await _markUnitInProgress(db, id, 'A1-U1');
        await _markUnitInProgress(db, id, 'A2-U1');
      },
    );

    // Three rows show until All is tapped; A2's sit behind A1's.
    await tester.tap(find.byType(TextButton).first);
    await tester.pumpAndSettle();

    // A1-U1 is A1's second unit (A1-U0 comes first); A2-U1 is A2's first.
    expect(find.text('My Name'), findsOneWidget);
    expect(find.text('A Regular Week'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data ?? '').startsWith(l10n.reviewWeakSpotMeta('A1', 2, '')),
      ),
      findsWidgets,
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data ?? '').startsWith(l10n.reviewWeakSpotMeta('A2', 1, '')),
      ),
      findsWidgets,
    );
  });

  testWidgets('the browse tiles count every level the learner has reached', (
    tester,
  ) async {
    final (_, _, l10n) = await pumpReview(tester, currentLevelId: 'a2');
    final a1 = reviewTestIndex.bundle;
    final a2 = reviewTestA2Index.bundle;

    expect(
      find.text(
        l10n.reviewWordsTileMeta(
          0,
          a1.lexicon.length +
              a1.chunks.length +
              a2.lexicon.length +
              a2.chunks.length,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        l10n.reviewGrammarTileMeta(a1.grammar.length + a2.grammar.length),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a level whose bundle fails to load does not take the tab '
      'down — the other level stays reviewable', (tester) async {
    final (_, _, l10n) = await pumpReview(
      tester,
      currentLevelId: 'a2',
      a2Fails: true,
      seed: seedBothLevels,
    );

    // A1's two items still count, and the A2 one is left out of the count
    // and the session together rather than being promised and then missing.
    expect(find.text(l10n.reviewDueCount(2)), findsOneWidget);
    expect(find.textContaining(_a1Word.headword), findsOneWidget);

    await tester.tap(find.text(l10n.reviewStartCta));
    await tester.pumpAndSettle();
    expect(find.text(l10n.reviewSessionProgress(1, 2)), findsOneWidget);
    expect(find.text(_a1Word.headword), findsOneWidget);
  });
}
