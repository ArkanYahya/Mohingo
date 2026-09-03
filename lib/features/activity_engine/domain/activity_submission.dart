/// Whether a submitted answer was auto-graded correct/incorrect, or needs a
/// task-specific rubric (writing/speaking) not yet built — see
/// docs/DATA_MODEL.md: "objective items auto-scored; writing and speaking
/// use task-specific rubrics."
enum ActivityCorrectness { correct, incorrect, notAutoGraded }

/// What one activity view reports back when the learner submits an answer.
/// The lesson player (Phase 6) turns this into an
/// `ActivityAttemptRepository.recordAttempt` call — this type intentionally
/// carries no learner/session identity, since a view has no idea which
/// lesson/session it's being shown in.
class ActivitySubmission {
  const ActivitySubmission({
    required this.correctness,
    this.score,
    this.rawAnswerJson,
    this.wasFallback = false,
  });

  final ActivityCorrectness correctness;

  /// 0.0-1.0 where known (choice/order/gap/match are 1.0/0.0; writing/
  /// speaking are null until a rubric evaluator exists).
  final double? score;

  /// The learner's actual answer, serialized — stored verbatim in
  /// `activity_attempts.rawAnswer`. Never a speech transcript at rest — see
  /// docs/SECURITY.md.
  final String? rawAnswerJson;

  /// True when a `speak` activity was answered via its typed-answer
  /// accessibility fallback — see docs/DATA_MODEL.md. Always true for
  /// [SpeakActivityView] in this phase (no on-device STT exists yet, see
  /// docs/ARCHITECTURE.md's Phase 8).
  final bool wasFallback;
}

typedef OnActivitySubmitted = void Function(ActivitySubmission submission);
