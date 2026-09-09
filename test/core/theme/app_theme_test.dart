import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';

void main() {
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

    test('leaves every other role exactly as ColorScheme.fromSeed derives it — '
        'only primary/onPrimary/primaryContainer/onPrimaryContainer are '
        'hand-picked', () {
      final generated = ColorScheme.fromSeed(
        seedColor: AppColorSeed.calmTeal.seedColor,
        brightness: Brightness.light,
      );
      final theme = AppTheme.light(AppColorSeed.calmTeal);
      expect(theme.colorScheme.surface, generated.surface);
      expect(theme.colorScheme.surfaceContainer, generated.surfaceContainer);
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
