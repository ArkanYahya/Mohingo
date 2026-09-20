import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/lesson_player/presentation/lesson_player_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// A small, hand-authored 4-activity lesson — deliberately not the real A1
/// bundle, so the resume position can be asserted exactly without depending
/// on real content shape. See docs/TESTING.md.
Map<String, dynamic> _fixtureBundleJson() {
  Map<String, dynamic> gapActivity(
    String id, {
    String lessonId = 'A1-TEST-U1-L1',
  }) => {
    'id': id,
    'lessonId': lessonId,
    'type': 'gap',
    'mode': 'mastery',
    'skill': 'reading',
    'canDo': ['TEST.CANDO'],
    'prompt': 'p $id',
    'text': 'a ___ b',
    'options': ['x', 'y'],
    'answer': 'x',
  };

  // A second lesson whose last activity's rubric spells back an *earlier*
  // activity's answer — the shape that breaks if a mid-lesson resume skips
  // past the referenced activity without rehydrating its recorded answer.
  Map<String, dynamic> writeActivity(String id) => {
    'id': id,
    'lessonId': 'A1-TEST-U1-L2',
    'type': 'write',
    'mode': 'mastery',
    'skill': 'writing',
    'canDo': ['TEST.CANDO'],
    'prompt': 'p $id',
    'accepted': <String>[],
  };

  Map<String, dynamic> spellBackActivity(String id, String referencedId) => {
    ...writeActivity(id),
    'evaluation': {
      'type': 'letterSequence',
      'reference': 'previousAnswer:$referencedId',
    },
  };

  return {
    'schemaVersion': '2.0.0',
    'contentVersion': 'TEST-1',
    'locale': {
      'targetLanguage': 'en',
      'supportLanguage': 'ar',
      'direction': {'target': 'ltr', 'support': 'rtl'},
    },
    'course': {
      'id': 'EN-TEST',
      'title': 'Test',
      'titleAr': 'اختبار',
      'status': 'test',
      'finalMissionId': 'TEST-FINAL-MISSION',
      'finalAssessmentId': 'TEST-FINAL-ASSESSMENT',
    },
    'domain': {
      'CAN_DO': {'TEST': 'TEST.CANDO'},
      'MASTERY_POLICY': {
        'minimumObjectiveScore': 0.75,
        'minimumEvidencePerRequiredObjective': 2,
        'requireProductiveEvidenceWhereDeclared': true,
        'practiceCountsAsMastery': false,
        'allowSpeechFallbackToWriting': true,
        'speechCriteria': <String>[],
        'speechAccuracyWeight': 0.2,
      },
    },
    'grammar': <Map<String, dynamic>>[],
    'lexicon': <Map<String, dynamic>>[],
    'chunks': <Map<String, dynamic>>[],
    'units': [
      {
        'id': 'A1-TEST-U1',
        'title': 'Test Unit',
        'titleAr': 'وحدة',
        'levelRole': 'core',
        'estimatedMinutes': [5, 10],
        'countsTowardA1Mastery': true,
        'lessons': [
          {
            'id': 'A1-TEST-U1-L1',
            'title': 'Test Lesson',
            'titleAr': 'درس',
            'lessonType': 'practice',
            'canDo': ['TEST.CANDO'],
            'grammar': <String>[],
            'lexicon': <String>[],
            'chunks': <String>[],
            'activities': [
              gapActivity('A1'),
              gapActivity('A2'),
              gapActivity('A3'),
              gapActivity('A4'),
            ],
          },
          {
            'id': 'A1-TEST-U1-L2',
            'title': 'Spell-back Lesson',
            'titleAr': 'درس',
            'lessonType': 'practice',
            'canDo': ['TEST.CANDO'],
            'grammar': <String>[],
            'lexicon': <String>[],
            'chunks': <String>[],
            'activities': [
              writeActivity('B1'),
              gapActivity('B2', lessonId: 'A1-TEST-U1-L2'),
              spellBackActivity('B3', 'B1'),
              gapActivity('B4', lessonId: 'A1-TEST-U1-L2'),
            ],
          },
        ],
        'mastery': {
          'requiredObjectives': <String>[],
          'requiredSkillGroups': <List<String>>[],
          'minimumObjectiveScore': 0.75,
        },
      },
    ],
    'mediaSpecifications': <String, dynamic>{},
    'finalMission': {
      'id': 'TEST-FINAL-MISSION',
      'title': 'Mission',
      'titleAr': 'مهمة',
      'scenario': 'x',
      'canDo': <String>[],
      'stages': <Map<String, dynamic>>[],
      'activities': <Map<String, dynamic>>[],
      'scoring': {
        'requiredSkillGroups': <List<String>>[],
        'minimumCriterionScore': 0.6,
        'noSingleAverageCompensation': true,
      },
    },
    'finalAssessment': {
      'id': 'TEST-FINAL-ASSESSMENT',
      'title': 'Assessment',
      'titleAr': 'اختبار',
      'sourcePolicy': 'unseen',
      'sections': <String, dynamic>{},
      'scoring': {
        'decisionRule': {
          'required': <String>[],
          'noSingleOverallAverage': true,
        },
        'accessibility': {'fallbackDoesNotCreateSpeakingEvidence': true},
      },
    },
  };
}

CourseContentIndex _fixtureIndex() {
  final bundle = CourseBundleParser.parse(jsonEncode(_fixtureBundleJson()));
  return CourseContentIndex.build(bundle);
}

void main() {
  // Each test intentionally opens its own isolated in-memory AppDatabase —
  // Drift's "opened multiple times" dev-mode warning doesn't apply here.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
    'resumes right after the last completed activity, not from the start '
    '— simulating reopening the app mid-lesson',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final uuid = const Uuid();
      final learnerId = await db
          .into(db.learners)
          .insert(
            LearnersCompanion.insert(
              uuid: uuid.v4(),
              createdAt: DateTime.utc(2026, 9, 2),
            ),
          );
      // Learner already answered A1 and A2 in a prior "session".
      await db
          .into(db.lessonProgress)
          .insert(
            LessonProgressCompanion.insert(
              uuid: uuid.v4(),
              learnerId: learnerId,
              lessonId: 'A1-TEST-U1-L1',
              unitId: 'A1-TEST-U1',
              state: 'inProgress',
              lastActivityId: const Value('A2'),
              updatedAt: DateTime.utc(2026, 9, 2),
            ),
          );

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appDatabaseProvider.overrideWithValue(db),
            courseContentProvider('a1')
                .overrideWith((ref) async => _fixtureIndex()),
          ],
          child: MaterialApp(
            theme: AppTheme.light(AppColorSeed.calmTeal),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const LessonPlayerScreen(
              unitId: 'A1-TEST-U1',
              lessonId: 'A1-TEST-U1-L1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should resume at A3 (index 2 of 4), not restart at A1.
      expect(find.text('p A3'), findsOneWidget);
      expect(find.text('p A1'), findsNothing);
      expect(find.text('p A2'), findsNothing);
    },
  );

  testWidgets('a lesson previously completed (lastActivityId = final activity) '
      'replays from the start on reopen', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final uuid = const Uuid();
    final learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: uuid.v4(),
            createdAt: DateTime.utc(2026, 9, 2),
          ),
        );
    await db
        .into(db.lessonProgress)
        .insert(
          LessonProgressCompanion.insert(
            uuid: uuid.v4(),
            learnerId: learnerId,
            lessonId: 'A1-TEST-U1-L1',
            unitId: 'A1-TEST-U1',
            state: 'inProgress',
            lastActivityId: const Value('A4'), // the final activity
            updatedAt: DateTime.utc(2026, 9, 2),
          ),
        );

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider('a1')
              .overrideWith((ref) async => _fixtureIndex()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppColorSeed.calmTeal),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const LessonPlayerScreen(
            unitId: 'A1-TEST-U1',
            lessonId: 'A1-TEST-U1-L1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('p A1'), findsOneWidget);
  });

  testWidgets(
    'a resumed lesson rehydrates the skipped activities\' answers, so a '
    'later previousAnswer rubric still grades instead of dropping to '
    'notAutoGraded',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final uuid = const Uuid();
      final learnerId = await db
          .into(db.learners)
          .insert(
            LearnersCompanion.insert(
              uuid: uuid.v4(),
              createdAt: DateTime.utc(2026, 9, 2),
            ),
          );
      // A prior session: the learner answered B1 ("Ali") and B2, then left.
      await db
          .into(db.activityAttempts)
          .insert(
            ActivityAttemptsCompanion.insert(
              uuid: uuid.v4(),
              learnerId: learnerId,
              activityId: 'B1',
              lessonId: const Value('A1-TEST-U1-L2'),
              sessionType: 'lesson',
              mode: 'mastery',
              evidenceSkill: 'writing',
              rawAnswer: Value(jsonEncode('Ali')),
              attemptedAt: DateTime.utc(2026, 9, 2, 10),
              updatedAt: DateTime.utc(2026, 9, 2, 10),
            ),
          );
      await db
          .into(db.lessonProgress)
          .insert(
            LessonProgressCompanion.insert(
              uuid: uuid.v4(),
              learnerId: learnerId,
              lessonId: 'A1-TEST-U1-L2',
              unitId: 'A1-TEST-U1',
              state: 'inProgress',
              lastActivityId: const Value('B2'),
              updatedAt: DateTime.utc(2026, 9, 2),
            ),
          );

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appDatabaseProvider.overrideWithValue(db),
            courseContentProvider('a1')
                .overrideWith((ref) async => _fixtureIndex()),
          ],
          child: MaterialApp(
            theme: AppTheme.light(AppColorSeed.calmTeal),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const LessonPlayerScreen(
              unitId: 'A1-TEST-U1',
              lessonId: 'A1-TEST-U1-L2',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Resumed at B3 — B1's answer was never entered in *this* State.
      expect(find.text('p B3'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'a l i');
      await tester.pump();
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();

      final recorded = await (db.select(
        db.activityAttempts,
      )..where((t) => t.activityId.equals('B3'))).getSingle();
      // Without rehydration the reference resolves to nothing and this is
      // recorded as notAutoGraded (isCorrect == null).
      expect(recorded.isCorrect, isTrue);
    },
  );
}
