import 'dart:async';

import 'package:mohingo/features/account/domain/auth_repository.dart';

/// A scriptable [AuthRepository]: [accounts] maps email → password, uids
/// are `uid-<email>`, and [nextFailure] makes the next call fail.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    AuthUser? signedIn,
    this.supportsGoogle = true,
    this.supportsApple = false,
  }) : _user = signedIn;

  final accounts = <String, String>{};
  final _changes = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;
  AuthFailure? nextFailure;
  final resetEmailsSent = <String>[];

  @override
  final bool supportsGoogle;

  @override
  final bool supportsApple;

  @override
  bool get isAvailable => true;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _user;
    yield* _changes.stream;
  }

  void _set(AuthUser? user) {
    _user = user;
    _changes.add(user);
  }

  void _maybeFail() {
    if (nextFailure case final failure?) {
      nextFailure = null;
      throw AuthException(failure);
    }
  }

  static AuthUser userFor(String email) =>
      AuthUser(uid: 'uid-$email', email: email);

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _maybeFail();
    if (accounts[email] != password) {
      throw const AuthException(AuthFailure.wrongCredentials);
    }
    final user = userFor(email);
    _set(user);
    return user;
  }

  @override
  Future<AuthUser> createAccountWithEmail({
    required String email,
    required String password,
  }) async {
    _maybeFail();
    if (accounts.containsKey(email)) {
      throw const AuthException(AuthFailure.emailAlreadyInUse);
    }
    accounts[email] = password;
    final user = userFor(email);
    _set(user);
    return user;
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    _maybeFail();
    resetEmailsSent.add(email);
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    _maybeFail();
    final user = userFor('google@example.com');
    _set(user);
    return user;
  }

  /// The account Sign in with Apple signs in to.
  static const appleUser = AuthUser(
    uid: 'uid-apple',
    email: 'hidden@privaterelay.appleid.com',
    providers: {AuthProvider.apple},
  );

  @override
  Future<AuthUser> signInWithApple() async {
    _maybeFail();
    _set(appleUser);
    return appleUser;
  }

  /// When set, [signOut] announces the sign-out on the stream at once but
  /// returns only once this completes — as Firebase does on a device, where
  /// listeners hear of it before the call itself returns.
  Completer<void>? signOutGate;

  @override
  Future<void> signOut() async {
    _set(null);
    await signOutGate?.future;
  }

  /// How many times the learner confirmed who they are (and how, by
  /// provider), and whether the account was then deleted.
  int reauthentications = 0;
  final reauthenticatedWith = <AuthProvider>[];
  final deletedUids = <String>[];

  @override
  Future<void> reauthenticateWithPassword(String password) async {
    _maybeFail();
    final email = _user?.email;
    if (email == null || accounts[email] != password) {
      throw const AuthException(AuthFailure.wrongCredentials);
    }
    reauthentications++;
    reauthenticatedWith.add(AuthProvider.emailPassword);
  }

  @override
  Future<void> reauthenticateWithGoogle() async {
    _maybeFail();
    reauthentications++;
    reauthenticatedWith.add(AuthProvider.google);
  }

  @override
  Future<void> reauthenticateWithApple() async {
    _maybeFail();
    reauthentications++;
    reauthenticatedWith.add(AuthProvider.apple);
  }

  @override
  Future<void> deleteCurrentUser() async {
    _maybeFail();
    final user = _user;
    if (user == null) return;
    accounts.remove(user.email);
    deletedUids.add(user.uid);
    _set(null);
  }
}
