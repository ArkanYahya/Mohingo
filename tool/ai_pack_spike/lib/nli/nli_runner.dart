import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:http/http.dart' as http;

import 'nli_candidates.dart';
import 'wordpiece_tokenizer.dart';

/// Downloads the three files of an [NliCandidate] into [dir], reporting
/// bytes as they arrive. Hugging Face answers `resolve` URLs with a redirect
/// to its CDN, which the client follows.
class NliDownloader {
  NliDownloader(this.dir);

  final Directory dir;

  File fileFor(NliCandidate c, String name) =>
      File('${dir.path}/${c.id}/${name.replaceAll('/', '_')}');

  bool isDownloaded(NliCandidate c) =>
      fileFor(c, NliCandidate.vocabFile).existsSync() &&
      fileFor(c, NliCandidate.configFile).existsSync() &&
      (fileFor(c, NliCandidate.modelFile).existsSync() ||
          fileFor(c, NliCandidate.modelFallbackFile).existsSync());

  Future<void> remove(NliCandidate c) async {
    final d = Directory('${dir.path}/${c.id}');
    if (d.existsSync()) await d.delete(recursive: true);
  }

  Future<void> download(
    NliCandidate c, {
    required void Function(String file, int received, int? total) onProgress,
  }) async {
    final client = http.Client();
    try {
      await _fetch(client, c, NliCandidate.vocabFile, onProgress);
      await _fetch(client, c, NliCandidate.configFile, onProgress);
      try {
        await _fetch(client, c, NliCandidate.modelFile, onProgress);
      } on HttpException {
        await _fetch(client, c, NliCandidate.modelFallbackFile, onProgress);
      }
    } finally {
      client.close();
    }
  }

  Future<void> _fetch(
    http.Client client,
    NliCandidate c,
    String name,
    void Function(String file, int received, int? total) onProgress,
  ) async {
    final target = fileFor(c, name);
    if (target.existsSync() && target.lengthSync() > 0) return;
    final response = await client.send(http.Request('GET', c.url(name)));
    if (response.statusCode != 200) {
      throw HttpException(
        'HTTP ${response.statusCode} for ${c.url(name)}',
        uri: c.url(name),
      );
    }
    target.parent.createSync(recursive: true);
    final part = File('${target.path}.part');
    final sink = part.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress(name, received, response.contentLength);
      }
    } finally {
      await sink.close();
    }
    await part.rename(target.path);
  }
}

/// One NLI scoring: the three class probabilities and the time it took.
class NliScore {
  const NliScore({
    required this.entailment,
    required this.neutral,
    required this.contradiction,
    required this.ms,
  });

  final double entailment;
  final double neutral;
  final double contradiction;
  final int ms;

  /// The part counts as done when entailment is the most likely class.
  bool get entails => entailment >= neutral && entailment >= contradiction;
}

/// A loaded cross-encoder: tokenizes a (premise, hypothesis) pair and runs
/// the ONNX session, deterministic and on the CPU.
class NliRunner {
  NliRunner._(this._session, this._tokenizer, this._labels, this.inputNames);

  final OrtSession _session;
  final WordPieceTokenizer _tokenizer;

  /// Class index → lower-cased label from `config.json` (`id2label`).
  final List<String> _labels;
  final List<String> inputNames;

  static Future<NliRunner> load(NliDownloader d, NliCandidate c) async {
    final vocab = await d.fileFor(c, NliCandidate.vocabFile).readAsString();
    final config = jsonDecode(
      await d.fileFor(c, NliCandidate.configFile).readAsString(),
    ) as Map<String, dynamic>;
    final labels = labelsFromConfig(config);
    final modelFile = d.fileFor(c, NliCandidate.modelFile).existsSync()
        ? d.fileFor(c, NliCandidate.modelFile)
        : d.fileFor(c, NliCandidate.modelFallbackFile);
    final runtime = OnnxRuntime();
    await runtime.getAvailableProviders();
    final session = await runtime.createSession(modelFile.path);
    return NliRunner._(
      session,
      WordPieceTokenizer.fromVocab(vocab),
      labels,
      session.inputNames,
    );
  }

  /// `id2label` as an ordered, lower-cased list; MNLI models disagree on
  /// the order, so the label text decides, never a fixed index.
  static List<String> labelsFromConfig(Map<String, dynamic> config) {
    final raw = config['id2label'];
    if (raw is! Map || raw.isEmpty) {
      throw const FormatException('config.json has no id2label');
    }
    final entries = raw.entries.toList()
      ..sort((a, b) => int.parse('${a.key}').compareTo(int.parse('${b.key}')));
    return [for (final e in entries) '${e.value}'.toLowerCase()];
  }

  String get labelsLine => _labels.join('/');

  Future<NliScore> score(String premise, String hypothesis) async {
    final sw = Stopwatch()..start();
    final enc = _tokenizer.encodePair(premise, hypothesis, maxTokens: 256);
    final n = enc.ids.length;
    final shape = [1, n];
    final ids = await OrtValue.fromList(Int64List.fromList(enc.ids), shape);
    final mask = await OrtValue.fromList(
      Int64List.fromList(List<int>.filled(n, 1)),
      shape,
    );
    final types = await OrtValue.fromList(
      Int64List.fromList(enc.typeIds),
      shape,
    );
    try {
      final byName = {
        'input_ids': ids,
        'attention_mask': mask,
        'token_type_ids': types,
      };
      final inputs = <String, OrtValue>{
        for (final name in inputNames)
          if (byName.containsKey(name)) name: byName[name]!,
      };
      final outputs = await _session.run(inputs);
      try {
        final logits = (await outputs.values.first.asFlattenedList())
            .cast<num>()
            .map((v) => v.toDouble())
            .toList();
        final probs = softmax(logits);
        sw.stop();
        return NliScore(
          entailment: _prob(probs, 'entail'),
          neutral: _prob(probs, 'neutral'),
          contradiction: _prob(probs, 'contra'),
          ms: sw.elapsedMilliseconds,
        );
      } finally {
        for (final v in outputs.values) {
          await v.dispose();
        }
      }
    } finally {
      await ids.dispose();
      await mask.dispose();
      await types.dispose();
    }
  }

  double _prob(List<double> probs, String labelPrefix) {
    for (var i = 0; i < _labels.length && i < probs.length; i++) {
      if (_labels[i].startsWith(labelPrefix)) return probs[i];
    }
    return 0;
  }

  static List<double> softmax(List<double> logits) {
    if (logits.isEmpty) return const [];
    final m = logits.reduce(math.max);
    final exps = logits.map((v) => math.exp(v - m)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  Future<void> close() => _session.close();
}

/// The code check behind a `@sentences:N` hypothesis.
int sentenceCount(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  final terminated = RegExp(r'[^.!?]+[.!?]+').allMatches(trimmed).length;
  final tail = trimmed.replaceAll(RegExp(r'^.*[.!?]'), '').trim();
  return terminated + (tail.isEmpty ? 0 : 1);
}

/// Parses `@sentences:3` → 3, or null for a real hypothesis.
int? sentencesRequired(String hypothesis) {
  final m = RegExp(r'^@sentences:(\d+)$').firstMatch(hypothesis.trim());
  return m == null ? null : int.parse(m.group(1)!);
}
