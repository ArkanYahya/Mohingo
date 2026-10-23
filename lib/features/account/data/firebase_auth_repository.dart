import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_repository.dart';

/// [AuthRepository] over Firebase Authentication, with Google sign-in
/// through the `google_sign_in` plugin and Sign in with Apple through
/// Firebase's own native flow. Sessions persist between launches
/// (Firebase's own on-device persistence); every Firebase error is
/// translated to an [AuthFailure] here and nowhere else.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, {GoogleSignIn? googleSignIn})
    : _google = googleSignIn ?? GoogleSignIn.instance;

  final fb.FirebaseAuth _auth;
  final GoogleSignIn _google;
  Future<void>? _googleReady;

  /// The authorization code from the last Apple reauthentication: single
  /// use and valid for five minutes, which is all [deleteCurrentUser]
  /// needs to revoke the app's Apple sign-in.
  String? _appleAuthorizationCode;

  @override
  bool get isAvailable => true;

  /// Android and iOS only — the platforms this app ships on. (iOS also
  /// needs its URL scheme in Info.plist; see docs/FIREBASE_SETUP.md.)
  @override
  bool get supportsGoogle =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// iOS only: the App Store requires it beside Google sign-in, and
  /// Firebase signs in natively there. Android would need Apple's web flow
  /// — see docs/adr/0012-ios-release-sign-in-with-apple.md.
  @override
  bool get supportsApple =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  AuthUser? get currentUser => _toUser(_auth.currentUser);

  @override
  Stream<AuthUser?> authStateChanges() => _auth.authStateChanges().map(_toUser);

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) => _guard(() async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _toUser(credential.user)!;
  });

  @override
  Future<AuthUser> createAccountWithEmail({
    required String email,
    required String password,
  }) => _guard(() async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _toUser(credential.user)!;
  });

  @override
  Future<void> sendPasswordReset({required String email}) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<AuthUser> signInWithGoogle() => _guard(() async {
    if (!supportsGoogle) throw const AuthException(AuthFailure.unavailable);
    await _initGoogle();
    final account = await _google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) throw const AuthException(AuthFailure.unknown);
    final credential = await _auth.signInWithCredential(
      fb.GoogleAuthProvider.credential(idToken: idToken),
    );
    return _toUser(credential.user)!;
  });

  @override
  Future<AuthUser> signInWithApple() => _guard(() async {
    if (!supportsApple) throw const AuthException(AuthFailure.unavailable);
    final credential = await _auth.signInWithProvider(_appleProvider());
    return _toUser(credential.user)!;
  });

  @override
  Future<void> signOut() async {
    _appleAuthorizationCode = null;
    await _auth.signOut();
    if (supportsGoogle && _googleReady != null) {
      // Otherwise the next "Continue with Google" silently reuses this
      // Google account instead of letting the learner pick one.
      try {
        await _google.signOut();
      } on Object catch (_) {}
    }
  }

  @override
  Future<void> reauthenticateWithPassword(String password) => _guard(() async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw const AuthException(AuthFailure.unknown);
    }
    await user.reauthenticateWithCredential(
      fb.EmailAuthProvider.credential(email: email, password: password),
    );
  });

  @override
  Future<void> reauthenticateWithGoogle() => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException(AuthFailure.unknown);
    if (!supportsGoogle) throw const AuthException(AuthFailure.unavailable);
    await _initGoogle();
    final account = await _google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) throw const AuthException(AuthFailure.unknown);
    await user.reauthenticateWithCredential(
      fb.GoogleAuthProvider.credential(idToken: idToken),
    );
  });

  @override
  Future<void> reauthenticateWithApple() => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException(AuthFailure.unknown);
    if (!supportsApple) throw const AuthException(AuthFailure.unavailable);
    final credential = await user.reauthenticateWithProvider(_appleProvider());
    _appleAuthorizationCode = credential.additionalUserInfo?.authorizationCode;
  });

  @override
  Future<void> deleteCurrentUser() => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _revokeApple();
    await user.delete();
    if (supportsGoogle && _googleReady != null) {
      try {
        await _google.signOut();
      } on Object catch (_) {}
    }
  });

  /// On Android the plugin reads the web client id that the
  /// google-services Gradle plugin generates from google-services.json; on
  /// iOS it gets the iOS client id `flutterfire configure` wrote into the
  /// Firebase options.
  Future<void> _initGoogle() => _googleReady ??= _google.initialize(
    clientId: defaultTargetPlatform == TargetPlatform.iOS
        ? _auth.app.options.iosClientId
        : null,
  );

  /// Only the email: the app shows the address an account signs in with
  /// and has no use for the learner's name.
  static fb.AppleAuthProvider _appleProvider() =>
      fb.AppleAuthProvider()..addScope('email');

  /// Apple requires an app that deletes an account made with Sign in with
  /// Apple to revoke its tokens, which also takes the app off the
  /// learner's Apple ID. Best effort: a failure here (no network, or the
  /// Apple provider's key missing in Firebase — docs/FIREBASE_SETUP.md)
  /// must not keep the account alive after its progress was deleted, so
  /// it is logged, not thrown.
  Future<void> _revokeApple() async {
    final code = _appleAuthorizationCode;
    _appleAuthorizationCode = null;
    if (code == null) return;
    try {
      await _auth.revokeTokenWithAuthorizationCode(code);
    } on Object catch (e) {
      developer.log('Apple token revocation failed: $e', name: 'mohingo.auth');
    }
  }

  AuthUser? _toUser(fb.User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      providers: {
        for (final info in user.providerData)
          if (info.providerId == fb.EmailAuthProvider.PROVIDER_ID)
            AuthProvider.emailPassword
          else if (info.providerId == fb.GoogleAuthProvider.PROVIDER_ID)
            AuthProvider.google
          else if (info.providerId == fb.AppleAuthProvider.PROVIDER_ID)
            AuthProvider.apple,
      },
    );
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on AuthException {
      rethrow;
    } on GoogleSignInException catch (e) {
      throw AuthException(switch (e.code) {
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode.interrupted => AuthFailure.cancelled,
        _ => AuthFailure.unknown,
      });
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_failureFor(e.code));
    } on Object {
      throw const AuthException(AuthFailure.unknown);
    }
  }

  static AuthFailure _failureFor(String code) => switch (code) {
    'invalid-email' => AuthFailure.invalidEmail,
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' ||
    'invalid-login-credentials' => AuthFailure.wrongCredentials,
    'email-already-in-use' => AuthFailure.emailAlreadyInUse,
    'weak-password' => AuthFailure.weakPassword,
    'user-disabled' => AuthFailure.userDisabled,
    'too-many-requests' => AuthFailure.tooManyRequests,
    'network-request-failed' => AuthFailure.network,
    'account-exists-with-different-credential' =>
      AuthFailure.accountExistsWithDifferentMethod,
    'operation-not-allowed' => AuthFailure.unavailable,
    'requires-recent-login' => AuthFailure.requiresRecentLogin,
    'user-mismatch' => AuthFailure.wrongAccount,
    // The learner closed Apple's sign-in sheet.
    'canceled' => AuthFailure.cancelled,
    _ => AuthFailure.unknown,
  };
}
