import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/evaluator.dart';
import 'package:mohingo/features/final_mission/domain/final_mission_scoring.dart';

/// Regression coverage for the A1 Final Mission's migration off opaque
/// `evaluation` strings, plus a real structural bug this migration exposed
/// and fixed: A1-FINAL-MISSION-A02 is a `form`-type activity, and
/// `FormActivityView` never grades forms (see form_activity_view.dart) —
/// it always submits `notAutoGraded`. `FinalMissionScoring` treats any
/// `notAutoGraded` score as "pending review" and gates the whole mission on
/// zero pending, so before this activity was excluded from scoring
/// evidence (see final_mission_screen.dart's `_handleSubmitted`), the
/// mission's `writing` skill group — and therefore the entire mission —
/// could never pass, no matter how well every other activity was answered.
/// This test proves the mission is now completable end to end.
void main() {
  test("the Final Mission's migrated speak/write rubrics parse to real "
      'structured specs, not the legacy-string null fallback — except the '
      'form activity, which is deliberately never graded', () async {
    final json = File('assets/content/en/A1/a1-course-bundle.json')
        .readAsStringSync();
    final index = CourseContentIndex.build(CourseBundleParser.parse(json));
    final mission = index.bundle.finalMission;

    for (final id in [
      'A1-FINAL-MISSION-A03',
      'A1-FINAL-MISSION-A06',
      'A1-FINAL-MISSION-A08',
      'A1-FINAL-MISSION-A10',
      'A1-FINAL-MISSION-A11',
      'A1-FINAL-MISSION-A12',
    ]) {
      final activity = mission.activities.firstWhere((a) => a.id == id);
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

    final form = mission.activities.firstWhere(
      (a) => a.id == 'A1-FINAL-MISSION-A02',
    );
    expect(form, isA<FormActivity>());
    expect((form as FormActivity).evaluation, isNull);
  });

  test('the Final Mission is fully passable once every gradable activity is '
      'answered well and the form activity is excluded from scoring '
      'evidence, mirroring _handleSubmitted', () async {
    final json = File('assets/content/en/A1/a1-course-bundle.json')
        .readAsStringSync();
    final index = CourseContentIndex.build(CourseBundleParser.parse(json));
    final mission = index.bundle.finalMission;

    const sampleAnswers = {
      'A1-FINAL-MISSION-A03':
          "I'm Ali. What's your name? Where are you "
          'from?',
      'A1-FINAL-MISSION-A06':
          'Go straight and turn left. The front entrance is closed, use '
          'the side entrance.',
      'A1-FINAL-MISSION-A08':
          "I'd like the jacket in medium. Can I pay "
          'by card?',
      'A1-FINAL-MISSION-A10':
          'I need the jacket in medium. You should '
          'rest and drink water.',
      'A1-FINAL-MISSION-A11':
          "Let's meet tomorrow. Can we change the time instead?",
      'A1-FINAL-MISSION-A12':
          "Tomorrow we're going to meet. Please bring your umbrella.",
    };

    final scoresBySkill = <String, List<double?>>{};
    for (final activity in mission.activities) {
      if (activity is FormActivity) continue;
      final skill = activity.skill.name;
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
      scoresBySkill.putIfAbsent(skill, () => []).add(score);
    }

    final result = FinalMissionScoring.score(
      mission: mission,
      scoresBySkill: scoresBySkill,
    );

    expect(
      result.passed,
      isTrue,
      reason: result.groupResults
          .where((g) => !g.passed)
          .map(
            (g) =>
                '${g.skills}: pending=${g.pendingReviewCount} '
                'avg=${g.averageScore}',
          )
          .join('; '),
    );
  });
}
