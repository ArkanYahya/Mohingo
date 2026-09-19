import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../content/providers/course_content_providers.dart';
import '../../features/app_shell/presentation/app_shell_scaffold.dart';
import '../../features/app_shell/presentation/content_error_screen.dart';
import '../../features/app_shell/presentation/splash_screen.dart';
import '../../features/final_assessment/presentation/final_assessment_screen.dart';
import '../../features/final_mission/presentation/final_mission_screen.dart';
import '../../features/grammar/presentation/grammar_detail_screen.dart';
import '../../features/grammar/presentation/grammar_list_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/learning_path/presentation/course_screen.dart';
import '../../features/learning_path/presentation/unit_overview_screen.dart';
import '../../features/lesson_player/presentation/lesson_player_screen.dart';
import '../../features/lesson_player/presentation/lesson_review_screen.dart';
import '../../features/placement_test/presentation/placement_test_screen.dart';
import '../../features/review/domain/practice_set.dart';
import '../../features/review/presentation/quick_practice_screen.dart';
import '../../features/review/presentation/review_home_screen.dart';
import '../../features/review/presentation/review_session_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/tests_home/presentation/tests_home_screen.dart';
import '../../features/vocabulary/presentation/chunk_detail_screen.dart';
import '../../features/vocabulary/presentation/vocabulary_list_screen.dart';
import '../../features/vocabulary/presentation/word_detail_screen.dart';
import 'content_load_refresh_listenable.dart';
import 'legacy_learn_redirect.dart';

part 'app_router.g.dart';

/// The app's route tree.
///
/// The root [GoRouter.redirect] gates every route on the A1 curriculum
/// bundle's load status: `/splash` while loading, `/content-error` on an
/// unsupported schema or parse failure, otherwise the normal tree. See
/// docs/ARCHITECTURE.md's content-loading strategy.
///
/// The lesson player, and any future placement/final-mission/
/// final-assessment flows, are deliberately full-screen pushes *outside*
/// the 5-tab `StatefulShellRoute` (hides the bottom nav during a lesson).
@riverpod
GoRouter appRouter(Ref ref) {
  final refreshListenable = ContentLoadRefreshListenable(ref);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final contentAsync = ref.read(courseContentProvider('a1'));
      final atGateScreen =
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/content-error';

      if (contentAsync.isLoading) {
        return state.matchedLocation == '/splash' ? null : '/splash';
      }
      if (contentAsync.hasError) {
        return state.matchedLocation == '/content-error'
            ? null
            : '/content-error';
      }
      // Content ready: leave the gate screens if we're still on one.
      return atGateScreen ? '/home' : null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: '/content-error',
        builder: (_, _) => const ContentErrorScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/learn',
                // The Learn tab opens straight on the A1 course — there is no
                // separate level list; unavailable levels are a "Coming
                // later" strip on the course page.
                builder: (_, _) => const CourseScreen(),
                routes: [
                  GoRoute(
                    path: 'unit/:unitId',
                    builder: (_, state) => UnitOverviewScreen(
                      unitId: state.pathParameters['unitId']!,
                    ),
                  ),
                  // Old addresses — /learn/<level> and
                  // /learn/<level>/unit/<id> — from saved or deep links. Must
                  // come after 'unit/:unitId', which ':levelId' would match.
                  GoRoute(
                    path: ':levelId',
                    redirect: (_, state) => legacyLearnRedirect(state.uri),
                    routes: [
                      GoRoute(
                        path: 'unit/:unitId',
                        redirect: (_, state) => legacyLearnRedirect(state.uri),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/review',
                builder: (_, _) => const ReviewHomeScreen(),
                routes: [
                  GoRoute(
                    path: 'vocabulary',
                    builder: (_, _) => const VocabularyListScreen(),
                    routes: [
                      GoRoute(
                        path: ':lexiconId',
                        builder: (_, state) => WordDetailScreen(
                          lexiconId: state.pathParameters['lexiconId']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'chunks/:chunkId',
                    builder: (_, state) => ChunkDetailScreen(
                      chunkId: state.pathParameters['chunkId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'grammar',
                    builder: (_, _) => const GrammarListScreen(),
                    routes: [
                      GoRoute(
                        path: ':grammarId',
                        builder: (_, state) => GrammarDetailScreen(
                          grammarId: state.pathParameters['grammarId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tests',
                builder: (_, _) => const TestsHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/lesson-player/:unitId/:lessonId',
        builder: (_, state) => LessonPlayerScreen(
          unitId: state.pathParameters['unitId']!,
          lessonId: state.pathParameters['lessonId']!,
        ),
      ),
      GoRoute(
        path: '/lesson-review/:unitId/:lessonId',
        builder: (_, state) => LessonReviewScreen(
          unitId: state.pathParameters['unitId']!,
          lessonId: state.pathParameters['lessonId']!,
        ),
      ),
      GoRoute(
        // Pushed with `extra: <PracticeSet>` from a grammar page's Quick
        // practice and the Review tab's weak spots — built from the
        // already-loaded CourseContentIndex at the call site.
        path: '/review/practice',
        builder: (_, state) =>
            QuickPracticeScreen(set: state.extra! as PracticeSet),
      ),
      GoRoute(
        // Full screen, above the tab bar, like the lesson player.
        path: '/review/session',
        builder: (_, _) => const ReviewSessionScreen(),
      ),
      GoRoute(
        path: '/tests/placement',
        builder: (_, _) => const PlacementTestScreen(),
      ),
      GoRoute(
        path: '/tests/final-mission',
        builder: (_, _) => const FinalMissionScreen(),
      ),
      GoRoute(
        path: '/tests/final-assessment',
        builder: (_, _) => const FinalAssessmentScreen(),
      ),
    ],
  );
}
