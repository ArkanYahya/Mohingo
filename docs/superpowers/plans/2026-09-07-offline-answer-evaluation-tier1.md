# Offline Answer Evaluation (Tier 1: Structured Evaluators) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the unimplemented `evaluation` rubric string with a structured, data-driven evaluator system for the four non-open-ended rubric types (`nonEmpty`, `numericRange`, `letterSequence`, `keywordChecklist`-without-online-refinement), wire it into `WriteActivityView`/`SpeakActivityView`, add the learner-name field the `letterSequence` evaluator needs, and migrate A1-U0's real bundle content onto it — fully unblocking A1-U0's mastery, which is currently impossible.

**Architecture:** A new pure-Dart `evaluation` domain module (`EvaluationSpec` parsed from structured JSON, an `EvaluationContext` carrying the two pieces of runtime state a spec might need, and an `evaluate()` dispatcher) plugs into the existing `accepted`-list branch already present in `WriteActivityView`/`SpeakActivityView`, exactly where `notAutoGraded` is produced today. `EvaluationContext` is assembled once per lesson by `LessonPlayerScreen` (learner name from the database, an in-memory map of this session's own prior answers) and threaded down through `buildActivityView`. No change to `MasteryAggregationService` or `ActivityAttempts` is needed — a spec that fails to parse (the ~128 rubrics this plan does not touch) simply returns `null` and every call site already falls back to today's `notAutoGraded` behavior.

**Tech Stack:** Dart (pure domain logic, no new packages), Drift (first-ever schema migration, `schemaVersion` 1→2), Flutter/Riverpod (existing patterns only).

**Spec:** [docs/superpowers/specs/2026-09-07-offline-answer-evaluation-design.md](../specs/2026-09-07-offline-answer-evaluation-design.md)

## Global Constraints

- No new third-party dependency — every evaluator in this plan is pure Dart/local. (Tier 2's LanguageTool/connectivity work is a separate plan.)
- All new user-facing copy must be bilingual (Arabic + English), each written natively, never machine-translated — see `docs/UX_PRINCIPLES.md`.
- UI must use directional (start/end) layout properties only, never hardcoded left/right — see `docs/DESIGN_SYSTEM.md`.
- `ActivityAttempts` is insert-only — never write code that updates or deletes an existing attempt row.
- TDD: every task's step order is failing test → verified RED → minimal implementation → verified GREEN → commit.

---

## Known content gap found while planning (read before Task 9)

`A1.U0.INTERACTION.REGISTER_FOR_CLASS` — one of U0's four required mastery objectives — has exactly **one** `mode: mastery` activity tagged with it anywhere in the bundle (`A1-U0-L5-A01`). `MasteryPolicy.minimumEvidencePerRequiredObjective` is `2`, so this objective is structurally unmasterable regardless of how good its evaluator is — a content gap, not a grading gap. Task 9 adds one new activity (`A1-U0-L5-A05`) to close it, using the same low-bar `nonEmpty` grading style already used for `A1-U0-L5-A01` (both are "can you produce a personal-register opening line" checks, matching the A1.0 objective). This is a real curriculum-content addition, not just a data-format change — flag it for review since it's a content decision, not a pure engineering one.

## File structure

**New:**
- `lib/features/activity_engine/domain/evaluation/evaluation_spec.dart` — `EvaluationSpec` sealed class (`NonEmptyEvaluationSpec`, `NumericRangeEvaluationSpec`, `LetterSequenceEvaluationSpec` + `LetterSequenceReference`, `KeywordChecklistEvaluationSpec`) and `EvaluationSpec.fromJson`.
- `lib/features/activity_engine/domain/evaluation/evaluation_context.dart` — `EvaluationContext` (`profileName`, `previousAnswers`).
- `lib/features/activity_engine/domain/evaluation/evaluator.dart` — `evaluate(EvaluationSpec, String answer, {EvaluationContext context})`.
- `test/features/activity_engine/domain/evaluation/evaluation_spec_test.dart`
- `test/features/activity_engine/domain/evaluation/evaluator_test.dart`

**Modified:**
- `lib/features/activity_engine/domain/answer_matching.dart` — export `lettersOnlyMatch`.
- `lib/content/models/activity.dart` — `FormActivity`/`SpeakActivity`/`WriteActivity`'s `evaluation` field: `String?` → `EvaluationSpec?`.
- `lib/features/activity_engine/presentation/views/write_activity_view.dart` — evaluator branch + `evaluationContext` param.
- `lib/features/activity_engine/presentation/views/speak_activity_view.dart` — evaluator branch + `evaluationContext` param.
- `lib/features/activity_engine/presentation/activity_view_registry.dart` — thread `evaluationContext` through.
- `lib/features/lesson_player/presentation/lesson_player_screen.dart` — assemble and pass `EvaluationContext`.
- `lib/data/local/tables/learner_tables.dart` — `Learners.name` (nullable).
- `lib/data/local/database.dart` — `schemaVersion` 2, `onUpgrade`.
- `lib/features/progress/domain/repositories/learner_repository.dart` + `lib/features/progress/data/drift_learner_repository.dart` — `updateName`.
- `lib/features/settings/presentation/settings_screen.dart` — name field.
- `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb` — new Settings copy.
- `assets/content/en/A1/a1-course-bundle.json` — 5 rubric migrations + 1 new activity.
- `docs/DATA_MODEL.md` — `Activity`/`Learner` sections.

---

### Task 1: `EvaluationSpec` data model

**Files:**
- Create: `lib/features/activity_engine/domain/evaluation/evaluation_spec.dart`
- Test: `test/features/activity_engine/domain/evaluation/evaluation_spec_test.dart`

**Interfaces:**
- Produces: `EvaluationSpec` (sealed), `EvaluationSpec.fromJson(Object? json) -> EvaluationSpec?`, subtypes `NonEmptyEvaluationSpec`, `NumericRangeEvaluationSpec{min, max}`, `LetterSequenceEvaluationSpec{reference}`, `KeywordChecklistEvaluationSpec{requiredGroups, minGroupsMatched}`, `LetterSequenceReference` (sealed): `ProfileNameReference`, `PreviousAnswerReference{activityId}`, `LiteralReference{text}`.

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/evaluation_spec.dart';

void main() {
  group('EvaluationSpec.fromJson', () {
    test('a legacy opaque string (not yet migrated) parses to null', () {
      expect(EvaluationSpec.fromJson('non-empty-name'), isNull);
    });

    test('a missing evaluation field parses to null', () {
      expect(EvaluationSpec.fromJson(null), isNull);
    });

    test('an unrecognized type parses to null', () {
      expect(EvaluationSpec.fromJson({'type': 'somethingElse'}), isNull);
    });

    test('parses nonEmpty', () {
      final spec = EvaluationSpec.fromJson({'type': 'nonEmpty'});
      expect(spec, isA<NonEmptyEvaluationSpec>());
    });

    test('parses numericRange', () {
      final spec = EvaluationSpec.fromJson({
        'type': 'numericRange',
        'min': 1,
        'max': 120,
      });
      expect(spec, isA<NumericRangeEvaluationSpec>());
      final range = spec as NumericRangeEvaluationSpec;
      expect(range.min, 1.0);
      expect(range.max, 120.0);
    });

    test('parses letterSequence with a profileName reference', () {
      final spec = EvaluationSpec.fromJson({
        'type': 'letterSequence',
        'reference': 'profileName',
      });
      expect(spec, isA<LetterSequenceEvaluationSpec>());
      expect(
        (spec as LetterSequenceEvaluationSpec).reference,
        isA<ProfileNameReference>(),
      );
    });

    test('parses letterSequence with a previousAnswer reference', () {
      final spec = EvaluationSpec.fromJson({
        'type': 'letterSequence',
        'reference': 'previousAnswer:A1-U0-L5-A01',
      });
      final reference =
          (spec as LetterSequenceEvaluationSpec).reference
              as PreviousAnswerReference;
      expect(reference.activityId, 'A1-U0-L5-A01');
    });

    test('parses letterSequence with a literal reference', () {
      final spec = EvaluationSpec.fromJson({
        'type': 'letterSequence',
        'reference': 'Ali',
      });
      final reference =
          (spec as LetterSequenceEvaluationSpec).reference as LiteralReference;
      expect(reference.text, 'Ali');
    });

    test('parses keywordChecklist', () {
      final spec = EvaluationSpec.fromJson({
        'type': 'keywordChecklist',
        'requiredGroups': [
          ['hi', 'hello'],
          ['weekend', 'saturday'],
        ],
        'minGroupsMatched': 2,
      });
      expect(spec, isA<KeywordChecklistEvaluationSpec>());
      final checklist = spec as KeywordChecklistEvaluationSpec;
      expect(checklist.requiredGroups, [
        ['hi', 'hello'],
        ['weekend', 'saturday'],
      ]);
      expect(checklist.minGroupsMatched, 2);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/activity_engine/domain/evaluation/evaluation_spec_test.dart`
Expected: FAIL — `evaluation_spec.dart` doesn't exist yet.

- [ ] **Step 3: Implement**

```dart
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/activity_engine/domain/evaluation/evaluation_spec_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/activity_engine/domain/evaluation/evaluation_spec.dart test/features/activity_engine/domain/evaluation/evaluation_spec_test.dart
git commit -m "feat: add structured EvaluationSpec data model"
```

---

### Task 2: `lettersOnlyMatch`, `EvaluationContext`, and the `evaluate()` dispatcher

**Files:**
- Modify: `lib/features/activity_engine/domain/answer_matching.dart`
- Create: `lib/features/activity_engine/domain/evaluation/evaluation_context.dart`
- Create: `lib/features/activity_engine/domain/evaluation/evaluator.dart`
- Test: `test/features/activity_engine/domain/evaluation/evaluator_test.dart`

**Interfaces:**
- Consumes: `EvaluationSpec` and subtypes (Task 1).
- Produces: `lettersOnlyMatch(String, String) -> bool` (in `answer_matching.dart`); `EvaluationContext({profileName, previousAnswers})`, `EvaluationContext.empty()`; `({ActivityCorrectness correctness, double? score}) evaluate(EvaluationSpec spec, String answer, {EvaluationContext context})`.

- [ ] **Step 1: Add `lettersOnlyMatch` to `answer_matching.dart`**

Add this public function near the bottom of `lib/features/activity_engine/domain/answer_matching.dart`, alongside the existing private `_lettersOnly` it reuses:

```dart
/// Whether [a] and [b] contain the same sequence of letters, ignoring case,
/// spacing, and punctuation — e.g. "Ali", "a l i", and "A-L-I" all match.
/// Shared by [answersMatch]'s letter-spelling case and the `letterSequence`
/// evaluator (see lib/features/activity_engine/domain/evaluation).
bool lettersOnlyMatch(String a, String b) => _lettersOnly(a) == _lettersOnly(b);
```

- [ ] **Step 2: Write the failing test for `EvaluationContext` and `evaluate()`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/evaluation_context.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/evaluation_spec.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/evaluator.dart';

void main() {
  group('nonEmpty', () {
    test('a non-blank answer is correct', () {
      final result = evaluate(const NonEmptyEvaluationSpec(), 'Ali');
      expect(result.correctness, ActivityCorrectness.correct);
      expect(result.score, 1.0);
    });

    test('a blank answer is incorrect', () {
      final result = evaluate(const NonEmptyEvaluationSpec(), '   ');
      expect(result.correctness, ActivityCorrectness.incorrect);
      expect(result.score, 0.0);
    });
  });

  group('numericRange', () {
    const spec = NumericRangeEvaluationSpec(min: 1, max: 120);

    test('a number inside the range is correct', () {
      final result = evaluate(spec, "I'm 25 years old.");
      expect(result.correctness, ActivityCorrectness.correct);
    });

    test('a number outside the range is incorrect', () {
      final result = evaluate(spec, '999');
      expect(result.correctness, ActivityCorrectness.incorrect);
    });

    test('no number at all is incorrect', () {
      final result = evaluate(spec, 'old enough');
      expect(result.correctness, ActivityCorrectness.incorrect);
      expect(result.score, 0.0);
    });
  });

  group('letterSequence', () {
    test('a profileName reference matches the context\'s profile name', () {
      const spec = LetterSequenceEvaluationSpec(
        reference: ProfileNameReference(),
      );
      final result = evaluate(
        spec,
        'a l i',
        context: const EvaluationContext(profileName: 'Ali'),
      );
      expect(result.correctness, ActivityCorrectness.correct);
    });

    test('a profileName reference falls back to a non-empty check when no '
        'name is set yet', () {
      const spec = LetterSequenceEvaluationSpec(
        reference: ProfileNameReference(),
      );
      final result = evaluate(spec, 'a l i');
      expect(result.correctness, ActivityCorrectness.correct);
    });

    test('a previousAnswer reference matches the referenced activity\'s '
        'stored answer', () {
      const spec = LetterSequenceEvaluationSpec(
        reference: PreviousAnswerReference('A1-U0-L5-A01'),
      );
      final result = evaluate(
        spec,
        'a l i',
        context: const EvaluationContext(
          previousAnswers: {'A1-U0-L5-A01': 'Ali'},
        ),
      );
      expect(result.correctness, ActivityCorrectness.correct);
    });

    test('a previousAnswer reference with nothing recorded yet is '
        'not-auto-graded, not falsely correct', () {
      const spec = LetterSequenceEvaluationSpec(
        reference: PreviousAnswerReference('A1-U0-L5-A01'),
      );
      final result = evaluate(spec, 'a l i');
      expect(result.correctness, ActivityCorrectness.notAutoGraded);
    });

    test('a mismatched letter sequence is incorrect', () {
      const spec = LetterSequenceEvaluationSpec(
        reference: LiteralReference('Ali'),
      );
      final result = evaluate(spec, 'a l e');
      expect(result.correctness, ActivityCorrectness.incorrect);
    });
  });

  group('keywordChecklist', () {
    const spec = KeywordChecklistEvaluationSpec(
      requiredGroups: [
        ['hi', 'hello'],
        ['weekend', 'saturday', 'sunday'],
      ],
      minGroupsMatched: 2,
    );

    test('meeting every required group is correct', () {
      final result = evaluate(spec, 'Hello! See you this weekend.');
      expect(result.correctness, ActivityCorrectness.correct);
      expect(result.score, 1.0);
    });

    test('meeting fewer than the threshold is incorrect, with a partial '
        'score', () {
      final result = evaluate(spec, 'Hello there.');
      expect(result.correctness, ActivityCorrectness.incorrect);
      expect(result.score, 0.5);
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/activity_engine/domain/evaluation/evaluator_test.dart`
Expected: FAIL — `evaluation_context.dart`/`evaluator.dart` don't exist yet.

- [ ] **Step 4: Implement `EvaluationContext`**

```dart
/// Runtime state a [EvaluationSpec] evaluator may need, assembled once per
/// lesson by whoever plays it (the lesson player, placement test, etc.) —
/// an activity view never resolves this itself. See
/// docs/superpowers/specs/2026-09-07-offline-answer-evaluation-design.md.
class EvaluationContext {
  const EvaluationContext({this.profileName, this.previousAnswers = const {}});
  const EvaluationContext.empty() : profileName = null, previousAnswers = const {};

  /// The learner's persisted `Learners.name`, if set.
  final String? profileName;

  /// Raw text answers already given earlier in this same play-through,
  /// keyed by activity id — never a database read, just what's been
  /// submitted so far in this session.
  final Map<String, String> previousAnswers;
}
```

- [ ] **Step 5: Implement `evaluate()`**

```dart
import '../activity_submission.dart';
import '../answer_matching.dart';
import 'evaluation_context.dart';
import 'evaluation_spec.dart';

final _numberPattern = RegExp(r'\d+(\.\d+)?');

/// Grades [answer] against [spec]. Pure and synchronous — every spec type
/// this dispatches to is fully offline. See docs/superpowers/specs/
/// 2026-09-07-offline-answer-evaluation-design.md.
({ActivityCorrectness correctness, double? score}) evaluate(
  EvaluationSpec spec,
  String answer, {
  EvaluationContext context = const EvaluationContext.empty(),
}) {
  return switch (spec) {
    NonEmptyEvaluationSpec() => _nonEmpty(answer),
    NumericRangeEvaluationSpec s => _numericRange(s, answer),
    LetterSequenceEvaluationSpec s => _letterSequence(s, answer, context),
    KeywordChecklistEvaluationSpec s => _keywordChecklist(s, answer),
  };
}

({ActivityCorrectness correctness, double? score}) _nonEmpty(String answer) {
  final isCorrect = answer.trim().isNotEmpty;
  return (
    correctness: isCorrect
        ? ActivityCorrectness.correct
        : ActivityCorrectness.incorrect,
    score: isCorrect ? 1.0 : 0.0,
  );
}

({ActivityCorrectness correctness, double? score}) _numericRange(
  NumericRangeEvaluationSpec spec,
  String answer,
) {
  final match = _numberPattern.firstMatch(answer);
  if (match == null) {
    return (correctness: ActivityCorrectness.incorrect, score: 0.0);
  }
  final value = double.parse(match.group(0)!);
  final isCorrect = value >= spec.min && value <= spec.max;
  return (
    correctness: isCorrect
        ? ActivityCorrectness.correct
        : ActivityCorrectness.incorrect,
    score: isCorrect ? 1.0 : 0.0,
  );
}

({ActivityCorrectness correctness, double? score}) _letterSequence(
  LetterSequenceEvaluationSpec spec,
  String answer,
  EvaluationContext context,
) {
  final reference = switch (spec.reference) {
    ProfileNameReference() => context.profileName,
    PreviousAnswerReference(:final activityId) =>
      context.previousAnswers[activityId],
    LiteralReference(:final text) => text,
  };

  if (reference == null || reference.trim().isEmpty) {
    // A profile name that hasn't been set yet is a normal, expected state
    // (the learner may not have visited Settings) — soften to a
    // non-empty check rather than blocking. A missing previous-answer
    // reference should never happen in a correctly authored lesson (the
    // referenced activity is always earlier in the same lesson), so it's
    // left un-auto-graded rather than silently treated as a pass.
    if (spec.reference is ProfileNameReference) return _nonEmpty(answer);
    return (correctness: ActivityCorrectness.notAutoGraded, score: null);
  }

  final isCorrect = lettersOnlyMatch(reference, answer);
  return (
    correctness: isCorrect
        ? ActivityCorrectness.correct
        : ActivityCorrectness.incorrect,
    score: isCorrect ? 1.0 : 0.0,
  );
}

({ActivityCorrectness correctness, double? score}) _keywordChecklist(
  KeywordChecklistEvaluationSpec spec,
  String answer,
) {
  final normalized = answer.toLowerCase();
  final matchedGroups = spec.requiredGroups
      .where(
        (group) => group.any((kw) => normalized.contains(kw.toLowerCase())),
      )
      .length;
  final isCorrect = matchedGroups >= spec.minGroupsMatched;
  final score = spec.requiredGroups.isEmpty
      ? (isCorrect ? 1.0 : 0.0)
      : matchedGroups / spec.requiredGroups.length;
  return (
    correctness: isCorrect
        ? ActivityCorrectness.correct
        : ActivityCorrectness.incorrect,
    score: score,
  );
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/features/activity_engine/domain/evaluation/evaluator_test.dart`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/features/activity_engine/domain/answer_matching.dart lib/features/activity_engine/domain/evaluation/evaluation_context.dart lib/features/activity_engine/domain/evaluation/evaluator.dart test/features/activity_engine/domain/evaluation/evaluator_test.dart
git commit -m "feat: add EvaluationContext and the evaluate() dispatcher"
```

---

### Task 3: Wire `EvaluationSpec` into `activity.dart`

**Files:**
- Modify: `lib/content/models/activity.dart:263-381` (`FormActivity`, `SpeakActivity`, `WriteActivity`)
- Test: `test/content/models/activity_test.dart` (create if it doesn't already cover this — check first; extend in place if it exists)

**Interfaces:**
- Consumes: `EvaluationSpec.fromJson` (Task 1).
- Produces: `FormActivity.evaluation`, `SpeakActivity.evaluation`, `WriteActivity.evaluation` — now typed `EvaluationSpec?` instead of `String?`.

- [ ] **Step 1: Check for an existing activity-parsing test file**

Run: `find test/content -iname "*activity*"`. If a suitable file exists, add the two tests below to it; otherwise create `test/content/models/activity_test.dart`.

- [ ] **Step 2: Write the failing tests**

```dart
test('WriteActivity parses a structured evaluation spec', () {
  final activity = Activity.fromJson({
    'id': 'A1-TEST-A01',
    'lessonId': 'A1-TEST-L1',
    'type': 'write',
    'mode': 'mastery',
    'skill': 'writing',
    'canDo': <String>[],
    'prompt': 'Write your name.',
    'accepted': <String>[],
    'evaluation': {'type': 'nonEmpty'},
  }) as WriteActivity;

  expect(activity.evaluation, isA<NonEmptyEvaluationSpec>());
});

test('WriteActivity with a not-yet-migrated legacy evaluation string '
    'parses evaluation as null, not a crash', () {
  final activity = Activity.fromJson({
    'id': 'A1-TEST-A02',
    'lessonId': 'A1-TEST-L1',
    'type': 'write',
    'mode': 'mastery',
    'skill': 'writing',
    'canDo': <String>[],
    'prompt': 'Write a message.',
    'accepted': <String>[],
    'evaluation': 'some-legacy-rubric-name',
  }) as WriteActivity;

  expect(activity.evaluation, isNull);
});
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/content/models/activity_test.dart`
Expected: FAIL — `WriteActivity.evaluation` is still `String?`, so `isA<NonEmptyEvaluationSpec>()` fails and/or a cast error surfaces.

- [ ] **Step 4: Implement**

In `lib/content/models/activity.dart`, add the import:

```dart
import 'evaluation/evaluation_spec.dart' show EvaluationSpec;
```

Note this file lives under `lib/content/models/`, not `lib/features/activity_engine/domain/evaluation/` — `EvaluationSpec` is a content-model-adjacent concept (parsed straight out of bundle JSON) used by both the content layer and the activity engine, so re-export it from a thin path alias if the import path above doesn't resolve cleanly; the concrete file still lives at `lib/features/activity_engine/domain/evaluation/evaluation_spec.dart` from Task 1 — use a relative import to that path instead:

```dart
import '../../features/activity_engine/domain/evaluation/evaluation_spec.dart';
```

Then, in each of `FormActivity`, `SpeakActivity`, `WriteActivity`:

```dart
// constructor: this.evaluation, unchanged signature-wise
// field:
final EvaluationSpec? evaluation;
// _fromJson:
evaluation: EvaluationSpec.fromJson(json['evaluation']),
```

(Three call sites: `activity.dart:289`, `:327`, `:369` per the current file — replace `json['evaluation'] as String?` with `EvaluationSpec.fromJson(json['evaluation'])` in each, and change each class's `final String? evaluation;` to `final EvaluationSpec? evaluation;`.)

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/content/models/activity_test.dart`
Expected: PASS

- [ ] **Step 6: Run the full test suite to check for fallout**

Run: `flutter test`
Expected: Compile errors in `write_activity_view.dart`/`speak_activity_view.dart`/`form_activity_view.dart` wherever `.evaluation` is referenced as a string — none currently reference it directly (they only branch on `.accepted`), so this should be clean; if not, note the exact error for the next task.

**Scope note:** this task changes `FormActivity.evaluation`'s type for consistency (all three classes share the same field), but `FormActivityView` is deliberately **not** wired to consume it in this plan — no U0-blocking objective needs a `form`-type activity graded, and no `FormActivity` example exists yet to design its grading against (unlike `write`/`speak`, `FormActivity` has multiple named `fields`, and it's not yet clear from any real content whether a rubric should grade them jointly or individually). `FormActivityView` keeps its existing hardcoded `notAutoGraded` behavior — no regression, just deferred. Revisit in a follow-up plan once a real `FormActivity` rubric needs it.

- [ ] **Step 7: Commit**

```bash
git add lib/content/models/activity.dart test/content/models/activity_test.dart
git commit -m "feat: parse Activity.evaluation as a structured EvaluationSpec"
```

---

### Task 4: Wire the evaluator into `WriteActivityView`

**Files:**
- Modify: `lib/features/activity_engine/presentation/views/write_activity_view.dart`
- Test: `test/features/activity_engine/write_activity_view_test.dart`

**Interfaces:**
- Consumes: `evaluate()` (Task 2), `EvaluationContext` (Task 2), `WriteActivity.evaluation` (Task 3).
- Produces: `WriteActivityView`'s new optional `evaluationContext` constructor parameter (default `EvaluationContext.empty()`).

- [ ] **Step 1: Write the failing test**

Add to `test/features/activity_engine/write_activity_view_test.dart`:

```dart
testWidgets(
  'an activity with a structured evaluation spec (no accepted list) is '
  'graded via it, not left notAutoGraded',
  (tester) async {
    const activity = WriteActivity(
      id: 'A1-TEST-A01',
      lessonId: 'A1-TEST-L1',
      mode: ActivityMode.mastery,
      skill: Skill.writing,
      canDo: [],
      prompt: 'Write your name.',
      promptAr: 'اكتب اسمك.',
      raw: {},
      accepted: [],
      evaluation: NonEmptyEvaluationSpec(),
    );

    ActivitySubmission? captured;
    await tester.pumpActivityView(
      WriteActivityView(
        activity: activity,
        onSubmitted: (s) => captured = s,
      ),
    );

    await tester.enterText(find.byType(TextField), 'Ali');
    await tester.tap(find.widgetWithText(FilledButton, 'Check'));
    await tester.pump();

    expect(captured!.correctness, ActivityCorrectness.correct);
  },
);
```

(Add the two imports this needs — `evaluation_spec.dart` and `evaluation_context.dart` — alongside the file's existing imports.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/activity_engine/write_activity_view_test.dart`
Expected: FAIL — `captured!.correctness` is `notAutoGraded`, not `correct`.

- [ ] **Step 3: Implement**

In `lib/features/activity_engine/presentation/views/write_activity_view.dart`, add imports:

```dart
import '../../domain/evaluation/evaluation_context.dart';
import '../../domain/evaluation/evaluator.dart';
```

Add the constructor parameter:

```dart
class WriteActivityView extends StatefulWidget {
  const WriteActivityView({
    required this.activity,
    required this.onSubmitted,
    this.evaluationContext = const EvaluationContext.empty(),
    super.key,
  });

  final WriteActivity activity;
  final OnActivitySubmitted onSubmitted;
  final EvaluationContext evaluationContext;
  ...
```

Replace `_submit()`'s `else` branch:

```dart
  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || _submission != null) return;

    final ActivitySubmission submission;
    if (widget.activity.accepted.isNotEmpty) {
      final isCorrect = widget.activity.accepted.any(
        (a) => answersMatch(a, text),
      );
      submission = ActivitySubmission(
        correctness: isCorrect
            ? ActivityCorrectness.correct
            : ActivityCorrectness.incorrect,
        score: isCorrect ? 1.0 : 0.0,
        rawAnswerJson: jsonEncode(text),
      );
    } else if (widget.activity.evaluation != null) {
      final result = evaluate(
        widget.activity.evaluation!,
        text,
        context: widget.evaluationContext,
      );
      submission = ActivitySubmission(
        correctness: result.correctness,
        score: result.score,
        rawAnswerJson: jsonEncode(text),
      );
    } else {
      submission = ActivitySubmission(
        correctness: ActivityCorrectness.notAutoGraded,
        rawAnswerJson: jsonEncode(text),
      );
    }
    setState(() => _submission = submission);
    widget.onSubmitted(submission);
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/activity_engine/write_activity_view_test.dart`
Expected: PASS

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`
Expected: PASS (no other file references `WriteActivityView`'s constructor positionally in a way this breaks — it's a new optional named parameter).

- [ ] **Step 6: Commit**

```bash
git add lib/features/activity_engine/presentation/views/write_activity_view.dart test/features/activity_engine/write_activity_view_test.dart
git commit -m "feat: grade WriteActivity via its structured evaluation spec"
```

---

### Task 5: Wire the evaluator into `SpeakActivityView`

**Files:**
- Modify: `lib/features/activity_engine/presentation/views/speak_activity_view.dart`
- Test: `test/features/activity_engine/speak_activity_view_test.dart`

**Interfaces:**
- Consumes: `evaluate()`, `EvaluationContext` (Task 2), `SpeakActivity.evaluation` (Task 3).
- Produces: `SpeakActivityView`'s new optional `evaluationContext` constructor parameter.

- [ ] **Step 1: Extend the `_pumpSpeak` helper**

In `test/features/activity_engine/speak_activity_view_test.dart`, give `_pumpSpeak` two new optional parameters — an activity override (this file's `_speakActivity()` fixture has no `evaluation`, so the new test needs its own) and an `EvaluationContext` passthrough:

```dart
Future<void> _pumpSpeak(
  WidgetTester tester, {
  required DeviceSpeechCapabilities capabilities,
  FakeSpeechRecognitionService? recognitionService,
  void Function(ActivitySubmission)? onSubmitted,
  Locale locale = const Locale('en'),
  SpeakActivity? activity,
  EvaluationContext evaluationContext = const EvaluationContext.empty(),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        speechCapabilityServiceProvider.overrideWithValue(
          FakeSpeechCapabilityService(capabilities),
        ),
        speechRecognitionServiceProvider.overrideWithValue(
          recognitionService ?? FakeSpeechRecognitionService(),
        ),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: SpeakActivityView(
            activity: activity ?? _speakActivity(),
            onSubmitted: onSubmitted ?? (_) {},
            evaluationContext: evaluationContext,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
```

Add the two new imports this needs: `evaluation_context.dart` and `evaluation_spec.dart`.

- [ ] **Step 2: Write the failing test**

```dart
testWidgets(
  'an activity with a structured evaluation spec is graded via it '
  'through the typed-fallback path',
  (tester) async {
    const activity = SpeakActivity(
      id: 'A1-U0-L5-A01',
      lessonId: 'A1-U0-L5',
      mode: ActivityMode.mastery,
      skill: Skill.spokenInteraction,
      canDo: ['A1.U0.INTERACTION.REGISTER_FOR_CLASS'],
      prompt: "What's your name?",
      promptAr: 'ما اسمك؟',
      raw: {},
      accepted: [],
      evaluation: NonEmptyEvaluationSpec(),
      fallbackSkill: 'writing',
    );

    ActivitySubmission? captured;
    // This exact capability combination is this file's/the codebase's
    // established way to force a `speak` activity straight to its typed
    // fallback in a widget test, with no real platform to answer a
    // capability/permission check — see
    // test/features/lesson_player/lesson_player_e2e_test.dart.
    await _pumpSpeak(
      tester,
      activity: activity,
      capabilities: const DeviceSpeechCapabilities(
        sttAvailableForLocale: false,
        micPermission: SpeechPermissionStatus.notDetermined,
      ),
      onSubmitted: (s) => captured = s,
    );

    await tester.enterText(find.byType(TextField), 'Ali');
    await tester.tap(find.text('Check'));
    await tester.pump();

    expect(captured!.correctness, ActivityCorrectness.correct);
    expect(captured!.wasFallback, isTrue);
  },
);
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/activity_engine/speak_activity_view_test.dart`
Expected: FAIL — compile error (`evaluation:`/`evaluationContext` not yet accepted) or `notAutoGraded` instead of `correct`.

- [ ] **Step 4: Implement**

In `lib/features/activity_engine/presentation/views/speak_activity_view.dart`, add imports:

```dart
import '../../domain/evaluation/evaluation_context.dart';
import '../../domain/evaluation/evaluator.dart';
```

Add the constructor parameter:

```dart
class SpeakActivityView extends ConsumerStatefulWidget {
  const SpeakActivityView({
    required this.activity,
    required this.onSubmitted,
    this.evaluationContext = const EvaluationContext.empty(),
    super.key,
  });

  final SpeakActivity activity;
  final OnActivitySubmitted onSubmitted;
  final EvaluationContext evaluationContext;
  ...
```

Replace `_submit`'s `else` branch (both `_submitTranscript`/`_submitTyped` already funnel through this one shared method):

```dart
  void _submit(String text, {required bool wasFallback}) {
    if (_submission != null) return;

    final ActivitySubmission submission;
    if (widget.activity.accepted.isNotEmpty) {
      final isCorrect = widget.activity.accepted.any(
        (a) => answersMatch(a, text),
      );
      submission = ActivitySubmission(
        correctness: isCorrect
            ? ActivityCorrectness.correct
            : ActivityCorrectness.incorrect,
        score: isCorrect ? 1.0 : 0.0,
        rawAnswerJson: jsonEncode(text),
        wasFallback: wasFallback,
      );
    } else if (widget.activity.evaluation != null) {
      final result = evaluate(
        widget.activity.evaluation!,
        text,
        context: widget.evaluationContext,
      );
      submission = ActivitySubmission(
        correctness: result.correctness,
        score: result.score,
        rawAnswerJson: jsonEncode(text),
        wasFallback: wasFallback,
      );
    } else {
      submission = ActivitySubmission(
        correctness: ActivityCorrectness.notAutoGraded,
        rawAnswerJson: jsonEncode(text),
        wasFallback: wasFallback,
      );
    }
    setState(() => _submission = submission);
    widget.onSubmitted(submission);
  }
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/activity_engine/speak_activity_view_test.dart`
Expected: PASS

- [ ] **Step 6: Run the full test suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/features/activity_engine/presentation/views/speak_activity_view.dart test/features/activity_engine/speak_activity_view_test.dart
git commit -m "feat: grade SpeakActivity via its structured evaluation spec"
```

---

### Task 6: `Learners.name` schema migration

**Files:**
- Modify: `lib/data/local/tables/learner_tables.dart`
- Modify: `lib/data/local/database.dart`
- Modify: `lib/features/progress/domain/repositories/learner_repository.dart`
- Modify: `lib/features/progress/data/drift_learner_repository.dart`
- Test: `test/data/local/database_test.dart`

**Interfaces:**
- Produces: `Learner.name` (`String?`, generated by Drift), `LearnerRepository.updateName({required int learnerId, required String name})`.

- [ ] **Step 1: Write the failing migration test**

Add to `test/data/local/database_test.dart`:

```dart
import 'package:sqlite3/sqlite3.dart' as sqlite3;
// (add alongside the file's existing imports)

test(
  'migrating from schemaVersion 1 adds a nullable name column without '
  'losing existing rows',
  () async {
    // Build a v1-shaped `learners` table by hand — v1 never had a `name`
    // column — then set drift's own version marker to 1, so opening it
    // through AppDatabase runs onUpgrade exactly like a real upgrading
    // install would.
    final raw = sqlite3.sqlite3.openInMemory();
    raw.execute('''
      CREATE TABLE learners (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        native_language TEXT NOT NULL DEFAULT 'ar',
        target_language TEXT NOT NULL DEFAULT 'en',
        created_at INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    raw.execute(
      "INSERT INTO learners (uuid, created_at) VALUES ('learner-1', 0)",
    );
    raw.execute('PRAGMA user_version = 1');

    final upgraded = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(upgraded.close);

    final row = await upgraded.select(upgraded.learners).getSingle();
    expect(row.uuid, 'learner-1');
    expect(row.name, isNull);

    await (upgraded.update(
      upgraded.learners,
    )..where((t) => t.id.equals(row.id))).write(
      const LearnersCompanion(name: Value('Ali')),
    );
    final updated = await (upgraded.select(
      upgraded.learners,
    )..where((t) => t.id.equals(row.id))).getSingle();
    expect(updated.name, 'Ali');
  },
);
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/local/database_test.dart`
Expected: FAIL — `row.name` doesn't exist (compile error) since the column and migration don't exist yet.

- [ ] **Step 3: Add the column**

In `lib/data/local/tables/learner_tables.dart`, add to `Learners`:

```dart
class Learners extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  TextColumn get name => text().nullable()();
  TextColumn get nativeLanguage => text().withDefault(const Constant('ar'))();
  TextColumn get targetLanguage => text().withDefault(const Constant('en'))();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
```

- [ ] **Step 4: Bump schemaVersion and add the migration**

In `lib/data/local/database.dart`:

```dart
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(learners, learners.name);
      }
    },
  );
```

- [ ] **Step 5: Regenerate Drift code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `database.g.dart` regenerates with `Learner.name` (`String?`) and `LearnersCompanion.name`.

- [ ] **Step 6: Update the existing "schema version is 1" test**

In `test/data/local/database_test.dart`, change:

```dart
test('schema version is 1', () {
  expect(database.schemaVersion, 1);
});
```
to:
```dart
test('schema version is 2', () {
  expect(database.schemaVersion, 2);
});
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `flutter test test/data/local/database_test.dart`
Expected: PASS

- [ ] **Step 8: Add `LearnerRepository.updateName`**

In `lib/features/progress/domain/repositories/learner_repository.dart`, add to the interface:

```dart
  /// Sets [learnerId]'s display name — used by the `letterSequence`
  /// evaluator's `profileName` reference. Passing an empty string clears it
  /// back to unset.
  Future<void> updateName({required int learnerId, required String name});
```

In `lib/features/progress/data/drift_learner_repository.dart`, add:

```dart
  @override
  Future<void> updateName({
    required int learnerId,
    required String name,
  }) async {
    await (_db.update(
      _db.learners,
    )..where((t) => t.id.equals(learnerId))).write(
      LearnersCompanion(name: Value(name.trim().isEmpty ? null : name.trim())),
    );
  }
```

- [ ] **Step 9: Run the full test suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 10: Commit**

```bash
git add lib/data/local/tables/learner_tables.dart lib/data/local/database.dart lib/data/local/database.g.dart lib/features/progress/domain/repositories/learner_repository.dart lib/features/progress/data/drift_learner_repository.dart test/data/local/database_test.dart
git commit -m "feat: add Learners.name (first schema migration, v1 to v2)"
```

---

### Task 7: Settings screen "Your name" field

**Files:**
- Modify: `lib/features/settings/presentation/settings_screen.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`
- Test: `test/features/settings/settings_screen_test.dart`

**Interfaces:**
- Consumes: `currentLearnerProvider`, `learnerRepositoryProvider` (existing), `LearnerRepository.updateName` (Task 6).

- [ ] **Step 1: Add ARB strings**

In `lib/l10n/app_en.arb`, add (matching the file's existing key/`@key` description pattern):

```json
"settingsNameTitle": "Your name",
"@settingsNameTitle": {
  "description": "Section title on Settings for the learner's name field."
},
"settingsNameHint": "Used by a few spelling exercises",
"@settingsNameHint": {
  "description": "Helper text under the Settings name field explaining why it's asked."
},
"settingsNameSaveButton": "Save",
"@settingsNameSaveButton": {
  "description": "Button to save the learner's name in Settings."
},
"settingsNameSaved": "Name saved",
"@settingsNameSaved": {
  "description": "Snackbar confirmation after saving the learner's name in Settings."
}
```

In `lib/l10n/app_ar.arb`, add the matching natively-written Arabic (not machine-translated):

```json
"settingsNameTitle": "اسمك",
"settingsNameHint": "يُستخدم في بعض تمارين التهجئة",
"settingsNameSaveButton": "حفظ",
"settingsNameSaved": "تم حفظ الاسم"
```

Run: `flutter gen-l10n` to regenerate `lib/core/l10n/generated/app_localizations*.dart`.

- [ ] **Step 2: Write the failing test**

Add to `test/features/settings/settings_screen_test.dart`'s `main()`, reusing this file's own `_useTallViewport`/`_setupBacking`/`_baseOverrides` helpers exactly as the existing "renders every settings section" test does (there is no other `TextField` anywhere on the Settings screen today, so `find.byType(TextField)` is unambiguous):

```dart
testWidgets(
  'entering a name and tapping Save persists it and shows confirmation',
  (tester) async {
    _useTallViewport(tester);
    final (db, prefs) = await _setupBacking();

    await tester.pumpWidget(
      ProviderScope(
        overrides: _baseOverrides(prefs, db),
        child: MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Ali');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Name saved'), findsOneWidget);

    final row = await db.select(db.learners).getSingle();
    expect(row.name, 'Ali');
  },
);
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/settings/settings_screen_test.dart`
Expected: FAIL — no such field exists yet.

- [ ] **Step 4: Implement**

In `lib/features/settings/presentation/settings_screen.dart`, add the import:

```dart
import '../../progress/domain/repositories/learner_repository.dart';
```

(`learnerRepositoryProvider` is already reachable via the existing `current_learner_provider.dart`/`progress_providers.dart` import chain — check whether it needs a direct import of `progress_providers.dart`; it's likely already imported transitively through `current_learner_provider.dart`'s import at the top of this file — add `import '../../progress/providers/progress_providers.dart';` if `learnerRepositoryProvider` isn't already resolvable.)

Add the section into `build()`'s `ListView`, after the colour-theme section:

```dart
          const SizedBox(height: 24),
          _SectionTitle(l10n.settingsNameTitle),
          const _NameField(),
```

Add the widget:

```dart
class _NameField extends ConsumerStatefulWidget {
  const _NameField();

  @override
  ConsumerState<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends ConsumerState<_NameField> {
  final _controller = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final learner = await ref.read(currentLearnerProvider.future);
    await ref
        .read(learnerRepositoryProvider)
        .updateName(learnerId: learner.id, name: _controller.text.trim());
    ref.invalidate(currentLearnerProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsNameSaved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final learnerAsync = ref.watch(currentLearnerProvider);
    return learnerAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => Text('$error'),
      data: (learner) {
        if (!_initialized) {
          _controller.text = learner.name ?? '';
          _initialized = true;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                helperText: l10n.settingsNameHint,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                onPressed: () => _save(context, ref),
                child: Text(l10n.settingsNameSaveButton),
              ),
            ),
          ],
        );
      },
    );
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/settings/settings_screen_test.dart`
Expected: PASS

- [ ] **Step 6: Run the full test suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/features/settings/presentation/settings_screen.dart lib/l10n/app_en.arb lib/l10n/app_ar.arb lib/core/l10n/generated/ test/features/settings/settings_screen_test.dart
git commit -m "feat: add a Your name field to Settings"
```

---

### Task 8: Thread `EvaluationContext` from `LessonPlayerScreen`

**Files:**
- Modify: `lib/features/activity_engine/presentation/activity_view_registry.dart`
- Modify: `lib/features/lesson_player/presentation/lesson_player_screen.dart`
- Test: `test/features/lesson_player/lesson_player_e2e_test.dart` (extend), or a new focused test file if cleaner — check the existing e2e file's scope first.

**Interfaces:**
- Consumes: `EvaluationContext` (Task 2), `Learner.name` (Task 6).
- Produces: `buildActivityView(..., {EvaluationContext evaluationContext})`.

- [ ] **Step 1: Write the failing test**

Add a new test to `test/features/lesson_player/lesson_player_e2e_test.dart`, in the same `main()` as the existing L1 test, reusing this file's own `_answerAndAdvance(tester, activity)` helper for A1-U0-L3's first 3 activities (`A1-U0-L3-A01`/`A02`: audioChoice; `A1-U0-L3-A03`: speak/practice with `accepted: ["A-L-I"]`) and driving `A1-U0-L3-A04` ("Spell your name.") manually, since it needs a specific answer and assertion:

```dart
testWidgets(
  'a letterSequence/profileName activity (A1-U0-L3-A04, "Spell your '
  'name.") is graded against the learner\'s saved name',
  (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final index = _realA1Index();
    final lesson = index.lessonsById['A1-U0-L3']!;
    expect(
      lesson.activities,
      hasLength(4),
      reason:
          'this test is written against the real content shape — if '
          'A1-U0-L3 changes, update the driving steps below alongside it',
    );
    await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: 'learner-1',
            name: const Value('Ali'),
            createdAt: DateTime.utc(2026, 9, 7),
          ),
        );

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider('a1').overrideWith((ref) async => index),
          textToSpeechServiceProvider.overrideWithValue(
            FakeTextToSpeechService(),
          ),
          speechCapabilityServiceProvider.overrideWithValue(
            FakeSpeechCapabilityService(
              const DeviceSpeechCapabilities(
                sttAvailableForLocale: false,
                micPermission: SpeechPermissionStatus.notDetermined,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const LessonPlayerScreen(
            unitId: 'A1-U0',
            lessonId: 'A1-U0-L3',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // A01, A02, A03 — drive with the file's existing generic helper.
    for (final activity in lesson.activities.take(3)) {
      await _answerAndAdvance(tester, activity);
    }

    // A04 ("Spell your name.") — answer manually to assert on its grading.
    await tester.enterText(find.byType(TextField), 'a l i');
    await tester.pump();
    await tester.tap(find.byType(FilledButton)); // Check
    await tester.pump();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await db.close();
  },
);
```

(`Icons.check_circle` is confirmed as `ActivityFeedbackBanner`'s correct-answer icon at `lib/features/activity_engine/presentation/activity_chrome.dart:99`, used only for the `ActivityCorrectness.correct` case.)

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/lesson_player/lesson_player_e2e_test.dart`
Expected: FAIL — L3-A04's `evaluation` is still the legacy opaque string at this point (migrated in Task 9), and `buildActivityView`/`LessonPlayerScreen` don't yet pass an `EvaluationContext`, so it's `notAutoGraded` regardless.

- [ ] **Step 3: Thread `EvaluationContext` through `buildActivityView`**

In `lib/features/activity_engine/presentation/activity_view_registry.dart`:

```dart
import '../domain/evaluation/evaluation_context.dart';

Widget buildActivityView(
  Activity activity, {
  required OnActivitySubmitted onSubmitted,
  Map<String, MediaSpecification> mediaByKey = const {},
  EvaluationContext evaluationContext = const EvaluationContext.empty(),
  Key? key,
}) {
  return switch (activity) {
    ...
    SpeakActivity a => SpeakActivityView(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
      evaluationContext: evaluationContext,
    ),
    WriteActivity a => WriteActivityView(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
      evaluationContext: evaluationContext,
    ),
    ...
  };
}
```

(Every other case in the `switch` is unchanged — only the `SpeakActivity`/`WriteActivity` branches gain `evaluationContext:`.)

- [ ] **Step 4: Assemble and pass `EvaluationContext` from the lesson player**

In `lib/features/lesson_player/presentation/lesson_player_screen.dart`, add the import:

```dart
import 'dart:convert';

import '../../activity_engine/domain/evaluation/evaluation_context.dart';
```

Pass the learner's name down from `LessonPlayerScreen.build()`:

```dart
          data: (learner) => _LessonPlayerBody(
            unitId: unitId,
            unit: unit,
            lesson: lesson,
            learnerId: learner.id,
            learnerName: learner.name,
            masteryPolicy: index.bundle.domain.masteryPolicy,
            mediaByKey: index.bundle.mediaSpecifications,
          ),
```

Add the field to `_LessonPlayerBody`:

```dart
class _LessonPlayerBody extends ConsumerStatefulWidget {
  const _LessonPlayerBody({
    required this.unitId,
    required this.unit,
    required this.lesson,
    required this.learnerId,
    required this.learnerName,
    required this.masteryPolicy,
    required this.mediaByKey,
  });

  final String unitId;
  final Unit unit;
  final Lesson lesson;
  final int learnerId;
  final String? learnerName;
  final MasteryPolicy masteryPolicy;
  final Map<String, MediaSpecification> mediaByKey;
  ...
```

Track prior answers and pass the assembled context in `_LessonPlayerBodyState`:

Add the new field (`_previousAnswers`) to the state class's existing field list, and add the new tracking block as the *first* statement inside the existing `_handleSubmitted` method — every other line in the method (shown here in full) is unchanged from what's already in the file:

```dart
class _LessonPlayerBodyState extends ConsumerState<_LessonPlayerBody> {
  int? _currentIndex;
  ActivitySubmission? _lastSubmission;
  bool _finished = false;
  final List<ActivityCorrectness> _results = [];
  final Map<String, String> _previousAnswers = {};

  ...

  Future<void> _handleSubmitted(
    Activity activity,
    ActivitySubmission submission,
  ) async {
    if (submission.rawAnswerJson != null) {
      final decoded = jsonDecode(submission.rawAnswerJson!);
      if (decoded is String) _previousAnswers[activity.id] = decoded;
    }

    final evidenceSkill = resolveEvidenceSkill(activity, submission);

    await ref
        .read(activityAttemptRepositoryProvider)
        .recordAttempt(
          learnerId: widget.learnerId,
          activityId: activity.id,
          lessonId: widget.lesson.id,
          sessionType: 'lesson',
          mode: activity.mode,
          evidenceSkill: evidenceSkill,
          canDoIds: activity.canDo,
          rawAnswer: submission.rawAnswerJson,
          isCorrect: switch (submission.correctness) {
            ActivityCorrectness.correct => true,
            ActivityCorrectness.incorrect => false,
            ActivityCorrectness.notAutoGraded => null,
          },
          score: submission.score,
          wasFallback: submission.wasFallback,
        );

    await ref
        .read(unitLessonProgressRepositoryProvider)
        .recordLessonPosition(
          learnerId: widget.learnerId,
          lessonId: widget.lesson.id,
          unitId: widget.unitId,
          lastActivityId: activity.id,
        );

    _results.add(submission.correctness);
    ref.invalidate(
      lessonProgressForUnitProvider((
        learnerId: widget.learnerId,
        unitId: widget.unitId,
      )),
    );
    ref.invalidate(
      lessonAttemptsForUnitProvider((
        learnerId: widget.learnerId,
        unitId: widget.unitId,
      )),
    );
    ref.invalidate(allLessonProgressProvider);
    if (mounted) setState(() => _lastSubmission = submission);
  }
```

(The `...` above stands only for `_resolveStartIndex()` and `initState()`, which are untouched by this task — every line of `_handleSubmitted` itself is shown in full.)

Pass it when building the view:

```dart
              buildActivityView(
                key: ValueKey(activity.id),
                activity,
                onSubmitted: (submission) =>
                    _handleSubmitted(activity, submission),
                mediaByKey: widget.mediaByKey,
                evaluationContext: EvaluationContext(
                  profileName: widget.learnerName,
                  previousAnswers: Map.unmodifiable(_previousAnswers),
                ),
              ),
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/lesson_player/lesson_player_e2e_test.dart`
Expected: Still FAIL at this point — L3-A04's `evaluation` in the real bundle is still the legacy string (`letter-sequence-from-profile-name`), which Task 3's `EvaluationSpec.fromJson` intentionally parses to `null` until it's migrated. This is expected; Task 9 migrates it and turns this green. Confirm the failure reason is specifically "not-auto-graded, not correct" (i.e. everything wired correctly, just waiting on content) rather than a crash or a different error — if it's a crash, fix before proceeding.

- [ ] **Step 6: Run the full test suite for fallout**

Run: `flutter test`
Expected: Only the new test (Step 1) fails, for the reason confirmed in Step 5; everything else passes.

- [ ] **Step 7: Commit**

```bash
git add lib/features/activity_engine/presentation/activity_view_registry.dart lib/features/lesson_player/presentation/lesson_player_screen.dart test/features/lesson_player/lesson_player_e2e_test.dart
git commit -m "feat: thread EvaluationContext (profile name, prior answers) from the lesson player"
```

---

### Task 9: Content migration — A1-U0's 5 rubrics + the missing REGISTER_FOR_CLASS activity

**Files:**
- Modify: `assets/content/en/A1/a1-course-bundle.json`
- Test: `test/content/a1_u0_mastery_regression_test.dart` (new)

**Interfaces:**
- Consumes: everything from Tasks 1-8.
- Produces: A1-U0 is fully masterable; Task 8's e2e test (Step 5's known failure) turns green.

- [ ] **Step 1: Write the failing regression test**

Create `test/content/a1_u0_mastery_regression_test.dart`:

```dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/data/drift_activity_attempt_repository.dart';
import 'package:mohingo/features/progress/data/drift_unit_lesson_progress_repository.dart';
import 'package:mohingo/features/progress/domain/mastery_aggregation_service.dart';

/// Regression test for the reported bug: A1-U0 could never reach
/// "Mastered" because two of its four required objectives had no gradable
/// evidence at all. This proves the *content-completeness* half of the
/// fix — that enough real mastery-mode evidence now exists per objective
/// to satisfy `minimumEvidencePerRequiredObjective` — given every such
/// attempt is answered correctly. Individual evaluator correctness (does
/// "a l i" actually match "Ali"?) is covered separately by
/// evaluator_test.dart; this test would stay green even if every
/// evaluator were replaced, as long as the evidence *count* per objective
/// holds.
void main() {
  test(
    'A1-U0 is fully masterable once every mastery-mode activity is '
    'answered correctly',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final attemptRepository = DriftActivityAttemptRepository(db);
      final progressRepository = DriftUnitLessonProgressRepository(db);
      final service = MasteryAggregationService(
        attemptRepository: attemptRepository,
        progressRepository: progressRepository,
      );

      final learnerId = await db
          .into(db.learners)
          .insert(
            LearnersCompanion.insert(
              uuid: 'learner-1',
              createdAt: DateTime.utc(2026, 9, 7),
            ),
          );

      final json = File(
        'assets/content/en/A1/a1-course-bundle.json',
      ).readAsStringSync();
      final index = CourseContentIndex.build(CourseBundleParser.parse(json));
      final unit = index.unitsById['A1-U0']!;

      for (final lesson in unit.lessons) {
        for (final activity in lesson.activities) {
          if (activity.mode != ActivityMode.mastery) continue;
          await attemptRepository.recordAttempt(
            learnerId: learnerId,
            activityId: activity.id,
            lessonId: lesson.id,
            sessionType: 'lesson',
            mode: activity.mode,
            evidenceSkill: activity.skill,
            canDoIds: activity.canDo,
            isCorrect: true,
            score: 1.0,
          );
        }
      }

      final result = await service.evaluateUnit(
        learnerId: learnerId,
        unit: unit,
        masteryPolicy: index.bundle.domain.masteryPolicy,
      );

      expect(
        result.isMastered,
        isTrue,
        reason: 'unmastered objectives: ${result.unmasteredObjectiveIds}',
      );
    },
  );

  test(
    "A1-U0's migrated evaluation rubrics parse to real structured specs, "
    'not the legacy-string null fallback',
    () async {
      final json = File(
        'assets/content/en/A1/a1-course-bundle.json',
      ).readAsStringSync();
      final index = CourseContentIndex.build(CourseBundleParser.parse(json));
      final l3a04 = index.lessonsById['A1-U0-L3']!.activities.firstWhere(
        (a) => a.id == 'A1-U0-L3-A04',
      );
      expect((l3a04 as dynamic).evaluation, isNotNull);
    },
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/content/a1_u0_mastery_regression_test.dart`
Expected: FAIL — `result.isMastered` is `false` (REGISTER_FOR_CLASS has only one piece of mastery evidence today; the second test also fails since `evaluation` is still the legacy string, parsing to `null`).

- [ ] **Step 3: Migrate the 5 rubric strings**

In `assets/content/en/A1/a1-course-bundle.json`, make these 5 edits (exact existing lines, found via the activity ids below):

`A1-U0-L3-A04`:
```json
"evaluation": "letter-sequence-from-profile-name",
```
→
```json
"evaluation": {
  "type": "letterSequence",
  "reference": "profileName"
},
```

`A1-U0-L4-A03`:
```json
"evaluation": "valid-age-response",
```
→
```json
"evaluation": {
  "type": "numericRange",
  "min": 1,
  "max": 120
},
```

`A1-U0-L5-A01`:
```json
"evaluation": "non-empty-name",
```
→
```json
"evaluation": {
  "type": "nonEmpty"
},
```

`A1-U0-L5-A02`:
```json
"evaluation": "letter-sequence-from-previous-answer",
```
→
```json
"evaluation": {
  "type": "letterSequence",
  "reference": "previousAnswer:A1-U0-L5-A01"
},
```

`A1-U0-L5-A03`:
```json
"evaluation": "valid-age-response",
```
→
```json
"evaluation": {
  "type": "numericRange",
  "min": 1,
  "max": 120
},
```

- [ ] **Step 4: Add the missing second `REGISTER_FOR_CLASS` mastery activity**

In `assets/content/en/A1/a1-course-bundle.json`, in `A1-U0-L5`'s `activities` array, immediately after `A1-U0-L5-A04` (the last activity in that lesson today), add:

```json
{
  "id": "A1-U0-L5-A05",
  "lessonId": "A1-U0-L5",
  "type": "speak",
  "mode": "mastery",
  "skill": "spokenInteraction",
  "canDo": [
    "A1.U0.INTERACTION.REGISTER_FOR_CLASS"
  ],
  "prompt": "Say hello and ask to join the English class.",
  "promptAr": "قل مرحباً واطلب الانضمام إلى صف الإنجليزية.",
  "accepted": [],
  "evaluation": {
    "type": "nonEmpty"
  },
  "fallbackSkill": "writing"
}
```

(Remember to add a trailing comma after `A1-U0-L5-A04`'s closing `}` now that it's no longer the last array element.)

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/content/a1_u0_mastery_regression_test.dart`
Expected: PASS

- [ ] **Step 6: Run Task 8's e2e test to confirm it's now green too**

Run: `flutter test test/features/lesson_player/lesson_player_e2e_test.dart`
Expected: PASS (this is the test whose failure was explicitly expected and confirmed in Task 8 Step 5 — it should turn green now that L3-A04's rubric is migrated).

- [ ] **Step 7: Run the full test suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add assets/content/en/A1/a1-course-bundle.json test/content/a1_u0_mastery_regression_test.dart
git commit -m "content: migrate A1-U0's 5 evaluation rubrics; add the missing REGISTER_FOR_CLASS evidence activity"
```

---

### Task 10: Documentation updates

**Files:**
- Modify: `docs/DATA_MODEL.md`

- [ ] **Step 1: Update the Activity section**

In `docs/DATA_MODEL.md`, replace the `### Activity` paragraph's rubric mention:

Old: `...`evaluation`/`wordGuide` for `write`)...`

New: `...`evaluation`/`wordGuide` for `write`; `evaluation` is a structured `{type, ...}` object — one of `nonEmpty`, `numericRange`, `letterSequence`, `keywordChecklist` — parsed by `EvaluationSpec.fromJson`, or `null` for content not yet migrated off the legacy opaque rubric-name string; see docs/superpowers/specs/2026-09-07-offline-answer-evaluation-design.md)...`

- [ ] **Step 2: Document `Learners.name`**

Find `docs/DATA_MODEL.md`'s description of the `Learners`/`Learner` table (search for "Learner") and add a line noting the new nullable `name` column and what it's for:

```markdown
`Learners.name` (nullable) — the learner's own name, set via Settings; used only by the `letterSequence`/`profileName` evaluation reference (see the Activity section above), never required for anything else.
```

- [ ] **Step 3: Bump the doc's Last verified line**

Update `docs/DATA_MODEL.md`'s top-of-file "Last verified" line (if it has one, matching this project's convention from `CLAUDE.md`) to today's date and this change.

- [ ] **Step 4: Commit**

```bash
git add docs/DATA_MODEL.md
git commit -m "docs: document the structured EvaluationSpec shape and Learners.name"
```
