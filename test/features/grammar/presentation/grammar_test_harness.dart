import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/grammar/presentation/grammar_detail_screen.dart';
import 'package:mohingo/features/grammar/presentation/grammar_list_screen.dart';
import 'package:mohingo/features/progress/providers/current_learner_provider.dart';
import 'package:mohingo/features/speech/providers/speech_providers.dart';

import '../../review/presentation/review_test_harness.dart';
import '../../speech/fake_speech_services.dart';

export '../../review/presentation/review_test_harness.dart'
    show reviewTestIndex;

/// Pumps [start] under the real grammar list and page, with a stub
/// practice route.
Future<(ProviderContainer, AppLocalizations)> pumpGrammar(
  WidgetTester tester, {
  String start = '/review/grammar',
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
        path: '/review/grammar',
        builder: (_, _) => const GrammarListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, s) =>
                GrammarDetailScreen(grammarId: s.pathParameters['id']!),
          ),
        ],
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
  return (container, l10n);
}
