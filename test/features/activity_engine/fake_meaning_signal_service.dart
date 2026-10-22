import 'package:mohingo/features/activity_engine/domain/evaluation/meaning_signal_service.dart';

/// A [MeaningSignalService] that returns a fixed signal, or `null` when
/// built with none — standing in for the on-device embedding model, which
/// has no runtime to load under `flutter test`.
class FakeMeaningSignalService implements MeaningSignalService {
  FakeMeaningSignalService({this.signal});

  /// What every call returns; `null` means "no signal available".
  double? signal;

  /// Every `(answer, modelAnswers)` pair asked for, in order.
  final calls = <({String answer, List<String> modelAnswers})>[];

  @override
  Future<double?> meaning(
    String answer, {
    required List<String> modelAnswers,
  }) async {
    calls.add((answer: answer, modelAnswers: modelAnswers));
    if (modelAnswers.isEmpty) return null;
    return signal;
  }
}
