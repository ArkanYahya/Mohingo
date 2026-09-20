import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mohingo/data/local/database.dart';

import 'vocabulary_test_harness.dart';

final _lex = reviewTestIndex.bundle.lexicon;
final _chunks = reviewTestIndex.bundle.chunks;

/// One due, one learning, one learned word; one saved phrase.
Future<void> _seed(AppDatabase db, int id) async {
  final now = DateTime.now();
  await seedVocabulary(
    db,
    id,
    lexiconId: _lex[0].id,
    dueAt: now.subtract(const Duration(hours: 1)),
  );
  await seedVocabulary(
    db,
    id,
    lexiconId: _lex[1].id,
    dueAt: now.add(const Duration(days: 3)),
    favorite: true,
  );
  await seedVocabulary(
    db,
    id,
    lexiconId: _lex[2].id,
    repetitions: 4,
    dueAt: now.add(const Duration(days: 20)),
  );
  await seedVocabulary(
    db,
    id,
    chunkId: _chunks[0].id,
    dueAt: now.add(const Duration(days: 1)),
    favorite: true,
  );
}

Finder _chip(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(ChoiceChip));

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('opens on words, each with its Arabic and a small status '
      'label; the old stat tiles are gone', (tester) async {
    final (_, l10n) = await pumpVocabulary(tester, seed: _seed);

    expect(find.text(l10n.reviewWordsTile), findsOneWidget);
    expect(find.text(_lex[0].headword), findsOneWidget);
    expect(find.text(_lex[0].arabic), findsWidgets);
    // Status labels on the rows (plus the chips' own labels).
    expect(find.text(l10n.vocabularyStatDue), findsNWidgets(2));
    expect(find.text(l10n.vocabularyStateLearned), findsNWidgets(2));
    expect(find.text(_chunks[0].text), findsNothing);
  });

  testWidgets('the status chips count this list and filter it', (tester) async {
    final (_, l10n) = await pumpVocabulary(tester, seed: _seed);

    expect(
      find.bySemanticsLabel(
        l10n.vocabularyFilterSemantics(l10n.vocabularyStatDue, 1),
      ),
      findsOneWidget,
    );

    await tester.tap(_chip(l10n.vocabularyStatLearning));
    await tester.pumpAndSettle();
    expect(find.text(_lex[1].headword), findsOneWidget);
    expect(find.text(_lex[0].headword), findsNothing);
    expect(find.text(_lex[2].headword), findsNothing);
  });

  testWidgets('Saved shows only starred items', (tester) async {
    final (_, l10n) = await pumpVocabulary(tester, seed: _seed);

    await tester.tap(_chip(l10n.vocabularyFilterSaved));
    await tester.pumpAndSettle();
    expect(find.text(_lex[1].headword), findsOneWidget);
    expect(find.text(_lex[0].headword), findsNothing);
  });

  testWidgets('Phrases switches the list to phrases', (tester) async {
    final (_, l10n) = await pumpVocabulary(tester, seed: _seed);

    await tester.tap(find.text(l10n.vocabularyTabChunks));
    await tester.pumpAndSettle();
    expect(find.text(_chunks[0].text), findsOneWidget);
    expect(find.text(_lex[0].headword), findsNothing);
    expect(find.text(l10n.vocabularyFilterProductive), findsNothing);
  });

  testWidgets('Speaking & writing leaves out words only to be recognised', (
    tester,
  ) async {
    final (_, l10n) = await pumpVocabulary(tester);
    final receptiveOnly = _lex.firstWhere((w) => !w.productive);
    final productive = _lex.firstWhere((w) => w.productive);

    await tester.enterText(find.byType(TextField), receptiveOnly.headword);
    await tester.pumpAndSettle();
    expect(find.text(receptiveOnly.headword), findsWidgets);

    // The last chip in a sideways-scrolling row.
    await tester.ensureVisible(find.text(l10n.vocabularyFilterProductive));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.vocabularyFilterProductive));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.text(receptiveOnly.headword),
      ),
      findsNothing,
    );

    await tester.enterText(find.byType(TextField), productive.headword);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.text(productive.headword),
      ),
      findsWidgets,
    );
  });

  testWidgets('search matches English or Arabic, and says when nothing '
      'matches', (tester) async {
    final (_, l10n) = await pumpVocabulary(tester);

    await tester.enterText(find.byType(TextField), _lex[5].arabic);
    await tester.pumpAndSettle();
    expect(find.text(_lex[5].headword), findsWidgets);

    await tester.enterText(find.byType(TextField), 'zzzznomatch');
    await tester.pumpAndSettle();
    expect(find.text(l10n.vocabularyEmptyResults), findsOneWidget);
  });

  testWidgets('tapping a word opens its page', (tester) async {
    await pumpVocabulary(tester, seed: _seed);

    await tester.tap(find.text(_lex[2].headword));
    await tester.pumpAndSettle();
    expect(find.text(_lex[2].examples.first.en), findsOneWidget);
  });
}
