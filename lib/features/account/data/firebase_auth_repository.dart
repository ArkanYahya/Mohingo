import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_repository.dart';

/// [AuthRepository] over Firebase Authentication, with Google sign-in
/// through the `google_sign_in` plugin. Sessions persist between launches
/// (Firebase's own on-device persistence); every Firebase error is
/// translated to an [AuthFailure] here and nowhere else.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, {GoogleSignIn? googleSignIn})
    : _google = googleSignIn ?? GoogleSignIn.instance;

  final fb.FirebaseAuth _auth;
  final GoogleSignIn _google;
  Future<void>? _googleReady;

  @override
  bool get isAvailable => true;

  /// Android and iOS only — the platforms this app ships on. (iOS also
  /// needs its URL scheme, added when iOS is configured; see
  /// docs/FIREBASE_SETUP.md.)
  @override
  bool get supportsGoogle =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

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
    // On Android the plugin reads the web client id that the
    // google-services Gradle plugin generates from google-services.json.
    await (_googleReady ??= _google.initialize());
    final account = await _google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) throw const AuthException(AuthFailure.unknown);
    final credential = await _auth.signInWithCredential(
      fb.GoogleAuthProvider.credential(idToken: idToken),
    );
    return _toUser(credential.user)!;
  });

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (supportsGoogle && _googleReady != null) {
      // Otherwise the next "Continue with Google" silently reuses this
      // Google account instead of letting the learner pick one.
      try {
        await _google.signOut();
      } on Object catch (_) {}
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
            AuthProvider.google,
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
    _ => AuthFailure.unknown,
  };
}
