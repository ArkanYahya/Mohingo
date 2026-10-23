import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo_ai_pack_spike/benchmark_cases.dart';
import 'package:mohingo_ai_pack_spike/judge_prompt.dart';

void main() {
  test(
    'the user prompt carries task, parts and learner answer, no model answer',
    () {
      final c = kBenchmarkCases.first;
      final p = judgeUserPrompt(c);
      expect(p, contains(c.task));
      // Not shown since v4: run 3 copied it as the learner's "mistakes".
      expect(p, isNot(contains(c.modelAnswer)));
      expect(p, contains(c.answer));
      for (final part in c.parts) {
        expect(p, contains(part));
      }
      expect(judgeMessages(c, JudgeMode.full).length, 2);
    },
  );

  test('each schema fixes the part names and requires every field', () {
    final c = kBenchmarkCases.first;
    for (final mode in JudgeMode.values) {
      final schema = judgementSchema(mode, c.parts);
      final required = (schema['required'] as List).cast<String>();
      final props = (schema['properties'] as Map).keys.toList();
      expect(required.toSet(), props.toSet(), reason: mode.name);
      expect(
        props.contains('explanation_ar'),
        mode == JudgeMode.full,
        reason: mode.name,
      );
      final parts = schema['properties']['parts'] as Map<String, dynamic>;
      expect(parts['minItems'], c.parts.length);
      expect(parts['maxItems'], c.parts.length);
      final prefix = parts['prefixItems'] as List;
      for (var i = 0; i < c.parts.length; i++) {
        final item = prefix[i] as Map<String, dynamic>;
        expect(item['properties']['part']['const'], c.parts[i]);
      }
    }
    expect(judgeSystemPrompt(JudgeMode.fast), isNot(contains('Arabic script')));
    expect(judgeSystemPrompt(JudgeMode.full), contains('Arabic script'));
    // The worked example that contaminated run 2 is gone.
    expect(judgeSystemPrompt(JudgeMode.full), isNot(contains('Example')));
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
      expect(looksEnglish('I appreciate it.'), isTrue);
      expect(looksEnglish('اسمي عمر'), isFalse);
    },
  );

  test('SpikeJudgement computes the verdict from the parts and the script', () {
    const parts = ['the name', 'the job'];
    final j = SpikeJudgement.fromJson(
      {
        'parts': [
          {'part': 'the name', 'done': true},
          {'part': 'the job', 'done': true},
        ],
        'mistakes': [
          {'wrong': 'I am engineer', 'right': 'I am an engineer'},
          {'wrong': 'My name Omar', 'right': 'My name is Omar'},
        ],
        'corrected': 'My name is Omar. I am an engineer.',
        'explanation_en': 'Add is and an.',
        'explanation_ar': 'أضف الفعل is وأداة an.',
      },
      parts: parts,
      answer: 'My name Omar. I am engineer.',
    );
    expect(j.isEnglish, isTrue);
    expect(j.answersTask, isTrue);
    expect(j.grammarIssues, 2);
    expect(j.explanationArIsArabic, isTrue);

    final onePartMissing = SpikeJudgement.fromJson(
      {
        'parts': [
          {'part': 'the name', 'done': true},
          {'part': 'the job', 'done': false},
        ],
        'mistakes': [],
        'explanation_en': 'Say your job.',
      },
      parts: parts,
      answer: 'My name is Omar.',
    );
    expect(onePartMissing.answersTask, isFalse);
    expect(onePartMissing.grammarIssues, 0);

    // The model is never asked whether the answer is English: code decides.
    final arabic = SpikeJudgement.fromJson(
      {
        'parts': [
          {'part': 'the name', 'done': true},
          {'part': 'the job', 'done': true},
        ],
        'mistakes': [],
        'explanation_en': 'Good.',
        'explanation_ar': 'আমি',
      },
      parts: parts,
      answer: 'اسمي عمر وأعمل مهندساً.',
    );
    expect(arabic.isEnglish, isFalse);
    expect(arabic.answersTask, isFalse);
    expect(arabic.explanationArIsArabic, isFalse);
  });

  test('SpikeJudgement rejects a malformed parts list', () {
    expect(
      () => SpikeJudgement.fromJson(
        {'parts': 'yes', 'mistakes': []},
        parts: const ['a'],
        answer: 'x',
      ),
      throwsFormatException,
    );
    expect(
      () => SpikeJudgement.fromJson(
        {
          'parts': [
            {'part': 'a', 'done': 'true'},
          ],
          'mistakes': [],
        },
        parts: const ['a'],
        answer: 'x',
      ),
      throwsFormatException,
    );
  });
}
