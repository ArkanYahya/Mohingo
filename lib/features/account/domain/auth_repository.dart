/// Who is signed in, in the app's own terms — no Firebase type crosses this
/// boundary. See docs/adr/0010-optional-accounts-and-progress-sync.md.
class AuthUser {
  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.providers = const {},
  });

  /// The account's stable id — the key its progress is stored under.
  final String uid;
  final String? email;
  final String? displayName;

  /// How this account can sign in.
  final Set<AuthProvider> providers;

  @override
  bool operator ==(Object other) => other is AuthUser && other.uid == uid;

  @override
  int get hashCode => uid.hashCode;
}

/// The sign-in methods the app offers. Adding one means a new value here, a
/// branch in the repository implementation, and a button — nothing else.
enum AuthProvider { emailPassword, google }

/// Why an account action failed, in terms the UI can explain. Each maps to
/// one bilingual message (`AuthFailureMessage`); raw provider errors never
/// reach learners.
enum AuthFailure {
  invalidEmail,
  wrongCredentials,
  emailAlreadyInUse,
  weakPassword,
  userDisabled,
  tooManyRequests,
  network,

  /// The learner closed the Google sign-in sheet — not an error to show.
  cancelled,

  /// This account was created with another sign-in method.
  accountExistsWithDifferentMethod,

  /// Firebase wants a fresh sign-in before a sensitive change (deleting
  /// the account) and the learner has not just confirmed who they are.
  requiresRecentLogin,

  /// The learner confirmed with a different account from the one signed in.
  wrongAccount,

  /// Accounts aren't set up in this build (no Firebase configuration).
  unavailable,
  unknown,
}

class AuthException implements Exception {
  const AuthException(this.failure);

  final AuthFailure failure;

  @override
  String toString() => 'AuthException(${failure.name})';
}

/// Sign-in, sign-up and sign-out, independent of any provider SDK. Every
/// method throws [AuthException] on failure and nothing else.
abstract interface class AuthRepository {
  /// Whether accounts work in this build at all.
  bool get isAvailable;

  /// Whether [signInWithGoogle] is offered on this platform.
  bool get supportsGoogle;

  AuthUser? get currentUser;

  /// Emits the signed-in user (or null) now and on every change, including
  /// a sign-in restored from the previous session.
  Stream<AuthUser?> authStateChanges();

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUser> createAccountWithEmail({
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset({required String email});

  Future<AuthUser> signInWithGoogle();

  Future<void> signOut();

  /// Confirms again that the signed-in learner is who they say, with the
  /// account's password — Firebase asks for this before deleting an
  /// account.
  Future<void> reauthenticateWithPassword(String password);

  /// As [reauthenticateWithPassword], for an account that signs in with
  /// Google: the learner picks their Google account again.
  Future<void> reauthenticateWithGoogle();

  /// Permanently deletes the signed-in account from the sign-in service.
  /// Call right after a reauthentication; the caller deletes the account's
  /// progress first (see `AccountSessionController.deleteAccount`).
  Future<void> deleteCurrentUser();
}

/// The repository used when Firebase isn't configured or failed to start:
/// the app runs exactly as it did before accounts existed.
class UnavailableAuthRepository implements AuthRepository {
  const UnavailableAuthRepository();

  @override
  bool get isAvailable => false;

  @override
  bool get supportsGoogle => false;

  @override
  AuthUser? get currentUser => null;

  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(null);

  Never _unavailable() => throw const AuthException(AuthFailure.unavailable);

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async => _unavailable();

  @override
  Future<AuthUser> createAccountWithEmail({
    required String email,
    required String password,
  }) async => _unavailable();

  @override
  Future<void> sendPasswordReset({required String email}) async =>
      _unavailable();

  @override
  Future<AuthUser> signInWithGoogle() async => _unavailable();

  @override
  Future<void> signOut() async {}

  @override
  Future<void> reauthenticateWithPassword(String password) async =>
      _unavailable();

  @override
  Future<void> reauthenticateWithGoogle() async => _unavailable();

  @override
  Future<void> deleteCurrentUser() async => _unavailable();
}
