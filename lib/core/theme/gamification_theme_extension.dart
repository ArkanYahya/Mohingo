import 'package:flutter/material.dart';

/// The single approved "light gamification" accent (see docs/DESIGN_SYSTEM.md).
///
/// Deliberately not part of [ColorScheme] and deliberately intended for
/// exactly one place in the UI (the Home streak/progress indicator) so it
/// never creeps into a general-purpose accent colour the way the old
/// Duolingo-style `color.accent` token did.
@immutable
class GamificationTheme extends ThemeExtension<GamificationTheme> {
  const GamificationTheme({required this.streakAccent});

  final Color streakAccent;

  static const light = GamificationTheme(streakAccent: Color(0xFFB7791F));
  static const dark = GamificationTheme(streakAccent: Color(0xFFD9A441));

  @override
  GamificationTheme copyWith({Color? streakAccent}) {
    return GamificationTheme(streakAccent: streakAccent ?? this.streakAccent);
  }

  @override
  GamificationTheme lerp(ThemeExtension<GamificationTheme>? other, double t) {
    if (other is! GamificationTheme) return this;
    return GamificationTheme(
      streakAccent: Color.lerp(streakAccent, other.streakAccent, t)!,
    );
  }
}
