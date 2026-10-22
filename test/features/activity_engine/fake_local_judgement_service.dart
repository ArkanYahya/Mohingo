import 'package:mohingo/features/activity_engine/domain/evaluation/local_judgement_service.dart';

/// A [LocalJudgementService] with a canned judgement, a canned failure, or
/// no pack at all — the AI pack never runs under `flutter test`.
class FakeLocalJudgementService implements LocalJudgementService {
  FakeLocalJudgementService({
    this.available = false,
    this.judgement,
    this.failWith,
  });

  bool available;

  /// Returned by every [judge] call when set.
  LocalJudgement? judgement;

  /// Thrown by every [judge] call when set (takes precedence over
  /// [judgement]).
  LocalJudgementUnavailableException? failWith;

  /// Every answer judged, in order.
  final judgedAnswers = <String>[];

  @override
  Future<bool> get isAvailable async => available;

  @override
  Future<LocalJudgement> judge({
    required JudgementTask task,
    required String answer,
  }) async {
    judgedAnswers.add(answer);
    final failure = failWith;
    if (failure != null) throw failure;
    final result = judgement;
    if (result == null) {
      throw const LocalJudgementUnavailableException('no canned judgement');
    }
    return result;
  }
}
