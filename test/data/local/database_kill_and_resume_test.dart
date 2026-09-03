import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:uuid/uuid.dart';

/// Proves the "kill and resume" guarantee at the persistence layer: closing
/// a file-backed [AppDatabase] connection and reopening a fresh one against
/// the same file (standing in for the OS terminating and relaunching the
/// app — no device/emulator is available in this dev environment to test
/// the literal OS-level kill, see docs/TESTING.md) never loses or
/// duplicates recorded attempts.
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('mohingo_kill_resume_test');
    dbFile = File('${tempDir.path}/test.sqlite');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('attempts recorded before a simulated kill survive a fresh connection '
      'to the same file, with no duplicates', () async {
    final uuid = const Uuid();

    // "Session 1": app runs, learner answers 2 of a 4-activity lesson.
    var db = AppDatabase(NativeDatabase(dbFile));
    final learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: uuid.v4(),
            createdAt: DateTime.utc(2026, 9, 2),
          ),
        );

    for (final activityId in ['A1-U0-L1-A01', 'A1-U0-L1-A02']) {
      await db
          .into(db.activityAttempts)
          .insert(
            ActivityAttemptsCompanion.insert(
              uuid: uuid.v4(),
              learnerId: learnerId,
              activityId: activityId,
              sessionType: 'lesson',
              mode: 'mastery',
              evidenceSkill: 'listening',
              attemptedAt: DateTime.utc(2026, 9, 2),
              updatedAt: DateTime.utc(2026, 9, 2),
            ),
          );
    }
    await db
        .into(db.lessonProgress)
        .insert(
          LessonProgressCompanion.insert(
            uuid: uuid.v4(),
            learnerId: learnerId,
            lessonId: 'A1-U0-L1',
            unitId: 'A1-U0',
            state: 'inProgress',
            lastActivityId: const Value('A1-U0-L1-A02'),
            updatedAt: DateTime.utc(2026, 9, 2),
          ),
        );

    // Simulated kill: close the connection without any further writes,
    // exactly what happens when the OS terminates the process.
    await db.close();

    // "Session 2": app relaunches, opens a brand-new AppDatabase instance
    // against the same on-disk file.
    db = AppDatabase(NativeDatabase(dbFile));

    final priorAttempts = await db.select(db.activityAttempts).get();
    expect(
      priorAttempts.map((a) => a.activityId),
      unorderedEquals(['A1-U0-L1-A01', 'A1-U0-L1-A02']),
      reason: 'attempts from before the simulated kill must survive',
    );

    final resumedProgress = await (db.select(
      db.lessonProgress,
    )..where((t) => t.lessonId.equals('A1-U0-L1'))).getSingle();
    expect(resumedProgress.lastActivityId, 'A1-U0-L1-A02');

    // The learner finishes the remaining 2 activities in this new session.
    for (final activityId in ['A1-U0-L1-A03', 'A1-U0-L1-A04']) {
      await db
          .into(db.activityAttempts)
          .insert(
            ActivityAttemptsCompanion.insert(
              uuid: uuid.v4(),
              learnerId: learnerId,
              activityId: activityId,
              sessionType: 'lesson',
              mode: 'mastery',
              evidenceSkill: 'listening',
              attemptedAt: DateTime.utc(2026, 9, 2),
              updatedAt: DateTime.utc(2026, 9, 2),
            ),
          );
    }

    final allAttempts = await db.select(db.activityAttempts).get();
    expect(
      allAttempts.map((a) => a.activityId),
      unorderedEquals([
        'A1-U0-L1-A01',
        'A1-U0-L1-A02',
        'A1-U0-L1-A03',
        'A1-U0-L1-A04',
      ]),
      reason:
          'exactly 4 attempts total: none lost from before the kill, '
          'none duplicated, all 4 present after resuming',
    );

    await db.close();
  });
}
