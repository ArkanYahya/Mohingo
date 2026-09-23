import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/account/domain/auth_repository.dart';
import 'package:mohingo/features/account/providers/account_providers.dart';
import 'package:mohingo/features/progress/data/drift_activity_attempt_repository.dart';
import 'package:mohingo/features/progress/providers/current_learner_provider.dart';

import 'fake_auth_repository.dart';

void main() {
  late AppDatabase db;
  late FakeAuthRepository auth;
  late ProviderContainer container;

  ProviderContainer start() {
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authRepositoryProvider.overrideWithValue(auth),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    auth = FakeAuthRepository()
      ..accounts.addAll({'a@x.io': 'pw-a', 'b@x.io': 'pw-b'});
    container = start();
  });

  tearDown(() => db.close());

  AccountSessionController session() =>
      container.read(accountSessionProvider.notifier);

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

  Future<Set<String>> visibleAnswers() async {
    final id = (await learner()).id;
    final rows = await (db.select(
      db.activityAttempts,
    )..where((t) => t.learnerId.equals(id))).get();
    return {for (final r in rows) r.activityId};
  }

  Future<AccountSession> signIn(String email, String password) async {
    final user = await auth.signInWithEmail(email: email, password: password);
    return session().settleFor(user);
  }

  test('starts as a guest with no account', () async {
    final s = await container.read(accountSessionProvider.future);
    expect(s, isA<GuestSession>());
    expect((await learner()).firebaseUid, isNull);
  });

  test('a first sign-in on a phone with no guest progress simply becomes '
      "the account's learner", () async {
    final guest = await learner();
    final s = await signIn('a@x.io', 'pw-a');
    expect(s, isA<SignedInSession>());
    expect(s.learnerId, guest.id);
    expect((await learner()).firebaseUid, 'uid-a@x.io');
  });

  test('guest progress waits for the learner to decide, then joins the '
      'account when they choose to add it', () async {
    final guest = await learner();
    await answer(guest.id, 'guest-answer');

    final s = await signIn('a@x.io', 'pw-a');
    expect(s, isA<GuestProgressDecision>());
    // Until they decide, the phone still shows the guest progress.
    expect(await visibleAnswers(), {'guest-answer'});

    await session().resolveGuestProgress(attach: true);
    final settled = container.read(accountSessionProvider).requireValue;
    expect(settled, isA<SignedInSession>());
    expect(await visibleAnswers(), {'guest-answer'});
    expect((await learner()).firebaseUid, 'uid-a@x.io');
  });

  test('choosing to keep guest progress on the phone leaves it with the '
      'guest, and it comes back on sign-out', () async {
    final guest = await learner();
    await answer(guest.id, 'guest-answer');
    await signIn('a@x.io', 'pw-a');
    await session().resolveGuestProgress(attach: false);

    expect(await visibleAnswers(), isEmpty);
    await session().signOut();
    expect(
      container.read(accountSessionProvider).requireValue,
      isA<GuestSession>(),
    );
    expect(await visibleAnswers(), {'guest-answer'});
  });

  test("one account's progress never appears under another account, and "
      'each account finds its own progress again', () async {
    await signIn('a@x.io', 'pw-a');
    final a = await learner();
    await answer(a.id, 'a-answer');

    await session().signOut();
    expect(await visibleAnswers(), isEmpty, reason: 'a fresh guest');

    await signIn('b@x.io', 'pw-b');
    final b = await learner();
    expect(b.id, isNot(a.id));
    expect(await visibleAnswers(), isEmpty);
    await answer(b.id, 'b-answer');

    await session().signOut();
    await signIn('a@x.io', 'pw-a');
    expect((await learner()).id, a.id);
    expect(await visibleAnswers(), {'a-answer'});
  });

  test(
    'a sign-in restored at launch resolves straight to that account',
    () async {
      await signIn('a@x.io', 'pw-a');
      final a = await learner();
      await answer(a.id, 'a-answer');

      // Relaunch: a new container, Firebase restores the session.
      final relaunched = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(signedIn: FakeAuthRepository.userFor('a@x.io')),
          ),
        ],
      );
      addTearDown(relaunched.dispose);
      final s = await relaunched.read(accountSessionProvider.future);
      expect(s, isA<SignedInSession>());
      expect((await relaunched.read(currentLearnerProvider.future)).id, a.id);
    },
  );

  test(
    'a build without Firebase stays a guest and offers no accounts',
    () async {
      final local = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(local.dispose);
      expect(local.read(authRepositoryProvider).isAvailable, isFalse);
      expect(
        await local.read(accountSessionProvider.future),
        isA<GuestSession>(),
      );
      await expectLater(
        local.read(authRepositoryProvider).signInWithGoogle(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.unavailable,
          ),
        ),
      );
    },
  );
}
