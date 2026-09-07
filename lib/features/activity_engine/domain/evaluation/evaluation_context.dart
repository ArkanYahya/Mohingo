/// Runtime state a [EvaluationSpec] evaluator may need, assembled once per
/// lesson by whoever plays it (the lesson player, placement test, etc.) —
/// an activity view never resolves this itself. See
/// docs/superpowers/specs/2026-09-07-offline-answer-evaluation-design.md.
class EvaluationContext {
  const EvaluationContext({this.profileName, this.previousAnswers = const {}});
  const EvaluationContext.empty()
    : profileName = null,
      previousAnswers = const {};

  /// The learner's persisted `Learners.name`, if set.
  final String? profileName;

  /// Raw text answers already given earlier in this same play-through,
  /// keyed by activity id — never a database read, just what's been
  /// submitted so far in this session.
  final Map<String, String> previousAnswers;
}
