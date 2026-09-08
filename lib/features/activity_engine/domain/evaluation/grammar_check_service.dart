/// A grammar/spelling-quality signal for one piece of text — the online
/// half of Tier 2's open-ended grading. See docs/superpowers/specs/
/// 2026-09-07-offline-answer-evaluation-design.md.
class GrammarCheckResult {
  const GrammarCheckResult({required this.errorCount, required this.wordCount});

  /// Number of grammar/spelling issues the service flagged.
  final int errorCount;

  /// Word count of the checked text — used to normalize [errorCount] into a
  /// density rather than a raw count, so a longer answer isn't unfairly
  /// penalized for a proportionally similar error rate.
  final int wordCount;
}

/// Thrown for any failure to get a usable result — a non-200 response, a
/// malformed body, a timeout, or no network at all. Callers (the drain
/// service) treat every instance of this identically: retry later, and
/// eventually fall back to the local-only score. Never lets a content bug
/// or a flaky network response crash the drain loop.
class GrammarCheckUnavailableException implements Exception {
  const GrammarCheckUnavailableException(this.message);
  final String message;

  @override
  String toString() => 'GrammarCheckUnavailableException: $message';
}

/// Checks [text] for grammar/spelling issues. Implementations must throw
/// [GrammarCheckUnavailableException] (never let another exception type
/// escape) for any failure — offline, timeout, rate-limited, or malformed
/// response.
abstract interface class GrammarCheckService {
  Future<GrammarCheckResult> check(String text, {required String localeCode});
}
