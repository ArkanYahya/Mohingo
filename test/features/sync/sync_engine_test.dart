import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/data/drift_activity_attempt_repository.dart';
import 'package:mohingo/features/progress/data/drift_assessment_attempt_repository.dart';
import 'package:mohingo/features/progress/data/drift_learner_repository.dart';
import 'package:mohingo/features/progress/data/drift_review_state_repository.dart';
import 'package:mohingo/features/progress/data/drift_unit_lesson_progress_repository.dart';
import 'package:mohingo/features/sync/data/drift_local_progress_store.dart';
import 'package:mohingo/features/sync/domain/cloud_progress_store.dart';
import 'package:mohingo/features/sync/domain/sync_engine.dart';
import 'package:mohingo/features/sync/domain/sync_records.dart';

import 'fake_cloud_progress_store.dart';

const _uid = 'account-A';

/// One phone: its own database, its own learner, the shared cloud.
class _Device {
  _Device(this.cloud) : db = AppDatabase(NativeDatabase.memory()) {
    local = DriftLocalProgressStore(db);
    engine = SyncEngine(local: local, cloud: cloud, log: logs.add);
  }

  final FakeCloudProgressStore cloud;
  final AppDatabase db;
  late final DriftLocalProgressStore local;
  late final SyncEngine engine;
  final logs = <String>[];
  late int learnerId;

  late final learners = DriftLearnerRepository(db);
  late final attempts = DriftActivityAttemptRepository(db);
  late final lessons = DriftUnitLessonProgressRepository(db);
  late final reviews = DriftReviewStateRepository(db);
  late final tests = DriftAssessmentAttemptRepository(db);

  /// Signs this device in as [uid] with a fresh learner.
  Future<void> signIn([String uid = _uid]) async {
    learnerId = (await learners.createAccountLearner(uid)).id;
  }

  Future<SyncOutcome> sync([String uid = _uid]) =>
      engine.sync(learnerId: learnerId, firebaseUid: uid);

  Future<void> answer(String activityId, {bool correct = true}) =>
      attempts.recordAttempt(
        learnerId: learnerId,
        activityId: activityId,
        lessonId: 'A1-U1-L1',
        sessionType: 'lesson',
        mode: ActivityMode.mastery,
        evidenceSkill: Skill.reading,
        canDoIds: const ['A1-CD-1', 'A1-CD-2'],
        isCorrect: correct,
        score: correct ? 1 : 0,
      );

  Future<List<ActivityAttempt>> allAttempts() => (db.select(
    db.activityAttempts,
  )..where((t) => t.learnerId.equals(learnerId))).get();

  Future<int> outboxSize() => local.pendingCount(learnerId);
}

void main() {
  late FakeCloudProgressStore cloud;
  late _Device phoneA;
  late _Device phoneB;

  setUp(() {
    cloud = FakeCloudProgressStore();
    phoneA = _Device(cloud);
    phoneB = _Device(cloud);
  });

  tearDown(() async {
    await phoneA.db.close();
    await phoneB.db.close();
  });

  test('progress made on one phone is restored on a second phone', () async {
    await phoneA.signIn();
    await phoneA.answer('A1-U1-L1-A01');
    await phoneA.answer('A1-U1-L1-A02', correct: false);
    await phoneA.lessons.recordLessonPosition(
      learnerId: phoneA.learnerId,
      lessonId: 'A1-U1-L1',
      unitId: 'A1-U1',
      lastActivityId: 'A1-U1-L1-A02',
    );
    await phoneA.reviews.upsertVocabularyReviewOutcome(
      learnerId: phoneA.learnerId,
      lexiconId: 'lex-hello',
      easeFactor: 2.6,
      intervalDays: 3,
      repetitions: 2,
      dueAt: DateTime.utc(2026, 9, 26),
      confidenceMarker: 'good',
    );
    await phoneA.reviews.setGrammarFavorite(
      learnerId: phoneA.learnerId,
      grammarId: 'gr-be',
      isFavorite: true,
    );
    await phoneA.learners.ensureEnrolled(
      learnerId: phoneA.learnerId,
      levelId: 'a1',
      courseId: 'EN-A1-V2',
      contentVersion: 'A1-v1',
    );
    final placement = await phoneA.tests.startPlacementAttempt(
      learnerId: phoneA.learnerId,
      itemSamplingSeed: 'seed',
    );
    await phoneA.tests.completePlacementAttempt(
      attemptId: placement,
      stageReached: 3,
      outcome: 'startAtUnit',
      recommendedUnitId: 'A1-U4',
    );
    await phoneA.learners.updateName(learnerId: phoneA.learnerId, name: 'Sara');

    final up = await phoneA.sync();
    expect(up.result, SyncResult.succeeded);
    expect(await phoneA.outboxSize(), 0);

    await phoneB.signIn();
    final down = await phoneB.sync();
    expect(down.result, SyncResult.succeeded);
    expect(down.evidenceChanged, isTrue);

    final attempts = await phoneB.allAttempts();
    expect(attempts.map((a) => a.activityId).toSet(), {
      'A1-U1-L1-A01',
      'A1-U1-L1-A02',
    });
    final canDos = await phoneB.db
        .select(phoneB.db.activityAttemptCanDos)
        .get();
    expect(canDos, hasLength(4));
    final lesson = await phoneB.lessons.lessonProgress(
      learnerId: phoneB.learnerId,
      lessonId: 'A1-U1-L1',
    );
    expect(lesson?.lastActivityId, 'A1-U1-L1-A02');
    final word = await phoneB.reviews.vocabularyState(
      learnerId: phoneB.learnerId,
      lexiconId: 'lex-hello',
    );
    expect(word?.intervalDays, 3);
    expect(word?.easeFactor, 2.6);
    expect(
      (await phoneB.reviews.grammarState(
        learnerId: phoneB.learnerId,
        grammarId: 'gr-be',
      ))?.isFavorite,
      isTrue,
    );
    final enrolment = await phoneB.learners.enrolmentForLevel(
      learnerId: phoneB.learnerId,
      levelId: 'a1',
    );
    expect(enrolment?.contentVersion, 'A1-v1');
    final test = await phoneB.tests.latestPlacementAttempt(
      learnerId: phoneB.learnerId,
    );
    expect(test?.recommendedUnitId, 'A1-U4');
    expect((await phoneB.learners.learnerById(phoneB.learnerId)).name, 'Sara');
    // Downloaded records are not queued to go back up.
    expect(await phoneB.outboxSize(), 0);
  });

  test('a phone that was offline keeps its work and gains the other '
      "phone's: nothing either phone recorded is lost", () async {
    await phoneA.signIn();
    await phoneB.signIn();
    await phoneA.answer('A1-U1-L1-A01');
    await phoneA.sync();
    await phoneB.sync();

    // A goes offline and keeps learning.
    cloud.online = false;
    await phoneA.answer('A1-U1-L1-A02');
    expect((await phoneA.sync()).result, SyncResult.deferred);
    expect(await phoneA.outboxSize(), greaterThan(0));

    // Meanwhile B learns online.
    cloud.online = true;
    await phoneB.answer('A1-U1-L1-A03');
    await phoneB.sync();

    // A reconnects.
    final outcome = await phoneA.sync();
    expect(outcome.result, SyncResult.succeeded);
    await phoneB.sync();

    for (final phone in [phoneA, phoneB]) {
      expect((await phone.allAttempts()).map((a) => a.activityId).toSet(), {
        'A1-U1-L1-A01',
        'A1-U1-L1-A02',
        'A1-U1-L1-A03',
      });
    }
  });

  test('a name set before accounts existed is uploaded too', () async {
    await phoneA.signIn();
    // As the v6 upgrade leaves it: a name with no updatedAt, queued.
    await phoneA.db.customStatement(
      "UPDATE learners SET name = 'Omar', updated_at = NULL "
      'WHERE id = ${phoneA.learnerId}',
    );
    await phoneA.sync();
    await phoneB.signIn();
    await phoneB.sync();
    expect((await phoneB.learners.learnerById(phoneB.learnerId)).name, 'Omar');
  });

  test('syncing again changes nothing and duplicates nothing', () async {
    await phoneA.signIn();
    await phoneA.answer('A1-U1-L1-A01');
    await phoneA.sync();
    await phoneB.signIn();
    await phoneB.sync();

    final again = await phoneB.sync();
    expect(again.localChanges, 0);
    await phoneA.sync();
    expect(await phoneA.allAttempts(), hasLength(1));
    expect(await phoneB.allAttempts(), hasLength(1));
    expect(cloud.docs(_uid, SyncCollection.attempts), hasLength(1));
  });

  test(
    'a favourite set on one phone survives a later review on another',
    () async {
      await phoneA.signIn();
      await phoneB.signIn();
      final t0 = DateTime.utc(2026, 9, 20);
      // B reviewed the word on day 1 (synced), A favourited it on day 2
      // offline, B reviewed it again on day 3.
      Future<void> writeVocab(
        _Device phone, {
        required bool favorite,
        DateTime? favoriteAt,
        required int interval,
        required DateTime reviewedAt,
        required DateTime updatedAt,
      }) async {
        await phone.db
            .into(phone.db.vocabularyReviewState)
            .insertOnConflictUpdate(
              VocabularyReviewStateCompanion.insert(
                id: const Value(1),
                uuid: 'v-${phone.hashCode}',
                learnerId: phone.learnerId,
                lexiconId: const Value('lex-cat'),
                isFavorite: Value(favorite),
                favoriteUpdatedAt: Value(favoriteAt),
                intervalDays: Value(interval),
                lastReviewedAt: Value(reviewedAt),
                updatedAt: updatedAt,
              ),
            );
      }

      await writeVocab(
        phoneB,
        favorite: false,
        interval: 1,
        reviewedAt: t0,
        updatedAt: t0,
      );
      await phoneB.sync();
      await phoneA.sync();
      cloud.online = false;
      await writeVocab(
        phoneA,
        favorite: true,
        favoriteAt: t0.add(const Duration(days: 1)),
        interval: 1,
        reviewedAt: t0,
        updatedAt: t0.add(const Duration(days: 1)),
      );
      cloud.online = true;
      await writeVocab(
        phoneB,
        favorite: false,
        interval: 4,
        reviewedAt: t0.add(const Duration(days: 2)),
        updatedAt: t0.add(const Duration(days: 2)),
      );
      await phoneB.sync();
      await phoneA.sync();
      await phoneB.sync();

      for (final phone in [phoneA, phoneB]) {
        final word = await phone.reviews.vocabularyState(
          learnerId: phone.learnerId,
          lexiconId: 'lex-cat',
        );
        expect(word?.isFavorite, isTrue, reason: 'the favourite from A');
        expect(word?.intervalDays, 4, reason: 'the newer review from B');
      }
    },
  );

  test(
    'the newer lesson position wins, whichever phone uploads last',
    () async {
      await phoneA.signIn();
      await phoneB.signIn();
      Future<void> position(_Device phone, String activity, DateTime at) =>
          phone.db
              .into(phone.db.lessonProgress)
              .insert(
                LessonProgressCompanion.insert(
                  uuid: 'lp-${phone.hashCode}',
                  learnerId: phone.learnerId,
                  lessonId: 'A1-U2-L1',
                  unitId: 'A1-U2',
                  state: 'inProgress',
                  lastActivityId: Value(activity),
                  lastPositionUpdatedAt: Value(at),
                  updatedAt: at,
                ),
              );
      await position(phoneB, 'A1-U2-L1-A05', DateTime.utc(2026, 9, 22));
      await position(phoneA, 'A1-U2-L1-A02', DateTime.utc(2026, 9, 21));
      await phoneB.sync();
      await phoneA.sync(); // uploads the older position last
      await phoneB.sync();

      for (final phone in [phoneA, phoneB]) {
        final lesson = await phone.lessons.lessonProgress(
          learnerId: phone.learnerId,
          lessonId: 'A1-U2-L1',
        );
        expect(lesson?.lastActivityId, 'A1-U2-L1-A05');
      }
    },
  );

  group('reset progress', () {
    test('a reset on one phone erases the progress on every phone, and '
        'work recorded after it syncs normally', () async {
      await phoneA.signIn();
      await phoneB.signIn();
      await phoneA.answer('A1-U1-L1-A01');
      await phoneA.sync();
      await phoneB.sync();
      expect(await phoneB.allAttempts(), hasLength(1));

      await phoneA.local.resetProgress(phoneA.learnerId, firebaseUid: _uid);
      await phoneA.answer('A1-U1-L1-A09'); // after the reset
      expect((await phoneA.sync()).result, SyncResult.succeeded);
      expect(cloud.epochOf(_uid), 1);
      // The erased records are gone from the cloud too.
      expect(
        cloud
            .docs(_uid, SyncCollection.attempts)
            .values
            .map((d) => d['activityId']),
        ['A1-U1-L1-A09'],
      );

      final outcome = await phoneB.sync();
      expect(outcome.remoteResetApplied, isTrue);
      expect((await phoneB.allAttempts()).map((a) => a.activityId), [
        'A1-U1-L1-A09',
      ]);
    });

    test('work an offline phone recorded before learning of the reset is '
        'discarded, not resurrected', () async {
      await phoneA.signIn();
      await phoneB.signIn();
      await phoneA.sync();
      await phoneB.sync();

      cloud.online = false;
      await phoneB.answer('A1-U1-L1-A03'); // B offline, pre-reset
      cloud.online = true;
      await phoneA.local.resetProgress(phoneA.learnerId, firebaseUid: _uid);
      await phoneA.sync();

      final outcome = await phoneB.sync();
      expect(outcome.remoteResetApplied, isTrue);
      expect(await phoneB.allAttempts(), isEmpty);
      await phoneA.sync();
      expect(await phoneA.allAttempts(), isEmpty);
      expect(cloud.docs(_uid, SyncCollection.attempts), isEmpty);
    });

    test('a reset before the first sync is still uploaded, so the first '
        'sync cannot bring the erased progress back', () async {
      await phoneA.signIn();
      await phoneA.answer('A1-U1-L1-A01');
      await phoneA.sync();

      await phoneB.signIn();
      await phoneB.local.resetProgress(phoneB.learnerId, firebaseUid: _uid);
      await phoneB.sync();
      expect(await phoneB.allAttempts(), isEmpty);
      await phoneA.sync();
      expect(await phoneA.allAttempts(), isEmpty);
    });
  });

  test('an interrupted run loses nothing: the next run finishes it', () async {
    await phoneA.signIn();
    for (var i = 0; i < 5; i++) {
      await phoneA.answer('A1-U1-L1-A0$i');
    }
    await phoneA.sync();
    await phoneB.signIn();
    await phoneB.answer('A1-U3-L1-A01');

    // Fails part-way through: after the upload, during the downloads.
    cloud.failAfterCalls = 4;
    expect((await phoneB.sync()).result, SyncResult.deferred);
    expect((await phoneB.sync()).result, SyncResult.succeeded);
    await phoneA.sync();

    expect(await phoneA.allAttempts(), hasLength(6));
    expect(await phoneB.allAttempts(), hasLength(6));
  });

  test('a malformed cloud record is skipped, never applied', () async {
    await phoneA.signIn();
    await phoneA.sync();
    cloud.putRaw(_uid, SyncCollection.attempts, 'bad', {
      'uuid': 'bad',
      'activityId': 42, // not a string
    });
    final outcome = await phoneA.sync();
    expect(outcome.result, SyncResult.succeeded);
    expect(await phoneA.allAttempts(), isEmpty);
    expect(phoneA.logs, contains(contains('malformed')));
  });

  test("a learner is never synced to an account that isn't theirs", () async {
    await phoneA.signIn('account-A');
    await expectLater(
      phoneA.engine.sync(learnerId: phoneA.learnerId, firebaseUid: 'account-B'),
      throwsStateError,
    );
    final guest = await phoneA.learners.activateGuest();
    await expectLater(
      phoneA.engine.sync(learnerId: guest.id, firebaseUid: 'account-A'),
      throwsStateError,
    );
  });

  test('guest progress attached to an account is uploaded and merged with '
      "the account's existing progress", () async {
    await phoneA.signIn();
    await phoneA.answer('A1-U1-L1-A01');
    await phoneA.sync();

    // Phone B was used as a guest before this account signed in there.
    final guest = await phoneB.learners.activateGuest();
    phoneB.learnerId = guest.id;
    await phoneB.answer('A1-U2-L1-A01');
    await phoneB.learners.bindGuestToAccount(
      learnerId: guest.id,
      firebaseUid: _uid,
    );
    await phoneB.sync();
    await phoneA.sync();

    for (final phone in [phoneA, phoneB]) {
      expect((await phone.allAttempts()).map((a) => a.activityId).toSet(), {
        'A1-U1-L1-A01',
        'A1-U2-L1-A01',
      });
    }
  });

  test('a signed-out session reports signedOut and keeps the outbox', () async {
    final failing = _FailingCloud(SyncFailure.signedOut);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final learner = await DriftLearnerRepository(db).createAccountLearner(_uid);
    await DriftActivityAttemptRepository(db).recordAttempt(
      learnerId: learner.id,
      activityId: 'x',
      sessionType: 'lesson',
      mode: ActivityMode.practice,
      evidenceSkill: Skill.reading,
      canDoIds: const [],
    );
    final local = DriftLocalProgressStore(db);
    final outcome = await SyncEngine(
      local: local,
      cloud: failing,
      log: (_) {},
    ).sync(learnerId: learner.id, firebaseUid: _uid);
    expect(outcome.result, SyncResult.failed);
    expect(outcome.failure, SyncFailure.signedOut);
    expect(await local.pendingCount(learner.id), 1);
  });
}

class _FailingCloud extends FakeCloudProgressStore {
  _FailingCloud(this.failure);

  final SyncFailure failure;

  @override
  Future<CloudAccount?> readAccount(String uid) async =>
      throw SyncException(failure);
}
