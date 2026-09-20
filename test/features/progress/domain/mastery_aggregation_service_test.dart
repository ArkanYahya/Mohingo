import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/curriculum_structure.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/domain/mastery_aggregation_service.dart';
import 'package:mohingo/features/progress/domain/repositories/activity_attempt_repository.dart';
import 'package:mohingo/features/progress/domain/repositories/unit_lesson_progress_repository.dart';

/// An in-memory fake of the evidence store, already filtering the way the
/// real Drift-backed repository does (mode='mastery', sessionType='lesson')
/// — that filtering contract is verified separately against the real
/// implementation in drift_activity_attempt_repository_test.dart. This fake
/// lets the aggregation *algorithm* be tested in isolation, fast and without
/// a database.
class _FakeActivityAttemptRepository implements ActivityAttemptRepository {
  final List<({int learnerId, String canDoId, ActivityAttempt attempt})>
  _masteryLessonEvidence = [];
  int _nextId = 1;

  /// Test helper: adds one piece of mastery-mode, lesson-session evidence.
  void addEvidence({
    required int learnerId,
    required String canDoId,
    required String evidenceSkill,
    double? score,
    bool? isCorrect,
    bool wasFallback = false,
  }) {
    final id = _nextId++;
    _masteryLessonEvidence.add((
      learnerId: learnerId,
      canDoId: canDoId,
      attempt: ActivityAttempt(
        id: id,
        uuid: 'attempt-$id',
        learnerId: learnerId,
        activityId: 'test-activity-$id',
        sessionType: 'lesson',
        mode: 'mastery',
        evidenceSkill: evidenceSkill,
        wasFallback: wasFallback,
        score: score,
        isCorrect: isCorrect,
        attemptedAt: DateTime.utc(2026, 9, 2),
        updatedAt: DateTime.utc(2026, 9, 2),
      ),
    ));
  }

  @override
  Future<List<ActivityAttempt>> masteryEvidenceForObjective({
    required int learnerId,
    required String canDoId,
  }) async {
    return _masteryLessonEvidence
        .where((e) => e.learnerId == learnerId && e.canDoId == canDoId)
        .map((e) => e.attempt)
        .toList();
  }

  @override
  Future<int> recordAttempt({
    required int learnerId,
    required String activityId,
    String? lessonId,
    required String sessionType,
    String? sessionId,
    required ActivityMode mode,
    required Skill evidenceSkill,
    required List<String> canDoIds,
    String? rawAnswer,
    bool? isCorrect,
    double? score,
    String? criteriaScores,
    bool wasFallback = false,
  }) async => throw UnimplementedError('not needed by these tests');

  @override
  Future<List<ActivityAttempt>> attemptsForLessons({
    required int learnerId,
    required List<String> lessonIds,
  }) async => const [];

  @override
  Future<int> currentStreakDays({
    required int learnerId,
    required DateTime asOf,
  }) async => throw UnimplementedError('not needed by these tests');

  @override
  Future<ActivityAttempt?> latestAttempt({
    required int learnerId,
    required String activityId,
  }) async => throw UnimplementedError('not needed by these tests');
}

class _FakeUnitLessonProgressRepository
    implements UnitLessonProgressRepository {
  final Map<String, UnitProgressData> _byUnitId = {};

  @override
  Future<UnitProgressData?> unitProgress({
    required int learnerId,
    required String unitId,
  }) async => _byUnitId[unitId];

  @override
  Future<void> upsertUnitProgress({
    required int learnerId,
    required String unitId,
    required UnitProgressState state,
    DateTime? masteredAt,
  }) async {
    _byUnitId[unitId] = UnitProgressData(
      id: _byUnitId[unitId]?.id ?? _byUnitId.length + 1,
      uuid: 'unit-progress-$unitId',
      learnerId: learnerId,
      unitId: unitId,
      state: state.name,
      masteredAt: masteredAt,
      isContentStale: false,
      updatedAt: DateTime.utc(2026, 9, 2),
    );
  }

  @override
  Future<List<UnitProgressData>> allUnitProgress({
    required int learnerId,
  }) async => _byUnitId.values.toList();

  @override
  Future<LessonProgressData?> lessonProgress({
    required int learnerId,
    required String lessonId,
  }) async => null;

  @override
  Future<List<LessonProgressData>> lessonProgressForUnit({
    required int learnerId,
    required String unitId,
  }) async => const [];

  @override
  Future<List<LessonProgressData>> allLessonProgress({
    required int learnerId,
  }) async => const [];

  @override
  Future<void> recordLessonPosition({
    required int learnerId,
    required String lessonId,
    required String unitId,
    required String lastActivityId,
  }) async {}
}

const _masteryPolicy = MasteryPolicy(
  minimumObjectiveScore: 0.75,
  minimumEvidencePerRequiredObjective: 2,
  requireProductiveEvidenceWhereDeclared: true,
  practiceCountsAsMastery: false,
  allowSpeechFallbackToWriting: true,
  speechCriteria: ['taskCompletion', 'intelligibility', 'appropriateLanguage'],
  speechAccuracyWeight: 0.2,
);

/// A unit shaped like the real A1-U1: 2 required objectives, one naturally
/// listening-evidenced, one naturally production-evidenced — requiring
/// coverage of both the listening group and the spoken group.
Unit _testUnit() {
  return Unit(
    id: 'TEST-U1',
    title: 'Test Unit',
    titleAr: 'وحدة اختبار',
    levelRole: 'core',
    estimatedMinutes: const [10, 20],
    countsTowardLevelMastery: true,
    lessons: const [],
    mastery: const UnitMastery(
      requiredObjectives: [
        'TEST.LISTENING.OBJECTIVE',
        'TEST.PRODUCTION.OBJECTIVE',
      ],
      requiredSkillGroups: [
        ['listening'],
        ['spokenProduction', 'writing'],
      ],
      minimumObjectiveScore: 0.75,
      raw: {},
    ),
  );
}

void main() {
  late _FakeActivityAttemptRepository attemptRepo;
  late _FakeUnitLessonProgressRepository progressRepo;
  late MasteryAggregationService service;
  const learnerId = 1;

  setUp(() {
    attemptRepo = _FakeActivityAttemptRepository();
    progressRepo = _FakeUnitLessonProgressRepository();
    service = MasteryAggregationService(
      attemptRepository: attemptRepo,
      progressRepository: progressRepo,
    );
  });

  test(
    'a unit with zero evidence is not mastered and has no evidence',
    () async {
      final result = await service.evaluateUnit(
        learnerId: learnerId,
        unit: _testUnit(),
        masteryPolicy: _masteryPolicy,
      );

      expect(result.isMastered, isFalse);
      expect(result.hasAnyEvidence, isFalse);
      expect(result.unmasteredObjectiveIds, hasLength(2));
    },
  );

  test('minimumEvidencePerRequiredObjective: one qualifying attempt is not '
      'enough when the policy requires 2', () async {
    attemptRepo.addEvidence(
      learnerId: learnerId,
      canDoId: 'TEST.LISTENING.OBJECTIVE',
      evidenceSkill: 'listening',
      score: 1.0,
    );

    final result = await service.evaluateUnit(
      learnerId: learnerId,
      unit: _testUnit(),
      masteryPolicy: _masteryPolicy,
    );

    expect(result.hasAnyEvidence, isTrue);
    expect(
      result.masteredObjectiveIds,
      isNot(contains('TEST.LISTENING.OBJECTIVE')),
    );
  });

  test('minimumEvidencePerRequiredObjective: a 2nd qualifying attempt masters '
      'the objective', () async {
    attemptRepo
      ..addEvidence(
        learnerId: learnerId,
        canDoId: 'TEST.LISTENING.OBJECTIVE',
        evidenceSkill: 'listening',
        score: 1.0,
      )
      ..addEvidence(
        learnerId: learnerId,
        canDoId: 'TEST.LISTENING.OBJECTIVE',
        evidenceSkill: 'listening',
        score: 0.8,
      );

    final result = await service.evaluateUnit(
      learnerId: learnerId,
      unit: _testUnit(),
      masteryPolicy: _masteryPolicy,
    );

    expect(result.masteredObjectiveIds, contains('TEST.LISTENING.OBJECTIVE'));
  });

  test('minimumObjectiveScore: attempts scoring below the unit threshold are '
      'not counted as qualifying evidence', () async {
    attemptRepo
      ..addEvidence(
        learnerId: learnerId,
        canDoId: 'TEST.LISTENING.OBJECTIVE',
        evidenceSkill: 'listening',
        score: 0.5, // below the 0.75 threshold
      )
      ..addEvidence(
        learnerId: learnerId,
        canDoId: 'TEST.LISTENING.OBJECTIVE',
        evidenceSkill: 'listening',
        score: 0.6, // also below
      );

    final result = await service.evaluateUnit(
      learnerId: learnerId,
      unit: _testUnit(),
      masteryPolicy: _masteryPolicy,
    );

    expect(
      result.masteredObjectiveIds,
      isNot(contains('TEST.LISTENING.OBJECTIVE')),
    );
    expect(
      result.hasAnyEvidence,
      isTrue,
    ); // evidence exists, just doesn't qualify
  });

  test('skill-group coverage: mastering every objective is not enough if a '
      'declared skill group has no covering evidence (recognition without '
      'production must not read as fully mastered)', () async {
    // Both required objectives individually mastered, but both only ever
    // produced 'listening' evidence — the ["spokenProduction","writing"]
    // group is never covered.
    for (final canDoId in [
      'TEST.LISTENING.OBJECTIVE',
      'TEST.PRODUCTION.OBJECTIVE',
    ]) {
      attemptRepo
        ..addEvidence(
          learnerId: learnerId,
          canDoId: canDoId,
          evidenceSkill: 'listening',
          score: 1.0,
        )
        ..addEvidence(
          learnerId: learnerId,
          canDoId: canDoId,
          evidenceSkill: 'listening',
          score: 1.0,
        );
    }

    final result = await service.evaluateUnit(
      learnerId: learnerId,
      unit: _testUnit(),
      masteryPolicy: _masteryPolicy,
    );

    expect(result.masteredObjectiveIds, hasLength(2));
    expect(result.unmasteredObjectiveIds, isEmpty);
    expect(
      result.isMastered,
      isFalse,
      reason: 'spoken/writing group never covered',
    );
    expect(result.missingSkillGroups, [
      ['spokenProduction', 'writing'],
    ]);
  });

  test('a fully qualifying unit — every objective mastered and every skill '
      'group covered — is mastered', () async {
    attemptRepo
      ..addEvidence(
        learnerId: learnerId,
        canDoId: 'TEST.LISTENING.OBJECTIVE',
        evidenceSkill: 'listening',
        score: 1.0,
      )
      ..addEvidence(
        learnerId: learnerId,
        canDoId: 'TEST.LISTENING.OBJECTIVE',
        evidenceSkill: 'listening',
        score: 1.0,
      )
      ..addEvidence(
        learnerId: learnerId,
        canDoId: 'TEST.PRODUCTION.OBJECTIVE',
        evidenceSkill: 'spokenProduction',
        score: 1.0,
      )
      ..addEvidence(
        learnerId: learnerId,
        canDoId: 'TEST.PRODUCTION.OBJECTIVE',
        evidenceSkill: 'spokenProduction',
        score: 1.0,
      );

    final result = await service.evaluateUnit(
      learnerId: learnerId,
      unit: _testUnit(),
      masteryPolicy: _masteryPolicy,
    );

    expect(result.isMastered, isTrue);
    expect(result.missingSkillGroups, isEmpty);
  });

  test('a speaking fallback (evidenceSkill=writing, wasFallback=true) still '
      'satisfies the writing/spokenProduction group — the fallback rule is '
      'enforced upstream at write time, not re-derived here', () async {
    attemptRepo
      ..addEvidence(
        learnerId: learnerId,
        canDoId: 'TEST.LISTENING.OBJECTIVE',
        evidenceSkill: 'listening',
        score: 1.0,
      )
      ..addEvidence(
        learnerId: learnerId,
        canDoId: 'TEST.LISTENING.OBJECTIVE',
        evidenceSkill: 'listening',
        score: 1.0,
      )
      ..addEvidence(
        learnerId: learnerId,
        canDoId: 'TEST.PRODUCTION.OBJECTIVE',
        evidenceSkill: 'writing', // fallback skill, not spokenProduction
        wasFallback: true,
        score: 1.0,
      )
      ..addEvidence(
        learnerId: learnerId,
        canDoId: 'TEST.PRODUCTION.OBJECTIVE',
        evidenceSkill: 'writing',
        wasFallback: true,
        score: 1.0,
      );

    final result = await service.evaluateUnit(
      learnerId: learnerId,
      unit: _testUnit(),
      masteryPolicy: _masteryPolicy,
    );

    expect(result.isMastered, isTrue);
  });

  group('refreshUnitProgress', () {
    test(
      'writes notStarted/inProgress/mastered to the progress cache',
      () async {
        await service.refreshUnitProgress(
          learnerId: learnerId,
          unit: _testUnit(),
          masteryPolicy: _masteryPolicy,
        );
        expect(
          (await progressRepo.unitProgress(
            learnerId: learnerId,
            unitId: 'TEST-U1',
          ))!.state,
          'notStarted',
        );

        attemptRepo.addEvidence(
          learnerId: learnerId,
          canDoId: 'TEST.LISTENING.OBJECTIVE',
          evidenceSkill: 'listening',
          score: 1.0,
        );
        await service.refreshUnitProgress(
          learnerId: learnerId,
          unit: _testUnit(),
          masteryPolicy: _masteryPolicy,
        );
        expect(
          (await progressRepo.unitProgress(
            learnerId: learnerId,
            unitId: 'TEST-U1',
          ))!.state,
          'inProgress',
        );
      },
    );

    test(
      'preserves the original masteredAt across repeated refreshes',
      () async {
        attemptRepo
          ..addEvidence(
            learnerId: learnerId,
            canDoId: 'TEST.LISTENING.OBJECTIVE',
            evidenceSkill: 'listening',
            score: 1.0,
          )
          ..addEvidence(
            learnerId: learnerId,
            canDoId: 'TEST.LISTENING.OBJECTIVE',
            evidenceSkill: 'listening',
            score: 1.0,
          )
          ..addEvidence(
            learnerId: learnerId,
            canDoId: 'TEST.PRODUCTION.OBJECTIVE',
            evidenceSkill: 'spokenProduction',
            score: 1.0,
          )
          ..addEvidence(
            learnerId: learnerId,
            canDoId: 'TEST.PRODUCTION.OBJECTIVE',
            evidenceSkill: 'spokenProduction',
            score: 1.0,
          );

        await service.refreshUnitProgress(
          learnerId: learnerId,
          unit: _testUnit(),
          masteryPolicy: _masteryPolicy,
        );
        final firstMasteredAt = (await progressRepo.unitProgress(
          learnerId: learnerId,
          unitId: 'TEST-U1',
        ))!.masteredAt;
        expect(firstMasteredAt, isNotNull);

        // Refresh again (e.g. after a later, unrelated evidence recompute) —
        // masteredAt must not be bumped forward.
        await service.refreshUnitProgress(
          learnerId: learnerId,
          unit: _testUnit(),
          masteryPolicy: _masteryPolicy,
        );
        final secondMasteredAt = (await progressRepo.unitProgress(
          learnerId: learnerId,
          unitId: 'TEST-U1',
        ))!.masteredAt;
        expect(secondMasteredAt, firstMasteredAt);
      },
    );
  });
}
