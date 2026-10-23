import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo_ai_pack_spike/benchmark_cases.dart';

void main() {
  test('every case is complete and ids are unique', () {
    final ids = kBenchmarkCases.map((c) => c.id).toSet();
    expect(ids.length, kBenchmarkCases.length);
    for (final c in kBenchmarkCases) {
      expect(c.task.trim(), isNotEmpty, reason: c.id);
      expect(c.modelAnswer.trim(), isNotEmpty, reason: c.id);
      expect(c.answer.trim(), isNotEmpty, reason: c.id);
      expect(c.tests.trim(), isNotEmpty, reason: c.id);
    }
  });

  test('the set covers both verdicts and both grammar outcomes', () {
    expect(kBenchmarkCases.length, greaterThanOrEqualTo(20));
    expect(
      kBenchmarkCases.where((c) => c.expectAnswersTask).length,
      greaterThanOrEqualTo(8),
    );
    expect(
      kBenchmarkCases.where((c) => !c.expectAnswersTask).length,
      greaterThanOrEqualTo(8),
    );
    expect(
      kBenchmarkCases.where((c) => c.expectGrammarIssues).length,
      greaterThanOrEqualTo(4),
    );
  });

  test('a grammar-issue case is always one that answers the task', () {
    // Otherwise a wrong verdict and a wrong grammar flag would be confounded.
    for (final c in kBenchmarkCases.where((c) => c.expectGrammarIssues)) {
      expect(c.expectAnswersTask, isTrue, reason: c.id);
    }
  });
}
