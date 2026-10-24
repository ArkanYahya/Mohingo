/// The structured, data-driven replacement for the bundle's legacy opaque
/// `evaluation` rubric-name string.
///
/// Pure bundle-shaped data — parsed straight from the course JSON alongside
/// the rest of an `Activity`, with no Flutter/Riverpod/behaviour deps —
/// so it lives in the foundational `lib/content/` layer, never importing
/// from `lib/features/`. The *grading* of a spec (and the runtime state it
/// needs) is a feature concern and stays in
/// `lib/features/activity_engine/domain/evaluation/`. See
/// docs/ARCHITECTURE.md and docs/superpowers/specs/
/// 2026-09-07-offline-answer-evaluation-design.md.
sealed class EvaluationSpec {
  const EvaluationSpec();

  /// Parses a bundle activity's raw `evaluation` field. Returns `null` for
  /// anything not yet migrated to this shape (a plain legacy string), an
  /// absent field, an unrecognized `type`, **or** a recognized `type` whose
  /// required fields are missing or the wrong shape (an authoring error) —
  /// every call site treats a `null` spec exactly like today's un-evaluated
  /// activity, so a partially migrated *or* mis-authored bundle degrades to
  /// one un-auto-graded activity rather than throwing out of
  /// `CourseBundleParser` and blanking the whole course.
  static EvaluationSpec? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return switch (json['type']) {
      'nonEmpty' => const NonEmptyEvaluationSpec(),
      'numericRange' => _numericRangeFromJson(json),
      'letterSequence' => _letterSequenceFromJson(json),
      'keywordChecklist' => _keywordChecklistFromJson(json),
      _ => null,
    };
  }

  static EvaluationSpec? _numericRangeFromJson(Map<String, dynamic> json) {
    final min = json['min'];
    final max = json['max'];
    if (min is! num || max is! num) return null;
    return NumericRangeEvaluationSpec(min: min.toDouble(), max: max.toDouble());
  }

  static EvaluationSpec? _letterSequenceFromJson(Map<String, dynamic> json) {
    final reference = json['reference'];
    if (reference is! String) return null;
    return LetterSequenceEvaluationSpec(
      reference: LetterSequenceReference.parse(reference),
    );
  }

  static EvaluationSpec? _keywordChecklistFromJson(Map<String, dynamic> json) {
    final rawGroups = json['requiredGroups'];
    final minGroupsMatched = json['minGroupsMatched'];
    if (rawGroups is! List || minGroupsMatched is! int) return null;
    final requiredGroups = <List<String>>[];
    for (final group in rawGroups) {
      if (group is! List) return null;
      final keywords = <String>[];
      for (final keyword in group) {
        if (keyword is! String) return null;
        keywords.add(keyword);
      }
      requiredGroups.add(keywords);
    }
    final onlineRefinement = json['onlineRefinement'];
    return KeywordChecklistEvaluationSpec(
      requiredGroups: requiredGroups,
      minGroupsMatched: minGroupsMatched,
      onlineRefinement: onlineRefinement is String ? onlineRefinement : null,
      meanings: _meaningsFromJson(json['meanings'], requiredGroups.length),
    );
  }

  /// One [GroupMeaning] per required group, or `null` when the task has
  /// none yet or they are mis-authored (wrong count, a missing field): the
  /// rubric then grades as it always has and the meaning signal falls back
  /// to the model answers. Never a reason to drop the whole spec.
  static List<GroupMeaning>? _meaningsFromJson(Object? raw, int groupCount) {
    if (raw is! List || raw.length != groupCount) return null;
    final meanings = <GroupMeaning>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) return null;
      final says = item['says'];
      final en = item['en'];
      final ar = item['ar'];
      if (says is! String || en is! String || ar is! String) return null;
      if (says.trim().isEmpty || en.trim().isEmpty || ar.trim().isEmpty) {
        return null;
      }
      meanings.add(GroupMeaning(hypothesis: says, labelEn: en, labelAr: ar));
    }
    return meanings;
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
      return PreviousAnswerReference(value.substring('previousAnswer:'.length));
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
/// letters-only normalization as `answersMatch`'s spelling case (see
/// lib/features/activity_engine/domain/answer_matching.dart).
class LetterSequenceEvaluationSpec extends EvaluationSpec {
  const LetterSequenceEvaluationSpec({required this.reference});
  final LetterSequenceReference reference;
}

/// Short structured answers *and* open-ended paragraphs: the answer must
/// mention at least [minGroupsMatched] of [requiredGroups] (each group is a
/// list of acceptable surface forms — matching any one word/phrase in a
/// group counts as covering it). [onlineRefinement] marks a rubric as
/// eligible for a deferred, free-tier online grammar-quality pass (see
/// docs/superpowers/specs/2026-09-07-offline-answer-evaluation-design.md's
/// Tier 2) — `null` for every structured/short-answer rubric, which never
/// touches the network.
class KeywordChecklistEvaluationSpec extends EvaluationSpec {
  const KeywordChecklistEvaluationSpec({
    required this.requiredGroups,
    required this.minGroupsMatched,
    this.onlineRefinement,
    this.meanings,
  });
  final List<List<String>> requiredGroups;
  final int minGroupsMatched;
  final String? onlineRefinement;

  /// What each group *means*, one per group in order (ADR 0014): the
  /// statement the on-device inference model checks the answer against,
  /// and the part's name for the learner in both languages. `null` for a
  /// task not yet authored this way.
  final List<GroupMeaning>? meanings;

  bool get hasMeanings =>
      meanings != null && meanings!.length == requiredGroups.length;
}

/// The meaning of one keyword group, for a reader of answers rather than a
/// matcher of words (ADR 0014). [hypothesis] is a plain English statement
/// of what an answer that meets the group says — "The speaker says one
/// thing they do not like." — and must describe the answer's own content,
/// never the task's situation. [labelEn] and [labelAr] name the part for
/// the learner ("one thing you don't like" / "شيئاً لا تحبّه"), written
/// natively in each language, and are what the feedback panel lists as
/// missing.
class GroupMeaning {
  const GroupMeaning({
    required this.hypothesis,
    required this.labelEn,
    required this.labelAr,
  });

  final String hypothesis;
  final String labelEn;
  final String labelAr;
}
