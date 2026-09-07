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

/// Regression test for the reported bug: A1-U0 could never reach
/// "Mastered" because two of its four required objectives had no gradable
/// evidence at all. This proves the *content-completeness* half of the
/// fix — that enough real mastery-mode evidence now exists per objective
/// to satisfy `minimumEvidencePerRequiredObjective` — given every such
/// attempt is answered correctly. Individual evaluator correctness (does
/// "a l i" actually match "Ali"?) is covered separately by
/// evaluator_test.dart; this test would stay green even if every
/// evaluator were replaced, as long as the evidence *count* per objective
/// holds.
void main() {
  test('A1-U0 is fully masterable once every mastery-mode activity is '
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
            createdAt: DateTime.utc(2026, 9, 7),
          ),
        );

    final json = File('assets/content/en/A1/a1-course-bundle.json')
        .readAsStringSync();
    final index = CourseContentIndex.build(CourseBundleParser.parse(json));
    final unit = index.unitsById['A1-U0']!;

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

  test("A1-U0's migrated evaluation rubrics parse to real structured specs, "
      'not the legacy-string null fallback', () async {
    final json = File('assets/content/en/A1/a1-course-bundle.json')
        .readAsStringSync();
    final index = CourseContentIndex.build(CourseBundleParser.parse(json));
    final l3a04 = index.lessonsById['A1-U0-L3']!.activities.firstWhere(
      (a) => a.id == 'A1-U0-L3-A04',
    );
    expect((l3a04 as dynamic).evaluation, isNotNull);
  });
}
