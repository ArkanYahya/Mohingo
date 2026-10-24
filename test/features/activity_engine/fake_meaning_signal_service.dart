import 'package:mohingo/content/models/evaluation_spec.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/meaning_signal_service.dart';

/// A [MeaningSignalService] that returns fixed signals, or `null` when built
/// with none — standing in for the on-device models, which have no runtime
/// to load under `flutter test`.
class FakeMeaningSignalService implements MeaningSignalService {
  FakeMeaningSignalService({this.signal, this.parts});

  /// What every [meaning] call returns; `null` means "no signal available".
  double? signal;

  /// What every [partMeanings] call returns, one entailment per meaning;
  /// `null` means "the inference model is unavailable". A list shorter than
  /// the meanings asked for is padded with zeros.
  List<double>? parts;

  /// Every `(answer, modelAnswers)` pair asked for, in order.
  final calls = <({String answer, List<String> modelAnswers})>[];

  /// Every `(answer, hypotheses)` pair asked for, in order.
  final partCalls = <({String answer, List<String> hypotheses})>[];

  @override
  Future<double?> meaning(
    String answer, {
    required List<String> modelAnswers,
  }) async {
    calls.add((answer: answer, modelAnswers: modelAnswers));
    if (modelAnswers.isEmpty) return null;
    return signal;
  }

  @override
  Future<List<double>?> partMeanings(
    String answer, {
    required List<GroupMeaning> meanings,
  }) async {
    partCalls.add((
      answer: answer,
      hypotheses: [for (final m in meanings) m.hypothesis],
    ));
    final p = parts;
    if (p == null || meanings.isEmpty) return null;
    return [
      for (var i = 0; i < meanings.length; i++) i < p.length ? p[i] : 0.0,
    ];
  }
}
