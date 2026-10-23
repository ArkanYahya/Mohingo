import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../domain/auth_repository.dart';
import '../providers/account_providers.dart';
import 'auth_failure_message.dart';
import 'guest_progress_dialog.dart';

/// Sign in, or create an account — one screen, two modes, switched in
/// place. Reached from Settings; accounts are optional, so leaving it
/// (back) is always fine.
///
/// While a request runs, the form is disabled and the primary button shows
/// progress. Failures appear under the form as a bilingual message, never a
/// raw provider error (`authFailureMessage`). Sign in with Apple is offered
/// where the platform supports it (iPhone), above Google, in Apple's own
/// black-or-white style. After signing in, a phone
/// with guest progress asks what to do with it
/// ([showGuestProgressDecision]); then the screen closes.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.createAccount = false});

  /// Opens in create-account mode rather than sign-in.
  final bool createAccount;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late bool _creating = widget.createAccount;
  bool _busy = false;
  bool _obscure = true;
  AuthFailure? _failure;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authRepositoryProvider);
    await _run(
      () => _creating
          ? auth.createAccountWithEmail(
              email: _email.text,
              password: _password.text,
            )
          : auth.signInWithEmail(email: _email.text, password: _password.text),
    );
  }

  Future<void> _submitGoogle() =>
      _run(() => ref.read(authRepositoryProvider).signInWithGoogle());

  Future<void> _submitApple() =>
      _run(() => ref.read(authRepositoryProvider).signInWithApple());

  Future<void> _run(Future<AuthUser> Function() signIn) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final user = await signIn();
      final session = await ref
          .read(accountSessionProvider.notifier)
          .settleFor(user);
      if (!mounted) return;
      if (session is GuestProgressDecision) {
        setState(() => _busy = false); // the dialog takes over
        await showGuestProgressDecision(context, ref);
      }
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.accountSignedIn)));
      context.pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = e.failure == AuthFailure.cancelled ? null : e.failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authRepositoryProvider);
    final failureText = _failure == null
        ? null
        : authFailureMessage(l10n, _failure!);

    return Scaffold(
      appBar: AppBar(
        title: Text(_creating ? l10n.authCreateTitle : l10n.authSignInTitle),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.md),
                children: [
                  Text(
                    l10n.authIntro,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  TextFormField(
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    // An address is Latin script whatever the interface
                    // language.
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: l10n.authEmailLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => looksLikeEmail(value ?? '')
                        ? null
                        : l10n.authEmailInvalid,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  TextFormField(
                    controller: _password,
                    enabled: !_busy,
                    obscureText: _obscure,
                    textInputAction: _creating
                        ? TextInputAction.next
                        : TextInputAction.done,
                    autofillHints: [
                      _creating
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    textDirection: TextDirection.ltr,
                    onFieldSubmitted: (_) {
                      if (!_creating) _submitEmail();
                    },
                    decoration: InputDecoration(
                      labelText: l10n.authPasswordLabel,
                      helperText: _creating ? l10n.authPasswordHint : null,
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
                    validator: (value) {
                      final password = value ?? '';
                      if (password.isEmpty) return l10n.authPasswordRequired;
                      if (_creating && password.length < 6) {
                        return l10n.authPasswordTooShort;
                      }
                      return null;
                    },
                  ),
                  if (_creating) ...[
                    const SizedBox(height: AppSpace.sm),
                    TextFormField(
                      controller: _confirm,
                      enabled: !_busy,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      textDirection: TextDirection.ltr,
                      onFieldSubmitted: (_) => _submitEmail(),
                      decoration: InputDecoration(
                        labelText: l10n.authConfirmPasswordLabel,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => value == _password.text
                          ? null
                          : l10n.authPasswordsDontMatch,
                    ),
                  ],
                  if (!_creating)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: _busy
                            ? null
                            : () => context.push(
                                '/account/forgot-password',
                                extra: _email.text.trim(),
                              ),
                        child: Text(l10n.authForgotPasswordLink),
                      ),
                    ),
                  if (failureText != null) ...[
                    const SizedBox(height: AppSpace.xs),
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
                    onPressed: _busy ? null : _submitEmail,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _creating
                                ? l10n.authCreateAction
                                : l10n.authSignInAction,
                          ),
                  ),
                  if (auth.supportsApple || auth.supportsGoogle) ...[
                    const SizedBox(height: AppSpace.md),
                    Row(
                      children: [
                        Expanded(child: Divider(color: tokens.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.sm,
                          ),
                          child: Text(
                            l10n.authOr,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: tokens.border)),
                      ],
                    ),
                  ],
                  if (auth.supportsApple) ...[
                    const SizedBox(height: AppSpace.md),
                    _AppleButton(onPressed: _busy ? null : _submitApple),
                  ],
                  if (auth.supportsGoogle) ...[
                    const SizedBox(height: AppSpace.md),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _submitGoogle,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      icon: const Icon(Icons.account_circle_outlined),
                      label: Text(l10n.authGoogleAction),
                    ),
                  ],
                  const SizedBox(height: AppSpace.lg),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _creating = !_creating;
                            _failure = null;
                            _formKey.currentState?.reset();
                          }),
                    child: Text(
                      _creating
                          ? l10n.authSwitchToSignIn
                          : l10n.authSwitchToCreate,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Continue with Apple", drawn to Apple's rules for a custom Sign in with
/// Apple button rather than the app's own: black on a light screen, white
/// on a dark one, the Apple logo in the title's colour, never the accent.
/// See docs/DESIGN_SYSTEM.md, Sign in with Apple.
class _AppleButton extends StatelessWidget {
  const _AppleButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: dark ? Colors.white : Colors.black,
        foregroundColor: dark ? Colors.black : Colors.white,
      ),
      icon: const Icon(Icons.apple),
      label: Text(l10n.authAppleAction),
    );
  }
}
