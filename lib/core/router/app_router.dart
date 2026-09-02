import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/app_shell/presentation/app_shell_scaffold.dart';
import '../../features/course_catalog/presentation/level_catalog_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/review/presentation/review_home_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/tests_home/presentation/tests_home_screen.dart';

part 'app_router.g.dart';

/// The app's route tree.
///
/// Phase 3 scope: the 5-tab shell only, with placeholder screens. The
/// content-load root [GoRouter.redirect] gate (routing to a splash/
/// unsupported-content screen based on the curriculum bundle's load status)
/// is added once `lib/content/` exists — see docs/ARCHITECTURE.md's
/// navigation map. Likewise, the full-screen pushes for the lesson player,
/// placement test, final mission, and final assessment are added once their
/// owning features exist.
@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
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
                builder: (_, _) => const LevelCatalogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/review',
                builder: (_, _) => const ReviewHomeScreen(),
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
    ],
  );
}
