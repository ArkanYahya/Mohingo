import 'dart:async';

import 'package:mohingo/features/account/domain/auth_repository.dart';

/// A scriptable [AuthRepository]: [accounts] maps email → password, uids
/// are `uid-<email>`, and [nextFailure] makes the next call fail.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? signedIn, this.supportsGoogle = true})
    : _user = signedIn;

  final accounts = <String, String>{};
  final _changes = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;
  AuthFailure? nextFailure;
  final resetEmailsSent = <String>[];

  @override
  final bool supportsGoogle;

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

  /// When set, [signOut] announces the sign-out on the stream at once but
  /// returns only once this completes — as Firebase does on a device, where
  /// listeners hear of it before the call itself returns.
  Completer<void>? signOutGate;

  @override
  Future<void> signOut() async {
    _set(null);
    await signOutGate?.future;
  }
}
