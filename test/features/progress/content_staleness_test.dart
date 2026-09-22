import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/bundle_asset_loader.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/progress/data/drift_activity_attempt_repository.dart';
import 'package:mohingo/features/progress/data/drift_learner_repository.dart';
import 'package:mohingo/features/progress/data/drift_unit_lesson_progress_repository.dart';
import 'package:mohingo/features/progress/domain/content_drift.dart';
import 'package:mohingo/features/progress/domain/repositories/unit_lesson_progress_repository.dart';
import 'package:mohingo/features/progress/providers/content_version_providers.dart';

/// Stale detection is only ever exercised on an **upgrade**, so testing it
/// on a fresh install proves nothing: with no prior row every diff is empty
/// by construction. These tests seed a real prior-version snapshot of the
/// shipped A2 bundle and then load the bundle itself — the same shape as
/// `test/data/local/database_test.dart` testing migrations against a
/// hand-built previous schema rather than against `onCreate`.
const _a2Asset = 'assets/content/en/A2/a2-course-bundle.json';

/// Reads the real bundles off disk, so what is loaded is what ships.
class _DiskLoader implements BundleAssetLoader {
  @override
  Future<String> load(String assetPath) async =>
      File(assetPath).readAsStringSync();
}

void main() {
  late AppDatabase db;
  late int learnerId;
  late DriftActivityAttemptRepository attempts;
  late DriftUnitLessonProgressRepository progress;

  final bundle = CourseBundleParser.parse(File(_a2Asset).readAsStringSync());
  final realActivityIds = <String>[
    for (final unit in bundle.units)
      for (final lesson in unit.lessons)
        for (final activity in lesson.activities) activity.id,
    for (final activity in bundle.finalMission.activities) activity.id,
    for (final activity in bundle.finalAssessment.allActivities) activity.id,
  ];
  final realCanDoIds = canDoIdsOf(bundle).toList();

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    attempts = DriftActivityAttemptRepository(db);
    progress = DriftUnitLessonProgressRepository(db);
    learnerId = (await DriftLearnerRepository(db).getOrCreateLearner()).id;
  });

  tearDown(() => db.close());

  /// Seeds the row a previous content version would have left behind.
  Future<void> seedPreviousVersion({
    required List<String> activityIds,
    required List<String> canDoIds,
  }) async {
    await db
        .into(db.contentVersions)
        .insert(
          ContentVersionsCompanion.insert(
            contentVersion: 'A2-PREVIOUS',
            schemaVersion: bundle.schemaVersion,
            courseId: bundle.course.id,
            installedAt: DateTime.utc(2026, 9, 1),
            unitIdsJson: jsonEncode([for (final u in bundle.units) u.id]),
            lessonIdsJson: jsonEncode([
              for (final u in bundle.units)
                for (final l in u.lessons) l.id,
            ]),
            activityIdsJson: jsonEncode(activityIds),
            canDoIdsJson: jsonEncode(canDoIds),
          ),
        );
  }

  Future<void> answer(String activityId, {String? lessonId}) =>
      attempts.recordAttempt(
        learnerId: learnerId,
        activityId: activityId,
        lessonId: lessonId,
        sessionType: 'lesson',
        mode: ActivityMode.mastery,
        evidenceSkill: Skill.reading,
        canDoIds: const [],
        isCorrect: true,
        score: 1,
      );

  Future<void> seedUnitProgress(List<String> unitIds) async {
    for (final unitId in unitIds) {
      await progress.upsertUnitProgress(
        learnerId: learnerId,
        unitId: unitId,
        state: UnitProgressState.mastered,
        masteredAt: DateTime.utc(2026, 9, 10),
      );
    }
  }

  Future<Set<String>> run() async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        bundleAssetLoaderProvider.overrideWithValue(_DiskLoader()),
      ],
    );
    addTearDown(container.dispose);
    return container.read(
      recordContentVersionAndFlagDriftProvider('a2').future,
    );
  }

  Future<Map<String, bool>> staleFlags() async => {
    for (final row in await progress.allUnitProgress(learnerId: learnerId))
      row.unitId: row.isContentStale,
  };

  test(
    'a fresh install records the bundle it loaded and flags nothing',
    () async {
      expect(await run(), isEmpty);

      final rows = await db.select(db.contentVersions).get();
      expect(rows, hasLength(1));
      expect(rows.single.courseId, bundle.course.id);
      expect(rows.single.contentVersion, bundle.contentVersion);
      expect(
        jsonDecode(rows.single.activityIdsJson),
        hasLength(realActivityIds.length),
        reason: 'content_versions was empty on every install before this',
      );
    },
  );

  test('loading the same version twice records one row, not two', () async {
    await run();
    await run();

    expect(await db.select(db.contentVersions).get(), hasLength(1));
  });

  test('an upgrade that removed an activity the learner answered flags that '
      'unit, and only that unit', () async {
    // This is also the ordering test. If recordIfNew ran before latest(),
    // the "previous" row read here would be the one just written — whose
    // contentVersion equals the bundle's — the early return would fire, and
    // nothing would ever be flagged on any device.
    const retired = 'A2-U1-L1-A99';
    await seedPreviousVersion(
      activityIds: [...realActivityIds, retired],
      canDoIds: realCanDoIds,
    );
    // Answered in A2-U1's first lesson, which the new bundle still has —
    // that lesson is what places their stranded answer in a unit.
    await answer(retired, lessonId: bundle.units.first.lessons.first.id);
    final u2Lesson = bundle.units[1].lessons.first;
    await answer(u2Lesson.activities.first.id, lessonId: u2Lesson.id);
    await seedUnitProgress(['A2-U1', 'A2-U2']);

    expect(await run(), {'A2-U1'});
    expect(await staleFlags(), {'A2-U1': true, 'A2-U2': false});
  });

  test(
    'a learner who never answered the removed activity is told nothing',
    () async {
      await seedPreviousVersion(
        activityIds: [...realActivityIds, 'A2-U1-L1-A99'],
        canDoIds: realCanDoIds,
      );
      await seedUnitProgress(['A2-U1']);

      expect(await run(), isEmpty);
      expect(await staleFlags(), {'A2-U1': false});
    },
  );

  test('a unit whose required objectives moved is stale even with every '
      'answer still in place', () async {
    // The update added an objective to A2-U3's mastery requirement: the bar
    // moved after the learner cleared it, which they deserve to know even
    // though nothing of theirs was lost.
    final u3 = bundle.units.firstWhere((u) => u.id == 'A2-U3');
    final addedObjective = u3.mastery.requiredObjectives.first;
    await seedPreviousVersion(
      activityIds: realActivityIds,
      canDoIds: realCanDoIds.where((id) => id != addedObjective).toList(),
    );
    await seedUnitProgress(['A2-U3', 'A2-U4']);

    final flagged = await run();
    expect(flagged, contains('A2-U3'));
    expect(flagged, isNot(contains('A2-U4')));
  });

  test('an upgrade that only added content flags nothing', () async {
    await seedPreviousVersion(
      // The previous version had one fewer activity and one fewer
      // objective. Content growing is a normal update.
      activityIds: realActivityIds.sublist(1),
      canDoIds: realCanDoIds,
    );
    await answer(
      realActivityIds.first,
      lessonId: bundle.units.first.lessons.first.id,
    );
    await seedUnitProgress(['A2-U1']);

    expect(await run(), isEmpty);
    expect(await staleFlags(), {'A2-U1': false});
  });

  test(
    'a later bundle that restores what was missing clears the flag',
    () async {
      const retired = 'A2-U1-L1-A99';
      await seedPreviousVersion(
        activityIds: [...realActivityIds, retired],
        canDoIds: realCanDoIds,
      );
      await answer(retired, lessonId: bundle.units.first.lessons.first.id);
      await seedUnitProgress(['A2-U1']);
      expect(await run(), {'A2-U1'});

      // A version after that one has the activity back. Nothing is stale now,
      // and the unit must stop saying so.
      await db.delete(db.contentVersions).go();
      await seedPreviousVersion(
        activityIds: realActivityIds,
        canDoIds: realCanDoIds,
      );
      expect(await run(), isEmpty);
      expect(await staleFlags(), {'A2-U1': false});
    },
  );
}
