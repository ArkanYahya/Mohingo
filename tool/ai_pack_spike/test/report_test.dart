import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo_ai_pack_spike/benchmark_cases.dart';
import 'package:mohingo_ai_pack_spike/judge_prompt.dart';
import 'package:mohingo_ai_pack_spike/report.dart';

SpikeJudgement _j(bool answers, int issues, {String ar = 'شرح جيد'}) =>
    SpikeJudgement(
      isEnglish: true,
      partsDone: {'a part': answers},
      mistakes: [
        for (var i = 0; i < issues; i++) Mistake(wrong: 'w$i', right: 'r$i'),
      ],
      corrected: 'c',
      explanationEn: 'e',
      explanationAr: ar,
    );

void main() {
  final yesClean = kBenchmarkCases.firstWhere(
    (c) => c.expectAnswersTask && !c.expectGrammarIssues,
  );
  final yesErrors = kBenchmarkCases.firstWhere((c) => c.expectGrammarIssues);
  final no = kBenchmarkCases.firstWhere((c) => !c.expectAnswersTask);

  test('summary counts right verdicts, grammar flags, speed and memory', () {
    final results = [
      CaseResult(
        benchmarkCase: yesClean,
        judgement: _j(true, 0),
        wallMs: 1200,
        generatedTokens: 60,
        generateMs: 3000,
        sampleMs: 500,
        rssMbAfter: 1500,
      ),
      CaseResult(
        benchmarkCase: yesErrors,
        judgement: _j(true, 0, ar: 'no arabic'),
        wallMs: 4000,
        generatedTokens: 60,
        generateMs: 2000,
        sampleMs: 1500,
        rssMbAfter: 1600,
      ),
      CaseResult(
        benchmarkCase: no,
        judgement: _j(true, 0),
        wallMs: 9000,
        rssMbAfter: 1550,
      ),
      CaseResult(benchmarkCase: no, wallMs: 120000, error: 'timeout'),
    ];
    final s = BenchmarkSummary.from(results);
    expect(s.total, 4);
    expect(s.completed, 3);
    expect(s.verdictsRight, 2); // yesClean, yesErrors; `no` judged yes
    expect(s.grammarRight, 2); // yesClean right, yesErrors missed, no right
    expect(s.arabicWritten, 2);
    expect(s.medianWallMs, 4000);
    expect(s.maxWallMs, 9000);
    expect(s.meanTokensPerSecond, closeTo(25, 0.01)); // (20 + 30) / 2
    expect(s.peakRssMb, 1600);
    expect(s.meanSampleMs, 1000);
    expect(s.meanGenerateMs, 2500);
    expect(s.fastEnough, isTrue);
  });

  test('an empty run is not fast enough and has no numbers', () {
    final s = BenchmarkSummary.from(const []);
    expect(s.medianWallMs, isNull);
    expect(s.fastEnough, isFalse);
  });

  test('the report names the device, the model and every case', () {
    final text = buildReport(
      deviceLine: 'android 14; RAM total 3800 MB',
      modelLine: 'Gemma 3 1B',
      runtimeLine: 'CPU',
      settingsLine: 'mode fast, threads 4',
      loadMs: 2500,
      rssMbBeforeLoad: 100,
      rssMbAfterLoad: 1000,
      results: [
        CaseResult(
          benchmarkCase: yesClean,
          judgement: _j(true, 0),
          wallMs: 1500,
        ),
        CaseResult(benchmarkCase: no, wallMs: 50, error: 'bad json'),
      ],
    );
    expect(text, contains('RAM total 3800 MB'));
    expect(text, contains('Gemma 3 1B'));
    expect(text, contains('load: 2500 ms'));
    expect(text, contains('settings: mode fast, threads 4'));
    expect(text, contains('where the time goes'));
    expect(text, contains('## ${yesClean.id}'));
    expect(text, contains('## ${no.id}'));
    expect(text, contains('error: bad json'));
    expect(text, contains('verdict right 1/1'));
  });
}
