import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/account/domain/auth_repository.dart';
import 'package:mohingo/features/account/providers/account_providers.dart';
import 'package:mohingo/features/activity_engine/providers/online_refinement_providers.dart';
import 'package:mohingo/features/progress/data/drift_activity_attempt_repository.dart';
import 'package:mohingo/features/progress/providers/current_learner_provider.dart';
import 'package:mohingo/features/sync/domain/cloud_progress_store.dart';
import 'package:mohingo/features/sync/domain/sync_records.dart';
import 'package:mohingo/features/sync/providers/sync_providers.dart';

import '../activity_engine/fake_connectivity_service.dart';
import '../sync/fake_cloud_progress_store.dart';
import 'fake_auth_repository.dart';

void main() {
  late AppDatabase db;
  late FakeAuthRepository auth;
  late FakeCloudProgressStore cloud;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    auth = FakeAuthRepository()..accounts.addAll({'a@x.io': 'pw-a'});
    cloud = FakeCloudProgressStore();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authRepositoryProvider.overrideWithValue(auth),
        firebaseReadyProvider.overrideWithValue(true),
        cloudProgressStoreProvider.overrideWithValue(cloud),
        connectivityServiceProvider.overrideWithValue(
          FakeConnectivityService(online: true),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  tearDown(() => db.close());

  Future<Learner> learner() => container.read(currentLearnerProvider.future);

  Future<void> answer(int learnerId, String activityId) =>
      DriftActivityAttemptRepository(db).recordAttempt(
        learnerId: learnerId,
        activityId: activityId,
        sessionType: 'lesson',
        mode: ActivityMode.practice,
        evidenceSkill: Skill.reading,
        canDoIds: const [],
      );

  Future<void> signIn() async {
    final user = await auth.signInWithEmail(email: 'a@x.io', password: 'pw-a');
    await container.read(accountSessionProvider.notifier).settleFor(user);
  }

  test('deleting the account removes its cloud copy, the account and its '
      "learner on this phone, and returns the phone to a guest", () async {
    await container.read(accountSessionProvider.future);
    await signIn();
    final accountLearner = await learner();
    expect(accountLearner.firebaseUid, 'uid-a@x.io');
    await answer(accountLearner.id, 'account-answer');
    // What an earlier sync put in the account.
    cloud.putRaw('uid-a@x.io', SyncCollection.attempts, 'x', const {
      'uuid': 'x',
    });

    await auth.reauthenticateWithPassword('pw-a');
    await container.read(deleteAccountProvider)();

    expect(cloud.hasAccount('uid-a@x.io'), isFalse);
    expect(auth.deletedUids, ['uid-a@x.io']);
    expect(container.read(accountSessionProvider).value, isA<GuestSession>());
    final guest = await learner();
    expect(guest.firebaseUid, isNull);
    // The account's learner row and its answers are gone from the device.
    final rows = await db.select(db.learners).get();
    expect(rows.map((r) => r.firebaseUid), isNot(contains('uid-a@x.io')));
    expect(await db.select(db.activityAttempts).get(), isEmpty);
    expect(container.read(syncPausedProvider), isFalse);
  });

  test("the guest's own progress on the phone survives the deletion", () async {
    await container.read(accountSessionProvider.future);
    final guest = await learner();
    await answer(guest.id, 'guest-answer');
    await signIn();
    // Keep the guest's progress on the phone; the account starts its own.
    await container
        .read(accountSessionProvider.notifier)
        .resolveGuestProgress(attach: false);

    await container.read(deleteAccountProvider)();

    final back = await learner();
    expect(back.id, guest.id);
    final answers = await db.select(db.activityAttempts).get();
    expect(answers.map((a) => a.activityId), ['guest-answer']);
  });

  test(
    'offline, nothing is deleted and the error reaches the caller',
    () async {
      await container.read(accountSessionProvider.future);
      await signIn();
      cloud.online = false;

      await expectLater(
        container.read(deleteAccountProvider)(),
        throwsA(isA<SyncException>()),
      );

      expect(auth.deletedUids, isEmpty);
      expect(
        container.read(accountSessionProvider).value,
        isA<SignedInSession>(),
      );
      expect(container.read(syncPausedProvider), isFalse);
    },
  );

  test('a wrong password is refused before anything is deleted', () async {
    await container.read(accountSessionProvider.future);
    await signIn();

    await expectLater(
      auth.reauthenticateWithPassword('nope'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.failure,
          'failure',
          AuthFailure.wrongCredentials,
        ),
      ),
    );
    expect(auth.deletedUids, isEmpty);
  });
}
