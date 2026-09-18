import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/data/local/database.dart' show ActivityAttempt;
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';
import 'package:mohingo/features/activity_engine/domain/sound_effects_service.dart';
import 'package:mohingo/features/activity_engine/presentation/views/order_activity_view.dart';
import 'package:mohingo/features/activity_engine/presentation/widgets/activity_word_tile.dart';
import 'package:mohingo/features/activity_engine/providers/sound_effects_providers.dart';

import 'fake_sound_effects_service.dart';
import 'test_harness.dart';

OrderActivity _orderActivity() {
  return const OrderActivity(
    id: 'A1-U2-L1-A03',
    lessonId: 'A1-U2-L1',
    mode: ActivityMode.practice,
    skill: Skill.reading,
    canDo: ['A1.U2.PRODUCTION.DESCRIBE_FAMILY'],
    prompt: 'Build the sentence.',
    promptAr: 'رتب الجملة.',
    raw: {},
    tokens: ['is', 'This', 'mother', 'my'],
    answer: ['This', 'is', 'my', 'mother'],
  );
}

void main() {
  /// Taps [token] in the word bank — the bank is laid out after the answer
  /// area, so `.last` is the bank's tile once the word is also placed.
  Future<void> placeToken(WidgetTester tester, String token) async {
    await tester.tap(find.widgetWithText(ActivityWordTile, token).last);
    await tester.pump();
  }

  testWidgets('renders every token as a tappable tile', (tester) async {
    await tester.pumpActivityView(
      OrderActivityView(activity: _orderActivity(), onSubmitted: (_) {}),
    );

    for (final token in ['is', 'This', 'mother', 'my']) {
      expect(find.widgetWithText(ActivityWordTile, token), findsOneWidget);
    }
  });

  testWidgets('a placed word leaves a same-size empty slot in the bank, so '
      "the other words don't move", (tester) async {
    await tester.pumpActivityView(
      OrderActivityView(activity: _orderActivity(), onSubmitted: (_) {}),
    );
    final motherBefore = tester.getTopLeft(
      find.widgetWithText(ActivityWordTile, 'mother'),
    );
    final thisSize = tester.getSize(
      find.widgetWithText(ActivityWordTile, 'This'),
    );

    await placeToken(tester, 'This');

    expect(find.byType(ActivityWordTileGhost), findsOneWidget);
    expect(tester.getSize(find.byType(ActivityWordTileGhost)), thisSize);
    expect(
      tester.getTopLeft(find.widgetWithText(ActivityWordTile, 'mother').last),
      motherBefore,
    );
  });

  testWidgets('placing every word only fills the sentence; Check submits it', (
    tester,
  ) async {
    ActivitySubmission? reported;
    await tester.pumpActivityView(
      OrderActivityView(
        activity: _orderActivity(),
        onSubmitted: (s) => reported = s,
      ),
    );

    for (final token in ['This', 'is', 'my', 'mother']) {
      await placeToken(tester, token);
    }
    expect(reported, isNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(reported?.correctness, ActivityCorrectness.correct);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('plays the correct sound when a correct order is checked', (
    tester,
  ) async {
    final fakeSound = FakeSoundEffectsService();
    await tester.pumpActivityView(
      OrderActivityView(activity: _orderActivity(), onSubmitted: (_) {}),
      overrides: [soundEffectsServiceProvider.overrideWithValue(fakeSound)],
    );

    for (final token in ['This', 'is', 'my', 'mother']) {
      await placeToken(tester, token);
    }
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(fakeSound.played, [ActivityFeedbackSound.correct]);
  });

  testWidgets('checking a wrong order reports incorrect', (tester) async {
    ActivitySubmission? reported;
    await tester.pumpActivityView(
      OrderActivityView(
        activity: _orderActivity(),
        onSubmitted: (s) => reported = s,
      ),
    );

    for (final token in ['is', 'This', 'my', 'mother']) {
      await placeToken(tester, token);
    }
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(reported?.correctness, ActivityCorrectness.incorrect);
  });

  testWidgets('tapping a placed word sends that word — not just the last '
      'one — back to the bank', (tester) async {
    ActivitySubmission? reported;
    await tester.pumpActivityView(
      OrderActivityView(
        activity: _orderActivity(),
        onSubmitted: (s) => reported = s,
      ),
    );

    await placeToken(tester, 'is'); // wrong start
    await placeToken(tester, 'This');
    // Take "is" back out of the sentence (the first tile in tree order).
    await tester.tap(find.widgetWithText(ActivityWordTile, 'is').first);
    await tester.pump();
    for (final token in ['is', 'my', 'mother']) {
      await placeToken(tester, token);
    }
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(reported?.correctness, ActivityCorrectness.correct);
    expect(reported?.rawAnswerJson, jsonEncode(['This', 'is', 'my', 'mother']));
  });

  testWidgets('after Check the spent word bank (all empty slots) is gone', (
    tester,
  ) async {
    await tester.pumpActivityView(
      OrderActivityView(activity: _orderActivity(), onSubmitted: (_) {}),
    );

    for (final token in ['This', 'is', 'my', 'mother']) {
      await placeToken(tester, token);
    }
    expect(find.byType(ActivityWordTileGhost), findsNWidgets(4));

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.byType(ActivityWordTileGhost), findsNothing);
  });

  testWidgets('Check stays disabled until every word is placed', (
    tester,
  ) async {
    await tester.pumpActivityView(
      OrderActivityView(activity: _orderActivity(), onSubmitted: (_) {}),
    );

    await placeToken(tester, 'This');
    await placeToken(tester, 'is');

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  group('review mode (reviewAttempt)', () {
    testWidgets(
      'renders the recorded order read-only, trusting isCorrect verbatim '
      'even when the recorded order is actually correct',
      (tester) async {
        await tester.pumpActivityView(
          OrderActivityView(
            activity: _orderActivity(),
            onSubmitted: (_) {},
            reviewAttempt: ActivityAttempt(
              id: 1,
              uuid: 'attempt-1',
              learnerId: 1,
              activityId: 'A1-U2-L1-A03',
              sessionType: 'lesson',
              mode: 'practice',
              evidenceSkill: 'reading',
              rawAnswer: jsonEncode([
                'This',
                'is',
                'my',
                'mother',
              ]), // the actually-correct order
              isCorrect: false, // deliberately recorded wrong
              score: 0.0,
              wasFallback: false,
              attemptedAt: DateTime.utc(2026, 9, 9),
              updatedAt: DateTime.utc(2026, 9, 9),
            ),
          ),
        );

        for (final token in ['This', 'is', 'my', 'mother']) {
          expect(find.text(token), findsOneWidget);
        }
        expect(find.byIcon(Icons.cancel), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsNothing);
        expect(find.byType(FilledButton), findsNothing);
      },
    );

    testWidgets('a never-graded (isCorrect: null) attempt renders the neutral '
        '"saved for review" treatment, never as incorrect', (tester) async {
      await tester.pumpActivityView(
        OrderActivityView(
          activity: _orderActivity(),
          onSubmitted: (_) {},
          reviewAttempt: ActivityAttempt(
            id: 1,
            uuid: 'attempt-1',
            learnerId: 1,
            activityId: 'A1-U2-L1-A03',
            sessionType: 'lesson',
            mode: 'practice',
            evidenceSkill: 'reading',
            rawAnswer: jsonEncode(['This', 'is', 'my', 'mother']),
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
