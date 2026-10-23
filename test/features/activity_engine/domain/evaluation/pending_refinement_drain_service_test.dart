import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/activity_engine/data/drift_pending_refinement_repository.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/grading_signals.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/grammar_check_service.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/local_judgement_service.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/pending_refinement_drain_service.dart';
import 'package:mohingo/features/progress/data/drift_activity_attempt_repository.dart';
import 'package:uuid/uuid.dart';

import '../../fake_grammar_check_service.dart';
import '../../fake_local_judgement_service.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftPendingRefinementRepository pendingRepository;
  late DriftActivityAttemptRepository attemptRepository;
  late int learnerId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    pendingRepository = DriftPendingRefinementRepository(db);
    attemptRepository = DriftActivityAttemptRepository(db);
    learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: const Uuid().v4(),
            createdAt: DateTime.utc(2026, 9, 8),
          ),
        );
  });

  tearDown(() => db.close());

  test('a successful grammar check combines with the local score and '
      'records a real attempt, removing the queue row', () async {
    await pendingRepository.enqueue(
      learnerId: learnerId,
      activityId: 'A1-U5-L6-A05',
      lessonId: 'A1-U5-L6',
      unitId: 'A1-U5',
      canDoIds: ['A1.U5.WRITING.WRITE_FREE_TIME_MESSAGE'],
      // Stored JSON-encoded, exactly as the lesson player enqueues it.
      rawAnswer: jsonEncode('Hello!\nMy free "time" message.'),
      evidenceSkill: 'writing',
      mode: 'mastery',
      localScore: 1.0,
    );
    final grammarCheckService = FakeGrammarCheckService(
      result: const GrammarCheckResult(errorCount: 0, wordCount: 5),
    );
    final resolved = <({int learnerId, String unitId})>[];
    final service = PendingRefinementDrainService(
      pendingRepository: pendingRepository,
      attemptRepository: attemptRepository,
      grammarCheckService: grammarCheckService,
      onItemResolved: ({required learnerId, required unitId}) async {
        resolved.add((learnerId: learnerId, unitId: unitId));
      },
    );

    await service.drainOnce();

    expect(await pendingRepository.allPending(), isEmpty);
    final attempts = await (db.select(
      db.activityAttempts,
    )..where((t) => t.activityId.equals('A1-U5-L6-A05'))).get();
    expect(attempts, hasLength(1));
    expect(attempts.single.score, isNotNull);
    expect(
      attempts.single.score! > 0.9,
      isTrue,
    ); // no grammar errors, full local score
    expect(attempts.single.isCorrect, isTrue);
    expect(attempts.single.mode, 'mastery');
    expect(resolved, [(learnerId: learnerId, unitId: 'A1-U5')]);
    expect(
      grammarCheckService.checkedText.single,
      'Hello!\nMy free "time" message.',
      reason:
          'the grammar checker must see the learner\'s actual sentence, not '
          'its JSON literal — enclosing quotes and escaped newlines would '
          'inflate the error density and corrupt the word count',
    );
    expect(
      attempts.single.rawAnswer,
      jsonEncode('Hello!\nMy free "time" message.'),
      reason:
          'what is *stored* stays JSON-encoded, matching every other attempt '
          'row in the app',
    );
  });

  test('wasFallback round-trips through the queue into the recorded '
      'attempt', () async {
    await pendingRepository.enqueue(
      learnerId: learnerId,
      activityId: 'A1-U5-L6-A05',
      lessonId: 'A1-U5-L6',
      unitId: 'A1-U5',
      canDoIds: const [],
      rawAnswer: jsonEncode('A typed answer to a speaking task.'),
      // A speak activity answered through its typed-answer accessibility
      // fallback: wasFallback=true is always paired with the fallback
      // skill, and must survive the queue (see docs/DATA_MODEL.md).
      evidenceSkill: 'writing',
      mode: 'mastery',
      localScore: 1.0,
      wasFallback: true,
    );
    final service = PendingRefinementDrainService(
      pendingRepository: pendingRepository,
      attemptRepository: attemptRepository,
      grammarCheckService: FakeGrammarCheckService(
        result: const GrammarCheckResult(errorCount: 0, wordCount: 6),
      ),
    );

    await service.drainOnce();

    final attempts = await db.select(db.activityAttempts).get();
    expect(attempts.single.wasFallback, isTrue);
    expect(attempts.single.evidenceSkill, 'writing');
  });

  test(
    'one malformed queue row does not block the rest of the batch',
    () async {
      // `mastry` is not an ActivityMode — ActivityMode.parse throws
      // UnsupportedContentSchemaException on it, from inside _finalize.
      await pendingRepository.enqueue(
        learnerId: learnerId,
        activityId: 'A1-BAD-A01',
        lessonId: 'A1-U5-L6',
        unitId: 'A1-U5',
        canDoIds: const [],
        rawAnswer: jsonEncode('poison'),
        evidenceSkill: 'writing',
        mode: 'mastry',
        localScore: 1.0,
      );
      await pendingRepository.enqueue(
        learnerId: learnerId,
        activityId: 'A1-U5-L6-A05',
        lessonId: 'A1-U5-L6',
        unitId: 'A1-U5',
        canDoIds: const [],
        rawAnswer: jsonEncode('a perfectly normal answer'),
        evidenceSkill: 'writing',
        mode: 'mastery',
        localScore: 1.0,
      );
      final service = PendingRefinementDrainService(
        pendingRepository: pendingRepository,
        attemptRepository: attemptRepository,
        grammarCheckService: FakeGrammarCheckService(
          result: const GrammarCheckResult(errorCount: 0, wordCount: 5),
        ),
      );

      await service.drainOnce();

      final attempts = await db.select(db.activityAttempts).get();
      expect(
        attempts.map((a) => a.activityId),
        ['A1-U5-L6-A05'],
        reason:
            'the bad row comes first in allPending() order — without per-item '
            'isolation it would abort the batch and wedge the queue forever',
      );
      final pending = await pendingRepository.allPending();
      expect(pending, hasLength(1));
      expect(pending.single.activityId, 'A1-BAD-A01');
      expect(
        pending.single.attemptCount,
        1,
        reason: 'the bad row degrades into an ordinary retry, not a crash',
      );
    },
  );

  test('many grammar errors pull the combined score down, but content '
      'coverage still dominates', () async {
    await pendingRepository.enqueue(
      learnerId: learnerId,
      activityId: 'A1-U5-L6-A05',
      lessonId: 'A1-U5-L6',
      unitId: 'A1-U5',
      canDoIds: const [],
      rawAnswer: 'answer',
      evidenceSkill: 'writing',
      mode: 'mastery',
      localScore: 1.0,
    );
    final grammarCheckService = FakeGrammarCheckService(
      result: const GrammarCheckResult(errorCount: 10, wordCount: 5),
    );
    final service = PendingRefinementDrainService(
      pendingRepository: pendingRepository,
      attemptRepository: attemptRepository,
      grammarCheckService: grammarCheckService,
    );

    await service.drainOnce();

    final attempts = await db.select(db.activityAttempts).get();
    expect(attempts.single.score! < 1.0, isTrue);
    // Grammar may take at most a quarter of the scale (combineSignals), so
    // a fully-covered answer still passes however error-dense it is.
    expect(attempts.single.score, closeTo(0.75, 1e-9));
    expect(attempts.single.isCorrect, isTrue);
    final criteria =
        jsonDecode(attempts.single.criteriaScores!) as Map<String, dynamic>;
    expect(criteria['rubric'], 1.0);
    expect(criteria['grammar'], 1.0);
    expect(criteria['final'], closeTo(0.75, 1e-9));
    expect(criteria.containsKey('meaning'), isFalse);
    expect(criteria.containsKey('judgement'), isFalse);
  });

  group('ADR 0013: the meaning signal and the AI pack', () {
    const task = JudgementTask(
      prompt: 'Write a message about your free time.',
      modelAnswers: ['Hi! Are you free on Saturday? Let\'s go to the park.'],
    );

    Future<void> enqueueOne({
      double localScore = 0.5,
      double? meaningSignal,
      bool onlineAllowed = true,
      String activityId = 'A1-U5-L6-A05',
    }) => pendingRepository.enqueue(
      learnerId: learnerId,
      activityId: activityId,
      lessonId: 'A1-U5-L6',
      unitId: 'A1-U5',
      canDoIds: const ['A1.U5.WRITING.WRITE_FREE_TIME_MESSAGE'],
      rawAnswer: jsonEncode('Hello! Free on Saturday?'),
      evidenceSkill: 'writing',
      mode: 'mastery',
      localScore: localScore,
      meaningSignal: meaningSignal,
      onlineAllowed: onlineAllowed,
    );

    test('the meaning signal carried on the row raises the grade within the '
        'bound, alongside the online grammar check', () async {
      await enqueueOne(localScore: 0.5, meaningSignal: 1.0);
      final service = PendingRefinementDrainService(
        pendingRepository: pendingRepository,
        attemptRepository: attemptRepository,
        grammarCheckService: FakeGrammarCheckService(
          result: const GrammarCheckResult(errorCount: 0, wordCount: 5),
        ),
      );

      await service.drainOnce();

      final attempt = (await db.select(db.activityAttempts).get()).single;
      expect(attempt.score, closeTo(0.75, 1e-9));
      expect(attempt.isCorrect, isTrue);
      final criteria =
          jsonDecode(attempt.criteriaScores!) as Map<String, dynamic>;
      expect(criteria['rubric'], 0.5);
      expect(criteria['meaning'], 1.0);
      expect(criteria['grammar'], 0.0);
    });

    test('an installed pack judges first: its grammar and verdict enter the '
        'grade, its explanation is stored, and the online check is never '
        'called', () async {
      await enqueueOne(localScore: 0.5, meaningSignal: 1.0);
      final grammar = FakeGrammarCheckService(
        result: const GrammarCheckResult(errorCount: 0, wordCount: 5),
      );
      final pack = FakeLocalJudgementService(
        available: true,
        judgement: const LocalJudgement(
          meaningOk: true,
          grammarIssues: 0,
          wordCount: 5,
          pack: 'test-pack-1',
          explanationEn: 'You asked about Saturday. Good.',
          explanationAr: 'سألت عن يوم السبت. جيد.',
        ),
      );
      final service = PendingRefinementDrainService(
        pendingRepository: pendingRepository,
        attemptRepository: attemptRepository,
        grammarCheckService: grammar,
        localJudgementService: pack,
        judgementTaskFor: (_) async => task,
      );

      await service.drainOnce();

      expect(grammar.checkedText, isEmpty);
      expect(pack.judgedAnswers, ['Hello! Free on Saturday?']);
      final attempt = (await db.select(db.activityAttempts).get()).single;
      // +0.25 (meaning) + 0.10 (judgement) is clamped to the bound.
      expect(attempt.score, closeTo(0.75, 1e-9));
      expect(attempt.isCorrect, isTrue);
      final criteria =
          jsonDecode(attempt.criteriaScores!) as Map<String, dynamic>;
      expect(criteria['judgement'], true);
      expect(criteria['pack'], 'test-pack-1');
      expect(explanationIn(attempt.criteriaScores), (
        en: 'You asked about Saturday. Good.',
        ar: 'سألت عن يوم السبت. جيد.',
      ));
      expect(await pendingRepository.allPending(), isEmpty);
    });

    test('a row not allowed online never reaches the grammar check, and '
        'without a pack resolves through the bounded fallback', () async {
      await enqueueOne(localScore: 1.0, onlineAllowed: false);
      final grammar = FakeGrammarCheckService(
        result: const GrammarCheckResult(errorCount: 0, wordCount: 5),
      );
      final service = PendingRefinementDrainService(
        pendingRepository: pendingRepository,
        attemptRepository: attemptRepository,
        grammarCheckService: grammar,
        maxAttemptsBeforeFallback: 2,
      );

      await service.drainOnce();
      expect(grammar.checkedText, isEmpty);
      expect(await db.select(db.activityAttempts).get(), isEmpty);
      expect((await pendingRepository.allPending()).single.attemptCount, 1);

      await service.drainOnce();
      expect(grammar.checkedText, isEmpty);
      final attempt = (await db.select(db.activityAttempts).get()).single;
      expect(attempt.score, 1.0);
      expect(await pendingRepository.allPending(), isEmpty);
    });

    test('a failing pack falls through to the online check, and after three '
        'failures in a session is not asked again', () async {
      for (var i = 0; i < 4; i++) {
        await enqueueOne(localScore: 1.0, activityId: 'A1-U5-L6-A0$i');
      }
      final pack = FakeLocalJudgementService(
        available: true,
        failWith: const LocalJudgementUnavailableException('out of memory'),
      );
      final grammar = FakeGrammarCheckService(
        result: const GrammarCheckResult(errorCount: 0, wordCount: 5),
      );
      final service = PendingRefinementDrainService(
        pendingRepository: pendingRepository,
        attemptRepository: attemptRepository,
        grammarCheckService: grammar,
        localJudgementService: pack,
        judgementTaskFor: (_) async => task,
      );

      await service.drainOnce();

      expect(pack.judgedAnswers, hasLength(3));
      expect(grammar.checkedText, hasLength(4));
      expect(await db.select(db.activityAttempts).get(), hasLength(4));
    });

    test(
      'a pack is not asked about an activity that has left the bundle',
      () async {
        await enqueueOne(localScore: 1.0);
        final pack = FakeLocalJudgementService(
          available: true,
          judgement: const LocalJudgement(
            meaningOk: true,
            grammarIssues: 0,
            wordCount: 5,
            pack: 'test-pack-1',
          ),
        );
        final service = PendingRefinementDrainService(
          pendingRepository: pendingRepository,
          attemptRepository: attemptRepository,
          grammarCheckService: FakeGrammarCheckService(
            result: const GrammarCheckResult(errorCount: 0, wordCount: 5),
          ),
          localJudgementService: pack,
          judgementTaskFor: (_) async => null,
        );

        await service.drainOnce();

        expect(pack.judgedAnswers, isEmpty);
        expect(await db.select(db.activityAttempts).get(), hasLength(1));
      },
    );
  });

  test(
    'a failed grammar check (below the retry threshold) is not '
    'finalized — the queue row stays, with its attempt count bumped',
    () async {
      await pendingRepository.enqueue(
        learnerId: learnerId,
        activityId: 'A1-U5-L6-A05',
        lessonId: 'A1-U5-L6',
        unitId: 'A1-U5',
        canDoIds: const [],
        rawAnswer: 'answer',
        evidenceSkill: 'writing',
        mode: 'mastery',
        localScore: 1.0,
      );
      final grammarCheckService = FakeGrammarCheckService(
        failure: const GrammarCheckUnavailableException('offline'),
      );
      var resolvedCallbackFired = false;
      final service = PendingRefinementDrainService(
        pendingRepository: pendingRepository,
        attemptRepository: attemptRepository,
        grammarCheckService: grammarCheckService,
        onItemResolved: ({required learnerId, required unitId}) async {
          resolvedCallbackFired = true;
        },
      );

      await service.drainOnce();

      expect(await db.select(db.activityAttempts).get(), isEmpty);
      final pending = await pendingRepository.allPending();
      expect(pending, hasLength(1));
      expect(pending.single.attemptCount, 1);
      expect(
        resolvedCallbackFired,
        isFalse,
        reason: 'nothing was actually resolved, so the callback must not fire',
      );
    },
  );

  test('a queue row that has failed enough times finalizes via the '
      'local-only score — the bounded fallback', () async {
    final id = await pendingRepository.enqueue(
      learnerId: learnerId,
      activityId: 'A1-U5-L6-A05',
      lessonId: 'A1-U5-L6',
      unitId: 'A1-U5',
      canDoIds: const [],
      rawAnswer: 'answer',
      evidenceSkill: 'writing',
      mode: 'mastery',
      localScore: 0.8,
    );
    // Pre-fail it 4 times, one below the default threshold of 5.
    for (var i = 0; i < 4; i++) {
      await pendingRepository.recordFailedAttempt(
        id: id,
        attemptedAt: DateTime.utc(2026, 9, 8),
      );
    }
    final grammarCheckService = FakeGrammarCheckService(
      failure: const GrammarCheckUnavailableException('still offline'),
    );
    final service = PendingRefinementDrainService(
      pendingRepository: pendingRepository,
      attemptRepository: attemptRepository,
      grammarCheckService: grammarCheckService,
    );

    await service.drainOnce();

    expect(await pendingRepository.allPending(), isEmpty);
    final attempts = await db.select(db.activityAttempts).get();
    expect(attempts, hasLength(1));
    expect(attempts.single.score, 0.8); // local-only score, unrefined
  });

  test('an old-enough queue row finalizes via the local-only score even '
      'on its very first failed attempt — the age-based fallback', () async {
    await pendingRepository.enqueue(
      learnerId: learnerId,
      activityId: 'A1-U5-L6-A05',
      lessonId: 'A1-U5-L6',
      unitId: 'A1-U5',
      canDoIds: const [],
      rawAnswer: 'answer',
      evidenceSkill: 'writing',
      mode: 'mastery',
      localScore: 0.6,
    );
    // enqueue() always stamps `now`, so directly age the row for this test.
    await (db.update(
      db.pendingOnlineRefinements,
    )..where((t) => t.activityId.equals('A1-U5-L6-A05'))).write(
      PendingOnlineRefinementsCompanion(
        submittedAt: Value(DateTime.now().subtract(const Duration(days: 30))),
      ),
    );
    final grammarCheckService = FakeGrammarCheckService(
      failure: const GrammarCheckUnavailableException('offline'),
    );
    final service = PendingRefinementDrainService(
      pendingRepository: pendingRepository,
      attemptRepository: attemptRepository,
      grammarCheckService: grammarCheckService,
    );

    await service.drainOnce();

    expect(await pendingRepository.allPending(), isEmpty);
    final attempts = await db.select(db.activityAttempts).get();
    expect(attempts.single.score, 0.6);
  });

  test('drainOnce processes at most maxItems queue rows in one call', () async {
    for (var i = 0; i < 3; i++) {
      await pendingRepository.enqueue(
        learnerId: learnerId,
        activityId: 'A1-TEST-A0$i',
        lessonId: 'A1-TEST-L',
        unitId: 'A1-TEST',
        canDoIds: const [],
        rawAnswer: 'answer',
        evidenceSkill: 'writing',
        mode: 'mastery',
        localScore: 1.0,
      );
    }
    final grammarCheckService = FakeGrammarCheckService(
      result: const GrammarCheckResult(errorCount: 0, wordCount: 2),
    );
    final service = PendingRefinementDrainService(
      pendingRepository: pendingRepository,
      attemptRepository: attemptRepository,
      grammarCheckService: grammarCheckService,
    );

    await service.drainOnce(maxItems: 2);

    expect(await pendingRepository.allPending(), hasLength(1));
  });
}
