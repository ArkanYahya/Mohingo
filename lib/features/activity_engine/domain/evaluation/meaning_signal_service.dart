import '../../../../content/models/evaluation_spec.dart';

/// The on-device meaning signal of ADR 0013's first layer, read two ways
/// since ADR 0014:
///
/// - [partMeanings]: for a task whose rubric groups carry [GroupMeaning]s,
///   how strongly the answer *entails* each group's statement, 0..1 per
///   group, from a natural-language-inference model. This is the signal
///   that reads an answer rather than measuring its wording.
/// - [meaning]: for a task without them, how close the answer is in meaning
///   to the task's model answers, 0 (nothing alike) to 1 (says the same
///   thing), from a sentence-embedding similarity. The fallback.
///
/// Deterministic for a given model file: the same inputs always give the
/// same values, which is what lets the level gates hold content to it.
/// Implementations never throw — anything that stops a signal being
/// computed (no model, a failed load, a runtime error) is reported as
/// `null`, and the rubric grades alone.
abstract interface class MeaningSignalService {
  /// `null` when no signal is available: no [modelAnswers], or the service
  /// cannot run on this device.
  Future<double?> meaning(String answer, {required List<String> modelAnswers});

  /// The entailment probability of [answer] for each of [meanings], in
  /// order; `null` when [meanings] is empty or the inference model cannot
  /// run on this device.
  Future<List<double>?> partMeanings(
    String answer, {
    required List<GroupMeaning> meanings,
  });
}

/// The binding for a build with no models — and the behaviour every
/// implementation falls back to when its models cannot load: no signal, the
/// rubric grades alone.
class UnavailableMeaningSignalService implements MeaningSignalService {
  const UnavailableMeaningSignalService();

  @override
  Future<double?> meaning(
    String answer, {
    required List<String> modelAnswers,
  }) async => null;

  @override
  Future<List<double>?> partMeanings(
    String answer, {
    required List<GroupMeaning> meanings,
  }) async => null;
}
