import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/data/drift_activity_attempt_repository.dart';

void main() {
  late AppDatabase db;
  late DriftActivityAttemptRepository repo;
  late int learnerId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftActivityAttemptRepository(db);
    learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: 'learner-1',
            createdAt: DateTime.utc(2026, 9, 2),
          ),
        );
  });

  tearDown(() => db.close());

  test('masteryEvidenceForObjective excludes practice-mode attempts — '
      'practiceCountsAsMastery is always false', () async {
    await repo.recordAttempt(
      learnerId: learnerId,
      activityId: 'A1-U1-L1-A02',
      sessionType: 'lesson',
      mode: ActivityMode.practice,
      evidenceSkill: Skill.reading,
      canDoIds: ['A1.U1.PRODUCTION.INTRODUCE_SELF'],
      isCorrect: true,
      score: 1.0,
    );

    final evidence = await repo.masteryEvidenceForObjective(
      learnerId: learnerId,
      canDoId: 'A1.U1.PRODUCTION.INTRODUCE_SELF',
    );
    expect(evidence, isEmpty);
  });

  test('masteryEvidenceForObjective excludes placement/mission/assessment '
      'evidence — training and assessment evidence stay isolated', () async {
    await repo.recordAttempt(
      learnerId: learnerId,
      activityId: 'A1-FINAL-ASSESS-L01',
      sessionType: 'finalAssessment',
      mode: ActivityMode.mastery,
      evidenceSkill: Skill.listening,
      canDoIds: ['A1.EXIT.LISTENING.UNDERSTAND_EVERYDAY_INFO'],
      isCorrect: true,
      score: 1.0,
    );

    final evidence = await repo.masteryEvidenceForObjective(
      learnerId: learnerId,
      canDoId: 'A1.EXIT.LISTENING.UNDERSTAND_EVERYDAY_INFO',
    );
    expect(evidence, isEmpty);
  });

  test('masteryEvidenceForObjective excludes placement-test evidence — the '
      'A1 Gateway Placement Test never leaks into ordinary mastery/Review, '
      'even when it draws items from real training content', () async {
    await repo.recordAttempt(
      learnerId: learnerId,
      activityId: 'A1-U1-L1-A03',
      sessionType: 'placement',
      sessionId: 'placement-attempt-uuid-1',
      mode: ActivityMode.practice,
      evidenceSkill: Skill.listening,
      canDoIds: ['A1.U1.LISTENING.UNDERSTAND_PERSONAL_INFO'],
      isCorrect: true,
      score: 1.0,
    );

    final evidence = await repo.masteryEvidenceForObjective(
      learnerId: learnerId,
      canDoId: 'A1.U1.LISTENING.UNDERSTAND_PERSONAL_INFO',
    );
    expect(evidence, isEmpty);
  });

  test('masteryEvidenceForObjective returns mastery-mode lesson evidence, '
      'linked via activity_attempt_can_dos', () async {
    await repo.recordAttempt(
      learnerId: learnerId,
      activityId: 'A1-U1-L1-A03',
      lessonId: 'A1-U1-L1',
      sessionType: 'lesson',
      mode: ActivityMode.mastery,
      evidenceSkill: Skill.listening,
      canDoIds: [
        'A1.U1.LISTENING.UNDERSTAND_PERSONAL_INFO',
        'A1.U1.PRODUCTION.INTRODUCE_SELF',
      ],
      isCorrect: true,
      score: 1.0,
    );

    final forListening = await repo.masteryEvidenceForObjective(
      learnerId: learnerId,
      canDoId: 'A1.U1.LISTENING.UNDERSTAND_PERSONAL_INFO',
    );
    final forProduction = await repo.masteryEvidenceForObjective(
      learnerId: learnerId,
      canDoId: 'A1.U1.PRODUCTION.INTRODUCE_SELF',
    );
    expect(forListening, hasLength(1));
    expect(forProduction, hasLength(1));
    expect(forListening.single.evidenceSkill, 'listening');
  });

  test(
    'a speak activity answered via its typed fallback records writing '
    'evidence with wasFallback=true, never spoken-production evidence',
    () async {
      await repo.recordAttempt(
        learnerId: learnerId,
        activityId: 'A1-U0-L1-A04',
        sessionType: 'lesson',
        mode: ActivityMode.mastery,
        evidenceSkill:
            Skill.writing, // the fallback skill, decided by the caller
        canDoIds: ['A1.U0.INTERACTION.RESPOND_GREETING'],
        wasFallback: true,
        isCorrect: true,
        score: 1.0,
      );

      final evidence = await repo.masteryEvidenceForObjective(
        learnerId: learnerId,
        canDoId: 'A1.U0.INTERACTION.RESPOND_GREETING',
      );
      expect(evidence.single.wasFallback, isTrue);
      expect(evidence.single.evidenceSkill, 'writing');
    },
  );

  test('a replay of the same activity appends, never overwrites', () async {
    for (var i = 0; i < 3; i++) {
      await repo.recordAttempt(
        learnerId: learnerId,
        activityId: 'A1-U1-L1-A01',
        sessionType: 'lesson',
        mode: ActivityMode.mastery,
        evidenceSkill: Skill.listening,
        canDoIds: ['A1.U1.LISTENING.UNDERSTAND_PERSONAL_INFO'],
        isCorrect: true,
        score: 1.0,
      );
    }

    final evidence = await repo.masteryEvidenceForObjective(
      learnerId: learnerId,
      canDoId: 'A1.U1.LISTENING.UNDERSTAND_PERSONAL_INFO',
    );
    expect(evidence, hasLength(3));
  });
}
