import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/placeholder_screen.dart';

/// Home tab landing screen. Real content (Continue learning card, Today's
/// review, A1 progress overview, etc.) arrives in a later phase — see
/// docs/PRODUCT.md's Home requirements.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(title: AppLocalizations.of(context)!.navHome);
  }
}
