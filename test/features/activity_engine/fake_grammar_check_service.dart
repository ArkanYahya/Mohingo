import 'package:mohingo/features/activity_engine/domain/evaluation/grammar_check_service.dart';

/// A fake [GrammarCheckService] with a test-controlled result or failure —
/// standing in for a real network call, which never runs in `flutter test`.
/// See docs/TESTING.md.
class FakeGrammarCheckService implements GrammarCheckService {
  FakeGrammarCheckService({this.result, this.failure, this.delay});

  /// Returned by [check] when set. Ignored if [failure] is also set.
  GrammarCheckResult? result;

  /// Thrown by [check] when set, taking priority over [result].
  GrammarCheckUnavailableException? failure;

  /// Held open for this long before answering — stands in for a real
  /// HTTP round trip (up to 10s against LanguageTool), which is what makes
  /// two drains able to overlap in the first place. `null` answers
  /// immediately.
  final Duration? delay;

  /// Every text [check] was called with, in order — the exact string the
  /// service would have sent over the wire.
  final List<String> checkedText = [];

  @override
  Future<GrammarCheckResult> check(
    String text, {
    required String localeCode,
  }) async {
    checkedText.add(text);
    if (delay != null) await Future<void>.delayed(delay!);
    if (failure != null) throw failure!;
    return result ?? const GrammarCheckResult(errorCount: 0, wordCount: 1);
  }
}
