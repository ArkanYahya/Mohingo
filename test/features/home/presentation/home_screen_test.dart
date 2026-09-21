import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:mohingo/content/catalog/level_catalog.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/core/theme/feedback_theme_extension.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/home/domain/day_part.dart';
import 'package:mohingo/features/home/presentation/home_screen.dart';
import 'package:mohingo/features/home/presentation/widgets/continue_lesson_card.dart';
import 'package:mohingo/features/home/presentation/widgets/daily_goal_section.dart';
import 'package:mohingo/features/home/presentation/widgets/home_header.dart';
import 'package:mohingo/features/home/presentation/widgets/journey_card.dart';
import 'package:mohingo/features/progress/data/drift_learner_repository.dart';
import 'package:mohingo/features/progress/domain/repositories/daily_task_event_repository.dart';
import 'package:mohingo/features/progress/providers/level_providers.dart';

final CourseContentIndex _index = CourseContentIndex.build(
  CourseBundleParser.parse(
    File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
  ),
);

final CourseContentIndex _a2Index = CourseContentIndex.build(
  CourseBundleParser.parse(
    File('assets/content/en/A2/a2-course-bundle.json').readAsStringSync(),
  ),
);

/// The shipped catalogue with A2 demoted to a level the app hasn't released
/// — what Home saw before A2 shipped, and what it will see again the first
/// time B1's content lands ahead of B1's release.
final _a2NotReleasedCatalog = [
  const LevelCatalogEntry(
    levelId: 'a1',
    cefrCode: 'A1',
    availability: LevelAvailability.available,
    bundleAssetPath: 'a1.json',
  ),
  const LevelCatalogEntry(
    levelId: 'a2',
    cefrCode: 'A2',
    availability: LevelAvailability.preview,
    bundleAssetPath: 'a2.json',
    prerequisiteLevelId: 'a1',
  ),
];

GoRouter _router() => GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: '/lesson-player/:unitId/:lessonId',
      builder: (_, state) => Scaffold(
        body: Text(
          'PLAYER ${state.pathParameters['unitId']} '
          '${state.pathParameters['lessonId']}',
        ),
      ),
    ),
    GoRoute(
      path: '/learn/unit/:unitId',
      builder: (_, state) =>
          Scaffold(body: Text('UNIT ${state.pathParameters['unitId']}')),
    ),
    GoRoute(
      path: '/learn',
      builder: (_, _) => const Scaffold(body: Text('LEARN')),
    ),
    GoRoute(
      path: '/review',
      builder: (_, _) => const Scaffold(body: Text('REVIEW')),
    ),
    GoRoute(
      path: '/tests',
      builder: (_, _) => const Scaffold(body: Text('TESTS')),
    ),
  ],
);

/// Pumps Home for a learner in [levelId] — enrolling and selecting anything
/// but the base level first, the way `LevelSelectionController.select`
/// would, so `currentLevelIdProvider` resolves to it. [catalog] replaces the
/// shipped level catalogue.
Future<void> _pumpHome(
  WidgetTester tester,
  AppDatabase db, {
  Locale locale = const Locale('en'),
  double textScale = 1,
  double width = 390,
  double height = 1400,
  String levelId = 'a1',
  List<LevelCatalogEntry>? catalog,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  if (levelId != 'a1') {
    final index = {'a2': _a2Index}[levelId]!;
    final learner = await db.select(db.learners).getSingle();
    final repository = DriftLearnerRepository(db);
    await repository.ensureEnrolled(
      learnerId: learner.id,
      levelId: levelId,
      courseId: index.bundle.course.id,
      contentVersion: index.bundle.contentVersion,
    );
    await repository.markLevelSelected(learnerId: learner.id, levelId: levelId);
  }

  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
        if (catalog != null) levelCatalogProvider.overrideWithValue(catalog),
        courseContentProvider('a1').overrideWith((ref) async => _index),
        courseContentProvider('a2').overrideWith((ref) async => _a2Index),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(AppColorSeed.calmTeal),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: _router(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<int> _learner(AppDatabase db, {String? name}) {
  return db
      .into(db.learners)
      .insert(
        LearnersCompanion.insert(
          uuid: 'learner-1',
          name: Value(name),
          createdAt: DateTime.utc(2026, 9, 1),
        ),
      );
}

Future<void> _lessonPosition(
  AppDatabase db,
  int learnerId, {
  required String unitId,
  required String lessonId,
  required String lastActivityId,
}) async {
  final now = DateTime.now();
  await db
      .into(db.lessonProgress)
      .insert(
        LessonProgressCompanion.insert(
          uuid: const Uuid().v4(),
          learnerId: learnerId,
          lessonId: lessonId,
          unitId: unitId,
          state: 'inProgress',
          lastActivityId: Value(lastActivityId),
          lastPositionUpdatedAt: Value(now),
          updatedAt: now,
        ),
      );
}

/// Marks every unit of [index] mastered \u2014 a learner who has finished the
/// level, which is what opens the level after it.
Future<void> _masterEveryUnit(
  AppDatabase db,
  int learnerId,
  CourseContentIndex index,
) async {
  final now = DateTime.now();
  for (final unit in index.bundle.units) {
    await db
        .into(db.unitProgress)
        .insert(
          UnitProgressCompanion.insert(
            uuid: const Uuid().v4(),
            learnerId: learnerId,
            unitId: unit.id,
            state: 'mastered',
            updatedAt: now,
          ),
        );
  }
}

/// Unit titles are wrapped in Unicode first-strong isolates on Home, so an
/// English title keeps its own direction inside an Arabic sentence.
String _isolated(String s) => '\u2068$s\u2069';

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(HomeScreen)))!;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('header', () {
    testWidgets('greets the learner by name, with level and streak as small '
        'chips — no oversized "Home" title bar, no streak card', (
      tester,
    ) async {
      await _learner(db, name: 'Arkan');
      await _pumpHome(tester, db);
      final l10n = _l10n(tester);

      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Arkan'), findsOneWidget);
      final greeting = switch (dayPartFor(DateTime.now().hour)) {
        DayPart.morning => l10n.homeGreetingMorning,
        DayPart.afternoon => l10n.homeGreetingAfternoon,
        DayPart.evening => l10n.homeGreetingEvening,
      };
      expect(find.text(greeting), findsOneWidget);
      expect(
        find.text(l10n.homeLevelBadge('A1', l10n.cefrDescriptorA1)),
        findsOneWidget,
      );
      expect(find.text(l10n.homeStreakChip(0)), findsOneWidget);
    });

    testWidgets('works without a name — the greeting alone becomes the '
        'headline', (tester) async {
      await _learner(db);
      await _pumpHome(tester, db);

      expect(find.byType(HomeHeader), findsOneWidget);
      final header = tester.widget<HomeHeader>(find.byType(HomeHeader));
      expect(header.name, isNull);
      expect(find.text('Arkan'), findsNothing);
    });

    testWidgets('an active streak shows its day count', (tester) async {
      final learnerId = await _learner(db);
      final now = DateTime.now();
      await db
          .into(db.activityAttempts)
          .insert(
            ActivityAttemptsCompanion.insert(
              uuid: 'a1',
              learnerId: learnerId,
              activityId: 'A1-U0-L1-A01',
              sessionType: 'lesson',
              mode: 'practice',
              evidenceSkill: 'listening',
              attemptedAt: now,
              updatedAt: now,
            ),
          );
      await _pumpHome(tester, db);

      expect(find.text(_l10n(tester).homeStreakChip(1)), findsOneWidget);
    });
  });

  group('continue-lesson hero', () {
    testWidgets('with no progress it offers the very first lesson — unit and '
        'lesson position, English title, Arabic support, a "Start lesson" '
        'CTA, and "New lesson" instead of a 0%', (tester) async {
      await _learner(db);
      await _pumpHome(tester, db);
      final l10n = _l10n(tester);
      final lesson = _index.unitsById['A1-U0']!.lessons.first;

      expect(
        find.text(l10n.homeUnitLessonOverline(1, 1).toUpperCase()),
        findsOneWidget,
      );
      expect(find.text(lesson.title), findsOneWidget);
      expect(find.text(lesson.titleAr), findsOneWidget);
      expect(find.text(l10n.homeLessonNew), findsOneWidget);
      expect(find.text(l10n.homeStartLessonCta), findsOneWidget);
    });

    testWidgets('the Arabic support line is laid out right-to-left even in '
        'the English interface', (tester) async {
      await _learner(db);
      await _pumpHome(tester, db);
      final lesson = _index.unitsById['A1-U0']!.lessons.first;

      final arabic = tester.widget<Text>(find.text(lesson.titleAr));
      expect(arabic.textDirection, TextDirection.rtl);
    });

    testWidgets('part-way through a lesson it says so — percentage, and '
        '"Continue lesson"', (tester) async {
      final learnerId = await _learner(db);
      final lesson = _index.unitsById['A1-U0']!.lessons.first;
      expect(lesson.activities, hasLength(4));
      await _lessonPosition(
        db,
        learnerId,
        unitId: 'A1-U0',
        lessonId: lesson.id,
        lastActivityId: lesson.activities[1].id,
      );
      await _pumpHome(tester, db);
      final l10n = _l10n(tester);

      expect(find.text(l10n.homeLessonPercent(50)), findsOneWidget);
      expect(find.text(l10n.homeContinueLessonCta), findsOneWidget);
    });

    testWidgets('a finished lesson moves the hero on to the next one', (
      tester,
    ) async {
      final learnerId = await _learner(db);
      final lessons = _index.unitsById['A1-U0']!.lessons;
      await _lessonPosition(
        db,
        learnerId,
        unitId: 'A1-U0',
        lessonId: lessons[0].id,
        lastActivityId: lessons[0].activities.last.id,
      );
      await _pumpHome(tester, db);

      expect(
        find.text(_l10n(tester).homeUnitLessonOverline(1, 2).toUpperCase()),
        findsOneWidget,
      );
      expect(find.text(lessons[1].title), findsOneWidget);
    });

    testWidgets('the CTA opens that exact lesson in the player — not the unit '
        'list', (tester) async {
      await _learner(db);
      await _pumpHome(tester, db);
      final lesson = _index.unitsById['A1-U0']!.lessons.first;

      await tester.tap(find.text(_l10n(tester).homeStartLessonCta));
      await tester.pumpAndSettle();

      expect(find.text('PLAYER A1-U0 ${lesson.id}'), findsOneWidget);
    });

    testWidgets('once every lesson in the unit is played (but the unit is not '
        'mastered) it offers to open the unit instead', (tester) async {
      final learnerId = await _learner(db);
      for (final lesson in _index.unitsById['A1-U0']!.lessons) {
        await _lessonPosition(
          db,
          learnerId,
          unitId: 'A1-U0',
          lessonId: lesson.id,
          lastActivityId: lesson.activities.last.id,
        );
      }
      await _pumpHome(tester, db);
      final l10n = _l10n(tester);

      expect(
        find.text(l10n.homeUnitReviewOverline(1).toUpperCase()),
        findsOneWidget,
      );
      await tester.tap(find.text(l10n.homeOpenUnitCta));
      await tester.pumpAndSettle();
      expect(find.text('UNIT A1-U0'), findsOneWidget);
    });
  });

  group("today's goal", () {
    testWidgets('one compact section with all three objectives and a done '
        'summary', (tester) async {
      await _learner(db);
      await _pumpHome(tester, db);
      final l10n = _l10n(tester);

      expect(find.text(l10n.homeTodaysGoalTitle), findsOneWidget);
      expect(find.text(l10n.homeTaskFinishLesson), findsOneWidget);
      expect(find.text(l10n.homeTaskReviewWords), findsOneWidget);
      expect(find.text(l10n.homeTaskSpeakOnce), findsOneWidget);
      expect(find.text(l10n.homeGoalsDone(0, 3)), findsOneWidget);
      expect(find.byType(DailyGoalItem), findsNWidgets(3));
    });

    testWidgets('a reached objective turns into a success-green check and '
        'counts toward the summary', (tester) async {
      final learnerId = await _learner(db);
      await db
          .into(db.dailyTaskEvents)
          .insert(
            DailyTaskEventsCompanion.insert(
              uuid: const Uuid().v4(),
              learnerId: learnerId,
              taskType: DailyTaskType.speaking.name,
              occurredAt: DateTime.now(),
            ),
          );
      await _pumpHome(tester, db);
      final l10n = _l10n(tester);

      expect(find.text(l10n.homeGoalsDone(1, 3)), findsOneWidget);
      final speakItem = find.ancestor(
        of: find.text(l10n.homeTaskSpeakOnce),
        matching: find.byType(DailyGoalItem),
      );
      final check = tester.widget<Icon>(
        find.descendant(
          of: speakItem,
          matching: find.byIcon(Icons.check_rounded),
        ),
      );
      final feedback = Theme.of(tester.element(speakItem))
          .extension<FeedbackTheme>()!;
      expect(check.color, feedback.onSuccess);
    });
  });

  group('journey', () {
    testWidgets('shows where the learner is in the level and what comes '
        'next', (tester) async {
      await _learner(db);
      await _pumpHome(tester, db);
      final l10n = _l10n(tester);
      final units = _index.bundle.units;

      expect(find.text(l10n.homeJourneyTitle), findsOneWidget);
      expect(
        find.text(l10n.homeJourneyUnitOf(1, units.length)),
        findsOneWidget,
      );
      expect(
        find.text(l10n.homeJourneyNow(_isolated(units[0].title))),
        findsOneWidget,
      );
      expect(
        find.text(l10n.homeJourneyNext(_isolated(units[1].title))),
        findsOneWidget,
      );
    });

    testWidgets('tapping it opens the Learn path', (tester) async {
      await _learner(db);
      await _pumpHome(tester, db);

      await tester.tap(find.text(_l10n(tester).homeJourneyTitle));
      await tester.pumpAndSettle();
      expect(find.text('LEARN'), findsOneWidget);
    });
  });

  group('review status', () {
    testWidgets('nothing due is a lightweight status line, with no button', (
      tester,
    ) async {
      await _learner(db);
      await _pumpHome(tester, db);
      final l10n = _l10n(tester);

      expect(find.text(l10n.homeReviewDueTitle(0)), findsOneWidget);
      expect(find.text(l10n.homeReviewNowCta), findsNothing);
    });

    testWidgets('items due become a prominent card with a "Review now" '
        'action', (tester) async {
      final learnerId = await _learner(db);
      final now = DateTime.now();
      for (final item in _index.bundle.lexicon.take(3)) {
        await db
            .into(db.vocabularyReviewState)
            .insert(
              VocabularyReviewStateCompanion.insert(
                uuid: const Uuid().v4(),
                learnerId: learnerId,
                lexiconId: Value(item.id),
                repetitions: const Value(1),
                dueAt: Value(now.subtract(const Duration(days: 1))),
                updatedAt: now,
              ),
            );
      }
      await _pumpHome(tester, db);
      final l10n = _l10n(tester);

      expect(find.text(l10n.homeReviewDueTitle(3)), findsOneWidget);
      await tester.tap(find.text(l10n.homeReviewNowCta));
      await tester.pumpAndSettle();
      expect(find.text('REVIEW'), findsOneWidget);
    });
  });

  group('current level', () {
    testWidgets('an A1 learner opens on A1 — its first lesson, its journey, '
        'and no offer of a level they have not finished A1 for', (
      tester,
    ) async {
      await _learner(db);
      await _pumpHome(tester, db);
      final l10n = _l10n(tester);

      expect(
        find.text(_index.unitsById['A1-U0']!.lessons.first.title),
        findsOneWidget,
      );
      expect(
        find.text(l10n.homeJourneyUnitOf(1, _index.bundle.units.length)),
        findsOneWidget,
      );
      expect(find.text(l10n.homeNextLevelTitle('A2')), findsNothing);
    });

    testWidgets('an A2 learner opens on A2 — A2\'s first lesson, A2\'s '
        'journey, and A2 in the header, with none of A1\'s', (tester) async {
      await _learner(db);
      await _pumpHome(tester, db, levelId: 'a2');
      final l10n = _l10n(tester);
      final a2Lesson = _a2Index.bundle.units.first.lessons.first;

      expect(
        find.text(l10n.homeLevelBadge('A2', l10n.cefrDescriptorA2)),
        findsOneWidget,
      );
      expect(find.text(a2Lesson.title), findsOneWidget);
      expect(
        find.text(l10n.homeJourneyUnitOf(1, _a2Index.bundle.units.length)),
        findsOneWidget,
      );
      // A1's first lesson is gone, not merely joined by A2's.
      expect(
        find.text(_index.unitsById['A1-U0']!.lessons.first.title),
        findsNothing,
      );
    });

    testWidgets('mastering every A1 unit turns the dead end into an offer of '
        'A2, and tapping it moves the learner into A2', (tester) async {
      final learnerId = await _learner(db);
      await _masterEveryUnit(db, learnerId, _index);
      await _pumpHome(tester, db, height: 1800);
      final l10n = _l10n(tester);

      // The old dead end still names the level the learner finished...
      expect(find.text(l10n.homeAllUnitsMastered('A1')), findsNWidgets(2));
      // ...and beside it, somewhere to go.
      expect(
        find.text(l10n.homeNextLevelOverline.toUpperCase()),
        findsOneWidget,
      );
      expect(find.text(l10n.homeNextLevelBody('A1', 'A2')), findsOneWidget);

      final offer = find.text(l10n.homeNextLevelTitle('A2'));
      await tester.ensureVisible(offer);
      await tester.tap(offer);
      await tester.pumpAndSettle();

      // Home is now A2's: A2's first lesson, A2 in the header, and the
      // offer gone because it has been taken.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      expect(await container.read(currentLevelIdProvider.future), 'a2');
      expect(
        find.text(l10n.homeLevelBadge('A2', l10n.cefrDescriptorA2)),
        findsOneWidget,
      );
      expect(
        find.text(_a2Index.bundle.units.first.lessons.first.title),
        findsOneWidget,
      );
      expect(find.text(l10n.homeNextLevelTitle('A2')), findsNothing);
    });

    testWidgets('a level the app has not released is never offered, however '
        'finished the current one is', (tester) async {
      final learnerId = await _learner(db);
      await _masterEveryUnit(db, learnerId, _index);
      await _pumpHome(tester, db, height: 1800, catalog: _a2NotReleasedCatalog);
      final l10n = _l10n(tester);

      expect(find.text(l10n.homeAllUnitsMastered('A1')), findsNWidgets(2));
      expect(find.text(l10n.homeNextLevelTitle('A2')), findsNothing);
      expect(find.text(l10n.homeNextLevelOverline.toUpperCase()), findsNothing);
    });

    testWidgets('a learner already in A2 is not offered A2 again', (
      tester,
    ) async {
      final learnerId = await _learner(db);
      await _masterEveryUnit(db, learnerId, _index);
      await _pumpHome(tester, db, levelId: 'a2', height: 1800);
      final l10n = _l10n(tester);

      expect(find.text(l10n.homeNextLevelTitle('A2')), findsNothing);
      expect(find.text(l10n.homeNextLevelOverline.toUpperCase()), findsNothing);
      // They are in A2, working on it — not being told A1 is finished.
      expect(find.text(l10n.homeAllUnitsMastered('A1')), findsNothing);
    });
  });

  group('layout', () {
    testWidgets('renders without overflow at common phone widths and text '
        'scales, in English and Arabic', (tester) async {
      final learnerId = await _learner(db, name: 'Arkan');
      final lesson = _index.unitsById['A1-U0']!.lessons.first;
      await _lessonPosition(
        db,
        learnerId,
        unitId: 'A1-U0',
        lessonId: lesson.id,
        lastActivityId: lesson.activities.first.id,
      );

      const cases = [
        (locale: Locale('en'), width: 320.0, scale: 1.0),
        (locale: Locale('en'), width: 360.0, scale: 1.0),
        (locale: Locale('en'), width: 390.0, scale: 1.0),
        (locale: Locale('en'), width: 412.0, scale: 1.0),
        (locale: Locale('en'), width: 320.0, scale: 1.3),
        (locale: Locale('en'), width: 360.0, scale: 1.6),
        (locale: Locale('ar'), width: 320.0, scale: 1.0),
        (locale: Locale('ar'), width: 360.0, scale: 1.3),
        (locale: Locale('ar'), width: 390.0, scale: 1.6),
      ];
      for (final c in cases) {
        await _pumpHome(
          tester,
          db,
          locale: c.locale,
          width: c.width,
          textScale: c.scale,
          height: 3000,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${c.locale} ${c.width}px @${c.scale}x',
        );
        expect(find.byType(ContinueLessonCard), findsOneWidget);
        expect(find.byType(DailyGoalSection), findsOneWidget);
        expect(find.byType(JourneyCard), findsOneWidget);
      }
    });

    testWidgets(
      'the Arabic interface lays the whole screen out right-to-left',
      (tester) async {
        await _learner(db);
        await _pumpHome(tester, db, locale: const Locale('ar'));

        expect(
          Directionality.of(tester.element(find.byType(HomeHeader))),
          TextDirection.rtl,
        );
      },
    );
  });
}
