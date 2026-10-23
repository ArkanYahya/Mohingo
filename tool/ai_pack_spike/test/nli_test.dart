import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo_ai_pack_spike/benchmark_cases.dart';
import 'package:mohingo_ai_pack_spike/nli/nli_report.dart';
import 'package:mohingo_ai_pack_spike/nli/nli_runner.dart';
import 'package:mohingo_ai_pack_spike/nli/wordpiece_tokenizer.dart';

void main() {
  test(
    'every case has one hypothesis per part, each a statement or a code check',
    () {
      for (final c in kBenchmarkCases) {
        expect(c.hypotheses.length, c.parts.length, reason: c.id);
        for (final h in c.hypotheses) {
          final code = sentencesRequired(h);
          if (code == null) {
            expect(h, endsWith('.'), reason: '${c.id}: $h');
            expect(h, isNot(startsWith('@')), reason: '${c.id}: $h');
          } else {
            expect(code, greaterThan(0));
          }
        }
      }
    },
  );

  test('sentence counting', () {
    expect(sentenceCount('I get up. I eat. Then I go to work.'), 3);
    expect(sentenceCount('Yes.'), 1);
    expect(sentenceCount('Hello! My name is Omar'), 2);
    expect(sentenceCount(''), 0);
    expect(sentencesRequired('@sentences:3'), 3);
    expect(sentencesRequired('The speaker says their name.'), isNull);
  });

  test('pair encoding is [CLS] a [SEP] b [SEP] with segment ids 0/1', () {
    final t = WordPieceTokenizer.fromVocab(
      [
        '[PAD]',
        '[UNK]',
        '[CLS]',
        '[SEP]',
        'i',
        'like',
        'tea',
        '.',
        'the',
        'speaker',
        'says',
      ].join('\n'),
    );
    final enc = t.encodePair('I like tea.', 'The speaker says.');
    expect(enc.ids, [2, 4, 5, 6, 7, 3, 8, 9, 10, 7, 3]);
    expect(enc.typeIds, [0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1]);
    final short = t.encodePair(
      'I like tea.',
      'The speaker says.',
      maxTokens: 8,
    );
    expect(short.ids.length, 8);
    expect(short.ids.first, 2);
    expect(short.ids.last, 3);
    // The premise is cut first; the hypothesis survives whole.
    expect(short.ids.sublist(short.ids.length - 5), [8, 9, 10, 7, 3]);
  });

  test('labels come from id2label in index order, lower-cased', () {
    expect(
      NliRunner.labelsFromConfig({
        'id2label': {'2': 'CONTRADICTION', '0': 'ENTAILMENT', '1': 'NEUTRAL'},
      }),
      ['entailment', 'neutral', 'contradiction'],
    );
    expect(() => NliRunner.labelsFromConfig({}), throwsFormatException);
  });

  test('softmax', () {
    final p = NliRunner.softmax([2.0, 1.0, 0.0]);
    expect(p.reduce((a, b) => a + b), closeTo(1, 1e-9));
    expect(p[0], greaterThan(p[1]));
    expect(p[1], greaterThan(p[2]));
  });

  test('a case answers the task only when English and every part entails', () {
    final yes = kBenchmarkCases.firstWhere((c) => c.expectAnswersTask);
    final arabic = kBenchmarkCases.firstWhere((c) => c.id == 'intro-arabic');
    const good = NliScore(
      entailment: 0.9,
      neutral: 0.05,
      contradiction: 0.05,
      ms: 40,
    );
    const bad = NliScore(
      entailment: 0.2,
      neutral: 0.7,
      contradiction: 0.1,
      ms: 40,
    );
    NliCaseResult result(BenchmarkCase c, List<NliScore> scores) =>
        NliCaseResult(
          benchmarkCase: c,
          checks: [
            for (var i = 0; i < c.parts.length; i++)
              PartCheck(
                part: c.parts[i],
                hypothesis: c.hypotheses[i],
                done: scores[i].entails,
                score: scores[i],
              ),
          ],
          wallMs: 100,
        );
    final allGood = result(yes, List.filled(yes.parts.length, good));
    expect(allGood.answersTask, isTrue);
    expect(allGood.verdictRight, isTrue);
    final oneBad = result(yes, [
      bad,
      ...List.filled(yes.parts.length - 1, good),
    ]);
    expect(oneBad.answersTask, isFalse);
    final arabicAllGood = result(
      arabic,
      List.filled(arabic.parts.length, good),
    );
    expect(arabicAllGood.isEnglish, isFalse);
    expect(arabicAllGood.answersTask, isFalse);
    expect(arabicAllGood.verdictRight, isTrue);

    final s = NliSummary.from([allGood, oneBad, arabicAllGood]);
    expect(s.completed, 3);
    expect(s.verdictsRight, 2);
    expect(s.medianPartMs, 40);
    final text = buildNliReport(
      deviceLine: 'd',
      modelLine: 'm',
      labelsLine: 'entailment/neutral/contradiction',
      inputsLine: 'input_ids,attention_mask',
      loadMs: 300,
      rssMbBeforeLoad: 100,
      rssMbAfterLoad: 160,
      results: [allGood, oneBad, arabicAllGood],
    );
    expect(text, contains('right 2/3'));
    expect(text, contains('## ${arabic.id}'));
  });
}
