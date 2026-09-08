import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/evaluator.dart';
import 'package:mohingo/features/final_assessment/domain/final_assessment_scoring.dart';

/// Regression coverage for the A1 Final Assessment's migration off opaque
/// `evaluation` strings onto structured `EvaluationSpec`s. Before this
/// migration, every writing/speaking/mediation item scored `notAutoGraded`
/// (the legacy-string null fallback), so those sections could never clear
/// `FinalAssessmentScoring`'s zero-pending gate and the assessment could
/// never be passed regardless of answer quality — the same class of bug
/// fixed for the regular units (see a1_u0_mastery_regression_test.dart) and
/// the Final Mission (see a1_final_mission_regression_test.dart). Unlike
/// the Final Mission, no section here contains a `form`-type activity, so
/// no additional code fix was needed.
void main() {
  test(
    "the Final Assessment's migrated writing/speaking/mediation rubrics "
    'parse to real structured specs, not the legacy-string null fallback',
    () async {
      final json = File('assets/content/en/A1/a1-course-bundle.json')
          .readAsStringSync();
      final index = CourseContentIndex.build(CourseBundleParser.parse(json));
      final assessment = index.bundle.finalAssessment;

      for (final id in [
        'A1-FINAL-ASSESS-W01',
        'A1-FINAL-ASSESS-W02',
        'A1-FINAL-ASSESS-S01',
        'A1-FINAL-ASSESS-S02',
        'A1-FINAL-ASSESS-S03',
        'A1-FINAL-ASSESS-S04',
        'A1-FINAL-ASSESS-M01',
        'A1-FINAL-ASSESS-M02',
      ]) {
        final activity = assessment.allActivities.firstWhere((a) => a.id == id);
        final evaluation = switch (activity) {
          SpeakActivity(:final evaluation) => evaluation,
          WriteActivity(:final evaluation) => evaluation,
          _ => throw StateError('unexpected activity type for $id'),
        };
        expect(
          evaluation,
          isNotNull,
          reason: '$id should carry a structured EvaluationSpec',
        );
      }
    },
  );

  test('the Final Assessment is fully passable once every item is answered '
      'well, including every writing/speaking/mediation section', () async {
    final json = File('assets/content/en/A1/a1-course-bundle.json')
        .readAsStringSync();
    final index = CourseContentIndex.build(CourseBundleParser.parse(json));
    final assessment = index.bundle.finalAssessment;

    const sampleAnswers = {
      'A1-FINAL-ASSESS-W01':
          "I'm Ali. I live in Erbil. I like walking. What time should I "
          'arrive?',
      'A1-FINAL-ASSESS-W02':
          "I'm busy at six, so can we meet at seven instead? Please "
          'confirm.',
      'A1-FINAL-ASSESS-S01':
          "I'm Ali. A-L-I. I'm from Iraq. I live in Erbil. I'm a "
          'student.',
      'A1-FINAL-ASSESS-S02':
          'Good morning. I start at eight. I like reading. Sorry, please '
          'repeat that.',
      'A1-FINAL-ASSESS-S03':
          "Where is the station, please? I'd like a ticket. Thank you.",
      'A1-FINAL-ASSESS-S04':
          "It's sunny now. I'm going to go for a walk because it's warm.",
      'A1-FINAL-ASSESS-M01':
          'The bus leaves at eight. The platform is three. It arrives at '
          'nine.',
      'A1-FINAL-ASSESS-M02':
          'Your appointment is at 14:30. Please bring '
          "your ID. Do not eat after 13:00.",
    };

    final scoresBySection = <String, List<double?>>{};
    for (final entry in assessment.sections.entries) {
      final sectionKey = entry.key;
      for (final activity in entry.value.activities) {
        final score = switch (activity) {
          SpeakActivity(:final evaluation) when evaluation != null => evaluate(
            evaluation,
            sampleAnswers[activity.id]!,
          ).score,
          WriteActivity(:final evaluation) when evaluation != null => evaluate(
            evaluation,
            sampleAnswers[activity.id]!,
          ).score,
          AudioChoiceActivity() || TextChoiceActivity() => 1.0,
          _ => throw StateError('unexpected activity type: ${activity.id}'),
        };
        scoresBySection.putIfAbsent(sectionKey, () => []).add(score);
      }
    }

    final results = FinalAssessmentScoring.score(
      assessment: assessment,
      scoresBySection: scoresBySection,
    );
    final overallPassed = FinalAssessmentScoring.overallPassed(
      assessment,
      results,
    );

    expect(
      overallPassed,
      isTrue,
      reason: results
          .where((r) => r.status != FinalAssessmentSectionStatus.passed)
          .map(
            (r) =>
                '${r.section}: ${r.status.name} '
                'pending=${r.pendingReviewCount} avg=${r.averageScore}',
          )
          .join('; '),
    );
  });
}
