import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import '../domain/evaluation/wordpiece_tokenizer.dart';

/// The bundled natural-language-inference cross-encoder behind the per-part
/// meaning signal (ADR 0014): given a learner's answer (the premise) and a
/// group's statement (the hypothesis), the probability that the answer
/// entails the statement.
///
/// The model is MobileBERT fine-tuned on MNLI, quantized to int8, under
/// `assets/models/nli/` with its vocabulary and its `config.json` (whose
/// `id2label` names the three classes — MNLI models disagree on the order,
/// so the label text decides, never a fixed index). Loaded lazily on the
/// first call and kept; a device without the runtime, or a build without
/// the files, reports `null` for every call after one failed load, and the
/// caller falls back. Deterministic: the same pair always gives the same
/// probability.
class OnnxEntailmentModel {
  OnnxEntailmentModel({
    this.modelAsset = 'assets/models/nli/model.onnx',
    this.vocabAsset = 'assets/models/nli/vocab.txt',
    this.configAsset = 'assets/models/nli/config.json',
    this.maxTokens = 256,
  });

  final String modelAsset;
  final String vocabAsset;
  final String configAsset;
  final int maxTokens;

  OrtSession? _session;
  WordPieceTokenizer? _tokenizer;
  List<String> _labels = const [];
  List<String> _inputNames = const [];
  Future<void>? _loading;
  bool _unavailable = false;

  /// Whether the model is loaded and answering. False before the first call
  /// and after a failed load.
  bool get isReady => _session != null && !_unavailable;

  /// The entailment probability, 0..1, or `null` when the model cannot run.
  Future<double?> entailment(String premise, String hypothesis) async {
    if (_unavailable) return null;
    await (_loading ??= _load());
    if (_unavailable) return null;
    try {
      return await _score(premise, hypothesis);
    } catch (error, stackTrace) {
      _giveUp('entailment model failed', error, stackTrace);
      return null;
    }
  }

  Future<void> _load() async {
    try {
      final runtime = OnnxRuntime();
      await runtime.getAvailableProviders();
      final config = jsonDecode(
        await rootBundle.loadString(configAsset),
      ) as Map<String, dynamic>;
      _labels = labelsFromConfig(config);
      final session = await runtime.createSessionFromAsset(modelAsset);
      final vocab = await rootBundle.loadString(vocabAsset);
      _tokenizer = WordPieceTokenizer.fromVocab(vocab);
      _inputNames = session.inputNames;
      _session = session;
    } catch (error, stackTrace) {
      _giveUp('entailment model unavailable', error, stackTrace);
    }
  }

  void _giveUp(String what, Object error, StackTrace stackTrace) {
    _unavailable = true;
    // The error alone: on a platform with no runtime (every `flutter test`)
    // and in a build without the model files this is expected.
    debugPrint('$what: $error');
  }

  /// `id2label` as an ordered, lower-cased list.
  static List<String> labelsFromConfig(Map<String, dynamic> config) {
    final raw = config['id2label'];
    if (raw is! Map || raw.isEmpty) {
      throw const FormatException('config.json has no id2label');
    }
    final entries = raw.entries.toList()
      ..sort((a, b) => int.parse('${a.key}').compareTo(int.parse('${b.key}')));
    return [for (final e in entries) '${e.value}'.toLowerCase()];
  }

  Future<double?> _score(String premise, String hypothesis) async {
    final session = _session;
    final tokenizer = _tokenizer;
    if (session == null || tokenizer == null) return null;
    final enc = tokenizer.encodePair(premise, hypothesis, maxTokens: maxTokens);
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
        for (final name in _inputNames)
          if (byName.containsKey(name)) name: byName[name]!,
      };
      final outputs = await session.run(inputs);
      try {
        final logits = (await outputs.values.first.asFlattenedList())
            .cast<num>()
            .map((v) => v.toDouble())
            .toList();
        return entailmentOf(softmax(logits), _labels);
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

  /// The probability of the class whose label starts with "entail", or 0
  /// when the labels name no such class.
  static double entailmentOf(List<double> probabilities, List<String> labels) {
    for (var i = 0; i < labels.length && i < probabilities.length; i++) {
      if (labels[i].startsWith('entail')) return probabilities[i];
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

  /// Releases the model. It reloads on the next call.
  Future<void> close() async {
    await _session?.close();
    _session = null;
    _loading = null;
  }
}
