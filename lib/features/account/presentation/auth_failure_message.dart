import '../../../core/l10n/generated/app_localizations.dart';
import '../domain/auth_repository.dart';

/// The learner-facing message for [failure] — raw provider errors are never
/// shown. Null for [AuthFailure.cancelled]: closing the Google sheet is a
/// choice, not an error.
String? authFailureMessage(AppLocalizations l10n, AuthFailure failure) =>
    switch (failure) {
      AuthFailure.invalidEmail => l10n.authErrorInvalidEmail,
      AuthFailure.wrongCredentials => l10n.authErrorWrongCredentials,
      AuthFailure.emailAlreadyInUse => l10n.authErrorEmailInUse,
      AuthFailure.weakPassword => l10n.authErrorWeakPassword,
      AuthFailure.userDisabled => l10n.authErrorUserDisabled,
      AuthFailure.tooManyRequests => l10n.authErrorTooManyRequests,
      AuthFailure.network => l10n.authErrorNetwork,
      AuthFailure.accountExistsWithDifferentMethod =>
        l10n.authErrorDifferentMethod,
      AuthFailure.unavailable => l10n.authErrorUnavailable,
      AuthFailure.unknown => l10n.authErrorUnknown,
      AuthFailure.cancelled => null,
    };

/// A deliberately loose check — the server has the final word; this only
/// catches typos before a round trip.
bool looksLikeEmail(String value) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
