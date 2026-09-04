import 'package:flutter/material.dart';

/// The single approved "light gamification" accent (see docs/DESIGN_SYSTEM.md).
///
/// Deliberately not part of [ColorScheme] and deliberately intended for
/// exactly one place in the UI (the Home streak/progress indicator) so it
/// never creeps into a general-purpose accent colour the way the old
/// Duolingo-style `color.accent` token did.
@immutable
class GamificationTheme extends ThemeExtension<GamificationTheme> {
  const GamificationTheme({
    required this.streakAccent,
    required this.onStreakAccent,
  });

  final Color streakAccent;

  /// Foreground colour for content drawn *on* [streakAccent].
  ///
  /// [streakAccent] deliberately sits outside [ColorScheme], so it has no
  /// `onStreakAccent` counterpart there to borrow — and borrowing
  /// `onPrimary` is wrong: white on the light theme's `#B7791F` computes to
  /// only 3.64:1, under the 4.5:1 WCAG 2.1 AA floor docs/UX_PRINCIPLES.md
  /// commits to. Both values below are warm near-blacks verified against
  /// their own ground with the WCAG relative-luminance formula:
  /// `#1A1200` on `#B7791F` is 5.10:1, `#2B1D00` on `#D9A441` is 7.30:1.
  final Color onStreakAccent;

  static const light = GamificationTheme(
    streakAccent: Color(0xFFB7791F),
    onStreakAccent: Color(0xFF1A1200),
  );
  static const dark = GamificationTheme(
    streakAccent: Color(0xFFD9A441),
    onStreakAccent: Color(0xFF2B1D00),
  );

  @override
  GamificationTheme copyWith({Color? streakAccent, Color? onStreakAccent}) {
    return GamificationTheme(
      streakAccent: streakAccent ?? this.streakAccent,
      onStreakAccent: onStreakAccent ?? this.onStreakAccent,
    );
  }

  @override
  GamificationTheme lerp(ThemeExtension<GamificationTheme>? other, double t) {
    if (other is! GamificationTheme) return this;
    return GamificationTheme(
      streakAccent: Color.lerp(streakAccent, other.streakAccent, t)!,
      onStreakAccent: Color.lerp(onStreakAccent, other.onStreakAccent, t)!,
    );
  }
}
