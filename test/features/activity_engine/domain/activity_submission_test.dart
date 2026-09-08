import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';

void main() {
  test('pendingOnlineRefinement defaults to false', () {
    const submission = ActivitySubmission(
      correctness: ActivityCorrectness.correct,
    );
    expect(submission.pendingOnlineRefinement, isFalse);
  });

  test('pendingOnlineRefinement can be set explicitly', () {
    const submission = ActivitySubmission(
      correctness: ActivityCorrectness.notAutoGraded,
      pendingOnlineRefinement: true,
    );
    expect(submission.pendingOnlineRefinement, isTrue);
  });
}
