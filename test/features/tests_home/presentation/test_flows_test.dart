import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/l10n/skill_label.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/activity_engine/providers/sound_effects_providers.dart';
import 'package:mohingo/features/final_assessment/presentation/final_assessment_screen.dart';
import 'package:mohingo/features/final_mission/presentation/final_mission_screen.dart';
import 'package:mohingo/features/placement_test/domain/placement_item_sampler.dart';
import 'package:mohingo/features/placement_test/presentation/placement_test_screen.dart';
import 'package:mohingo/features/progress/data/drift_learner_repository.dart';
import 'package:mohingo/features/speech/domain/speech_capability_service.dart';
import 'package:mohingo/features/speech/domain/speech_recognition_service.dart';
import 'package:mohingo/features/speech/providers/speech_providers.dart';

import '../../activity_engine/answer_activity.dart';
import '../../activity_engine/fake_sound_effects_service.dart';
import '../../speech/fake_speech_services.dart';

final _index = CourseContentIndex.build(
  CourseBundleParser.parse(
    File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
  ),
);
final _a2Index = CourseContentIndex.build(
  CourseBundleParser.parse(
    File('assets/content/en/A2/a2-course-bundle.json').readAsStringSync(),
  ),
);

/// Pumps [screen] for a learner in [levelId] — enrolling and selecting
/// anything but the base level first, the way
/// `LevelSelectionController.select` would, so `currentLevelIdProvider`
/// resolves to it and the capstones load that level's content.
Future<(AppLocalizations, AppDatabase)> _pump(
  WidgetTester tester,
  Widget screen, {
  String levelId = 'a1',
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  if (levelId != 'a1') {
    final index = {'a2': _a2Index}[levelId]!;
    final repository = DriftLearnerRepository(db);
    final learnerId = (await repository.getOrCreateLearner()).id;
    await repository.ensureEnrolled(
      learnerId: learnerId,
      levelId: levelId,
      courseId: index.bundle.course.id,
      contentVersion: index.bundle.contentVersion,
    );
    await repository.markLevelSelected(learnerId: learnerId, levelId: levelId);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
        courseContentProvider('a1').overrideWith((ref) async => _index),
        courseContentProvider('a2').overrideWith((ref) async => _a2Index),
        placementSeedProvider.overrideWithValue(999),
        soundEffectsServiceProvider.overrideWithValue(
          FakeSoundEffectsService(),
        ),
        textToSpeechServiceProvider.overrideWithValue(
          FakeTextToSpeechService(),
        ),
        speechCapabilityServiceProvider.overrideWithValue(
          FakeSpeechCapabilityService(
            const DeviceSpeechCapabilities(
              sttAvailableForLocale: false,
              micPermission: SpeechPermissionStatus.notDetermined,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(AppColorSeed.calmTeal),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (
    AppLocalizations.of(tester.element(find.byType(Scaffold).first))!,
    db,
  );
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final assessment = _index.bundle.finalAssessment;
  final mission = _index.bundle.finalMission;

  group('final assessment', () {
    testWidgets('the intro lists every section with its size, and says '
        "answers aren't marked", (tester) async {
      final (l10n, _) = await _pump(tester, const FinalAssessmentScreen());

      expect(find.text(assessment.title), findsOneWidget);
      for (final MapEntry(:key, :value) in assessment.sections.entries) {
        expect(find.text(sectionLabel(l10n, key)), findsOneWidget);
        expect(
          find.text(l10n.testIntroQuestionCount(value.activities.length)),
          findsWidgets,
        );
      }
      expect(find.text(l10n.testRulesNote), findsOneWidget);
      expect(find.text(l10n.finalAssessmentIntroBody('A1')), findsOneWidget);
    });

    testWidgets('a learner in A2 sits A2\'s assessment, named as A2', (
      tester,
    ) async {
      final a2 = _a2Index.bundle.finalAssessment;
      final (l10n, _) = await _pump(
        tester,
        const FinalAssessmentScreen(),
        levelId: 'a2',
      );

      expect(find.text(a2.title), findsOneWidget);
      expect(find.text(assessment.title), findsNothing);
      expect(find.text(l10n.finalAssessmentIntroBody('A2')), findsOneWidget);
      expect(find.text(l10n.finalAssessmentIntroBody('A1')), findsNothing);

      // It is not just the intro: starting it serves an A2 question.
      await tester.tap(find.text(l10n.finalAssessmentStartButton));
      await tester.pumpAndSettle();
      final first = a2.sections.entries.first;
      expect(
        find.text(
          l10n
              .testQuestionEyebrow(
                sectionLabel(l10n, first.key),
                1,
                first.value.activities.length,
              )
              .toUpperCase(),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a question sits in the frame with its section and place; '
        'no transcript, and after Check the answer is only saved', (
      tester,
    ) async {
      final (l10n, db) = await _pump(tester, const FinalAssessmentScreen());
      await tester.tap(find.text(l10n.finalAssessmentStartButton));
      await tester.pumpAndSettle();

      final first = assessment.sections.entries.first;
      expect(
        find.text(
          l10n
              .testQuestionEyebrow(
                sectionLabel(l10n, first.key),
                1,
                first.value.activities.length,
              )
              .toUpperCase(),
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.activityShowTranscript), findsNothing);

      await enterCorrectAnswer(tester, first.value.activities.first);
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
      expect(find.text(l10n.testAnswerSaved), findsOneWidget);
      expect(find.text(l10n.activityFeedbackCorrect), findsNothing);

      await tester.tap(find.text(l10n.testNextQuestion));
      await tester.pumpAndSettle();
      expect(
        find.text(
          l10n
              .testQuestionEyebrow(
                sectionLabel(l10n, first.key),
                2,
                first.value.activities.length,
              )
              .toUpperCase(),
        ),
        findsOneWidget,
      );
      final attempts = await db.select(db.activityAttempts).get();
      expect(attempts.single.sessionType, 'finalAssessment');
    });
  });

  group('final mission', () {
    testWidgets('the intro lists the stages of the day with their tasks', (
      tester,
    ) async {
      final (l10n, _) = await _pump(tester, const FinalMissionScreen());

      expect(find.text(mission.title), findsOneWidget);
      expect(find.text(l10n.testsMissionBody('A1')), findsOneWidget);
      for (final stage in mission.stages) {
        expect(find.text(stage.title), findsOneWidget);
        expect(find.text(stage.titleAr), findsOneWidget);
      }
    });

    testWidgets('a learner in A2 runs A2\'s mission, named as A2', (
      tester,
    ) async {
      final a2 = _a2Index.bundle.finalMission;
      final (l10n, _) = await _pump(
        tester,
        const FinalMissionScreen(),
        levelId: 'a2',
      );

      expect(find.text(a2.title), findsOneWidget);
      expect(find.text(mission.title), findsNothing);
      expect(find.text(l10n.testsMissionBody('A2')), findsOneWidget);
      expect(find.text(l10n.testsMissionBody('A1')), findsNothing);
      for (final stage in a2.stages) {
        expect(find.text(stage.title), findsOneWidget, reason: stage.title);
      }

      // It is not just the intro: starting it serves an A2 stage's task.
      await tester.tap(find.text(l10n.finalMissionStartButton));
      await tester.pumpAndSettle();
      final stage = a2.stages.first;
      expect(
        find.text(
          l10n
              .testQuestionEyebrow(stage.title, 1, stage.activityIds.length)
              .toUpperCase(),
        ),
        findsOneWidget,
      );
    });

    testWidgets('questions show their stage, and keep right/wrong feedback', (
      tester,
    ) async {
      final (l10n, _) = await _pump(tester, const FinalMissionScreen());
      await tester.tap(find.text(l10n.finalMissionStartButton));
      await tester.pumpAndSettle();

      final stage = mission.stages.first;
      expect(
        find.text(
          l10n
              .testQuestionEyebrow(stage.title, 1, stage.activityIds.length)
              .toUpperCase(),
        ),
        findsOneWidget,
      );
      await enterCorrectAnswer(tester, mission.activities.first);
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
      expect(find.text(l10n.activityFeedbackCorrect), findsOneWidget);
    });
  });

  group('placement test', () {
    testWidgets('the intro says what it covers and that answers are not '
        'marked; questions are saved, not marked', (tester) async {
      final (l10n, _) = await _pump(tester, const PlacementTestScreen());

      expect(find.text(l10n.placementCoversStops), findsOneWidget);
      expect(find.text(l10n.testRulesNote), findsOneWidget);

      await tester.tap(find.text(l10n.placementStartButton));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(l10n.learnUnitOverline(1).toUpperCase()),
        findsOneWidget,
      );
      final first = PlacementItemSampler.receptiveItemsForUnit(
        _index.bundle.units.first,
        seed: 999,
      ).first;
      await enterCorrectAnswer(tester, first);
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();
      expect(find.text(l10n.testAnswerSaved), findsOneWidget);
      expect(find.text(l10n.activityFeedbackCorrect), findsNothing);
    });
  });
}
