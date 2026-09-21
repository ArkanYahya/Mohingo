import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/catalog/level_catalog.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/data/drift_activity_attempt_repository.dart';
import 'package:mohingo/features/progress/data/drift_unit_lesson_progress_repository.dart';
import 'package:mohingo/features/progress/domain/mastery_aggregation_service.dart';

import 'a2_capstone_checks.dart';
import 'a2_finished_units.dart';

void main() {
  test('answering every mastery item correctly masters the unit', () async {
    // Drives the real MasteryAggregationService instead of re-implementing
    // its rule — a hand-rolled "every required objective is mentioned by at
    // least one mastery activity" check is membership, not the app's actual
    // count-based rule (>= MasteryPolicy.minimumEvidencePerRequiredObjective
    // qualifying attempts per objective, plus skill-group coverage). That
    // gap is exactly what let A1-U6 ship with one objective carried by a
    // single mastery-mode activity — one short of the required two — so the
    // unit could never reach Mastered. See
    // a1_u6_mastery_regression_test.dart, whose doc comment tells that
    // story and which this test mirrors.
    final masteryPolicy = loadA2Bundle().domain.masteryPolicy;

    for (final unit in finishedA2Units()) {
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

      for (final a in activitiesOf(unit)) {
        if (a.mode != ActivityMode.mastery) continue;
        await attemptRepository.recordAttempt(
          learnerId: learnerId,
          activityId: a.id,
          lessonId: a.lessonId,
          sessionType: 'lesson',
          mode: a.mode,
          evidenceSkill: a.skill,
          canDoIds: a.canDo,
          isCorrect: true,
          score: 1.0,
        );
      }

      final result = await service.evaluateUnit(
        learnerId: learnerId,
        unit: unit,
        masteryPolicy: masteryPolicy,
      );

      expect(
        result.isMastered,
        isTrue,
        reason:
            '${unit.id} unmastered objectives: '
            '${result.unmasteredObjectiveIds}; missing skill groups: '
            '${result.missingSkillGroups}',
      );
    }
  });

  test('the finished list names real, distinct units', () {
    // Always live: a duplicate or a typo here would otherwise only surface
    // on release day, when the release gate finally runs.
    expect(
      a2FinishedUnitIds.toSet().length,
      a2FinishedUnitIds.length,
      reason: 'a2FinishedUnitIds contains a duplicate',
    );
    final bundleUnitIds = {for (final u in loadA2Bundle().units) u.id};
    expect(bundleUnitIds.containsAll(a2FinishedUnitIds), isTrue);
  });

  test('A2 stays a preview until every unit is finished and both capstones '
      'pass their gates', () {
    final a2 = kLevelCatalog.firstWhere((e) => e.levelId == 'a2');
    if (a2.availability != LevelAvailability.available) return;
    final bundle = loadA2Bundle();
    final bundleUnitIds = {for (final u in bundle.units) u.id};
    expect(
      a2FinishedUnitIds.toSet(),
      bundleUnitIds,
      reason:
          'A2 is marked available, but the finished list is not every '
          'unit in the bundle',
    );

    // Counting units is not enough. A2's exits are its Final Mission and its
    // Final Assessment, and neither is a unit — so the check above would let
    // A2 go live with twelve finished units behind two skeleton capstones.
    // Re-run the real capstone rules here rather than restating them: they
    // are the same functions `a2_capstones_test.dart` runs gate by gate, so
    // this can never pass on a rule that file no longer enforces.
    expect(
      allCapstoneViolations(bundle),
      isEmpty,
      reason:
          'A2 is marked available, but its capstones break these rules:\n'
          '${allCapstoneViolations(bundle).join('\n')}',
    );

    // And the focused suite itself must still be there. Without this, the
    // capstone gates could be deleted wholesale and release day would only
    // notice the combined check above — which would still run, but nobody
    // would be told which gate had gone missing from day-to-day CI.
    expect(
      File('test/content/a2_capstones_test.dart').existsSync(),
      isTrue,
      reason:
          'the A2 capstone gate suite has been deleted; A2 cannot be marked '
          'available without it',
    );
  });
}
