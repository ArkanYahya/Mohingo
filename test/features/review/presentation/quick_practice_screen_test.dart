import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/activity_engine/providers/sound_effects_providers.dart';
import 'package:mohingo/features/review/domain/practice_set.dart';
import 'package:mohingo/features/review/domain/weak_spots.dart';
import 'package:mohingo/features/review/presentation/quick_practice_screen.dart';
import 'package:mohingo/features/speech/domain/speech_capability_service.dart';
import 'package:mohingo/features/speech/domain/speech_recognition_service.dart';
import 'package:mohingo/features/speech/providers/speech_providers.dart';

import '../../activity_engine/answer_activity.dart';
import '../../activity_engine/fake_sound_effects_service.dart';
import '../../speech/fake_speech_services.dart';

final _index = CourseContentIndex.build(
  CourseBundleParser.parse(
    File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
  ),
);

/// The "My Name" weak spot's practice set.
final _set = practiceSetForWeakSpot(
  weakSpotsFor(
    index: _index,
    levelCode: 'A1',
    canDoIds: const [
      'A1.U1.PRODUCTION.INTRODUCE_SELF',
      'A1.U1.INTERACTION.ASK_NAME',
    ],
  ).single,
);

Future<(AppLocalizations, AppDatabase)> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const Text('HOME')),
      GoRoute(
        path: '/practice',
        builder: (_, _) => QuickPracticeScreen(set: _set),
      ),
      GoRoute(
        path: '/lesson-player/:unitId/:lessonId',
        builder: (_, s) => Text('PLAYER ${s.pathParameters['lessonId']}'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
        courseContentProvider('a1').overrideWith((ref) async => _index),
        soundEffectsServiceProvider.overrideWithValue(
          FakeSoundEffectsService(),
        ),
        textToSpeechServiceProvider.overrideWithValue(
          FakeTextToSpeechService(),
        ),
        speechCapabilityServiceProvider.overrideWithValue(
          FakeSpeechCapabilityService(
            const DeviceSpeechCapabilities(
              sttAvailableForLocale: false,
              micPermission: SpeechPermissionStatus.notDetermined,
            ),
          ),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(AppColorSeed.calmTeal),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  router.push('/practice');
  await tester.pumpAndSettle();
  return (
    AppLocalizations.of(tester.element(find.byType(Scaffold).first))!,
    db,
  );
}

String _eyebrow(AppLocalizations l10n, int n) => l10n
    .practiceEyebrow('\u2068${_set.title}\u2069', n, _set.activities.length)
    .toUpperCase();

Future<void> _answerAll(WidgetTester tester) async {
  for (final activity in _set.activities) {
    await answerCheckAndAdvance(tester, activity);
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('the set has more than one question', () {
    expect(_set.activities.length, greaterThan(1));
  });

  testWidgets('asks each question in the frame, saying which one of how '
      'many, and records them as practice, not lessons', (tester) async {
    final (l10n, db) = await _pump(tester);

    expect(find.text(_eyebrow(l10n, 1)), findsOneWidget);
    await answerCheckAndAdvance(tester, _set.activities.first);
    expect(find.text(_eyebrow(l10n, 2)), findsOneWidget);

    final attempts = await db.select(db.activityAttempts).get();
    expect(attempts.single.sessionType, 'practiceReview');
  });

  testWidgets('ends on a summary that says practice does not count towards '
      'mastery; Done closes it', (tester) async {
    final (l10n, _) = await _pump(tester);

    await _answerAll(tester);

    // The helper's stock spoken answer misses A03's keyword checklist, so
    // one of the three is "not quite".
    expect(
      find.text(l10n.lessonReviewScore(2, _set.activities.length)),
      findsOneWidget,
    );
    expect(find.text(l10n.practiceNoMastery), findsOneWidget);

    await tester.tap(find.text(l10n.quickPracticeDone));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('Practise again starts the set over', (tester) async {
    final (l10n, _) = await _pump(tester);

    await _answerAll(tester);
    await tester.tap(find.text(l10n.practiceAgain));
    await tester.pumpAndSettle();

    expect(find.text(_eyebrow(l10n, 1)), findsOneWidget);
  });

  testWidgets('the summary links to the lesson that teaches it', (
    tester,
  ) async {
    final (_, _) = await _pump(tester);

    await _answerAll(tester);
    await tester.tap(find.text(_set.lesson!.title));
    await tester.pumpAndSettle();

    expect(find.text('PLAYER ${_set.lesson!.id}'), findsOneWidget);
  });
}
