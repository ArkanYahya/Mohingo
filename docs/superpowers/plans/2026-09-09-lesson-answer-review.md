# Lesson Answer Review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reopening an already-finished lesson from the Learn tab shows a read-only walkthrough of the learner's latest answer to every activity (correct/incorrect, correct answer where applicable) instead of dropping them back into a blank, fully live lesson — with an explicit "Practice again" button as the only way back into the real (replaying, evidence-recording) player.

**Architecture:** Every answerable activity view already has a submitted (read-only, banner-shown) rendering state, reached today only through live interaction. Add one new optional constructor parameter, `reviewAttempt: ActivityAttempt?`, to each of the 7 answerable views (`ChoiceActivityView`, `GapActivityView`, `MatchActivityView`, `OrderActivityView`, `FormActivityView`, `WriteActivityView`, `SpeakActivityView`); when non-null, the view seeds its internal state from the recorded `rawAnswer`/`isCorrect`/`score` at `initState` and renders straight into its existing submitted branch — no live interaction offered, `evaluate()` never called, `onSubmitted` never invoked. A new `LessonReviewScreen` loads the lesson's attempts, reduces to latest-per-activity, and renders each activity via `buildActivityView(..., reviewAttempt: ...)`. `UnitOverviewScreen` routes a finished lesson's tap to this new screen instead of `LessonPlayerScreen`; an unfinished one is unaffected.

**Tech Stack:** Flutter/Dart, Riverpod (plain `FutureProvider`/`FutureProvider.family` for Drift-`DataClass`-returning providers — `riverpod_generator` fails on those), Drift/SQLite (`ActivityAttemptRepository.attemptsForLessons`, already exists — no new repository method), go_router.

**Spec:** `docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md`

## Global Constraints

- Learn tab only. The Tests tab (Final Mission, Final Assessment, Placement Test) is explicitly out of scope — do not touch `final_assessment_screen.dart`, `final_mission_screen.dart`, `placement_test_screen.dart`, or `tests_home_screen.dart`.
- `ActivityAttemptRepository.recordAttempt` stays insert-only and untouched. Review mode never calls `recordAttempt`, `refreshUnitProgress`, or any provider invalidation that implies a new attempt was recorded.
- Review mode never calls `evaluate()` or otherwise recomputes correctness/score. It always trusts the recorded `ActivityAttempt.isCorrect`/`.score` verbatim, even when they contradict what live grading of the same `rawAnswer` would produce (deliberately covered by tests below — data can be messy, e.g. a rubric changed after the attempt).
- Latest-attempt-only. No multi-attempt history UI — one attempt per activity id, the most recent by `attemptedAt`.
- Every new constructor/function parameter this plan adds (`reviewAttempt` on 7 views, on `buildActivityView`) is optional with a `null`/default value, so every existing call site and every existing test is unaffected. Confirm `flutter analyze` and the full existing suite stay green after each task.
- All new user-facing copy is bilingual: native English in `lib/l10n/app_en.arb`, native Arabic (not machine-translated) in `lib/l10n/app_ar.arb`, run through `flutter gen-l10n` after editing either file.
- `dart format --set-exit-if-changed .` and `flutter analyze` must be clean at the end of every task.

---

## Task 1: `ChoiceActivityView` gains `reviewAttempt`

**Files:**
- Modify: `lib/features/activity_engine/presentation/views/choice_activity_view.dart`
- Test: `test/features/activity_engine/choice_activity_view_test.dart`

**Interfaces:**
- Produces: `ChoiceActivityView.audioChoice({..., ActivityAttempt? reviewAttempt})` and `.textChoice({..., ActivityAttempt? reviewAttempt})` — both default `null`. `ActivityAttempt` from `package:mohingo/data/local/database.dart`.

- [ ] **Step 1: Write the failing test**

Add to `test/features/activity_engine/choice_activity_view_test.dart` (add `import 'dart:convert';` and `import 'package:mohingo/data/local/database.dart' show ActivityAttempt;` at the top alongside the existing imports):

```dart
  group('review mode (reviewAttempt)', () {
    testWidgets(
      'renders the recorded result read-only, trusting isCorrect verbatim '
      'even when it contradicts what live re-grading of the same answer '
      'would produce — no live interaction, no submit button',
      (tester) async {
        await tester.pumpActivityView(
          ChoiceActivityView.audioChoice(
            activity: _audioChoice(),
            onSubmitted: (_) {},
            reviewAttempt: ActivityAttempt(
              id: 1,
              uuid: 'attempt-1',
              learnerId: 1,
              activityId: 'A1-U1-L1-A01',
              sessionType: 'lesson',
              mode: 'mastery',
              evidenceSkill: 'listening',
              rawAnswer: jsonEncode('Omar'), // the actually-correct answer
              isCorrect: false, // deliberately recorded wrong
              score: 0.0,
              wasFallback: false,
              attemptedAt: DateTime.utc(2026, 9, 9),
              updatedAt: DateTime.utc(2026, 9, 9),
            ),
          ),
        );

        // Trusts the recorded isCorrect, never re-evaluates "Omar" == answer.
        expect(find.byIcon(Icons.cancel), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsNothing);
        expect(find.byType(FilledButton), findsNothing);
      },
    );
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/activity_engine/choice_activity_view_test.dart`
Expected: FAIL — `reviewAttempt` is not a named parameter of `ChoiceActivityView.audioChoice`.

- [ ] **Step 3: Implement**

In `lib/features/activity_engine/presentation/views/choice_activity_view.dart`, add the import:

```dart
import '../../../../data/local/database.dart' show ActivityAttempt;
```

Change both named constructors and the field list:

```dart
class ChoiceActivityView extends StatefulWidget {
  ChoiceActivityView.audioChoice({
    required AudioChoiceActivity activity,
    required this.onSubmitted,
    this.mediaByKey = const {},
    this.reviewAttempt,
    super.key,
  }) : prompt = activity.prompt,
       promptAr = activity.promptAr,
       options = activity.options,
       answer = activity.answer,
       audioTranscript = activity.audioTranscript,
       isMediaOptions = activity.raw['optionMode'] == 'media';

  ChoiceActivityView.textChoice({
    required TextChoiceActivity activity,
    required this.onSubmitted,
    this.mediaByKey = const {},
    this.reviewAttempt,
    super.key,
  }) : prompt = activity.prompt,
       promptAr = activity.promptAr,
       options = activity.options,
       answer = activity.answer,
       audioTranscript = null,
       isMediaOptions = activity.raw['optionMode'] == 'media';

  final String prompt;
  final String? promptAr;
  final List<String> options;
  final String answer;
  final String? audioTranscript;
  final bool isMediaOptions;
  final Map<String, MediaSpecification> mediaByKey;
  final OnActivitySubmitted onSubmitted;

  /// When non-null, this view renders read-only straight into its submitted
  /// state, seeded from this recorded attempt — never live-interactive, and
  /// [reviewAttempt].isCorrect/.score are trusted verbatim, never
  /// recomputed. See docs/superpowers/specs/
  /// 2026-09-09-lesson-answer-review-design.md.
  final ActivityAttempt? reviewAttempt;

  @override
  State<ChoiceActivityView> createState() => _ChoiceActivityViewState();
}
```

Add `initState` and a decode helper to `_ChoiceActivityViewState`:

```dart
class _ChoiceActivityViewState extends State<ChoiceActivityView> {
  String? _selected;
  ActivitySubmission? _submission;

  @override
  void initState() {
    super.initState();
    final reviewAttempt = widget.reviewAttempt;
    if (reviewAttempt == null) return;
    _selected = _decodeSelection(reviewAttempt.rawAnswer);
    _submission = ActivitySubmission(
      correctness: reviewAttempt.isCorrect == true
          ? ActivityCorrectness.correct
          : ActivityCorrectness.incorrect,
      score: reviewAttempt.score,
      rawAnswerJson: reviewAttempt.rawAnswer,
    );
  }

  String? _decodeSelection(String? rawAnswer) {
    if (rawAnswer == null) return null;
    try {
      final decoded = jsonDecode(rawAnswer);
      return decoded is String ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  void _submit() {
```

(the rest of `_submit` and `build` are unchanged).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/activity_engine/choice_activity_view_test.dart`
Expected: PASS, all tests in the file green.

- [ ] **Step 5: Commit**

```bash
git add lib/features/activity_engine/presentation/views/choice_activity_view.dart test/features/activity_engine/choice_activity_view_test.dart
git commit -m "$(cat <<'EOF'
feat: add read-only review mode to ChoiceActivityView

Part of the Lesson Answer Review feature — see
docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: `GapActivityView` gains `reviewAttempt`

**Files:**
- Modify: `lib/features/activity_engine/presentation/views/gap_activity_view.dart`
- Test: `test/features/activity_engine/gap_activity_view_test.dart`

**Interfaces:**
- Produces: `GapActivityView({..., ActivityAttempt? reviewAttempt})`, default `null`.

- [ ] **Step 1: Write the failing test**

Add to `test/features/activity_engine/gap_activity_view_test.dart` (add `import 'dart:convert';` and `import 'package:mohingo/data/local/database.dart' show ActivityAttempt;`):

```dart
  group('review mode (reviewAttempt)', () {
    testWidgets(
      'renders the recorded result read-only, trusting isCorrect verbatim '
      'even when it contradicts what live re-grading of the same answer '
      'would produce — no submit button, gap filled from the record',
      (tester) async {
        await tester.pumpActivityView(
          GapActivityView(
            activity: _gapActivity(),
            onSubmitted: (_) {},
            reviewAttempt: ActivityAttempt(
              id: 1,
              uuid: 'attempt-1',
              learnerId: 1,
              activityId: 'A1-U2-L2-A02',
              sessionType: 'lesson',
              mode: 'practice',
              evidenceSkill: 'reading',
              rawAnswer: jsonEncode('has'), // the actually-correct answer
              isCorrect: false, // deliberately recorded wrong
              score: 0.0,
              wasFallback: false,
              attemptedAt: DateTime.utc(2026, 9, 9),
              updatedAt: DateTime.utc(2026, 9, 9),
            ),
          ),
        );

        expect(find.text('She has one sister.'), findsOneWidget);
        expect(find.byIcon(Icons.cancel), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsNothing);
        expect(find.byType(FilledButton), findsNothing);
      },
    );
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/activity_engine/gap_activity_view_test.dart`
Expected: FAIL — `reviewAttempt` is not a named parameter of `GapActivityView`.

- [ ] **Step 3: Implement**

In `lib/features/activity_engine/presentation/views/gap_activity_view.dart`, add the import:

```dart
import '../../../../data/local/database.dart' show ActivityAttempt;
```

Update the widget:

```dart
class GapActivityView extends StatefulWidget {
  const GapActivityView({
    required this.activity,
    required this.onSubmitted,
    this.reviewAttempt,
    super.key,
  });

  final GapActivity activity;
  final OnActivitySubmitted onSubmitted;

  /// When non-null, this view renders read-only straight into its submitted
  /// state, seeded from this recorded attempt — never live-interactive, and
  /// [reviewAttempt].isCorrect/.score are trusted verbatim, never
  /// recomputed. See docs/superpowers/specs/
  /// 2026-09-09-lesson-answer-review-design.md.
  final ActivityAttempt? reviewAttempt;

  @override
  State<GapActivityView> createState() => _GapActivityViewState();
}

class _GapActivityViewState extends State<GapActivityView> {
  String? _selected;
  ActivitySubmission? _submission;

  @override
  void initState() {
    super.initState();
    final reviewAttempt = widget.reviewAttempt;
    if (reviewAttempt == null) return;
    _selected = _decodeSelection(reviewAttempt.rawAnswer);
    _submission = ActivitySubmission(
      correctness: reviewAttempt.isCorrect == true
          ? ActivityCorrectness.correct
          : ActivityCorrectness.incorrect,
      score: reviewAttempt.score,
      rawAnswerJson: reviewAttempt.rawAnswer,
    );
  }

  String? _decodeSelection(String? rawAnswer) {
    if (rawAnswer == null) return null;
    try {
      final decoded = jsonDecode(rawAnswer);
      return decoded is String ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  void _submit() {
```

(the rest of `_submit` and `build` are unchanged).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/activity_engine/gap_activity_view_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/activity_engine/presentation/views/gap_activity_view.dart test/features/activity_engine/gap_activity_view_test.dart
git commit -m "$(cat <<'EOF'
feat: add read-only review mode to GapActivityView

Part of the Lesson Answer Review feature — see
docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: `MatchActivityView` gains `reviewAttempt`

**Files:**
- Modify: `lib/features/activity_engine/presentation/views/match_activity_view.dart`
- Test: `test/features/activity_engine/match_activity_view_test.dart`

**Interfaces:**
- Produces: `MatchActivityView({..., ActivityAttempt? reviewAttempt})`, default `null`.

- [ ] **Step 1: Write the failing test**

Add to `test/features/activity_engine/match_activity_view_test.dart` (add `import 'dart:convert';` and `import 'package:mohingo/data/local/database.dart' show ActivityAttempt;`):

```dart
  group('review mode (reviewAttempt)', () {
    testWidgets(
      'renders the recorded result read-only, trusting isCorrect verbatim '
      'even when every pair in the record is actually correct',
      (tester) async {
        await tester.pumpActivityView(
          MatchActivityView(
            activity: _matchActivity(),
            onSubmitted: (_) {},
            reviewAttempt: ActivityAttempt(
              id: 1,
              uuid: 'attempt-1',
              learnerId: 1,
              activityId: 'A1-U2-L1-A02',
              sessionType: 'lesson',
              mode: 'practice',
              evidenceSkill: 'reading',
              rawAnswer: jsonEncode({
                'Lina': 'mother',
                'Sami': 'father',
              }), // every pair actually correct
              isCorrect: false, // deliberately recorded wrong
              score: 0.0,
              wasFallback: false,
              attemptedAt: DateTime.utc(2026, 9, 9),
              updatedAt: DateTime.utc(2026, 9, 9),
            ),
          ),
        );

        expect(find.byIcon(Icons.cancel), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsNothing);
        expect(find.byType(FilledButton), findsNothing);
      },
    );
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/activity_engine/match_activity_view_test.dart`
Expected: FAIL — `reviewAttempt` is not a named parameter of `MatchActivityView`.

- [ ] **Step 3: Implement**

In `lib/features/activity_engine/presentation/views/match_activity_view.dart`, add the import:

```dart
import '../../../../data/local/database.dart' show ActivityAttempt;
```

Update the widget:

```dart
class MatchActivityView extends StatefulWidget {
  const MatchActivityView({
    required this.activity,
    required this.onSubmitted,
    this.reviewAttempt,
    super.key,
  });

  final MatchActivity activity;
  final OnActivitySubmitted onSubmitted;

  /// When non-null, this view renders read-only straight into its submitted
  /// state, seeded from this recorded attempt — never live-interactive, and
  /// [reviewAttempt].isCorrect/.score are trusted verbatim, never
  /// recomputed. See docs/superpowers/specs/
  /// 2026-09-09-lesson-answer-review-design.md.
  final ActivityAttempt? reviewAttempt;

  @override
  State<MatchActivityView> createState() => _MatchActivityViewState();
}

class _MatchActivityViewState extends State<MatchActivityView> {
  late final List<String> _rightShuffled =
      widget.activity.pairs.map((pair) => pair[1]).toList()
        ..shuffle(Random(widget.activity.pairs.length));

  final Map<String, String> _userMatches = {}; // left -> right
  String? _pendingLeft;
  ActivitySubmission? _submission;

  @override
  void initState() {
    super.initState();
    final reviewAttempt = widget.reviewAttempt;
    if (reviewAttempt == null) return;
    final decoded = _decodeMatches(reviewAttempt.rawAnswer);
    if (decoded != null) _userMatches.addAll(decoded);
    _submission = ActivitySubmission(
      correctness: reviewAttempt.isCorrect == true
          ? ActivityCorrectness.correct
          : ActivityCorrectness.incorrect,
      score: reviewAttempt.score,
      rawAnswerJson: reviewAttempt.rawAnswer,
    );
  }

  Map<String, String>? _decodeMatches(String? rawAnswer) {
    if (rawAnswer == null) return null;
    try {
      final decoded = jsonDecode(rawAnswer);
      return decoded is Map ? Map<String, String>.from(decoded) : null;
    } catch (_) {
      // Catches both malformed JSON (FormatException) and a syntactically
      // valid JSON value in the wrong shape, e.g. a Map with non-String
      // values (TypeError from the cast above) — either way, a corrupted
      // or legacy row degrades to "no prior selection" rather than
      // crashing initState().
      return null;
    }
  }

  bool get _isComplete => _userMatches.length == widget.activity.pairs.length;
```

(the rest of the class is unchanged).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/activity_engine/match_activity_view_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/activity_engine/presentation/views/match_activity_view.dart test/features/activity_engine/match_activity_view_test.dart
git commit -m "$(cat <<'EOF'
feat: add read-only review mode to MatchActivityView

Part of the Lesson Answer Review feature — see
docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: `OrderActivityView` gains `reviewAttempt`

**Files:**
- Modify: `lib/features/activity_engine/presentation/views/order_activity_view.dart`
- Test: `test/features/activity_engine/order_activity_view_test.dart`

**Interfaces:**
- Produces: `OrderActivityView({..., ActivityAttempt? reviewAttempt})`, default `null`.

- [ ] **Step 1: Write the failing test**

Add to `test/features/activity_engine/order_activity_view_test.dart` (add `import 'dart:convert';` and `import 'package:mohingo/data/local/database.dart' show ActivityAttempt;`):

```dart
  group('review mode (reviewAttempt)', () {
    testWidgets(
      'renders the recorded order read-only, trusting isCorrect verbatim '
      'even when the recorded order is actually correct',
      (tester) async {
        await tester.pumpActivityView(
          OrderActivityView(
            activity: _orderActivity(),
            onSubmitted: (_) {},
            reviewAttempt: ActivityAttempt(
              id: 1,
              uuid: 'attempt-1',
              learnerId: 1,
              activityId: 'A1-U2-L1-A03',
              sessionType: 'lesson',
              mode: 'practice',
              evidenceSkill: 'reading',
              rawAnswer: jsonEncode(
                ['This', 'is', 'my', 'mother'],
              ), // the actually-correct order
              isCorrect: false, // deliberately recorded wrong
              score: 0.0,
              wasFallback: false,
              attemptedAt: DateTime.utc(2026, 9, 9),
              updatedAt: DateTime.utc(2026, 9, 9),
            ),
          ),
        );

        for (final token in ['This', 'is', 'my', 'mother']) {
          expect(find.text(token), findsOneWidget);
        }
        expect(find.byIcon(Icons.cancel), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsNothing);
        expect(find.byType(FilledButton), findsNothing);
      },
    );
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/activity_engine/order_activity_view_test.dart`
Expected: FAIL — `reviewAttempt` is not a named parameter of `OrderActivityView`.

- [ ] **Step 3: Implement**

In `lib/features/activity_engine/presentation/views/order_activity_view.dart`, add the import:

```dart
import '../../../../data/local/database.dart' show ActivityAttempt;
```

Update the widget:

```dart
class OrderActivityView extends StatefulWidget {
  const OrderActivityView({
    required this.activity,
    required this.onSubmitted,
    this.reviewAttempt,
    super.key,
  });

  final OrderActivity activity;
  final OnActivitySubmitted onSubmitted;

  /// When non-null, this view renders read-only straight into its submitted
  /// state, seeded from this recorded attempt — never live-interactive, and
  /// [reviewAttempt].isCorrect/.score are trusted verbatim, never
  /// recomputed. See docs/superpowers/specs/
  /// 2026-09-09-lesson-answer-review-design.md.
  final ActivityAttempt? reviewAttempt;

  @override
  State<OrderActivityView> createState() => _OrderActivityViewState();
}

class _OrderActivityViewState extends State<OrderActivityView> {
  final List<String> _placed = [];
  ActivitySubmission? _submission;

  @override
  void initState() {
    super.initState();
    final reviewAttempt = widget.reviewAttempt;
    if (reviewAttempt == null) return;
    final decoded = _decodeOrder(reviewAttempt.rawAnswer);
    if (decoded != null) _placed.addAll(decoded);
    _submission = ActivitySubmission(
      correctness: reviewAttempt.isCorrect == true
          ? ActivityCorrectness.correct
          : ActivityCorrectness.incorrect,
      score: reviewAttempt.score,
      rawAnswerJson: reviewAttempt.rawAnswer,
    );
  }

  List<String>? _decodeOrder(String? rawAnswer) {
    if (rawAnswer == null) return null;
    try {
      final decoded = jsonDecode(rawAnswer);
      return decoded is List ? List<String>.from(decoded) : null;
    } catch (_) {
      // Catches both malformed JSON (FormatException) and a syntactically
      // valid JSON value in the wrong shape, e.g. a List with non-String
      // elements (TypeError from the cast above) — either way, a corrupted
      // or legacy row degrades to "nothing placed" rather than crashing
      // initState().
      return null;
    }
  }

  List<String> get _remaining {
```

(the rest of the class is unchanged).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/activity_engine/order_activity_view_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/activity_engine/presentation/views/order_activity_view.dart test/features/activity_engine/order_activity_view_test.dart
git commit -m "$(cat <<'EOF'
feat: add read-only review mode to OrderActivityView

Part of the Lesson Answer Review feature — see
docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: `FormActivityView` gains `reviewAttempt`

**Files:**
- Modify: `lib/features/activity_engine/presentation/views/form_activity_view.dart`
- Test: `test/features/activity_engine/form_activity_view_test.dart`

**Interfaces:**
- Produces: `FormActivityView({..., ActivityAttempt? reviewAttempt})`, default `null`. Always renders `notAutoGraded` — forms are never auto-graded, in review or live.

- [ ] **Step 1: Write the failing test**

Add to `test/features/activity_engine/form_activity_view_test.dart` (add `import 'dart:convert';` and `import 'package:mohingo/data/local/database.dart' show ActivityAttempt;`):

```dart
  group('review mode (reviewAttempt)', () {
    testWidgets(
      'pre-fills the recorded field values, disabled, with the neutral '
      'saved-for-review treatment — no submit button',
      (tester) async {
        await tester.pumpActivityView(
          FormActivityView(
            activity: _formActivity(),
            onSubmitted: (_) {},
            reviewAttempt: ActivityAttempt(
              id: 1,
              uuid: 'attempt-1',
              learnerId: 1,
              activityId: 'A1-U2-L7-A01',
              sessionType: 'lesson',
              mode: 'mastery',
              evidenceSkill: 'writing',
              rawAnswer: jsonEncode({'name': 'Lina', 'relationship': 'mother'}),
              wasFallback: false,
              attemptedAt: DateTime.utc(2026, 9, 9),
              updatedAt: DateTime.utc(2026, 9, 9),
            ),
          ),
        );

        expect(find.text('Lina'), findsOneWidget);
        expect(find.text('mother'), findsOneWidget);
        expect(find.byType(FilledButton), findsNothing);
        expect(find.byIcon(Icons.hourglass_top), findsOneWidget);

        final nameField = tester.widget<TextField>(
          find.byType(TextField).first,
        );
        expect(nameField.enabled, isFalse);
      },
    );
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/activity_engine/form_activity_view_test.dart`
Expected: FAIL — `reviewAttempt` is not a named parameter of `FormActivityView`.

- [ ] **Step 3: Implement**

In `lib/features/activity_engine/presentation/views/form_activity_view.dart`, add the import:

```dart
import '../../../../data/local/database.dart' show ActivityAttempt;
```

Update the widget:

```dart
class FormActivityView extends StatefulWidget {
  const FormActivityView({
    required this.activity,
    required this.onSubmitted,
    this.reviewAttempt,
    super.key,
  });

  final FormActivity activity;
  final OnActivitySubmitted onSubmitted;

  /// When non-null, this view renders read-only straight into its submitted
  /// state, pre-filled from this recorded attempt — never live-editable.
  /// Always the neutral `notAutoGraded` treatment, exactly like a live
  /// submission — forms are never auto-graded. See docs/superpowers/specs/
  /// 2026-09-09-lesson-answer-review-design.md.
  final ActivityAttempt? reviewAttempt;

  @override
  State<FormActivityView> createState() => _FormActivityViewState();
}

class _FormActivityViewState extends State<FormActivityView> {
  late final Map<String, String> _reviewAnswers =
      _decodeAnswers(widget.reviewAttempt?.rawAnswer) ?? const {};

  late final Map<String, TextEditingController> _controllers = {
    for (final field in widget.activity.fields)
      field: TextEditingController(text: _reviewAnswers[field] ?? ''),
  };
  ActivitySubmission? _submission;

  @override
  void initState() {
    super.initState();
    final reviewAttempt = widget.reviewAttempt;
    if (reviewAttempt == null) return;
    _submission = ActivitySubmission(
      correctness: ActivityCorrectness.notAutoGraded,
      rawAnswerJson: reviewAttempt.rawAnswer,
    );
  }

  Map<String, String>? _decodeAnswers(String? rawAnswer) {
    if (rawAnswer == null) return null;
    try {
      final decoded = jsonDecode(rawAnswer);
      return decoded is Map ? Map<String, String>.from(decoded) : null;
    } catch (_) {
      // Catches both malformed JSON (FormatException) and a syntactically
      // valid JSON value in the wrong shape, e.g. a Map with non-String
      // values (TypeError from the cast above) — either way, a corrupted
      // or legacy row degrades to "no saved values" rather than crashing
      // initState().
      return null;
    }
  }

  bool get _allFilled =>
```

(the rest of the class is unchanged).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/activity_engine/form_activity_view_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/activity_engine/presentation/views/form_activity_view.dart test/features/activity_engine/form_activity_view_test.dart
git commit -m "$(cat <<'EOF'
feat: add read-only review mode to FormActivityView

Part of the Lesson Answer Review feature — see
docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: `WriteActivityView` gains `reviewAttempt`

**Files:**
- Modify: `lib/features/activity_engine/presentation/views/write_activity_view.dart`
- Test: `test/features/activity_engine/write_activity_view_test.dart`

**Interfaces:**
- Produces: `WriteActivityView({..., ActivityAttempt? reviewAttempt})`, default `null`. `ActivityAttempt` is already imported in this file.

- [ ] **Step 1: Write the failing test**

Add to `test/features/activity_engine/write_activity_view_test.dart` (add `import 'dart:convert';` alongside the existing imports — `ActivityAttempt` needs no new import here, `package:mohingo/data/local/database.dart` isn't currently imported in this test file, so add `import 'package:mohingo/data/local/database.dart' show ActivityAttempt;` too):

```dart
  group('review mode (reviewAttempt)', () {
    testWidgets(
      'pre-fills the recorded text, disabled, trusting isCorrect verbatim '
      'even when it contradicts what live re-grading of the same answer '
      'would produce — no submit button, no online-refinement watch',
      (tester) async {
        await tester.pumpActivityView(
          WriteActivityView(
            activity: _closedFormWrite(),
            learnerId: 1,
            onSubmitted: (_) {},
            reviewAttempt: ActivityAttempt(
              id: 1,
              uuid: 'attempt-1',
              learnerId: 1,
              activityId: 'A1-U6-L1-A04',
              sessionType: 'lesson',
              mode: 'mastery',
              evidenceSkill: 'writing',
              rawAnswer: jsonEncode(
                'One coffee, please.',
              ), // the actually-accepted answer
              isCorrect: false, // deliberately recorded wrong
              score: 0.0,
              wasFallback: false,
              attemptedAt: DateTime.utc(2026, 9, 9),
              updatedAt: DateTime.utc(2026, 9, 9),
            ),
          ),
        );

        expect(find.byIcon(Icons.cancel), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsNothing);
        expect(find.byType(FilledButton), findsNothing);

        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.enabled, isFalse);
        expect(field.controller!.text, 'One coffee, please.');
      },
    );
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/activity_engine/write_activity_view_test.dart`
Expected: FAIL — `reviewAttempt` is not a named parameter of `WriteActivityView`.

- [ ] **Step 3: Implement**

In `lib/features/activity_engine/presentation/views/write_activity_view.dart`, update the constructor and field list:

```dart
class WriteActivityView extends ConsumerStatefulWidget {
  const WriteActivityView({
    required this.activity,
    required this.learnerId,
    required this.onSubmitted,
    this.evaluationContext = const EvaluationContext.empty(),
    this.reviewAttempt,
    super.key,
  });

  final WriteActivity activity;
  final int learnerId;
  final OnActivitySubmitted onSubmitted;
  final EvaluationContext evaluationContext;

  /// When non-null, this view renders read-only straight into its submitted
  /// state, pre-filled from this recorded attempt — never live-interactive,
  /// and [reviewAttempt].isCorrect/.score are trusted verbatim, never
  /// recomputed (and never sent through the online-refinement queue). See
  /// docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md.
  final ActivityAttempt? reviewAttempt;

  @override
  ConsumerState<WriteActivityView> createState() => _WriteActivityViewState();
}
```

Add `initState` and a decode helper to `_WriteActivityViewState`, right after the `_truncatedToSeconds` method and before `_submit`:

```dart
  DateTime _truncatedToSeconds(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);

  @override
  void initState() {
    super.initState();
    final reviewAttempt = widget.reviewAttempt;
    if (reviewAttempt == null) return;
    final decoded = _decodeText(reviewAttempt.rawAnswer);
    if (decoded != null) _controller.text = decoded;
    _submission = ActivitySubmission(
      correctness: reviewAttempt.isCorrect == true
          ? ActivityCorrectness.correct
          : ActivityCorrectness.incorrect,
      score: reviewAttempt.score,
      rawAnswerJson: reviewAttempt.rawAnswer,
    );
  }

  String? _decodeText(String? rawAnswer) {
    if (rawAnswer == null) return null;
    try {
      final decoded = jsonDecode(rawAnswer);
      return decoded is String ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  void _submit() {
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/activity_engine/write_activity_view_test.dart`
Expected: PASS, including every pre-existing test in the file (`_pendingSince`/`displaySubmission` logic is untouched — `reviewAttempt`-seeded submissions always have `pendingOnlineRefinement: false`, so `build()`'s existing branch never watches `latestAttemptProvider` for them).

- [ ] **Step 5: Commit**

```bash
git add lib/features/activity_engine/presentation/views/write_activity_view.dart test/features/activity_engine/write_activity_view_test.dart
git commit -m "$(cat <<'EOF'
feat: add read-only review mode to WriteActivityView

Part of the Lesson Answer Review feature — see
docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: `SpeakActivityView` gains `reviewAttempt`

**Files:**
- Modify: `lib/features/activity_engine/presentation/views/speak_activity_view.dart`
- Test: `test/features/activity_engine/speak_activity_view_test.dart`

**Interfaces:**
- Produces: `SpeakActivityView({..., ActivityAttempt? reviewAttempt})`, default `null`. `ActivityAttempt` is already imported in this file. In review mode, skips `_checkCapability()` entirely — no speech-provider overrides needed in the test.

- [ ] **Step 1: Write the failing test**

Add to `test/features/activity_engine/speak_activity_view_test.dart` (add `import 'dart:convert';` alongside the existing imports):

```dart
  group('review mode (reviewAttempt)', () {
    testWidgets(
      'renders the recorded transcript read-only, trusting isCorrect '
      'verbatim even when it contradicts what live re-grading of the same '
      'answer would produce — no capability check, no mic/typed UI',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(
                body: SpeakActivityView(
                  activity: _speakActivity(),
                  learnerId: 1,
                  onSubmitted: (_) {},
                  reviewAttempt: ActivityAttempt(
                    id: 1,
                    uuid: 'attempt-1',
                    learnerId: 1,
                    activityId: 'A1-U0-L1-A04',
                    sessionType: 'lesson',
                    mode: 'mastery',
                    evidenceSkill: 'writing',
                    rawAnswer: jsonEncode(
                      'Thank you.',
                    ), // the actually-accepted answer
                    isCorrect: false, // deliberately recorded wrong
                    score: 0.0,
                    wasFallback: true,
                    attemptedAt: DateTime.utc(2026, 9, 9),
                    updatedAt: DateTime.utc(2026, 9, 9),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Thank you.'), findsOneWidget);
        expect(find.byIcon(Icons.cancel), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsNothing);
        // No capability check ever ran: no spinner, no mic/typed controls.
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(TextField), findsNothing);
        expect(find.byIcon(Icons.mic), findsNothing);
      },
    );
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/activity_engine/speak_activity_view_test.dart`
Expected: FAIL — `reviewAttempt` is not a named parameter of `SpeakActivityView`.

- [ ] **Step 3: Implement**

In `lib/features/activity_engine/presentation/views/speak_activity_view.dart`, update the constructor and field list:

```dart
class SpeakActivityView extends ConsumerStatefulWidget {
  const SpeakActivityView({
    required this.activity,
    required this.learnerId,
    required this.onSubmitted,
    this.evaluationContext = const EvaluationContext.empty(),
    this.reviewAttempt,
    super.key,
  });

  final SpeakActivity activity;
  final int learnerId;
  final OnActivitySubmitted onSubmitted;
  final EvaluationContext evaluationContext;

  /// When non-null, this view skips its microphone-capability check
  /// entirely and renders read-only straight into its submitted state,
  /// seeded from this recorded attempt — [reviewAttempt].isCorrect/.score
  /// are trusted verbatim, never recomputed. See docs/superpowers/specs/
  /// 2026-09-09-lesson-answer-review-design.md.
  final ActivityAttempt? reviewAttempt;

  @override
  ConsumerState<SpeakActivityView> createState() => _SpeakActivityViewState();
}
```

Replace the existing `initState` override in `_SpeakActivityViewState`:

```dart
  @override
  void initState() {
    super.initState();
    final reviewAttempt = widget.reviewAttempt;
    if (reviewAttempt == null) {
      _checkCapability();
      return;
    }
    _liveTranscript = _decodeText(reviewAttempt.rawAnswer) ?? '';
    _mode = _SpeakMode.reviewTranscript;
    _submission = ActivitySubmission(
      correctness: reviewAttempt.isCorrect == true
          ? ActivityCorrectness.correct
          : ActivityCorrectness.incorrect,
      score: reviewAttempt.score,
      rawAnswerJson: reviewAttempt.rawAnswer,
      wasFallback: reviewAttempt.wasFallback,
    );
  }

  String? _decodeText(String? rawAnswer) {
    if (rawAnswer == null) return null;
    try {
      final decoded = jsonDecode(rawAnswer);
      return decoded is String ? decoded : null;
    } on FormatException {
      return null;
    }
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/activity_engine/speak_activity_view_test.dart`
Expected: PASS, including every pre-existing test in the file.

- [ ] **Step 5: Commit**

```bash
git add lib/features/activity_engine/presentation/views/speak_activity_view.dart test/features/activity_engine/speak_activity_view_test.dart
git commit -m "$(cat <<'EOF'
feat: add read-only review mode to SpeakActivityView

Part of the Lesson Answer Review feature — see
docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Thread `reviewAttempt` through `buildActivityView`

**Files:**
- Modify: `lib/features/activity_engine/presentation/activity_view_registry.dart`
- Test: `test/features/activity_engine/activity_view_registry_test.dart`

**Interfaces:**
- Consumes: the `reviewAttempt` parameter added to all 7 answerable views in Tasks 1-7.
- Produces: `buildActivityView(Activity, {..., ActivityAttempt? reviewAttempt})`, default `null`. `DialogueActivityView` has no such parameter and never receives one — a completed `dialogue` attempt (none exist in real content today) still renders live/interactive even from `LessonReviewScreen`; this is the spec's explicit, intentional carve-out, not an oversight.

- [ ] **Step 1: Write the failing test**

Add to `test/features/activity_engine/activity_view_registry_test.dart` (add `import 'package:mohingo/data/local/database.dart' show ActivityAttempt;` alongside the existing imports):

```dart
  test(
    'reviewAttempt threads through to every view that declares the '
    'parameter, and is silently ignored by DialogueActivityView (which has '
    'none — no real dialogue content exists to review yet)',
    () {
      final reviewAttempt = ActivityAttempt(
        id: 1,
        uuid: 'attempt-1',
        learnerId: 1,
        activityId: 'x',
        sessionType: 'lesson',
        mode: 'mastery',
        evidenceSkill: 'writing',
        rawAnswer: '"an answer"',
        isCorrect: true,
        wasFallback: false,
        attemptedAt: DateTime.utc(2026, 9, 9),
        updatedAt: DateTime.utc(2026, 9, 9),
      );

      final widget = buildActivityView(
        WriteActivity(
          id: _common.id,
          lessonId: _common.lessonId,
          mode: _common.mode,
          skill: _common.skill,
          canDo: _common.canDo,
          prompt: _common.prompt,
          promptAr: _common.promptAr,
          raw: _common.raw,
          accepted: const [],
        ),
        learnerId: 1,
        onSubmitted: (_) {},
        reviewAttempt: reviewAttempt,
      ) as WriteActivityView;

      expect(widget.reviewAttempt, same(reviewAttempt));
    },
  );
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/activity_engine/activity_view_registry_test.dart`
Expected: FAIL — `reviewAttempt` is not a named parameter of `buildActivityView`.

- [ ] **Step 3: Implement**

In `lib/features/activity_engine/presentation/activity_view_registry.dart`, add the import:

```dart
import '../../../data/local/database.dart' show ActivityAttempt;
```

Update the function signature and every branch except `DialogueActivity`:

```dart
Widget buildActivityView(
  Activity activity, {
  required int learnerId,
  required OnActivitySubmitted onSubmitted,
  Map<String, MediaSpecification> mediaByKey = const {},
  EvaluationContext evaluationContext = const EvaluationContext.empty(),
  ActivityAttempt? reviewAttempt,
  Key? key,
}) {
  return switch (activity) {
    AudioChoiceActivity a => ChoiceActivityView.audioChoice(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
      mediaByKey: mediaByKey,
      reviewAttempt: reviewAttempt,
    ),
    TextChoiceActivity a => ChoiceActivityView.textChoice(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
      mediaByKey: mediaByKey,
      reviewAttempt: reviewAttempt,
    ),
    MatchActivity a => MatchActivityView(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
      reviewAttempt: reviewAttempt,
    ),
    OrderActivity a => OrderActivityView(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
      reviewAttempt: reviewAttempt,
    ),
    GapActivity a => GapActivityView(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
      reviewAttempt: reviewAttempt,
    ),
    FormActivity a => FormActivityView(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
      reviewAttempt: reviewAttempt,
    ),
    SpeakActivity a => SpeakActivityView(
      key: key,
      activity: a,
      learnerId: learnerId,
      onSubmitted: onSubmitted,
      evaluationContext: evaluationContext,
      reviewAttempt: reviewAttempt,
    ),
    WriteActivity a => WriteActivityView(
      key: key,
      activity: a,
      learnerId: learnerId,
      onSubmitted: onSubmitted,
      evaluationContext: evaluationContext,
      reviewAttempt: reviewAttempt,
    ),
    // dialogue has no review mode — no authored instance exists in the real
    // bundle to review yet (verified in DialogueActivityView's own doc
    // comment). Always renders live/interactive; see docs/superpowers/specs/
    // 2026-09-09-lesson-answer-review-design.md.
    DialogueActivity a => DialogueActivityView(
      key: key,
      activity: a,
      onSubmitted: onSubmitted,
    ),
  };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/activity_engine/activity_view_registry_test.dart`
Expected: PASS, both the existing and the new test.

- [ ] **Step 5: Commit**

```bash
git add lib/features/activity_engine/presentation/activity_view_registry.dart test/features/activity_engine/activity_view_registry_test.dart
git commit -m "$(cat <<'EOF'
feat: thread reviewAttempt through buildActivityView

Part of the Lesson Answer Review feature — see
docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: `LessonReviewScreen`

**Files:**
- Create: `lib/features/lesson_player/presentation/lesson_review_screen.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`
- Test: `test/features/lesson_player/lesson_review_screen_test.dart`

**Interfaces:**
- Consumes: `buildActivityView(..., reviewAttempt:)` (Task 8), `ActivityAttemptRepository.attemptsForLessons` (existing), `currentLearnerProvider`, `courseContentProvider('a1')`.
- Produces: `LessonReviewScreen({required String unitId, required String lessonId})`; `lessonReviewAttemptsProvider` (`FutureProvider.family<List<ActivityAttempt>, ({int learnerId, String lessonId})>`); `latestAttemptPerActivity(List<ActivityAttempt>, Lesson) -> Map<String, ActivityAttempt>` (internal to this screen, not imported elsewhere). `LessonReviewScreen` itself is consumed by Task 10's `app_router.dart` route registration and Task 11's end-to-end test.

- [ ] **Step 1: Add the two new l10n keys**

In `lib/l10n/app_en.arb`, insert after the `lessonPlayerProgress` block (after line 177, before `"vocabularyTabWords"`):

```json
  "lessonReviewPracticeAgain": "Practice again",
  "@lessonReviewPracticeAgain": {
    "description": "Button on the lesson review screen (a finished lesson's read-only answer walkthrough) that starts a fresh replay of the lesson."
  },
  "lessonReviewNotAnswered": "Not answered",
  "@lessonReviewNotAnswered": {
    "description": "Placeholder shown on the lesson review screen for an activity with no recorded attempt at all (e.g. content changed after the lesson was finished)."
  },
```

In `lib/l10n/app_ar.arb`, insert after the `lessonPlayerProgress` line (after line 43, before `"vocabularyTabWords"`):

```json
  "lessonReviewPracticeAgain": "تدرّب مرة أخرى",
  "lessonReviewNotAnswered": "لم تتم الإجابة",
```

Run: `flutter gen-l10n`
Expected: regenerates `lib/core/l10n/generated/app_localizations.dart` (and per-locale files) with `lessonReviewPracticeAgain`/`lessonReviewNotAnswered` getters, no errors.

- [ ] **Step 2: Write the failing tests**

Create `test/features/lesson_player/lesson_review_screen_test.dart`:

```dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/lesson_player/presentation/lesson_review_screen.dart';
import 'package:mohingo/features/progress/providers/current_learner_provider.dart';
import 'package:mohingo/features/progress/providers/progress_providers.dart';

CourseContentIndex _realA1Index() {
  final raw = File('assets/content/en/A1/a1-course-bundle.json')
      .readAsStringSync();
  return CourseContentIndex.build(CourseBundleParser.parse(raw));
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
    'shows the recorded read-only result for an attempted activity, and a '
    '"not answered" placeholder for one with no attempt at all',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final index = _realA1Index();
      final lesson = index.lessonsById['A1-U0-L1']!;

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider('a1').overrideWith((ref) async => index),
        ],
      );
      addTearDown(container.dispose);
      final learner = await container.read(currentLearnerProvider.future);

      // A1-U0-L1-A01 (audioChoice, answer "morning-office") answered
      // correctly. A1-U0-L1-A04 (speak) left entirely unattempted.
      await container
          .read(activityAttemptRepositoryProvider)
          .recordAttempt(
            learnerId: learner.id,
            activityId: 'A1-U0-L1-A01',
            lessonId: lesson.id,
            sessionType: 'lesson',
            mode: ActivityMode.encounter,
            evidenceSkill: Skill.listening,
            canDoIds: const [],
            rawAnswer: '"morning-office"',
            isCorrect: true,
            score: 1.0,
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: LessonReviewScreen(unitId: 'A1-U0', lessonId: lesson.id),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text(l10n.lessonReviewNotAnswered), findsOneWidget);
      expect(find.text(l10n.speakStartRecording), findsNothing);
    },
  );

  testWidgets('tapping "Practice again" navigates to the real lesson player', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final index = _realA1Index();
    final lesson = index.lessonsById['A1-U0-L1']!;

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        courseContentProvider('a1').overrideWith((ref) async => index),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/lesson-review-test',
      routes: [
        GoRoute(
          path: '/lesson-review-test',
          builder: (_, _) =>
              LessonReviewScreen(unitId: 'A1-U0', lessonId: lesson.id),
        ),
        GoRoute(
          path: '/lesson-player/:unitId/:lessonId',
          builder: (_, _) => const Scaffold(body: Text('LESSON_PLAYER_STUB')),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
    await tester.tap(find.text(l10n.lessonReviewPracticeAgain));
    await tester.pumpAndSettle();

    expect(find.text('LESSON_PLAYER_STUB'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/features/lesson_player/lesson_review_screen_test.dart`
Expected: FAIL — `package:mohingo/features/lesson_player/presentation/lesson_review_screen.dart` doesn't exist.

- [ ] **Step 4: Implement**

Create `lib/features/lesson_player/presentation/lesson_review_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/activity.dart';
import '../../../content/models/curriculum_structure.dart';
import '../../../content/models/media_specification.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../data/local/database.dart';
import '../../activity_engine/presentation/activity_chrome.dart';
import '../../activity_engine/presentation/activity_view_registry.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';

/// Every recorded attempt for one lesson's activities, for one learner —
/// feeds [LessonReviewScreen]'s "latest attempt per activity" reduction.
///
/// Declared as a plain (non-code-generated) provider — see
/// [currentLearnerProvider]'s doc comment for why: riverpod_generator fails
/// on providers returning Drift `DataClass` types directly.
final lessonReviewAttemptsProvider =
    FutureProvider.family<
      List<ActivityAttempt>,
      ({int learnerId, String lessonId})
    >((ref, params) {
      final repository = ref.watch(activityAttemptRepositoryProvider);
      return repository.attemptsForLessons(
        learnerId: params.learnerId,
        lessonIds: [params.lessonId],
      );
    });

/// Reduces [attempts] to the single latest attempt per activity id, for
/// activities that actually belong to [lesson] — the same reduction
/// `lesson_player_screen.dart`'s `_rehydratePreviousAnswers` performs (kept
/// as a separate function here since the two screens use the result for
/// different purposes). Restricted to `sessionType == 'lesson'`:
/// placement/mission/assessment attempts never leak into ordinary lesson
/// review. See docs/DATA_MODEL.md.
Map<String, ActivityAttempt> latestAttemptPerActivity(
  List<ActivityAttempt> attempts,
  Lesson lesson,
) {
  final activityIds = lesson.activities.map((a) => a.id).toSet();
  final latest = <String, ActivityAttempt>{};
  for (final attempt in attempts) {
    if (attempt.sessionType != 'lesson') continue;
    if (!activityIds.contains(attempt.activityId)) continue;
    final existing = latest[attempt.activityId];
    if (existing == null ||
        !attempt.attemptedAt.isBefore(existing.attemptedAt)) {
      latest[attempt.activityId] = attempt;
    }
  }
  return latest;
}

/// Read-only walkthrough of a learner's latest answer to every activity in
/// an already-finished lesson — the Learn tab's answer-review feature. Shown
/// instead of [LessonPlayerScreen] when `UnitOverviewScreen` detects the
/// lesson has already reached its final activity. "Practice again" is the
/// only door back into the real (replaying, evidence-recording) player. See
/// docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md.
class LessonReviewScreen extends ConsumerWidget {
  const LessonReviewScreen({
    required this.unitId,
    required this.lessonId,
    super.key,
  });

  final String unitId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(courseContentProvider('a1'));
    final learnerAsync = ref.watch(currentLearnerProvider);

    return contentAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (error, _) => _ErrorScaffold(message: '$error'),
      data: (index) {
        final lesson = index.lessonsById[lessonId];
        if (lesson == null) {
          return const _ErrorScaffold(message: 'Lesson not found');
        }
        return learnerAsync.when(
          loading: () => const _LoadingScaffold(),
          error: (error, _) => _ErrorScaffold(message: '$error'),
          data: (learner) => _LessonReviewBody(
            unitId: unitId,
            lesson: lesson,
            learnerId: learner.id,
            mediaByKey: index.bundle.mediaSpecifications,
          ),
        );
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(message)));
}

class _LessonReviewBody extends ConsumerWidget {
  const _LessonReviewBody({
    required this.unitId,
    required this.lesson,
    required this.learnerId,
    required this.mediaByKey,
  });

  final String unitId;
  final Lesson lesson;
  final int learnerId;
  final Map<String, MediaSpecification> mediaByKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attemptsAsync = ref.watch(
      lessonReviewAttemptsProvider((
        learnerId: learnerId,
        lessonId: lesson.id,
      )),
    );
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: attemptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (attempts) {
          final latest = latestAttemptPerActivity(attempts, lesson);
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final activity in lesson.activities)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: latest[activity.id] == null
                        ? _NotAnsweredCard(activity: activity)
                        : buildActivityView(
                            key: ValueKey(activity.id),
                            activity,
                            learnerId: learnerId,
                            onSubmitted: (_) {},
                            mediaByKey: mediaByKey,
                            reviewAttempt: latest[activity.id],
                          ),
                  ),
                FilledButton(
                  onPressed: () =>
                      context.push('/lesson-player/$unitId/${lesson.id}'),
                  child: Text(l10n.lessonReviewPracticeAgain),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotAnsweredCard extends StatelessWidget {
  const _NotAnsweredCard({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ActivityChrome(
      prompt: activity.prompt,
      promptAr: activity.promptAr,
      body: Text(
        l10n.lessonReviewNotAnswered,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/features/lesson_player/lesson_review_screen_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/lesson_player/presentation/lesson_review_screen.dart lib/l10n/app_en.arb lib/l10n/app_ar.arb lib/core/l10n/generated test/features/lesson_player/lesson_review_screen_test.dart
git commit -m "$(cat <<'EOF'
feat: add LessonReviewScreen, the Learn tab's read-only answer walkthrough

Part of the Lesson Answer Review feature — see
docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: Route a finished lesson's tap to `LessonReviewScreen`

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/features/learning_path/presentation/unit_overview_screen.dart`
- Test: `test/features/learning_path/presentation/unit_overview_screen_test.dart`

**Interfaces:**
- Consumes: `LessonReviewScreen` (Task 9), the existing `lessonStatus(...)` selector.
- Produces: new route `/lesson-review/:unitId/:lessonId`.

- [ ] **Step 1: Write the failing tests**

Add to `test/features/learning_path/presentation/unit_overview_screen_test.dart` (add `import 'package:go_router/go_router.dart';` alongside the existing imports):

```dart
  group('lesson-row tap routing', () {
    GoRouter testRouter({required Widget Function() home}) {
      return GoRouter(
        initialLocation: '/unit-test',
        routes: [
          GoRoute(path: '/unit-test', builder: (_, _) => home()),
          GoRoute(
            path: '/lesson-player/:unitId/:lessonId',
            builder: (_, _) =>
                const Scaffold(body: Text('LESSON_PLAYER_STUB')),
          ),
          GoRoute(
            path: '/lesson-review/:unitId/:lessonId',
            builder: (_, _) =>
                const Scaffold(body: Text('LESSON_REVIEW_STUB')),
          ),
        ],
      );
    }

    testWidgets(
      'a not-started lesson still routes to the real lesson player, '
      'unaffected',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        final index = await _realA1Index();
        final unit = index.bundle.units.firstWhere(
          (u) => u.lessons.any((l) => l.activities.isNotEmpty),
        );
        final lesson = unit.lessons.firstWhere(
          (l) => l.activities.isNotEmpty,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              appDatabaseProvider.overrideWithValue(db),
              courseContentProvider(
                'a1',
              ).overrideWith((ref) async => _realA1Index()),
            ],
            child: MaterialApp.router(
              routerConfig: testRouter(
                home: () => UnitOverviewScreen(unitId: unit.id),
              ),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text(lesson.title).first);
        await tester.pumpAndSettle();

        expect(find.text('LESSON_PLAYER_STUB'), findsOneWidget);
      },
    );

    testWidgets('a finished lesson routes to the read-only review screen', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final index = await _realA1Index();
      final unit = index.bundle.units.firstWhere(
        (u) => u.lessons.any((l) => l.activities.isNotEmpty),
      );
      final lesson = unit.lessons.firstWhere((l) => l.activities.isNotEmpty);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider(
            'a1',
          ).overrideWith((ref) async => _realA1Index()),
        ],
      );
      addTearDown(container.dispose);
      final learner = await container.read(currentLearnerProvider.future);

      await container
          .read(unitLessonProgressRepositoryProvider)
          .recordLessonPosition(
            learnerId: learner.id,
            lessonId: lesson.id,
            unitId: unit.id,
            lastActivityId: lesson.activities.last.id,
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: testRouter(
              home: () => UnitOverviewScreen(unitId: unit.id),
            ),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(lesson.title).first);
      await tester.pumpAndSettle();

      expect(find.text('LESSON_REVIEW_STUB'), findsOneWidget);
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/learning_path/presentation/unit_overview_screen_test.dart`
Expected: the first new test (not-started) PASSes already (behavior unchanged); the second (finished lesson) FAILs — it currently still routes to `LESSON_PLAYER_STUB`, not `LESSON_REVIEW_STUB`.

- [ ] **Step 3: Implement — add the route**

In `lib/core/router/app_router.dart`, add the import:

```dart
import '../../features/lesson_player/presentation/lesson_review_screen.dart';
```

Add a new `GoRoute` immediately after the existing `/lesson-player/:unitId/:lessonId` route (inside the top-level `routes` list, still a sibling of the `StatefulShellRoute` for the same reason the lesson player is — hides the bottom nav):

```dart
      GoRoute(
        path: '/lesson-player/:unitId/:lessonId',
        builder: (_, state) => LessonPlayerScreen(
          unitId: state.pathParameters['unitId']!,
          lessonId: state.pathParameters['lessonId']!,
        ),
      ),
      GoRoute(
        path: '/lesson-review/:unitId/:lessonId',
        builder: (_, state) => LessonReviewScreen(
          unitId: state.pathParameters['unitId']!,
          lessonId: state.pathParameters['lessonId']!,
        ),
      ),
```

- [ ] **Step 4: Implement — branch the tap target**

In `lib/features/learning_path/presentation/unit_overview_screen.dart`, replace the lesson-row loop and `_lessonStatusIndicator` method. The `for (final lesson in unit.lessons) Padding(...)` block becomes:

```dart
              for (final lesson in unit.lessons)
                _lessonRow(
                  context,
                  lesson,
                  progressByLessonId[lesson.id],
                  lessonAttempts,
                ),
```

Replace `_lessonStatusIndicator` with two methods — one building the full row (computing `state`/`isFinished` once), one just the indicator:

```dart
  /// One lesson's tappable row. Reused between the "genuinely finished"
  /// (read-only review) and "not started"/"mid-lesson" (resume/start the
  /// real player) cases — [isFinished] is the same "reached the lesson's
  /// final activity" signal `lesson_player_screen.dart`'s
  /// `_resolveStartIndex` uses, derived once here via [lessonStatus] so the
  /// status dot and the tap target never disagree. See
  /// docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md.
  Widget _lessonRow(
    BuildContext context,
    Lesson lesson,
    LessonProgressData? row,
    List<ActivityAttempt> lessonAttempts,
  ) {
    final state = lessonStatus(
      lesson: lesson,
      progress: row,
      lessonAttempts: lessonAttempts,
    );
    final isFinished =
        state == ProgressState.mastered || state == ProgressState.needsReview;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          // No invalidate-on-return here: the lesson player invalidates
          // [lessonProgressForUnitProvider] itself the moment a lesson is
          // finished, which covers both its "Back to unit" (pop) and "Next
          // lesson" (pushReplacement) exits. See that provider's doc
          // comment.
          onTap: () => context.push(
            isFinished
                ? '/lesson-review/${unit.id}/${lesson.id}'
                : '/lesson-player/${unit.id}/${lesson.id}',
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _lessonStatusIndicator(context, state),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        textDirection: TextDirection.ltr,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        lesson.titleAr,
                        textDirection: TextDirection.rtl,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The lesson row's status dot. A finished, all-correct lesson
  /// deliberately announces "Completed" rather than the shared "Mastered"
  /// label: reaching a lesson's last activity is not course mastery as
  /// docs/GLOSSARY.md defines it (that is `MasteryAggregationService`'s
  /// call, made per unit against Can-Do evidence). A finished lesson with
  /// at least one wrong answer shows `needsReview` instead, using its own
  /// default "Needs review" label — see [lessonStatus].
  Widget _lessonStatusIndicator(BuildContext context, ProgressState state) {
    return StatusIndicator(
      state: state,
      size: 20,
      semanticLabelOverride: state == ProgressState.mastered
          ? AppLocalizations.of(context)!.lessonStateCompleted
          : null,
    );
  }
```

Remove the now-unused `Padding`/`Material`/`InkWell`/`Row` block that previously lived inline in `build()`'s `children:` list (it's fully replaced by the `_lessonRow(...)` call above).

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/features/learning_path/presentation/unit_overview_screen_test.dart`
Expected: PASS, including every pre-existing test in the file (the `StatusIndicator` assertions are unaffected — `_lessonStatusIndicator` still renders the same widget from the same `state`).

- [ ] **Step 6: Run the full suite and analyzer**

Run: `flutter test && dart format --set-exit-if-changed . && flutter analyze`
Expected: all tests pass, no formatting diffs, 0 analyzer issues.

- [ ] **Step 7: Commit**

```bash
git add lib/core/router/app_router.dart lib/features/learning_path/presentation/unit_overview_screen.dart test/features/learning_path/presentation/unit_overview_screen_test.dart
git commit -m "$(cat <<'EOF'
feat: route a finished lesson's tap to the read-only review screen

Part of the Lesson Answer Review feature — see
docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 11: End-to-end test — replay shows the latest attempt in review

**Files:**
- Test: `test/features/lesson_player/lesson_review_e2e_test.dart` (create)

**Interfaces:**
- Consumes: `LessonPlayerScreen` (existing, real), `LessonReviewScreen` (Task 9), real A1-U0-L1 content (3 `audioChoice` + 1 `speak`, per `assets/content/en/A1/a1-course-bundle.json`).

- [ ] **Step 1: Write the failing test**

Create `test/features/lesson_player/lesson_review_e2e_test.dart`:

```dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/lesson_player/presentation/lesson_player_screen.dart';
import 'package:mohingo/features/lesson_player/presentation/lesson_review_screen.dart';
import 'package:mohingo/features/speech/domain/speech_capability_service.dart';
import 'package:mohingo/features/speech/providers/speech_providers.dart';

import '../speech/fake_speech_services.dart';

/// A full, real pass through A1-U0-L1's 3 `audioChoice` + 1 `speak`
/// activities: A01's answer is [a01Answer] (varied between passes to
/// produce two different results for the same activity across a replay);
/// A02/A03/A04 are always answered correctly so the lesson reliably
/// reaches its final activity regardless of A01's outcome.
Future<void> _playLessonOnce(WidgetTester tester, String a01Answer) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text(a01Answer).last);
  await tester.pump();
  await tester.tap(find.byType(FilledButton)); // Check
  await tester.pump();
  await tester.tap(find.byType(FilledButton)); // Next
  await tester.pump();

  await tester.pumpAndSettle();
  await tester.tap(find.text("You're welcome.").last); // A02
  await tester.pump();
  await tester.tap(find.byType(FilledButton));
  await tester.pump();
  await tester.tap(find.byType(FilledButton));
  await tester.pump();

  await tester.pumpAndSettle();
  await tester.tap(find.text('Good morning.').last); // A03
  await tester.pump();
  await tester.tap(find.byType(FilledButton));
  await tester.pump();
  await tester.tap(find.byType(FilledButton));
  await tester.pump();

  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), 'Thank you.'); // A04
  await tester.pump();
  await tester.tap(find.byType(FilledButton));
  await tester.pump();
  await tester.tap(find.byType(FilledButton));
  await tester.pump();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
    'reopening a lesson replayed with a different answer shows the latest '
    '(second) attempt in review, not the first',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final index = CourseContentIndex.build(
        CourseBundleParser.parse(
          File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
        ),
      );

      final overrides = [
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
      ];

      // First pass: A01 answered correctly.
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const LessonPlayerScreen(
              unitId: 'A1-U0',
              lessonId: 'A1-U0-L1',
            ),
          ),
        ),
      );
      await _playLessonOnce(tester, 'morning-office');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.celebration), findsOneWidget);

      // Replay: A01 answered incorrectly this time.
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const LessonPlayerScreen(
              unitId: 'A1-U0',
              lessonId: 'A1-U0-L1',
            ),
          ),
        ),
      );
      await _playLessonOnce(tester, 'night-bedroom');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.celebration), findsOneWidget);

      final a01Attempts = await (db.select(
        db.activityAttempts,
      )..where((t) => t.activityId.equals('A1-U0-L1-A01'))).get();
      expect(
        a01Attempts,
        hasLength(2),
        reason: 'insert-only — replaying must append, never overwrite',
      );

      // Open the review screen: A01 must show the *second* (latest,
      // incorrect) attempt, not the first (correct) one.
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const LessonReviewScreen(
              unitId: 'A1-U0',
              lessonId: 'A1-U0-L1',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // A01 wrong (latest); A02/A03/A04 correct on both passes.
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
    },
  );
}
```

- [ ] **Step 2: Run test to verify it fails for the right reason**

Run: `flutter test test/features/lesson_player/lesson_review_e2e_test.dart`
Expected: without Tasks 1-10, this fails to compile (`LessonReviewScreen` doesn't exist). Since Tasks 1-10 are already complete by this point in the plan, run it now and expect PASS immediately — this task adds coverage, not new production code. If it fails, the failure must be diagnosed against the real behavior (not written around) before proceeding — see the `systematic-debugging` approach.

- [ ] **Step 3: Run the full suite**

Run: `flutter test`
Expected: PASS, full suite green (this task adds no production code, only a test).

- [ ] **Step 4: Commit**

```bash
git add test/features/lesson_player/lesson_review_e2e_test.dart
git commit -m "$(cat <<'EOF'
test: add end-to-end coverage for lesson answer review after a replay

Confirms LessonReviewScreen shows the latest attempt per activity, not an
earlier one from before a replay — part of the Lesson Answer Review
feature. See
docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 12: Update `docs/TESTING.md`

**Files:**
- Modify: `docs/TESTING.md`

**Interfaces:** None — documentation only.

- [ ] **Step 1: Add a bullet under "What must be tested"**

In `docs/TESTING.md`, in the `## What must be tested` section, add a new bullet after the existing "Online-refinement feedback" bullet:

```markdown
- **Lesson answer review (Learn tab only):** reopening a lesson that has reached its final activity shows `LessonReviewScreen`, not `LessonPlayerScreen` — a lesson that's merely started or mid-way through is unaffected. Every answerable activity view's `reviewAttempt` parameter renders read-only, seeded from the recorded `ActivityAttempt`, and must **never** call `evaluate()` or otherwise recompute correctness/score — the banner always reflects the attempt exactly as recorded, even when it disagrees with what live re-grading of the same answer would produce (a rubric can change after the attempt was recorded). A lesson replayed more than once shows only the latest attempt per activity. Out of scope: the Tests tab (Final Mission/Assessment/Placement Test) — a deliberately separate, later decision, see docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md.
```

- [ ] **Step 2: Bump the "Last verified" line**

At the top of `docs/TESTING.md`, append a sentence to the end of the existing `_Last verified: ..._` paragraph:

```markdown
2026-09-09: added the Learn-tab "Lesson Answer Review" feature — reopening an already-finished lesson now shows a read-only `LessonReviewScreen` walkthrough of the learner's latest answers instead of a blank replay, with an explicit "Practice again" button as the only way back into the real player; see the "Lesson answer review" row below and docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md.
```

- [ ] **Step 3: Verify**

Run: `flutter test && dart format --set-exit-if-changed . && flutter analyze`
Expected: unaffected (documentation-only change) — all still green, confirming no earlier task left the tree dirty.

- [ ] **Step 4: Commit**

```bash
git add docs/TESTING.md
git commit -m "$(cat <<'EOF'
docs: document Lesson Answer Review testing coverage

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```
