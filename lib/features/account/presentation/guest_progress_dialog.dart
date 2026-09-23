import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../providers/account_providers.dart';

/// Asks whether the progress this phone collected as a guest joins the
/// account that just signed in. Dismissing it decides nothing — the choice
/// stays open on the Settings account row, and nothing syncs until it is
/// made. Neither answer deletes anything.
Future<void> showGuestProgressDecision(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context)!;
  final attach = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.phone_android_rounded),
      title: Text(l10n.guestProgressTitle),
      content: Text(l10n.guestProgressBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.guestProgressKeepSeparate),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.guestProgressAttach),
        ),
      ],
    ),
  );
  if (attach == null) return;
  await ref
      .read(accountSessionProvider.notifier)
      .resolveGuestProgress(attach: attach);
}
