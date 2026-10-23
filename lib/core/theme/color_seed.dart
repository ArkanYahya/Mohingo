import 'package:flutter/material.dart';

/// The app's brand accent. Learners no longer choose a colour (the picker
/// left Settings in 1.0.0); the other seeds stay as tested theme
/// infrastructure.
const kAppColorSeed = AppColorSeed.calmTeal;

/// Approved colour-theme seeds. [kAppColorSeed] is the one the app uses.
///
/// Material 3's `ColorScheme.fromSeed` derives the full light/dark role set
/// from one seed colour per theme, so adding a "colour theme" choice is a
/// matter of adding an entry here, not hand-maintaining a full palette. The
/// exceptions are [brandPrimary]/[onBrandPrimary]/[brandPrimaryContainer]/
/// [onBrandPrimaryContainer] — see their doc comments. See
/// docs/DESIGN_SYSTEM.md.
enum AppColorSeed {
  calmTeal(
    seedColor: Color(0xFF2A6F77),
    labelEn: 'Calm Teal',
    labelAr: 'أزرق مخضر هادئ',
    brandPrimary: Color(0xFF00CBE5),
    onBrandPrimary: Color(0xFF00363C),
    brandPrimaryContainer: Color(0xFF3DE8FF),
    onBrandPrimaryContainer: Color(0xFF00363C),
    brandInk: Color(0xFF007A87),
  ),
  slateIndigo(
    seedColor: Color(0xFF3F4A7A),
    labelEn: 'Slate Indigo',
    labelAr: 'نيلي رمادي',
    brandPrimary: Color(0xFF3645E2),
    onBrandPrimary: Color(0xFFFFFFFF),
    brandPrimaryContainer: Color(0xFF9DA4F1),
    onBrandPrimaryContainer: Color(0xFF1F2C61),
    brandInk: Color(0xFF3645E2),
  ),
  warmTerracotta(
    seedColor: Color(0xFF8A5238),
    labelEn: 'Warm Terracotta',
    labelAr: 'طيني دافئ',
    brandPrimary: Color(0xFFC74605),
    onBrandPrimary: Color(0xFFFFFFFF),
    brandPrimaryContainer: Color(0xFFFBA174),
    onBrandPrimaryContainer: Color(0xFF542105),
    brandInk: Color(0xFFC74605),
  );

  const AppColorSeed({
    required this.seedColor,
    required this.labelEn,
    required this.labelAr,
    required this.brandPrimary,
    required this.onBrandPrimary,
    required this.brandPrimaryContainer,
    required this.onBrandPrimaryContainer,
    required this.brandInk,
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

  /// Replaces `ColorScheme.fromSeed`'s own light-mode `primaryContainer` —
  /// that algorithm's container tone is a pale, near-pastel tint (e.g.
  /// `#9DF0FB` for [calmTeal]), which read as a mismatched, washed-out
  /// surface once [brandPrimary] made the *solid* `primary` role vivid (the
  /// "Correct!" feedback banner and Home's "Continue learning" card both
  /// use this role, right next to solid-`primary` buttons/chips). Still
  /// clearly a lighter tint than [brandPrimary] — just not desaturated all
  /// the way to pastel. Same hue family, same AA-with-[onBrandPrimaryContainer]
  /// verification as [brandPrimary].
  final Color brandPrimaryContainer;

  /// Foreground colour for content drawn on [brandPrimaryContainer].
  final Color onBrandPrimaryContainer;

  /// Light-mode accent for text, icons and progress fills drawn *on* a
  /// neutral surface (`AppTokens.primaryInk`). Equal to [brandPrimary]
  /// wherever that already meets 4.5:1 on white ([slateIndigo] 6.8:1,
  /// [warmTerracotta] 4.9:1); [calmTeal]'s vivid cyan only reaches ~1.9:1,
  /// so it gets a deeper tone in the same hue (5.1:1).
  final Color brandInk;
}
