import 'package:flutter/material.dart';

import '../../../content/models/activity.dart';
import '../../../content/models/media_specification.dart';
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
  required OnActivitySubmitted onSubmitted,
  Map<String, MediaSpecification> mediaByKey = const {},
  EvaluationContext evaluationContext = const EvaluationContext.empty(),
  Key? key,
}) {
  return switch (activity) {
    AudioChoiceActivity a => ChoiceActivityView.audioChoice(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
      mediaByKey: mediaByKey,
    ),
    TextChoiceActivity a => ChoiceActivityView.textChoice(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
      mediaByKey: mediaByKey,
    ),
    MatchActivity a => MatchActivityView(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
    ),
    OrderActivity a => OrderActivityView(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
    ),
    GapActivity a => GapActivityView(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
    ),
    FormActivity a => FormActivityView(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
    ),
    SpeakActivity a => SpeakActivityView(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
      evaluationContext: evaluationContext,
    ),
    WriteActivity a => WriteActivityView(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
      evaluationContext: evaluationContext,
    ),
    DialogueActivity a => DialogueActivityView(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
    ),
  };
}
