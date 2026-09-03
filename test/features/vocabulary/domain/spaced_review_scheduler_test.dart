import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/vocabulary/domain/spaced_review_scheduler.dart';

void main() {
  final now = DateTime.utc(2026, 9, 2);

  group('a failed recall (ReviewQuality.again)', () {
    test('resets repetitions to 0 and schedules for tomorrow', () {
      final result = SpacedReviewScheduler.schedule(
        currentEaseFactor: 2.5,
        currentIntervalDays: 6,
        currentRepetitions: 3,
        quality: ReviewQuality.again,
        now: now,
      );

      expect(result.repetitions, 0);
      expect(result.intervalDays, 1);
      expect(result.dueAt, now.add(const Duration(days: 1)));
    });

    test('decreases the ease factor — a genuinely harder item is reviewed '
        'more often going forward, not just reset once', () {
      final result = SpacedReviewScheduler.schedule(
        currentEaseFactor: 2.6,
        currentIntervalDays: 6,
        currentRepetitions: 3,
        quality: ReviewQuality.again,
        now: now,
      );

      expect(result.easeFactor, closeTo(2.28, 0.001)); // 2.6 - 0.32
    });

    test('the ease factor never drops below the 1.3 floor', () {
      var easeFactor = 1.4;
      for (var i = 0; i < 3; i++) {
        final result = SpacedReviewScheduler.schedule(
          currentEaseFactor: easeFactor,
          currentIntervalDays: 1,
          currentRepetitions: 1,
          quality: ReviewQuality.again,
          now: now,
        );
        easeFactor = result.easeFactor;
        expect(easeFactor, greaterThanOrEqualTo(1.3));
      }
      expect(easeFactor, 1.3);
    });
  });

  group('a passed recall (Good/Easy)', () {
    test('the first repetition schedules 1 day out', () {
      final result = SpacedReviewScheduler.schedule(
        currentEaseFactor: 2.5,
        currentIntervalDays: 0,
        currentRepetitions: 0,
        quality: ReviewQuality.good,
        now: now,
      );

      expect(result.repetitions, 1);
      expect(result.intervalDays, 1);
    });

    test('the second repetition schedules 6 days out', () {
      final result = SpacedReviewScheduler.schedule(
        currentEaseFactor: 2.5,
        currentIntervalDays: 1,
        currentRepetitions: 1,
        quality: ReviewQuality.good,
        now: now,
      );

      expect(result.repetitions, 2);
      expect(result.intervalDays, 6);
    });

    test('the third+ repetition multiplies the previous interval by the '
        'ease factor', () {
      final result = SpacedReviewScheduler.schedule(
        currentEaseFactor: 2.5,
        currentIntervalDays: 6,
        currentRepetitions: 2,
        quality: ReviewQuality.good,
        now: now,
      );

      expect(result.repetitions, 3);
      expect(result.intervalDays, 15); // round(6 * 2.5)
    });

    test('dueAt is now + the new interval', () {
      final result = SpacedReviewScheduler.schedule(
        currentEaseFactor: 2.5,
        currentIntervalDays: 6,
        currentRepetitions: 2,
        quality: ReviewQuality.good,
        now: now,
      );

      expect(result.dueAt, now.add(Duration(days: result.intervalDays)));
    });

    test('Easy raises the ease factor more than Good', () {
      final good = SpacedReviewScheduler.schedule(
        currentEaseFactor: 2.5,
        currentIntervalDays: 6,
        currentRepetitions: 2,
        quality: ReviewQuality.good,
        now: now,
      );
      final easy = SpacedReviewScheduler.schedule(
        currentEaseFactor: 2.5,
        currentIntervalDays: 6,
        currentRepetitions: 2,
        quality: ReviewQuality.easy,
        now: now,
      );

      expect(easy.easeFactor, greaterThan(good.easeFactor));
    });

    test('Good leaves the ease factor unchanged (delta is exactly 0 for '
        "this scheme's quality mapping)", () {
      final result = SpacedReviewScheduler.schedule(
        currentEaseFactor: 2.5,
        currentIntervalDays: 6,
        currentRepetitions: 2,
        quality: ReviewQuality.good,
        now: now,
      );

      expect(result.easeFactor, 2.5);
    });
  });
}
