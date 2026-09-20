import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/generated/app_localizations.dart';
import 'core/l10n/locale_preference_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_preferences_provider.dart';
import 'features/activity_engine/providers/online_refinement_providers.dart';
import 'features/progress/providers/level_providers.dart';

/// The root widget. Theme mode, colour theme, and interface language are all
/// read from Riverpod-backed preferences and apply immediately on change —
/// no restart required. See docs/DESIGN_SYSTEM.md's theming rules.
class MohingoApp extends ConsumerWidget {
  const MohingoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModePreferenceProvider);
    final colorSeed = ref.watch(colorSeedPreferenceProvider);
    final locale = ref.watch(localePreferenceProvider);
    // Fire-and-forget: enrols the learner in the level they're working in as
    // soon as both the profile and that level's content are ready. Not
    // awaited here — nothing in the UI blocks on it.
    final currentLevelId = ref.watch(currentLevelIdProvider).value;
    if (currentLevelId != null) {
      ref.watch(ensureLevelEnrolmentProvider(currentLevelId));
    }
    // Fire-and-forget: drains any queued open-ended answers immediately if
    // already online, and again whenever connectivity is regained. Never
    // required for a learning feature to function — see
    // pendingRefinementDrainerProvider's doc comment.
    ref.watch(pendingRefinementDrainerProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      routerConfig: router,
      theme: AppTheme.light(colorSeed),
      darkTheme: AppTheme.dark(colorSeed),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}
