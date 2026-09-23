import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/catalog/level_catalog.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../data/local/database_provider.dart';
import '../../account/providers/account_providers.dart';
import '../../activity_engine/providers/online_refinement_providers.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/learner_progress_refresh.dart';
import '../../progress/providers/progress_providers.dart';
import '../data/drift_local_progress_store.dart';
import '../data/firestore_progress_store.dart';
import '../domain/cloud_progress_store.dart';
import '../domain/sync_engine.dart';

final localProgressStoreProvider = Provider<DriftLocalProgressStore>(
  (ref) => DriftLocalProgressStore(ref.watch(appDatabaseProvider)),
);

/// The account's cloud copy, or null when Firebase isn't running (then the
/// app is local-only and nothing syncs).
final cloudProgressStoreProvider = Provider<CloudProgressStore?>((ref) {
  if (!ref.watch(firebaseReadyProvider)) return null;
  final firestore = FirebaseFirestore.instance;
  // The Drift database is the offline store; see FirestoreProgressStore.
  firestore.settings = const Settings(persistenceEnabled: false);
  return FirestoreProgressStore(firestore);
});

final syncEngineProvider = Provider<SyncEngine?>((ref) {
  final cloud = ref.watch(cloudProgressStoreProvider);
  if (cloud == null) return null;
  return SyncEngine(local: ref.watch(localProgressStoreProvider), cloud: cloud);
});

/// What the account screen shows about syncing.
class SyncStatus {
  const SyncStatus({
    this.enabled = false,
    this.running = false,
    this.lastOutcome,
    this.lastSyncedAt,
    this.pendingUploads = 0,
  });

  /// A signed-in account is syncing (false for guests and local-only
  /// builds).
  final bool enabled;
  final bool running;
  final SyncOutcome? lastOutcome;
  final DateTime? lastSyncedAt;

  /// Local changes not yet uploaded.
  final int pendingUploads;

  SyncStatus copyWith({
    bool? running,
    SyncOutcome? lastOutcome,
    DateTime? lastSyncedAt,
    int? pendingUploads,
  }) => SyncStatus(
    enabled: enabled,
    running: running ?? this.running,
    lastOutcome: lastOutcome ?? this.lastOutcome,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    pendingUploads: pendingUploads ?? this.pendingUploads,
  );
}

/// Runs the [SyncEngine] for the signed-in learner, whenever there is
/// reason to: on sign-in and launch, a few seconds after local progress
/// changes, when the device comes back online, when the app returns to the
/// foreground, every [_periodic] while it is open, and on "Sync now".
///
/// Failures are never surfaced as errors to the learner — the local
/// database already holds their progress. Offline runs wait for
/// connectivity; other failures retry with backoff; an expired sign-in
/// waits for the learner to sign in again.
class SyncController extends Notifier<SyncStatus> {
  static const _debounce = Duration(seconds: 4);
  static const _periodic = Duration(minutes: 10);

  Future<SyncOutcome?>? _running;
  bool _runAgain = false;
  Timer? _debounceTimer;
  Timer? _retryTimer;
  Timer? _periodicTimer;
  int _failures = 0;

  @override
  SyncStatus build() {
    final session = ref.watch(accountSessionProvider).value;
    final engine = ref.watch(syncEngineProvider);
    if (session is! SignedInSession || engine == null) {
      return const SyncStatus();
    }
    final learnerId = session.learnerId;
    final local = ref.watch(localProgressStoreProvider);
    final subscriptions = <StreamSubscription<Object?>>[
      local.watchPendingCount(learnerId).listen((pending) {
        state = state.copyWith(pendingUploads: pending);
        if (pending > 0) _schedule(_debounce);
      }),
      ref.read(connectivityServiceProvider).onlineChanges.listen((online) {
        if (online) _schedule(Duration.zero);
      }),
    ];
    final lifecycle = AppLifecycleListener(
      onResume: () => _schedule(Duration.zero),
    );
    _periodicTimer = Timer.periodic(_periodic, (_) => _schedule(Duration.zero));
    ref.onDispose(() {
      for (final s in subscriptions) {
        s.cancel();
      }
      lifecycle.dispose();
      _debounceTimer?.cancel();
      _retryTimer?.cancel();
      _periodicTimer?.cancel();
    });
    _schedule(Duration.zero);
    unawaited(
      local.lastSyncedAt(learnerId).then((at) {
        if (at != null && ref.mounted) {
          state = state.copyWith(lastSyncedAt: at);
        }
      }),
    );
    return const SyncStatus(enabled: true);
  }

  void _schedule(Duration delay) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () => unawaited(syncNow()));
  }

  /// Syncs now (or, if a run is under way, once more right after it).
  Future<SyncOutcome?> syncNow() {
    if (!state.enabled) return Future.value();
    if (_running != null) {
      _runAgain = true;
      return _running!;
    }
    return _running = _run().whenComplete(() {
      _running = null;
      if (_runAgain && ref.mounted) {
        _runAgain = false;
        _schedule(Duration.zero);
      }
    });
  }

  Future<SyncOutcome?> _run() async {
    final session = ref.read(accountSessionProvider).value;
    final engine = ref.read(syncEngineProvider);
    if (session is! SignedInSession || engine == null) return null;
    state = state.copyWith(running: true);
    SyncOutcome outcome;
    try {
      outcome = await engine.sync(
        learnerId: session.learnerId,
        firebaseUid: session.user.uid,
      );
    } on Object catch (e) {
      // Only a broken invariant lands here (e.g. the ownership guard); the
      // engine itself reports every cloud failure as an outcome.
      developer.log('sync aborted: $e', name: 'mohingo.sync');
      outcome = const SyncOutcome(
        result: SyncResult.failed,
        failure: SyncFailure.unexpected,
      );
    }
    if (!ref.mounted) return outcome;

    if (outcome.evidenceChanged) await _recomputeMastery(session.learnerId);
    if (outcome.localChanges > 0 || outcome.remoteResetApplied) {
      refreshLearnerProgress(ref.invalidate);
    }

    _retryTimer?.cancel();
    switch (outcome.result) {
      case SyncResult.succeeded:
        _failures = 0;
      case SyncResult.deferred:
        // The connectivity listener starts the next run.
        break;
      case SyncResult.failed:
        if (outcome.failure != SyncFailure.signedOut) {
          _failures++;
          final minutes = 1 << (_failures - 1).clamp(0, 5); // 1..32 min
          _retryTimer = Timer(Duration(minutes: minutes), syncNow);
        }
    }
    state = state.copyWith(
      running: false,
      lastOutcome: outcome,
      lastSyncedAt: outcome.result == SyncResult.succeeded
          ? DateTime.now()
          : null,
    );
    return outcome;
  }

  /// Unit badges are computed from answers; answers that arrived from
  /// another device are only reflected once every unit is re-evaluated.
  Future<void> _recomputeMastery(int learnerId) async {
    final mastery = ref.read(masteryAggregationServiceProvider);
    for (final entry in ref.read(levelCatalogProvider)) {
      if (entry.availability != LevelAvailability.available) continue;
      try {
        final index = await ref.read(
          courseContentProvider(entry.levelId).future,
        );
        for (final unit in index.bundle.units) {
          final result = await mastery.evaluateUnit(
            learnerId: learnerId,
            unit: unit,
            masteryPolicy: index.bundle.domain.masteryPolicy,
          );
          if (!result.hasAnyEvidence) continue;
          await mastery.refreshUnitProgress(
            learnerId: learnerId,
            unit: unit,
            masteryPolicy: index.bundle.domain.masteryPolicy,
          );
        }
      } on Object catch (e) {
        developer.log(
          'mastery recompute skipped for ${entry.levelId}: $e',
          name: 'mohingo.sync',
        );
      }
    }
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);

/// Erases the current learner's progress: on this device, and — when the
/// learner is signed in — on every device of their account (the next sync
/// records the reset, and every other device follows it on its next sync).
/// The caller confirms with the learner first; see the Settings reset row.
final resetProgressProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final learner = await ref.read(currentLearnerProvider.future);
    await ref
        .read(localProgressStoreProvider)
        .resetProgress(learner.id, firebaseUid: learner.firebaseUid);
    if (learner.firebaseUid != null) {
      unawaited(ref.read(syncControllerProvider.notifier).syncNow());
    }
  };
});
