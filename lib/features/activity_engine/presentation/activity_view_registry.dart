import 'package:flutter/material.dart';

import '../../../content/models/activity.dart';
import '../../../content/models/media_specification.dart';
import '../../../data/local/database.dart' show ActivityAttempt;
import '../domain/activity_submission.dart';
import '../domain/evaluation/evaluation_context.dart';
import 'views/choice_activity_view.dart';
import 'views/dialogue_activity_view.dart';
import 'views/form_activity_view.dart';
import 'views/gap_activity_view.dart';
import 'views/match_activity_view.dart';
import 'views/order_activity_view.dart';
import 'views/speak_activity_view.dart';
import 'views/write_activity_view.dart';

/// Builds the widget for one [Activity], dispatching on its runtime type —
/// a typed registry, not a large switch scattered across screens. See
/// docs/ARCHITECTURE.md.
///
/// [mediaByKey] is only consulted by `audioChoice`/`textChoice` activities
/// whose `optionMode` is `"media"` (picture-choice items) — pass the
/// current level's `CourseContentIndex.bundle.mediaSpecifications` once
/// content is wired in (Phase 6); an empty map is a safe default for any
/// activity that doesn't need it.
Widget buildActivityView(
  Activity activity, {
  required int learnerId,
  required OnActivitySubmitted onSubmitted,
  Map<String, MediaSpecification> mediaByKey = const {},
  EvaluationContext evaluationContext = const EvaluationContext.empty(),
  ActivityAttempt? reviewAttempt,
  Key? key,
}) {
  return switch (activity) {
    AudioChoiceActivity a => ChoiceActivityView.audioChoice(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
      mediaByKey: mediaByKey,
      reviewAttempt: reviewAttempt,
    ),
    TextChoiceActivity a => ChoiceActivityView.textChoice(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
      mediaByKey: mediaByKey,
      reviewAttempt: reviewAttempt,
    ),
    MatchActivity a => MatchActivityView(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
      reviewAttempt: reviewAttempt,
    ),
    OrderActivity a => OrderActivityView(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
      reviewAttempt: reviewAttempt,
    ),
    GapActivity a => GapActivityView(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
      reviewAttempt: reviewAttempt,
    ),
    FormActivity a => FormActivityView(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
      reviewAttempt: reviewAttempt,
    ),
    SpeakActivity a => SpeakActivityView(
      key: key,
      activity: a,
      learnerId: learnerId,
      onSubmitted: onSubmitted,
      evaluationContext: evaluationContext,
      reviewAttempt: reviewAttempt,
    ),
    WriteActivity a => WriteActivityView(
      key: key,
      activity: a,
      learnerId: learnerId,
      onSubmitted: onSubmitted,
      evaluationContext: evaluationContext,
      reviewAttempt: reviewAttempt,
    ),
    // dialogue has no review mode — no authored instance exists in the real
    // bundle to review yet (verified in DialogueActivityView's own doc
    // comment). Always renders live/interactive; see docs/superpowers/specs/
    // 2026-09-09-lesson-answer-review-design.md.
    DialogueActivity a => DialogueActivityView(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
    ),
  };
}
