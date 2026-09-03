import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/generated/app_localizations.dart';
import 'core/l10n/locale_preference_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_preferences_provider.dart';
import 'features/progress/providers/ensure_a1_enrollment_provider.dart';

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
    // Fire-and-forget: starts the learner-bootstrap + A1-enrolment chain as
    // soon as both the learner profile and content bundle are ready. Not
    // awaited here — nothing in the UI blocks on it, see
    // ensureA1EnrollmentProvider's doc comment.
    ref.watch(ensureA1EnrollmentProvider);

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
