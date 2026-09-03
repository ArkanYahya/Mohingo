import 'package:flutter/material.dart';

import '../../../content/catalog/level_catalog.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../learning_path/presentation/unit_path_view.dart';

/// Routed at `/learn/:levelId`. Only ever meaningfully reached for `a1` —
/// [LevelCatalogScreen]'s Coming Soon cards are disabled, not tappable —
/// but a stray deep link to a Coming Soon level id is handled defensively
/// rather than assumed impossible. See docs/ARCHITECTURE.md.
class LevelDetailScreen extends StatelessWidget {
  const LevelDetailScreen({required this.levelId, super.key});

  final String levelId;

  @override
  Widget build(BuildContext context) {
    final entry = levelCatalogEntry(levelId);
    if (entry == null || entry.availability != LevelAvailability.available) {
      return const _ComingSoonLevelScreen();
    }
    // Only 'a1' is ever available in v1 — the guided path view is A1-shaped
    // for now; a future level bundle would need its own path view or a
    // generalized one, not attempted here.
    return const UnitPathView();
  }
}

class _ComingSoonLevelScreen extends StatelessWidget {
  const _ComingSoonLevelScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            AppLocalizations.of(context)!.comingSoonLevelBody,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
