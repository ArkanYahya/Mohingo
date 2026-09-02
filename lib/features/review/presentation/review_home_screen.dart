import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/placeholder_screen.dart';

/// Review tab landing screen — unites due vocabulary/chunks, favourites,
/// incorrect-answer history, and weak Can-Do objectives. Real content arrives
/// in a later phase — see docs/ARCHITECTURE.md's `review` feature.
class ReviewHomeScreen extends StatelessWidget {
  const ReviewHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(title: AppLocalizations.of(context)!.navReview);
  }
}
