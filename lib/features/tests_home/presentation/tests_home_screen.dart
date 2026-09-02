import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/placeholder_screen.dart';

/// Tests tab landing screen — lists the A1 Gateway Placement Test, unit
/// mastery checks, the Final Mission, and the Final Assessment. A thin
/// landing feature: it links out to `placement_test`/`final_mission`/
/// `final_assessment`, which own their own flows. Real content arrives in a
/// later phase — see docs/ARCHITECTURE.md.
class TestsHomeScreen extends StatelessWidget {
  const TestsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(title: AppLocalizations.of(context)!.navTests);
  }
}
