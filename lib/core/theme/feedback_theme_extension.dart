import 'package:flutter/material.dart';

/// The app-wide semantic "success" accent — a real green, deliberately
/// separate from [ColorScheme.primary]. See docs/DESIGN_SYSTEM.md.
///
/// Before this existed, the "correct answer" feedback banner and the
/// mastered/correct chip states all read from `colorScheme.primary`/
/// `primaryContainer` — meaning "correct" was whatever colour the learner's
/// chosen theme happened to be (a vivid orange for `warmTerracotta`), not
/// the green every learner already associates with "right" from virtually
/// every other app. [success]/[onSuccess] are for solid fills (a correct
/// answer chip, a mastered status icon); [successContainer]/
/// [onSuccessContainer] are for the softer "Correct!" banner — same
/// light/dark split as [ColorScheme.error]/[ColorScheme.errorContainer],
/// which this is the positive counterpart to. Not part of [ColorScheme]
/// itself since Material 3 has no built-in "success" role, mirroring how
/// [GamificationTheme]'s `streakAccent` already lives outside it.
@immutable
class FeedbackTheme extends ThemeExtension<FeedbackTheme> {
  const FeedbackTheme({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  /// Verified against the WCAG 2.1 relative-luminance formula: `#157A36`
  /// on white is 5.43:1, `#0F5C28` on `#E3F5E8` is 7.16:1 — both clear the
  /// 4.5:1 AA floor docs/UX_PRINCIPLES.md commits to.
  static const light = FeedbackTheme(
    success: Color(0xFF157A36),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFE3F5E8),
    onSuccessContainer: Color(0xFF0F5C28),
  );

  /// A solid saturated fill reads fine at chip/icon scale even on a dark
  /// surface, so [success] stays a genuine green rather than switching to
  /// a tinted-container treatment the way a full-screen banner would need
  /// to (see [successContainer], which does exactly that: a dark-tinted
  /// background with bright text, matching `colorScheme.errorContainer`'s
  /// own dark-mode shape, rather than a saturated fill that would glow
  /// against near-black). Verified: `#4ADE80` on `#0B2E17` is 8.50:1,
  /// `#16311F` on `#7EE39C` is 8.94:1.
  static const dark = FeedbackTheme(
    success: Color(0xFF4ADE80),
    onSuccess: Color(0xFF0B2E17),
    successContainer: Color(0xFF16311F),
    onSuccessContainer: Color(0xFF7EE39C),
  );

  @override
  FeedbackTheme copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
  }) {
    return FeedbackTheme(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    );
  }

  @override
  FeedbackTheme lerp(ThemeExtension<FeedbackTheme>? other, double t) {
    if (other is! FeedbackTheme) return this;
    return FeedbackTheme(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
    );
  }
}
