import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../providers/tests_home_providers.dart';

/// Tests tab landing screen — links out to the A1 Gateway Placement Test,
/// the Final Mission, and the Final Assessment, each showing its own latest-
/// attempt state (not yet taken / in progress / completed on a date), plus
/// two informational entries: unit mastery checks (already visible as unit
/// badges on the Learn tab, not a separate flow) and future-level placement
/// (Coming Soon — this app has no content beyond A1 yet).
class TestsHomeScreen extends ConsumerWidget {
  const TestsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final placementAsync = ref.watch(latestPlacementAttemptProvider);
    final missionAsync = ref.watch(latestFinalMissionAttemptProvider);
    final assessmentAsync = ref.watch(latestFinalAssessmentAttemptProvider);
    final locale = Localizations.localeOf(context).languageCode;

    String stateLine(DateTime? startedAt, DateTime? completedAt) {
      if (startedAt == null) return l10n.testsHomeNotYetTaken;
      if (completedAt == null) return l10n.testsHomeInProgress;
      return l10n.testsHomeCompletedOn(
        DateFormat.yMMMd(locale).format(completedAt),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTests)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TestCard(
            icon: Icons.flag_outlined,
            title: l10n.testsHomePlacementTitle,
            subtitle: l10n.testsHomePlacementSubtitle,
            stateLine: stateLine(
              placementAsync.value?.startedAt,
              placementAsync.value?.completedAt,
            ),
            onTap: () => context.push('/tests/placement'),
          ),
          const SizedBox(height: 12),
          _TestCard(
            icon: Icons.explore_outlined,
            title: l10n.testsHomeFinalMissionTitle,
            subtitle: l10n.testsHomeFinalMissionSubtitle,
            stateLine: stateLine(
              missionAsync.value?.startedAt,
              missionAsync.value?.completedAt,
            ),
            onTap: () => context.push('/tests/final-mission'),
          ),
          const SizedBox(height: 12),
          _TestCard(
            icon: Icons.fact_check_outlined,
            title: l10n.testsHomeFinalAssessmentTitle,
            subtitle: l10n.testsHomeFinalAssessmentSubtitle,
            stateLine: stateLine(
              assessmentAsync.value?.startedAt,
              assessmentAsync.value?.completedAt,
            ),
            onTap: () => context.push('/tests/final-assessment'),
          ),
          const SizedBox(height: 12),
          _TestCard(
            icon: Icons.checklist_outlined,
            title: l10n.testsHomeUnitChecksTitle,
            subtitle: l10n.testsHomeUnitChecksSubtitle,
            stateLine: null,
            onTap: () => context.go('/learn/a1'),
          ),
          const SizedBox(height: 12),
          _TestCard(
            icon: Icons.upgrade_outlined,
            title: l10n.testsHomeFutureLevelsTitle,
            subtitle: l10n.comingSoon,
            stateLine: null,
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.stateLine,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? stateLine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            if (stateLine != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  stateLine!,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ),
          ],
        ),
        isThreeLine: stateLine != null,
        enabled: onTap != null,
        onTap: onTap,
      ),
    );
  }
}
