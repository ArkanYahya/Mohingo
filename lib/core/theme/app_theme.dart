import 'package:flutter/material.dart';

import 'app_tokens.dart';
import 'color_seed.dart';
import 'feedback_theme_extension.dart';
import 'gamification_theme_extension.dart';

/// Builds the app's light/dark [ThemeData] from an approved [AppColorSeed].
///
/// Two layers: the *accent* comes from the seed (light-mode primary roles
/// are the seed's hand-picked flat brand tones — see [AppColorSeed]); the
/// *neutrals* — page, cards, text, borders — come from [AppTokens] and are
/// the same whichever seed is picked. On top of that sit the typography
/// scale and component themes, so every screen shares one hierarchy. See
/// docs/DESIGN_SYSTEM.md.
abstract final class AppTheme {
  static ThemeData light(AppColorSeed seed) => _build(seed, Brightness.light);

  static ThemeData dark(AppColorSeed seed) => _build(seed, Brightness.dark);

  static ThemeData _build(AppColorSeed seed, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final generated = ColorScheme.fromSeed(
      seedColor: seed.seedColor,
      brightness: brightness,
    );
    final tokens = isLight
        ? AppTokens.light(primaryInk: seed.brandInk)
        : AppTokens.dark(primaryInk: generated.primary);

    final accented = isLight
        ? generated.copyWith(
            primary: seed.brandPrimary,
            onPrimary: seed.onBrandPrimary,
            primaryContainer: seed.brandPrimaryContainer,
            onPrimaryContainer: seed.onBrandPrimaryContainer,
          )
        : generated;
    final colorScheme = accented.copyWith(
      surface: tokens.page,
      onSurface: tokens.textPrimary,
      onSurfaceVariant: tokens.textSecondary,
      outline: isLight ? const Color(0xFF8C847C) : const Color(0xFF7D766F),
      outlineVariant: tokens.border,
      surfaceTint: Colors.transparent,
      // A monotonic ramp in the same warm neutral: lighter-to-darker in
      // light mode, darker-to-lighter in dark — matching M3's semantics,
      // so existing screens' surfaceContainer* panels harmonise with it.
      surfaceContainerLowest: isLight
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF0D0C0B),
      surfaceContainerLow: isLight
          ? const Color(0xFFFAF9F7)
          : const Color(0xFF171514),
      surfaceContainer: isLight ? const Color(0xFFF3F1EE) : tokens.card,
      surfaceContainerHigh: isLight
          ? const Color(0xFFEDEAE6)
          : const Color(0xFF262320),
      surfaceContainerHighest: isLight
          ? const Color(0xFFE6E2DD)
          : const Color(0xFF2F2B28),
    );

    final navIndicator = Color.alphaBlend(
      tokens.primaryInk.withValues(alpha: isLight ? 0.12 : 0.2),
      tokens.card,
    );

    // Base first, so component themes derive from the *merged* text theme
    // (platform font family + scheme colours), never the partial styles.
    final base = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: tokens.page,
      textTheme: _textTheme,
    );
    final text = base.textTheme;

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.page,
        foregroundColor: tokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge!.copyWith(color: tokens.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: tokens.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      dividerTheme: DividerThemeData(color: tokens.border, thickness: 1),
      // Filled buttons use the accessible ink tone, not the raw brand fill:
      // calmTeal's vivid cyan needs dark text to pass contrast, which reads
      // as a toy; its ink (#007A87) carries white text at 5.1:1. For the
      // other seeds ink == brandPrimary, so nothing changes there.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.primaryInk,
          foregroundColor: isLight ? Colors.white : generated.onPrimary,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          textStyle: text.labelLarge,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: tokens.card,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        indicatorColor: navIndicator,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? tokens.primaryInk
                : tokens.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? text.labelMedium!.copyWith(
                  color: tokens.primaryInk,
                  fontWeight: FontWeight.w700,
                )
              : text.labelMedium!.copyWith(
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
        ),
      ),
      extensions: [
        tokens,
        isLight ? GamificationTheme.light : GamificationTheme.dark,
        isLight ? FeedbackTheme.light : FeedbackTheme.dark,
      ],
    );
  }

  /// Five working styles carry every redesigned screen: page header
  /// ([TextTheme.headlineSmall]), card title ([TextTheme.titleLarge]),
  /// section title ([TextTheme.titleSmall]), body ([TextTheme.bodyMedium])
  /// and meta ([TextTheme.bodySmall] / [TextTheme.labelSmall]). Only size,
  /// weight, line height and tracking are set here — colours come from the
  /// scheme, and the platform font renders both Latin and Arabic.
  static const _textTheme = TextTheme(
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -0.3,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.3,
      letterSpacing: -0.2,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.35,
      letterSpacing: 0,
    ),
    titleSmall: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.35,
      letterSpacing: 0,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.45, letterSpacing: 0),
    bodyMedium: TextStyle(fontSize: 14, height: 1.45, letterSpacing: 0),
    bodySmall: TextStyle(fontSize: 12.5, height: 1.4, letterSpacing: 0),
    labelLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
    ),
  );
}
