/// What a local judgement model says about one free answer (ADR 0013's second
/// layer, reserved by ADR 0014 for a downloadable grammar model):
/// whether the answer does what the task asked, how many grammar issues it
/// has, and a short explanation for the learner in simple English and,
/// when the model managed one, in Arabic.
///
/// The judgement moves the score only within `combineSignals`'s bound; the
/// explanations are feedback and are never read by mastery.
class LocalJudgement {
  const LocalJudgement({
    required this.meaningOk,
    required this.grammarIssues,
    required this.wordCount,
    required this.pack,
    this.explanationEn,
    this.explanationAr,
  });

  final bool meaningOk;
  final int grammarIssues;
  final int wordCount;

  /// `<name>-<version>` of the pack that produced this, recorded on the
  /// attempt so a judgement can be traced to the model that made it.
  final String pack;

  final String? explanationEn;
  final String? explanationAr;
}

/// Everything a task's judgement needs besides the answer — resolved from
/// the content bundle by the caller, since the drain itself never reads
/// content.
class JudgementTask {
  const JudgementTask({required this.prompt, required this.modelAnswers});

  final String prompt;
  final List<String> modelAnswers;
}

/// Thrown for any failure to get a usable judgement — no pack installed, the
/// model failed to load or run, a timeout, or output that is not the JSON
/// asked for. Callers treat every instance identically: carry on without
/// the judgement.
class LocalJudgementUnavailableException implements Exception {
  const LocalJudgementUnavailableException(this.message);
  final String message;

  @override
  String toString() => 'LocalJudgementUnavailableException: $message';
}

/// Judges a free answer with the installed local model, entirely on the device.
/// Implementations must throw [LocalJudgementUnavailableException] (never
/// let another exception type escape) for any failure.
abstract interface class LocalJudgementService {
  /// Whether a pack is installed and healthy enough to ask. Cheap; the drain
  /// asks before every item so an uninstalled pack costs nothing.
  Future<bool> get isAvailable;

  Future<LocalJudgement> judge({
    required JudgementTask task,
    required String answer,
  });
}

/// The binding until a local model ships (ADR 0014, grammar), and the state
/// of a build whose pack is not installed: never available, never asked.
class UnavailableLocalJudgementService implements LocalJudgementService {
  const UnavailableLocalJudgementService();

  @override
  Future<bool> get isAvailable async => false;

  @override
  Future<LocalJudgement> judge({
    required JudgementTask task,
    required String answer,
  }) async {
    throw const LocalJudgementUnavailableException(
      'no local model is installed',
    );
  }
}
