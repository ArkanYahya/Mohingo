import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mohingo/content/catalog/level_catalog.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/learning_path/presentation/course_screen.dart';
import 'package:mohingo/features/learning_path/presentation/widgets/level_strip.dart';
import 'package:mohingo/features/progress/data/drift_learner_repository.dart';
import 'package:mohingo/features/progress/domain/level_access.dart';
import 'package:mohingo/features/progress/providers/level_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../content/fixtures/minimal_bundle.dart';

final _index = CourseContentIndex.build(
  CourseBundleParser.parse(
    File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
  ),
);

final _a2Index = CourseContentIndex.build(
  CourseBundleParser.parse(jsonEncode(minimalBundleJson(level: 'A2'))),
);

/// With [midCourse]: Unit 1 (A1-U0) mastered, and in A1-U1 the first two
/// lessons finished and the third started. Otherwise a brand-new learner.
Future<AppDatabase> _seed({required bool midCourse}) async {
  final db = AppDatabase(NativeDatabase.memory());
  final learner = await db
      .into(db.learners)
      .insert(
        LearnersCompanion.insert(uuid: 'l', createdAt: DateTime.utc(2026)),
      );
  if (!midCourse) return db;
  final now = DateTime.utc(2026, 9, 18);
  await db
      .into(db.unitProgress)
      .insert(
        UnitProgressCompanion.insert(
          uuid: 'u0',
          learnerId: learner,
          unitId: 'A1-U0',
          state: 'mastered',
          updatedAt: now,
        ),
      );
  final u1 = _index.unitsById['A1-U1']!;
  for (final (i, finished) in [(0, true), (1, true), (2, false)]) {
    final lesson = u1.lessons[i];
    await db
        .into(db.lessonProgress)
        .insert(
          LessonProgressCompanion.insert(
            uuid: 'lp$i',
            learnerId: learner,
            lessonId: lesson.id,
            unitId: 'A1-U1',
            state: finished ? 'completed' : 'inProgress',
            lastActivityId: Value(
              finished ? lesson.activities.last.id : lesson.activities.first.id,
            ),
            lastPositionUpdatedAt: Value(now.add(Duration(minutes: i))),
            updatedAt: now,
          ),
        );
  }
  return db;
}

/// Three-entry catalogue matching the brief: A1 available, A2 available
/// (or [LevelAvailability.preview] when its id is in [previewLevelIds])
/// building on A1, B1 with no content yet.
List<LevelCatalogEntry> _catalog({required Set<String> previewLevelIds}) => [
  const LevelCatalogEntry(
    levelId: 'a1',
    cefrCode: 'A1',
    availability: LevelAvailability.available,
    bundleAssetPath: 'a1.json',
  ),
  LevelCatalogEntry(
    levelId: 'a2',
    cefrCode: 'A2',
    availability: previewLevelIds.contains('a2')
        ? LevelAvailability.preview
        : LevelAvailability.available,
    bundleAssetPath: 'a2.json',
    prerequisiteLevelId: 'a1',
  ),
  const LevelCatalogEntry(
    levelId: 'b1',
    cefrCode: 'B1',
    availability: LevelAvailability.comingSoon,
  ),
];

/// Pumps the course screen under a [ProviderContainer] the test can read
/// directly, standing up A2 (`Test A2`, from [minimalBundleJson]) alongside
/// A1 so the level strip has something real to switch to.
///
/// [unlockedLevelIds] enrols and unlocks the learner in each named level
/// before pumping, the way `LevelSelectionController.unlock` would.
/// [previewLevelIds] demotes A2's catalogue entry to
/// [LevelAvailability.preview] instead of the default `available`.
Future<(ProviderContainer, AppLocalizations)> _pump(
  WidgetTester tester, {
  bool midCourse = true,
  Set<String> unlockedLevelIds = const {},
  Set<String> previewLevelIds = const {},
  bool a2Fails = false,
}) async {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final db = await _seed(midCourse: midCourse);
  addTearDown(db.close);
  if (unlockedLevelIds.isNotEmpty) {
    final learner = await db.select(db.learners).getSingle();
    final repository = DriftLearnerRepository(db);
    final indexByLevelId = {'a1': _index, 'a2': _a2Index};
    for (final levelId in unlockedLevelIds) {
      final index = indexByLevelId[levelId]!;
      await repository.ensureEnrolled(
        learnerId: learner.id,
        levelId: levelId,
        courseId: index.bundle.course.id,
        contentVersion: index.bundle.contentVersion,
      );
      await repository.markLevelUnlocked(
        learnerId: learner.id,
        levelId: levelId,
      );
    }
  }
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: '/learn',
    routes: [
      GoRoute(path: '/learn', builder: (_, _) => const CourseScreen()),
      GoRoute(
        path: '/learn/unit/:unitId',
        builder: (_, s) => Text('UNIT ${s.pathParameters['unitId']}'),
      ),
      GoRoute(
        path: '/lesson-player/:unitId/:lessonId',
        builder: (_, s) => Text(
          'PLAYER ${s.pathParameters['unitId']} ${s.pathParameters['lessonId']}',
        ),
      ),
      GoRoute(path: '/tests', builder: (_, _) => const Text('TESTS')),
    ],
  );
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWithValue(db),
      levelCatalogProvider.overrideWithValue(
        _catalog(previewLevelIds: previewLevelIds),
      ),
      courseContentProvider('a1').overrideWith((ref) async => _index),
      courseContentProvider('a2').overrideWith(
        (ref) async => a2Fails ? throw StateError('bad bundle') : _a2Index,
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light(AppColorSeed.calmTeal),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  final l10n = AppLocalizations.of(tester.element(find.byType(CourseScreen)))!;
  return (container, l10n);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('opens on the course: its title in English and Arabic, units '
      'mastered over total, and every unit on the path', (tester) async {
    final (_, l10n) = await _pump(tester);

    expect(find.text('English A1'), findsOneWidget);
    expect(find.text(_index.bundle.course.titleAr), findsOneWidget);
    expect(find.text(l10n.homeLevelProgressCaption(1, 13)), findsOneWidget);
    for (final unit in _index.bundle.units) {
      expect(find.text(unit.title), findsOneWidget, reason: unit.id);
    }
  });

  testWidgets('the unit being worked on is the one highlighted card — its '
      'lessons done, the next lesson, and Continue lesson opens the player', (
    tester,
  ) async {
    final (_, l10n) = await _pump(tester);

    expect(
      find.text(l10n.learnUnitInProgressOverline(2).toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(l10n.learnUnitLessonsDone(2, 7)), findsOneWidget);
    expect(
      find.textContaining(_index.lessonsById['A1-U1-L3']!.title),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.homeContinueLessonCta));
    await tester.pumpAndSettle();
    expect(find.text('PLAYER A1-U1 A1-U1-L3'), findsOneWidget);
  });

  testWidgets('a new learner starts on the first unit, with Start lesson', (
    tester,
  ) async {
    final (_, l10n) = await _pump(tester, midCourse: false);

    expect(
      find.text(l10n.learnUnitStartHereOverline(1).toUpperCase()),
      findsOneWidget,
    );
    await tester.tap(find.text(l10n.homeStartLessonCta));
    await tester.pumpAndSettle();
    expect(find.text('PLAYER A1-U0 A1-U0-L1'), findsOneWidget);
  });

  testWidgets('a mastered unit says so; a unit not started shows its size '
      'and time; the starter unit is tagged', (tester) async {
    final (_, l10n) = await _pump(tester);

    expect(find.text(l10n.unitStateMastered), findsOneWidget);
    expect(find.text(l10n.learnUnitStarter.toUpperCase()), findsOneWidget);
    final u2 = _index.unitsById['A1-U2']!;
    expect(
      find.text(
        '${l10n.learnLessonCount(u2.lessons.length)} · '
        '${l10n.learnUnitMinutes(u2.estimatedMinutes[0], u2.estimatedMinutes[1])}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('each unit\'s circle is announced with its number and state', (
    tester,
  ) async {
    final (_, l10n) = await _pump(tester);

    expect(
      find.bySemanticsLabel(
        l10n.learnUnitNodeSemantics(1, l10n.unitStateMastered),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        l10n.learnUnitNodeSemantics(3, l10n.unitStateNotStarted),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping a unit opens its unit page', (tester) async {
    await _pump(tester);

    await tester.tap(find.text(_index.unitsById['A1-U3']!.title));
    await tester.pumpAndSettle();
    expect(find.text('UNIT A1-U3'), findsOneWidget);
  });

  testWidgets('the path ends at the final mission & assessment, which opens '
      'the Tests tab', (tester) async {
    final (_, l10n) = await _pump(tester);

    await tester.tap(find.text(l10n.learnFinishTitle));
    await tester.pumpAndSettle();
    expect(find.text('TESTS'), findsOneWidget);
  });

  testWidgets('the level switcher carries only the levels that exist, and '
      'marks which is current', (tester) async {
    final (_, l10n) = await _pump(tester);

    expect(find.byType(LevelStrip), findsOneWidget);
    expect(
      find.bySemanticsLabel(l10n.learnLevelSemanticsCurrent('A1')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(l10n.learnLevelSemanticsLocked('A2')),
      findsOneWidget,
    );
    // B1 has no content, so it is not a segment: the caption is what
    // tells the learner more levels are coming.
    expect(find.text('B1'), findsNothing);
    expect(find.text(l10n.learnLevelComingLaterBody('A1')), findsOneWidget);
  });

  testWidgets('a level counts only its own units as mastered', (tester) async {
    final (_, l10n) = await _pump(tester, unlockedLevelIds: const {'a2'});

    await tester.tap(find.text('A2'));
    await tester.pumpAndSettle();

    // A1-U0 is mastered; A2 has one unit and no progress at all.
    expect(find.text(l10n.homeLevelProgressCaption(0, 1)), findsOneWidget);
  });

  testWidgets('tapping an open level switches the course page to it', (
    tester,
  ) async {
    final (_, l10n) = await _pump(tester, unlockedLevelIds: const {'a2'});

    await tester.tap(find.text('A2'));
    await tester.pumpAndSettle();

    expect(find.text('Test A2'), findsOneWidget);
    expect(
      find.bySemanticsLabel(l10n.learnLevelSemanticsCurrent('A2')),
      findsOneWidget,
    );
  });

  testWidgets('tapping a locked level explains it and offers the placement '
      'test or opening it anyway', (tester) async {
    final (container, l10n) = await _pump(tester);
    String iso(String s) => '\u2068$s\u2069';

    await tester.tap(find.text('A2'));
    await tester.pumpAndSettle();

    expect(
      find.text(l10n.levelLockTitle(iso('A2'), iso('A1'))),
      findsOneWidget,
    );
    expect(find.text(l10n.levelLockTakeTest), findsOneWidget);

    await tester.tap(find.text(l10n.levelLockOpenAnyway('A2')));
    await tester.pumpAndSettle();

    expect(find.text('Test A2'), findsOneWidget);
    expect(find.text(l10n.levelLockTakeTest), findsNothing);

    // The assertions above would still pass if "Open anyway" only switched
    // into A2 without truly unlocking it first — the shown level's segment
    // reads as current regardless of its real access, and switching alone
    // moves the course page. Read A2's access straight from the provider
    // to confirm `unlock` actually ran, not just `select`.
    expect(container.read(levelAccessProvider('a2')).value, LevelAccess.open);
  });

  testWidgets('a level the app has not released can be looked at but not '
      'opened', (tester) async {
    final (container, l10n) = await _pump(
      tester,
      previewLevelIds: const {'a2'},
    );

    await tester.tap(find.text('A2'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.levelNotReleasedTitle('A2')), findsOneWidget);
    expect(find.text(l10n.levelLockOpenAnyway('A2')), findsNothing);

    await tester.tap(find.text(l10n.levelNotReleasedBrowse('A2')));
    await tester.pumpAndSettle();

    // Its units are listed, with the banner, and nothing starts a lesson.
    expect(find.text(l10n.learnPreviewBannerTitle('A2')), findsOneWidget);
    expect(find.text('Unit 1'), findsOneWidget);
    expect(find.text(l10n.homeStartLessonCta), findsNothing);
    expect(find.text(l10n.homeContinueLessonCta), findsNothing);

    // Browsing never changes which level the learner is in.
    expect(await container.read(currentLevelIdProvider.future), 'a1');
  });

  testWidgets('a level that fails to load still lets the learner back out', (
    tester,
  ) async {
    final (_, l10n) = await _pump(
      tester,
      previewLevelIds: const {'a2'},
      a2Fails: true,
    );

    await tester.tap(find.text('A2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.levelNotReleasedBrowse('A2')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.contentErrorTitle), findsOneWidget);

    await tester.tap(find.text(l10n.learnPreviewBackToCurrent('A1')));
    await tester.pumpAndSettle();

    // Back on their own level, which loads fine.
    expect(find.text(_index.bundle.course.title), findsOneWidget);
    expect(find.text(l10n.contentErrorTitle), findsNothing);
  });

  testWidgets('leaving the preview returns to the level being learned', (
    tester,
  ) async {
    final (container, l10n) = await _pump(
      tester,
      previewLevelIds: const {'a2'},
    );

    await tester.tap(find.text('A2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.levelNotReleasedBrowse('A2')));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.learnPreviewBackToCurrent('A1')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.learnPreviewBannerTitle('A2')), findsNothing);
  });

  testWidgets('browsing an unreleased level never claims the learner moved '
      'into it', (tester) async {
    final (container, l10n) = await _pump(
      tester,
      previewLevelIds: const {'a2'},
    );

    await tester.tap(find.text('A2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.levelNotReleasedBrowse('A2')));
    await tester.pumpAndSettle();

    // The preview is on screen...
    expect(find.text(l10n.learnPreviewBannerTitle('A2')), findsOneWidget);
    // ...but the switcher still says which level they are in, and says so
    // to a screen reader too.
    expect(
      find.bySemanticsLabel(l10n.learnLevelSemanticsCurrent('A1')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(l10n.learnLevelSemanticsCurrent('A2')),
      findsNothing,
    );
    expect(find.text(l10n.learnLevelComingLaterBody('A1')), findsOneWidget);
    expect(await container.read(currentLevelIdProvider.future), 'a1');
  });

  testWidgets('a preview is not called "your course"', (tester) async {
    final (_, l10n) = await _pump(tester, previewLevelIds: const {'a2'});

    final overline = find.text(l10n.learnCourseOverline.toUpperCase());
    expect(overline, findsOneWidget);

    await tester.tap(find.text('A2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.levelNotReleasedBrowse('A2')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.learnPreviewBannerTitle('A2')), findsOneWidget);
    expect(overline, findsNothing);
  });
}
