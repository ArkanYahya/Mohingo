import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../review/providers/review_providers.dart';

/// The 5-tab bottom-navigation shell (Home / Learn / Review / Tests /
/// Settings) — see docs/ARCHITECTURE.md's navigation map. Vocabulary and
/// Grammar live inside Review, not as separate top-level destinations.
class AppShellScaffold extends ConsumerWidget {
  const AppShellScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dueCount = ref.watch(dueVocabularyCountProvider).value ?? 0;

    Widget reviewIcon(IconData icon) {
      if (dueCount <= 0) return Icon(icon);
      return Badge(label: Text('$dueCount'), child: Icon(icon));
    }

    final tokens = Theme.of(context).extension<AppTokens>()!;

    return Scaffold(
      body: navigationShell,
      // Colours, height, indicator and label styles come from the theme's
      // NavigationBarThemeData; the hairline separates the bar from the
      // page without a tonal slab or shadow.
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: tokens.border)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: l10n.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book),
              label: l10n.navLearn,
            ),
            NavigationDestination(
              icon: reviewIcon(Icons.refresh_outlined),
              selectedIcon: reviewIcon(Icons.refresh),
              label: l10n.navReview,
            ),
            NavigationDestination(
              icon: const Icon(Icons.fact_check_outlined),
              selectedIcon: const Icon(Icons.fact_check),
              label: l10n.navTests,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: l10n.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
