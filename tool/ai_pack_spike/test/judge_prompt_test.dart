import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo_ai_pack_spike/benchmark_cases.dart';
import 'package:mohingo_ai_pack_spike/judge_prompt.dart';

void main() {
  test('the user prompt carries task, model answer and learner answer', () {
    final c = kBenchmarkCases.first;
    final p = judgeUserPrompt(c);
    expect(p, contains(c.task));
    expect(p, contains(c.modelAnswer));
    expect(p, contains(c.answer));
    final messages = judgeMessages(c);
    expect(messages.length, 2);
  });

  test('the schema requires every field the app would read', () {
    final required = (kJudgementSchema['required'] as List).cast<String>();
    final props = (kJudgementSchema['properties'] as Map).keys.toSet();
    expect(required.toSet(), props);
    expect(props, containsAll(['answers_task', 'grammar_issues']));
  });

  test('decoding is deterministic', () {
    expect(kJudgeGenerationParams.temp, 0.0);
    expect(kJudgeGenerationParams.topK, 1);
    expect(kJudgeGenerationParams.seed, isNotNull);
  });

  test('SpikeJudgement parses the JSON and spots Arabic', () {
    final j = SpikeJudgement.fromJson({
      'answers_task': true,
      'grammar_issues': 2,
      'corrected': 'I like swimming.',
      'explanation_en': 'Good. Use -ing after like.',
      'explanation_ar': 'جيد. استخدم -ing بعد like.',
    });
    expect(j.answersTask, isTrue);
    expect(j.grammarIssues, 2);
    expect(j.explanationArIsArabic, isTrue);

    final noArabic = SpikeJudgement.fromJson({
      'answers_task': false,
      'grammar_issues': -3,
      'corrected': '',
      'explanation_en': 'Off topic.',
      'explanation_ar': 'Off topic.',
    });
    expect(noArabic.grammarIssues, 0);
    expect(noArabic.explanationArIsArabic, isFalse);
  });

  test('SpikeJudgement rejects the wrong types', () {
    expect(
      () =>
          SpikeJudgement.fromJson({'answers_task': 'yes', 'grammar_issues': 0}),
      throwsFormatException,
    );
    expect(
      () => SpikeJudgement.fromJson({
        'answers_task': true,
        'grammar_issues': '0',
      }),
      throwsFormatException,
    );
  });
}
