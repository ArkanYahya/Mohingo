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
    this.pendingOnlineRefinement = false,
    this.correctAnswerLabel,
  });

  final ActivityCorrectness correctness;

  /// The correct answer, in display form — set by the activity view
  /// whenever it already knows one (the same value it passes to its own
  /// inline [ActivityFeedbackBanner]). `LessonPlayerScreen` reads this to
  /// populate the incorrect-answer bottom sheet, since the callback that
  /// fires this submission carries no other way to reach it. `null` when
  /// the activity has no single fixed correct answer to show (e.g. an
  /// open-ended writing/speaking rubric).
  final String? correctAnswerLabel;

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

  /// True only for an open-ended `keywordChecklist`/`onlineRefinement`
  /// rubric's submission: [score] here is the *local* content-only score,
  /// not the final grade — the lesson player enqueues this into
  /// `pending_online_refinements` instead of recording it as an ordinary
  /// attempt. See docs/superpowers/specs/
  /// 2026-09-07-offline-answer-evaluation-design.md's Tier 2.
  final bool pendingOnlineRefinement;
}

typedef OnActivitySubmitted = void Function(ActivitySubmission submission);
