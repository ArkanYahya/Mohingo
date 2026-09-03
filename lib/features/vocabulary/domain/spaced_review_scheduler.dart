/// The learner's self-reported recall quality for one review — a
/// simplified 3-button scale (Again/Good/Easy, the same shape most
/// mainstream spaced-repetition apps use) standing in for SM-2's original
/// 0-5 scale. See [SpacedReviewScheduler].
enum ReviewQuality {
  again,
  good,
  easy;

  /// The SM-2 quality score (0-5) this button maps to.
  int get sm2Score => switch (this) {
    ReviewQuality.again => 2,
    ReviewQuality.good => 4,
    ReviewQuality.easy => 5,
  };
}

/// The result of scheduling one review — what to persist to
/// `vocabulary_review_state`.
class SpacedReviewSchedule {
  const SpacedReviewSchedule({
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.dueAt,
  });

  final double easeFactor;
  final int intervalDays;
  final int repetitions;
  final DateTime dueAt;
}

/// A simplified SM-2 (SuperMemo-2) spaced-repetition scheduler.
///
/// Chosen because it's a well-known, simple, well-documented algorithm
/// (rather than a bespoke one) — see docs/ARCHITECTURE.md's Vocabulary
/// requirements ("a local spaced-review queue using a simple, documented
/// algorithm"). This is a *vocabulary-memory* schedule only — it never
/// grants or affects course/Can-Do mastery, which is tracked entirely
/// separately by `MasteryAggregationService`. See docs/DATA_MODEL.md.
///
/// Algorithm, given the learner's [ReviewQuality] and the item's current
/// `easeFactor`/`intervalDays`/`repetitions` (matching genuine SM-2, not a
/// weakened variant — the ease-factor update applies to *every* review,
/// passed or failed, exactly as SM-2 specifies):
/// - The ease factor is always nudged by the standard SM-2 formula
///   `EF' = EF + (0.1 - (5-q)*(0.08+(5-q)*0.02))`, floored at 1.3 (SM-2's
///   own floor, below which items would be reviewed too often to be
///   useful). With this scheme's 3-button mapping ([ReviewQuality.again]=2,
///   [ReviewQuality.good]=4, [ReviewQuality.easy]=5): Again *decreases* the
///   ease factor (delta -0.32), Good leaves it unchanged (delta 0), Easy
///   increases it (delta +0.1) — so an item that's repeatedly hard genuinely
///   gets a lower ease factor and is reviewed more often, not just reset.
/// - A "failed" recall (quality score < 3, i.e. [ReviewQuality.again]):
///   `repetitions` resets to 0 and the item is due again tomorrow,
///   regardless of the (now-lowered) ease factor.
/// - A "passed" recall ([ReviewQuality.good]/[ReviewQuality.easy]):
///   `repetitions` increments; the new interval is 1 day after the 1st
///   repetition, 6 days after the 2nd, and `previousInterval * easeFactor`
///   (rounded) after that.
abstract final class SpacedReviewScheduler {
  static const double _minimumEaseFactor = 1.3;

  static SpacedReviewSchedule schedule({
    required double currentEaseFactor,
    required int currentIntervalDays,
    required int currentRepetitions,
    required ReviewQuality quality,
    required DateTime now,
  }) {
    final score = quality.sm2Score;

    final delta = 0.1 - (5 - score) * (0.08 + (5 - score) * 0.02);
    final newEaseFactor = (currentEaseFactor + delta) < _minimumEaseFactor
        ? _minimumEaseFactor
        : currentEaseFactor + delta;

    if (score < 3) {
      return SpacedReviewSchedule(
        easeFactor: newEaseFactor,
        intervalDays: 1,
        repetitions: 0,
        dueAt: now.add(const Duration(days: 1)),
      );
    }

    final newRepetitions = currentRepetitions + 1;
    final int newIntervalDays;
    if (newRepetitions <= 1) {
      newIntervalDays = 1;
    } else if (newRepetitions == 2) {
      newIntervalDays = 6;
    } else {
      newIntervalDays = (currentIntervalDays * currentEaseFactor).round();
    }

    return SpacedReviewSchedule(
      easeFactor: newEaseFactor,
      intervalDays: newIntervalDays,
      repetitions: newRepetitions,
      dueAt: now.add(Duration(days: newIntervalDays)),
    );
  }
}
