import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/data/drift_activity_attempt_repository.dart';
import 'package:mohingo/features/progress/data/drift_content_version_repository.dart';
import 'package:mohingo/features/progress/data/drift_learner_repository.dart';
import 'package:mohingo/features/progress/data/drift_unit_lesson_progress_repository.dart';
import 'package:mohingo/features/progress/domain/repositories/unit_lesson_progress_repository.dart';

void main() {
  late AppDatabase db;
  late int learnerId;
  late DriftActivityAttemptRepository attempts;
  late DriftUnitLessonProgressRepository progress;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    attempts = DriftActivityAttemptRepository(db);
    progress = DriftUnitLessonProgressRepository(db);
    learnerId = (await DriftLearnerRepository(db).getOrCreateLearner()).id;
  });

  tearDown(() => db.close());

  Future<void> answer(String activityId) => attempts.recordAttempt(
    learnerId: learnerId,
    activityId: activityId,
    lessonId: 'A2-U1-L1',
    sessionType: 'lesson',
    mode: ActivityMode.mastery,
    evidenceSkill: Skill.reading,
    canDoIds: const [],
    isCorrect: true,
    score: 1,
  );

  test('attemptedActivityLessons returns every activity this learner '
      'answered, once each, with the lesson it was answered in', () async {
    await answer('A2-U1-L1-A01');
    await answer('A2-U1-L1-A01');
    await answer('A2-U1-L2-A03');

    expect(await attempts.attemptedActivityLessons(learnerId: learnerId), {
      'A2-U1-L1-A01': 'A2-U1-L1',
      'A2-U1-L2-A03': 'A2-U1-L1',
    });
  });

  test('an activity answered in a review session keeps the lesson its other '
      'attempt recorded', () async {
    // Review records no lesson. If that attempt overwrote the lesson-bound
    // one, a content update could no longer place the learner's answer in a
    // unit, and the unit would quietly say nothing.
    await answer('A2-U1-L1-A01');
    await attempts.recordAttempt(
      learnerId: learnerId,
      activityId: 'A2-U1-L1-A01',
      sessionType: 'review',
      mode: ActivityMode.practice,
      evidenceSkill: Skill.reading,
      canDoIds: const [],
      isCorrect: true,
      score: 1,
    );

    expect(await attempts.attemptedActivityLessons(learnerId: learnerId), {
      'A2-U1-L1-A01': 'A2-U1-L1',
    });
  });

  test('an activity only ever answered outside a lesson is still recorded, '
      'with no lesson', () async {
    await attempts.recordAttempt(
      learnerId: learnerId,
      activityId: 'A2-FINAL-MISSION-A02',
      sessionType: 'finalMission',
      mode: ActivityMode.mastery,
      evidenceSkill: Skill.writing,
      canDoIds: const [],
    );

    expect(await attempts.attemptedActivityLessons(learnerId: learnerId), {
      'A2-FINAL-MISSION-A02': null,
    });
  });

  test("another learner's attempts are not this learner's", () async {
    await answer('A2-U1-L1-A01');
    final other = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: 'other',
            createdAt: DateTime.utc(2026),
          ),
        );

    expect(
      await attempts.attemptedActivityLessons(learnerId: other),
      isEmpty,
      reason: 'a shared device must not strand one learner on another\'s work',
    );
  });

  test(
    'marking units stale also clears the flag on units that are not',
    () async {
      for (final unitId in ['A2-U1', 'A2-U2']) {
        await progress.upsertUnitProgress(
          learnerId: learnerId,
          unitId: unitId,
          state: UnitProgressState.inProgress,
        );
      }

      Future<Map<String, bool>> flags() async => {
        for (final r in await progress.allUnitProgress(learnerId: learnerId))
          r.unitId: r.isContentStale,
      };

      await progress.markUnitsContentStale(
        learnerId: learnerId,
        unitIds: const {'A2-U1'},
      );
      expect(await flags(), {'A2-U1': true, 'A2-U2': false});

      // A later bundle restores what was missing: nothing is stale now, and
      // the flag must come back off rather than stick forever.
      await progress.markUnitsContentStale(
        learnerId: learnerId,
        unitIds: const {},
      );
      expect(await flags(), {'A2-U1': false, 'A2-U2': false});
    },
  );

  test('recomputing a unit\'s mastery does not clear its stale flag', () async {
    // MasteryAggregationService upserts unit progress constantly. If that
    // write reset the flag, a stale unit would announce itself once and
    // then go quiet the next time the learner touched anything.
    await progress.upsertUnitProgress(
      learnerId: learnerId,
      unitId: 'A2-U1',
      state: UnitProgressState.inProgress,
    );
    await progress.markUnitsContentStale(
      learnerId: learnerId,
      unitIds: const {'A2-U1'},
    );
    await progress.upsertUnitProgress(
      learnerId: learnerId,
      unitId: 'A2-U1',
      state: UnitProgressState.mastered,
      masteredAt: DateTime.utc(2026, 9, 21),
    );

    final row = await progress.unitProgress(
      learnerId: learnerId,
      unitId: 'A2-U1',
    );
    expect(row!.isContentStale, isTrue);
  });

  test('marking one learner stale leaves the other learner alone', () async {
    final other = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: 'other',
            createdAt: DateTime.utc(2026),
          ),
        );
    for (final id in [learnerId, other]) {
      await progress.upsertUnitProgress(
        learnerId: id,
        unitId: 'A2-U1',
        state: UnitProgressState.inProgress,
      );
    }

    await progress.markUnitsContentStale(
      learnerId: learnerId,
      unitIds: const {'A2-U1'},
    );

    final theirs = await progress.unitProgress(
      learnerId: other,
      unitId: 'A2-U1',
    );
    expect(theirs!.isContentStale, isFalse);
  });

  test('latest() returns the newer version even when both were installed in '
      'the same tick', () async {
    // A content upgrade writes its row moments after the app reads the
    // previous one. Ordering by installedAt alone ties on a fast clock, and
    // a tie that resolves the wrong way makes the diff compare a version
    // against itself — which reads exactly like "nothing changed".
    final versions = DriftContentVersionRepository(db);
    final sameInstant = DateTime.utc(2026, 9, 21, 12);
    for (final v in ['EN-A2-V1', 'EN-A2-V2']) {
      await db
          .into(db.contentVersions)
          .insert(
            ContentVersionsCompanion.insert(
              contentVersion: v,
              schemaVersion: '2.0.0',
              courseId: 'EN-A2-V1',
              installedAt: sameInstant,
              unitIdsJson: jsonEncode(const <String>[]),
              lessonIdsJson: jsonEncode(const <String>[]),
              activityIdsJson: jsonEncode(const <String>[]),
              canDoIdsJson: jsonEncode(const <String>[]),
            ),
          );
    }

    final latest = await versions.latest(courseId: 'EN-A2-V1');
    expect(latest!.contentVersion, 'EN-A2-V2');
  });
}
