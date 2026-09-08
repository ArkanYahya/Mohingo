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

/// Regression coverage for A1-U10's migration off opaque `evaluation`
/// strings onto structured `EvaluationSpec`s. Mirrors
/// a1_u0_mastery_regression_test.dart.
void main() {
  test('A1-U10 is fully masterable once every mastery-mode activity is '
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
    final unit = index.unitsById['A1-U10']!;

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

  test("A1-U10's migrated evaluation rubrics parse to real structured "
      'specs, not the legacy-string null fallback', () async {
    final json = File('assets/content/en/A1/a1-course-bundle.json')
        .readAsStringSync();
    final index = CourseContentIndex.build(CourseBundleParser.parse(json));

    for (final id in [
      'A1-U10-L1-A05',
      'A1-U10-L2-A05',
      'A1-U10-L3-A05',
      'A1-U10-L4-A05',
      'A1-U10-L5-A05',
      'A1-U10-L6-A05',
      'A1-U10-L7-A03',
      'A1-U10-L7-A05',
      'A1-U10-L7-A06',
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
