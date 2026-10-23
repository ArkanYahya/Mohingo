import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import '../domain/evaluation/meaning_signal_service.dart';
import '../domain/evaluation/sentence_similarity.dart';
import '../domain/evaluation/wordpiece_tokenizer.dart';

/// The meaning signal computed on the device with the bundled MiniLM
/// sentence-embedding model through ONNX Runtime (ADR 0013, first layer).
///
/// The model and its vocabulary load lazily on the first call and stay
/// loaded. Anything that goes wrong — no runtime on this platform, a failed
/// load, a failed run — marks the service unavailable for the rest of the
/// session and returns `null`, so the rubric grades alone and nothing is
/// shown as an error. Model answers'
/// embeddings are cached, since the same few texts are compared again and
/// again.
class OnnxMeaningSignalService implements MeaningSignalService {
  OnnxMeaningSignalService({
    this.modelAsset = 'assets/models/all-MiniLM-L6-v2-int8.onnx',
    this.vocabAsset = 'assets/models/all-MiniLM-L6-v2-vocab.txt',
    this.lowSimilarity = kDefaultLowSimilarity,
    this.highSimilarity = kDefaultHighSimilarity,
    this.maxTokens = 256,
    this.cacheSize = 512,
  });

  final String modelAsset;
  final String vocabAsset;
  final double lowSimilarity;
  final double highSimilarity;
  final int maxTokens;
  final int cacheSize;

  OrtSession? _session;
  WordPieceTokenizer? _tokenizer;
  Future<void>? _loading;
  var _unavailable = false;
  final _cache = <String, Float32List>{};

  /// Whether the model is loaded and has not failed — for Settings or a
  /// diagnostic; grading never needs to ask.
  bool get isAvailable => _session != null && !_unavailable;

  @override
  Future<double?> meaning(
    String answer, {
    required List<String> modelAnswers,
  }) async {
    final references = modelAnswers
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toList();
    if (references.isEmpty || answer.trim().isEmpty) return null;
    if (!await _ensureLoaded()) return null;
    try {
      final a = await _embed(answer);
      if (a == null) return null;
      double? best;
      for (final reference in references) {
        final r = _cache[reference] ?? await _embed(reference);
        if (r == null) continue;
        _remember(reference, r);
        final similarity = cosine(a, r);
        if (best == null || similarity > best) best = similarity;
      }
      if (best == null) return null;
      return meaningFromCosine(best, low: lowSimilarity, high: highSimilarity);
    } catch (error, stackTrace) {
      _giveUp('meaning signal failed', error, stackTrace);
      return null;
    }
  }

  void _remember(String text, Float32List vector) {
    if (_cache.length >= cacheSize) _cache.remove(_cache.keys.first);
    _cache[text] = vector;
  }

  Future<bool> _ensureLoaded() async {
    if (_unavailable) return false;
    if (_session != null) return true;
    _loading ??= _load();
    await _loading;
    return _session != null && !_unavailable;
  }

  Future<void> _load() async {
    try {
      // The runtime first, the vocabulary second: on a platform with no
      // runtime the plugin fails with MissingPluginException before any
      // asset is read, so an unusable device never pays for the read.
      // (Under `flutter test` the provider binds the unavailable service
      // instead — a platform channel never answers inside a widget test's
      // fake clock, see docs/TESTING.md.)
      final runtime = OnnxRuntime();
      await runtime.getAvailableProviders();
      final session = await runtime.createSessionFromAsset(modelAsset);
      final vocab = await rootBundle.loadString(vocabAsset);
      _tokenizer = WordPieceTokenizer.fromVocab(vocab);
      _session = session;
    } catch (error, stackTrace) {
      _giveUp('meaning signal model unavailable', error, stackTrace);
    }
  }

  void _giveUp(String what, Object error, StackTrace stackTrace) {
    _unavailable = true;
    // The error alone: on a platform with no runtime (every `flutter test`)
    // this is expected, and a stack trace per test run is noise.
    debugPrint('$what: $error');
  }

  Future<Float32List?> _embed(String text) async {
    final session = _session;
    final tokenizer = _tokenizer;
    if (session == null || tokenizer == null) return null;
    final ids = tokenizer.encode(text, maxTokens: maxTokens);
    final n = ids.length;
    final shape = [1, n];
    final inputIds = await OrtValue.fromList(Int64List.fromList(ids), shape);
    final mask = await OrtValue.fromList(
      Int64List.fromList(List<int>.filled(n, 1)),
      shape,
    );
    final types = await OrtValue.fromList(
      Int64List.fromList(List<int>.filled(n, 0)),
      shape,
    );
    try {
      final byName = {
        'input_ids': inputIds,
        'attention_mask': mask,
        'token_type_ids': types,
      };
      final inputs = <String, OrtValue>{
        for (final name in session.inputNames)
          if (byName.containsKey(name)) name: byName[name]!,
      };
      final outputs = await session.run(inputs);
      try {
        final hidden = outputs.values.first;
        final flat = (await hidden.asFlattenedList()).cast<num>();
        return meanPoolNormalized(flat, tokens: n);
      } finally {
        for (final value in outputs.values) {
          await value.dispose();
        }
      }
    } finally {
      await inputIds.dispose();
      await mask.dispose();
      await types.dispose();
    }
  }

  /// Releases the model. The service may be used again afterwards: it
  /// reloads on the next call.
  Future<void> close() async {
    await _session?.close();
    _session = null;
    _loading = null;
    _cache.clear();
  }
}
