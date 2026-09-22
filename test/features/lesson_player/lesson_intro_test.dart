import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/activity_engine/presentation/activity_chrome.dart';
import 'package:mohingo/features/lesson_player/presentation/lesson_player_screen.dart';
import 'package:mohingo/features/lesson_player/presentation/widgets/lesson_conversation_step.dart';
import 'package:mohingo/features/lesson_player/presentation/widgets/lesson_key_phrases_step.dart';
import 'package:mohingo/features/lesson_player/presentation/widgets/lesson_progress_bar.dart';
import 'package:mohingo/features/lesson_player/presentation/widgets/lesson_reading_step.dart';
import 'package:mohingo/features/speech/domain/speech_capability_service.dart';
import 'package:mohingo/features/speech/domain/speech_recognition_service.dart';
import 'package:mohingo/features/speech/providers/speech_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../speech/fake_speech_services.dart';

final _index = CourseContentIndex.build(
  CourseBundleParser.parse(
    File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
  ),
);

/// The lesson player on real content, offline, with speech faked. With
/// [resumeAfter] the learner already answered that many activities.
Future<FakeTextToSpeechService> _pumpPlayer(
  WidgetTester tester, {
  String unitId = 'A1-U1',
  String lessonId = 'A1-U1-L1',
  int resumeAfter = 0,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  if (resumeAfter > 0) {
    final learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(uuid: 'l', createdAt: DateTime.utc(2026)),
        );
    final now = DateTime.utc(2026, 9, 18);
    await db
        .into(db.lessonProgress)
        .insert(
          LessonProgressCompanion.insert(
            uuid: const Uuid().v4(),
            learnerId: learnerId,
            lessonId: lessonId,
            unitId: unitId,
            state: 'inProgress',
            lastActivityId: Value(
              _index.lessonsById[lessonId]!.activities[resumeAfter - 1].id,
            ),
            updatedAt: now,
          ),
        );
  }
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final tts = FakeTextToSpeechService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
        courseContentProvider('a1').overrideWith((ref) async => _index),
        textToSpeechServiceProvider.overrideWithValue(tts),
        speechCapabilityServiceProvider.overrideWithValue(
          FakeSpeechCapabilityService(
            const DeviceSpeechCapabilities(
              sttAvailableForLocale: false,
              micPermission: SpeechPermissionStatus.notDetermined,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(AppColorSeed.calmTeal),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: LessonPlayerScreen(unitId: unitId, lessonId: lessonId),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tts;
}

AppLocalizations _l10n(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(LessonPlayerScreen)))!;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('a lesson with a conversation opens on it: the lesson title in '
      'English and Arabic, every line with its speaker and its Arabic, read '
      'aloud once in order', (tester) async {
    final tts = await _pumpPlayer(tester);
    final l10n = _l10n(tester);

    expect(find.byType(LessonConversationStep), findsOneWidget);
    expect(find.byType(ActivityChrome), findsNothing);
    expect(find.text('My Name'), findsOneWidget);
    expect(find.text('اسمي'), findsOneWidget);
    expect(
      find.text(l10n.homeUnitLessonOverline(2, 1).toUpperCase()),
      findsOneWidget,
    );
    expect(find.text("Hi. I'm Maya. What's your name?"), findsOneWidget);
    expect(find.text('مرحباً. أنا مايا. ما اسمك؟'), findsOneWidget);
    expect(find.text('Omar'), findsWidgets);
    expect(tts.spoken, [
      "Hi. I'm Maya. What's your name?",
      "I'm Omar.",
      'Nice to meet you.',
      'Nice to meet you too.',
    ]);
  });

  testWidgets('tapping a line reads just that line', (tester) async {
    final tts = await _pumpPlayer(tester);
    tts.spoken.clear();

    await tester.tap(find.text("I'm Omar."));
    await tester.pumpAndSettle();

    expect(tts.spoken, ["I'm Omar."]);
  });

  testWidgets('the Arabic translation switch hides and shows every Arabic '
      'line', (tester) async {
    await _pumpPlayer(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.text(l10n.lessonIntroArabicToggle));
    await tester.pumpAndSettle();
    expect(find.text('مرحباً. أنا مايا. ما اسمك؟'), findsNothing);

    await tester.tap(find.text(l10n.lessonIntroArabicToggle));
    await tester.pumpAndSettle();
    expect(find.text('مرحباً. أنا مايا. ما اسمك؟'), findsOneWidget);
  });

  testWidgets('key phrases come next: the lesson\'s phrases with their '
      'Arabic, NEW on the ones this lesson introduces, then its grammar '
      'forms; Start practice opens the first question', (tester) async {
    await _pumpPlayer(tester);
    final l10n = _l10n(tester);

    await tester.tap(find.widgetWithText(FilledButton, l10n.activityContinue));
    await tester.pumpAndSettle();

    expect(find.byType(LessonKeyPhrasesStep), findsOneWidget);
    expect(find.text(l10n.lessonIntroKeyPhrasesTitle), findsOneWidget);
    // A phrase and, below, the example of the "What is ...?" grammar form.
    expect(find.text("What's your name?"), findsNWidgets(2));
    expect(find.text('Nice to meet you.'), findsOneWidget);
    expect(find.text('سعيد بلقائك.'), findsOneWidget);
    // I'm {name} and Nice to meet you are introduced in A1-U1-L1; the
    // other two were introduced in A1-U0-L3.
    expect(find.text(l10n.lessonIntroNew.toUpperCase()), findsNWidgets(2));
    expect(find.text('I am'), findsOneWidget);
    expect(find.text("I'm"), findsOneWidget);

    await tester.tap(
      find.widgetWithText(FilledButton, l10n.lessonIntroStartPractice),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ActivityChrome), findsOneWidget);
    expect(find.text("What's the man's name?"), findsOneWidget);
  });

  testWidgets('the intro is the first group of the progress bar — '
      'conversation and key phrases, then the phases', (tester) async {
    await _pumpPlayer(tester);
    final l10n = _l10n(tester);

    expect(
      tester
          .widget<LessonProgressBar>(find.byType(LessonProgressBar))
          .groupSizes,
      [2, 1, 1, 2],
    );
    expect(
      find.bySemanticsLabel(l10n.lessonPlayerProgress(1, 6)),
      findsOneWidget,
    );
  });

  testWidgets('resuming a lesson part-way through skips the intro, which '
      'shows as done in the progress bar', (tester) async {
    await _pumpPlayer(tester, resumeAfter: 2);
    final l10n = _l10n(tester);

    expect(find.byType(LessonConversationStep), findsNothing);
    expect(find.byType(ActivityChrome), findsOneWidget);
    expect(
      find.bySemanticsLabel(l10n.lessonPlayerProgress(5, 6)),
      findsOneWidget,
    );
  });

  testWidgets('a lesson without a conversation starts on its first '
      'question', (tester) async {
    // A1-U0-L2 is the app-instructions drill: no conversation, no model
    // text, four questions. (A1-U1-L4 served here until every A1 guided
    // lesson was given an opening conversation on 2026-09-22.)
    await _pumpPlayer(tester, unitId: 'A1-U0', lessonId: 'A1-U0-L2');

    expect(find.byType(LessonConversationStep), findsNothing);
    expect(find.byType(ActivityChrome), findsOneWidget);
  });

  testWidgets('a lesson built around a text opens on it — its title, the '
      'English and its Arabic, which the switch hides — then key phrases, '
      'then the first question', (tester) async {
    await _pumpPlayer(tester, unitId: 'A1-U2', lessonId: 'A1-U2-L6');

    expect(find.byType(LessonReadingStep), findsOneWidget);
    expect(find.text('A People Profile'), findsOneWidget);
    expect(find.text("Maya's Family"), findsOneWidget);
    expect(find.textContaining('My name is Maya.'), findsOneWidget);
    expect(find.textContaining('اسمي مايا.'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.textContaining('اسمي مايا.'), findsNothing);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byType(LessonKeyPhrasesStep), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityChrome), findsOneWidget);
  });

  testWidgets('tapping the reading step\'s Arabic-toggle label — not the '
      'switch itself — hides the Arabic translation too', (tester) async {
    await _pumpPlayer(tester, unitId: 'A1-U2', lessonId: 'A1-U2-L6');
    final l10n = _l10n(tester);

    expect(find.textContaining('اسمي مايا.'), findsOneWidget);

    await tester.tap(find.text(l10n.lessonIntroArabicToggle));
    await tester.pumpAndSettle();

    expect(find.textContaining('اسمي مايا.'), findsNothing);
  });

  testWidgets('on a speaking question the lesson\'s own phrases are there as '
      'optional help, hidden until asked for', (tester) async {
    await _pumpPlayer(tester, resumeAfter: 2); // A03: "Introduce yourself."
    final l10n = _l10n(tester);

    expect(find.text('Nice to meet you.'), findsNothing);
    await tester.tap(find.text(l10n.speakShowUsefulPhrases));
    await tester.pumpAndSettle();

    expect(find.text('Nice to meet you.'), findsOneWidget);
    expect(find.text(l10n.speakHideUsefulPhrases), findsOneWidget);
  });
}
