import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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
import 'package:mohingo/features/progress/domain/repositories/daily_task_event_repository.dart';

final CourseContentIndex _index = CourseContentIndex.build(
  CourseBundleParser.parse(
    File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
  ),
);

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
      path: '/learn/a1/unit/:unitId',
      builder: (_, state) =>
          Scaffold(body: Text('UNIT ${state.pathParameters['unitId']}')),
    ),
    GoRoute(
      path: '/learn/a1',
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

Future<void> _pumpHome(
  WidgetTester tester,
  AppDatabase db, {
  Locale locale = const Locale('en'),
  double textScale = 1,
  double width = 390,
  double height = 1400,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
        courseContentProvider('a1').overrideWith((ref) async => _index),
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
      expect(find.text(l10n.homeLevelBadge('A1')), findsOneWidget);
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
