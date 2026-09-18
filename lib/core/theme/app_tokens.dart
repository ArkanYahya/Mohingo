import 'package:flutter/material.dart';

/// The app's semantic neutral tokens — the page, card, text and border
/// colours every screen is built from, plus [primaryInk] for accent text
/// and the two colours derived from it ([onPrimaryInk], [primaryInkTint]).
///
/// Deliberately *not* derived from the colour-theme seed: picking a colour
/// theme in Settings changes the accent, never the greys. `ColorScheme`'s
/// neutral roles (`surface`, `onSurface`, `onSurfaceVariant`,
/// `outlineVariant`, the `surfaceContainer*` ramp) are set from these same
/// values in [AppTheme], so stock Material widgets inherit them too. See
/// docs/DESIGN_SYSTEM.md.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.page,
    required this.card,
    required this.cardMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.primaryInk,
    required this.onPrimaryInk,
    required this.primaryInkTint,
  });

  /// Screen background.
  final Color page;

  /// Raised container — always separates *lighter* than [page], in dark
  /// mode too (a darker card would read as sunken).
  final Color card;

  /// A quieter container or pill (chips, tracks, inactive states).
  final Color cardMuted;

  /// Hairline separators. Used sparingly — most separation comes from
  /// [card] against [page], not from outlining every object.
  final Color border;

  final Color textPrimary;

  /// Supporting / meta text. Meets 4.5:1 on [page], [card] and [cardMuted].
  final Color textSecondary;

  /// The brand accent in a tone that is legible as text, an icon or a
  /// progress fill on [card] (4.5:1). The solid `colorScheme.primary` fill
  /// is for buttons; this is for everything drawn *on* a neutral surface.
  final Color primaryInk;

  /// Text and icons on a solid [primaryInk] fill — filled buttons, the
  /// lesson player's play and microphone buttons. 4.5:1 on [primaryInk].
  final Color onPrimaryInk;

  /// The selected-state fill: a quiet wash of [primaryInk] over [card]
  /// (a chosen answer, a paired tile, the navigation indicator). Text in
  /// [textPrimary] stays at 4.5:1 on it.
  final Color primaryInkTint;

  static Color _tint(Color ink, Color card, double alpha) =>
      Color.alphaBlend(ink.withValues(alpha: alpha), card);

  static const _lightNeutrals = (
    page: Color(0xFFF5F3F0),
    card: Color(0xFFFFFFFF),
    cardMuted: Color(0xFFEFECE8),
    border: Color(0xFFE7E2DC),
    textPrimary: Color(0xFF1C1917),
    textSecondary: Color(0xFF635C55),
  );

  static const _darkNeutrals = (
    page: Color(0xFF121110),
    card: Color(0xFF1D1B19),
    cardMuted: Color(0xFF282522),
    border: Color(0xFF34302C),
    textPrimary: Color(0xFFF3EFEA),
    textSecondary: Color(0xFFABA49C),
  );

  factory AppTokens.light({
    required Color primaryInk,
    Color onPrimaryInk = const Color(0xFFFFFFFF),
  }) => AppTokens(
    page: _lightNeutrals.page,
    card: _lightNeutrals.card,
    cardMuted: _lightNeutrals.cardMuted,
    border: _lightNeutrals.border,
    textPrimary: _lightNeutrals.textPrimary,
    textSecondary: _lightNeutrals.textSecondary,
    primaryInk: primaryInk,
    onPrimaryInk: onPrimaryInk,
    primaryInkTint: _tint(primaryInk, _lightNeutrals.card, 0.12),
  );

  factory AppTokens.dark({
    required Color primaryInk,
    required Color onPrimaryInk,
  }) => AppTokens(
    page: _darkNeutrals.page,
    card: _darkNeutrals.card,
    cardMuted: _darkNeutrals.cardMuted,
    border: _darkNeutrals.border,
    textPrimary: _darkNeutrals.textPrimary,
    textSecondary: _darkNeutrals.textSecondary,
    primaryInk: primaryInk,
    onPrimaryInk: onPrimaryInk,
    primaryInkTint: _tint(primaryInk, _darkNeutrals.card, 0.2),
  );

  @override
  AppTokens copyWith({
    Color? page,
    Color? card,
    Color? cardMuted,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? primaryInk,
    Color? onPrimaryInk,
    Color? primaryInkTint,
  }) {
    return AppTokens(
      page: page ?? this.page,
      card: card ?? this.card,
      cardMuted: cardMuted ?? this.cardMuted,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      primaryInk: primaryInk ?? this.primaryInk,
      onPrimaryInk: onPrimaryInk ?? this.onPrimaryInk,
      primaryInkTint: primaryInkTint ?? this.primaryInkTint,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      page: Color.lerp(page, other.page, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardMuted: Color.lerp(cardMuted, other.cardMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      primaryInk: Color.lerp(primaryInk, other.primaryInk, t)!,
      onPrimaryInk: Color.lerp(onPrimaryInk, other.onPrimaryInk, t)!,
      primaryInkTint: Color.lerp(primaryInkTint, other.primaryInkTint, t)!,
    );
  }
}

/// The 8pt spacing scale — every gap and padding on the redesigned screens
/// comes from here, never an ad-hoc value.
abstract final class AppSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Corner radii, from small controls to the one hero card.
abstract final class AppRadius {
  static const double control = 12;
  static const double card = 16;
  static const double hero = 20;
}
