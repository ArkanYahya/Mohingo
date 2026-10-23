import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../benchmark_cases.dart';
import 'nli_candidates.dart';
import 'nli_report.dart';
import 'nli_runner.dart';

enum NliPhase { idle, downloading, loading, running }

/// The second engine of the spike: a natural-language-inference
/// cross-encoder asked, per benchmark answer and per listed part, whether
/// the answer entails the part's statement. Nothing generative: one forward
/// pass per part, deterministic, a probability back.
class NliController extends ChangeNotifier {
  NliDownloader? _downloader;
  NliRunner? _runner;
  bool _disposed = false;

  NliPhase phase = NliPhase.idle;
  NliCandidate selected = kNliCandidates.first;
  final List<String> log = [];
  final Set<String> downloaded = {};
  String downloadLine = '';

  NliCandidate? loadedModel;
  int? loadMs;
  double? rssMbBeforeLoad;
  double? rssMbAfterLoad;

  final List<NliCaseResult> results = [];
  int caseIndex = 0;
  String? report;
  String? savedReport;
  String? _reportPath;

  /// The device line the main controller measured; set by the screen.
  String deviceLine = '';

  bool get busy => phase != NliPhase.idle;
  bool get isLoaded => _runner != null && loadedModel != null;
  bool get selectedIsDownloaded => downloaded.contains(selected.id);
  bool get selectedIsLoaded => isLoaded && loadedModel!.id == selected.id;
  String get logText => log.reversed.join('\n');

  Future<void> init() async {
    try {
      final cache = await getApplicationCacheDirectory();
      _downloader = NliDownloader(Directory('${cache.path}/nli'));
      _refreshDownloaded();
      final docs = await getApplicationDocumentsDirectory();
      _reportPath = '${docs.path}/nli_report.txt';
      final f = File(_reportPath!);
      if (f.existsSync()) savedReport = f.readAsStringSync();
    } catch (e) {
      _log('init failed: $e');
    }
    _notify();
  }

  void select(NliCandidate c) {
    if (busy) return;
    selected = c;
    _refreshDownloaded();
    _notify();
  }

  void selectCustom(String repo) {
    if (busy || repo.trim().isEmpty) return;
    select(customNliCandidate(repo));
  }

  Future<void> download() async {
    final d = _downloader;
    if (busy || d == null) return;
    phase = NliPhase.downloading;
    _log('download ${selected.repo}');
    _notify();
    final sw = Stopwatch()..start();
    try {
      await d.download(
        selected,
        onProgress: (file, received, total) {
          downloadLine =
              '$file: ${(received / 1048576).toStringAsFixed(1)}'
              '${total == null ? '' : ' / ${(total / 1048576).toStringAsFixed(1)}'} MB';
          _notify();
        },
      );
      _log('downloaded in ${sw.elapsed.inSeconds} s');
    } catch (e) {
      _log('download failed: $e');
    } finally {
      downloadLine = '';
      _refreshDownloaded();
      phase = NliPhase.idle;
      _notify();
    }
  }

  Future<void> deleteDownloaded() async {
    final d = _downloader;
    if (busy || d == null) return;
    if (selectedIsLoaded) await unload();
    await d.remove(selected);
    _refreshDownloaded();
    _log('deleted ${selected.name}');
    _notify();
  }

  Future<void> load() async {
    final d = _downloader;
    if (busy || d == null || !selectedIsDownloaded) return;
    phase = NliPhase.loading;
    results.clear();
    report = null;
    _notify();
    try {
      await _runner?.close();
      _runner = null;
      loadedModel = null;
      rssMbBeforeLoad = _rssMb();
      final sw = Stopwatch()..start();
      final runner = await NliRunner.load(d, selected);
      sw.stop();
      loadMs = sw.elapsedMilliseconds;
      rssMbAfterLoad = _rssMb();
      _runner = runner;
      loadedModel = selected;
      _log(
        'loaded in $loadMs ms; labels ${runner.labelsLine}; inputs '
        '${runner.inputNames.join(',')}',
      );
    } catch (e) {
      _log('load failed: $e');
    } finally {
      phase = NliPhase.idle;
      _notify();
    }
  }

  Future<void> unload() async {
    try {
      await _runner?.close();
    } catch (e) {
      _log('unload failed: $e');
    }
    _runner = null;
    loadedModel = null;
    _notify();
  }

  Future<void> run() async {
    final runner = _runner;
    if (busy || runner == null || !selectedIsLoaded) return;
    phase = NliPhase.running;
    results.clear();
    report = null;
    caseIndex = 0;
    _notify();
    try {
      for (final c in kBenchmarkCases) {
        if (_disposed) return;
        caseIndex++;
        _notify();
        final sw = Stopwatch()..start();
        final checks = <PartCheck>[];
        String? error;
        try {
          for (var i = 0; i < c.parts.length; i++) {
            final h = c.hypotheses[i];
            final needed = sentencesRequired(h);
            if (needed != null) {
              checks.add(
                PartCheck(
                  part: c.parts[i],
                  hypothesis: h,
                  done: sentenceCount(c.answer) >= needed,
                  byCode: true,
                ),
              );
              continue;
            }
            final score = await runner.score(c.answer, h);
            checks.add(
              PartCheck(
                part: c.parts[i],
                hypothesis: h,
                done: score.entails,
                score: score,
              ),
            );
          }
        } catch (e) {
          error = e.toString();
        }
        sw.stop();
        results.add(
          NliCaseResult(
            benchmarkCase: c,
            checks: checks,
            wallMs: sw.elapsedMilliseconds,
            error: error,
            rssMbAfter: _rssMb(),
          ),
        );
        _rebuildReport(partial: caseIndex < kBenchmarkCases.length);
        _notify();
      }
    } finally {
      phase = NliPhase.idle;
      _notify();
    }
  }

  void _rebuildReport({required bool partial}) {
    final m = loadedModel ?? selected;
    final text = buildNliReport(
      deviceLine: deviceLine,
      modelLine: '${m.name} — ${m.repo}',
      labelsLine: _runner?.labelsLine ?? '-',
      inputsLine: _runner?.inputNames.join(',') ?? '-',
      loadMs: loadMs,
      rssMbBeforeLoad: rssMbBeforeLoad,
      rssMbAfterLoad: rssMbAfterLoad,
      results: results,
    );
    report = partial
        ? '# PARTIAL: ${results.length} of ${kBenchmarkCases.length}\n$text'
        : text;
    final path = _reportPath;
    if (path != null) {
      try {
        File(path).writeAsStringSync(report!, flush: true);
      } catch (e) {
        _log('could not save the report: $e');
      }
    }
  }

  void _refreshDownloaded() {
    final d = _downloader;
    if (d == null) return;
    downloaded.clear();
    for (final c in [...kNliCandidates, selected]) {
      if (d.isDownloaded(c)) downloaded.add(c.id);
    }
  }

  double? _rssMb() {
    try {
      return ProcessInfo.currentRss / (1024 * 1024);
    } catch (_) {
      return null;
    }
  }

  void _log(String line) {
    final t = DateTime.now().toIso8601String().substring(11, 19);
    log.insert(0, '$t $line');
    if (log.length > 100) log.removeLast();
    debugPrint('nli: $line');
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _runner?.close();
    super.dispose();
  }
}
