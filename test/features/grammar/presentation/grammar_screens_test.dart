import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/providers/current_learner_provider.dart';
import 'package:mohingo/features/progress/providers/progress_providers.dart';

import 'grammar_test_harness.dart';

final _grammar = reviewTestIndex.bundle.grammar;
final _units = reviewTestIndex.bundle.units;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('grammar list', () {
    testWidgets('groups forms under their unit, named — never by unit id', (
      tester,
    ) async {
      final (_, l10n) = await pumpGrammar(tester);

      expect(find.textContaining('A1-U'), findsNothing);
      final heading = find.textContaining(
        l10n.learnUnitOverline(2).toUpperCase(),
      );
      expect(heading, findsOneWidget);
      expect(
        tester.widget<Text>(heading).data,
        contains(_units[1].title.toUpperCase()),
      );
      expect(find.text(_grammar.first.form), findsOneWidget);
      expect(find.text(_grammar.first.meaningAr), findsOneWidget);
    });

    testWidgets('search narrows the list and drops empty units', (
      tester,
    ) async {
      final (_, l10n) = await pumpGrammar(tester);

      await tester.enterText(find.byType(TextField), 'you are');
      await tester.pumpAndSettle();
      expect(find.text('you are'), findsWidgets);
      expect(find.text(_grammar.first.form), findsNothing); // "I am"
      expect(
        find.textContaining(l10n.learnUnitOverline(3).toUpperCase()),
        findsNothing,
      );

      await tester.enterText(find.byType(TextField), 'zzzznomatch');
      await tester.pumpAndSettle();
      expect(find.text(l10n.grammarEmptyResults), findsOneWidget);
    });

    testWidgets('a saved form shows its star, and tapping opens its page', (
      tester,
    ) async {
      final (_, l10n) = await pumpGrammar(
        tester,
        seed: (db, id) => db
            .into(db.grammarReviewState)
            .insert(
              GrammarReviewStateCompanion.insert(
                uuid: 'g',
                learnerId: id,
                grammarId: _grammar.first.id,
                isFavorite: const Value(true),
                updatedAt: DateTime.now(),
              ),
            ),
      );

      expect(find.byIcon(Icons.star_rounded), findsOneWidget);

      await tester.tap(find.text(_grammar.first.form));
      await tester.pumpAndSettle();
      expect(find.text(l10n.grammarOverline(2).toUpperCase()), findsOneWidget);
    });
  });

  group('grammar page', () {
    final item = _grammar.first; // "I am", short form "I'm", Unit 2

    testWidgets('shows the form, short form, meaning, examples, and the '
        'lessons where you practise it', (tester) async {
      final (_, l10n) = await pumpGrammar(
        tester,
        start: '/review/grammar/${item.id}',
      );

      expect(find.text(l10n.grammarOverline(2).toUpperCase()), findsOneWidget);
      expect(find.text(item.form), findsOneWidget);
      expect(find.text(l10n.grammarShortForm(item.shortForm!)), findsOneWidget);
      expect(find.text(item.meaningAr), findsOneWidget);
      expect(find.text(item.examples.first.en), findsOneWidget);
      expect(find.text(item.examples.first.ar), findsOneWidget);
      expect(
        find.text(l10n.grammarPractisedInOverline.toUpperCase()),
        findsOneWidget,
      );
      expect(find.text('My Name'), findsOneWidget);
      expect(find.text(l10n.wordMetInMeta(2, 1)), findsOneWidget);
    });

    testWidgets('Quick practice opens a practice activity from a linked '
        'lesson', (tester) async {
      final (_, l10n) = await pumpGrammar(
        tester,
        start: '/review/grammar/${item.id}',
      );

      await tester.tap(find.text(l10n.grammarQuickPractice));
      await tester.pumpAndSettle();
      expect(find.textContaining('PRACTICE A1-U1-L1'), findsOneWidget);
    });

    testWidgets('Mark as reviewed saves and becomes Reviewed', (tester) async {
      final (container, l10n) = await pumpGrammar(
        tester,
        start: '/review/grammar/${item.id}',
      );

      await tester.tap(find.text(l10n.grammarMarkReviewed));
      await tester.pumpAndSettle();

      final learner = await container.read(currentLearnerProvider.future);
      final state = await container
          .read(reviewStateRepositoryProvider)
          .grammarState(learnerId: learner.id, grammarId: item.id);
      expect(state!.markedReviewedAt, isNotNull);
      expect(find.text(l10n.grammarReviewed), findsOneWidget);
    });

    testWidgets('the star saves the form', (tester) async {
      final (container, l10n) = await pumpGrammar(
        tester,
        start: '/review/grammar/${item.id}',
      );

      await tester.tap(find.byTooltip(l10n.favoriteAddTooltip));
      await tester.pumpAndSettle();

      final learner = await container.read(currentLearnerProvider.future);
      final state = await container
          .read(reviewStateRepositoryProvider)
          .grammarState(learnerId: learner.id, grammarId: item.id);
      expect(state!.isFavorite, isTrue);
      expect(find.byTooltip(l10n.favoriteRemoveTooltip), findsOneWidget);
    });
  });
}
