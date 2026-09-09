import 'package:flutter/material.dart';

import 'color_seed.dart';
import 'feedback_theme_extension.dart';
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
    // Every role but primary/onPrimary/primaryContainer/onPrimaryContainer
    // stays exactly as Material 3's tonal-palette algorithm derives it —
    // calm surfaces, secondary/tertiary accents, error red are untouched.
    // Only light-mode primary and its container (the roles behind buttons,
    // selected answers, progress fills, and the "Continue learning" hero
    // card — see docs/DESIGN_SYSTEM.md) are swapped for
    // [AppColorSeed.brandPrimary]/[brandPrimaryContainer]; see those
    // fields' doc comments for why. The "correct"/mastered state no longer
    // reads from primary at all — see [FeedbackTheme].
    final colorScheme = brightness == Brightness.light
        ? generated.copyWith(
            primary: seed.brandPrimary,
            onPrimary: seed.onBrandPrimary,
            primaryContainer: seed.brandPrimaryContainer,
            onPrimaryContainer: seed.onBrandPrimaryContainer,
          )
        : generated;
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      extensions: [
        brightness == Brightness.light
            ? GamificationTheme.light
            : GamificationTheme.dark,
        brightness == Brightness.light
            ? FeedbackTheme.light
            : FeedbackTheme.dark,
      ],
    );
  }
}
