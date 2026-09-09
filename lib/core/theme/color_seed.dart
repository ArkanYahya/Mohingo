import 'package:flutter/material.dart';

/// Approved colour-theme seeds for the Settings colour-theme picker.
///
/// Material 3's `ColorScheme.fromSeed` derives the full light/dark role set
/// from one seed colour per theme, so adding a "colour theme" choice is a
/// matter of adding an entry here, not hand-maintaining a full palette. The
/// one exception is [brandPrimary]/[onBrandPrimary] — see their doc comment.
/// See docs/DESIGN_SYSTEM.md.
enum AppColorSeed {
  calmTeal(
    seedColor: Color(0xFF2A6F77),
    labelEn: 'Calm Teal',
    labelAr: 'أزرق مخضر هادئ',
    brandPrimary: Color(0xFF00CBE5),
    onBrandPrimary: Color(0xFF00363C),
  ),
  slateIndigo(
    seedColor: Color(0xFF3F4A7A),
    labelEn: 'Slate Indigo',
    labelAr: 'نيلي رمادي',
    brandPrimary: Color(0xFF3645E2),
    onBrandPrimary: Color(0xFFFFFFFF),
  ),
  warmTerracotta(
    seedColor: Color(0xFF8A5238),
    labelEn: 'Warm Terracotta',
    labelAr: 'طيني دافئ',
    brandPrimary: Color(0xFFC74605),
    onBrandPrimary: Color(0xFFFFFFFF),
  );

  const AppColorSeed({
    required this.seedColor,
    required this.labelEn,
    required this.labelAr,
    required this.brandPrimary,
    required this.onBrandPrimary,
  });

  final Color seedColor;
  final String labelEn;
  final String labelAr;

  /// A flat, saturated tone in the same hue family as [seedColor], used in
  /// place of `ColorScheme.fromSeed`'s own light-mode `primary` — that
  /// algorithm deliberately keeps light-mode primary dark enough to
  /// guarantee white-text contrast, which reads closer to ink than to an
  /// accent (see [AppTheme]). Light mode only: dark mode's
  /// algorithm-derived primary is already a light tone that reads clearly
  /// against the dark surface, so it's left untouched. Each value is swept
  /// across lightness at full saturation and checked against the 4.5:1
  /// WCAG 2.1 AA floor with its paired [onBrandPrimary] — the same bar
  /// `docs/UX_PRINCIPLES.md` holds `GamificationTheme.streakAccent` to.
  final Color brandPrimary;

  /// Foreground colour for content drawn on [brandPrimary]. White passes
  /// AA contrast on [slateIndigo]/[warmTerracotta]'s brand tone, but not on
  /// [calmTeal]'s (a vivid cyan) — mirroring exactly why
  /// `GamificationTheme.onStreakAccent` isn't always white either.
  final Color onBrandPrimary;
}
