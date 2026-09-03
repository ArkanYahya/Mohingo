import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/capstone.dart';
import 'package:mohingo/features/final_mission/domain/final_mission_scoring.dart';

FinalMission _mission({List<List<String>>? groups, double? minimumScore}) {
  return FinalMission(
    id: 'A1-FINAL-MISSION',
    title: 'Mission',
    titleAr: 'المهمة',
    scenario: 'scenario',
    canDo: const [],
    stages: const [],
    activities: const [],
    requiredSkillGroups:
        groups ??
        const [
          ['listening', 'reading'],
          ['spokenInteraction', 'writing'],
          ['mediation'],
        ],
    minimumCriterionScore: minimumScore ?? 0.6,
    noSingleAverageCompensation: true,
    raw: const {},
  );
}

void main() {
  test('every group scored and above threshold -> overall passed', () {
    final result = FinalMissionScoring.score(
      mission: _mission(),
      scoresBySkill: {
        'listening': [1.0],
        'reading': [1.0],
        'spokenInteraction': [0.8],
        'writing': [0.8],
        'mediation': [1.0],
      },
    );
    expect(result.passed, isTrue);
    for (final group in result.groupResults) {
      expect(group.passed, isTrue);
    }
  });

  test(
    'one group below the threshold fails the whole mission — a perfect '
    'score elsewhere never compensates for it (noSingleAverageCompensation)',
    () {
      final result = FinalMissionScoring.score(
        mission: _mission(),
        scoresBySkill: {
          'listening': [1.0],
          'reading': [1.0],
          'spokenInteraction': [0.2], // below 0.6
          'writing': [0.2],
          'mediation': [1.0],
        },
      );
      expect(result.passed, isFalse);
      final weakGroup = result.groupResults.firstWhere(
        (g) => g.skills.contains('spokenInteraction'),
      );
      expect(weakGroup.passed, isFalse);
      final strongGroup = result.groupResults.firstWhere(
        (g) => g.skills.contains('listening'),
      );
      expect(
        strongGroup.passed,
        isTrue,
        reason:
            'the receptive group is unaffected by the productive group\'s '
            'low score — groups are never blended',
      );
    },
  );

  test('a group with un-auto-graded (null) evidence is reported pending '
      'review, never silently passed or failed', () {
    final result = FinalMissionScoring.score(
      mission: _mission(),
      scoresBySkill: {
        'listening': [1.0],
        'reading': [1.0],
        'spokenInteraction': [null], // free-response, no rubric grader yet
        'writing': [0.8],
        'mediation': [1.0],
      },
    );
    final group = result.groupResults.firstWhere(
      (g) => g.skills.contains('spokenInteraction'),
    );
    expect(group.passed, isFalse);
    expect(group.pendingReviewCount, 1);
    expect(result.passed, isFalse);
  });

  test('a group with no evidence at all is not passed', () {
    final result = FinalMissionScoring.score(
      mission: _mission(),
      scoresBySkill: {
        'listening': [1.0],
        'reading': [1.0],
        'mediation': [1.0],
        // spokenInteraction/writing never attempted
      },
    );
    final group = result.groupResults.firstWhere(
      (g) => g.skills.contains('spokenInteraction'),
    );
    expect(group.passed, isFalse);
    expect(group.scoredEvidenceCount, 0);
    expect(result.passed, isFalse);
  });
}
