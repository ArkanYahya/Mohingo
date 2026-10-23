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
    final messages = judgeMessages(c, JudgeMode.full);
    expect(messages.length, 2);
  });

  test('each schema requires every field it declares, checks first', () {
    for (final mode in JudgeMode.values) {
      final schema = judgementSchema(mode);
      final required = (schema['required'] as List).cast<String>();
      final props = (schema['properties'] as Map).keys.toList();
      expect(required.toSet(), props.toSet(), reason: mode.name);
      expect(props.indexOf('missing'), lessThan(props.indexOf('answers_task')));
      expect(
        props.contains('explanation_ar'),
        mode == JudgeMode.full,
        reason: mode.name,
      );
    }
    expect(judgeSystemPrompt(JudgeMode.fast), isNot(contains('Arabic script')));
    expect(judgeSystemPrompt(JudgeMode.full), contains('Arabic script'));
  });

  test('decoding is deterministic and fast mode is shorter', () {
    for (final mode in JudgeMode.values) {
      final p = judgeGenerationParams(mode);
      expect(p.temp, 0.0);
      expect(p.topK, 1);
      expect(p.seed, isNotNull);
    }
    expect(
      judgeGenerationParams(JudgeMode.fast).maxTokens,
      lessThan(judgeGenerationParams(JudgeMode.full).maxTokens),
    );
  });

  test(
    'dominantScript tells Arabic from the scripts a 1B model drifts into',
    () {
      expect(dominantScript('اسمي عمر وأنا من العراق.'), Script.arabic);
      expect(
        dominantScript('খুব ভালো। আপনি কি শিশুদেরকে সাহায্য করেন?'),
        Script.bengali,
      );
      expect(dominantScript('谢谢你。 / 谢谢。'), Script.cjk);
      expect(dominantScript('Off topic.'), Script.latin);
      expect(dominantScript(''), Script.none);
      // One Arabic word in a Bengali sentence is not Arabic.
      expect(
        dominantScript('خیرا! এটা খুব ভালো। আপনি কি শিশুদেরকে সাহায্য করেন?'),
        isNot(Script.arabic),
      );
    },
  );

  test('SpikeJudgement parses the JSON and spots Arabic', () {
    final j = SpikeJudgement.fromJson({
      'is_english': true,
      'missing': 'nothing',
      'answers_task': true,
      'grammar_issues': 2,
      'corrected': 'I like swimming.',
      'explanation_en': 'Good. Use -ing after like.',
      'explanation_ar': 'جيد. استخدم -ing بعد like.',
    });
    expect(j.answersTask, isTrue);
    expect(j.isEnglish, isTrue);
    expect(j.missing, 'nothing');
    expect(j.grammarIssues, 2);
    expect(j.explanationArIsArabic, isTrue);

    final noArabic = SpikeJudgement.fromJson({
      'answers_task': false,
      'grammar_issues': -3,
      'corrected': '',
      'explanation_en': 'Off topic.',
      'explanation_ar': 'আমি ফুটবল ভালোবাসি।',
    });
    expect(noArabic.grammarIssues, 0);
    expect(noArabic.isEnglish, isTrue); // absent in fast mode: assumed
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
