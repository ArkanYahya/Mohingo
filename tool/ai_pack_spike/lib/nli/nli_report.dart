import '../benchmark_cases.dart';
import '../judge_prompt.dart' show looksEnglish;
import 'nli_runner.dart';

/// One part's check: the NLI score, or the code check for a count.
class PartCheck {
  const PartCheck({
    required this.part,
    required this.hypothesis,
    required this.done,
    this.score,
    this.byCode = false,
  });

  final String part;
  final String hypothesis;
  final bool done;
  final NliScore? score;
  final bool byCode;
}

/// What the NLI engine said about one benchmark answer.
class NliCaseResult {
  const NliCaseResult({
    required this.benchmarkCase,
    required this.checks,
    required this.wallMs,
    this.error,
    this.rssMbAfter,
  });

  final BenchmarkCase benchmarkCase;
  final List<PartCheck> checks;

  /// The whole answer's time: every part scored, one after the other.
  final int wallMs;
  final String? error;
  final double? rssMbAfter;

  bool get ok => error == null;
  bool get isEnglish => looksEnglish(benchmarkCase.answer);

  /// English (by script) and every part done.
  bool get answersTask => isEnglish && checks.every((c) => c.done);

  bool? get verdictRight =>
      ok ? answersTask == benchmarkCase.expectAnswersTask : null;
}

class NliSummary {
  NliSummary._({
    required this.total,
    required this.completed,
    required this.verdictsRight,
    required this.medianWallMs,
    required this.maxWallMs,
    required this.medianPartMs,
    required this.peakRssMb,
  });

  factory NliSummary.from(List<NliCaseResult> results) {
    final done = results.where((r) => r.ok).toList();
    final walls = done.map((r) => r.wallMs).toList()..sort();
    final parts = [
      for (final r in done)
        for (final c in r.checks)
          if (c.score != null) c.score!.ms,
    ]..sort();
    final rss = results.map((r) => r.rssMbAfter).whereType<double>().toList();
    return NliSummary._(
      total: results.length,
      completed: done.length,
      verdictsRight: done.where((r) => r.verdictRight == true).length,
      medianWallMs: walls.isEmpty ? null : walls[walls.length ~/ 2],
      maxWallMs: walls.isEmpty ? null : walls.last,
      medianPartMs: parts.isEmpty ? null : parts[parts.length ~/ 2],
      peakRssMb: rss.isEmpty ? null : rss.reduce((a, b) => a > b ? a : b),
    );
  }

  final int total;
  final int completed;
  final int verdictsRight;
  final int? medianWallMs;
  final int? maxWallMs;
  final int? medianPartMs;
  final double? peakRssMb;
}

String buildNliReport({
  required String deviceLine,
  required String modelLine,
  required String labelsLine,
  required String inputsLine,
  required int? loadMs,
  required double? rssMbBeforeLoad,
  required double? rssMbAfterLoad,
  required List<NliCaseResult> results,
}) {
  final s = NliSummary.from(results);
  final b = StringBuffer()
    ..writeln('# Mohingo AI-pack spike report — NLI engine')
    ..writeln('device: $deviceLine')
    ..writeln('model: $modelLine')
    ..writeln('labels: $labelsLine; inputs: $inputsLine')
    ..writeln(
      'load: ${loadMs ?? '-'} ms, rss before ${_mb(rssMbBeforeLoad)} -> '
      'after ${_mb(rssMbAfterLoad)}, peak during run ${_mb(s.peakRssMb)}',
    )
    ..writeln(
      'verdicts: ${s.completed}/${s.total} completed, '
      'right ${s.verdictsRight}/${s.completed}',
    )
    ..writeln(
      'speed: median ${s.medianWallMs ?? '-'} ms per answer (all parts), '
      'max ${s.maxWallMs ?? '-'} ms, median ${s.medianPartMs ?? '-'} ms per '
      'part',
    )
    ..writeln()
    ..writeln('id | expected | got | ms | parts (entailment p) | tests');
  for (final r in results) {
    final c = r.benchmarkCase;
    final got = r.ok ? (r.answersTask ? 'yes' : 'no') : 'ERR';
    final mark = r.verdictRight == null ? '?' : (r.verdictRight! ? 'ok' : 'X');
    final parts = r.checks
        .map(
          (k) => k.byCode
              ? '${k.done ? 'T' : 'F'}(code)'
              : '${k.done ? 'T' : 'F'}(${k.score!.entailment.toStringAsFixed(2)})',
        )
        .join(' ');
    b.writeln(
      '${c.id} | ${c.expectAnswersTask ? 'yes' : 'no'} | $got $mark | '
      '${r.wallMs} | $parts | ${c.tests}',
    );
  }
  b.writeln();
  for (final r in results) {
    final c = r.benchmarkCase;
    b
      ..writeln('## ${c.id}')
      ..writeln('answer: ${c.answer}');
    if (!r.ok) {
      b.writeln('error: ${r.error}');
    } else {
      b.writeln('english (code): ${r.isEnglish}');
      for (final k in r.checks) {
        if (k.byCode) {
          b.writeln('- ${k.hypothesis} -> ${k.done} (code)');
        } else {
          final sc = k.score!;
          b.writeln(
            '- "${k.hypothesis}" -> ${k.done ? 'done' : 'not done'} '
            '(entail ${sc.entailment.toStringAsFixed(2)}, neutral '
            '${sc.neutral.toStringAsFixed(2)}, contradiction '
            '${sc.contradiction.toStringAsFixed(2)}, ${sc.ms} ms)',
          );
        }
      }
    }
    b.writeln();
  }
  return b.toString();
}

String _mb(double? v) => v == null ? '-' : '${v.toStringAsFixed(0)} MB';
