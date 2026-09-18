import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/app_tokens.dart';
import 'package:mohingo/core/theme/color_seed.dart';

/// WCAG 2.1 contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

final _themes = <String, ThemeData>{
  for (final seed in AppColorSeed.values) ...{
    '${seed.name}/light': AppTheme.light(seed),
    '${seed.name}/dark': AppTheme.dark(seed),
  },
};

void main() {
  group('AppTokens (semantic neutral tokens)', () {
    test('are registered on every theme, light and dark', () {
      for (final entry in _themes.entries) {
        expect(
          entry.value.extension<AppTokens>(),
          isNotNull,
          reason: entry.key,
        );
      }
    });

    test('surfaces are neutral, not seed-tinted — picking a colour theme '
        'changes the accent, never the page/card/text greys', () {
      for (final brightness in Brightness.values) {
        final tokens = AppColorSeed.values
            .map(
              (seed) =>
                  (brightness == Brightness.light
                          ? AppTheme.light(seed)
                          : AppTheme.dark(seed))
                      .extension<AppTokens>()!,
            )
            .toList();
        for (final t in tokens.skip(1)) {
          expect(t.page, tokens.first.page, reason: '$brightness page');
          expect(t.card, tokens.first.card, reason: '$brightness card');
          expect(t.textPrimary, tokens.first.textPrimary);
          expect(t.textSecondary, tokens.first.textSecondary);
          expect(t.border, tokens.first.border);
        }
      }
    });

    test('ColorScheme neutral roles and the scaffold follow the tokens, so '
        'every stock Material widget inherits the same surfaces', () {
      for (final entry in _themes.entries) {
        final theme = entry.value;
        final t = theme.extension<AppTokens>()!;
        expect(theme.colorScheme.surface, t.page, reason: entry.key);
        expect(theme.scaffoldBackgroundColor, t.page, reason: entry.key);
        expect(theme.colorScheme.onSurface, t.textPrimary, reason: entry.key);
        expect(
          theme.colorScheme.onSurfaceVariant,
          t.textSecondary,
          reason: entry.key,
        );
        expect(theme.colorScheme.outlineVariant, t.border, reason: entry.key);
      }
    });

    test('a card separates from the page in both modes — lighter than the '
        'page in light AND in dark (never a darker "sunken" card in dark)', () {
      for (final entry in _themes.entries) {
        final t = entry.value.extension<AppTokens>()!;
        final isDark = entry.key.endsWith('/dark');
        if (isDark) {
          expect(
            t.card.computeLuminance(),
            greaterThan(t.page.computeLuminance()),
            reason: entry.key,
          );
        } else {
          expect(
            t.card.computeLuminance(),
            greaterThanOrEqualTo(t.page.computeLuminance()),
            reason: entry.key,
          );
        }
      }
    });

    test('text tokens meet WCAG AA (4.5:1) on both the page and a card', () {
      for (final entry in _themes.entries) {
        final t = entry.value.extension<AppTokens>()!;
        for (final ground in [t.page, t.card, t.cardMuted]) {
          expect(
            _contrast(t.textPrimary, ground),
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key} textPrimary',
          );
          expect(
            _contrast(t.textSecondary, ground),
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key} textSecondary',
          );
        }
      }
    });

    test('primaryInk — the accent used for text, icons and progress on a '
        'neutral surface — meets 4.5:1 on a card for every seed and mode '
        "(calmTeal's cyan brandPrimary alone does not)", () {
      for (final entry in _themes.entries) {
        final t = entry.value.extension<AppTokens>()!;
        expect(
          _contrast(t.primaryInk, t.card),
          greaterThanOrEqualTo(4.5),
          reason: entry.key,
        );
      }
    });

    test('onPrimaryInk — text and icons drawn on a solid primaryInk fill '
        '(play/mic buttons, filled buttons) — meets 4.5:1 on it for every '
        'seed and mode, and is what FilledButton paints', () {
      for (final entry in _themes.entries) {
        final t = entry.value.extension<AppTokens>()!;
        expect(
          _contrast(t.onPrimaryInk, t.primaryInk),
          greaterThanOrEqualTo(4.5),
          reason: entry.key,
        );
        expect(
          entry.value.filledButtonTheme.style!.foregroundColor!.resolve({}),
          t.onPrimaryInk,
          reason: entry.key,
        );
      }
    });

    test('text buttons, outlined buttons, the text cursor, progress '
        'indicators and switches draw in primaryInk — Material defaults them to '
        "colorScheme.primary, and calmTeal's vivid cyan fails contrast as "
        'text or a thin line on the page', () {
      for (final entry in _themes.entries) {
        final theme = entry.value;
        final t = theme.extension<AppTokens>()!;
        expect(
          theme.textButtonTheme.style!.foregroundColor!.resolve({}),
          t.primaryInk,
          reason: entry.key,
        );
        expect(
          theme.outlinedButtonTheme.style!.foregroundColor!.resolve({}),
          t.primaryInk,
          reason: entry.key,
        );
        expect(
          theme.textSelectionTheme.cursorColor,
          t.primaryInk,
          reason: entry.key,
        );
        expect(
          theme.progressIndicatorTheme.color,
          t.primaryInk,
          reason: entry.key,
        );
        const on = {WidgetState.selected};
        expect(
          theme.switchTheme.trackColor!.resolve(on),
          t.primaryInk,
          reason: '${entry.key} switch track',
        );
        expect(
          theme.switchTheme.thumbColor!.resolve(on),
          t.onPrimaryInk,
          reason: '${entry.key} switch thumb',
        );
      }
    });

    test('primaryInkTint — the selected-state fill — is a quiet wash of '
        'primaryInk over a card that textPrimary still reads on at 4.5:1, '
        'and is the navigation bar indicator too', () {
      for (final entry in _themes.entries) {
        final t = entry.value.extension<AppTokens>()!;
        expect(t.primaryInkTint, isNot(t.card), reason: entry.key);
        expect(
          _contrast(t.textPrimary, t.primaryInkTint),
          greaterThanOrEqualTo(4.5),
          reason: entry.key,
        );
        expect(
          _contrast(t.primaryInk, t.primaryInkTint),
          greaterThanOrEqualTo(3),
          reason: '${entry.key}: a selected border must still show',
        );
        expect(
          entry.value.navigationBarTheme.indicatorColor,
          t.primaryInkTint,
          reason: entry.key,
        );
      }
    });
  });

  group('AppTheme typography', () {
    test('defines the deliberate text hierarchy (header / section / card '
        'title / body / meta) rather than stock M3 sizes', () {
      final text = AppTheme.light(AppColorSeed.calmTeal).textTheme;
      expect(text.headlineSmall!.fontSize, 24);
      expect(text.headlineSmall!.fontWeight, FontWeight.w700);
      expect(text.titleLarge!.fontSize, 20);
      expect(text.titleLarge!.fontWeight, FontWeight.w700);
      expect(text.titleSmall!.fontSize, 15);
      expect(text.titleSmall!.fontWeight, FontWeight.w600);
      expect(text.bodyMedium!.fontSize, 14);
      expect(text.labelSmall!.fontWeight, FontWeight.w700);
    });
  });

  group('AppTheme filled button', () {
    test('its label meets 4.5:1 on its fill for every seed and mode — '
        'including calmTeal, whose raw cyan brand fill cannot carry white '
        'text', () {
      for (final entry in _themes.entries) {
        final style = entry.value.filledButtonTheme.style!;
        final bg = style.backgroundColor!.resolve({})!;
        final fg = style.foregroundColor!.resolve({})!;
        expect(_contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: entry.key);
      }
    });
  });

  group('AppTheme navigation bar', () {
    test('is a light, 64px bar on the card surface with a visible selected '
        'indicator whose icon colour passes 3:1 against it (WCAG 1.4.11)', () {
      for (final entry in _themes.entries) {
        final theme = entry.value;
        final nav = theme.navigationBarTheme;
        final t = theme.extension<AppTokens>()!;
        expect(nav.height, 64, reason: entry.key);
        expect(nav.backgroundColor, t.card, reason: entry.key);
        expect(nav.indicatorColor, isNotNull, reason: entry.key);
        final selectedIcon = nav.iconTheme!.resolve({WidgetState.selected})!;
        expect(
          _contrast(selectedIcon.color!, nav.indicatorColor!),
          greaterThanOrEqualTo(3),
          reason: entry.key,
        );
      }
    });
  });
  group('AppTheme.light', () {
    test("overrides primary/onPrimary with the seed's flat brand accent, not "
        'the algorithm-derived tone — see docs/DESIGN_SYSTEM.md', () {
      final theme = AppTheme.light(AppColorSeed.calmTeal);
      expect(theme.colorScheme.primary, AppColorSeed.calmTeal.brandPrimary);
      expect(theme.colorScheme.onPrimary, AppColorSeed.calmTeal.onBrandPrimary);
    });

    test("overrides primaryContainer/onPrimaryContainer with the seed's own "
        "punchier tint too — the algorithm's pale, near-pastel container read "
        'as a mismatched, muted surface right next to the now-vivid primary '
        '(the reported "some are vivid and some are mute" follow-up: the '
        '"Correct!" banner and the Home "Continue learning" card both use '
        'this role)', () {
      final theme = AppTheme.light(AppColorSeed.calmTeal);
      expect(
        theme.colorScheme.primaryContainer,
        AppColorSeed.calmTeal.brandPrimaryContainer,
      );
      expect(
        theme.colorScheme.onPrimaryContainer,
        AppColorSeed.calmTeal.onBrandPrimaryContainer,
      );
    });

    test('leaves secondary/tertiary/error exactly as ColorScheme.fromSeed '
        'derives them — only primary roles and the neutral surfaces are '
        'hand-picked', () {
      final generated = ColorScheme.fromSeed(
        seedColor: AppColorSeed.calmTeal.seedColor,
        brightness: Brightness.light,
      );
      final theme = AppTheme.light(AppColorSeed.calmTeal);
      expect(theme.colorScheme.secondary, generated.secondary);
      expect(theme.colorScheme.tertiary, generated.tertiary);
      expect(theme.colorScheme.error, generated.error);
    });

    test('applies its own brand-accent pair for every approved seed', () {
      for (final seed in AppColorSeed.values) {
        final theme = AppTheme.light(seed);
        expect(theme.colorScheme.primary, seed.brandPrimary, reason: seed.name);
        expect(
          theme.colorScheme.onPrimary,
          seed.onBrandPrimary,
          reason: seed.name,
        );
        expect(
          theme.colorScheme.primaryContainer,
          seed.brandPrimaryContainer,
          reason: seed.name,
        );
        expect(
          theme.colorScheme.onPrimaryContainer,
          seed.onBrandPrimaryContainer,
          reason: seed.name,
        );
      }
    });
  });

  group('AppTheme.dark', () {
    test("is left as Material 3's pure algorithm output — its generated "
        'primary is already a light tone that reads clearly against the dark '
        "surface, unlike light mode's primary, which the algorithm deliberately "
        'keeps dark to guarantee white-text contrast (reading closer to ink '
        'than to an accent)', () {
      for (final seed in AppColorSeed.values) {
        final generated = ColorScheme.fromSeed(
          seedColor: seed.seedColor,
          brightness: Brightness.dark,
        );
        final theme = AppTheme.dark(seed);
        expect(theme.colorScheme.primary, generated.primary, reason: seed.name);
        expect(
          theme.colorScheme.onPrimary,
          generated.onPrimary,
          reason: seed.name,
        );
        expect(
          theme.colorScheme.primaryContainer,
          generated.primaryContainer,
          reason: seed.name,
        );
        expect(
          theme.colorScheme.onPrimaryContainer,
          generated.onPrimaryContainer,
          reason: seed.name,
        );
      }
    });
  });
}
