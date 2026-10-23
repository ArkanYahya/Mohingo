import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:llamadart/llamadart.dart';
import 'package:path_provider/path_provider.dart';

import 'benchmark_cases.dart';
import 'candidates.dart';
import 'judge_prompt.dart';
import 'report.dart';

/// Where the spike is in its download → load → run sequence.
enum SpikePhase { idle, downloading, loading, running }

/// Owns the engine, the download, the benchmark and the report. Plain
/// `ChangeNotifier`; the screen only renders it.
class SpikeController extends ChangeNotifier {
  SpikeController();

  static const Duration _judgementTimeout = Duration(seconds: 120);

  LlamaEngine? _engine;
  ModelDownloadManager? _manager;
  ModelDownloadController? _download;
  StreamSubscription<ModelDownloadTaskSnapshot>? _downloadSub;
  bool _disposed = false;

  SpikePhase phase = SpikePhase.idle;
  CandidateModel selected = kCandidates.first;
  String hfToken = '';
  final List<String> log = [];

  String deviceLine = 'reading…';
  double? totalRamMb;
  double? availableRamMb;

  /// Which candidates already have a file in the cache.
  final Set<String> downloaded = {};
  ModelDownloadTaskSnapshot? downloadSnapshot;

  String? loadedUri;
  String runtimeLine = '-';
  int? loadMs;
  double? rssMbBeforeLoad;
  double? rssMbAfterLoad;

  final List<CaseResult> results = [];
  int caseIndex = 0;

  /// The report of the current run, rebuilt after every answer so it can be
  /// copied while the run is still going, or after a crash cut it short.
  String? report;

  /// The report found on disk at start-up: the last run's, written after
  /// every answer, so a run the phone killed still leaves its numbers.
  String? savedReport;
  String? _reportPath;

  /// A plain text of the log, for pasting when there is no report.
  String get logText => log.reversed.join('\n');

  bool get busy => phase != SpikePhase.idle;
  bool get isLoaded => loadedUri != null && (_engine?.isReady ?? false);
  bool get selectedIsDownloaded => downloaded.contains(selected.uri);

  Future<void> init() async {
    _readMemInfo();
    try {
      final cacheDir = await getApplicationCacheDirectory();
      _manager = DefaultModelDownloadManager.auto(
        appPrivateCacheDirectory: cacheDir.path,
      );
      _engine = LlamaEngine(LlamaBackend(), modelDownloadManager: _manager);
      await _refreshDownloaded();
      final docs = await getApplicationDocumentsDirectory();
      _reportPath = '${docs.path}/spike_report.txt';
      final f = File(_reportPath!);
      if (f.existsSync()) {
        savedReport = f.readAsStringSync();
        _log('found the last saved report (${savedReport!.length} chars)');
      }
    } catch (e) {
      _log('init failed: $e');
    }
    _notify();
  }

  void select(CandidateModel c) {
    if (busy) return;
    selected = c;
    _notify();
  }

  void selectCustom(String uri) {
    if (busy || uri.trim().isEmpty) return;
    selected = customCandidate(uri);
    _notify();
  }

  void setToken(String t) => hfToken = t.trim();

  Future<void> download() async {
    final manager = _manager;
    if (busy || manager == null) return;
    phase = SpikePhase.downloading;
    _log('download ${selected.uri}');
    _notify();
    final controller = ModelDownloadController(manager: manager);
    _download = controller;
    _downloadSub = controller.snapshots.listen((s) {
      downloadSnapshot = s;
      _notify();
    });
    final sw = Stopwatch()..start();
    try {
      final entry = await controller.start(
        ModelSource.parse(selected.uri),
        options: ModelLoadOptions(
          bearerToken: hfToken.isEmpty ? null : hfToken,
        ),
      );
      _log(
        'downloaded ${entry.fileName} (${_mb(entry.bytes?.toDouble())}) in '
        '${sw.elapsed.inSeconds} s',
      );
      await _refreshDownloaded();
    } on LlamaException catch (e) {
      _log('download failed: ${e.message}');
    } catch (e) {
      _log('download failed: $e');
    } finally {
      await _downloadSub?.cancel();
      _downloadSub = null;
      await controller.dispose();
      _download = null;
      phase = SpikePhase.idle;
      _notify();
    }
  }

  void cancelDownload() => _download?.cancel();

  Future<void> deleteDownloaded() async {
    final manager = _manager;
    if (busy || manager == null) return;
    if (loadedUri == selected.uri) await unload();
    try {
      await manager.remove(ModelSource.parse(selected.uri).cacheKey);
      _log('deleted ${selected.name}');
    } catch (e) {
      _log('delete failed: $e');
    }
    await _refreshDownloaded();
    _notify();
  }

  Future<void> load() async {
    final engine = _engine;
    final manager = _manager;
    if (busy || engine == null || manager == null) return;
    phase = SpikePhase.loading;
    results.clear();
    report = null;
    runtimeLine = '-';
    _notify();
    try {
      final entry = await manager.get(ModelSource.parse(selected.uri).cacheKey);
      if (entry == null) {
        _log('not downloaded yet');
        return;
      }
      rssMbBeforeLoad = _rssMb();
      final sw = Stopwatch()..start();
      await engine.setModel(
        LlamaModel(ModelSource.path(entry.filePath)),
        // One answer at a time, a short prompt: 1024 tokens of context is
        // plenty and keeps memory down (phones: one model, small context).
        params: const ModelParams(contextSize: 1024, device: ComputeDevice.cpu),
      );
      sw.stop();
      loadMs = sw.elapsedMilliseconds;
      rssMbAfterLoad = _rssMb();
      loadedUri = selected.uri;
      runtimeLine =
          '${await engine.getBackendName()} / ${engine.runtime} / '
          'llamadart 0.16';
      _log(
        'loaded in $loadMs ms; rss ${_mb(rssMbBeforeLoad)} -> '
        '${_mb(rssMbAfterLoad)}',
      );
    } on LlamaException catch (e) {
      loadedUri = null;
      _log('load failed: ${e.message}');
    } catch (e) {
      loadedUri = null;
      _log('load failed: $e');
    } finally {
      phase = SpikePhase.idle;
      _notify();
    }
  }

  Future<void> unload() async {
    final engine = _engine;
    if (engine == null || !isLoaded) return;
    try {
      await engine.unloadModel();
    } catch (e) {
      _log('unload failed: $e');
    }
    loadedUri = null;
    _notify();
  }

  Future<void> runBenchmark() async {
    final engine = _engine;
    if (busy || engine == null || !isLoaded) return;
    phase = SpikePhase.running;
    results.clear();
    report = null;
    caseIndex = 0;
    _notify();
    final output = judgementOutput();
    final thinking = !selected.disableThinking;
    try {
      for (final c in kBenchmarkCases) {
        if (_disposed) return;
        caseIndex++;
        _notify();
        final sw = Stopwatch()..start();
        SpikeJudgement? judgement;
        String? error;
        try {
          judgement = await engine
              .createStructuredJson<SpikeJudgement>(
                judgeMessages(c),
                output: output,
                params: kJudgeGenerationParams,
                enableThinking: thinking,
              )
              .timeout(_judgementTimeout);
        } on TimeoutException {
          engine.cancelGeneration();
          error = 'timeout after ${_judgementTimeout.inSeconds} s';
        } on LlamaException catch (e) {
          error = e.message;
        } catch (e) {
          error = e.toString();
        }
        sw.stop();
        BackendPerfContextData? perf;
        try {
          perf = await engine.getPerformanceContext();
        } catch (_) {
          perf = null;
        }
        results.add(
          CaseResult(
            benchmarkCase: c,
            judgement: judgement,
            error: error,
            wallMs: sw.elapsedMilliseconds,
            promptTokens: perf?.promptEvalTokens,
            generatedTokens: perf?.evalTokens,
            promptMs: perf?.promptEvalMs,
            generateMs: perf?.evalMs,
            rssMbAfter: _rssMb(),
          ),
        );
        _log(
          '${c.id}: ${error ?? (judgement!.answersTask ? 'yes' : 'no')} '
          '(${sw.elapsedMilliseconds} ms)',
        );
        _rebuildReport(partial: caseIndex < kBenchmarkCases.length);
        _notify();
      }
    } finally {
      phase = SpikePhase.idle;
      _notify();
    }
  }

  void _rebuildReport({required bool partial}) {
    final text = buildReport(
      deviceLine: deviceLine,
      modelLine: '${selected.name} — ${selected.uri}',
      runtimeLine: runtimeLine,
      loadMs: loadMs,
      rssMbBeforeLoad: rssMbBeforeLoad,
      rssMbAfterLoad: rssMbAfterLoad,
      results: results,
    );
    report = partial
        ? '# PARTIAL: ${results.length} of ${kBenchmarkCases.length} answers '
              'judged so far\n$text'
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

  Future<void> _refreshDownloaded() async {
    final manager = _manager;
    if (manager == null) return;
    downloaded.clear();
    final uris = {...kCandidates.map((c) => c.uri), selected.uri};
    for (final uri in uris) {
      try {
        final entry = await manager.get(ModelSource.parse(uri).cacheKey);
        if (entry != null) downloaded.add(uri);
      } catch (_) {
        // An unparsable custom URI is simply not downloaded.
      }
    }
  }

  void _readMemInfo() {
    final rss = _rssMb();
    try {
      // Android is Linux: /proc/meminfo is readable by every process.
      final lines = File('/proc/meminfo').readAsLinesSync();
      double? kb(String key) {
        final line = lines.firstWhere(
          (l) => l.startsWith('$key:'),
          orElse: () => '',
        );
        final m = RegExp(r'(\d+)').firstMatch(line);
        return m == null ? null : double.parse(m.group(1)!) / 1024;
      }

      totalRamMb = kb('MemTotal');
      availableRamMb = kb('MemAvailable');
    } catch (_) {
      // iOS has no /proc; the RSS line still says what the app uses.
    }
    deviceLine =
        '${Platform.operatingSystem} ${Platform.operatingSystemVersion}; '
        'RAM total ${_mb(totalRamMb)}, available ${_mb(availableRamMb)}; '
        'app rss ${_mb(rss)}; ${Platform.numberOfProcessors} cores';
  }

  double? _rssMb() {
    try {
      return ProcessInfo.currentRss / (1024 * 1024);
    } catch (_) {
      return null;
    }
  }

  String _mb(double? v) => v == null ? '-' : '${v.toStringAsFixed(0)} MB';

  void _log(String line) {
    final t = DateTime.now().toIso8601String().substring(11, 19);
    log.insert(0, '$t $line');
    if (log.length > 200) log.removeLast();
    debugPrint('spike: $line');
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _download?.cancel();
    unawaited(_downloadSub?.cancel());
    _engine?.cancelGeneration();
    unawaited(_engine?.dispose());
    super.dispose();
  }
}
