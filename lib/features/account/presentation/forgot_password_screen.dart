import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../domain/auth_repository.dart';
import '../providers/account_providers.dart';
import 'auth_failure_message.dart';

/// Sends a password-reset email. The confirmation never says whether an
/// account exists for the address, so this screen can't be used to probe
/// for accounts.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _busy = false;
  String? _sentTo;
  AuthFailure? _failure;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final email = _email.text.trim();
    AuthFailure? failure;
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email: email);
    } on AuthException catch (e) {
      // "No such account" is reported as sent, like any address.
      if (e.failure != AuthFailure.wrongCredentials) failure = e.failure;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failure = failure;
      _sentTo = failure == null ? email : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final failureText = _failure == null
        ? null
        : authFailureMessage(l10n, _failure!);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authResetTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.md),
                children: [
                  if (_sentTo == null) ...[
                    Text(
                      l10n.authResetBody,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    TextFormField(
                      controller: _email,
                      enabled: !_busy,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      textDirection: TextDirection.ltr,
                      onFieldSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        labelText: l10n.authEmailLabel,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => looksLikeEmail(value ?? '')
                          ? null
                          : l10n.authEmailInvalid,
                    ),
                    if (failureText != null) ...[
                      const SizedBox(height: AppSpace.sm),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          failureText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpace.md),
                    FilledButton(
                      onPressed: _busy ? null : _send,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: _busy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.authResetAction),
                    ),
                  ] else ...[
                    Icon(
                      Icons.mark_email_read_outlined,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpace.md),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        l10n.authResetSent(_sentTo!),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    FilledButton(
                      onPressed: () => context.pop(),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(l10n.authBackToSignIn),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
