import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../progress/providers/learner_progress_refresh.dart';
import '../../sync/providers/sync_providers.dart';
import '../domain/auth_repository.dart';
import '../providers/account_providers.dart';
import 'auth_failure_message.dart';

/// "Delete account", from Settings: a confirmation that says exactly what
/// goes and what stays, then a fresh sign-in (the account's password, or
/// picking the Google account again — Firebase deletes only an account that
/// has just proved who it is), then the deletion ([deleteAccountProvider]).
/// Errors are explained in the learner's language inside the dialog, which
/// stays open so they can try again or cancel.
Future<void> runDeleteAccountFlow(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final user = container.read(accountSessionProvider).value?.user;
  if (user == null) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colorScheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        icon: Icon(Icons.person_remove_outlined, color: colorScheme.error),
        title: Text(l10n.accountDeleteConfirmTitle),
        content: SingleChildScrollView(
          child: Text(l10n.accountDeleteConfirmBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.accountCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.accountDeleteContinue),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) return;

  final deleted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ConfirmIdentityDialog(user: user),
  );
  if (deleted != true) return;
  // The Settings row that started this is gone with the account, so the
  // refresh and the message use what was taken from the context up front.
  refreshLearnerProgress(container.invalidate);
  messenger.showSnackBar(SnackBar(content: Text(l10n.accountDeleted)));
}

class _ConfirmIdentityDialog extends ConsumerStatefulWidget {
  const _ConfirmIdentityDialog({required this.user});

  final AuthUser user;

  @override
  ConsumerState<_ConfirmIdentityDialog> createState() =>
      _ConfirmIdentityDialogState();
}

class _ConfirmIdentityDialogState
    extends ConsumerState<_ConfirmIdentityDialog> {
  final _password = TextEditingController();
  var _obscure = true;
  var _busy = false;
  String? _error;

  /// Email accounts confirm with their password; Google accounts by picking
  /// the Google account again.
  bool get _usesPassword =>
      widget.user.providers.contains(AuthProvider.emailPassword) ||
      !widget.user.providers.contains(AuthProvider.google);

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    if (_usesPassword && _password.text.isEmpty) {
      setState(() => _error = l10n.authPasswordRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      final auth = ref.read(authRepositoryProvider);
      if (_usesPassword) {
        await auth.reauthenticateWithPassword(_password.text);
      } else {
        await auth.reauthenticateWithGoogle();
      }
      await ref.read(deleteAccountProvider)();
      if (mounted) Navigator.of(context).pop(true);
      return;
    } on AuthException catch (e) {
      // Null for a closed Google sheet: not an error, just not done.
      error = authFailureMessage(l10n, e.failure);
    } on Object {
      error = l10n.accountDeleteFailed;
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = theme.colorScheme;
    final email = widget.user.email;

    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(l10n.accountDeletePasswordTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _usesPassword
                    ? (email == null
                          ? l10n.accountDeletePasswordBodyNoEmail
                          : l10n.accountDeletePasswordBody(email))
                    : l10n.accountDeleteGoogleBody,
              ),
              if (_usesPassword) ...[
                const SizedBox(height: AppSpace.md),
                TextField(
                  controller: _password,
                  enabled: !_busy,
                  obscureText: _obscure,
                  autofocus: true,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _delete(),
                  decoration: InputDecoration(
                    labelText: l10n.authPasswordLabel,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: _obscure
                          ? l10n.authShowPassword
                          : l10n.authHidePassword,
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
              ],
              if (_busy) ...[
                const SizedBox(height: AppSpace.md),
                Row(
                  children: [
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        l10n.accountDeleting,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (_error case final error?) ...[
                const SizedBox(height: AppSpace.sm),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    error,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
            child: Text(l10n.accountCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: _busy ? null : _delete,
            child: Text(
              _usesPassword ? l10n.accountDeleteTitle : l10n.authGoogleAction,
            ),
          ),
        ],
      ),
    );
  }
}
