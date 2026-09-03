import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/capstone.dart';
import 'package:mohingo/features/final_assessment/domain/final_assessment_scoring.dart';

FinalAssessment _assessment() {
  return FinalAssessment(
    id: 'A1-FINAL-ASSESSMENT',
    title: 'Assessment',
    titleAr: 'التقييم',
    sourcePolicy: 'secure',
    sections: const {
      'listening': AssessmentSection(activities: [], raw: {}),
      'reading': AssessmentSection(activities: [], raw: {}),
      'writing': AssessmentSection(activities: [], raw: {}),
      'speaking': AssessmentSection(activities: [], raw: {}),
      'mediation': AssessmentSection(activities: [], raw: {}),
    },
    requiredSkills: const [
      'listening',
      'reading',
      'writing',
      'speaking',
      'mediation',
    ],
    noSingleOverallAverage: true,
    fallbackDoesNotCreateSpeakingEvidence: true,
    raw: const {
      'scoring': {
        'receptive': {'minimumPerSkill': 0.6},
        'writing': {'minimumTaskCriterionAverage': 0.6},
        'speaking': {'minimumTaskCriterionAverage': 0.6},
        'mediation': {'minimumCriterionAverage': 0.6},
      },
    },
  );
}

Map<String, List<double?>> _allSectionsPassing() => {
  'listening': [1.0, 0.8],
  'reading': [0.8, 0.8],
  'writing': [0.8],
  'speaking': [0.8],
  'mediation': [1.0],
};

void main() {
  test(
    'every required section scored and above threshold -> overall passed',
    () {
      final assessment = _assessment();
      final results = FinalAssessmentScoring.score(
        assessment: assessment,
        scoresBySection: _allSectionsPassing(),
      );
      for (final r in results) {
        expect(r.status, FinalAssessmentSectionStatus.passed);
      }
      expect(FinalAssessmentScoring.overallPassed(assessment, results), isTrue);
    },
  );

  test('a section below its threshold is notMet, and never gets averaged '
      'away by strong sections elsewhere', () {
    final assessment = _assessment();
    final scores = _allSectionsPassing()..['listening'] = [0.2, 0.2];
    final results = FinalAssessmentScoring.score(
      assessment: assessment,
      scoresBySection: scores,
    );
    final listening = results.firstWhere((r) => r.section == 'listening');
    expect(listening.status, FinalAssessmentSectionStatus.notMet);
    final reading = results.firstWhere((r) => r.section == 'reading');
    expect(
      reading.status,
      FinalAssessmentSectionStatus.passed,
      reason: 'reading is scored independently of listening',
    );
    expect(FinalAssessmentScoring.overallPassed(assessment, results), isFalse);
  });

  test('a section with an un-auto-graded item is pendingReview, never '
      'silently marked passed or notMet', () {
    final assessment = _assessment();
    final scores = _allSectionsPassing()..['writing'] = [0.8, null];
    final results = FinalAssessmentScoring.score(
      assessment: assessment,
      scoresBySection: scores,
    );
    final writing = results.firstWhere((r) => r.section == 'writing');
    expect(writing.status, FinalAssessmentSectionStatus.pendingReview);
    expect(writing.pendingReviewCount, 1);
    expect(FinalAssessmentScoring.overallPassed(assessment, results), isFalse);
  });

  test('overallPassed requires every required skill individually — 4 of 5 '
      'passing is not a pass, matching noSingleOverallAverage', () {
    final assessment = _assessment();
    final scores = _allSectionsPassing()..['mediation'] = [null];
    final results = FinalAssessmentScoring.score(
      assessment: assessment,
      scoresBySection: scores,
    );
    final passingCount = results
        .where((r) => r.status == FinalAssessmentSectionStatus.passed)
        .length;
    expect(passingCount, 4);
    expect(FinalAssessmentScoring.overallPassed(assessment, results), isFalse);
  });
}
