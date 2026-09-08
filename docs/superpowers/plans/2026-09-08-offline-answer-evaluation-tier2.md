# Offline Answer Evaluation (Tier 2: Deferred Online Refinement) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the ~40 genuinely open-ended writing/speaking rubrics (`keywordChecklist` with `onlineRefinement: "grammarCheck"`) real, eventually-resolving mastery credit — local content-check now, a free grammar-quality pass from the device when it's next online, with a bounded local-only fallback so the app never actually requires network — closing the gap Tier 1 deliberately left open.

**Architecture:** A new `pending_online_refinements` queue table (not a change to the insert-only `activity_attempts`) holds a submitted open-ended answer plus its already-computed local content score. `WriteActivityView`/`SpeakActivityView` detect the `onlineRefinement` flag and enqueue instead of grading synchronously, showing a distinct bilingual "we'll finish checking this online" notice. An app-root Riverpod provider (same shape as the existing `ensureA1EnrollmentProvider`) drains the queue whenever `ConnectivityService` reports the device just came online: each item gets a real grammar-quality pass from the free public LanguageTool API via `GrammarCheckService`, combined with its stored local score, and is then recorded through the ordinary `ActivityAttemptRepository.recordAttempt` — a normal insert, same as any other attempt. A bounded retry/age threshold finalizes a stuck item using its local-only score, so an offline-only learner is never blocked.

**Tech Stack:** Dart, `http` (LanguageTool client), `connectivity_plus` (online/offline detection), Drift (second schema migration, v2→v3), Flutter/Riverpod (existing patterns).

**Spec:** [docs/superpowers/specs/2026-09-07-offline-answer-evaluation-design.md](../specs/2026-09-07-offline-answer-evaluation-design.md)

## Global Constraints

- All new user-facing copy must be bilingual (Arabic + English), each written natively, never machine-translated — see `docs/UX_PRINCIPLES.md`.
- UI must use directional (start/end) layout properties only, never hardcoded left/right — see `docs/DESIGN_SYSTEM.md`.
- `ActivityAttempts` is insert-only — never write code that updates or deletes an existing attempt row. The new `pending_online_refinements` table IS updatable/deletable (it's a queue, not evidence-of-record).
- TDD: every task's step order is failing test → verified RED → minimal implementation → verified GREEN → commit.
- **Online refinement must never be required.** Every code path that touches the network must have a working, tested fallback that doesn't need it. This is the whole point of Task 11's ADR — read it before touching Tasks 6-10.
- No cost, ever: only the free public LanguageTool endpoint, no API key, no paid tier of anything.

---

## Known simplifications relative to the design spec (read before Task 6)

- **No "highlight missing elements" UI.** The spec's step 1 says the local check "drives UI feedback... (e.g. highlighting a missing expected element)" — that example is illustrative, not a hard requirement (the spec's actual requirement is "drives UI feedback," which the new pending-disclosure banner itself satisfies). Building a keyword-by-keyword highlighting UI is real, separate scope; deferred. The local score is still computed and used (silently, for the eventual combined grade), just not surfaced element-by-element.
- **No "N answers finished grading" notification.** The spec mentions "a light notification" once items resolve. This plan relies entirely on the provider-invalidation mechanism Tier 1 already built (mastery/progress providers refresh automatically once a finalized attempt lands) — a learner sees their updated mastery state the next time they visit the relevant screen, without a new notification component. A dedicated notification is real, separable scope for later.

## File structure

**New:**
- `lib/features/activity_engine/domain/evaluation/connectivity_service.dart` — `ConnectivityService` interface.
- `lib/features/activity_engine/data/device_connectivity_service.dart` — real impl (`connectivity_plus`).
- `lib/features/activity_engine/domain/evaluation/grammar_check_service.dart` — `GrammarCheckService` interface, `GrammarCheckResult`, `GrammarCheckUnavailableException`.
- `lib/features/activity_engine/data/language_tool_grammar_check_service.dart` — real impl (`http`, `api.languagetool.org`).
- `lib/features/activity_engine/providers/online_refinement_providers.dart` — providers for the above two services, the repository, and the drain trigger.
- `lib/data/local/tables/pending_online_refinement_tables.dart` — the new Drift table.
- `lib/features/activity_engine/domain/repositories/pending_refinement_repository.dart` — interface.
- `lib/features/activity_engine/data/drift_pending_refinement_repository.dart` — Drift impl.
- `lib/features/activity_engine/domain/evaluation/pending_refinement_drain_service.dart` — the drain/retry/fallback logic.
- `docs/adr/0005-narrow-network-exception-for-open-ended-grading.md`.
- Matching test files under `test/` mirroring each of the above.

**Modified:**
- `lib/content/models/evaluation_spec.dart` — `KeywordChecklistEvaluationSpec` gains `onlineRefinement`.
- `lib/features/activity_engine/domain/activity_submission.dart` — `ActivitySubmission` gains `pendingOnlineRefinement`.
- `lib/features/activity_engine/presentation/activity_chrome.dart` — `ActivityFeedbackBanner` gains a pending-refinement visual state.
- `lib/features/activity_engine/presentation/views/write_activity_view.dart`, `speak_activity_view.dart` — enqueue branch.
- `lib/features/lesson_player/presentation/lesson_player_screen.dart` — enqueue instead of `recordAttempt` when pending.
- `lib/data/local/database.dart` — new table registered, `schemaVersion` 3, `onUpgrade` extended, `resetProgressForLearner` extended.
- `lib/app.dart` — watches the new drain-trigger provider.
- `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb` — new disclosure copy.
- `pubspec.yaml` — `http`, `connectivity_plus`.
- `assets/content/en/A1/a1-course-bundle.json` — `A1-U5-L6-A05` migrated.
- `docs/SECURITY.md`, `docs/TECH_STACK.md`, `docs/DATA_MODEL.md`.

---

### Task 1: `onlineRefinement` on `KeywordChecklistEvaluationSpec`

**Files:**
- Modify: `lib/content/models/evaluation_spec.dart`
- Test: `test/content/models/evaluation_spec_test.dart`

**Interfaces:**
- Produces: `KeywordChecklistEvaluationSpec.onlineRefinement` (`String?`), parsed from JSON's `onlineRefinement` field.

- [ ] **Step 1: Write the failing tests**

Add to `test/content/models/evaluation_spec_test.dart`:

```dart
test('parses keywordChecklist with an onlineRefinement flag', () {
  final spec = EvaluationSpec.fromJson({
    'type': 'keywordChecklist',
    'requiredGroups': [
      ['hi', 'hello'],
    ],
    'minGroupsMatched': 1,
    'onlineRefinement': 'grammarCheck',
  });
  final checklist = spec as KeywordChecklistEvaluationSpec;
  expect(checklist.onlineRefinement, 'grammarCheck');
});

test('keywordChecklist without onlineRefinement leaves it null', () {
  final spec = EvaluationSpec.fromJson({
    'type': 'keywordChecklist',
    'requiredGroups': [
      ['hi', 'hello'],
    ],
    'minGroupsMatched': 1,
  });
  final checklist = spec as KeywordChecklistEvaluationSpec;
  expect(checklist.onlineRefinement, isNull);
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/content/models/evaluation_spec_test.dart`
Expected: FAIL — `onlineRefinement` getter doesn't exist yet.

- [ ] **Step 3: Implement**

In `lib/content/models/evaluation_spec.dart`, update `KeywordChecklistEvaluationSpec`:

```dart
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
  });
  final List<List<String>> requiredGroups;
  final int minGroupsMatched;
  final String? onlineRefinement;
}
```

Update `_keywordChecklistFromJson` to also parse it:

```dart
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
    );
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/content/models/evaluation_spec_test.dart`
Expected: PASS

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`
Expected: PASS (adding an optional field with a default doesn't break any existing `KeywordChecklistEvaluationSpec(...)` construction).

- [ ] **Step 6: Commit**

```bash
git add lib/content/models/evaluation_spec.dart test/content/models/evaluation_spec_test.dart
git commit -m "feat: add onlineRefinement flag to KeywordChecklistEvaluationSpec"
```

---

### Task 2: `ActivitySubmission.pendingOnlineRefinement`

**Files:**
- Modify: `lib/features/activity_engine/domain/activity_submission.dart`
- Test: `test/features/activity_engine/domain/activity_submission_test.dart` (create — none exists yet; check first)

**Interfaces:**
- Produces: `ActivitySubmission.pendingOnlineRefinement` (`bool`, default `false`).

- [ ] **Step 1: Check for an existing test file, write the failing test**

Run: `find test/features/activity_engine/domain -iname "activity_submission*"`. If none exists, create `test/features/activity_engine/domain/activity_submission_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/activity_engine/domain/activity_submission.dart';

void main() {
  test('pendingOnlineRefinement defaults to false', () {
    const submission = ActivitySubmission(correctness: ActivityCorrectness.correct);
    expect(submission.pendingOnlineRefinement, isFalse);
  });

  test('pendingOnlineRefinement can be set explicitly', () {
    const submission = ActivitySubmission(
      correctness: ActivityCorrectness.notAutoGraded,
      pendingOnlineRefinement: true,
    );
    expect(submission.pendingOnlineRefinement, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/activity_engine/domain/activity_submission_test.dart`
Expected: FAIL — no such named parameter.

- [ ] **Step 3: Implement**

In `lib/features/activity_engine/domain/activity_submission.dart`:

```dart
class ActivitySubmission {
  const ActivitySubmission({
    required this.correctness,
    this.score,
    this.rawAnswerJson,
    this.wasFallback = false,
    this.pendingOnlineRefinement = false,
  });

  final ActivityCorrectness correctness;
  final double? score;
  final String? rawAnswerJson;
  final bool wasFallback;

  /// True only for an open-ended `keywordChecklist`/`onlineRefinement`
  /// rubric's submission: [score] here is the *local* content-only score,
  /// not the final grade — the lesson player enqueues this into
  /// `pending_online_refinements` instead of recording it as an ordinary
  /// attempt. See docs/superpowers/specs/
  /// 2026-09-07-offline-answer-evaluation-design.md's Tier 2.
  final bool pendingOnlineRefinement;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/activity_engine/domain/activity_submission_test.dart`
Expected: PASS

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/activity_engine/domain/activity_submission.dart test/features/activity_engine/domain/activity_submission_test.dart
git commit -m "feat: add ActivitySubmission.pendingOnlineRefinement"
```

---

### Task 3: `ConnectivityService`

**Files:**
- Modify: `pubspec.yaml` — add `connectivity_plus: ^7.3.1`
- Create: `lib/features/activity_engine/domain/evaluation/connectivity_service.dart`
- Create: `lib/features/activity_engine/data/device_connectivity_service.dart`
- Create: `test/features/activity_engine/fake_connectivity_service.dart`
- Create: `lib/features/activity_engine/providers/online_refinement_providers.dart` (first entry in this file — more providers added in later tasks)
- Test: `test/features/activity_engine/data/device_connectivity_service_test.dart`

**Interfaces:**
- Produces: `ConnectivityService` (`Future<bool> isOnline()`, `Stream<bool> get onlineChanges`), `DeviceConnectivityService`, `FakeConnectivityService`, `connectivityServiceProvider`.

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, add under `dependencies:` (alphabetical, matching the file's existing ordering):

```yaml
  connectivity_plus: ^7.3.1
```

Run: `flutter pub get`

- [ ] **Step 2: Write the failing test for the interface + real implementation's mapping logic**

`connectivity_plus`'s `Connectivity` class exposes `checkConnectivity() -> Future<List<ConnectivityResult>>` and `onConnectivityChanged -> Stream<List<ConnectivityResult>>` — a *list*, since a device can report more than one active connection type at once. `DeviceConnectivityService` maps that list down to a single `bool`: online unless every entry is `ConnectivityResult.none`.

Create `test/features/activity_engine/data/device_connectivity_service_test.dart`:

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/activity_engine/data/device_connectivity_service.dart';

void main() {
  group('isOnlineFromResults', () {
    test('a single non-none result is online', () {
      expect(isOnlineFromResults([ConnectivityResult.wifi]), isTrue);
    });

    test('a list of only none is offline', () {
      expect(isOnlineFromResults([ConnectivityResult.none]), isFalse);
    });

    test('an empty list is offline', () {
      expect(isOnlineFromResults(const []), isFalse);
    });

    test('mixed none and a real connection is online', () {
      expect(
        isOnlineFromResults([ConnectivityResult.none, ConnectivityResult.mobile]),
        isTrue,
      );
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/activity_engine/data/device_connectivity_service_test.dart`
Expected: FAIL — `device_connectivity_service.dart` doesn't exist yet.

- [ ] **Step 4: Implement the interface**

Create `lib/features/activity_engine/domain/evaluation/connectivity_service.dart`:

```dart
/// Whether the device currently has network connectivity — used only to
/// decide when it's worth *attempting* the optional online grammar-quality
/// refinement (Tier 2). Never gates any learning feature directly: every
/// caller must have a working offline path. See docs/superpowers/specs/
/// 2026-09-07-offline-answer-evaluation-design.md and
/// docs/adr/0005-narrow-network-exception-for-open-ended-grading.md.
abstract interface class ConnectivityService {
  Future<bool> isOnline();

  /// Emits the new online/offline state on every change. A `true` event is
  /// the trigger the drain-queue provider listens for.
  Stream<bool> get onlineChanges;
}
```

- [ ] **Step 5: Implement the real service**

Create `lib/features/activity_engine/data/device_connectivity_service.dart`:

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

import '../domain/evaluation/connectivity_service.dart';

/// Online unless every reported connection type is [ConnectivityResult.none]
/// — a device can report more than one simultaneous connection (e.g. wifi
/// and a VPN), so this only needs one of them to be real.
bool isOnlineFromResults(List<ConnectivityResult> results) =>
    results.any((r) => r != ConnectivityResult.none);

class DeviceConnectivityService implements ConnectivityService {
  DeviceConnectivityService() : _connectivity = Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return isOnlineFromResults(results);
  }

  @override
  Stream<bool> get onlineChanges =>
      _connectivity.onConnectivityChanged.map(isOnlineFromResults);
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/features/activity_engine/data/device_connectivity_service_test.dart`
Expected: PASS

- [ ] **Step 7: Add the fake**

Create `test/features/activity_engine/fake_connectivity_service.dart`:

```dart
import 'dart:async';

import 'package:mohingo/features/activity_engine/domain/evaluation/connectivity_service.dart';

/// A fake [ConnectivityService] with a test-controlled online/offline state
/// and a manually-fireable change stream — standing in for
/// `connectivity_plus`'s platform channel, which can't be exercised in a
/// `flutter test` environment. See docs/TESTING.md.
class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService({bool online = true}) : _online = online;

  bool _online;
  final _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> isOnline() async => _online;

  @override
  Stream<bool> get onlineChanges => _controller.stream;

  /// Test hook: simulates the device's connectivity state changing.
  void setOnline(bool online) {
    _online = online;
    _controller.add(online);
  }
}
```

- [ ] **Step 8: Add the provider**

Create `lib/features/activity_engine/providers/online_refinement_providers.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/device_connectivity_service.dart';
import '../domain/evaluation/connectivity_service.dart';

part 'online_refinement_providers.g.dart';

/// Bound to the real device implementation today, same seam pattern as
/// `speech_providers.dart`'s `textToSpeechServiceProvider` — a future
/// alternative implementation swaps in by changing only this binding.
@Riverpod(keepAlive: true)
ConnectivityService connectivityService(Ref ref) {
  return DeviceConnectivityService();
}
```

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 9: Run the full test suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 10: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/features/activity_engine/domain/evaluation/connectivity_service.dart lib/features/activity_engine/data/device_connectivity_service.dart lib/features/activity_engine/providers/online_refinement_providers.dart lib/features/activity_engine/providers/online_refinement_providers.g.dart test/features/activity_engine/data/device_connectivity_service_test.dart test/features/activity_engine/fake_connectivity_service.dart
git commit -m "feat: add ConnectivityService (connectivity_plus-backed)"
```

---

### Task 4: `GrammarCheckService`

**Files:**
- Modify: `pubspec.yaml` — add `http: ^1.6.0`
- Create: `lib/features/activity_engine/domain/evaluation/grammar_check_service.dart`
- Create: `lib/features/activity_engine/data/language_tool_grammar_check_service.dart`
- Create: `test/features/activity_engine/fake_grammar_check_service.dart`
- Modify: `lib/features/activity_engine/providers/online_refinement_providers.dart`
- Test: `test/features/activity_engine/data/language_tool_grammar_check_service_test.dart`

**Interfaces:**
- Produces: `GrammarCheckService` (`Future<GrammarCheckResult> check(String text, {required String localeCode})`), `GrammarCheckResult({errorCount, wordCount})`, `GrammarCheckUnavailableException`, `LanguageToolGrammarCheckService`, `FakeGrammarCheckService`, `grammarCheckServiceProvider`.

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, add under `dependencies:` (alphabetical):

```yaml
  http: ^1.6.0
```

Run: `flutter pub get`

- [ ] **Step 2: Write the failing test**

`package:http/testing.dart` (shipped inside the `http` package itself — no extra dependency) provides `MockClient`, letting a test supply a canned HTTP response without any real network call. Create `test/features/activity_engine/data/language_tool_grammar_check_service_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mohingo/features/activity_engine/data/language_tool_grammar_check_service.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/grammar_check_service.dart';

void main() {
  group('LanguageToolGrammarCheckService', () {
    test('counts matches and words from a well-formed response', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'https://api.languagetool.org/v2/check');
        expect(request.bodyFields['text'], 'I has two cat.');
        expect(request.bodyFields['language'], 'en-US');
        return http.Response(
          jsonEncode({
            'matches': [
              {'message': 'Did you mean "have"?'},
              {'message': 'Did you mean "cats"?'},
            ],
          }),
          200,
        );
      });
      final service = LanguageToolGrammarCheckService(client: client);

      final result = await service.check('I has two cat.', localeCode: 'en');

      expect(result.errorCount, 2);
      expect(result.wordCount, 4);
    });

    test('a non-200 response throws GrammarCheckUnavailableException', () async {
      final client = MockClient((request) async => http.Response('', 503));
      final service = LanguageToolGrammarCheckService(client: client);

      expect(
        () => service.check('text', localeCode: 'en'),
        throwsA(isA<GrammarCheckUnavailableException>()),
      );
    });

    test('a malformed (non-JSON) response throws '
        'GrammarCheckUnavailableException, not a raw crash', () async {
      final client = MockClient((request) async => http.Response('not json', 200));
      final service = LanguageToolGrammarCheckService(client: client);

      expect(
        () => service.check('text', localeCode: 'en'),
        throwsA(isA<GrammarCheckUnavailableException>()),
      );
    });

    test('a 200 response missing the matches field throws '
        'GrammarCheckUnavailableException', () async {
      final client = MockClient((request) async => http.Response('{}', 200));
      final service = LanguageToolGrammarCheckService(client: client);

      expect(
        () => service.check('text', localeCode: 'en'),
        throwsA(isA<GrammarCheckUnavailableException>()),
      );
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/activity_engine/data/language_tool_grammar_check_service_test.dart`
Expected: FAIL — the service and its target files don't exist yet.

- [ ] **Step 4: Implement the interface**

Create `lib/features/activity_engine/domain/evaluation/grammar_check_service.dart`:

```dart
/// A grammar/spelling-quality signal for one piece of text — the online
/// half of Tier 2's open-ended grading. See docs/superpowers/specs/
/// 2026-09-07-offline-answer-evaluation-design.md.
class GrammarCheckResult {
  const GrammarCheckResult({required this.errorCount, required this.wordCount});

  /// Number of grammar/spelling issues the service flagged.
  final int errorCount;

  /// Word count of the checked text — used to normalize [errorCount] into a
  /// density rather than a raw count, so a longer answer isn't unfairly
  /// penalized for a proportionally similar error rate.
  final int wordCount;
}

/// Thrown for any failure to get a usable result — a non-200 response, a
/// malformed body, a timeout, or no network at all. Callers (the drain
/// service) treat every instance of this identically: retry later, and
/// eventually fall back to the local-only score. Never lets a content bug
/// or a flaky network response crash the drain loop.
class GrammarCheckUnavailableException implements Exception {
  const GrammarCheckUnavailableException(this.message);
  final String message;

  @override
  String toString() => 'GrammarCheckUnavailableException: $message';
}

/// Checks [text] for grammar/spelling issues. Implementations must throw
/// [GrammarCheckUnavailableException] (never let another exception type
/// escape) for any failure — offline, timeout, rate-limited, or malformed
/// response.
abstract interface class GrammarCheckService {
  Future<GrammarCheckResult> check(String text, {required String localeCode});
}
```

- [ ] **Step 5: Implement the real service**

Create `lib/features/activity_engine/data/language_tool_grammar_check_service.dart`:

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/evaluation/grammar_check_service.dart';

final _endpoint = Uri.parse('https://api.languagetool.org/v2/check');
final _whitespace = RegExp(r'\s+');

/// Calls the free public LanguageTool API (`api.languagetool.org`) — no API
/// key, no cost, a soft rate limit of roughly 20 requests/minute per IP with
/// no availability guarantee. This is the one narrow, deliberate exception
/// to this app's otherwise fully-offline design — see
/// docs/adr/0005-narrow-network-exception-for-open-ended-grading.md. Never
/// self-hosted in v1; see the design spec's "Open questions".
class LanguageToolGrammarCheckService implements GrammarCheckService {
  LanguageToolGrammarCheckService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<GrammarCheckResult> check(
    String text, {
    required String localeCode,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            _endpoint,
            body: {
              'text': text,
              'language': localeCode == 'en' ? 'en-US' : localeCode,
            },
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw GrammarCheckUnavailableException('Request failed: $e');
    }

    if (response.statusCode != 200) {
      throw GrammarCheckUnavailableException(
        'LanguageTool returned HTTP ${response.statusCode}',
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const GrammarCheckUnavailableException(
        'Response body was not valid JSON',
      );
    }

    if (decoded is! Map<String, dynamic> || decoded['matches'] is! List) {
      throw const GrammarCheckUnavailableException(
        'Response was missing a matches field',
      );
    }

    final trimmed = text.trim();
    final wordCount = trimmed.isEmpty ? 0 : trimmed.split(_whitespace).length;
    return GrammarCheckResult(
      errorCount: (decoded['matches'] as List).length,
      wordCount: wordCount,
    );
  }
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/features/activity_engine/data/language_tool_grammar_check_service_test.dart`
Expected: PASS

- [ ] **Step 7: Add the fake**

Create `test/features/activity_engine/fake_grammar_check_service.dart`:

```dart
import 'package:mohingo/features/activity_engine/domain/evaluation/grammar_check_service.dart';

/// A fake [GrammarCheckService] with a test-controlled result or failure —
/// standing in for a real network call, which never runs in `flutter test`.
/// See docs/TESTING.md.
class FakeGrammarCheckService implements GrammarCheckService {
  FakeGrammarCheckService({this.result, this.failure});

  /// Returned by [check] when set. Ignored if [failure] is also set.
  GrammarCheckResult? result;

  /// Thrown by [check] when set, taking priority over [result].
  GrammarCheckUnavailableException? failure;

  final List<String> checkedText = [];

  @override
  Future<GrammarCheckResult> check(
    String text, {
    required String localeCode,
  }) async {
    checkedText.add(text);
    if (failure != null) throw failure!;
    return result ?? const GrammarCheckResult(errorCount: 0, wordCount: 1);
  }
}
```

- [ ] **Step 8: Add the provider**

In `lib/features/activity_engine/providers/online_refinement_providers.dart`, add:

```dart
import '../data/language_tool_grammar_check_service.dart';
import '../domain/evaluation/grammar_check_service.dart';

// (alongside the existing connectivityService provider)

@Riverpod(keepAlive: true)
GrammarCheckService grammarCheckService(Ref ref) {
  return LanguageToolGrammarCheckService();
}
```

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 9: Run the full test suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 10: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/features/activity_engine/domain/evaluation/grammar_check_service.dart lib/features/activity_engine/data/language_tool_grammar_check_service.dart lib/features/activity_engine/providers/online_refinement_providers.dart lib/features/activity_engine/providers/online_refinement_providers.g.dart test/features/activity_engine/data/language_tool_grammar_check_service_test.dart test/features/activity_engine/fake_grammar_check_service.dart
git commit -m "feat: add GrammarCheckService (free public LanguageTool API)"
```

---

### Task 5: `pending_online_refinements` table, repository, and schema migration

**Files:**
- Create: `lib/data/local/tables/pending_online_refinement_tables.dart`
- Create: `lib/features/activity_engine/domain/repositories/pending_refinement_repository.dart`
- Create: `lib/features/activity_engine/data/drift_pending_refinement_repository.dart`
- Modify: `lib/data/local/database.dart`
- Modify: `lib/features/activity_engine/providers/online_refinement_providers.dart`
- Test: `test/data/local/database_test.dart`, `test/features/activity_engine/data/drift_pending_refinement_repository_test.dart` (new)

**Interfaces:**
- Produces: `PendingOnlineRefinement` (Drift-generated row class), `PendingRefinementRepository` (`enqueue`, `allPending`, `recordFailedAttempt`, `remove`, `removeAllForLearner`), `DriftPendingRefinementRepository`, `pendingRefinementRepositoryProvider`.

- [ ] **Step 1: Write the failing schema test**

Add to `test/data/local/database_test.dart`:

```dart
test('schema version is 3', () {
  expect(database.schemaVersion, 3);
});

group('pendingOnlineRefinements', () {
  test('can insert and read back a queued refinement', () async {
    final learnerId = await database
        .into(database.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: const Uuid().v4(),
            createdAt: DateTime.utc(2026, 9, 8),
          ),
        );

    await database
        .into(database.pendingOnlineRefinements)
        .insert(
          PendingOnlineRefinementsCompanion.insert(
            uuid: const Uuid().v4(),
            learnerId: learnerId,
            activityId: 'A1-U5-L6-A05',
            lessonId: 'A1-U5-L6',
            unitId: 'A1-U5',
            canDoIds: '["A1.U5.WRITING.WRITE_FREE_TIME_MESSAGE"]',
            rawAnswer: 'See you at the park on Saturday!',
            evidenceSkill: 'writing',
            mode: 'mastery',
            localScore: 0.5,
            submittedAt: DateTime.utc(2026, 9, 8),
          ),
        );

    final rows = await database.select(database.pendingOnlineRefinements).get();
    expect(rows, hasLength(1));
    expect(rows.single.activityId, 'A1-U5-L6-A05');
    expect(rows.single.attemptCount, 0);
    expect(rows.single.lastAttemptAt, isNull);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/local/database_test.dart`
Expected: FAIL — no such table.

- [ ] **Step 3: Define the table**

Create `lib/data/local/tables/pending_online_refinement_tables.dart`:

```dart
import 'package:drift/drift.dart';

import 'learner_tables.dart';

/// A submitted open-ended answer waiting for its free, online grammar-
/// quality pass — Tier 2 of docs/superpowers/specs/
/// 2026-09-07-offline-answer-evaluation-design.md.
///
/// Deliberately **not** a row in `ActivityAttempts` (that table is
/// insert-only, evidence-of-record) — this is a mutable queue. Once an
/// item resolves (online refinement succeeds, or the bounded fallback in
/// [attemptCount]/[submittedAt] triggers), exactly one ordinary
/// `ActivityAttempts` row is inserted and this row is deleted. [canDoIds]
/// and [mode] are copied from the activity at enqueue time (denormalized,
/// like `ActivityAttempts.mode` already is) so resolving an item never
/// needs a fresh content-bundle lookup. [localScore] is the offline
/// `keywordChecklist` content score, computed once at submission time —
/// combined with the online grammar signal (or used alone, on fallback) to
/// produce the final score. See docs/DATA_MODEL.md.
class PendingOnlineRefinements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  IntColumn get learnerId => integer().references(Learners, #id)();
  TextColumn get activityId => text()();
  TextColumn get lessonId => text()();
  TextColumn get unitId => text()();
  TextColumn get canDoIds => text()(); // JSON-encoded List<String>
  TextColumn get rawAnswer => text()();
  TextColumn get evidenceSkill => text()();
  TextColumn get mode => text()(); // encounter | practice | mastery
  RealColumn get localScore => real()();
  DateTimeColumn get submittedAt => dateTime()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
}
```

`unitId` is denormalized here for the same reason `lessonId`/`mode`/`evidenceSkill` are: once an item resolves, `PendingRefinementDrainService` needs to know which unit's cached `unit_progress` row to refresh (see Task 9) without a content-bundle lookup.

- [ ] **Step 4: Register the table and bump the schema**

In `lib/data/local/database.dart`:

```dart
import 'tables/pending_online_refinement_tables.dart';
// (alongside the existing table imports)

@DriftDatabase(
  tables: [
    Learners,
    CourseEnrolments,
    UnitProgress,
    LessonProgress,
    ActivityAttempts,
    ActivityAttemptCanDos,
    PlacementAttempts,
    FinalMissionAttempts,
    FinalAssessmentAttempts,
    VocabularyReviewState,
    GrammarReviewState,
    ContentVersions,
    PendingOnlineRefinements,
  ],
)
class AppDatabase extends _$AppDatabase {
  ...

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(learners, learners.name);
      }
      if (from < 3) {
        await migrator.createTable(pendingOnlineRefinements);
      }
    },
  );
```

- [ ] **Step 5: Extend `resetProgressForLearner`**

Still in `lib/data/local/database.dart`, add one more delete inside the existing `resetProgressForLearner` transaction (a queued-but-unresolved refinement is progress state, same as any attempt — a "reset progress" action must clear it):

```dart
      await (delete(
        pendingOnlineRefinements,
      )..where((t) => t.learnerId.equals(learnerId))).go();
```

(Add it alongside the other `delete(...)` calls, before the closing of the transaction.)

- [ ] **Step 6: Regenerate Drift code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `database.g.dart` regenerates with `PendingOnlineRefinement`/`PendingOnlineRefinementsCompanion` and the table wired into `AppDatabase`.

- [ ] **Step 7: Run tests to verify they pass**

Run: `flutter test test/data/local/database_test.dart`
Expected: PASS

- [ ] **Step 8: Write the repository interface**

Create `lib/features/activity_engine/domain/repositories/pending_refinement_repository.dart`:

```dart
import '../../../../data/local/database.dart';

/// Queues and resolves open-ended answers awaiting a free online
/// grammar-quality pass — see [PendingOnlineRefinements] and
/// docs/superpowers/specs/2026-09-07-offline-answer-evaluation-design.md.
abstract interface class PendingRefinementRepository {
  /// Queues one submitted answer. [canDoIds] is stored JSON-encoded;
  /// [localScore] is the already-computed offline content score. [unitId]
  /// is stored so a later resolution can refresh that unit's cached
  /// mastery state without a content-bundle lookup.
  Future<int> enqueue({
    required int learnerId,
    required String activityId,
    required String lessonId,
    required String unitId,
    required List<String> canDoIds,
    required String rawAnswer,
    required String evidenceSkill,
    required String mode,
    required double localScore,
  });

  /// Every queued item across every learner — the drain service resolves
  /// whichever learner's items it can reach; in practice there is only one
  /// local learner in v1.
  Future<List<PendingOnlineRefinement>> allPending();

  /// Bumps [id]'s retry bookkeeping after a failed online attempt — never
  /// removes the row.
  Future<void> recordFailedAttempt({
    required int id,
    required DateTime attemptedAt,
  });

  /// Removes [id] once it's been resolved (recorded as a real attempt),
  /// online or via the bounded fallback.
  Future<void> remove({required int id});

  /// Clears every queued item for [learnerId] — used by
  /// `AppDatabase.resetProgressForLearner`.
  Future<void> removeAllForLearner({required int learnerId});
}
```

- [ ] **Step 9: Write the failing repository test**

Create `test/features/activity_engine/data/drift_pending_refinement_repository_test.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/activity_engine/data/drift_pending_refinement_repository.dart';
import 'package:uuid/uuid.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftPendingRefinementRepository repository;
  late int learnerId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftPendingRefinementRepository(db);
    learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: const Uuid().v4(),
            createdAt: DateTime.utc(2026, 9, 8),
          ),
        );
  });

  tearDown(() => db.close());

  test('enqueue then allPending round-trips every field', () async {
    await repository.enqueue(
      learnerId: learnerId,
      activityId: 'A1-U5-L6-A05',
      lessonId: 'A1-U5-L6',
      unitId: 'A1-U5',
      canDoIds: ['A1.U5.WRITING.WRITE_FREE_TIME_MESSAGE'],
      rawAnswer: 'See you at the park on Saturday!',
      evidenceSkill: 'writing',
      mode: 'mastery',
      localScore: 0.5,
    );

    final pending = await repository.allPending();
    expect(pending, hasLength(1));
    expect(pending.single.activityId, 'A1-U5-L6-A05');
    expect(pending.single.canDoIds, '["A1.U5.WRITING.WRITE_FREE_TIME_MESSAGE"]');
    expect(pending.single.localScore, 0.5);
    expect(pending.single.attemptCount, 0);
  });

  test('recordFailedAttempt increments attemptCount and sets lastAttemptAt', () async {
    final id = await repository.enqueue(
      learnerId: learnerId,
      activityId: 'A1-U5-L6-A05',
      lessonId: 'A1-U5-L6',
      unitId: 'A1-U5',
      canDoIds: const [],
      rawAnswer: 'answer',
      evidenceSkill: 'writing',
      mode: 'mastery',
      localScore: 0.0,
    );

    await repository.recordFailedAttempt(
      id: id,
      attemptedAt: DateTime.utc(2026, 9, 8, 10),
    );

    final pending = await repository.allPending();
    expect(pending.single.attemptCount, 1);
    expect(pending.single.lastAttemptAt, DateTime.utc(2026, 9, 8, 10));
  });

  test('remove deletes the row', () async {
    final id = await repository.enqueue(
      learnerId: learnerId,
      activityId: 'A1-U5-L6-A05',
      lessonId: 'A1-U5-L6',
      unitId: 'A1-U5',
      canDoIds: const [],
      rawAnswer: 'answer',
      evidenceSkill: 'writing',
      mode: 'mastery',
      localScore: 0.0,
    );

    await repository.remove(id: id);

    expect(await repository.allPending(), isEmpty);
  });

  test('removeAllForLearner clears only that learner\'s rows', () async {
    final otherLearnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: const Uuid().v4(),
            createdAt: DateTime.utc(2026, 9, 8),
          ),
        );
    await repository.enqueue(
      learnerId: learnerId,
      activityId: 'A1-TEST-A',
      lessonId: 'A1-TEST-L',
      unitId: 'A1-TEST',
      canDoIds: const [],
      rawAnswer: 'answer',
      evidenceSkill: 'writing',
      mode: 'mastery',
      localScore: 0.0,
    );
    await repository.enqueue(
      learnerId: otherLearnerId,
      activityId: 'A1-TEST-B',
      lessonId: 'A1-TEST-L',
      unitId: 'A1-TEST',
      canDoIds: const [],
      rawAnswer: 'answer',
      evidenceSkill: 'writing',
      mode: 'mastery',
      localScore: 0.0,
    );

    await repository.removeAllForLearner(learnerId: learnerId);

    final remaining = await repository.allPending();
    expect(remaining, hasLength(1));
    expect(remaining.single.learnerId, otherLearnerId);
  });
}
```

- [ ] **Step 10: Run test to verify it fails**

Run: `flutter test test/features/activity_engine/data/drift_pending_refinement_repository_test.dart`
Expected: FAIL — `drift_pending_refinement_repository.dart` doesn't exist yet.

- [ ] **Step 11: Implement**

Create `lib/features/activity_engine/data/drift_pending_refinement_repository.dart`:

```dart
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/database.dart';
import '../domain/repositories/pending_refinement_repository.dart';

class DriftPendingRefinementRepository implements PendingRefinementRepository {
  DriftPendingRefinementRepository(this._db, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Future<int> enqueue({
    required int learnerId,
    required String activityId,
    required String lessonId,
    required String unitId,
    required List<String> canDoIds,
    required String rawAnswer,
    required String evidenceSkill,
    required String mode,
    required double localScore,
  }) {
    final now = DateTime.now();
    return _db
        .into(_db.pendingOnlineRefinements)
        .insert(
          PendingOnlineRefinementsCompanion.insert(
            uuid: _uuid.v4(),
            learnerId: learnerId,
            activityId: activityId,
            lessonId: lessonId,
            unitId: unitId,
            canDoIds: jsonEncode(canDoIds),
            rawAnswer: rawAnswer,
            evidenceSkill: evidenceSkill,
            mode: mode,
            localScore: localScore,
            submittedAt: now,
          ),
        );
  }

  @override
  Future<List<PendingOnlineRefinement>> allPending() {
    return _db.select(_db.pendingOnlineRefinements).get();
  }

  @override
  Future<void> recordFailedAttempt({
    required int id,
    required DateTime attemptedAt,
  }) async {
    final row = await (_db.select(
      _db.pendingOnlineRefinements,
    )..where((t) => t.id.equals(id))).getSingle();
    await (_db.update(
      _db.pendingOnlineRefinements,
    )..where((t) => t.id.equals(id))).write(
      PendingOnlineRefinementsCompanion(
        attemptCount: Value(row.attemptCount + 1),
        lastAttemptAt: Value(attemptedAt),
      ),
    );
  }

  @override
  Future<void> remove({required int id}) async {
    await (_db.delete(
      _db.pendingOnlineRefinements,
    )..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> removeAllForLearner({required int learnerId}) async {
    await (_db.delete(
      _db.pendingOnlineRefinements,
    )..where((t) => t.learnerId.equals(learnerId))).go();
  }
}
```

- [ ] **Step 12: Run test to verify it passes**

Run: `flutter test test/features/activity_engine/data/drift_pending_refinement_repository_test.dart`
Expected: PASS

- [ ] **Step 13: Add the provider**

In `lib/features/activity_engine/providers/online_refinement_providers.dart`, add:

```dart
import '../../../data/local/database_provider.dart';
import '../data/drift_pending_refinement_repository.dart';
import '../domain/repositories/pending_refinement_repository.dart';

// (alongside the existing providers in this file)

@Riverpod(keepAlive: true)
PendingRefinementRepository pendingRefinementRepository(Ref ref) {
  return DriftPendingRefinementRepository(ref.watch(appDatabaseProvider));
}
```

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 14: Run the full test suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 15: Commit**

```bash
git add lib/data/local/tables/pending_online_refinement_tables.dart lib/data/local/database.dart lib/data/local/database.g.dart lib/features/activity_engine/domain/repositories/pending_refinement_repository.dart lib/features/activity_engine/data/drift_pending_refinement_repository.dart lib/features/activity_engine/providers/online_refinement_providers.dart lib/features/activity_engine/providers/online_refinement_providers.g.dart test/data/local/database_test.dart test/features/activity_engine/data/drift_pending_refinement_repository_test.dart
git commit -m "feat: add pending_online_refinements queue table and repository (schema v2 to v3)"
```

---

### Task 6: Wire `WriteActivityView` to enqueue instead of grade

**Files:**
- Modify: `lib/features/activity_engine/presentation/views/write_activity_view.dart`
- Modify: `lib/features/activity_engine/presentation/activity_chrome.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`
- Test: `test/features/activity_engine/write_activity_view_test.dart`

**Interfaces:**
- Consumes: `KeywordChecklistEvaluationSpec.onlineRefinement` (Task 1), `ActivitySubmission.pendingOnlineRefinement` (Task 2), `evaluate()` (existing, Tier 1).
- Produces: a new pending-refinement visual state on `ActivityFeedbackBanner`.

- [ ] **Step 1: Add the disclosure copy**

In `lib/l10n/app_en.arb`, add:

```json
"activityFeedbackPendingOnlineRefinement": "Saved — we'll finish checking this once you're online",
"@activityFeedbackPendingOnlineRefinement": {
  "description": "Feedback banner shown after submitting an open-ended writing/speaking answer whose full grading is deferred until the device is online (Tier 2 online refinement)."
}
```

In `lib/l10n/app_ar.arb`, add the matching natively-written Arabic (not machine-translated):

```json
"activityFeedbackPendingOnlineRefinement": "تم الحفظ — سنكمل تصحيح هذه الإجابة عند اتصالك بالإنترنت"
```

Run: `flutter gen-l10n`

- [ ] **Step 2: Write the failing test**

Add to `test/features/activity_engine/write_activity_view_test.dart`:

```dart
testWidgets(
  'an activity with an onlineRefinement rubric is queued, not graded, '
  'and shows the pending-online-refinement banner',
  (tester) async {
    const activity = WriteActivity(
      id: 'A1-U5-L6-A05',
      lessonId: 'A1-U5-L6',
      mode: ActivityMode.mastery,
      skill: Skill.writing,
      canDo: ['A1.U5.WRITING.WRITE_FREE_TIME_MESSAGE'],
      prompt: 'Write a message about your free time.',
      promptAr: 'اكتب رسالة عن وقت فراغك.',
      raw: {},
      accepted: [],
      evaluation: KeywordChecklistEvaluationSpec(
        requiredGroups: [
          ['hi', 'hello'],
        ],
        minGroupsMatched: 1,
        onlineRefinement: 'grammarCheck',
      ),
      wordGuide: [35, 55],
    );

    ActivitySubmission? captured;
    await tester.pumpActivityView(
      WriteActivityView(
        activity: activity,
        onSubmitted: (s) => captured = s,
      ),
    );

    await tester.enterText(find.byType(TextField), 'Hello! Free on Saturday?');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Check'));
    await tester.pump();

    expect(captured!.pendingOnlineRefinement, isTrue);
    expect(captured!.correctness, ActivityCorrectness.notAutoGraded);
    expect(captured!.score, 1.0); // 1 of 1 required group matched, locally
    expect(
      find.text('Saved — we\'ll finish checking this once you\'re online'),
      findsOneWidget,
    );
  },
);
```

(Add the `KeywordChecklistEvaluationSpec` import from `package:mohingo/content/models/evaluation_spec.dart` alongside this file's existing imports, if not already present via Tier 1's `NonEmptyEvaluationSpec` test.)

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/activity_engine/write_activity_view_test.dart`
Expected: FAIL — `captured!.pendingOnlineRefinement` is `false` (falls through to the ordinary `evaluate()` branch today), and the new banner text doesn't exist.

- [ ] **Step 4: Add the pending-refinement banner state**

In `lib/features/activity_engine/presentation/activity_chrome.dart`, `ActivityFeedbackBanner.build()`:

```dart
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final (
      Color background,
      Color onColor,
      IconData icon,
      String label,
    ) = submission.pendingOnlineRefinement
        ? (
            colorScheme.surfaceContainerHighest,
            colorScheme.onSurface,
            Icons.cloud_sync,
            l10n.activityFeedbackPendingOnlineRefinement,
          )
        : switch (submission.correctness) {
            ActivityCorrectness.correct => (
              colorScheme.primaryContainer,
              colorScheme.onPrimaryContainer,
              Icons.check_circle,
              l10n.activityFeedbackCorrect,
            ),
            ActivityCorrectness.incorrect => (
              colorScheme.errorContainer,
              colorScheme.onErrorContainer,
              Icons.cancel,
              l10n.activityFeedbackIncorrectWithAnswer(correctAnswerLabel ?? ''),
            ),
            ActivityCorrectness.notAutoGraded => (
              colorScheme.surfaceContainerHighest,
              colorScheme.onSurface,
              Icons.hourglass_top,
              l10n.activityFeedbackSavedForReview,
            ),
          };

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: onColor),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: TextStyle(color: onColor))),
          ],
        ),
      ),
    );
  }
```

(Only the destructuring assignment changes — everything from `return Semantics(...)` onward is unchanged.)

- [ ] **Step 5: Wire the enqueue-detection branch in `_submit()`**

In `lib/features/activity_engine/presentation/views/write_activity_view.dart`, add the import:

```dart
import '../../../../content/models/evaluation_spec.dart';
```

Insert a new branch in `_submit()`, **before** the existing `widget.activity.evaluation != null` branch (order matters — an online-refinement rubric must be caught here first, not fall through to being graded synchronously):

```dart
  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || _submission != null) return;

    final ActivitySubmission submission;
    final evaluation = widget.activity.evaluation;
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
    } else if (evaluation is KeywordChecklistEvaluationSpec &&
        evaluation.onlineRefinement != null) {
      // Open-ended, deferred-grading path: the local score is computed now
      // but never used as the graded score directly — it's carried through
      // to the pending_online_refinements queue and combined with a free
      // online grammar-quality pass once the device is online. See
      // docs/superpowers/specs/2026-09-07-offline-answer-evaluation-design.md.
      final localResult = evaluate(evaluation, text);
      submission = ActivitySubmission(
        correctness: ActivityCorrectness.notAutoGraded,
        score: localResult.score,
        rawAnswerJson: jsonEncode(text),
        pendingOnlineRefinement: true,
      );
    } else if (evaluation != null) {
      final result = evaluate(evaluation, text, context: widget.evaluationContext);
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

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/features/activity_engine/write_activity_view_test.dart`
Expected: PASS

- [ ] **Step 7: Run the full test suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add lib/features/activity_engine/presentation/views/write_activity_view.dart lib/features/activity_engine/presentation/activity_chrome.dart lib/l10n/app_en.arb lib/l10n/app_ar.arb lib/core/l10n/generated/ test/features/activity_engine/write_activity_view_test.dart
git commit -m "feat: queue open-ended WriteActivity answers for online refinement instead of grading them"
```

---

### Task 7: Wire `SpeakActivityView` to enqueue instead of grade

**Files:**
- Modify: `lib/features/activity_engine/presentation/views/speak_activity_view.dart`
- Test: `test/features/activity_engine/speak_activity_view_test.dart`

**Interfaces:**
- Consumes: the same as Task 6, applied to `SpeakActivity`/`_submit(text, {wasFallback})`.

- [ ] **Step 1: Write the failing test**

Add to `test/features/activity_engine/speak_activity_view_test.dart`:

```dart
testWidgets(
  'an activity with an onlineRefinement rubric is queued through the '
  'typed-fallback path, not graded',
  (tester) async {
    const activity = SpeakActivity(
      id: 'A1-U5-L6-A05',
      lessonId: 'A1-U5-L6',
      mode: ActivityMode.mastery,
      skill: Skill.spokenProduction,
      canDo: ['A1.U5.WRITING.WRITE_FREE_TIME_MESSAGE'],
      prompt: 'Tell a friend about your free time.',
      promptAr: 'أخبر صديقاً عن وقت فراغك.',
      raw: {},
      accepted: [],
      evaluation: KeywordChecklistEvaluationSpec(
        requiredGroups: [
          ['hi', 'hello'],
        ],
        minGroupsMatched: 1,
        onlineRefinement: 'grammarCheck',
      ),
      fallbackSkill: 'writing',
    );

    ActivitySubmission? captured;
    await _pumpSpeak(
      tester,
      activity: activity,
      capabilities: const DeviceSpeechCapabilities(
        sttAvailableForLocale: false,
        micPermission: SpeechPermissionStatus.notDetermined,
      ),
      onSubmitted: (s) => captured = s,
    );

    await tester.enterText(find.byType(TextField), 'Hello! Free on Saturday?');
    await tester.pump();
    await tester.tap(find.text('Check'));
    await tester.pump();

    expect(captured!.pendingOnlineRefinement, isTrue);
    expect(captured!.correctness, ActivityCorrectness.notAutoGraded);
    expect(captured!.wasFallback, isTrue);
  },
);
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/activity_engine/speak_activity_view_test.dart`
Expected: FAIL — `captured!.pendingOnlineRefinement` is `false`.

- [ ] **Step 3: Implement**

In `lib/features/activity_engine/presentation/views/speak_activity_view.dart`, add the import:

```dart
import '../../../../content/models/evaluation_spec.dart';
```

Apply the same branch reordering to `_submit(text, {required bool wasFallback})` as Task 6 did for `WriteActivityView`:

```dart
  void _submit(String text, {required bool wasFallback}) {
    if (_submission != null) return;

    final ActivitySubmission submission;
    final evaluation = widget.activity.evaluation;
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
    } else if (evaluation is KeywordChecklistEvaluationSpec &&
        evaluation.onlineRefinement != null) {
      final localResult = evaluate(evaluation, text);
      submission = ActivitySubmission(
        correctness: ActivityCorrectness.notAutoGraded,
        score: localResult.score,
        rawAnswerJson: jsonEncode(text),
        wasFallback: wasFallback,
        pendingOnlineRefinement: true,
      );
    } else if (evaluation != null) {
      final result = evaluate(evaluation, text, context: widget.evaluationContext);
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

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/activity_engine/speak_activity_view_test.dart`
Expected: PASS

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/activity_engine/presentation/views/speak_activity_view.dart test/features/activity_engine/speak_activity_view_test.dart
git commit -m "feat: queue open-ended SpeakActivity answers for online refinement instead of grading them"
```

---

### Task 8: Lesson player enqueues instead of recording an attempt

**Files:**
- Modify: `lib/features/lesson_player/presentation/lesson_player_screen.dart`
- Test: `test/features/lesson_player/lesson_player_e2e_test.dart`

**Interfaces:**
- Consumes: `ActivitySubmission.pendingOnlineRefinement` (Task 2), `PendingRefinementRepository.enqueue` + `pendingRefinementRepositoryProvider` (Task 5).

- [ ] **Step 1: Write the failing test**

Add a new test to `test/features/lesson_player/lesson_player_e2e_test.dart`, in the same `main()`, driving A1-U5-L6 up to its final activity (`A1-U5-L6-A05`, the real `u5-free-time-message-rubric` activity Task 12 migrates) and confirming it's queued, not recorded, until then:

```dart
testWidgets(
  'an onlineRefinement activity is queued in pending_online_refinements, '
  'not recorded as an ordinary attempt, when submitted',
  (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final index = _realA1Index();
    final lesson = index.lessonsById['A1-U5-L6']!;
    final lastActivity = lesson.activities.last;
    expect(
      lastActivity.id,
      'A1-U5-L6-A05',
      reason:
          'this test is written against the real content shape — if '
          'A1-U5-L6 changes, update the assumption here alongside it',
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
            unitId: 'A1-U5',
            lessonId: 'A1-U5-L6',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final activity in lesson.activities.sublist(0, lesson.activities.length - 1)) {
      await _answerAndAdvance(tester, activity);
    }

    // A1-U5-L6-A05 — a `write` activity with wordGuide [35, 55]; drive it
    // manually, since a wordGuide-shaped answer isn't what
    // _answerAndAdvance's generic "an answer" text produces.
    await tester.enterText(
      find.byType(TextField),
      'Hello! I love hiking and reading on weekends. Would you like to join '
      'me for a walk in the park this Saturday afternoon?',
    );
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    final attemptRows = await (db.select(
      db.activityAttempts,
    )..where((t) => t.activityId.equals('A1-U5-L6-A05'))).get();
    expect(
      attemptRows,
      isEmpty,
      reason: 'a queued, not-yet-refined answer must not appear as an '
          'ordinary attempt yet',
    );

    final pendingRows = await (db.select(
      db.pendingOnlineRefinements,
    )..where((t) => t.activityId.equals('A1-U5-L6-A05'))).get();
    expect(pendingRows, hasLength(1));
    expect(pendingRows.single.lessonId, 'A1-U5-L6');
    expect(pendingRows.single.unitId, 'A1-U5');
    expect(pendingRows.single.mode, 'mastery');

    await db.close();
  },
);
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/lesson_player/lesson_player_e2e_test.dart`
Expected: FAIL — `A1-U5-L6-A05`'s `evaluation` is still the legacy opaque string at this point (migrated in Task 12), so it grades as `notAutoGraded` via the ordinary path and lands in `activity_attempts`, not the queue. This is expected — confirm the failure reason specifically (an unexpected row in `attemptRows`), not a crash.

- [ ] **Step 3: Implement**

In `lib/features/lesson_player/presentation/lesson_player_screen.dart`, add the import:

```dart
import '../../activity_engine/providers/online_refinement_providers.dart';
```

In `_LessonPlayerBodyState._handleSubmitted`, branch before the existing `recordAttempt` call:

```dart
  Future<void> _handleSubmitted(
    Activity activity,
    ActivitySubmission submission,
  ) async {
    if (submission.rawAnswerJson != null) {
      final decoded = jsonDecode(submission.rawAnswerJson!);
      if (decoded is String) _previousAnswers[activity.id] = decoded;
    }

    final evidenceSkill = resolveEvidenceSkill(activity, submission);

    if (submission.pendingOnlineRefinement) {
      await ref
          .read(pendingRefinementRepositoryProvider)
          .enqueue(
            learnerId: widget.learnerId,
            activityId: activity.id,
            lessonId: widget.lesson.id,
            unitId: widget.unitId,
            canDoIds: activity.canDo,
            rawAnswer: submission.rawAnswerJson!,
            evidenceSkill: evidenceSkill.name,
            mode: activity.mode.name,
            localScore: submission.score ?? 0.0,
          );
    } else {
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
    }

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

(Every line after the new `if`/`else` branch is unchanged from what exists today — the position update, invalidations, and `_lastSubmission` set all still run for a queued submission, exactly as for a graded one: the learner still moves on to the next activity either way.)

- [ ] **Step 4: Run test to verify it fails for the expected reason, still**

Run: `flutter test test/features/lesson_player/lesson_player_e2e_test.dart`
Expected: still FAIL — the code path is now correct, but `A1-U5-L6-A05` still carries the legacy string `evaluation`, which Tier 1's `EvaluationSpec.fromJson` parses to `null`, so `submission.pendingOnlineRefinement` is still `false`. Confirm the failure is specifically this (still no pending row, and now also no attempt row, since `null` evaluation falls to `notAutoGraded` — check the assertion messages to confirm which one fails and why) rather than a crash.

- [ ] **Step 5: Run the full test suite for fallout**

Run: `flutter test`
Expected: only the new test (from Step 1) fails, for the reason confirmed in Step 4.

- [ ] **Step 6: Commit**

```bash
git add lib/features/lesson_player/presentation/lesson_player_screen.dart test/features/lesson_player/lesson_player_e2e_test.dart
git commit -m "feat: enqueue pending-online-refinement submissions instead of recording them as attempts"
```

---

### Task 9: `PendingRefinementDrainService`

**Files:**
- Create: `lib/features/activity_engine/domain/evaluation/pending_refinement_drain_service.dart`
- Test: `test/features/activity_engine/domain/evaluation/pending_refinement_drain_service_test.dart`

**Interfaces:**
- Consumes: `PendingRefinementRepository` (Task 5, including its `unitId`-bearing `enqueue`), `GrammarCheckService`/`GrammarCheckResult`/`GrammarCheckUnavailableException` (Task 4), `ActivityAttemptRepository.recordAttempt` (existing).
- Produces: `PendingRefinementDrainService.drainOnce({int maxItems})`, `OnItemResolved` typedef (`Future<void> Function({required int learnerId, required String unitId})`) — the drain service itself knows nothing about Riverpod or mastery aggregation; Task 10's provider supplies this callback to refresh the affected unit's cached mastery state and invalidate the relevant providers once an item actually resolves. Called only when `_finalize` runs (a real attempt was recorded) — never for a mere failed-attempt retry, since nothing changed in that case.

- [ ] **Step 1: Write the failing tests**

Create `test/features/activity_engine/domain/evaluation/pending_refinement_drain_service_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/activity_engine/data/drift_pending_refinement_repository.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/grammar_check_service.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/pending_refinement_drain_service.dart';
import 'package:mohingo/features/progress/data/drift_activity_attempt_repository.dart';
import 'package:uuid/uuid.dart';

import '../../fake_grammar_check_service.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftPendingRefinementRepository pendingRepository;
  late DriftActivityAttemptRepository attemptRepository;
  late int learnerId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    pendingRepository = DriftPendingRefinementRepository(db);
    attemptRepository = DriftActivityAttemptRepository(db);
    learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: const Uuid().v4(),
            createdAt: DateTime.utc(2026, 9, 8),
          ),
        );
  });

  tearDown(() => db.close());

  test('a successful grammar check combines with the local score and '
      'records a real attempt, removing the queue row', () async {
    await pendingRepository.enqueue(
      learnerId: learnerId,
      activityId: 'A1-U5-L6-A05',
      lessonId: 'A1-U5-L6',
      unitId: 'A1-U5',
      canDoIds: ['A1.U5.WRITING.WRITE_FREE_TIME_MESSAGE'],
      rawAnswer: 'Hello! Free time message.',
      evidenceSkill: 'writing',
      mode: 'mastery',
      localScore: 1.0,
    );
    final grammarCheckService = FakeGrammarCheckService(
      result: const GrammarCheckResult(errorCount: 0, wordCount: 5),
    );
    final resolved = <({int learnerId, String unitId})>[];
    final service = PendingRefinementDrainService(
      pendingRepository: pendingRepository,
      attemptRepository: attemptRepository,
      grammarCheckService: grammarCheckService,
      onItemResolved: ({required learnerId, required unitId}) async {
        resolved.add((learnerId: learnerId, unitId: unitId));
      },
    );

    await service.drainOnce();

    expect(await pendingRepository.allPending(), isEmpty);
    final attempts = await (db.select(
      db.activityAttempts,
    )..where((t) => t.activityId.equals('A1-U5-L6-A05'))).get();
    expect(attempts, hasLength(1));
    expect(attempts.single.score, isNotNull);
    expect(attempts.single.score! > 0.9, isTrue); // no grammar errors, full local score
    expect(attempts.single.isCorrect, isTrue);
    expect(attempts.single.mode, 'mastery');
    expect(resolved, [(learnerId: learnerId, unitId: 'A1-U5')]);
  });

  test('many grammar errors pull the combined score down, but content '
      'coverage still dominates', () async {
    await pendingRepository.enqueue(
      learnerId: learnerId,
      activityId: 'A1-U5-L6-A05',
      lessonId: 'A1-U5-L6',
      unitId: 'A1-U5',
      canDoIds: const [],
      rawAnswer: 'answer',
      evidenceSkill: 'writing',
      mode: 'mastery',
      localScore: 1.0,
    );
    final grammarCheckService = FakeGrammarCheckService(
      result: const GrammarCheckResult(errorCount: 10, wordCount: 5),
    );
    final service = PendingRefinementDrainService(
      pendingRepository: pendingRepository,
      attemptRepository: attemptRepository,
      grammarCheckService: grammarCheckService,
    );

    await service.drainOnce();

    final attempts = await db.select(db.activityAttempts).get();
    expect(attempts.single.score! < 1.0, isTrue);
    expect(attempts.single.score! > 0.5, isTrue); // content score still dominates
  });

  test('a failed grammar check (below the retry threshold) is not '
      'finalized — the queue row stays, with its attempt count bumped', () async {
    await pendingRepository.enqueue(
      learnerId: learnerId,
      activityId: 'A1-U5-L6-A05',
      lessonId: 'A1-U5-L6',
      unitId: 'A1-U5',
      canDoIds: const [],
      rawAnswer: 'answer',
      evidenceSkill: 'writing',
      mode: 'mastery',
      localScore: 1.0,
    );
    final grammarCheckService = FakeGrammarCheckService(
      failure: const GrammarCheckUnavailableException('offline'),
    );
    var resolvedCallbackFired = false;
    final service = PendingRefinementDrainService(
      pendingRepository: pendingRepository,
      attemptRepository: attemptRepository,
      grammarCheckService: grammarCheckService,
      onItemResolved: ({required learnerId, required unitId}) async {
        resolvedCallbackFired = true;
      },
    );

    await service.drainOnce();

    expect(await db.select(db.activityAttempts).get(), isEmpty);
    final pending = await pendingRepository.allPending();
    expect(pending, hasLength(1));
    expect(pending.single.attemptCount, 1);
    expect(
      resolvedCallbackFired,
      isFalse,
      reason: 'nothing was actually resolved, so the callback must not fire',
    );
  });

  test('a queue row that has failed enough times finalizes via the '
      'local-only score — the bounded fallback', () async {
    final id = await pendingRepository.enqueue(
      learnerId: learnerId,
      activityId: 'A1-U5-L6-A05',
      lessonId: 'A1-U5-L6',
      unitId: 'A1-U5',
      canDoIds: const [],
      rawAnswer: 'answer',
      evidenceSkill: 'writing',
      mode: 'mastery',
      localScore: 0.8,
    );
    // Pre-fail it 4 times, one below the default threshold of 5.
    for (var i = 0; i < 4; i++) {
      await pendingRepository.recordFailedAttempt(
        id: id,
        attemptedAt: DateTime.utc(2026, 9, 8),
      );
    }
    final grammarCheckService = FakeGrammarCheckService(
      failure: const GrammarCheckUnavailableException('still offline'),
    );
    final service = PendingRefinementDrainService(
      pendingRepository: pendingRepository,
      attemptRepository: attemptRepository,
      grammarCheckService: grammarCheckService,
    );

    await service.drainOnce();

    expect(await pendingRepository.allPending(), isEmpty);
    final attempts = await db.select(db.activityAttempts).get();
    expect(attempts, hasLength(1));
    expect(attempts.single.score, 0.8); // local-only score, unrefined
  });

  test('an old-enough queue row finalizes via the local-only score even '
      'on its very first failed attempt — the age-based fallback', () async {
    await pendingRepository.enqueue(
      learnerId: learnerId,
      activityId: 'A1-U5-L6-A05',
      lessonId: 'A1-U5-L6',
      unitId: 'A1-U5',
      canDoIds: const [],
      rawAnswer: 'answer',
      evidenceSkill: 'writing',
      mode: 'mastery',
      localScore: 0.6,
    );
    // enqueue() always stamps `now`, so directly age the row for this test.
    await (db.update(db.pendingOnlineRefinements)..where((t) => t.activityId.equals('A1-U5-L6-A05')))
        .write(
      PendingOnlineRefinementsCompanion(
        submittedAt: Value(DateTime.now().subtract(const Duration(days: 30))),
      ),
    );
    final grammarCheckService = FakeGrammarCheckService(
      failure: const GrammarCheckUnavailableException('offline'),
    );
    final service = PendingRefinementDrainService(
      pendingRepository: pendingRepository,
      attemptRepository: attemptRepository,
      grammarCheckService: grammarCheckService,
    );

    await service.drainOnce();

    expect(await pendingRepository.allPending(), isEmpty);
    final attempts = await db.select(db.activityAttempts).get();
    expect(attempts.single.score, 0.6);
  });

  test('drainOnce processes at most maxItems queue rows in one call',
      () async {
    for (var i = 0; i < 3; i++) {
      await pendingRepository.enqueue(
        learnerId: learnerId,
        activityId: 'A1-TEST-A0$i',
        lessonId: 'A1-TEST-L',
        unitId: 'A1-TEST',
        canDoIds: const [],
        rawAnswer: 'answer',
        evidenceSkill: 'writing',
        mode: 'mastery',
        localScore: 1.0,
      );
    }
    final grammarCheckService = FakeGrammarCheckService(
      result: const GrammarCheckResult(errorCount: 0, wordCount: 2),
    );
    final service = PendingRefinementDrainService(
      pendingRepository: pendingRepository,
      attemptRepository: attemptRepository,
      grammarCheckService: grammarCheckService,
    );

    await service.drainOnce(maxItems: 2);

    expect(await pendingRepository.allPending(), hasLength(1));
  });
}
```

(You need `import 'package:drift/drift.dart';` for `Value` in the age-based fallback test — check the file's imports.)

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/activity_engine/domain/evaluation/pending_refinement_drain_service_test.dart`
Expected: FAIL — `pending_refinement_drain_service.dart` doesn't exist yet.

- [ ] **Step 3: Implement**

Create `lib/features/activity_engine/domain/evaluation/pending_refinement_drain_service.dart`:

```dart
import 'dart:convert';

import '../../../../content/models/domain_definitions.dart';
import '../../../../data/local/database.dart';
import '../../../progress/domain/repositories/activity_attempt_repository.dart';
import '../repositories/pending_refinement_repository.dart';
import 'grammar_check_service.dart';

/// Called after a queue row is actually finalized (recorded as a real
/// attempt and removed) — never for a mere failed-attempt retry. Lets the
/// caller refresh whatever depends on that unit's mastery state without
/// this service knowing anything about Riverpod or content lookups. See
/// Task 10.
typedef OnItemResolved =
    Future<void> Function({required int learnerId, required String unitId});

/// Resolves queued open-ended answers: a real online grammar-quality pass
/// when it succeeds, or — once a row has failed enough times or sat long
/// enough — its already-stored local content score alone. Either way, this
/// is the only place a `pending_online_refinements` row turns into a real
/// `ActivityAttempts` row. See docs/superpowers/specs/
/// 2026-09-07-offline-answer-evaluation-design.md's Tier 2 and
/// docs/adr/0005-narrow-network-exception-for-open-ended-grading.md.
class PendingRefinementDrainService {
  PendingRefinementDrainService({
    required PendingRefinementRepository pendingRepository,
    required ActivityAttemptRepository attemptRepository,
    required GrammarCheckService grammarCheckService,
    this.onItemResolved,
    this.maxAttemptsBeforeFallback = 5,
    this.maxAgeBeforeFallback = const Duration(days: 14),
  }) : _pendingRepository = pendingRepository,
       _attemptRepository = attemptRepository,
       _grammarCheckService = grammarCheckService;

  final PendingRefinementRepository _pendingRepository;
  final ActivityAttemptRepository _attemptRepository;
  final GrammarCheckService _grammarCheckService;

  /// Invoked once per finalized item — see [OnItemResolved]. `null` (the
  /// default) is a legitimate choice for a caller that doesn't need it
  /// (e.g. a script or test with no provider tree to refresh).
  final OnItemResolved? onItemResolved;

  /// A queue row this many failed attempts old finalizes via its local
  /// score alone, rather than waiting on the network indefinitely.
  final int maxAttemptsBeforeFallback;

  /// A queue row this old finalizes via its local score alone even on its
  /// first failed attempt — the age bound, independent of retry count.
  final Duration maxAgeBeforeFallback;

  /// Resolves up to [maxItems] queued rows. Safe to call opportunistically
  /// and often — an empty queue is a no-op, and every row either resolves
  /// or is left untouched for the next call.
  Future<void> drainOnce({int maxItems = 5}) async {
    final pending = await _pendingRepository.allPending();
    for (final item in pending.take(maxItems)) {
      await _resolveOne(item);
    }
  }

  Future<void> _resolveOne(PendingOnlineRefinement item) async {
    GrammarCheckResult? grammarResult;
    try {
      grammarResult = await _grammarCheckService.check(
        item.rawAnswer,
        localeCode: 'en',
      );
    } on GrammarCheckUnavailableException {
      grammarResult = null;
    }

    if (grammarResult == null) {
      final age = DateTime.now().difference(item.submittedAt);
      final wouldExceedAttempts =
          item.attemptCount + 1 >= maxAttemptsBeforeFallback;
      if (wouldExceedAttempts || age >= maxAgeBeforeFallback) {
        await _finalize(item, score: item.localScore);
      } else {
        await _pendingRepository.recordFailedAttempt(
          id: item.id,
          attemptedAt: DateTime.now(),
        );
      }
      return;
    }

    await _finalize(item, score: _combineScores(item.localScore, grammarResult));
  }

  /// Content coverage (the offline score) still dominates: grammar quality
  /// can subtract at most 30% of the final score, and only in proportion to
  /// how error-dense the answer actually is. A learner who covers every
  /// required point with a few typos should still pass; grammar alone can
  /// never turn a fully-covered answer into a failing one.
  double _combineScores(double localScore, GrammarCheckResult grammar) {
    final words = grammar.wordCount == 0 ? 1 : grammar.wordCount;
    final errorDensity = grammar.errorCount / words;
    final grammarScore = (1.0 - errorDensity * 4).clamp(0.0, 1.0);
    return (localScore * 0.7) + (grammarScore * 0.3);
  }

  Future<void> _finalize(PendingOnlineRefinement item, {required double score}) async {
    await _attemptRepository.recordAttempt(
      learnerId: item.learnerId,
      activityId: item.activityId,
      lessonId: item.lessonId,
      sessionType: 'lesson',
      mode: ActivityMode.parse(item.mode),
      evidenceSkill: Skill.parse(item.evidenceSkill),
      canDoIds: (jsonDecode(item.canDoIds) as List).cast<String>(),
      rawAnswer: item.rawAnswer,
      isCorrect: score >= 0.75,
      score: score,
    );
    await _pendingRepository.remove(id: item.id);
    await onItemResolved?.call(learnerId: item.learnerId, unitId: item.unitId);
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/activity_engine/domain/evaluation/pending_refinement_drain_service_test.dart`
Expected: PASS

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/activity_engine/domain/evaluation/pending_refinement_drain_service.dart test/features/activity_engine/domain/evaluation/pending_refinement_drain_service_test.dart
git commit -m "feat: add PendingRefinementDrainService (retry, bounded local-only fallback)"
```

---

### Task 10: App-root drain trigger

**Files:**
- Modify: `lib/features/activity_engine/providers/online_refinement_providers.dart`
- Modify: `lib/app.dart`
- Test: `test/features/activity_engine/providers/online_refinement_providers_test.dart` (new)

**Interfaces:**
- Consumes: `ConnectivityService` (Task 3), `GrammarCheckService` (Task 4), `PendingRefinementRepository` (Task 5), `PendingRefinementDrainService`/`OnItemResolved` (Task 9), `MasteryAggregationService`/`masteryAggregationServiceProvider` (existing), `courseContentProvider` (existing), `allUnitProgressProvider`/`allLessonProgressProvider`/`lessonProgressForUnitProvider`/`lessonAttemptsForUnitProvider` (existing).
- Produces: `pendingRefinementDrainerProvider`.

- [ ] **Step 1: Write the failing test**

This provider's job is a side effect (draining, and — via `onItemResolved` — refreshing the resolved unit's cached mastery state), not a returned value. Test it by overriding the underlying repository/services with fakes, watching the provider, and asserting both the queue actually drains AND `unit_progress` actually gets refreshed for the unit that was resolved (the concrete proof that `onItemResolved` is wired, not just present). Create `test/features/activity_engine/providers/online_refinement_providers_test.dart`:

```dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/grammar_check_service.dart';
import 'package:mohingo/features/activity_engine/providers/online_refinement_providers.dart';
import 'package:uuid/uuid.dart';

import '../fake_connectivity_service.dart';
import '../fake_grammar_check_service.dart';

CourseContentIndex _realA1Index() {
  final raw = File(
    'assets/content/en/A1/a1-course-bundle.json',
  ).readAsStringSync();
  return CourseContentIndex.build(CourseBundleParser.parse(raw));
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test(
    'watching the drainer while already online drains the queue, records a '
    'real attempt, and refreshes the resolved unit\'s cached mastery state',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final index = _realA1Index();
      final learnerId = await db
          .into(db.learners)
          .insert(
            LearnersCompanion.insert(
              uuid: const Uuid().v4(),
              createdAt: DateTime.utc(2026, 9, 8),
            ),
          );
      await db
          .into(db.pendingOnlineRefinements)
          .insert(
            PendingOnlineRefinementsCompanion.insert(
              uuid: const Uuid().v4(),
              learnerId: learnerId,
              activityId: 'A1-U0-L5-A01',
              lessonId: 'A1-U0-L5',
              unitId: 'A1-U0',
              canDoIds: '["A1.U0.INTERACTION.REGISTER_FOR_CLASS"]',
              rawAnswer: 'Hi there!',
              evidenceSkill: 'spokenInteraction',
              mode: 'mastery',
              localScore: 1.0,
              submittedAt: DateTime.utc(2026, 9, 8),
            ),
          );

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider('a1').overrideWith((ref) async => index),
          connectivityServiceProvider.overrideWithValue(
            FakeConnectivityService(online: true),
          ),
          grammarCheckServiceProvider.overrideWithValue(
            FakeGrammarCheckService(
              result: const GrammarCheckResult(errorCount: 0, wordCount: 2),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(pendingRefinementDrainerProvider);
      // The drain, and the async unit-progress refresh it triggers, are
      // both fire-and-forget started at provider creation — give them a
      // few turns to run.
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(await db.select(db.pendingOnlineRefinements).get(), isEmpty);
      final attempts = await (db.select(
        db.activityAttempts,
      )..where((t) => t.activityId.equals('A1-U0-L5-A01'))).get();
      expect(attempts, hasLength(1));

      final unitProgress = await (db.select(
        db.unitProgress,
      )..where((t) => t.unitId.equals('A1-U0'))).get();
      expect(
        unitProgress,
        hasLength(1),
        reason:
            'refreshUnitProgress must have run for A1-U0 as a direct '
            'result of the resolved item — proves onItemResolved is wired, '
            'not just present',
      );
    },
  );

  test('a connectivity-regained event triggers another drain', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final index = _realA1Index();
    final learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: const Uuid().v4(),
            createdAt: DateTime.utc(2026, 9, 8),
          ),
        );
    final connectivity = FakeConnectivityService(online: false);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        courseContentProvider('a1').overrideWith((ref) async => index),
        connectivityServiceProvider.overrideWithValue(connectivity),
        grammarCheckServiceProvider.overrideWithValue(
          FakeGrammarCheckService(
            result: const GrammarCheckResult(errorCount: 0, wordCount: 2),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(pendingRefinementDrainerProvider);
    await Future<void>.delayed(Duration.zero);

    // Enqueue only after the drainer is already listening, then simulate
    // coming online.
    await db
        .into(db.pendingOnlineRefinements)
        .insert(
          PendingOnlineRefinementsCompanion.insert(
            uuid: const Uuid().v4(),
            learnerId: learnerId,
            activityId: 'A1-U0-L5-A01',
            lessonId: 'A1-U0-L5',
            unitId: 'A1-U0',
            canDoIds: '[]',
            rawAnswer: 'answer',
            evidenceSkill: 'spokenInteraction',
            mode: 'mastery',
            localScore: 1.0,
            submittedAt: DateTime.utc(2026, 9, 8),
          ),
        );
    connectivity.setOnline(true);
    for (var i = 0; i < 4; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    final remaining = await db.select(db.pendingOnlineRefinements).get();
    expect(remaining, isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/activity_engine/providers/online_refinement_providers_test.dart`
Expected: FAIL — `pendingRefinementDrainerProvider` doesn't exist yet.

- [ ] **Step 3: Implement**

In `lib/features/activity_engine/providers/online_refinement_providers.dart`, add (this one is a plain, hand-written `Provider`, not `@riverpod`-generated — matching this codebase's established exception for providers doing subscription/side-effect setup rather than returning a plain value; see `docs/TECH_STACK.md`'s note on `currentLearnerProvider`):

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;

import '../../../content/providers/course_content_providers.dart';
import '../../learning_path/providers/unit_progress_providers.dart';
import '../../progress/providers/progress_providers.dart';
import 'pending_refinement_drain_service.dart';

// (alongside the existing @riverpod providers in this file)

/// Watched once at app root (`MohingoApp`) — drains
/// `pending_online_refinements` immediately if already online, then again
/// every time [ConnectivityService.onlineChanges] reports the device just
/// came online. Never required for any learning feature to function: if
/// this never fires (a learner who's never online), queued items still
/// resolve via `PendingRefinementDrainService`'s bounded local-only
/// fallback the next time a drain happens to run — this provider is only
/// what makes that happen *sooner* when possible. See
/// docs/adr/0005-narrow-network-exception-for-open-ended-grading.md.
///
/// [OnItemResolved] is wired here, not inside the drain service itself,
/// because refreshing a unit's cached mastery state needs a real [Unit]
/// from the content bundle plus `MasteryAggregationService` — content and
/// Riverpod concerns the drain service deliberately knows nothing about.
final pendingRefinementDrainerProvider = Provider<void>((ref) {
  final service = PendingRefinementDrainService(
    pendingRepository: ref.watch(pendingRefinementRepositoryProvider),
    attemptRepository: ref.watch(activityAttemptRepositoryProvider),
    grammarCheckService: ref.watch(grammarCheckServiceProvider),
    onItemResolved: ({required learnerId, required unitId}) async {
      final index = await ref.read(courseContentProvider('a1').future);
      final unit = index.unitsById[unitId];
      // The content bundle could in principle change between when an item
      // was queued and when it resolves; nothing to refresh if the unit no
      // longer exists.
      if (unit == null) return;
      await ref
          .read(masteryAggregationServiceProvider)
          .refreshUnitProgress(
            learnerId: learnerId,
            unit: unit,
            masteryPolicy: index.bundle.domain.masteryPolicy,
          );
      ref.invalidate(allUnitProgressProvider);
      ref.invalidate(
        lessonProgressForUnitProvider((learnerId: learnerId, unitId: unitId)),
      );
      ref.invalidate(
        lessonAttemptsForUnitProvider((learnerId: learnerId, unitId: unitId)),
      );
      ref.invalidate(allLessonProgressProvider);
    },
  );
  final connectivity = ref.watch(connectivityServiceProvider);

  Future<void> drainIfOnline() async {
    if (await connectivity.isOnline()) {
      await service.drainOnce();
    }
  }

  drainIfOnline();

  final subscription = connectivity.onlineChanges
      .where((isOnline) => isOnline)
      .listen((_) => drainIfOnline());
  ref.onDispose(subscription.cancel);
});
```

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/activity_engine/providers/online_refinement_providers_test.dart`
Expected: PASS

- [ ] **Step 5: Watch it at app root**

In `lib/app.dart`, add the import and the watch, alongside the existing `ensureA1EnrollmentProvider` one:

```dart
import 'features/activity_engine/providers/online_refinement_providers.dart';

// inside MohingoApp.build(), alongside the existing:
//   ref.watch(ensureA1EnrollmentProvider);
    ref.watch(pendingRefinementDrainerProvider);
```

- [ ] **Step 6: Run the full test suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/features/activity_engine/providers/online_refinement_providers.dart lib/features/activity_engine/providers/online_refinement_providers.g.dart lib/app.dart test/features/activity_engine/providers/online_refinement_providers_test.dart
git commit -m "feat: drain pending online refinements at app start and on connectivity regained"
```

---

### Task 11: ADR 0005 and doc updates

**Files:**
- Create: `docs/adr/0005-narrow-network-exception-for-open-ended-grading.md`
- Modify: `docs/SECURITY.md`
- Modify: `docs/TECH_STACK.md`

- [ ] **Step 1: Write the ADR**

Create `docs/adr/0005-narrow-network-exception-for-open-ended-grading.md`:

```markdown
# 0005: A narrow, bounded network exception for open-ended answer grading

**Status:** Accepted

## Context

[ADR 0004](0004-local-only-v1-no-firebase-backend.md) established that v1 "requires no network permission or background network call for any learning feature." Tier 1 of the offline-answer-evaluation work (see docs/superpowers/specs/2026-09-07-offline-answer-evaluation-design.md) built a fully offline, non-AI grading system for structured answers, but deliberately deferred ~40 genuinely open-ended writing/speaking rubrics — no offline technique can meaningfully judge free-form paragraph quality beyond keyword coverage.

The product owner's explicit, self-imposed constraints for this gap (given directly, not inferred) were: no paid AI API, ever (the app must cost nothing to run); a free, rate-limited third-party service is acceptable (their own example: DeepL's free tier); open-ended tasks must still count toward mastery, not be silently excluded; and — per ADR 0004, unchanged — a learner who never goes online must still be able to reach "Mastered."

This is the first time anything in the app sends learner-authored content off the device. It needed its own decision, not a silent extension of Tier 1's scope.

## Decision

A narrow, bounded exception to ADR 0004: when the device is online, an open-ended writing/speaking answer (only the ~40 rubrics explicitly marked `onlineRefinement: "grammarCheck"`) may be sent to the free public LanguageTool API (`api.languagetool.org`) for a grammar/spelling-quality check — a rule-based checker, not an AI/LLM, no API key, no cost. This is strictly a quality upgrade, never a requirement: every such answer is graded locally first (content-coverage score), queued, and — per `docs/superpowers/specs/2026-09-07-offline-answer-evaluation-design.md`'s Tier 2 — resolved via the bounded local-only fallback if the device never goes online. ADR 0004's actual guarantee ("no network call is *required*") still holds exactly as written; what's new is that the *capability* now exists in the codebase.

The learner is told, before this first applies to them, that their open-ended answer may be sent online for a quality check — a bilingual, non-blocking notice on the submission itself (see the Tier 2 plan's Task 6), not something that happens silently.

## Alternatives considered

- **Keep the exclusion Tier 1 shipped with (never grade open-ended tasks at all)** — rejected; the product owner explicitly required real credit for these, not exclusion, when this was first raised.
- **A cloud AI/LLM grading service** — rejected outright per the product owner's own constraint; conflicts with `docs/TECH_STACK.md`'s existing "Cloud-based AI grading... rejected" entry, which this ADR does not reverse (LanguageTool is a deterministic, rule-based grammar/spellchecker, not an AI model).
- **Self-hosting LanguageTool** — considered, deferred: the free public endpoint is sufficient at v1's scale; self-hosting is a pure implementation swap behind the same `GrammarCheckService` interface if the public endpoint's rate limit ever proves too tight.

## Consequences

- `docs/SECURITY.md`'s "no network permission or background network call is required" and "no data leaves the device" statements now carry one explicit, scoped exception — updated in the same change as this ADR, not left to drift.
- The app declares internet-access capability at the platform level for the first time (already implicit for any Flutter app that can make an HTTP call; no new OS permission prompt is needed on either platform for outbound HTTP).
- A learner's open-ended answer text (never any other PII, never audio, never a speech transcript verbatim — see `docs/SECURITY.md`'s existing "never logged" list, unaffected) may leave the device, only when: the rubric is one of the ~40 explicitly marked ones, the device is online, and the learner has been shown the disclosure notice.
- Does **not** reverse `docs/TECH_STACK.md`'s rejection of cloud-based AI grading, and does not open the door to one — a genuinely new AI-grading proposal still needs its own ADR.
```

- [ ] **Step 2: Update `docs/SECURITY.md`**

In the `## Data handling` section, replace the line:

```
- Encryption at rest / in transit: **no data leaves the device in v1**, so "in transit" doesn't apply. ...
```

with:

```
- Encryption at rest / in transit: no data leaves the device in v1, **with one narrow, bounded exception**: an open-ended writing/speaking answer (only the ~40 rubrics marked `onlineRefinement`), when the device is online, may be sent over HTTPS to the free public LanguageTool API for a grammar-quality check — never blocking, never required (a bounded local-only fallback resolves it either way), and disclosed to the learner before it first applies. See [ADR 0005](adr/0005-narrow-network-exception-for-open-ended-grading.md). The local Drift database is not encrypted by default for v1 — acceptable given the limited PII involved (no payment data, no accounts); revisit if that changes.
```

In the `## Hard limits` section, replace:

```
- **No network permission or background network call is required for any learning feature in v1** — verify at build time that no plugin silently requires `INTERNET` beyond what's unavoidable for platform tooling.
```

with:

```
- **No network permission or background network call is required for any learning feature in v1** — still true after [ADR 0005](adr/0005-narrow-network-exception-for-open-ended-grading.md): online grammar refinement for open-ended answers is a bounded quality upgrade with a working offline fallback, never a requirement. Verify at build time that no plugin silently requires `INTERNET` beyond what ADR 0005 and platform tooling account for.
```

- [ ] **Step 3: Update `docs/TECH_STACK.md`**

In the `## Explicitly rejected` table, find the row:

```
| Cloud-based AI grading for speaking/writing at runtime | Conflicts with "fully offline" requirement for MVP; deferred to post-MVP roadmap (see [ROADMAP.md](ROADMAP.md)) once a serverless AI-grading path (e.g. Firebase Cloud Functions) is worth the added complexity. |
```

and append a note directly after that table row's cell content (same row, extend the text — do not add a new row):

```
| Cloud-based AI grading for speaking/writing at runtime | Conflicts with "fully offline" requirement for MVP; deferred to post-MVP roadmap (see [ROADMAP.md](ROADMAP.md)) once a serverless AI-grading path (e.g. Firebase Cloud Functions) is worth the added complexity. Does **not** cover the narrow, rule-based (non-AI) LanguageTool grammar check added for open-ended rubrics — see [ADR 0005](adr/0005-narrow-network-exception-for-open-ended-grading.md), a bounded exception, not a reversal of this rejection. |
```

Also add a new row to the `## Third-party services` table:

```
| Free public LanguageTool API (`api.languagetool.org`) | Grammar/spelling-quality pass for the ~40 open-ended writing/speaking rubrics, once the device is online | Free, no API key, no cost; rule-based, not AI/LLM; a bounded quality upgrade, never required — see [ADR 0005](adr/0005-narrow-network-exception-for-open-ended-grading.md) |
```

- [ ] **Step 4: Bump both docs' "Last verified" lines**

Update the top-of-file "Last verified" line in both `docs/SECURITY.md` and `docs/TECH_STACK.md` to today's date, noting this change (matching each file's existing convention of appending a short rationale clause).

- [ ] **Step 5: Commit**

```bash
git add docs/adr/0005-narrow-network-exception-for-open-ended-grading.md docs/SECURITY.md docs/TECH_STACK.md
git commit -m "docs: add ADR 0005 for the narrow online-grammar-check network exception"
```

---

### Task 12: Content migration — `A1-U5-L6-A05`

**Files:**
- Modify: `assets/content/en/A1/a1-course-bundle.json`
- Test: `test/content/a1_u5_free_time_message_regression_test.dart` (new)

**Interfaces:**
- Consumes: everything from Tasks 1-10.
- Produces: `A1-U5-L6-A05` fully wired end-to-end; Task 8's e2e test (Step 4's known failure) turns green.

- [ ] **Step 1: Write the failing regression test**

Create `test/content/a1_u5_free_time_message_regression_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/evaluation_spec.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';

void main() {
  test(
    'A1-U5-L6-A05 (the u5-free-time-message-rubric activity) is migrated '
    'to a keywordChecklist spec with online refinement enabled',
    () {
      final json = File(
        'assets/content/en/A1/a1-course-bundle.json',
      ).readAsStringSync();
      final index = CourseContentIndex.build(CourseBundleParser.parse(json));
      final activity =
          index.lessonsById['A1-U5-L6']!.activities.last as WriteActivity;

      expect(activity.id, 'A1-U5-L6-A05');
      final spec = activity.evaluation as KeywordChecklistEvaluationSpec;
      expect(spec.onlineRefinement, 'grammarCheck');
      expect(spec.minGroupsMatched, greaterThan(0));
      expect(spec.requiredGroups, isNotEmpty);
    },
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/content/a1_u5_free_time_message_regression_test.dart`
Expected: FAIL — `evaluation` is still the legacy string, so the cast to `KeywordChecklistEvaluationSpec` throws.

- [ ] **Step 3: Migrate the rubric**

In `assets/content/en/A1/a1-course-bundle.json`, find `A1-U5-L6-A05` (prompt: `"Write a 35–55-word message about what you like and invite a friend to one activity."`) and replace:

```json
"evaluation": "u5-free-time-message-rubric",
```

with:

```json
"evaluation": {
  "type": "keywordChecklist",
  "requiredGroups": [
    ["like", "love", "enjoy", "hobby", "hobbies"],
    ["free time", "weekend", "hobby", "hobbies"],
    ["would you like", "let's", "join", "come"]
  ],
  "minGroupsMatched": 2,
  "onlineRefinement": "grammarCheck"
},
```

(These three groups map to the activity's own three `canDo` objectives — describing what you like, describing free-time habits, and making/responding to an invitation — requiring at least 2 of 3 keeps the bar realistic for an A1.0 learner without demanding all three in one 35-55 word message.)

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/content/a1_u5_free_time_message_regression_test.dart`
Expected: PASS

- [ ] **Step 5: Run Task 8's e2e test to confirm it's now green too**

Run: `flutter test test/features/lesson_player/lesson_player_e2e_test.dart`
Expected: PASS (the test whose failure was explicitly expected and confirmed in Task 8 Step 4 should turn green now that the rubric is migrated — the sample answer in that test already mentions "Hello", weekend hobbies, and an invitation, matching at least 2 of the 3 groups above).

- [ ] **Step 6: Run the full test suite**

Run: `flutter test`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add assets/content/en/A1/a1-course-bundle.json test/content/a1_u5_free_time_message_regression_test.dart
git commit -m "content: migrate A1-U5-L6-A05 (u5-free-time-message-rubric) to keywordChecklist with online refinement"
```

---

### Task 13: Documentation

**Files:**
- Modify: `docs/DATA_MODEL.md`

- [ ] **Step 1: Document the new table**

In `docs/DATA_MODEL.md`, add a new entry near the existing `ActivityAttempts`/progress-table descriptions:

```markdown
### PendingOnlineRefinement

`id`, `uuid`, `learnerId`, `activityId`, `lessonId`, `unitId` (denormalized so a resolved item can refresh that unit's cached mastery state without a content lookup), `canDoIds` (JSON-encoded `[canDoId]`), `rawAnswer`, `evidenceSkill`, `mode`, `localScore` (the offline `keywordChecklist` content score, computed once at submission), `submittedAt`, `attemptCount`, `lastAttemptAt`. A mutable queue, unlike every other progress table — not evidence-of-record. One row per submitted open-ended answer awaiting a free online grammar-quality pass; removed the moment it resolves (online, or via the bounded local-only fallback) into exactly one ordinary `ActivityAttempts` row, which also triggers a `MasteryAggregationService.refreshUnitProgress` for `unitId`. See docs/superpowers/specs/2026-09-07-offline-answer-evaluation-design.md's Tier 2 and [ADR 0005](adr/0005-narrow-network-exception-for-open-ended-grading.md).
```

- [ ] **Step 2: Bump the "Last verified" line**

Update `docs/DATA_MODEL.md`'s top-of-file "Last verified" line to today's date.

- [ ] **Step 3: Commit**

```bash
git add docs/DATA_MODEL.md
git commit -m "docs: document PendingOnlineRefinement"
```
