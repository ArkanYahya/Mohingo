import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/lesson_player/presentation/lesson_review_screen.dart';
import 'package:mohingo/features/progress/providers/current_learner_provider.dart';
import 'package:mohingo/features/progress/providers/progress_providers.dart';

final _index = CourseContentIndex.build(
  CourseBundleParser.parse(
    File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
  ),
);

/// A1-U0-L1 (Unit 1, Lesson 1): A01 answered right, A02 wrong, A03 and A04
/// not answered.
Future<AppLocalizations> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      courseContentProvider('a1').overrideWith((ref) async => _index),
    ],
  );
  addTearDown(container.dispose);
  final learner = await container.read(currentLearnerProvider.future);
  for (final (id, answer, correct) in [
    ('A1-U0-L1-A01', '"In the morning"', true),
    ('A1-U0-L1-A02', '"Goodbye."', false),
  ]) {
    await container
        .read(activityAttemptRepositoryProvider)
        .recordAttempt(
          learnerId: learner.id,
          activityId: id,
          lessonId: 'A1-U0-L1',
          sessionType: 'lesson',
          mode: ActivityMode.encounter,
          evidenceSkill: Skill.listening,
          canDoIds: const [],
          rawAnswer: answer,
          isCorrect: correct,
          score: correct ? 1 : 0,
        );
  }
  final router = GoRouter(
    initialLocation: '/review',
    routes: [
      GoRoute(
        path: '/review',
        builder: (_, _) =>
            const LessonReviewScreen(unitId: 'A1-U0', lessonId: 'A1-U0-L1'),
      ),
      GoRoute(
        path: '/lesson-player/:unitId/:lessonId',
        builder: (_, _) => const Scaffold(body: Text('PLAYER')),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light(AppColorSeed.calmTeal),
        routerConfig: router,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final lesson = _index.lessonsById['A1-U0-L1']!;

  testWidgets('opens on where the lesson sits, its title, and a summary: '
      'how many right, with a numbered mark per question', (tester) async {
    final l10n = await _pump(tester);

    expect(
      find.text(l10n.lessonReviewOverline(1, 1).toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(lesson.title), findsOneWidget);
    expect(find.text(l10n.lessonReviewScore(1, 4)), findsOneWidget);
    for (var n = 1; n <= 4; n++) {
      expect(
        find.bySemanticsLabel(RegExp('^${l10n.lessonReviewQuestion(n)}')),
        findsWidgets,
      );
    }
  });

  testWidgets('each question card says whether it was right', (tester) async {
    final l10n = await _pump(tester);

    expect(find.text(l10n.lessonReviewRight), findsOneWidget);
    expect(find.text(l10n.lessonReviewNotQuite), findsOneWidget);
    expect(find.text(l10n.lessonReviewNotAnsweredPill), findsNWidgets(2));
  });

  testWidgets('To revisit shows only the questions that went wrong', (
    tester,
  ) async {
    final l10n = await _pump(tester);
    final first = lesson.activities[0];
    final second = lesson.activities[1];

    await tester.tap(find.text(l10n.lessonReviewFilterToRevisit));
    await tester.pumpAndSettle();

    expect(find.text(second.prompt), findsOneWidget);
    expect(find.text(first.prompt), findsNothing);
    expect(find.text(l10n.lessonReviewNotAnswered), findsNothing);
  });

  testWidgets('Practise this lesson again is pinned and opens the player', (
    tester,
  ) async {
    final l10n = await _pump(tester);

    await tester.tap(find.text(l10n.lessonReviewPracticeAgain));
    await tester.pumpAndSettle();
    expect(find.text('PLAYER'), findsOneWidget);
  });
}
