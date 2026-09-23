// Tests firestore.rules against the Firestore emulator:
//   cd tool/firestore_rules_test && npm install && npm test
// Documents here have the exact shape the app writes
// (lib/features/sync/data/firestore_progress_store.dart).
import { after, before, beforeEach, describe, test } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  collection,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
} from 'firebase/firestore';

let env;
const now = Timestamp.fromDate(new Date('2026-09-23T10:00:00Z'));
const envelope = (epoch = 0) => ({
  epoch,
  serverUpdatedAt: serverTimestamp(),
  v: 1,
});

const account = (epoch = 0) => ({
  epoch,
  name: null,
  nameUpdatedAt: null,
  createdAt: serverTimestamp(),
  ...envelope(epoch),
});

const attempt = (uuid = 'a-1') => ({
  uuid,
  activityId: 'A1-U1-L1-A01',
  lessonId: 'A1-U1-L1',
  sessionType: 'lesson',
  sessionId: null,
  mode: 'mastery',
  evidenceSkill: 'reading',
  rawAnswer: '{"choice":1}',
  isCorrect: true,
  score: 1,
  criteriaScores: null,
  wasFallback: false,
  attemptedAt: now,
  updatedAt: now,
  canDoIds: ['A1-CD-1'],
  ...envelope(),
});

const vocabulary = () => ({
  lexiconId: 'lex-1',
  chunkId: null,
  isFavorite: true,
  favoriteUpdatedAt: now,
  confidenceMarker: null,
  easeFactor: 2.5,
  intervalDays: 0,
  repetitions: 0,
  dueAt: null,
  lastReviewedAt: null,
  updatedAt: now,
  ...envelope(),
});

const as = (uid) => env.authenticatedContext(uid).firestore();

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-mohingo',
    firestore: { rules: readFileSync('../../firestore.rules', 'utf8') },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
});

after(async () => {
  await env.cleanup();
});

describe('ownership', () => {
  test('a learner can create and read their own account', async () => {
    const db = as('alice');
    await assertSucceeds(setDoc(doc(db, 'users/alice'), account()));
    await assertSucceeds(getDoc(doc(db, 'users/alice')));
  });

  test("a learner can't read or write another learner's account", async () => {
    await assertSucceeds(setDoc(doc(as('alice'), 'users/alice'), account()));
    await assertSucceeds(
      setDoc(doc(as('alice'), 'users/alice/attempts/a-1'), attempt()),
    );

    const bob = as('bob');
    await assertFails(getDoc(doc(bob, 'users/alice')));
    await assertFails(getDoc(doc(bob, 'users/alice/attempts/a-1')));
    await assertFails(getDocs(collection(bob, 'users/alice/attempts')));
    await assertFails(setDoc(doc(bob, 'users/alice/attempts/a-2'), attempt('a-2')));
    await assertFails(deleteDoc(doc(bob, 'users/alice/attempts/a-1')));
    await assertFails(updateDoc(doc(bob, 'users/alice'), { epoch: 9 }));
  });

  test('signed-out clients can do nothing', async () => {
    const anon = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(anon, 'users/alice')));
    await assertFails(setDoc(doc(anon, 'users/alice'), account()));
  });

  test('nobody can list every account, or write outside users/', async () => {
    await assertFails(getDocs(collection(as('alice'), 'users')));
    await assertFails(setDoc(doc(as('alice'), 'other/x'), { a: 1 }));
  });
});

describe('record shape', () => {
  test('the records the app writes are accepted', async () => {
    const db = as('alice');
    await assertSucceeds(setDoc(doc(db, 'users/alice/attempts/a-1'), attempt()));
    await assertSucceeds(
      setDoc(doc(db, 'users/alice/vocabularyReview/lexicon%3Alex-1'), vocabulary()),
    );
    await assertSucceeds(
      setDoc(doc(db, 'users/alice/enrolments/a1'), {
        levelId: 'a1',
        courseId: 'EN-A1-V2',
        contentVersion: 'A1-COMPLETE-2026.09.22-3',
        enrolledAt: now,
        status: 'active',
        lastSelectedAt: now,
        unlockedAt: null,
        ...envelope(),
      }),
    );
    await assertSucceeds(
      setDoc(doc(db, 'users/alice/testAttempts/t-1'), {
        uuid: 't-1',
        kind: 'placement',
        courseId: null,
        startedAt: now,
        completedAt: null,
        stageReached: 0,
        outcome: null,
        recommendedUnitId: null,
        confidenceSelfReports: null,
        itemSamplingSeed: 'seed',
        stagesCompleted: null,
        sectionResults: null,
        outcomeSummary: null,
        ...envelope(),
      }),
    );
  });

  test('unknown fields, wrong types and client-chosen timestamps are refused', async () => {
    const db = as('alice');
    await assertFails(
      setDoc(doc(db, 'users/alice/attempts/a-1'), { ...attempt(), isAdmin: true }),
    );
    await assertFails(
      setDoc(doc(db, 'users/alice/attempts/a-1'), { ...attempt(), score: 'high' }),
    );
    await assertFails(
      setDoc(doc(db, 'users/alice/attempts/a-1'), { ...attempt(), serverUpdatedAt: now }),
    );
    await assertFails(
      setDoc(doc(db, 'users/alice/attempts/a-1'), { ...attempt(), v: 2 }),
    );
    await assertFails(setDoc(doc(db, 'users/alice/attempts/other-id'), attempt()));
    await assertFails(setDoc(doc(db, 'users/alice/unknownCollection/x'), attempt()));
  });

  test('an answer can be re-uploaded unchanged, never altered', async () => {
    const db = as('alice');
    const ref = doc(db, 'users/alice/attempts/a-1');
    await assertSucceeds(setDoc(ref, attempt()));
    await assertSucceeds(setDoc(ref, attempt()));
    await assertFails(setDoc(ref, { ...attempt(), isCorrect: false }));
  });

  test("the account's epoch only moves forward", async () => {
    const db = as('alice');
    await assertSucceeds(setDoc(doc(db, 'users/alice'), account(2)));
    await assertSucceeds(
      updateDoc(doc(db, 'users/alice'), { epoch: 3, serverUpdatedAt: serverTimestamp() }),
    );
    await assertFails(
      updateDoc(doc(db, 'users/alice'), { epoch: 1, serverUpdatedAt: serverTimestamp() }),
    );
  });

  test('a learner can delete their own records (reset clean-up)', async () => {
    const db = as('alice');
    await assertSucceeds(setDoc(doc(db, 'users/alice/attempts/a-1'), attempt()));
    await assertSucceeds(deleteDoc(doc(db, 'users/alice/attempts/a-1')));
  });
});
