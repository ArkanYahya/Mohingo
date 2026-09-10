import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/core/theme/feedback_theme_extension.dart';
import 'package:mohingo/core/widgets/status_indicator.dart';

Widget _wrapped(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(AppColorSeed.calmTeal),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders a distinct icon/color/label per state', (tester) async {
    final cases =
        <ProgressState, (IconData, String Function(AppLocalizations))>{
          ProgressState.notStarted: (
            Icons.circle_outlined,
            (l10n) => l10n.unitStateNotStarted,
          ),
          ProgressState.inProgress: (
            Icons.incomplete_circle,
            (l10n) => l10n.unitStateInProgress,
          ),
          ProgressState.needsReview: (
            Icons.refresh,
            (l10n) => l10n.unitStateNeedsReview,
          ),
          ProgressState.mastered: (
            Icons.check_circle,
            (l10n) => l10n.unitStateMastered,
          ),
        };

    for (final entry in cases.entries) {
      await tester.pumpWidget(_wrapped(StatusIndicator(state: entry.key)));
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, entry.value.$1, reason: 'icon for ${entry.key}');

      final context = tester.element(find.byType(Scaffold));
      final l10n = AppLocalizations.of(context)!;
      expect(icon.semanticLabel, entry.value.$2(l10n));
    }
  });

  testWidgets('mastered and notStarted use different colors', (tester) async {
    await tester.pumpWidget(
      _wrapped(const StatusIndicator(state: ProgressState.mastered)),
    );
    final masteredIcon = tester.widget<Icon>(find.byType(Icon));

    await tester.pumpWidget(
      _wrapped(const StatusIndicator(state: ProgressState.notStarted)),
    );
    final notStartedIcon = tester.widget<Icon>(find.byType(Icon));

    expect(masteredIcon.color, isNot(equals(notStartedIcon.color)));
  });

  testWidgets(
    "mastered uses the theme's semantic success colour (a real green), not "
    "colorScheme.primary — a per-theme brand colour (e.g. warmTerracotta's "
    'orange) doesn\'t read as "success" the way green universally does',
    (tester) async {
      await tester.pumpWidget(
        _wrapped(const StatusIndicator(state: ProgressState.mastered)),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));

      final context = tester.element(find.byType(Icon));
      final feedbackTheme = Theme.of(context).extension<FeedbackTheme>()!;
      final colorScheme = Theme.of(context).colorScheme;

      expect(icon.color, feedbackTheme.success);
      expect(icon.color, isNot(equals(colorScheme.primary)));
    },
  );

  testWidgets('colorOverride replaces the state-derived colour (icon shape and '
      'semantic label are unaffected) — used to force the "current lesson" '
      'highlight to read as the brand accent regardless of its raw state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrapped(
        StatusIndicator(
          state: ProgressState.notStarted,
          colorOverride: const Color(0xFF3645E2),
        ),
      ),
    );
    final icon = tester.widget<Icon>(find.byType(Icon));

    final context = tester.element(find.byType(Icon));
    final l10n = AppLocalizations.of(context)!;

    expect(icon.color, const Color(0xFF3645E2));
    expect(icon.icon, Icons.circle_outlined);
    expect(icon.semanticLabel, l10n.unitStateNotStarted);
  });
}
