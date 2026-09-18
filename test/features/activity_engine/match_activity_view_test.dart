import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/data/local/database.dart' show ActivityAttempt;
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';
import 'package:mohingo/features/activity_engine/domain/sound_effects_service.dart';
import 'package:mohingo/features/activity_engine/presentation/views/match_activity_view.dart';
import 'package:mohingo/features/activity_engine/presentation/widgets/activity_word_tile.dart';
import 'package:mohingo/features/activity_engine/presentation/widgets/answer_tile_state.dart';
import 'package:mohingo/features/activity_engine/providers/sound_effects_providers.dart';

import 'fake_sound_effects_service.dart';
import 'test_harness.dart';

MatchActivity _matchActivity() {
  return const MatchActivity(
    id: 'A1-U2-L1-A02',
    lessonId: 'A1-U2-L1',
    mode: ActivityMode.practice,
    skill: Skill.reading,
    canDo: ['A1.U2.PRODUCTION.STATE_RELATIONSHIP'],
    prompt: 'Match the people and relationships.',
    promptAr: 'طابق الأشخاص بصلة القرابة.',
    raw: {},
    pairs: [
      ['Lina', 'mother'],
      ['Sami', 'father'],
    ],
  );
}

void main() {
  testWidgets('renders every left and right item', (tester) async {
    await tester.pumpActivityView(
      MatchActivityView(activity: _matchActivity(), onSubmitted: (_) {}),
    );

    expect(find.text('Lina'), findsOneWidget);
    expect(find.text('Sami'), findsOneWidget);
    expect(find.text('mother'), findsOneWidget);
    expect(find.text('father'), findsOneWidget);
  });

  testWidgets('submit is disabled until every left item is matched', (
    tester,
  ) async {
    await tester.pumpActivityView(
      MatchActivityView(activity: _matchActivity(), onSubmitted: (_) {}),
    );

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.tap(find.text('Lina'));
    await tester.pump();
    await tester.tap(find.text('mother'));
    await tester.pump();

    // Only 1 of 2 pairs matched so far.
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  Future<void> tapItem(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pump();
  }

  ActivityWordTile tileOf(WidgetTester tester, String label) => tester
      .widget<ActivityWordTile>(find.widgetWithText(ActivityWordTile, label));

  testWidgets('matching every pair only enables Check; Check submits', (
    tester,
  ) async {
    ActivitySubmission? reported;
    await tester.pumpActivityView(
      MatchActivityView(
        activity: _matchActivity(),
        onSubmitted: (s) => reported = s,
      ),
    );

    await tapItem(tester, 'Lina');
    await tapItem(tester, 'mother');
    await tapItem(tester, 'Sami');
    await tapItem(tester, 'father');
    expect(reported, isNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(reported?.correctness, ActivityCorrectness.correct);
    expect(
      reported?.rawAnswerJson,
      jsonEncode({'Lina': 'mother', 'Sami': 'father'}),
    );
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('a pair gets the same number on both sides, in the neutral '
      'paired look — never green before Check', (tester) async {
    await tester.pumpActivityView(
      MatchActivityView(activity: _matchActivity(), onSubmitted: (_) {}),
    );

    await tapItem(tester, 'Sami');
    expect(tileOf(tester, 'Sami').state, AnswerTileState.selected);

    await tapItem(tester, 'father');

    expect(tileOf(tester, 'Sami').state, AnswerTileState.paired);
    expect(tileOf(tester, 'father').state, AnswerTileState.paired);
    expect(tileOf(tester, 'Sami').badge, isNotNull);
    expect(tileOf(tester, 'father').badge, tileOf(tester, 'Sami').badge);
    expect(tileOf(tester, 'Lina').badge, isNull);
  });

  testWidgets('either column can be tapped first', (tester) async {
    await tester.pumpActivityView(
      MatchActivityView(activity: _matchActivity(), onSubmitted: (_) {}),
    );

    await tapItem(tester, 'mother');
    await tapItem(tester, 'Lina');

    expect(tileOf(tester, 'Lina').state, AnswerTileState.paired);
    expect(tileOf(tester, 'mother').state, AnswerTileState.paired);
  });

  testWidgets('tapping a paired item un-pairs it, so a wrong pair can be '
      'fixed before Check', (tester) async {
    await tester.pumpActivityView(
      MatchActivityView(activity: _matchActivity(), onSubmitted: (_) {}),
    );

    await tapItem(tester, 'Lina');
    await tapItem(tester, 'father'); // wrong pair
    await tapItem(tester, 'father'); // undo it

    expect(tileOf(tester, 'Lina').state, AnswerTileState.idle);
    expect(tileOf(tester, 'father').state, AnswerTileState.idle);
    expect(tileOf(tester, 'Lina').badge, isNull);
  });

  testWidgets('counts matched pairs under the columns', (tester) async {
    await tester.pumpActivityView(
      MatchActivityView(activity: _matchActivity(), onSubmitted: (_) {}),
    );

    expect(find.text('0 of 2 matched'), findsOneWidget);
    await tapItem(tester, 'Lina');
    await tapItem(tester, 'mother');
    expect(find.text('1 of 2 matched'), findsOneWidget);
  });

  testWidgets('after Check, each pair is marked right or wrong on both sides', (
    tester,
  ) async {
    await tester.pumpActivityView(
      MatchActivityView(activity: _matchActivity(), onSubmitted: (_) {}),
    );

    await tapItem(tester, 'Lina');
    await tapItem(tester, 'father');
    await tapItem(tester, 'Sami');
    await tapItem(tester, 'mother');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    for (final label in ['Lina', 'father', 'Sami', 'mother']) {
      expect(tileOf(tester, label).state, AnswerTileState.incorrect);
    }
  });

  testWidgets('plays the correct sound when a fully correct match is checked', (
    tester,
  ) async {
    final fakeSound = FakeSoundEffectsService();
    await tester.pumpActivityView(
      MatchActivityView(activity: _matchActivity(), onSubmitted: (_) {}),
      overrides: [soundEffectsServiceProvider.overrideWithValue(fakeSound)],
    );

    await tapItem(tester, 'Lina');
    await tapItem(tester, 'mother');
    await tapItem(tester, 'Sami');
    await tapItem(tester, 'father');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(fakeSound.played, [ActivityFeedbackSound.correct]);
  });

  group('review mode (reviewAttempt)', () {
    testWidgets(
      'renders the recorded result read-only, trusting isCorrect verbatim '
      'even when every pair in the record is actually correct',
      (tester) async {
        await tester.pumpActivityView(
          MatchActivityView(
            activity: _matchActivity(),
            onSubmitted: (_) {},
            reviewAttempt: ActivityAttempt(
              id: 1,
              uuid: 'attempt-1',
              learnerId: 1,
              activityId: 'A1-U2-L1-A02',
              sessionType: 'lesson',
              mode: 'practice',
              evidenceSkill: 'reading',
              rawAnswer: jsonEncode({
                'Lina': 'mother',
                'Sami': 'father',
              }), // every pair actually correct
              isCorrect: false, // deliberately recorded wrong
              score: 0.0,
              wasFallback: false,
              attemptedAt: DateTime.utc(2026, 9, 9),
              updatedAt: DateTime.utc(2026, 9, 9),
            ),
          ),
        );

        expect(find.byIcon(Icons.cancel), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsNothing);
        expect(find.byType(FilledButton), findsNothing);
      },
    );

    testWidgets('a never-graded (isCorrect: null) attempt renders the neutral '
        '"saved for review" treatment, never as incorrect', (tester) async {
      await tester.pumpActivityView(
        MatchActivityView(
          activity: _matchActivity(),
          onSubmitted: (_) {},
          reviewAttempt: ActivityAttempt(
            id: 1,
            uuid: 'attempt-1',
            learnerId: 1,
            activityId: 'A1-U2-L1-A02',
            sessionType: 'lesson',
            mode: 'practice',
            evidenceSkill: 'reading',
            rawAnswer: jsonEncode({'Lina': 'mother', 'Sami': 'father'}),
            isCorrect: null,
            score: null,
            wasFallback: false,
            attemptedAt: DateTime.utc(2026, 9, 9),
            updatedAt: DateTime.utc(2026, 9, 9),
          ),
        ),
      );

      expect(find.byIcon(Icons.hourglass_top), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });
  });
}
