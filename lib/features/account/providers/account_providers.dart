import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../progress/domain/repositories/learner_repository.dart';
import '../../progress/providers/progress_providers.dart';
import '../data/firebase_auth_repository.dart';
import '../domain/auth_repository.dart';

/// Whether Firebase started in this run of the app. `main` overrides it
/// with the result of `Firebase.initializeApp`; it defaults to false, so
/// tests — and a build without Firebase configuration — run local-only,
/// exactly as the app did before accounts existed.
final firebaseReadyProvider = Provider<bool>((ref) => false);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!ref.watch(firebaseReadyProvider)) {
    return const UnavailableAuthRepository();
  }
  return FirebaseAuthRepository(fb.FirebaseAuth.instance);
});

/// Who owns the progress on screen right now.
sealed class AccountSession {
  const AccountSession();

  /// The local learner every screen reads.
  int get learnerId;
  AuthUser? get user;
}

/// Nobody is signed in: the device's guest learner.
class GuestSession extends AccountSession {
  const GuestSession(this.learnerId);

  @override
  final int learnerId;

  @override
  AuthUser? get user => null;
}

/// [user] is signed in and their learner is on screen.
class SignedInSession extends AccountSession {
  const SignedInSession(this.user, this.learnerId);

  @override
  final AuthUser user;
  @override
  final int learnerId;
}

/// [user] signed in for the first time on this device, which has guest
/// progress. Until the learner decides whether that progress becomes the
/// account's, the guest's progress stays on screen and nothing syncs.
class GuestProgressDecision extends AccountSession {
  const GuestProgressDecision(this.user, this.guestLearnerId);

  @override
  final AuthUser user;
  final int guestLearnerId;

  @override
  int get learnerId => guestLearnerId;
}

/// Binds the signed-in account to a local learner — the one rule that
/// keeps one person's progress from appearing under another's account:
///
/// - signed out → the guest learner;
/// - an account that has signed in here before → its own learner, never
///   anyone else's;
/// - a new account, and the guest has no progress → the (empty) guest
///   becomes the account's learner;
/// - a new account, and the guest has progress → [GuestProgressDecision]:
///   the learner chooses ([resolveGuestProgress]).
///
/// See docs/adr/0010-optional-accounts-and-progress-sync.md.
class AccountSessionController extends AsyncNotifier<AccountSession> {
  StreamSubscription<AuthUser?>? _subscription;

  /// Serialises resolutions so two auth events can't interleave.
  Future<void> _queue = Future.value();

  AuthRepository get _auth => ref.read(authRepositoryProvider);
  LearnerRepository get _learners => ref.read(learnerRepositoryProvider);

  @override
  Future<AccountSession> build() async {
    final auth = ref.watch(authRepositoryProvider);
    ref.watch(learnerRepositoryProvider);
    // The stream's first event repeats the current user; _onAuthChanged
    // ignores events that don't change who is signed in.
    _subscription = auth.authStateChanges().listen(_onAuthChanged);
    ref.onDispose(() => _subscription?.cancel());
    return _resolve(auth.currentUser);
  }

  void _onAuthChanged(AuthUser? user) {
    _queue = _queue.then((_) async {
      try {
        await future; // let build's own resolution finish first
      } on Object catch (_) {}
      final current = state.value;
      if (current != null && current.user?.uid == user?.uid) return;
      state = await AsyncValue.guard(() => _resolve(user));
    });
  }

  Future<AccountSession> _resolve(AuthUser? user) async {
    if (user == null) {
      final guest = await _learners.activateGuest();
      return GuestSession(guest.id);
    }
    final own = await _learners.learnerForAccount(user.uid);
    if (own != null) {
      await _learners.activate(own.id);
      return SignedInSession(user, own.id);
    }
    final guest = await _learners.guestLearner();
    if (guest != null && await _learners.hasProgress(guest.id)) {
      await _learners.activate(guest.id);
      return GuestProgressDecision(user, guest.id);
    }
    if (guest != null) {
      await _learners.bindGuestToAccount(
        learnerId: guest.id,
        firebaseUid: user.uid,
      );
      return SignedInSession(user, guest.id);
    }
    final created = await _learners.createAccountLearner(user.uid);
    return SignedInSession(user, created.id);
  }

  /// Settles a [GuestProgressDecision]: [attach] hands the guest's progress
  /// to the account (it is uploaded and merged with anything the account
  /// already has); otherwise the account starts from its own progress and
  /// the guest's stays on this device, returning on sign-out.
  Future<void> resolveGuestProgress({required bool attach}) async {
    final pending = state.value;
    if (pending is! GuestProgressDecision) return;
    final completer = Completer<void>();
    _queue = _queue.then((_) async {
      state = await AsyncValue.guard(() async {
        final learner = attach
            ? await _learners.bindGuestToAccount(
                learnerId: pending.guestLearnerId,
                firebaseUid: pending.user.uid,
              )
            : await _learners.createAccountLearner(pending.user.uid);
        return SignedInSession(pending.user, learner.id);
      });
      completer.complete();
    });
    return completer.future;
  }

  /// Signs out and returns the device to its guest learner. The account's
  /// progress stays on the device (hidden) and anything not yet uploaded
  /// uploads when that account next signs in here.
  Future<void> signOut() async {
    await _auth.signOut();
    _onAuthChanged(null);
    await _queue;
  }

  /// Waits until the session reflects [user] — used right after a sign-in,
  /// so the caller sees the resulting session (e.g. a pending decision).
  Future<AccountSession> settleFor(AuthUser user) async {
    _onAuthChanged(user);
    await _queue;
    return state.requireValue;
  }
}

final accountSessionProvider =
    AsyncNotifierProvider<AccountSessionController, AccountSession>(
      AccountSessionController.new,
    );
