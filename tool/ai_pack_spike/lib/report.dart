import 'benchmark_cases.dart';
import 'judge_prompt.dart';

/// What one benchmark case produced on the phone.
class CaseResult {
  const CaseResult({
    required this.benchmarkCase,
    required this.wallMs,
    this.judgement,
    this.error,
    this.promptTokens,
    this.generatedTokens,
    this.promptMs,
    this.generateMs,
    this.sampleMs,
    this.rssMbAfter,
  });

  final BenchmarkCase benchmarkCase;
  final SpikeJudgement? judgement;

  /// Set when the model gave no usable judgement (timeout, bad JSON, crash).
  final String? error;

  /// Wall-clock time of the whole call as the app would wait for it.
  final int wallMs;
  final int? promptTokens;
  final int? generatedTokens;
  final double? promptMs;
  final double? generateMs;

  /// Time llama.cpp spent choosing tokens: with a JSON-schema grammar this
  /// can rival generation itself, which is why it is reported apart.
  final double? sampleMs;
  final double? rssMbAfter;

  bool get ok => judgement != null;

  bool? get verdictRight => judgement == null
      ? null
      : judgement!.answersTask == benchmarkCase.expectAnswersTask;

  bool? get grammarRight => judgement == null
      ? null
      : (judgement!.grammarIssues > 0) == benchmarkCase.expectGrammarIssues;

  double? get tokensPerSecond {
    final t = generatedTokens;
    final ms = generateMs;
    if (t == null || ms == null || ms <= 0) return null;
    return t / (ms / 1000);
  }
}

/// The three numbers the spike exists to measure, plus judgement quality.
class BenchmarkSummary {
  BenchmarkSummary._({
    required this.total,
    required this.completed,
    required this.verdictsRight,
    required this.grammarRight,
    required this.arabicWritten,
    required this.medianWallMs,
    required this.maxWallMs,
    required this.meanTokensPerSecond,
    required this.peakRssMb,
    required this.meanPromptMs,
    required this.meanGenerateMs,
    required this.meanSampleMs,
  });

  factory BenchmarkSummary.from(List<CaseResult> results) {
    final done = results.where((r) => r.ok).toList();
    final walls = done.map((r) => r.wallMs).toList()..sort();
    final tps = done.map((r) => r.tokensPerSecond).whereType<double>().toList();
    final rss = results.map((r) => r.rssMbAfter).whereType<double>().toList();
    double? mean(Iterable<double?> xs) {
      final v = xs.whereType<double>().toList();
      return v.isEmpty ? null : v.reduce((a, b) => a + b) / v.length;
    }

    return BenchmarkSummary._(
      meanPromptMs: mean(done.map((r) => r.promptMs)),
      meanGenerateMs: mean(done.map((r) => r.generateMs)),
      meanSampleMs: mean(done.map((r) => r.sampleMs)),
      total: results.length,
      completed: done.length,
      verdictsRight: done.where((r) => r.verdictRight == true).length,
      grammarRight: done.where((r) => r.grammarRight == true).length,
      arabicWritten: done
          .where((r) => r.judgement!.explanationArIsArabic)
          .length,
      medianWallMs: walls.isEmpty ? null : walls[walls.length ~/ 2],
      maxWallMs: walls.isEmpty ? null : walls.last,
      meanTokensPerSecond: tps.isEmpty
          ? null
          : tps.reduce((a, b) => a + b) / tps.length,
      peakRssMb: rss.isEmpty ? null : rss.reduce((a, b) => a > b ? a : b),
    );
  }

  final int total;
  final int completed;
  final int verdictsRight;
  final int grammarRight;
  final int arabicWritten;
  final int? medianWallMs;
  final int? maxWallMs;
  final double? meanTokensPerSecond;
  final double? peakRssMb;
  final double? meanPromptMs;
  final double? meanGenerateMs;
  final double? meanSampleMs;

  /// ADR 0013's bar: "a judgement slower than a few seconds" degrades to the
  /// first layer. Five seconds at the median is the line the spike draws.
  bool get fastEnough => medianWallMs != null && medianWallMs! <= 5000;
}

/// Everything the owner pastes back from the phone.
String buildReport({
  required String deviceLine,
  required String modelLine,
  required String runtimeLine,
  required String settingsLine,
  required int? loadMs,
  required double? rssMbBeforeLoad,
  required double? rssMbAfterLoad,
  required List<CaseResult> results,
}) {
  final s = BenchmarkSummary.from(results);
  final b = StringBuffer()
    ..writeln('# Mohingo AI-pack spike report')
    ..writeln('device: $deviceLine')
    ..writeln('model: $modelLine')
    ..writeln('runtime: $runtimeLine')
    ..writeln('settings: $settingsLine')
    ..writeln(
      'load: ${loadMs ?? '-'} ms, rss before ${_mb(rssMbBeforeLoad)} -> '
      'after ${_mb(rssMbAfterLoad)}, peak during run ${_mb(s.peakRssMb)}',
    )
    ..writeln(
      'judgements: ${s.completed}/${s.total} completed, '
      'verdict right ${s.verdictsRight}/${s.completed}, '
      'grammar flag right ${s.grammarRight}/${s.completed}, '
      'Arabic written ${s.arabicWritten}/${s.completed}',
    )
    ..writeln(
      'speed: median ${s.medianWallMs ?? '-'} ms, max ${s.maxWallMs ?? '-'} ms, '
      '${s.meanTokensPerSecond?.toStringAsFixed(1) ?? '-'} tokens/s '
      '(${s.fastEnough ? 'fast enough' : 'too slow or incomplete'})',
    )
    ..writeln(
      'where the time goes (mean per answer): prompt '
      '${_ms(s.meanPromptMs)}, generation ${_ms(s.meanGenerateMs)}, '
      'sampling ${_ms(s.meanSampleMs)}',
    )
    ..writeln()
    ..writeln('id | expected | got | issues | ms | prompt/gen tokens | tests');
  for (final r in results) {
    final c = r.benchmarkCase;
    final j = r.judgement;
    final got = j == null ? 'ERR' : (j.answersTask ? 'yes' : 'no');
    final mark = r.verdictRight == null ? '?' : (r.verdictRight! ? 'ok' : 'X');
    b.writeln(
      '${c.id} | ${c.expectAnswersTask ? 'yes' : 'no'}'
      '${c.expectGrammarIssues ? '+err' : ''} | $got $mark | '
      '${j?.grammarIssues ?? '-'} | ${r.wallMs} | '
      '${r.promptTokens ?? '-'}/${r.generatedTokens ?? '-'} | '
      '${_ms(r.sampleMs)} | ${c.tests}',
    );
  }
  b.writeln();
  for (final r in results) {
    final c = r.benchmarkCase;
    b
      ..writeln('## ${c.id}')
      ..writeln('answer: ${c.answer}');
    final j = r.judgement;
    if (j == null) {
      b.writeln('error: ${r.error}');
    } else {
      b
        ..writeln(
          'english: ${j.isEnglish}; missing: ${j.missing}; '
          'verdict: ${j.answersTask}; issues: ${j.grammarIssues}',
        )
        ..writeln('en: ${j.explanationEn}');
      if (j.corrected.isNotEmpty) b.writeln('corrected: ${j.corrected}');
      if (j.explanationAr.isNotEmpty) {
        b.writeln(
          'ar (${dominantScript(j.explanationAr).name}): ${j.explanationAr}',
        );
      }
    }
    b.writeln();
  }
  return b.toString();
}

String _mb(double? v) => v == null ? '-' : '${v.toStringAsFixed(0)} MB';
String _ms(double? v) => v == null ? '-' : '${v.toStringAsFixed(0)} ms';
