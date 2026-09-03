import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/generated/app_localizations.dart';

/// Tests tab landing screen — links out to the A1 Gateway Placement Test,
/// the Final Mission, and the Final Assessment (each owns its own flow, see
/// `lib/features/placement_test`/`final_mission`/`final_assessment`), plus
/// two informational entries: unit mastery checks (already visible as unit
/// badges on the Learn tab, not a separate flow) and future-level placement
/// (Coming Soon — this app has no content beyond A1 yet).
class TestsHomeScreen extends StatelessWidget {
  const TestsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTests)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TestCard(
            icon: Icons.flag_outlined,
            title: l10n.testsHomePlacementTitle,
            subtitle: l10n.testsHomePlacementSubtitle,
            onTap: () => context.push('/tests/placement'),
          ),
          const SizedBox(height: 12),
          _TestCard(
            icon: Icons.explore_outlined,
            title: l10n.testsHomeFinalMissionTitle,
            subtitle: l10n.testsHomeFinalMissionSubtitle,
            onTap: () => context.push('/tests/final-mission'),
          ),
          const SizedBox(height: 12),
          _TestCard(
            icon: Icons.fact_check_outlined,
            title: l10n.testsHomeFinalAssessmentTitle,
            subtitle: l10n.testsHomeFinalAssessmentSubtitle,
            onTap: () => context.push('/tests/final-assessment'),
          ),
          const SizedBox(height: 12),
          _TestCard(
            icon: Icons.checklist_outlined,
            title: l10n.testsHomeUnitChecksTitle,
            subtitle: l10n.testsHomeUnitChecksSubtitle,
            onTap: () => context.go('/learn/a1'),
          ),
          const SizedBox(height: 12),
          _TestCard(
            icon: Icons.upgrade_outlined,
            title: l10n.testsHomeFutureLevelsTitle,
            subtitle: l10n.comingSoon,
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
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        enabled: onTap != null,
        onTap: onTap,
      ),
    );
  }
}
