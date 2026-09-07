/// The structured, data-driven replacement for the bundle's legacy opaque
/// `evaluation` rubric-name string. See docs/superpowers/specs/
/// 2026-09-07-offline-answer-evaluation-design.md.
sealed class EvaluationSpec {
  const EvaluationSpec();

  /// Parses a bundle activity's raw `evaluation` field. Returns `null` for
  /// anything not yet migrated to this shape (a plain legacy string), an
  /// absent field, or an unrecognized `type` — every call site treats a
  /// `null` spec exactly like today's un-evaluated activity, so a partially
  /// migrated bundle degrades gracefully rather than breaking.
  static EvaluationSpec? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return switch (json['type']) {
      'nonEmpty' => const NonEmptyEvaluationSpec(),
      'numericRange' => NumericRangeEvaluationSpec(
        min: (json['min'] as num).toDouble(),
        max: (json['max'] as num).toDouble(),
      ),
      'letterSequence' => LetterSequenceEvaluationSpec(
        reference: LetterSequenceReference.parse(json['reference'] as String),
      ),
      'keywordChecklist' => KeywordChecklistEvaluationSpec(
        requiredGroups: [
          for (final group in json['requiredGroups'] as List)
            List<String>.from(group as List),
        ],
        minGroupsMatched: json['minGroupsMatched'] as int,
      ),
      _ => null,
    };
  }
}

/// A trivial presence check — the answer just needs to be non-blank.
class NonEmptyEvaluationSpec extends EvaluationSpec {
  const NonEmptyEvaluationSpec();
}

/// Extracts a number from the answer and checks it falls within
/// `[min, max]` inclusive.
class NumericRangeEvaluationSpec extends EvaluationSpec {
  const NumericRangeEvaluationSpec({required this.min, required this.max});
  final double min;
  final double max;
}

/// What a [LetterSequenceEvaluationSpec] compares the spelled answer
/// against.
sealed class LetterSequenceReference {
  const LetterSequenceReference();

  static LetterSequenceReference parse(String value) {
    if (value == 'profileName') return const ProfileNameReference();
    if (value.startsWith('previousAnswer:')) {
      return PreviousAnswerReference(
        value.substring('previousAnswer:'.length),
      );
    }
    return LiteralReference(value);
  }
}

/// Compare against the learner's own persisted name (`Learners.name`).
class ProfileNameReference extends LetterSequenceReference {
  const ProfileNameReference();
}

/// Compare against the raw answer previously given to [activityId] earlier
/// in the same lesson (e.g. "How do you spell it?" after "What's your
/// name?").
class PreviousAnswerReference extends LetterSequenceReference {
  const PreviousAnswerReference(this.activityId);
  final String activityId;
}

/// Compare against a fixed string authored directly into the rubric.
class LiteralReference extends LetterSequenceReference {
  const LiteralReference(this.text);
  final String text;
}

/// Compares the spelled answer against [reference] using the same
/// letters-only normalization as [answersMatch]'s spelling case.
class LetterSequenceEvaluationSpec extends EvaluationSpec {
  const LetterSequenceEvaluationSpec({required this.reference});
  final LetterSequenceReference reference;
}

/// Short structured answers *and* open-ended paragraphs: the answer must
/// mention at least [minGroupsMatched] of [requiredGroups] (each group is a
/// list of acceptable surface forms — matching any one word/phrase in a
/// group counts as covering it).
class KeywordChecklistEvaluationSpec extends EvaluationSpec {
  const KeywordChecklistEvaluationSpec({
    required this.requiredGroups,
    required this.minGroupsMatched,
  });
  final List<List<String>> requiredGroups;
  final int minGroupsMatched;
}
