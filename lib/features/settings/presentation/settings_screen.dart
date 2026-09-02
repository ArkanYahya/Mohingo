import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/placeholder_screen.dart';

/// Settings tab landing screen — language, theme, speech, privacy/about,
/// reset progress. Real content arrives in a later phase — see
/// docs/ARCHITECTURE.md's `settings` feature.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(title: AppLocalizations.of(context)!.navSettings);
  }
}
