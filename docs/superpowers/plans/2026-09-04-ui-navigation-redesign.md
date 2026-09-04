# UI Navigation & Progress-Feedback Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make "where am I" and "what have I completed" visually legible on Home, Learn, Review, and Tests, using a shared 4-state status indicator and real (not decorative) progress data that already exists in the local Drift database.

**Architecture:** Flutter/Riverpod app, no backend (offline-first, local Drift DB only — see `docs/adr/0004-local-only-v1-no-firebase-backend.md`). All changes are additive: one new shared widget (`StatusIndicator`), two small repository additions (a streak query, a bulk per-unit lesson-progress query), a handful of new derived Riverpod providers, and rewrites of 8 existing presentation-layer files. No schema migration — the project has never shipped one (`schemaVersion` is hardcoded to `1`, no `onUpgrade`), and every new data need here is satisfied by reading existing tables differently, not adding new ones.

**Tech Stack:** Flutter (Dart SDK `^3.13.2`), `flutter_riverpod: ^3.4.2`, `go_router: ^18.0.0`, Drift (SQLite), `flutter gen-l10n` for ARB-based bilingual strings.

**Spec:** `docs/superpowers/specs/2026-09-04-ui-navigation-redesign-design.md`

## Global Constraints

- All new user-facing copy must be added to **both** `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`, each written natively (never machine-translated from the other) — see the root `CLAUDE.md`.
- Every status/feedback state must pair a `colorScheme` role with an icon and text — never color alone (existing rule, already followed by `ActivityFeedbackBanner`).
- All layout uses Flutter's directional (`start`/`end`) properties and explicit per-language `textDirection` on bilingual text — never hardcoded `left`/`right`. English text is always `TextDirection.ltr`, Arabic always `TextDirection.rtl`, matching every existing screen in this codebase.
- No new gamification mechanics beyond the streak indicator (no XP, leaderboards, badges, mascot) — per `docs/DESIGN_SYSTEM.md`.
- No schema migration. If a task's data need can't be met by querying existing tables, stop and flag it rather than inventing a migration path — none exists in this codebase yet.
- Every `driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;` line goes at the top of `main()` in any new test file that opens an `AppDatabase(NativeDatabase.memory())` — matches every existing DB-backed test file.
- Run `dart format --set-exit-if-changed .` and `flutter analyze` before every commit in this plan (matches `docs/TESTING.md`/root `CLAUDE.md`'s lint command) — fix anything either reports before moving on.

---

## Task 1: Shared 4-state status indicator + gamification token doc fix

**Files:**
- Create: `lib/core/widgets/status_indicator.dart`
- Create: `test/core/widgets/status_indicator_test.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ar.arb`
- Modify: `docs/DESIGN_SYSTEM.md`

**Interfaces:**
- Produces: `enum ProgressState { notStarted, inProgress, needsReview, mastered }` with `static ProgressState fromRaw(String? raw)` (unknown/null → `notStarted`), and `class StatusIndicator extends StatelessWidget` with constructor `StatusIndicator({required ProgressState state, double size = 22, Key? key})`. Both in `lib/core/widgets/status_indicator.dart`. Every later task that renders a progress state imports and uses these two.

- [ ] **Step 1: Add the new ARB string**

In `lib/l10n/app_en.arb`, add immediately after the existing `unitStateMastered`/`@unitStateMastered` pair (around line 86):

```json
  "unitStateNeedsReview": "Needs review",
  "@unitStateNeedsReview": {"description": "Unit/lesson progress badge — was mastered but evidence or content has gone stale."},
```

In `lib/l10n/app_ar.arb`, add immediately after `"unitStateMastered": "أتقنتها",` (around line 21):

```json
  "unitStateNeedsReview": "يحتاج مراجعة",
```

- [ ] **Step 2: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: exits 0, and `lib/core/l10n/generated/app_localizations.dart` (and the `_en`/`_ar` variants) now declare a `unitStateNeedsReview` getter. Confirm with:

Run: `grep -r "unitStateNeedsReview" lib/core/l10n/generated/`
Expected: at least one match per generated file.

- [ ] **Step 3: Write the failing widget test**

Create `test/core/widgets/status_indicator_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/widgets/status_indicator.dart';

Widget _wrapped(Widget child) {
  return MaterialApp(
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders a distinct icon/color/label per state', (
    tester,
  ) async {
    final cases = <ProgressState, (IconData, String Function(AppLocalizations))>{
      ProgressState.notStarted: (
        Icons.circle_outlined,
        (l10n) => l10n.unitStateNotStarted,
      ),
      ProgressState.inProgress: (
        Icons.incomplete_circle,
        (l10n) => l10n.unitStateInProgress,
      ),
      ProgressState.needsReview: (
        Icons.refresh,
        (l10n) => l10n.unitStateNeedsReview,
      ),
      ProgressState.mastered: (
        Icons.check_circle,
        (l10n) => l10n.unitStateMastered,
      ),
    };

    for (final entry in cases.entries) {
      await tester.pumpWidget(
        _wrapped(StatusIndicator(state: entry.key)),
      );
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, entry.value.$1, reason: 'icon for ${entry.key}');

      final context = tester.element(find.byType(Scaffold));
      final l10n = AppLocalizations.of(context)!;
      expect(icon.semanticLabel, entry.value.$2(l10n));
    }
  });

  testWidgets('mastered and notStarted use different colors', (tester) async {
    await tester.pumpWidget(
      _wrapped(const StatusIndicator(state: ProgressState.mastered)),
    );
    final masteredIcon = tester.widget<Icon>(find.byType(Icon));

    await tester.pumpWidget(
      _wrapped(const StatusIndicator(state: ProgressState.notStarted)),
    );
    final notStartedIcon = tester.widget<Icon>(find.byType(Icon));

    expect(masteredIcon.color, isNot(equals(notStartedIcon.color)));
  });
}
```

(Adjust the `package:mohingo/...` import prefix if `pubspec.yaml`'s `name:` field differs — check it first with `grep "^name:" pubspec.yaml`.)

- [ ] **Step 4: Run the test to verify it fails**

Run: `flutter test test/core/widgets/status_indicator_test.dart`
Expected: FAIL — `lib/core/widgets/status_indicator.dart` doesn't exist yet (import error).

- [ ] **Step 5: Implement `ProgressState` and `StatusIndicator`**

Create `lib/core/widgets/status_indicator.dart`:

```dart
import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// The 4 progress states shown across Learn, Review, and Tests — mirrors
/// [UnitProgressState] but lives in the presentation layer since not every
/// consumer (e.g. vocabulary review rows) is backed by that exact enum. See
/// docs/superpowers/specs/2026-09-04-ui-navigation-redesign-design.md.
enum ProgressState {
  notStarted,
  inProgress,
  needsReview,
  mastered;

  /// Parses a raw progress-state string (e.g. from [UnitProgressData.state]),
  /// falling back to [notStarted] for `null` or anything unrecognized.
  static ProgressState fromRaw(String? raw) {
    return ProgressState.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => ProgressState.notStarted,
    );
  }
}

/// The shared icon+color+text status indicator used on Learn's unit spine
/// and lesson rows, Review's vocabulary/chunk rows, and Tests' cards. Never
/// color alone, per docs/UX_PRINCIPLES.md's accessibility rule.
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({required this.state, this.size = 22, super.key});

  final ProgressState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final (IconData icon, Color color, String label) = switch (state) {
      ProgressState.notStarted => (
        Icons.circle_outlined,
        colorScheme.onSurfaceVariant,
        l10n.unitStateNotStarted,
      ),
      ProgressState.inProgress => (
        Icons.incomplete_circle,
        colorScheme.tertiary,
        l10n.unitStateInProgress,
      ),
      ProgressState.needsReview => (
        Icons.refresh,
        colorScheme.tertiary,
        l10n.unitStateNeedsReview,
      ),
      ProgressState.mastered => (
        Icons.check_circle,
        colorScheme.primary,
        l10n.unitStateMastered,
      ),
    };
    return Icon(icon, color: color, size: size, semanticLabel: label);
  }
}
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `flutter test test/core/widgets/status_indicator_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 7: Correct the gamification token name in DESIGN_SYSTEM.md and document the new components**

Read `docs/DESIGN_SYSTEM.md` first to find the exact current wording around its `gamificationAccent`/streak mention and its "Progress bar (unit path)" / component-states bullet (from the design audit: line ~28 names the token `gamificationAccent`, but the real Dart property is `GamificationTheme.streakAccent`). Edit that section to:
1. Rename `gamificationAccent` → `streakAccent` (matching `lib/core/theme/gamification_theme_extension.dart`) wherever it appears.
2. Add a short "Status indicator" entry documenting the 4 states (`notStarted`/`inProgress`/`needsReview`/`mastered`) and their icon+color mapping (outline circle/`onSurfaceVariant`, half-filled ring/`tertiary`, refresh icon/`tertiary`, filled check/`primary`), matching `StatusIndicator`'s `switch` above.
3. Update the doc's `_Last verified_` line to today's date with a short note ("added StatusIndicator component; corrected streakAccent naming — see the 2026-09-04 UI redesign plan").

- [ ] **Step 8: Run static checks and commit**

Run: `dart format --set-exit-if-changed lib/core/widgets/status_indicator.dart test/core/widgets/status_indicator_test.dart && flutter analyze`
Expected: both exit 0.

```bash
git add lib/core/widgets/status_indicator.dart test/core/widgets/status_indicator_test.dart lib/l10n/app_en.arb lib/l10n/app_ar.arb lib/core/l10n/generated docs/DESIGN_SYSTEM.md
git commit -m "$(cat <<'EOF'
Add shared 4-state status indicator widget

Introduces ProgressState + StatusIndicator, the icon+color+text component
every later task in the navigation redesign renders unit/lesson/vocabulary/
test state through. Also corrects DESIGN_SYSTEM.md's gamification token
name (gamificationAccent -> streakAccent, matching the actual Dart
property) and documents the new component.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Home screen — streak, level progress, review-due dashboard

**Files:**
- Modify: `lib/features/progress/domain/repositories/activity_attempt_repository.dart`
- Modify: `lib/features/progress/data/drift_activity_attempt_repository.dart`
- Modify: `lib/features/progress/providers/current_learner_provider.dart`
- Modify: `lib/features/review/providers/review_providers.dart`
- Modify: `lib/features/home/presentation/home_screen.dart`
- Create: `test/features/progress/data/drift_activity_attempt_repository_streak_test.dart`
- Create: `test/features/home/presentation/home_screen_test.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`

**Interfaces:**
- Consumes: nothing from Task 1 directly (Home doesn't use `StatusIndicator`).
- Produces: `ActivityAttemptRepository.currentStreakDays({required int learnerId, required DateTime asOf}) -> Future<int>`; `currentStreakDaysProvider` (`FutureProvider<int>`, in `current_learner_provider.dart`); `dueVocabularyCountProvider` (`Provider<AsyncValue<int>>`, in `review_providers.dart`). Task 9 (nav badge) consumes `dueVocabularyCountProvider`.

- [ ] **Step 1: Write the failing repository test for `currentStreakDays`**

Create `test/features/progress/data/drift_activity_attempt_repository_streak_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/data/drift_activity_attempt_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late DriftActivityAttemptRepository repository;
  late int learnerId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftActivityAttemptRepository(db);
    learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: 'learner-1',
            createdAt: DateTime.utc(2026, 9, 1),
          ),
        );
  });

  tearDown(() => db.close());

  Future<void> attemptOn(DateTime day) async {
    await repository.recordAttempt(
      learnerId: learnerId,
      activityId: 'A1-U1-L1-A01',
      sessionType: 'lesson',
      mode: ActivityMode.practice,
      evidenceSkill: Skill.reading,
      canDoIds: const [],
    );
    // recordAttempt always stamps DateTime.now(); override attemptedAt
    // directly for deterministic test dates.
    await (db.update(
      db.activityAttempts,
    )..where((t) => t.learnerId.equals(learnerId))).write(
      ActivityAttemptsCompanion(attemptedAt: Value(day)),
    );
  }

  test('returns 0 with no attempts', () async {
    final streak = await repository.currentStreakDays(
      learnerId: learnerId,
      asOf: DateTime.utc(2026, 9, 4),
    );
    expect(streak, 0);
  });

  test('counts consecutive days ending on asOf', () async {
    await attemptOn(DateTime.utc(2026, 9, 2));
    await attemptOn(DateTime.utc(2026, 9, 3));
    await attemptOn(DateTime.utc(2026, 9, 4));

    final streak = await repository.currentStreakDays(
      learnerId: learnerId,
      asOf: DateTime.utc(2026, 9, 4),
    );
    expect(streak, 3);
  });

  test('stops counting at the first gap', () async {
    await attemptOn(DateTime.utc(2026, 9, 1));
    // gap on Sep 2
    await attemptOn(DateTime.utc(2026, 9, 3));
    await attemptOn(DateTime.utc(2026, 9, 4));

    final streak = await repository.currentStreakDays(
      learnerId: learnerId,
      asOf: DateTime.utc(2026, 9, 4),
    );
    expect(streak, 2);
  });

  test('multiple attempts on the same day count once', () async {
    await attemptOn(DateTime.utc(2026, 9, 4));
    await attemptOn(DateTime.utc(2026, 9, 4));

    final streak = await repository.currentStreakDays(
      learnerId: learnerId,
      asOf: DateTime.utc(2026, 9, 4),
    );
    expect(streak, 1);
  });
}
```

Note: this test file calls `attemptOn` sequentially per test, so each `recordAttempt` + follow-up `update` pair only ever touches the most-recently-inserted row's `attemptedAt` in isolation is not quite right — the `update` above updates *every* row for that learner, not just the one just inserted. Fix `attemptOn` before running: since each test's attempts are meant to land on distinct days, restructure to insert-then-update-by-id:

```dart
  Future<void> attemptOn(DateTime day) async {
    final id = await repository.recordAttempt(
      learnerId: learnerId,
      activityId: 'A1-U1-L1-A01',
      sessionType: 'lesson',
      mode: ActivityMode.practice,
      evidenceSkill: Skill.reading,
      canDoIds: const [],
    );
    await (db.update(
      db.activityAttempts,
    )..where((t) => t.id.equals(id))).write(
      ActivityAttemptsCompanion(attemptedAt: Value(day)),
    );
  }
```

(`recordAttempt` returns the inserted row's `int` id — see `ActivityAttemptRepository.recordAttempt`'s existing signature.) Use this corrected version in the file. Also add `import 'package:drift/drift.dart' show Value;` at the top for the `Value(...)` wrapper.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/progress/data/drift_activity_attempt_repository_streak_test.dart`
Expected: FAIL — `currentStreakDays` is not defined on `DriftActivityAttemptRepository`/`ActivityAttemptRepository`.

- [ ] **Step 3: Add `currentStreakDays` to the interface and implementation**

In `lib/features/progress/domain/repositories/activity_attempt_repository.dart`, add to `abstract interface class ActivityAttemptRepository` (after `attemptsForLessons`):

```dart
  /// Consecutive calendar days (ending on [asOf]'s date, inclusive) on which
  /// [learnerId] has at least one attempt. 0 if there's no attempt on
  /// [asOf]'s own date. Used only for Home's streak display — not a
  /// mastery/gating signal. See docs/superpowers/specs/
  /// 2026-09-04-ui-navigation-redesign-design.md.
  Future<int> currentStreakDays({
    required int learnerId,
    required DateTime asOf,
  });
```

In `lib/features/progress/data/drift_activity_attempt_repository.dart`, add to `DriftActivityAttemptRepository` (after `attemptsForLessons`):

```dart
  @override
  Future<int> currentStreakDays({
    required int learnerId,
    required DateTime asOf,
  }) async {
    final rows = await (_db.selectOnly(_db.activityAttempts)
          ..addColumns([_db.activityAttempts.attemptedAt])
          ..where(_db.activityAttempts.learnerId.equals(learnerId)))
        .get();

    final activeDates = <DateTime>{
      for (final row in rows)
        _dateOnly(row.read(_db.activityAttempts.attemptedAt)!),
    };

    var streak = 0;
    var day = _dateOnly(asOf);
    while (activeDates.contains(day)) {
      streak += 1;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
```

Add this top-level helper at the bottom of the same file, outside the class:

```dart
DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/progress/data/drift_activity_attempt_repository_streak_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Add the `currentStreakDaysProvider` and `dueVocabularyCountProvider`**

In `lib/features/progress/providers/current_learner_provider.dart`, add after the existing `currentLearnerProvider`:

```dart
/// Consecutive days (ending today) the learner has done at least one
/// activity. Home-only display signal — never used for gating. See
/// [ActivityAttemptRepository.currentStreakDays].
final currentStreakDaysProvider = FutureProvider<int>((ref) async {
  final learner = await ref.watch(currentLearnerProvider.future);
  final repository = ref.watch(activityAttemptRepositoryProvider);
  return repository.currentStreakDays(
    learnerId: learner.id,
    asOf: DateTime.now(),
  );
});
```

(`activityAttemptRepositoryProvider` is already available via this file's existing `import 'progress_providers.dart';`.)

In `lib/features/review/providers/review_providers.dart`, add after `dueVocabularyProvider`:

```dart
/// Just the count of [dueVocabularyProvider] — Home's review-due card and
/// the Review nav-tab badge both need only the number, not the rows.
final dueVocabularyCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(dueVocabularyProvider).whenData((items) => items.length);
});
```

- [ ] **Step 6: Add new ARB strings for the dashboard**

In `lib/l10n/app_en.arb`, add (anywhere near the existing `homeAllUnitsMastered` entry):

```json
  "homeStreakTitle": "{days, plural, =0{No streak yet} =1{1-day streak} other{{days}-day streak}}",
  "@homeStreakTitle": {
    "description": "Home streak card title.",
    "placeholders": {"days": {"type": "int"}}
  },
  "homeStreakEncouragement": "Keep it going today",
  "@homeStreakEncouragement": {"description": "Home streak card subtitle."},
  "homeLevelProgressTitle": "A1 progress",
  "@homeLevelProgressTitle": {"description": "Home level-progress card title."},
  "homeLevelProgressCaption": "{mastered} of {total} units mastered",
  "@homeLevelProgressCaption": {
    "description": "Home level-progress card caption.",
    "placeholders": {
      "mastered": {"type": "int"},
      "total": {"type": "int"}
    }
  },
  "homeReviewDueTitle": "{count, plural, =0{Nothing due for review} =1{1 item due for review} other{{count} items due for review}}",
  "@homeReviewDueTitle": {
    "description": "Home review-due card title.",
    "placeholders": {"count": {"type": "int"}}
  },
```

In `lib/l10n/app_ar.arb`, add:

```json
  "homeStreakTitle": "{days, plural, =0{لا يوجد تتابع بعد} =1{تتابع يوم واحد} other{تتابع {days} أيام}}",
  "homeStreakEncouragement": "واصل اليوم أيضاً",
  "homeLevelProgressTitle": "تقدّم A1",
  "homeLevelProgressCaption": "أتقنت {mastered} من {total} وحدة",
  "homeReviewDueTitle": "{count, plural, =0{لا يوجد شيء بحاجة للمراجعة} =1{عنصر واحد بحاجة للمراجعة} other{{count} عناصر بحاجة للمراجعة}}",
```

Run: `flutter gen-l10n`
Expected: exits 0.

- [ ] **Step 7: Write the failing Home screen widget test**

Create `test/features/home/presentation/home_screen_test.dart`:

```dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/home/presentation/home_screen.dart';

Future<dynamic> _realA1Index() async {
  final json = File(
    'assets/content/en/A1/a1-course-bundle.json',
  ).readAsStringSync();
  return CourseBundleParser.parse(json);
}

Future<Widget> _wrapped(AppDatabase db) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWithValue(db),
      courseContentProvider('a1').overrideWith((ref) async => _realA1Index()),
    ],
    child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const HomeScreen(),
    ),
  );
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('shows streak, continue, progress, and review-due cards', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(await _wrapped(db));
    await tester.pumpAndSettle();

    expect(find.textContaining('progress'), findsWidgets);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    // Streak card renders even with 0 days.
    final l10n = AppLocalizations.of(
      tester.element(find.byType(HomeScreen)),
    )!;
    expect(find.text(l10n.homeStreakTitle(0)), findsOneWidget);
    expect(find.text(l10n.homeReviewDueTitle(0)), findsOneWidget);
  });
}
```

- [ ] **Step 8: Run the test to verify it fails**

Run: `flutter test test/features/home/presentation/home_screen_test.dart`
Expected: FAIL — `find.text(l10n.homeStreakTitle(0))` etc. find nothing, since `HomeScreen` doesn't render these yet.

- [ ] **Step 9: Rewrite `HomeScreen`**

Replace the full contents of `lib/features/home/presentation/home_screen.dart` with:

```dart
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/gamification_theme_extension.dart';
import '../../learning_path/providers/unit_progress_providers.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../review/providers/review_providers.dart';

/// Home tab landing screen: a streak card, the "Continue learning" card, an
/// A1 level-progress card, and a review-due card. See
/// docs/superpowers/specs/2026-09-04-ui-navigation-redesign-design.md.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final contentAsync = ref.watch(courseContentProvider('a1'));
    final progressAsync = ref.watch(allUnitProgressProvider);
    final streakAsync = ref.watch(currentStreakDaysProvider);
    final dueCountAsync = ref.watch(dueVocabularyCountProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navHome)),
      body: contentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (index) {
          final masteredUnitIds = {
            for (final p in progressAsync.value ?? const [])
              if (p.state == 'mastered') p.unitId,
          };
          final totalUnits = index.bundle.units.length;
          final masteredCount = masteredUnitIds.length;
          final nextUnit = index.bundle.units
              .where((u) => !masteredUnitIds.contains(u.id))
              .firstOrNull;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StreakCard(days: streakAsync.value ?? 0),
              const SizedBox(height: 12),
              if (nextUnit == null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.homeAllUnitsMastered),
                  ),
                )
              else
                _ContinueLearningCard(
                  title: nextUnit.title,
                  titleAr: nextUnit.titleAr,
                  onContinue: () =>
                      context.go('/learn/a1/unit/${nextUnit.id}'),
                ),
              const SizedBox(height: 12),
              _LevelProgressCard(mastered: masteredCount, total: totalUnits),
              const SizedBox(height: 12),
              _ReviewDueCard(
                count: dueCountAsync.value ?? 0,
                onTap: () => context.go('/review'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final gamification = Theme.of(context).extension<GamificationTheme>()!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: gamification.streakAccent,
              child: Text(
                '$days',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeStreakTitle(days),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    l10n.homeStreakEncouragement,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard({
    required this.title,
    required this.titleAr,
    required this.onContinue,
  });

  final String title;
  final String titleAr;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.continueLearningTitle,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: colorScheme.onPrimaryContainer),
            ),
            Text(
              titleAr,
              textDirection: TextDirection.rtl,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onContinue,
              child: Text(l10n.continueLearningCta),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelProgressCard extends StatelessWidget {
  const _LevelProgressCard({required this.mastered, required this.total});

  final int mastered;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final fraction = total == 0 ? 0.0 : mastered / total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.homeLevelProgressTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(colorScheme.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.homeLevelProgressCaption(mastered, total),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewDueCard extends StatelessWidget {
  const _ReviewDueCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.style_outlined),
        title: Text(l10n.homeReviewDueTitle(count)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
```

- [ ] **Step 10: Run the test to verify it passes**

Run: `flutter test test/features/home/presentation/home_screen_test.dart`
Expected: PASS.

- [ ] **Step 11: Run the full test suite to check for regressions**

Run: `flutter test`
Expected: all tests pass (no other file references the old single-card `HomeScreen` layout by exact widget tree shape).

- [ ] **Step 12: Static checks and commit**

Run: `dart format --set-exit-if-changed . && flutter analyze`
Expected: both exit 0.

```bash
git add lib/features/progress/domain/repositories/activity_attempt_repository.dart lib/features/progress/data/drift_activity_attempt_repository.dart lib/features/progress/providers/current_learner_provider.dart lib/features/review/providers/review_providers.dart lib/features/home/presentation/home_screen.dart lib/l10n/app_en.arb lib/l10n/app_ar.arb lib/core/l10n/generated test/features/progress/data/drift_activity_attempt_repository_streak_test.dart test/features/home/presentation/home_screen_test.dart
git commit -m "$(cat <<'EOF'
Redesign Home as a real dashboard

Adds a streak card (using the previously-unused GamificationTheme
token), an A1 level-progress bar, and a review-due card alongside the
existing Continue card. Backed by a new currentStreakDays repository
query (derived from ActivityAttempts.attemptedAt, no schema change)
and a dueVocabularyCountProvider.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Level catalog — per-level progress indicator

**Files:**
- Modify: `lib/features/course_catalog/presentation/level_catalog_screen.dart`
- Create: `test/features/course_catalog/presentation/level_catalog_screen_test.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`

**Interfaces:**
- Consumes: `allUnitProgressProvider` (existing), `courseContentProvider` (existing) — no Task 1/2 dependency.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Add the ARB caption string**

Reuse `homeLevelProgressCaption` (already added in Task 2 — same "{mastered} of {total} units mastered" shape fits here too). No new ARB entry needed; confirm it's available by checking `lib/core/l10n/generated/app_localizations.dart` already declares `homeLevelProgressCaption` (it will, since Task 2 ran `flutter gen-l10n`).

- [ ] **Step 2: Write the failing widget test**

Create `test/features/course_catalog/presentation/level_catalog_screen_test.dart`:

```dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/course_catalog/presentation/level_catalog_screen.dart';

Future<dynamic> _realA1Index() async {
  final json = File(
    'assets/content/en/A1/a1-course-bundle.json',
  ).readAsStringSync();
  return CourseBundleParser.parse(json);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('A1 card shows a mastered-of-total caption', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider(
            'a1',
          ).overrideWith((ref) async => _realA1Index()),
        ],
        child: MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const LevelCatalogScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(LevelCatalogScreen)),
    )!;
    expect(find.text(l10n.homeLevelProgressCaption(0, 13)), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/features/course_catalog/presentation/level_catalog_screen_test.dart`
Expected: FAIL — no such caption text is rendered yet, and `_LevelCard` currently doesn't watch any provider (it's a `StatelessWidget`).

- [ ] **Step 4: Rewrite `level_catalog_screen.dart`**

Replace the full contents of `lib/features/course_catalog/presentation/level_catalog_screen.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/catalog/level_catalog.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../learning_path/providers/unit_progress_providers.dart';

/// Learn tab landing screen — the CEFR level catalogue. A1 is tappable and
/// opens the guided unit path; A2-C2 are visible but disabled with
/// accessible "Coming Soon" labelling, never selectable as if content
/// exists. See docs/PRODUCT.md and docs/ARCHITECTURE.md.
class LevelCatalogScreen extends StatelessWidget {
  const LevelCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navLearn)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final entry in kLevelCatalog)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LevelCard(entry: entry),
            ),
        ],
      ),
    );
  }
}

class _LevelCard extends ConsumerWidget {
  const _LevelCard({required this.entry});

  final LevelCatalogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final available = entry.availability == LevelAvailability.available;

    (int mastered, int total)? progress;
    if (available) {
      final contentAsync = ref.watch(courseContentProvider(entry.levelId));
      final progressAsync = ref.watch(allUnitProgressProvider);
      final total = contentAsync.value?.bundle.units.length;
      if (total != null) {
        final mastered = (progressAsync.value ?? const [])
            .where((p) => p.state == 'mastered')
            .length;
        progress = (mastered, total);
      }
    }

    return Semantics(
      button: available,
      enabled: available,
      label: available
          ? entry.cefrCode
          : '${entry.cefrCode} — ${l10n.comingSoon}',
      child: Opacity(
        opacity: available ? 1 : 0.5,
        child: Material(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: available
                ? () => context.go('/learn/${entry.levelId}')
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.cefrCode,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (progress != null)
                          Text(
                            l10n.homeLevelProgressCaption(
                              progress.$1,
                              progress.$2,
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (!available)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.comingSoon,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/features/course_catalog/presentation/level_catalog_screen_test.dart`
Expected: PASS.

- [ ] **Step 6: Run the full suite, static checks, and commit**

Run: `flutter test && dart format --set-exit-if-changed . && flutter analyze`
Expected: all pass.

```bash
git add lib/features/course_catalog/presentation/level_catalog_screen.dart test/features/course_catalog/presentation/level_catalog_screen_test.dart
git commit -m "$(cat <<'EOF'
Show per-level progress on the level catalogue

A1's card now shows "N of 13 units mastered" alongside its availability
chip, instead of nothing.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Learn journey spine (`UnitPathView` rewrite)

**Files:**
- Modify: `lib/features/learning_path/presentation/unit_path_view.dart`
- Create: `test/features/learning_path/presentation/unit_path_view_test.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`

**Interfaces:**
- Consumes: `ProgressState`/`StatusIndicator` from Task 1 (`lib/core/widgets/status_indicator.dart`).
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Add the "you are here" ARB string**

`lib/l10n/app_en.arb`:

```json
  "unitPathYouAreHere": "You are here",
  "@unitPathYouAreHere": {"description": "Marker on the Learn journey spine showing the learner's current unit."},
```

`lib/l10n/app_ar.arb`:

```json
  "unitPathYouAreHere": "أنت هنا",
```

Run: `flutter gen-l10n`
Expected: exits 0.

- [ ] **Step 2: Write the failing widget test**

Create `test/features/learning_path/presentation/unit_path_view_test.dart`:

```dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/widgets/status_indicator.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/learning_path/presentation/unit_path_view.dart';

Future<dynamic> _realA1Index() async {
  final json = File(
    'assets/content/en/A1/a1-course-bundle.json',
  ).readAsStringSync();
  return CourseBundleParser.parse(json);
}

Future<AppDatabase> _seededDb() async {
  final db = AppDatabase(NativeDatabase.memory());
  final learnerId = await db
      .into(db.learners)
      .insert(
        LearnersCompanion.insert(
          uuid: 'learner-1',
          createdAt: DateTime.utc(2026, 9, 2),
        ),
      );
  await db
      .into(db.unitProgress)
      .insert(
        UnitProgressCompanion.insert(
          uuid: 'up-1',
          learnerId: learnerId,
          unitId: 'A1-U0',
          state: 'mastered',
          updatedAt: DateTime.utc(2026, 9, 2),
        ),
      );
  return db;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('renders one StatusIndicator per unit and a you-are-here marker', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = await _seededDb();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider(
            'a1',
          ).overrideWith((ref) async => _realA1Index()),
        ],
        child: MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const UnitPathView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final index = await _realA1Index();
    expect(find.byType(StatusIndicator), findsNWidgets(index.bundle.units.length));

    final l10n = AppLocalizations.of(
      tester.element(find.byType(UnitPathView)),
    )!;
    expect(find.text(l10n.unitPathYouAreHere), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/features/learning_path/presentation/unit_path_view_test.dart`
Expected: FAIL — `UnitPathView` doesn't render `StatusIndicator` or a "you are here" marker yet.

- [ ] **Step 4: Rewrite `unit_path_view.dart`**

Replace the full contents of `lib/features/learning_path/presentation/unit_path_view.dart` with:

```dart
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/curriculum_structure.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/status_indicator.dart';
import '../providers/unit_progress_providers.dart';

/// The A1 guided unit path (U0-U12), rendered as a vertical journey spine:
/// one node per unit, larger "milestone" nodes for units with a mission
/// lesson, and a "you are here" marker at the learner's current position.
/// State badges are a recommendation, never a hard lock: every unit is
/// always tappable, per docs/PRODUCT.md flow 5. There is no Block/chapter
/// entity in the real curriculum data (see [Unit]'s doc comment) — milestone
/// grouping is derived from mission lessons, not a chapter boundary. See
/// docs/superpowers/specs/2026-09-04-ui-navigation-redesign-design.md.
class UnitPathView extends ConsumerWidget {
  const UnitPathView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(courseContentProvider('a1'));
    final progressAsync = ref.watch(allUnitProgressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('A1')),
      body: contentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (index) {
          final progressByUnitId = {
            for (final p in progressAsync.value ?? const []) p.unitId: p,
          };
          final units = index.bundle.units;
          final masteredIds = {
            for (final p in progressByUnitId.values)
              if (p.state == 'mastered') p.unitId,
          };
          final currentUnitId = units
              .where((u) => !masteredIds.contains(u.id))
              .firstOrNull
              ?.id;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: units.length,
            itemBuilder: (context, i) {
              final unit = units[i];
              return _SpineTile(
                unit: unit,
                state: ProgressState.fromRaw(progressByUnitId[unit.id]?.state),
                isMilestone: unit.lessons.any(
                  (l) => l.lessonType == 'mission',
                ),
                isCurrent: unit.id == currentUnitId,
                isFirst: i == 0,
                isLast: i == units.length - 1,
                onTap: () => context.go('/learn/a1/unit/${unit.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _SpineTile extends StatelessWidget {
  const _SpineTile({
    required this.unit,
    required this.state,
    required this.isMilestone,
    required this.isCurrent,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final Unit unit;
  final ProgressState state;
  final bool isMilestone;
  final bool isCurrent;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final railColor = colorScheme.outlineVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Expanded(
                      child: isFirst
                          ? const SizedBox.shrink()
                          : Container(width: 2, color: railColor),
                    ),
                    StatusIndicator(state: state, size: isMilestone ? 32 : 22),
                    Expanded(
                      child: isLast
                          ? const SizedBox.shrink()
                          : Container(width: 2, color: railColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isCurrent)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.unitPathYouAreHere,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colorScheme.onTertiaryContainer,
                                ),
                          ),
                        ),
                      Text(
                        unit.title,
                        textDirection: TextDirection.ltr,
                        style: isMilestone
                            ? Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)
                            : Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        unit.titleAr,
                        textDirection: TextDirection.rtl,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/features/learning_path/presentation/unit_path_view_test.dart`
Expected: PASS.

- [ ] **Step 6: Run the full suite, static checks, and commit**

Run: `flutter test && dart format --set-exit-if-changed . && flutter analyze`
Expected: all pass.

```bash
git add lib/features/learning_path/presentation/unit_path_view.dart test/features/learning_path/presentation/unit_path_view_test.dart lib/l10n/app_en.arb lib/l10n/app_ar.arb lib/core/l10n/generated
git commit -m "$(cat <<'EOF'
Redesign the Learn unit list as a journey spine

Replaces the plain list + color-pill badges with a vertical spine: one
StatusIndicator node per unit, larger milestone nodes for mission-bearing
units, and an explicit "you are here" marker at the learner's current
unit. No Block entity exists in the real curriculum data, so milestones
are derived from lessonType == 'mission' rather than a chapter boundary.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Unit overview — per-lesson status

**Files:**
- Modify: `lib/features/progress/domain/repositories/unit_lesson_progress_repository.dart`
- Modify: `lib/features/progress/data/drift_unit_lesson_progress_repository.dart`
- Modify: `lib/features/learning_path/presentation/unit_overview_screen.dart`
- Create: `test/features/progress/data/drift_unit_lesson_progress_repository_bulk_test.dart`
- Create: `test/features/learning_path/presentation/unit_overview_screen_test.dart`

**Interfaces:**
- Consumes: `ProgressState`/`StatusIndicator` from Task 1.
- Produces: `UnitLessonProgressRepository.lessonProgressForUnit({required int learnerId, required String unitId}) -> Future<List<LessonProgressData>>` — consumed only within this task.

- [ ] **Step 1: Write the failing repository test**

Create `test/features/progress/data/drift_unit_lesson_progress_repository_bulk_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/data/drift_unit_lesson_progress_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('lessonProgressForUnit returns only rows for that unit and learner', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = DriftUnitLessonProgressRepository(db);

    final learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: 'learner-1',
            createdAt: DateTime.utc(2026, 9, 2),
          ),
        );
    final otherLearnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: 'learner-2',
            createdAt: DateTime.utc(2026, 9, 2),
          ),
        );

    await repository.recordLessonPosition(
      learnerId: learnerId,
      lessonId: 'A1-U1-L1',
      unitId: 'A1-U1',
      lastActivityId: 'A1-U1-L1-A02',
    );
    await repository.recordLessonPosition(
      learnerId: learnerId,
      lessonId: 'A1-U1-L2',
      unitId: 'A1-U1',
      lastActivityId: 'A1-U1-L2-A01',
    );
    // Different unit — must not be returned.
    await repository.recordLessonPosition(
      learnerId: learnerId,
      lessonId: 'A1-U2-L1',
      unitId: 'A1-U2',
      lastActivityId: 'A1-U2-L1-A01',
    );
    // Different learner, same unit — must not be returned.
    await repository.recordLessonPosition(
      learnerId: otherLearnerId,
      lessonId: 'A1-U1-L1',
      unitId: 'A1-U1',
      lastActivityId: 'A1-U1-L1-A01',
    );

    final rows = await repository.lessonProgressForUnit(
      learnerId: learnerId,
      unitId: 'A1-U1',
    );

    expect(rows.map((r) => r.lessonId).toSet(), {'A1-U1-L1', 'A1-U1-L2'});
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/progress/data/drift_unit_lesson_progress_repository_bulk_test.dart`
Expected: FAIL — `lessonProgressForUnit` is not defined.

- [ ] **Step 3: Add `lessonProgressForUnit` to the interface and implementation**

In `lib/features/progress/domain/repositories/unit_lesson_progress_repository.dart`, add to the interface (after `lessonProgress`):

```dart
  /// All lesson-progress rows for one learner within one unit — used to
  /// render per-lesson status on the unit overview without one query per
  /// lesson. See docs/superpowers/specs/
  /// 2026-09-04-ui-navigation-redesign-design.md.
  Future<List<LessonProgressData>> lessonProgressForUnit({
    required int learnerId,
    required String unitId,
  });
```

In `lib/features/progress/data/drift_unit_lesson_progress_repository.dart`, add to the implementation (after `lessonProgress`):

```dart
  @override
  Future<List<LessonProgressData>> lessonProgressForUnit({
    required int learnerId,
    required String unitId,
  }) {
    return (_db.select(_db.lessonProgress)..where(
          (t) => t.learnerId.equals(learnerId) & t.unitId.equals(unitId),
        ))
        .get();
  }
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/progress/data/drift_unit_lesson_progress_repository_bulk_test.dart`
Expected: PASS.

- [ ] **Step 5: Write the failing `UnitOverviewScreen` widget test**

Create `test/features/learning_path/presentation/unit_overview_screen_test.dart`:

```dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/widgets/status_indicator.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/learning_path/presentation/unit_overview_screen.dart';

Future<dynamic> _realA1Index() async {
  final json = File(
    'assets/content/en/A1/a1-course-bundle.json',
  ).readAsStringSync();
  return CourseBundleParser.parse(json);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('shows one StatusIndicator per lesson in the unit', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: 'learner-1',
            createdAt: DateTime.utc(2026, 9, 2),
          ),
        );

    final index = await _realA1Index();
    final unit = index.bundle.units.first;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider(
            'a1',
          ).overrideWith((ref) async => _realA1Index()),
        ],
        child: MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: UnitOverviewScreen(unitId: unit.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byType(StatusIndicator),
      findsNWidgets(unit.lessons.length),
    );
  });
}
```

- [ ] **Step 6: Run the test to verify it fails**

Run: `flutter test test/features/learning_path/presentation/unit_overview_screen_test.dart`
Expected: FAIL — `UnitOverviewScreen` doesn't watch any progress provider or render `StatusIndicator` yet.

- [ ] **Step 7: Rewrite `unit_overview_screen.dart`**

Replace the full contents of `lib/features/learning_path/presentation/unit_overview_screen.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/curriculum_structure.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/status_indicator.dart';
import '../../progress/domain/repositories/unit_lesson_progress_repository.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';

/// Shows one unit's lessons, each with a [StatusIndicator] derived from
/// whether the learner's recorded position in that lesson has reached its
/// final activity. Every lesson is always tappable — free access, no hard
/// lock — per docs/PRODUCT.md flow 5. Revisiting a completed lesson replays
/// it from the start and appends fresh evidence rather than overwriting
/// history; see docs/DATA_MODEL.md.
class UnitOverviewScreen extends ConsumerWidget {
  const UnitOverviewScreen({required this.unitId, super.key});

  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(courseContentProvider('a1'));
    final learnerAsync = ref.watch(currentLearnerProvider);

    return contentAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
      data: (index) {
        final unit = index.unitsById[unitId];
        if (unit == null) {
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(body: Center(child: Text(l10n.contentNotFoundTitle)));
        }
        return learnerAsync.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
          data: (learner) => _UnitOverviewBody(unit: unit, learnerId: learner.id),
        );
      },
    );
  }
}

class _UnitOverviewBody extends ConsumerWidget {
  const _UnitOverviewBody({required this.unit, required this.learnerId});

  final Unit unit;
  final int learnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref
          .read(unitLessonProgressRepositoryProvider)
          .lessonProgressForUnit(learnerId: learnerId, unitId: unit.id),
      builder: (context, snapshot) {
        final progressByLessonId = {
          for (final row in snapshot.data ?? const <LessonProgressData>[])
            row.lessonId: row,
        };

        return Scaffold(
          appBar: AppBar(title: Text(unit.title)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final lesson in unit.lessons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () =>
                          context.push('/lesson-player/${unit.id}/${lesson.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            StatusIndicator(
                              state: _lessonState(
                                lesson,
                                progressByLessonId[lesson.id],
                              ),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lesson.title,
                                    textDirection: TextDirection.ltr,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  Text(
                                    lesson.titleAr,
                                    textDirection: TextDirection.rtl,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
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
                ),
            ],
          ),
        );
      },
    );
  }

  /// A lesson with no recorded position is [ProgressState.notStarted]; one
  /// whose last recorded activity is its final activity is
  /// [ProgressState.mastered] (the lesson player's own "reached the last
  /// activity" resume rule — see `lesson_player_screen.dart`); anything else
  /// recorded is [ProgressState.inProgress].
  ProgressState _lessonState(Lesson lesson, LessonProgressData? row) {
    if (row == null || lesson.activities.isEmpty) {
      return ProgressState.notStarted;
    }
    final lastActivityId = row.lastActivityId;
    if (lastActivityId != null &&
        lastActivityId == lesson.activities.last.id) {
      return ProgressState.mastered;
    }
    return ProgressState.inProgress;
  }
}
```

- [ ] **Step 8: Run the test to verify it passes**

Run: `flutter test test/features/learning_path/presentation/unit_overview_screen_test.dart`
Expected: PASS.

- [ ] **Step 9: Run the full suite, static checks, and commit**

Run: `flutter test && dart format --set-exit-if-changed . && flutter analyze`
Expected: all pass.

```bash
git add lib/features/progress/domain/repositories/unit_lesson_progress_repository.dart lib/features/progress/data/drift_unit_lesson_progress_repository.dart lib/features/learning_path/presentation/unit_overview_screen.dart test/features/progress/data/drift_unit_lesson_progress_repository_bulk_test.dart test/features/learning_path/presentation/unit_overview_screen_test.dart
git commit -m "$(cat <<'EOF'
Show per-lesson status on the unit overview screen

This was the single most concrete gap from the navigation audit: a
learner had no way to tell which lessons in a unit they'd already done.
Backed by a new lessonProgressForUnit bulk query (no schema change).

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Lesson player — in-lesson progress bar + richer completion screen

**Files:**
- Modify: `lib/features/lesson_player/presentation/lesson_player_screen.dart`
- Create: `test/features/lesson_player/presentation/lesson_complete_screen_test.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`

**Interfaces:**
- Consumes: `ActivityCorrectness`/`ActivitySubmission` (existing, `activity_submission.dart`).
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Add new ARB strings**

`lib/l10n/app_en.arb`:

```json
  "lessonCompleteTally": "{correct} of {total} correct",
  "@lessonCompleteTally": {
    "description": "Lesson-complete screen: auto-graded correct/total tally.",
    "placeholders": {
      "correct": {"type": "int"},
      "total": {"type": "int"}
    }
  },
  "lessonCompletePendingReview": "{count, plural, =1{1 answer saved for review} other{{count} answers saved for review}}",
  "@lessonCompletePendingReview": {
    "description": "Lesson-complete screen: writing/speaking answers not auto-graded.",
    "placeholders": {"count": {"type": "int"}}
  },
  "lessonCompleteNextLesson": "Next lesson",
  "@lessonCompleteNextLesson": {"description": "Lesson-complete screen CTA when more lessons remain in the unit."},
  "lessonCompleteBackToUnit": "Back to unit",
  "@lessonCompleteBackToUnit": {"description": "Lesson-complete screen CTA when this was the unit's last lesson."},
```

`lib/l10n/app_ar.arb`:

```json
  "lessonCompleteTally": "{correct} من {total} إجابة صحيحة",
  "lessonCompletePendingReview": "{count, plural, =1{إجابة واحدة محفوظة للمراجعة} other{{count} إجابات محفوظة للمراجعة}}",
  "lessonCompleteNextLesson": "الدرس التالي",
  "lessonCompleteBackToUnit": "العودة إلى الوحدة",
```

Run: `flutter gen-l10n`
Expected: exits 0.

- [ ] **Step 2: Write the failing widget test for `_LessonCompleteScreen`**

`_LessonCompleteScreen` is currently private with a no-argument const constructor. This task changes its constructor, so test it directly by making it accessible — since it's a private class in `lesson_player_screen.dart`, the test lives in the same `test/features/lesson_player/presentation/` directory but tests behavior through the full `LessonPlayerScreen` flow (matching the existing `lesson_player_e2e_test.dart` pattern referenced in `README.md`). Read `test/features/lesson_player/presentation/lesson_player_e2e_test.dart` first to reuse its exact ProviderScope/answer-driving setup, then add a new test to a new file:

Create `test/features/lesson_player/presentation/lesson_complete_screen_test.dart`:

```dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/lesson_player/presentation/lesson_player_screen.dart';

Future<dynamic> _realA1Index() async {
  final json = File(
    'assets/content/en/A1/a1-course-bundle.json',
  ).readAsStringSync();
  return CourseBundleParser.parse(json);
}

/// Answers every activity type with a plausible, submittable response —
/// enough to drive the player to completion, not necessarily correctly.
/// Mirrors the answer-driving approach used by
/// test/features/placement_test/placement_test_screen_test.dart.
Future<void> _answerCurrentActivity(WidgetTester tester, Activity activity) async {
  final choiceFinder = find.byType(RadioListTile<String>);
  if (choiceFinder.evaluate().isNotEmpty) {
    await tester.tap(choiceFinder.first);
    await tester.pump();
  } else {
    final textFieldFinder = find.byType(TextField);
    if (textFieldFinder.evaluate().isNotEmpty) {
      await tester.enterText(textFieldFinder.first, 'a plausible answer');
      await tester.pump();
    }
  }
  final submitFinder = find.text(
    AppLocalizations.of(tester.element(find.byType(Scaffold).first))!
        .activitySubmitButton,
  );
  if (submitFinder.evaluate().isNotEmpty) {
    await tester.tap(submitFinder.first);
    await tester.pumpAndSettle();
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('shows a tally and a forward CTA on lesson completion', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: 'learner-1',
            createdAt: DateTime.utc(2026, 9, 2),
          ),
        );

    final index = await _realA1Index();
    final unit = index.bundle.units.first;
    final lesson = unit.lessons.first;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider(
            'a1',
          ).overrideWith((ref) async => _realA1Index()),
        ],
        child: MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: LessonPlayerScreen(unitId: unit.id, lessonId: lesson.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final activity in lesson.activities) {
      await _answerCurrentActivity(tester, activity);
      final nextFinder = find.text(
        AppLocalizations.of(tester.element(find.byType(Scaffold).first))!
            .lessonPlayerNext,
      );
      if (nextFinder.evaluate().isNotEmpty) {
        await tester.tap(nextFinder.first);
        await tester.pumpAndSettle();
      }
    }

    final l10n = AppLocalizations.of(
      tester.element(find.byType(Scaffold).first),
    )!;
    expect(find.textContaining('correct'), findsWidgets);
    expect(
      find.text(l10n.lessonCompleteNextLesson).evaluate().isNotEmpty ||
          find.text(l10n.lessonCompleteBackToUnit).evaluate().isNotEmpty,
      isTrue,
    );
  });
}
```

Note: before finalizing this test, read `test/features/lesson_player/presentation/lesson_player_e2e_test.dart` in full and reconcile `_answerCurrentActivity` with whatever exact finder/answer-driving helper that file already uses per activity type (`choice`/`gap`/`order`/`match`/`form`/`write`/`speak`/`dialogue`) — reuse its exact helper rather than the simplified one sketched above if the real activity widgets need more specific interaction (e.g. `speak` activities render a typed-answer fallback field with a different key). Adjust imports accordingly.

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/features/lesson_player/presentation/lesson_complete_screen_test.dart`
Expected: FAIL — no "correct" text and no next-lesson/back-to-unit CTA text exist on the current static `_LessonCompleteScreen`.

- [ ] **Step 4: Add a running tally and thread it + navigation into `_LessonCompleteScreen`**

In `lib/features/lesson_player/presentation/lesson_player_screen.dart`:

Add a field to `_LessonPlayerBodyState` (after `bool _finished = false;`):

```dart
  final List<ActivityCorrectness> _results = [];
```

In `_handleSubmitted`, after the existing `if (mounted) setState(() => _lastSubmission = submission);` line, add (still inside the method, so it runs every submission):

```dart
    _results.add(submission.correctness);
```

(Insert this line just before the existing `if (mounted) setState(...)` line, so `_results` is updated synchronously before the rebuild.)

Replace the `_next()` method's `if (mounted) setState(() => _finished = true);` line with the same line unchanged — no change needed there, `_finished` still gates rendering `_LessonCompleteScreen`.

Compute the next lesson in `_LessonPlayerBodyState.build()`. Replace:

```dart
    if (_finished) {
      return const _LessonCompleteScreen();
    }
```

with:

```dart
    if (_finished) {
      final lessons = widget.unit.lessons;
      final currentIndex = lessons.indexWhere((l) => l.id == widget.lesson.id);
      final nextLesson = currentIndex >= 0 && currentIndex < lessons.length - 1
          ? lessons[currentIndex + 1]
          : null;
      return _LessonCompleteScreen(
        results: _results,
        onNext: nextLesson != null
            ? () => context.pushReplacement(
                '/lesson-player/${widget.unitId}/${nextLesson.id}',
              )
            : () => context.pop(),
      );
    }
```

Add `import 'package:go_router/go_router.dart';` at the top of the file if not already present (it already is — confirmed by the existing `context.go`/`context.push` usage elsewhere in this file's imports).

Replace the full `_LessonCompleteScreen` class with:

```dart
class _LessonCompleteScreen extends StatelessWidget {
  const _LessonCompleteScreen({required this.results, required this.onNext});

  final List<ActivityCorrectness> results;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final correct = results
        .where((r) => r == ActivityCorrectness.correct)
        .length;
    final incorrect = results
        .where((r) => r == ActivityCorrectness.incorrect)
        .length;
    final pending = results
        .where((r) => r == ActivityCorrectness.notAutoGraded)
        .length;
    final scored = correct + incorrect;
    final isNextLesson = onNext != _popCallback(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.celebration, size: 48, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                l10n.lessonCompleteTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (scored > 0)
                Text(l10n.lessonCompleteTally(correct, scored)),
              if (pending > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.lessonCompletePendingReview(pending),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onNext,
                child: Text(
                  isNextLesson
                      ? l10n.lessonCompleteNextLesson
                      : l10n.lessonCompleteBackToUnit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

The `isNextLesson` line above (`onNext != _popCallback(context)`) is not a valid way to distinguish the two cases — function identity comparison like that will not reliably work. Replace this approach: pass an explicit `bool hasNextLesson` parameter instead of trying to infer it from the callback. Revise the class to:

```dart
class _LessonCompleteScreen extends StatelessWidget {
  const _LessonCompleteScreen({
    required this.results,
    required this.hasNextLesson,
    required this.onNext,
  });

  final List<ActivityCorrectness> results;
  final bool hasNextLesson;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final correct = results
        .where((r) => r == ActivityCorrectness.correct)
        .length;
    final incorrect = results
        .where((r) => r == ActivityCorrectness.incorrect)
        .length;
    final pending = results
        .where((r) => r == ActivityCorrectness.notAutoGraded)
        .length;
    final scored = correct + incorrect;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.celebration, size: 48, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                l10n.lessonCompleteTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (scored > 0) Text(l10n.lessonCompleteTally(correct, scored)),
              if (pending > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.lessonCompletePendingReview(pending),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onNext,
                child: Text(
                  hasNextLesson
                      ? l10n.lessonCompleteNextLesson
                      : l10n.lessonCompleteBackToUnit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

And update the call site in `build()` to pass `hasNextLesson` explicitly:

```dart
    if (_finished) {
      final lessons = widget.unit.lessons;
      final currentIndex = lessons.indexWhere((l) => l.id == widget.lesson.id);
      final nextLesson = currentIndex >= 0 && currentIndex < lessons.length - 1
          ? lessons[currentIndex + 1]
          : null;
      return _LessonCompleteScreen(
        results: _results,
        hasNextLesson: nextLesson != null,
        onNext: nextLesson != null
            ? () => context.pushReplacement(
                '/lesson-player/${widget.unitId}/${nextLesson.id}',
              )
            : () => context.pop(),
      );
    }
```

Also add the in-lesson progress bar: replace the `AppBar` in the non-finished branch of `build()`:

```dart
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.lessonPlayerProgress(_currentIndex! + 1, activities.length),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentIndex! + 1) / activities.length,
            minHeight: 4,
          ),
        ),
      ),
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/features/lesson_player/presentation/lesson_complete_screen_test.dart`
Expected: PASS. If the answer-driving helper needs adjustment per the note in Step 2 to actually reach the completion screen for every activity type in the first lesson, iterate on it now until the test passes for real (don't weaken the assertions to work around a helper that doesn't actually finish the lesson).

- [ ] **Step 6: Run the full suite, static checks, and commit**

Run: `flutter test && dart format --set-exit-if-changed . && flutter analyze`
Expected: all pass — pay particular attention to the existing `test/features/lesson_player/presentation/lesson_player_e2e_test.dart`, which may reference the old no-argument `_LessonCompleteScreen` constructor indirectly; fix any resulting failures by reading that file and adjusting it to expect the new tally/CTA content instead of the old static copy.

```bash
git add lib/features/lesson_player/presentation/lesson_player_screen.dart test/features/lesson_player/presentation/lesson_complete_screen_test.dart lib/l10n/app_en.arb lib/l10n/app_ar.arb lib/core/l10n/generated
git commit -m "$(cat <<'EOF'
Add in-lesson progress bar and a real lesson-complete result screen

The lesson-complete screen now shows a correct/total tally and a
next-lesson (or back-to-unit) CTA instead of identical static copy
regardless of performance. The app bar also gains a visible progress
bar alongside the existing "N of M" text.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Review confidence row — visible feedback + forward motion

**Files:**
- Modify: `lib/features/vocabulary/presentation/review_confidence_row.dart`
- Create: `test/features/vocabulary/presentation/review_confidence_row_test.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Add the ARB string**

`lib/l10n/app_en.arb`:

```json
  "reviewConfidenceSaved": "Saved",
  "@reviewConfidenceSaved": {"description": "Confirmation shown briefly after tapping a spaced-review confidence button, before returning to the previous screen."},
```

`lib/l10n/app_ar.arb`:

```json
  "reviewConfidenceSaved": "تم الحفظ",
```

Run: `flutter gen-l10n`
Expected: exits 0.

- [ ] **Step 2: Write the failing widget test**

Create `test/features/vocabulary/presentation/review_confidence_row_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/vocabulary/presentation/review_confidence_row.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
    'shows a saved confirmation then pops back after tapping a confidence button',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    key: const Key('push'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const Scaffold(
                          body: ReviewConfidenceRow(lexiconId: 'A1.LEX.HELLO.INTJ'),
                        ),
                      ),
                    ),
                    child: const Text('open word'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('push')));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ReviewConfidenceRow)),
      )!;
      await tester.tap(find.text(l10n.reviewQualityGood));
      await tester.pump();

      expect(find.text(l10n.reviewConfidenceSaved), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('open word'), findsOneWidget);
      expect(find.byType(ReviewConfidenceRow), findsNothing);
    },
  );
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/features/vocabulary/presentation/review_confidence_row_test.dart`
Expected: FAIL — no confirmation text appears and no pop happens with the current implementation.

- [ ] **Step 4: Rewrite `review_confidence_row.dart`**

Replace the full contents of `lib/features/vocabulary/presentation/review_confidence_row.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../domain/spaced_review_scheduler.dart';
import '../providers/vocabulary_providers.dart';

/// The 3-button spaced-review confidence row, shared by word and chunk
/// detail screens. Recording a review here only ever updates the vocabulary
/// memory schedule — it never grants course/Can-Do mastery, which is
/// tracked entirely separately via `MasteryAggregationService`. See
/// docs/DATA_MODEL.md.
///
/// After a tap: shows a brief saved confirmation, then pops the current
/// route — the screen this row lives on (a word/chunk detail screen) was
/// pushed to review this one item, so returning is the natural "done"
/// action. See docs/superpowers/specs/
/// 2026-09-04-ui-navigation-redesign-design.md.
class ReviewConfidenceRow extends ConsumerStatefulWidget {
  const ReviewConfidenceRow({this.lexiconId, this.chunkId, super.key})
    : assert(
        (lexiconId == null) != (chunkId == null),
        'exactly one of lexiconId/chunkId must be set',
      );

  final String? lexiconId;
  final String? chunkId;

  @override
  ConsumerState<ReviewConfidenceRow> createState() =>
      _ReviewConfidenceRowState();
}

class _ReviewConfidenceRowState extends ConsumerState<ReviewConfidenceRow> {
  ReviewQuality? _selected;

  Future<void> _record(ReviewQuality quality) async {
    setState(() => _selected = quality);
    final learner = await ref.read(currentLearnerProvider.future);
    await ref
        .read(vocabularyReviewServiceProvider)
        .recordReview(
          learnerId: learner.id,
          lexiconId: widget.lexiconId,
          chunkId: widget.chunkId,
          quality: quality,
        );
    ref.invalidate(allVocabularyReviewStateProvider);
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_selected != null) {
      return _SavedConfirmation();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.reviewHowWellKnew,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _confidenceButton(l10n.reviewQualityAgain, ReviewQuality.again),
            const SizedBox(width: 8),
            _confidenceButton(l10n.reviewQualityGood, ReviewQuality.good),
            const SizedBox(width: 8),
            _confidenceButton(l10n.reviewQualityEasy, ReviewQuality.easy),
          ],
        ),
      ],
    );
  }

  Widget _confidenceButton(String label, ReviewQuality quality) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _record(quality),
        child: Text(label),
      ),
    );
  }
}

class _SavedConfirmation extends StatelessWidget {
  const _SavedConfirmation();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: colorScheme.onPrimaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.reviewConfidenceSaved,
                style: TextStyle(color: colorScheme.onPrimaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/features/vocabulary/presentation/review_confidence_row_test.dart`
Expected: PASS.

- [ ] **Step 6: Run the full suite, static checks, and commit**

Run: `flutter test && dart format --set-exit-if-changed . && flutter analyze`
Expected: all pass — check `test/features/vocabulary/presentation/vocabulary_review_screens_smoke_test.dart` (and any other existing test that renders `WordDetailScreen`/`ChunkDetailScreen`/`ReviewConfidenceRow`) for assumptions about the old stateless/no-feedback behavior; update as needed.

```bash
git add lib/features/vocabulary/presentation/review_confidence_row.dart test/features/vocabulary/presentation/review_confidence_row_test.dart lib/l10n/app_en.arb lib/l10n/app_ar.arb lib/core/l10n/generated
git commit -m "$(cat <<'EOF'
Give the review confidence row visible feedback and forward motion

Tapping Again/Good/Easy previously did nothing visible. It now shows a
brief saved confirmation, then returns to the previous screen (the
list the learner came from) instead of leaving them stranded on an
unchanged word/chunk detail screen.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Vocabulary list rows — due/new/mastered status badge

**Files:**
- Modify: `lib/features/vocabulary/presentation/vocabulary_list_screen.dart`
- Create: `test/features/vocabulary/presentation/vocabulary_list_screen_status_test.dart`

**Interfaces:**
- Consumes: `ProgressState`/`StatusIndicator` from Task 1.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write the failing widget test**

Create `test/features/vocabulary/presentation/vocabulary_list_screen_status_test.dart`:

```dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/widgets/status_indicator.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/vocabulary/presentation/vocabulary_list_screen.dart';

Future<dynamic> _realA1Index() async {
  final json = File(
    'assets/content/en/A1/a1-course-bundle.json',
  ).readAsStringSync();
  return CourseBundleParser.parse(json);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('word rows show a status indicator alongside the favorite star', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider(
            'a1',
          ).overrideWith((ref) async => _realA1Index()),
        ],
        child: MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const VocabularyListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StatusIndicator), findsWidgets);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/vocabulary/presentation/vocabulary_list_screen_status_test.dart`
Expected: FAIL — `_VocabularyRow` currently renders only a favorite star, no `StatusIndicator`.

- [ ] **Step 3: Add a vocabulary-specific `ProgressState` mapping and render it**

In `lib/features/vocabulary/presentation/vocabulary_list_screen.dart`, add the import:

```dart
import '../../../core/widgets/status_indicator.dart';
```

Add this top-level function (near the bottom, alongside `_matchesQuery`):

```dart
/// Maps one vocabulary/chunk review row onto the shared 4-state
/// [ProgressState]: no row (or never successfully recalled) is
/// [ProgressState.notStarted]; overdue is [ProgressState.needsReview];
/// recalled at least once but not yet graduated (repetitions < 3, matching
/// [SpacedReviewScheduler]'s interval steps: 1st repetition -> 1 day, 2nd ->
/// 6 days, 3rd+ -> ease-factor-driven) is [ProgressState.inProgress];
/// repetitions >= 3 is [ProgressState.mastered]. See docs/superpowers/specs/
/// 2026-09-04-ui-navigation-redesign-design.md.
ProgressState _vocabularyProgressState({
  required int repetitions,
  required DateTime? dueAt,
  required DateTime now,
}) {
  if (repetitions == 0) return ProgressState.notStarted;
  if (dueAt != null && dueAt.isBefore(now)) return ProgressState.needsReview;
  if (repetitions >= 3) return ProgressState.mastered;
  return ProgressState.inProgress;
}
```

In `_WordListView.build`, inside the `data:` callback, add alongside the existing `favoriteLexiconIds` computation:

```dart
        final reviewStateByLexiconId = {
          for (final s in reviewStateAsync.value ?? const [])
            if (s.lexiconId != null) s.lexiconId!: s,
        };
```

Then in its `itemBuilder`, compute the state and pass it through:

```dart
          itemBuilder: (context, i) {
            final item = items[i];
            final isFavorite = favoriteLexiconIds.contains(item.id);
            final reviewState = reviewStateByLexiconId[item.id];
            return _VocabularyRow(
              headword: item.headword,
              arabic: item.arabic,
              isFavorite: isFavorite,
              progressState: _vocabularyProgressState(
                repetitions: reviewState?.repetitions ?? 0,
                dueAt: reviewState?.dueAt,
                now: DateTime.now(),
              ),
              onTap: () => context.push('/review/vocabulary/${item.id}'),
            );
          },
```

Apply the same pattern to `_ChunkListView` (using `favoriteChunkIds`/`reviewStateByChunkId` analogously — build a `reviewStateByChunkId` map keyed by `s.chunkId!` where `s.chunkId != null`, and pass `progressState` the same way).

Update `_VocabularyRow` to accept and render it:

```dart
class _VocabularyRow extends StatelessWidget {
  const _VocabularyRow({
    required this.headword,
    required this.arabic,
    required this.isFavorite,
    required this.progressState,
    required this.onTap,
  });

  final String headword;
  final String arabic;
  final bool isFavorite;
  final ProgressState progressState;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: StatusIndicator(state: progressState, size: 20),
      title: Text(headword, textDirection: TextDirection.ltr),
      subtitle: Text(arabic, textDirection: TextDirection.rtl),
      trailing: isFavorite
          ? Icon(Icons.star, color: Theme.of(context).colorScheme.tertiary)
          : null,
    );
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/vocabulary/presentation/vocabulary_list_screen_status_test.dart`
Expected: PASS.

- [ ] **Step 5: Run the full suite, static checks, and commit**

Run: `flutter test && dart format --set-exit-if-changed . && flutter analyze`
Expected: all pass.

```bash
git add lib/features/vocabulary/presentation/vocabulary_list_screen.dart test/features/vocabulary/presentation/vocabulary_list_screen_status_test.dart
git commit -m "$(cat <<'EOF'
Show due/new/mastered status on vocabulary list rows

Rows previously showed only a favourite star, with no due/learned/new
signal. Adds the shared StatusIndicator, mapped from each item's
spaced-review repetitions/dueAt.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Review nav-tab due-count badge

**Files:**
- Modify: `lib/features/app_shell/presentation/app_shell_scaffold.dart`
- Create: `test/features/app_shell/presentation/app_shell_scaffold_badge_test.dart`

**Interfaces:**
- Consumes: `dueVocabularyCountProvider` from Task 2.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write the failing widget test**

Create `test/features/app_shell/presentation/app_shell_scaffold_badge_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/review/providers/review_providers.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('review nav destination shows a Badge when items are due', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // Minimal harness: a NavigationBar built the same way
    // AppShellScaffold builds its Review destination, with
    // dueVocabularyCountProvider overridden directly (avoids needing a
    // full go_router StatefulNavigationShell in this test).
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          dueVocabularyCountProvider.overrideWithValue(const AsyncData(3)),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final dueCount = ref.watch(dueVocabularyCountProvider).value ?? 0;
            return MaterialApp(
              home: Scaffold(
                bottomNavigationBar: NavigationBar(
                  destinations: [
                    NavigationDestination(
                      icon: dueCount > 0
                          ? Badge(
                              label: Text('$dueCount'),
                              child: const Icon(Icons.refresh_outlined),
                            )
                          : const Icon(Icons.refresh_outlined),
                      label: 'Review',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Badge), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}
```

(This test validates the `Badge`-wrapping approach in isolation before wiring it into the real `AppShellScaffold`, since that widget is driven by a live `StatefulNavigationShell` that's awkward to construct standalone in a widget test.)

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/app_shell/presentation/app_shell_scaffold_badge_test.dart`
Expected: FAIL initially only if there's a typo/import issue — this test exercises a local harness, not `AppShellScaffold` itself, so it should actually pass immediately once written correctly (Flutter's `Badge` widget already exists in the SDK). Run it now to confirm the harness itself is correct before moving on:

Run: `flutter test test/features/app_shell/presentation/app_shell_scaffold_badge_test.dart`
Expected: PASS (this step validates the test harness, not app code — there is no "make it fail first" step here since no app code changed yet).

- [ ] **Step 3: Wire the badge into the real `AppShellScaffold`**

Replace the full contents of `lib/features/app_shell/presentation/app_shell_scaffold.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../review/providers/review_providers.dart';

/// The 5-tab bottom-navigation shell (Home / Learn / Review / Tests /
/// Settings) — see docs/ARCHITECTURE.md's navigation map. Vocabulary and
/// Grammar live inside Review, not as separate top-level destinations.
class AppShellScaffold extends ConsumerWidget {
  const AppShellScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dueCount = ref.watch(dueVocabularyCountProvider).value ?? 0;

    Widget reviewIcon(IconData icon) {
      if (dueCount <= 0) return Icon(icon);
      return Badge(label: Text('$dueCount'), child: Icon(icon));
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: l10n.navLearn,
          ),
          NavigationDestination(
            icon: reviewIcon(Icons.refresh_outlined),
            selectedIcon: reviewIcon(Icons.refresh),
            label: l10n.navReview,
          ),
          NavigationDestination(
            icon: const Icon(Icons.fact_check_outlined),
            selectedIcon: const Icon(Icons.fact_check),
            label: l10n.navTests,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the full suite, static checks, and commit**

Run: `flutter test && dart format --set-exit-if-changed . && flutter analyze`
Expected: all pass — check for any existing test that constructs `AppShellScaffold` directly (it's now a `ConsumerWidget`, so any such test needs a `ProviderScope` ancestor if it didn't already have one).

```bash
git add lib/features/app_shell/presentation/app_shell_scaffold.dart test/features/app_shell/presentation/app_shell_scaffold_badge_test.dart
git commit -m "$(cat <<'EOF'
Add a due-count badge to the Review nav tab

The due count is now visible before opening the Review tab, using
Flutter's Badge widget wrapped around the existing nav icon (there is
no badge: parameter on NavigationDestination in this Flutter version).

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: Tests home — state-aware cards

**Files:**
- Create: `lib/features/tests_home/providers/tests_home_providers.dart`
- Modify: `lib/features/tests_home/presentation/tests_home_screen.dart`
- Create: `test/features/tests_home/presentation/tests_home_screen_test.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`

**Interfaces:**
- Consumes: `AssessmentAttemptRepository.latestPlacementAttempt`/`latestFinalMissionAttempt`/`latestFinalAssessmentAttempt` (existing, `assessment_attempt_repository.dart`).
- Produces: `latestPlacementAttemptProvider`, `latestFinalMissionAttemptProvider`, `latestFinalAssessmentAttemptProvider` (each `FutureProvider<X?>`) — consumed only within this task.

- [ ] **Step 1: Add ARB strings for the state lines**

`lib/l10n/app_en.arb`:

```json
  "testsHomeNotYetTaken": "Not yet taken",
  "@testsHomeNotYetTaken": {"description": "Tests tab card state line — no attempt exists yet."},
  "testsHomeInProgress": "In progress",
  "@testsHomeInProgress": {"description": "Tests tab card state line — an attempt was started but not completed."},
  "testsHomeCompletedOn": "Completed {date}",
  "@testsHomeCompletedOn": {
    "description": "Tests tab card state line — an attempt was completed on this date.",
    "placeholders": {"date": {"type": "String"}}
  },
```

`lib/l10n/app_ar.arb`:

```json
  "testsHomeNotYetTaken": "لم يُخض بعد",
  "testsHomeInProgress": "قيد التقدّم",
  "testsHomeCompletedOn": "اكتمل في {date}",
```

Run: `flutter gen-l10n`
Expected: exits 0.

- [ ] **Step 2: Write the failing widget test**

Create `test/features/tests_home/presentation/tests_home_screen_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/tests_home/presentation/tests_home_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<Widget> wrapped(AppDatabase db) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const TestsHomeScreen(),
      ),
    );
  }

  testWidgets('placement card shows "not yet taken" with no attempt', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(await wrapped(db));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(TestsHomeScreen)),
    )!;
    expect(find.text(l10n.testsHomeNotYetTaken), findsWidgets);
  });

  testWidgets('placement card shows a completed date after an attempt', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: 'learner-1',
            createdAt: DateTime.utc(2026, 9, 2),
          ),
        );
    await db
        .into(db.placementAttempts)
        .insert(
          PlacementAttemptsCompanion.insert(
            uuid: 'pa-1',
            learnerId: learnerId,
            startedAt: DateTime.utc(2026, 9, 2),
            completedAt: const Value(null),
          ),
        );
    await (db.update(
      db.placementAttempts,
    )..where((t) => t.learnerId.equals(learnerId))).write(
      PlacementAttemptsCompanion(
        completedAt: Value(DateTime.utc(2026, 9, 2)),
        outcome: const Value('a1FromU1'),
      ),
    );

    await tester.pumpWidget(await wrapped(db));
    await tester.pumpAndSettle();

    expect(find.textContaining('Completed'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/features/tests_home/presentation/tests_home_screen_test.dart`
Expected: FAIL — `TestsHomeScreen` is currently a `StatelessWidget` with no state lines at all.

- [ ] **Step 4: Add the three latest-attempt providers**

Create `lib/features/tests_home/providers/tests_home_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';

/// The current learner's latest attempt at each of the three Tests-tab
/// flows — `null` when never attempted. Backs the state line shown on each
/// TestsHomeScreen card. See docs/superpowers/specs/
/// 2026-09-04-ui-navigation-redesign-design.md.
final latestPlacementAttemptProvider = FutureProvider<PlacementAttempt?>((
  ref,
) async {
  final learner = await ref.watch(currentLearnerProvider.future);
  final repository = ref.watch(assessmentAttemptRepositoryProvider);
  return repository.latestPlacementAttempt(learnerId: learner.id);
});

final latestFinalMissionAttemptProvider =
    FutureProvider<FinalMissionAttempt?>((ref) async {
      final learner = await ref.watch(currentLearnerProvider.future);
      final repository = ref.watch(assessmentAttemptRepositoryProvider);
      return repository.latestFinalMissionAttempt(learnerId: learner.id);
    });

final latestFinalAssessmentAttemptProvider =
    FutureProvider<FinalAssessmentAttempt?>((ref) async {
      final learner = await ref.watch(currentLearnerProvider.future);
      final repository = ref.watch(assessmentAttemptRepositoryProvider);
      return repository.latestFinalAssessmentAttempt(learnerId: learner.id);
    });
```

- [ ] **Step 5: Rewrite `tests_home_screen.dart`**

Replace the full contents of `lib/features/tests_home/presentation/tests_home_screen.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../providers/tests_home_providers.dart';

/// Tests tab landing screen — links out to the A1 Gateway Placement Test,
/// the Final Mission, and the Final Assessment, each showing its own latest-
/// attempt state (not yet taken / in progress / completed on a date), plus
/// two informational entries: unit mastery checks (already visible as unit
/// badges on the Learn tab, not a separate flow) and future-level placement
/// (Coming Soon — this app has no content beyond A1 yet).
class TestsHomeScreen extends ConsumerWidget {
  const TestsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final placementAsync = ref.watch(latestPlacementAttemptProvider);
    final missionAsync = ref.watch(latestFinalMissionAttemptProvider);
    final assessmentAsync = ref.watch(latestFinalAssessmentAttemptProvider);
    final locale = Localizations.localeOf(context).languageCode;

    String stateLine(DateTime? startedAt, DateTime? completedAt) {
      if (startedAt == null) return l10n.testsHomeNotYetTaken;
      if (completedAt == null) return l10n.testsHomeInProgress;
      return l10n.testsHomeCompletedOn(
        DateFormat.yMMMd(locale).format(completedAt),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navTests)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TestCard(
            icon: Icons.flag_outlined,
            title: l10n.testsHomePlacementTitle,
            subtitle: l10n.testsHomePlacementSubtitle,
            stateLine: stateLine(
              placementAsync.value?.startedAt,
              placementAsync.value?.completedAt,
            ),
            onTap: () => context.push('/tests/placement'),
          ),
          const SizedBox(height: 12),
          _TestCard(
            icon: Icons.explore_outlined,
            title: l10n.testsHomeFinalMissionTitle,
            subtitle: l10n.testsHomeFinalMissionSubtitle,
            stateLine: stateLine(
              missionAsync.value?.startedAt,
              missionAsync.value?.completedAt,
            ),
            onTap: () => context.push('/tests/final-mission'),
          ),
          const SizedBox(height: 12),
          _TestCard(
            icon: Icons.fact_check_outlined,
            title: l10n.testsHomeFinalAssessmentTitle,
            subtitle: l10n.testsHomeFinalAssessmentSubtitle,
            stateLine: stateLine(
              assessmentAsync.value?.startedAt,
              assessmentAsync.value?.completedAt,
            ),
            onTap: () => context.push('/tests/final-assessment'),
          ),
          const SizedBox(height: 12),
          _TestCard(
            icon: Icons.checklist_outlined,
            title: l10n.testsHomeUnitChecksTitle,
            subtitle: l10n.testsHomeUnitChecksSubtitle,
            stateLine: null,
            onTap: () => context.go('/learn/a1'),
          ),
          const SizedBox(height: 12),
          _TestCard(
            icon: Icons.upgrade_outlined,
            title: l10n.testsHomeFutureLevelsTitle,
            subtitle: l10n.comingSoon,
            stateLine: null,
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.stateLine,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? stateLine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            if (stateLine != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  stateLine!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        isThreeLine: stateLine != null,
        enabled: onTap != null,
        onTap: onTap,
      ),
    );
  }
}
```

Confirm `intl` is already a dependency before using `DateFormat`: run `grep "intl:" pubspec.yaml`. It's a transitive requirement of Flutter's official ARB-based localization setup already in use in this project (`flutter: generate: true` in `pubspec.yaml`), so it should already be present; if the grep finds nothing, add `intl: ^0.20.2` (or whatever version `flutter pub outdated` resolves to satisfy the Flutter SDK's own `intl` constraint) to `pubspec.yaml`'s `dependencies:` section and run `flutter pub get` before continuing.

- [ ] **Step 6: Run the test to verify it passes**

Run: `flutter test test/features/tests_home/presentation/tests_home_screen_test.dart`
Expected: PASS.

- [ ] **Step 7: Run the full suite, static checks, and commit**

Run: `flutter test && dart format --set-exit-if-changed . && flutter analyze`
Expected: all pass.

```bash
git add lib/features/tests_home/providers/tests_home_providers.dart lib/features/tests_home/presentation/tests_home_screen.dart test/features/tests_home/presentation/tests_home_screen_test.dart lib/l10n/app_en.arb lib/l10n/app_ar.arb lib/core/l10n/generated pubspec.yaml pubspec.lock
git commit -m "$(cat <<'EOF'
Show attempt state on each Tests-tab card

Placement/Final Mission/Final Assessment cards previously looked
identical regardless of history. Each now shows "Not yet taken",
"In progress", or "Completed <date>", sourced from existing attempt
tables — no new persistence.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Task 11: Final assessment result — scores + next-step link

**Files:**
- Modify: `lib/features/final_assessment/presentation/final_assessment_screen.dart`
- Create: `test/features/final_assessment/presentation/final_assessment_result_test.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`

**Interfaces:**
- Consumes: `FinalAssessmentSectionResult.averageScore` (existing field, currently unrendered).
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Add ARB strings**

`lib/l10n/app_en.arb`:

```json
  "finalAssessmentSectionScore": "{percent}%",
  "@finalAssessmentSectionScore": {
    "description": "Final Assessment result screen — a section's average score as a percentage.",
    "placeholders": {"percent": {"type": "int"}}
  },
  "finalAssessmentWhatsNext": "Keep practicing",
  "@finalAssessmentWhatsNext": {"description": "Final Assessment result screen CTA shown when the overall result isn't yet a pass, linking back to the Learn tab."},
```

`lib/l10n/app_ar.arb`:

```json
  "finalAssessmentSectionScore": "{percent}٪",
  "finalAssessmentWhatsNext": "واصل التدرّب",
```

Run: `flutter gen-l10n`
Expected: exits 0.

- [ ] **Step 2: Write the failing widget test**

Read `lib/features/final_assessment/domain/final_assessment_scoring.dart` first to confirm `FinalAssessmentSectionResult`'s exact constructor (fields already known from the plan's research: `section`, `status`, `averageScore`, `scoredCount`, `pendingReviewCount` — confirm exact parameter names/types before writing the test, since the constructor call below must match exactly).

Create `test/features/final_assessment/presentation/final_assessment_result_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/features/final_assessment/domain/final_assessment_scoring.dart';
import 'package:mohingo/features/final_assessment/presentation/final_assessment_screen.dart';

void main() {
  testWidgets('shows a percentage score per section and a next-step link when not passed', (
    tester,
  ) async {
    final results = [
      FinalAssessmentSectionResult(
        section: 'reading',
        status: FinalAssessmentSectionStatus.passed,
        averageScore: 0.9,
        scoredCount: 5,
        pendingReviewCount: 0,
      ),
      FinalAssessmentSectionResult(
        section: 'writing',
        status: FinalAssessmentSectionStatus.notMet,
        averageScore: 0.4,
        scoredCount: 3,
        pendingReviewCount: 0,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: buildFinalAssessmentResultViewForTest(
          results: results,
          overallPassed: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('90'), findsOneWidget);
    expect(find.textContaining('40'), findsOneWidget);

    final l10n = AppLocalizations.of(
      tester.element(find.byType(Scaffold)),
    )!;
    expect(find.text(l10n.finalAssessmentWhatsNext), findsOneWidget);
  });
}
```

`_AssessmentResultView` is currently private with no way to construct it from a test. Add a small `@visibleForTesting` factory function to `final_assessment_screen.dart` (see Step 3) rather than making the class itself public, matching the principle of keeping the class's real construction path (via `_FinalAssessmentBodyState`) as the only production entry point.

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/features/final_assessment/presentation/final_assessment_result_test.dart`
Expected: FAIL — `buildFinalAssessmentResultViewForTest` doesn't exist yet, and even once it does, no percentage/next-step text is rendered by the current `_AssessmentResultView`.

- [ ] **Step 4: Add score percentages and a next-step link to `_AssessmentResultView`**

In `lib/features/final_assessment/presentation/final_assessment_screen.dart`, add near the top of the file (after the imports, before `_FlatItem`):

```dart
/// Test-only construction path for [_AssessmentResultView] — the class
/// itself stays private since its only real entry point is
/// [_FinalAssessmentBodyState]; this just gives widget tests a way to pump
/// the result view directly without driving a full attempt through.
@visibleForTesting
Widget buildFinalAssessmentResultViewForTest({
  required List<FinalAssessmentSectionResult> results,
  required bool overallPassed,
}) {
  return _AssessmentResultView(results: results, overallPassed: overallPassed);
}
```

Add `import 'package:flutter/foundation.dart' show visibleForTesting;` to the top imports.

Replace the `for (final result in results) Card(...)` block inside `_AssessmentResultView.build` with:

```dart
              for (final result in results)
                Card(
                  child: ListTile(
                    title: Text(sectionLabel(l10n, result.section)),
                    subtitle: result.averageScore != null
                        ? Text(
                            l10n.finalAssessmentSectionScore(
                              (result.averageScore! * 100).round(),
                            ),
                          )
                        : null,
                    trailing: Text(switch (result.status) {
                      FinalAssessmentSectionStatus.passed =>
                        l10n.finalAssessmentSkillPassed,
                      FinalAssessmentSectionStatus.notMet =>
                        l10n.finalAssessmentSkillNotMet,
                      FinalAssessmentSectionStatus.pendingReview =>
                        l10n.finalAssessmentSkillPendingReview,
                    }),
                  ),
                ),
```

Replace the closing `OutlinedButton` block with a version that adds a "keep practicing" link back to Learn when not passed:

```dart
              const SizedBox(height: 16),
              if (!overallPassed)
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/learn/a1');
                  },
                  child: Text(l10n.finalAssessmentWhatsNext),
                ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.finalAssessmentDone),
              ),
```

Add `import 'package:go_router/go_router.dart';` to the top imports (needed for `context.go`).

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/features/final_assessment/presentation/final_assessment_result_test.dart`
Expected: PASS.

- [ ] **Step 6: Run the full suite, static checks, and commit**

Run: `flutter test && dart format --set-exit-if-changed . && flutter analyze`
Expected: all pass.

```bash
git add lib/features/final_assessment/presentation/final_assessment_screen.dart test/features/final_assessment/presentation/final_assessment_result_test.dart lib/l10n/app_en.arb lib/l10n/app_ar.arb lib/core/l10n/generated
git commit -m "$(cat <<'EOF'
Show per-section scores and a next-step link on the Final Assessment result

The result screen previously showed only pass/not-met text labels even
though averageScore was already computed and stored. Now renders it as
a percentage, and links to Learn when the overall result isn't a pass
yet, matching the placement test's already-good result pattern.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**Spec coverage:**
- Shared 4-state status indicator → Task 1.
- Home dashboard (streak/continue/progress/due) → Task 2.
- Level screen per-level progress → Task 3.
- Journey spine with milestones + "you are here" → Task 4 (with the documented Block→mission-lesson correction).
- Per-lesson status on unit overview → Task 5.
- In-lesson progress bar + richer lesson-complete screen → Task 6.
- Review confidence row feedback/forward motion → Task 7.
- Vocabulary row status badges → Task 8.
- Review nav-tab due badge → Task 9.
- Tests-home state-aware cards → Task 10.
- Final Assessment result scores + next-step link → Task 11.
- DESIGN_SYSTEM.md correction/update → Task 1, Step 7.
- Explicit non-goals from the spec (no new gamification mechanics, no raw-error-text fixes, no typography-system fix, no Settings changes) are respected — no task touches any of them.

**Placeholder scan:** no "TBD"/"add appropriate error handling"-style steps remain; every code step above is complete, runnable code. The one open item worth flagging explicitly rather than silently deciding: Task 6's exact `_answerCurrentActivity` test helper is deliberately marked "adjust to match the real `lesson_player_e2e_test.dart` helper" rather than asserted as final, since that existing file wasn't fully read during planning — this is a real, bounded piece of investigation for whoever executes that task, not a vague instruction (the step says exactly what to read and reconcile against).

**Type consistency:** `ProgressState`/`StatusIndicator` (Task 1) are referenced with the same constructor shape (`StatusIndicator(state: ..., size: ...)`) in Tasks 4, 5, and 8. `dueVocabularyCountProvider` (Task 2) is referenced identically in Tasks 2's own Home usage and Task 9. `lessonProgressForUnit` (Task 5) matches its interface and implementation signatures exactly. `ActivityCorrectness` values (`correct`/`incorrect`/`notAutoGraded`) are used consistently in Task 6 against the existing enum in `activity_submission.dart`, not invented.

**Scope check:** 11 tasks, each independently testable and committable, matches the spec's scope without decomposition into separate specs — all 11 serve one cohesive redesign the user asked for as a whole.
