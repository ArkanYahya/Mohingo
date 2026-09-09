import 'package:flutter/material.dart';

import 'color_seed.dart';
import 'gamification_theme_extension.dart';

/// Builds the app's light/dark [ThemeData] from an approved [AppColorSeed].
///
/// Calm, adult-oriented Material 3 direction (not the earlier bright
/// Duolingo-style palette) — see docs/DESIGN_SYSTEM.md and
/// docs/adr/0004-local-only-v1-no-firebase-backend.md for why this changed.
abstract final class AppTheme {
  static ThemeData light(AppColorSeed seed) => _build(seed, Brightness.light);

  static ThemeData dark(AppColorSeed seed) => _build(seed, Brightness.dark);

  static ThemeData _build(AppColorSeed seed, Brightness brightness) {
    final generated = ColorScheme.fromSeed(
      seedColor: seed.seedColor,
      brightness: brightness,
    );
    // Every role but primary/onPrimary stays exactly as Material 3's
    // tonal-palette algorithm derives it — calm surfaces, secondary/
    // tertiary accents, error red are untouched. Only light-mode primary
    // (the one role behind buttons, selected answers, progress fills, and
    // the "correct" state — see docs/DESIGN_SYSTEM.md) is swapped for
    // [AppColorSeed.brandPrimary]; see that field's doc comment for why.
    final colorScheme = brightness == Brightness.light
        ? generated.copyWith(
            primary: seed.brandPrimary,
            onPrimary: seed.onBrandPrimary,
          )
        : generated;
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      extensions: [
        brightness == Brightness.light
            ? GamificationTheme.light
            : GamificationTheme.dark,
      ],
    );
  }
}
