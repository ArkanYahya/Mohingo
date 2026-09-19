import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/features/activity_engine/presentation/activity_chrome.dart';
import 'package:mohingo/features/activity_engine/presentation/activity_view_registry.dart';
import 'package:mohingo/features/activity_engine/presentation/widgets/activity_option_tile.dart';
import 'package:mohingo/features/activity_engine/presentation/widgets/activity_word_tile.dart';
import 'package:mohingo/features/activity_engine/presentation/widgets/answer_tile_state.dart';
import 'package:mohingo/features/activity_engine/providers/sound_effects_providers.dart';
import 'package:mohingo/features/speech/domain/speech_capability_service.dart';
import 'package:mohingo/features/speech/domain/speech_recognition_service.dart';
import 'package:mohingo/features/speech/providers/speech_providers.dart';

import '../speech/fake_speech_services.dart';
import 'answer_activity.dart';
import 'fake_sound_effects_service.dart';
import 'test_harness.dart';

final _index = CourseContentIndex.build(
  CourseBundleParser.parse(
    File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
  ),
);

T _first<T extends Activity>() =>
    _index.activitiesById.values.whereType<T>().first;

/// Marked states that must never appear inside a test.
bool _marked(AnswerTileState s) =>
    s == AnswerTileState.correct ||
    s == AnswerTileState.incorrect ||
    s == AnswerTileState.dimmed;

Future<(FakeSoundEffectsService, AppLocalizations)> _pumpInTest(
  WidgetTester tester,
  Activity activity, {
  bool testMode = true,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final sound = FakeSoundEffectsService();
  await tester.pumpActivityView(
    Builder(
      builder: (context) => ActivityFrameScope(
        onContinue: () {},
        testMode: testMode,
        child: buildActivityView(
          activity,
          learnerId: 1,
          onSubmitted: (_) {},
          mediaByKey: _index.bundle.mediaSpecifications,
        ),
      ),
    ),
    overrides: [
      soundEffectsServiceProvider.overrideWithValue(sound),
      speechCapabilityServiceProvider.overrideWithValue(
        FakeSpeechCapabilityService(
          const DeviceSpeechCapabilities(
            sttAvailableForLocale: false,
            micPermission: SpeechPermissionStatus.notDetermined,
          ),
        ),
      ),
    ],
  );
  await tester.pumpAndSettle();
  return (
    sound,
    AppLocalizations.of(tester.element(find.byType(Scaffold).first))!,
  );
}

Future<void> _check(WidgetTester tester) async {
  await tester.tap(find.byType(FilledButton).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('choice: after Check the answer is saved, not marked — the '
      "pick stays selected, the right answer isn't shown, no sound", (
    tester,
  ) async {
    final activity = _first<AudioChoiceActivity>();
    final (sound, l10n) = await _pumpInTest(tester, activity);
    final wrong = activity.options.firstWhere((o) => o != activity.answer);

    await tester.tap(find.text(wrong).last);
    await tester.pump();
    await _check(tester);

    expect(find.text(l10n.testAnswerSaved), findsOneWidget);
    expect(find.text(l10n.activityFeedbackIncorrectTitle), findsNothing);
    expect(
      find.text(l10n.activityFeedbackCorrectAnswerLabel.toUpperCase()),
      findsNothing,
    );
    final tiles = tester.widgetList<ActivityOptionTile>(
      find.byType(ActivityOptionTile),
    );
    expect(tiles.where((t) => _marked(t.state)), isEmpty);
    expect(
      tiles.singleWhere((t) => t.label == wrong).state,
      AnswerTileState.selected,
    );
    expect(sound.played, isEmpty);
  });

  testWidgets('listening questions offer no transcript in a test', (
    tester,
  ) async {
    final (_, l10n) = await _pumpInTest(tester, _first<AudioChoiceActivity>());

    expect(find.text(l10n.activityShowTranscript), findsNothing);
  });

  testWidgets('outside a test the same question still marks and offers the '
      'transcript', (tester) async {
    final activity = _first<AudioChoiceActivity>();
    final (sound, l10n) = await _pumpInTest(tester, activity, testMode: false);

    expect(find.text(l10n.activityShowTranscript), findsOneWidget);
    await enterCorrectAnswer(tester, activity);
    await _check(tester);
    expect(find.text(l10n.activityFeedbackCorrect), findsOneWidget);
    expect(sound.played, isNotEmpty);
  });

  for (final (name, pick) in <(String, Activity Function())>[
    ('gap', _first<GapActivity>),
    ('order', _first<OrderActivity>),
    ('match', _first<MatchActivity>),
  ]) {
    testWidgets('$name: no word tile is marked right or wrong in a test', (
      tester,
    ) async {
      final activity = pick();
      final (sound, l10n) = await _pumpInTest(tester, activity);

      await enterCorrectAnswer(tester, activity);
      await _check(tester);

      expect(find.text(l10n.testAnswerSaved), findsOneWidget);
      expect(find.text(l10n.activityFeedbackCorrect), findsNothing);
      final tiles = tester.widgetList<ActivityWordTile>(
        find.byType(ActivityWordTile),
      );
      expect(tiles.where((t) => _marked(t.state)), isEmpty);
      expect(sound.played, isEmpty);
    });
  }

  for (final (name, pick) in <(String, Activity Function())>[
    ('write', _first<WriteActivity>),
    ('speak', _first<SpeakActivity>),
  ]) {
    testWidgets('$name: saved without a verdict or sound in a test', (
      tester,
    ) async {
      final activity = pick();
      final (sound, l10n) = await _pumpInTest(tester, activity);

      await enterCorrectAnswer(tester, activity);
      await _check(tester);

      expect(find.text(l10n.testAnswerSaved), findsOneWidget);
      expect(find.text(l10n.activityFeedbackCorrect), findsNothing);
      expect(sound.played, isEmpty);
    });
  }
}
