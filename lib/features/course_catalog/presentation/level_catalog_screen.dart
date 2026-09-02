import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/placeholder_screen.dart';

/// Learn tab landing screen — the CEFR level catalogue (A1 available,
/// A2-C2 Coming Soon). Real content arrives in a later phase — see
/// docs/ARCHITECTURE.md's `course_catalog` feature and `lib/content/catalog`.
class LevelCatalogScreen extends StatelessWidget {
  const LevelCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(title: AppLocalizations.of(context)!.navLearn);
  }
}
