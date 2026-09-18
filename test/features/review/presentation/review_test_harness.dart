import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/progress/providers/current_learner_provider.dart';
import 'package:mohingo/features/review/presentation/review_home_screen.dart';
import 'package:mohingo/features/review/presentation/review_session_screen.dart';
import 'package:mohingo/features/speech/providers/speech_providers.dart';

import '../../speech/fake_speech_services.dart';

final reviewTestIndex = CourseContentIndex.build(
  CourseBundleParser.parse(
    File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
  ),
);

/// Seeds one vocabulary-review row.
Future<void> seedVocabulary(
  AppDatabase db,
  int learnerId, {
  String? lexiconId,
  String? chunkId,
  int repetitions = 1,
  int intervalDays = 1,
  required DateTime dueAt,
  bool favorite = false,
}) async {
  await db
      .into(db.vocabularyReviewState)
      .insert(
        VocabularyReviewStateCompanion.insert(
          uuid: '${lexiconId ?? chunkId}',
          learnerId: learnerId,
          lexiconId: Value(lexiconId),
          chunkId: Value(chunkId),
          isFavorite: Value(favorite),
          repetitions: Value(repetitions),
          intervalDays: Value(intervalDays),
          dueAt: Value(dueAt),
          updatedAt: DateTime.now(),
        ),
      );
}

/// Pumps [start] ('/review' or '/review/session') inside a router with
/// stub pages for everything the Review tab links to. [seed] runs first.
Future<(ProviderContainer, AppDatabase, AppLocalizations)> pumpReview(
  WidgetTester tester, {
  String start = '/review',
  Future<void> Function(AppDatabase db, int learnerId)? seed,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWithValue(db),
      courseContentProvider('a1').overrideWith((ref) async => reviewTestIndex),
      textToSpeechServiceProvider.overrideWithValue(FakeTextToSpeechService()),
    ],
  );
  addTearDown(container.dispose);
  final learner = await container.read(currentLearnerProvider.future);
  if (seed != null) await seed(db, learner.id);

  final router = GoRouter(
    initialLocation: start,
    routes: [
      GoRoute(
        path: '/review',
        builder: (_, _) => const ReviewHomeScreen(),
        routes: [
          GoRoute(
            path: 'vocabulary',
            builder: (_, _) => const Text('WORDS'),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, s) => Text('WORD ${s.pathParameters['id']}'),
              ),
            ],
          ),
          GoRoute(
            path: 'chunks/:id',
            builder: (_, s) => Text('CHUNK ${s.pathParameters['id']}'),
          ),
          GoRoute(
            path: 'grammar',
            builder: (_, _) => const Text('GRAMMAR'),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, s) => Text('GRAMMAR ${s.pathParameters['id']}'),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/review/session',
        builder: (_, _) => const ReviewSessionScreen(),
      ),
      GoRoute(
        path: '/review/practice',
        builder: (_, s) => Text('PRACTICE ${(s.extra! as Activity).id}'),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light(AppColorSeed.calmTeal),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  final l10n = AppLocalizations.of(
    tester.element(find.byType(Navigator).first),
  )!;
  return (container, db, l10n);
}
