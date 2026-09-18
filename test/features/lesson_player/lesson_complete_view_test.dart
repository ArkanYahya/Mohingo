import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/curriculum_structure.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';
import 'package:mohingo/features/lesson_player/presentation/widgets/lesson_complete_view.dart';

final _index = CourseContentIndex.build(
  CourseBundleParser.parse(
    File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
  ),
);

const _c = ActivityCorrectness.correct;
const _x = ActivityCorrectness.incorrect;
const _p = ActivityCorrectness.notAutoGraded;

Future<AppLocalizations> _pump(
  WidgetTester tester, {
  List<ActivityCorrectness> results = const [_c, _c, _x, _c],
  List<Skill> skills = const [Skill.listening, Skill.reading],
  int phraseCount = 4,
  int? streakDays = 2,
  Lesson? nextLesson,
  int? nextLessonNumber,
  VoidCallback? onNext,
  VoidCallback? onReviewAnswers,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      theme: AppTheme.light(AppColorSeed.calmTeal),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: LessonCompleteView(
          lesson: _index.lessonsById['A1-U1-L1']!,
          results: results,
          skills: skills,
          phraseCount: phraseCount,
          streakDays: streakDays,
          nextLesson: nextLesson,
          nextLessonNumber: nextLessonNumber,
          onNext: onNext ?? () {},
          onReviewAnswers: onReviewAnswers ?? () {},
          onClose: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(LessonCompleteView)))!;
}

void main() {
  testWidgets('the score ring shows correct over total and announces the '
      'tally; the figures show streak, accuracy and the lesson\'s phrases', (
    tester,
  ) async {
    final l10n = await _pump(tester);

    expect(find.text(l10n.lessonCompleteTitle), findsOneWidget);
    expect(find.text('My Name'), findsOneWidget);
    expect(find.text('اسمي'), findsOneWidget);
    expect(find.text('3/4'), findsOneWidget);
    expect(
      find.bySemanticsLabel(l10n.lessonCompleteTally(3, 4)),
      findsOneWidget,
    );
    expect(find.text(l10n.homeStreakChip(2)), findsOneWidget);
    expect(find.text(l10n.homeLessonPercent(75)), findsOneWidget);
    expect(find.text(l10n.lessonCompletePhrasesLabel), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('answers saved for review are counted apart — a pending line, '
      'and no accuracy when nothing was auto-graded', (tester) async {
    final l10n = await _pump(tester, results: const [_p, _p]);

    expect(find.text(l10n.lessonCompletePendingReview(2)), findsOneWidget);
    expect(find.text(l10n.lessonCompleteAccuracyLabel), findsNothing);
    expect(find.textContaining('/'), findsNothing);
  });

  testWidgets('with no key phrases, the third figure counts questions', (
    tester,
  ) async {
    final l10n = await _pump(tester, phraseCount: 0);

    expect(find.text(l10n.lessonCompletePhrasesLabel), findsNothing);
    expect(find.text(l10n.lessonCompleteQuestionsLabel), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('skills practised are listed once each, in order, with both '
      'speaking skills as "Speaking"', (tester) async {
    final l10n = await _pump(
      tester,
      skills: const [
        Skill.listening,
        Skill.reading,
        Skill.listening,
        Skill.spokenProduction,
        Skill.spokenInteraction,
      ],
    );

    expect(find.text(l10n.skillListening), findsOneWidget);
    expect(find.text(l10n.skillReading), findsOneWidget);
    expect(find.text(l10n.skillSpeaking), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(l10n.skillReading)).dx,
      greaterThan(tester.getTopLeft(find.text(l10n.skillListening)).dx),
    );
  });

  testWidgets('the next lesson is previewed — number, title, Arabic, type '
      'and size — and both the card and Next lesson continue to it', (
    tester,
  ) async {
    var next = 0;
    final nextLesson = _index.lessonsById['A1-U1-L2']!;
    final l10n = await _pump(
      tester,
      nextLesson: nextLesson,
      nextLessonNumber: 2,
      onNext: () => next++,
    );

    expect(
      find.text(l10n.lessonCompleteUpNext(2).toUpperCase()),
      findsOneWidget,
    );
    expect(find.text('Where Are You From?'), findsOneWidget);
    expect(find.text('من أين أنت؟'), findsOneWidget);
    expect(
      find.text(
        '${l10n.homeLessonTypeGuided} · '
        '${l10n.homeActivityCount(nextLesson.activities.length)}',
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Where Are You From?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Where Are You From?'));
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.lessonCompleteNextLesson),
    );
    expect(next, 2);
  });

  testWidgets('the unit\'s last lesson offers Back to unit and no preview', (
    tester,
  ) async {
    final l10n = await _pump(tester);

    expect(
      find.widgetWithText(FilledButton, l10n.lessonCompleteBackToUnit),
      findsOneWidget,
    );
    expect(find.textContaining(l10n.lessonCompleteUpNext(2)), findsNothing);
  });

  testWidgets('Review answers opens the answer review', (tester) async {
    var reviewed = 0;
    final l10n = await _pump(tester, onReviewAnswers: () => reviewed++);

    await tester.tap(find.text(l10n.lessonCompleteReviewAnswers));
    expect(reviewed, 1);
  });

  testWidgets('on a narrow screen at large text the figures stack, one per '
      'row, instead of breaking words across lines', (tester) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final l10n = await _pump(tester, textScale: 1.6);

    final streak = tester.getTopLeft(find.text(l10n.lessonCompleteStreakLabel));
    final accuracy = tester.getTopLeft(
      find.text(l10n.lessonCompleteAccuracyLabel),
    );
    expect(accuracy.dy, greaterThan(streak.dy));
    expect(accuracy.dx, streak.dx);
  });
}
