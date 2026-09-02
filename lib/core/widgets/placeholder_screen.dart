import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// A scaffold screen with no real content yet.
///
/// Used only for feature areas genuinely scheduled in a later implementation
/// phase — never as a way to hide incomplete v1-scope functionality behind a
/// fake success state. See CLAUDE.md's implementation-workflow rule.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(l10n.placeholderScreenBody(title))),
    );
  }
}
