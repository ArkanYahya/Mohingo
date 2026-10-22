/// The on-device meaning signal of ADR 0011's first layer: how close a free
/// answer is in meaning to a task's model answers, 0 (nothing alike) to 1
/// (says the same thing), computed entirely on the device.
///
/// Deterministic for a given model file: the same answer and the same
/// model answers always give the same value, which is what lets the level
/// gates hold content to it. Implementations never throw — anything that
/// stops the signal being computed (no model, a failed load, a runtime
/// error) is reported as `null`, and the rubric grades alone.
abstract interface class MeaningSignalService {
  /// `null` when no signal is available: no [modelAnswers], or the service
  /// cannot run on this device.
  Future<double?> meaning(String answer, {required List<String> modelAnswers});
}

/// The binding for a build with no embedding model — and the behaviour every
/// implementation falls back to when its model cannot load: no signal, the
/// rubric grades alone.
class UnavailableMeaningSignalService implements MeaningSignalService {
  const UnavailableMeaningSignalService();

  @override
  Future<double?> meaning(
    String answer, {
    required List<String> modelAnswers,
  }) async => null;
}
