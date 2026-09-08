import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/data/drift_activity_attempt_repository.dart';
import 'package:mohingo/features/progress/data/drift_unit_lesson_progress_repository.dart';
import 'package:mohingo/features/progress/domain/mastery_aggregation_service.dart';

/// Regression coverage for A1-U8's migration off opaque `evaluation`
/// strings onto structured `EvaluationSpec`s. Mirrors
/// a1_u0_mastery_regression_test.dart.
///
/// Also proves a content-completeness fix, the same class of bug as U0's
/// original REGISTER_FOR_CLASS gap and U6's MEDIATION.COMPLETE_MEAL_MISSION
/// gap: `A1.U8.MEDIATION.GUIDE_VISITOR` had exactly one mastery-mode
/// activity carrying it (A1-U8-L7-A05) — one short of
/// `minimumEvidencePerRequiredObjective` (2). Fixed by adding
/// `A1.U8.MEDIATION.GUIDE_VISITOR` to A1-U8-L7-A06's canDo list, mirroring
/// every sibling unit's mission-writing activity.
void main() {
  test('A1-U8 is fully masterable once every mastery-mode activity is '
      'answered correctly', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final attemptRepository = DriftActivityAttemptRepository(db);
    final progressRepository = DriftUnitLessonProgressRepository(db);
    final service = MasteryAggregationService(
      attemptRepository: attemptRepository,
      progressRepository: progressRepository,
    );

    final learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: 'learner-1',
            createdAt: DateTime.utc(2026, 9, 8),
          ),
        );

    final json = File('assets/content/en/A1/a1-course-bundle.json')
        .readAsStringSync();
    final index = CourseContentIndex.build(CourseBundleParser.parse(json));
    final unit = index.unitsById['A1-U8']!;

    for (final lesson in unit.lessons) {
      for (final activity in lesson.activities) {
        if (activity.mode != ActivityMode.mastery) continue;
        await attemptRepository.recordAttempt(
          learnerId: learnerId,
          activityId: activity.id,
          lessonId: lesson.id,
          sessionType: 'lesson',
          mode: activity.mode,
          evidenceSkill: activity.skill,
          canDoIds: activity.canDo,
          isCorrect: true,
          score: 1.0,
        );
      }
    }

    final result = await service.evaluateUnit(
      learnerId: learnerId,
      unit: unit,
      masteryPolicy: index.bundle.domain.masteryPolicy,
    );

    expect(
      result.isMastered,
      isTrue,
      reason: 'unmastered objectives: ${result.unmasteredObjectiveIds}',
    );
  });

  test('A1.U8.MEDIATION.GUIDE_VISITOR has 2 real mastery-mode evidence '
      'sources, not 1', () async {
    final json = File('assets/content/en/A1/a1-course-bundle.json')
        .readAsStringSync();
    final index = CourseContentIndex.build(CourseBundleParser.parse(json));
    final unit = index.unitsById['A1-U8']!;

    final carriers = [
      for (final lesson in unit.lessons)
        for (final activity in lesson.activities)
          if (activity.mode == ActivityMode.mastery &&
              activity.canDo.contains('A1.U8.MEDIATION.GUIDE_VISITOR'))
            activity.id,
    ];

    expect(carriers.length, greaterThanOrEqualTo(2), reason: '$carriers');
  });

  test("A1-U8's migrated evaluation rubrics parse to real structured specs, "
      'not the legacy-string null fallback', () async {
    final json = File('assets/content/en/A1/a1-course-bundle.json')
        .readAsStringSync();
    final index = CourseContentIndex.build(CourseBundleParser.parse(json));

    for (final id in [
      'A1-U8-L1-A05',
      'A1-U8-L2-A05',
      'A1-U8-L3-A05',
      'A1-U8-L4-A05',
      'A1-U8-L5-A05',
      'A1-U8-L6-A05',
      'A1-U8-L7-A03',
      'A1-U8-L7-A04',
      'A1-U8-L7-A05',
      'A1-U8-L7-A06',
    ]) {
      final lessonId = id.substring(0, id.lastIndexOf('-'));
      final activity = index.lessonsById[lessonId]!.activities.firstWhere(
        (a) => a.id == id,
      );
      expect(
        (activity as dynamic).evaluation,
        isNotNull,
        reason: '$id should carry a structured EvaluationSpec',
      );
    }
  });
}
