import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// The 4 progress states shown across Learn, Review, and Tests — mirrors
/// [UnitProgressState] but lives in the presentation layer since not every
/// consumer (e.g. vocabulary review rows) is backed by that exact enum. See
/// docs/superpowers/specs/2026-09-04-ui-navigation-redesign-design.md.
enum ProgressState {
  notStarted,
  inProgress,
  needsReview,
  mastered;

  /// Parses a raw progress-state string (e.g. from [UnitProgressData.state]),
  /// falling back to [notStarted] for `null` or anything unrecognized.
  static ProgressState fromRaw(String? raw) {
    return ProgressState.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => ProgressState.notStarted,
    );
  }
}

/// The shared icon+color+text status indicator used on Learn's unit spine
/// and lesson rows, Review's vocabulary/chunk rows, and Tests' cards. Never
/// color alone, per docs/UX_PRINCIPLES.md's accessibility rule.
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({
    required this.state,
    this.size = 22,
    this.semanticLabelOverride,
    super.key,
  });

  final ProgressState state;
  final double size;

  /// Replaces the [state]-derived screen-reader label when non-null; the
  /// icon and colour still come from [state].
  ///
  /// Exists because [ProgressState.mastered] is reused for three different
  /// things: a *unit* that genuinely met `MasteryAggregationService`'s
  /// mastery policy, a *lesson* merely played to its last activity, and a
  /// *vocabulary item* that graduated the spaced-review schedule. Only the
  /// first is "mastery" as docs/GLOSSARY.md defines it, so the other two
  /// pass their own honest label here rather than announcing "Mastered".
  final String? semanticLabelOverride;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final (IconData icon, Color color, String defaultLabel) = switch (state) {
      ProgressState.notStarted => (
        Icons.circle_outlined,
        colorScheme.onSurfaceVariant,
        l10n.unitStateNotStarted,
      ),
      ProgressState.inProgress => (
        Icons.incomplete_circle,
        colorScheme.tertiary,
        l10n.unitStateInProgress,
      ),
      ProgressState.needsReview => (
        Icons.refresh,
        colorScheme.tertiary,
        l10n.unitStateNeedsReview,
      ),
      ProgressState.mastered => (
        Icons.check_circle,
        colorScheme.primary,
        l10n.unitStateMastered,
      ),
    };
    return Icon(
      icon,
      color: color,
      size: size,
      semanticLabel: semanticLabelOverride ?? defaultLabel,
    );
  }
}
