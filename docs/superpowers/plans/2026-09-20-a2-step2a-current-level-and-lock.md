# A2 Step 2a — Current Level and the Lock Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A learner can see A2 in the app, browse what it covers, and switch to it once it's open — while A2's content is present but its lessons stay closed until the level is released.

**Architecture:** The level a learner is working in lives with their progress: `course_enrolments` gains `levelId`, `lastSelectedAt` and `unlockedAt` (schema v5), so "current level" is the enrolment selected most recently and "unlocked" is a timestamp set by finishing A1, by a placement result, or by the learner's own choice. The catalogue gains a third availability state, `preview` — content exists and loads, lessons don't open — which a `--dart-define` flag lifts to `available` in development builds. The Learn tab grows a level strip that switches levels, a lock sheet for a level that isn't open yet, and a read-only rendering of a level that isn't released.

**Not in this plan:** Home, Tests, Review, the Vocabulary/Grammar lists and the "A1" wording sweep (step 2b); the placement test across levels (step 2c); any rewriting of A2's lesson content (steps 3–5). A2's imported bundle is the reference package as authored — thin, templated and with legacy marking — which is exactly why its lessons stay closed here.

**Tech Stack:** Flutter, Riverpod 3 (`riverpod_annotation` codegen), Drift, `flutter_test`, ARB l10n (`flutter gen-l10n`).

**Spec:** [docs/superpowers/specs/2026-09-19-a2-level-design.md](../specs/2026-09-19-a2-level-design.md) — this plan implements Design 3's "Current level and lock" and the Learn half of "Tabs", plus the import from step 3's workflow, brought forward (see Deviations).

## Deviations from the spec, and why

Three, all recorded here so a reviewer judges them against this section rather than the spec's letter:

1. **The A2 import moves from step 3 into this plan (Task 5).** The spec ordered "multiple levels" before "import", but a locked *preview* with no content can only say "coming soon" — which is what the app already does. Importing first makes the switcher, the preview and the lock testable against real content. Only the file copy moves; the content rewriting (A1 references, merged grammar records, per-unit authoring) stays in steps 3–5.
2. **`course_enrolments` gains three columns, not the spec's two.** Enrolments key on the bundle's `courseId` (`"EN-A1-V2"`), and the current level must resolve *before* any bundle is loaded — the router gate depends on it. A nullable `levelId` column makes that mapping direct instead of parsing a course id string.
3. **Levels load lazily, not all at startup.** The spec says every released level loads at startup; `courseContentProvider` is keep-alive and loads on first watch, so watching the current level achieves the same thing without paying A2's parse cost for a learner who never leaves A1. The router gate stays on the base level (A1), so a broken A2 can never gate the app — which is the property the spec actually asked for.

## Global Constraints

- Every user-facing string is added to **both** `lib/l10n/app_en.arb` (with an `@key` description) and `lib/l10n/app_ar.arb`, the Arabic written as natural Arabic — never a word-for-word translation. Run `flutter gen-l10n` after editing ARB files; the generated files under `lib/core/l10n/generated/` are committed.
- No hard-coded left/right: `EdgeInsetsDirectional`, `AlignmentDirectional`, start/end. English content text is `textDirection: TextDirection.ltr`, Arabic content `TextDirection.rtl`. A CEFR code (`A1`, `A2`) inside Arabic copy goes through a placeholder, never string concatenation.
- Every interactive element carries a screen-reader label in both languages (docs/UX_PRINCIPLES.md's non-negotiable). A locked control says it is locked, not just that it exists.
- Progression is a recommendation, never a hard lock, **except** the release gate: a level the app has not released yet cannot be opened at all, and a level that is merely un-started is always openable via "Open anyway".
- Nothing here may need the network. No new dependencies.
- After editing any `@riverpod`/`@Riverpod` function or Drift table, run `dart run build_runner build --delete-conflicting-outputs`; generated `*.g.dart` files are committed, including any other provider's hash that shifts as a result.
- `lib/content/` never imports from `lib/features/`.
- Commands: tests `flutter test <path>`; lint `dart format .` then `flutter analyze`.
- Commit messages: short imperative summary with a type prefix (`feat:`, `fix:`, `content:`, `docs:`, `test:`, `chore:`), ending with `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>` after a blank line.
- Work on branch `feature/a2-current-level` (Task 1 creates it).

## File map

| File | Status | Responsibility |
|---|---|---|
| `lib/data/local/tables/learner_tables.dart` | modify | `CourseEnrolments` gains `levelId`, `lastSelectedAt`, `unlockedAt` |
| `lib/data/local/database.dart` | modify | schema v5 + migration |
| `lib/features/progress/domain/repositories/learner_repository.dart` | modify | enrolment reads, select, unlock |
| `lib/features/progress/data/drift_learner_repository.dart` | modify | their Drift implementations |
| `assets/content/en/A2/a2-course-bundle.json` | new | the imported A2 bundle |
| `pubspec.yaml` | modify | declare the new asset |
| `lib/content/catalog/level_catalog.dart` | modify | `LevelAvailability.preview`, A2's entry, `applyPreviewOverrides` |
| `lib/content/providers/course_content_providers.dart` | modify | load `preview` levels; apply the dev flag; `kBaseLevelId` |
| `lib/features/progress/domain/level_access.dart` | new | current level + open/locked rules (pure) |
| `lib/features/progress/providers/level_providers.dart` | new | `currentLevelIdProvider`, `levelAccessProvider`, `setCurrentLevel`, `unlockLevel` |
| `lib/features/progress/providers/ensure_a1_enrollment_provider.dart` | replace | per-level enrolment |
| `lib/features/learning_path/presentation/widgets/level_strip.dart` | new | the A1 \| A2 strip |
| `lib/features/learning_path/presentation/widgets/level_lock_sheet.dart` | new | the soft-lock sheet |
| `lib/features/learning_path/presentation/course_screen.dart` | modify | follow the current level; strip; preview rendering |
| `lib/core/router/app_router.dart`, `content_load_refresh_listenable.dart` | modify | gate on the base level by name |
| `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb` | modify | the new strings |
| 8 docs | modify | definition of done (Task 11) |

---

### Task 1: Branch and commit the plan

**Files:**
- Commit: `docs/superpowers/plans/2026-09-20-a2-step2a-current-level-and-lock.md`

- [ ] **Step 1: Create the branch**

```bash
git checkout -b feature/a2-current-level
```

- [ ] **Step 2: Commit the plan**

```bash
git add docs/superpowers/plans/2026-09-20-a2-step2a-current-level-and-lock.md
git commit -m "docs: plan A2's current level and level lock

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: The enrolment row remembers its level, when it was chosen, and when it opened

**Files:**
- Modify: `lib/data/local/tables/learner_tables.dart`, `lib/data/local/database.dart` (+ regenerated `database.g.dart`)
- Test: `test/data/local/database_test.dart`

**Interfaces:**
- Produces: `CourseEnrolments.levelId` (`TextColumn`, nullable), `.lastSelectedAt` (`DateTimeColumn`, nullable), `.unlockedAt` (`DateTimeColumn`, nullable); `AppDatabase.schemaVersion == 5`.

- [ ] **Step 1: Write the failing tests**

In `test/data/local/database_test.dart`, change the existing version assertion:

```dart
  test('schema version is 5', () {
    expect(database.schemaVersion, 5);
  });
```

and add a migration test beside the existing ones (it follows their shape: hand-write the prior version's DDL, set `user_version`, then open `AppDatabase` so `onUpgrade` really runs):

```dart
  test('a v4 install upgrades to 5: an existing enrolment keeps its data and '
      'gains the three nullable level columns', () async {
    final raw = sqlite3.sqlite3.openInMemory();
    raw.execute('''
          CREATE TABLE learners (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            uuid TEXT NOT NULL UNIQUE,
            name TEXT NULL,
            native_language TEXT NOT NULL DEFAULT 'ar',
            target_language TEXT NOT NULL DEFAULT 'en',
            created_at INTEGER NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1
          )
        ''');
    raw.execute('''
          CREATE TABLE course_enrolments (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            uuid TEXT NOT NULL UNIQUE,
            learner_id INTEGER NOT NULL REFERENCES learners (id),
            course_id TEXT NOT NULL,
            content_version TEXT NOT NULL,
            enrolled_at INTEGER NOT NULL,
            status TEXT NOT NULL
          )
        ''');
    raw.execute(
      "INSERT INTO learners (uuid, created_at) VALUES ('learner-1', 0)",
    );
    raw.execute(
      "INSERT INTO course_enrolments "
      "(uuid, learner_id, course_id, content_version, enrolled_at, status) "
      "VALUES ('e-1', 1, 'EN-A1-V2', 'A1-COMPLETE-2026.09.02', 0, 'active')",
    );
    raw.execute('PRAGMA user_version = 4');

    final upgraded = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(upgraded.close);

    final row = await upgraded.select(upgraded.courseEnrolments).getSingle();
    expect(row.courseId, 'EN-A1-V2');
    expect(row.levelId, isNull);
    expect(row.lastSelectedAt, isNull);
    expect(row.unlockedAt, isNull);

    // The new columns are writable, not just present.
    await (upgraded.update(
      upgraded.courseEnrolments,
    )..where((t) => t.id.equals(row.id))).write(
      CourseEnrolmentsCompanion(
        levelId: const Value('a1'),
        lastSelectedAt: Value(DateTime.utc(2026, 9, 20)),
        unlockedAt: Value(DateTime.utc(2026, 9, 20)),
      ),
    );
    final updated = await upgraded.select(upgraded.courseEnrolments).getSingle();
    expect(updated.levelId, 'a1');
    expect(updated.lastSelectedAt, DateTime.utc(2026, 9, 20));
    expect(updated.unlockedAt, DateTime.utc(2026, 9, 20));
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/data/local/database_test.dart`
Expected: FAIL — `schemaVersion` is 4, and `levelId`/`lastSelectedAt`/`unlockedAt` don't exist.

- [ ] **Step 3: Implement**

In `lib/data/local/tables/learner_tables.dart`, add to `CourseEnrolments` after `status`:

```dart
  /// The catalogue level this enrolment is for (`"a1"`, `"a2"`) — the same
  /// key `kLevelCatalog` and `courseContentProvider` use. Null on rows
  /// written before schema v5, which are read as the base level; see
  /// `LearnerRepository.ensureEnrolled`, which backfills them.
  TextColumn get levelId => text().nullable()();

  /// When the learner last made this level the one they're working in. The
  /// enrolment with the most recent value is the current level; null means
  /// they have never chosen it explicitly.
  DateTimeColumn get lastSelectedAt => dateTime().nullable()();

  /// When this level opened for the learner — by finishing the level it
  /// builds on, by a placement result inside it, or by their own "open
  /// anyway". Null while it is still locked. A level with no prerequisite
  /// needs no unlock. See `lib/features/progress/domain/level_access.dart`.
  DateTimeColumn get unlockedAt => dateTime().nullable()();
```

In `lib/data/local/database.dart`, set `int get schemaVersion => 5;` and add to `onUpgrade`, after the `from < 4` branch:

```dart
        if (from < 5) {
          await migrator.addColumn(courseEnrolments, courseEnrolments.levelId);
          await migrator.addColumn(
            courseEnrolments,
            courseEnrolments.lastSelectedAt,
          );
          await migrator.addColumn(
            courseEnrolments,
            courseEnrolments.unlockedAt,
          );
        }
```

Regenerate: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/data/local/`
Expected: PASS, including the existing `resetProgressForLearner` tests (a reset still deletes enrolments, so it still returns the learner to the base level with every other level locked).

- [ ] **Step 5: Commit**

```bash
git add lib/data/local/ test/data/local/
git commit -m "feat: remember which level an enrolment is for, when it was chosen and when it opened

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: The learner repository can read enrolments, select a level and unlock one

**Files:**
- Modify: `lib/features/progress/domain/repositories/learner_repository.dart`, `lib/features/progress/data/drift_learner_repository.dart`
- Test: `test/features/progress/data/drift_learner_repository_test.dart` (new)

**Interfaces:**
- Consumes: the three columns from Task 2.
- Produces on `LearnerRepository`: `Future<void> ensureEnrolled({required int learnerId, required String levelId, required String courseId, required String contentVersion})` (the existing method gains `levelId`); `Future<List<CourseEnrolment>> enrolments({required int learnerId})`; `Future<CourseEnrolment?> enrolmentForLevel({required int learnerId, required String levelId})`; `Future<void> markLevelSelected({required int learnerId, required String levelId, DateTime? at})`; `Future<void> markLevelUnlocked({required int learnerId, required String levelId, DateTime? at})`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/progress/data/drift_learner_repository_test.dart`:

```dart
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/data/drift_learner_repository.dart';

void main() {
  late AppDatabase db;
  late DriftLearnerRepository repository;
  late int learnerId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftLearnerRepository(db);
    final learner = await repository.getOrCreateLearner();
    learnerId = learner.id;
  });

  tearDown(() => db.close());

  test('enrolling records the level, and enrolling again changes nothing', () async {
    await repository.ensureEnrolled(
      learnerId: learnerId,
      levelId: 'a1',
      courseId: 'EN-A1-V2',
      contentVersion: 'v1',
    );
    await repository.ensureEnrolled(
      learnerId: learnerId,
      levelId: 'a1',
      courseId: 'EN-A1-V2',
      contentVersion: 'v2',
    );

    final rows = await repository.enrolments(learnerId: learnerId);
    expect(rows, hasLength(1));
    expect(rows.single.levelId, 'a1');
    expect(rows.single.contentVersion, 'v1');
  });

  test('a row written before levelId existed is backfilled, not duplicated', () async {
    await db
        .into(db.courseEnrolments)
        .insert(
          CourseEnrolmentsCompanion.insert(
            uuid: 'legacy',
            learnerId: learnerId,
            courseId: 'EN-A1-V2',
            contentVersion: 'v1',
            enrolledAt: DateTime.utc(2026, 9, 1),
            status: 'active',
          ),
        );

    await repository.ensureEnrolled(
      learnerId: learnerId,
      levelId: 'a1',
      courseId: 'EN-A1-V2',
      contentVersion: 'v1',
    );

    final rows = await repository.enrolments(learnerId: learnerId);
    expect(rows, hasLength(1));
    expect(rows.single.uuid, 'legacy');
    expect(rows.single.levelId, 'a1');
  });

  test('selecting a level stamps it, and selecting another moves the stamp', () async {
    await repository.ensureEnrolled(
      learnerId: learnerId,
      levelId: 'a1',
      courseId: 'EN-A1-V2',
      contentVersion: 'v1',
    );
    await repository.ensureEnrolled(
      learnerId: learnerId,
      levelId: 'a2',
      courseId: 'EN-A2-V1',
      contentVersion: 'v1',
    );

    await repository.markLevelSelected(
      learnerId: learnerId,
      levelId: 'a1',
      at: DateTime.utc(2026, 9, 19),
    );
    await repository.markLevelSelected(
      learnerId: learnerId,
      levelId: 'a2',
      at: DateTime.utc(2026, 9, 20),
    );

    final a1 = await repository.enrolmentForLevel(
      learnerId: learnerId,
      levelId: 'a1',
    );
    final a2 = await repository.enrolmentForLevel(
      learnerId: learnerId,
      levelId: 'a2',
    );
    expect(a1!.lastSelectedAt, DateTime.utc(2026, 9, 19));
    expect(a2!.lastSelectedAt, DateTime.utc(2026, 9, 20));
  });

  test('unlocking is idempotent — the first time is the time that sticks', () async {
    await repository.ensureEnrolled(
      learnerId: learnerId,
      levelId: 'a2',
      courseId: 'EN-A2-V1',
      contentVersion: 'v1',
    );

    await repository.markLevelUnlocked(
      learnerId: learnerId,
      levelId: 'a2',
      at: DateTime.utc(2026, 9, 20),
    );
    await repository.markLevelUnlocked(
      learnerId: learnerId,
      levelId: 'a2',
      at: DateTime.utc(2026, 9, 21),
    );

    final row = await repository.enrolmentForLevel(
      learnerId: learnerId,
      levelId: 'a2',
    );
    expect(row!.unlockedAt, DateTime.utc(2026, 9, 20));
  });

  test('selecting or unlocking a level the learner never started does nothing', () async {
    await repository.markLevelSelected(learnerId: learnerId, levelId: 'b1');
    await repository.markLevelUnlocked(learnerId: learnerId, levelId: 'b1');

    expect(await repository.enrolments(learnerId: learnerId), isEmpty);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/progress/data/drift_learner_repository_test.dart`
Expected: FAIL — `ensureEnrolled` has no `levelId`, and the other four methods don't exist.

- [ ] **Step 3: Implement the interface**

In `lib/features/progress/domain/repositories/learner_repository.dart`, replace `ensureEnrolled`'s declaration and add the four new methods:

```dart
  /// Records that [learnerId] has started the catalogue level [levelId]
  /// (bundle [courseId]) at [contentVersion]. Idempotent: a level the
  /// learner is already enrolled in keeps its original row — except that a
  /// row written before levels were tracked (null `levelId`) is backfilled
  /// with [levelId] rather than duplicated.
  Future<void> ensureEnrolled({
    required int learnerId,
    required String levelId,
    required String courseId,
    required String contentVersion,
  });

  /// Every level [learnerId] has started, in no particular order — the
  /// caller decides what "current" means (see
  /// `lib/features/progress/domain/level_access.dart`).
  Future<List<CourseEnrolment>> enrolments({required int learnerId});

  /// [learnerId]'s enrolment in [levelId], or null if they never started it.
  Future<CourseEnrolment?> enrolmentForLevel({
    required int learnerId,
    required String levelId,
  });

  /// Marks [levelId] as the level [learnerId] is working in now. A level
  /// they have never started is ignored — enrolment comes first.
  Future<void> markLevelSelected({
    required int learnerId,
    required String levelId,
    DateTime? at,
  });

  /// Records that [levelId] is open for [learnerId]. Idempotent: an
  /// already-open level keeps the time it first opened, so "when did this
  /// learner reach A2" stays answerable.
  Future<void> markLevelUnlocked({
    required int learnerId,
    required String levelId,
    DateTime? at,
  });
```

- [ ] **Step 4: Implement the Drift repository**

In `lib/features/progress/data/drift_learner_repository.dart`, replace `ensureEnrolled` and add the rest:

```dart
  @override
  Future<void> ensureEnrolled({
    required int learnerId,
    required String levelId,
    required String courseId,
    required String contentVersion,
  }) async {
    final existing =
        await (_db.select(_db.courseEnrolments)..where(
              (t) =>
                  t.learnerId.equals(learnerId) &
                  (t.levelId.equals(levelId) | t.courseId.equals(courseId)),
            ))
            .getSingleOrNull();
    if (existing != null) {
      // A row written before schema v5 knows its course but not its level.
      if (existing.levelId == null) {
        await (_db.update(
          _db.courseEnrolments,
        )..where((t) => t.id.equals(existing.id))).write(
          CourseEnrolmentsCompanion(levelId: Value(levelId)),
        );
      }
      return;
    }

    await _db
        .into(_db.courseEnrolments)
        .insert(
          CourseEnrolmentsCompanion.insert(
            uuid: _uuid.v4(),
            learnerId: learnerId,
            courseId: courseId,
            contentVersion: contentVersion,
            enrolledAt: DateTime.now(),
            status: 'active',
            levelId: Value(levelId),
          ),
        );
  }

  @override
  Future<List<CourseEnrolment>> enrolments({required int learnerId}) {
    return (_db.select(
      _db.courseEnrolments,
    )..where((t) => t.learnerId.equals(learnerId))).get();
  }

  @override
  Future<CourseEnrolment?> enrolmentForLevel({
    required int learnerId,
    required String levelId,
  }) {
    return (_db.select(_db.courseEnrolments)..where(
          (t) => t.learnerId.equals(learnerId) & t.levelId.equals(levelId),
        ))
        .getSingleOrNull();
  }

  @override
  Future<void> markLevelSelected({
    required int learnerId,
    required String levelId,
    DateTime? at,
  }) async {
    await (_db.update(_db.courseEnrolments)..where(
          (t) => t.learnerId.equals(learnerId) & t.levelId.equals(levelId),
        ))
        .write(
          CourseEnrolmentsCompanion(
            lastSelectedAt: Value(at ?? DateTime.now()),
          ),
        );
  }

  @override
  Future<void> markLevelUnlocked({
    required int learnerId,
    required String levelId,
    DateTime? at,
  }) async {
    final existing = await enrolmentForLevel(
      learnerId: learnerId,
      levelId: levelId,
    );
    if (existing == null || existing.unlockedAt != null) return;
    await (_db.update(
      _db.courseEnrolments,
    )..where((t) => t.id.equals(existing.id))).write(
      CourseEnrolmentsCompanion(unlockedAt: Value(at ?? DateTime.now())),
    );
  }
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/features/progress/`
Expected: PASS. (`ensureA1EnrollmentProvider` still calls the old signature — Task 6 replaces it; if the analyzer breaks here, add `levelId: 'a1'` to that one call so the tree compiles, and let Task 6 replace the provider properly.)

- [ ] **Step 6: Commit**

```bash
git add lib/features/progress/ test/features/progress/
git commit -m "feat: read enrolments per level, select one and unlock one

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: A level can be a preview — content that loads, lessons that don't open

**Files:**
- Modify: `lib/content/catalog/level_catalog.dart`, `lib/content/providers/course_content_providers.dart` (+ regenerated `.g.dart`)
- Test: `test/content/catalog/level_catalog_test.dart`, `test/content/providers/course_content_providers_test.dart`

**Interfaces:**
- Produces: `LevelAvailability.preview`; `const kBaseLevelId = 'a1';`; `List<LevelCatalogEntry> applyPreviewOverrides(List<LevelCatalogEntry> catalog, Set<String> openedLevelIds)`; `courseContentProvider` loads any entry with a `bundleAssetPath` (available **or** preview).

- [ ] **Step 1: Write the failing tests**

Add to `test/content/catalog/level_catalog_test.dart`:

```dart
  test('a preview level is opened by the development flag, and everything '
      'else is left alone', () {
    const catalog = [
      LevelCatalogEntry(
        levelId: 'a1',
        cefrCode: 'A1',
        availability: LevelAvailability.available,
        bundleAssetPath: 'a1.json',
      ),
      LevelCatalogEntry(
        levelId: 'a2',
        cefrCode: 'A2',
        availability: LevelAvailability.preview,
        bundleAssetPath: 'a2.json',
        prerequisiteLevelId: 'a1',
      ),
      LevelCatalogEntry(
        levelId: 'b1',
        cefrCode: 'B1',
        availability: LevelAvailability.comingSoon,
      ),
    ];

    final opened = applyPreviewOverrides(catalog, {'a2'});
    expect(
      opened.map((e) => e.availability),
      [
        LevelAvailability.available,
        LevelAvailability.available,
        LevelAvailability.comingSoon,
      ],
    );
    // Everything else about the entry survives the override.
    expect(opened[1].bundleAssetPath, 'a2.json');
    expect(opened[1].prerequisiteLevelId, 'a1');

    // A level with no bundle can't be opened by the flag.
    expect(
      applyPreviewOverrides(catalog, {'b1'})[2].availability,
      LevelAvailability.comingSoon,
    );
    expect(applyPreviewOverrides(catalog, const {}), same(catalog));
  });
```

and update the existing "only A1 is available" test so it expects A2 as `preview` with a bundle path, and B1–C2 as `comingSoon` with none.

Add to `test/content/providers/course_content_providers_test.dart` (its `_catalog` gains a preview entry — give `a2` `availability: LevelAvailability.preview` there):

```dart
  test("a preview level's content loads — its lessons are closed by the app, "
      'not by the loader', () async {
    final container = _container(_loader());
    final a2 = await container.read(courseContentProvider('a2').future);
    expect(a2.bundle.course.id, 'EN-A2-TEST');
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/content/`
Expected: FAIL — `LevelAvailability.preview` and `applyPreviewOverrides` don't exist.

- [ ] **Step 3: Implement**

In `lib/content/catalog/level_catalog.dart`:

```dart
/// Whether a CEFR level has real content in this build.
///
/// [preview] sits between the other two: the level's content exists and
/// loads, so a learner can see what it covers, but its lessons don't open
/// until it is released (and a development build can open it — see
/// `applyPreviewOverrides`). [comingSoon] has no content at all.
enum LevelAvailability { available, preview, comingSoon }

/// The level every learner starts in, and the one the app cannot run
/// without — the router's content gate waits for this one alone, so a
/// later level failing to load never blocks the app.
const kBaseLevelId = 'a1';
```

A2's entry becomes:

```dart
  LevelCatalogEntry(
    levelId: 'a2',
    cefrCode: 'A2',
    availability: LevelAvailability.preview,
    bundleAssetPath: 'assets/content/en/A2/a2-course-bundle.json',
    prerequisiteLevelId: 'a1',
  ),
```

and at the end of the file:

```dart
/// [catalog] with every level in [openedLevelIds] promoted from
/// [LevelAvailability.preview] to [LevelAvailability.available] — how a
/// development build opens a level that isn't released yet. A level with no
/// bundle can't be promoted; a level that is already available is
/// unaffected. Returns [catalog] itself when there is nothing to promote.
List<LevelCatalogEntry> applyPreviewOverrides(
  List<LevelCatalogEntry> catalog,
  Set<String> openedLevelIds,
) {
  if (openedLevelIds.isEmpty) return catalog;
  return [
    for (final entry in catalog)
      if (entry.availability == LevelAvailability.preview &&
          entry.bundleAssetPath != null &&
          openedLevelIds.contains(entry.levelId))
        LevelCatalogEntry(
          levelId: entry.levelId,
          cefrCode: entry.cefrCode,
          availability: LevelAvailability.available,
          bundleAssetPath: entry.bundleAssetPath,
          prerequisiteLevelId: entry.prerequisiteLevelId,
        )
      else
        entry,
  ];
}
```

In `lib/content/providers/course_content_providers.dart`, apply the flag in the catalogue provider and load previews:

```dart
/// Levels this build opens although they aren't released — set at build
/// time with `--dart-define=MOHINGO_PREVIEW_LEVELS=a2` so the product owner
/// can walk through a level's real lessons before it ships. Empty in a
/// release build.
const _previewLevelIds = String.fromEnvironment('MOHINGO_PREVIEW_LEVELS');

/// The level catalogue ([kLevelCatalog]), with any development-opened
/// preview levels promoted; overridden in tests.
@Riverpod(keepAlive: true)
List<LevelCatalogEntry> levelCatalog(Ref ref) => applyPreviewOverrides(
  kLevelCatalog,
  _previewLevelIds
      .split(',')
      .map((id) => id.trim().toLowerCase())
      .where((id) => id.isNotEmpty)
      .toSet(),
);
```

and change `courseContent`'s guard so a preview level loads (its lessons are closed by the Learn tab, not by the loader):

```dart
  final entry = levelCatalogEntryIn(ref.watch(levelCatalogProvider), levelId);
  if (entry == null || entry.bundleAssetPath == null) {
    throw StateError('Level "$levelId" has no content bundle to load');
  }
```

Regenerate: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/content/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/content/ test/content/
git commit -m "feat: let a level's content load while its lessons stay closed

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Import the A2 bundle as a shipped asset

Brought forward from the spec's step 3 — see Deviations. This is the reference package as authored; its lessons are thin and its marking is legacy, which is why the level stays a preview.

**Files:**
- Create: `assets/content/en/A2/a2-course-bundle.json`
- Modify: `pubspec.yaml`
- Test: `test/content/a2_bundle_loads_test.dart` (new)

- [ ] **Step 1: Write the failing test**

Create `test/content/a2_bundle_loads_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';

/// The shipped A2 bundle must parse and index with the same reader A1 uses —
/// the acceptance test the curriculum package's own handover asks for. Its
/// lessons are not rewritten yet (see the A2 design doc's steps 4-5); this
/// only proves the app can load what was imported.
void main() {
  test('the shipped A2 bundle parses, indexes and resolves every reference', () {
    final json = File(
      'assets/content/en/A2/a2-course-bundle.json',
    ).readAsStringSync();

    final index = CourseContentIndex.build(CourseBundleParser.parse(json));

    expect(index.bundle.course.id, 'EN-A2-V1');
    expect(index.unitsById, hasLength(12));
    expect(index.lessonsById, hasLength(84));
    expect(index.bundle.finalMission.id, 'A2-FINAL-MISSION');
    expect(index.bundle.finalAssessment.id, 'A2-FINAL-ASSESSMENT');
    expect(index.unitsById['A2-U1']!.lessons, hasLength(7));
  });

  test('every A2 unit counts towards its level', () {
    final json = File(
      'assets/content/en/A2/a2-course-bundle.json',
    ).readAsStringSync();
    final bundle = CourseBundleParser.parse(json);

    expect(bundle.units.every((u) => u.countsTowardLevelMastery), isTrue);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/content/a2_bundle_loads_test.dart`
Expected: FAIL — the asset doesn't exist.

- [ ] **Step 3: Import the bundle**

```bash
mkdir -p assets/content/en/A2
cp reference/a2-modular-course/dist/a2-course-bundle.json assets/content/en/A2/a2-course-bundle.json
```

Then set the shipped file's own content version, so the asset and the reference package are never confused. Exact string replacement in the copied asset — the old value occurs exactly once (line 3), and nothing else in the file changes:

`"contentVersion": "A2-COMPLETE-A1-CONTRACT-2026.09.19"` → `"contentVersion": "A2-IMPORT-2026.09.20"`

In `pubspec.yaml`, add under `assets:`, after the A1 line:

```yaml
    - assets/content/en/A2/a2-course-bundle.json
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/content/`
Expected: PASS. If the parser or the index rejects the bundle, **stop and report it** — that is a real content finding, not something to work around by loosening the test.

- [ ] **Step 5: Commit**

```bash
git add assets/content/en/A2/ pubspec.yaml test/content/a2_bundle_loads_test.dart
git commit -m "content: import the A2 bundle as a shipped, not-yet-open level

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Which level the learner is in, and whether it is open

**Files:**
- Create: `lib/features/progress/domain/level_access.dart`, `lib/features/progress/providers/level_providers.dart` (+ generated `.g.dart`)
- Delete: `lib/features/progress/providers/ensure_a1_enrollment_provider.dart` (+ its `.g.dart`)
- Modify: `lib/app.dart`
- Test: `test/features/progress/domain/level_access_test.dart` (new), `test/features/progress/providers/level_providers_test.dart` (new)

**Interfaces:**
- Consumes: Task 3's repository methods; Task 4's `LevelAvailability.preview`, `kBaseLevelId`, `levelCatalogProvider`.
- Produces:
  - `enum LevelAccess { open, lockedNeedsPrerequisite, notReleased, noContent }`
  - `String currentLevelIdFor({required List<CourseEnrolment> enrolments, required List<LevelCatalogEntry> catalog})`
  - `bool levelComplete({required List<Unit> units, required Set<String> masteredUnitIds})`
  - `LevelAccess levelAccessFor({required LevelCatalogEntry entry, required CourseEnrolment? enrolment, required bool prerequisiteComplete})`
  - providers `currentLevelIdProvider` (`FutureProvider<String>`), `levelAccessProvider` (family on `levelId`), `ensureLevelEnrolmentProvider` (family), and a `LevelSelectionController` with `select(levelId)` / `unlock(levelId)`.

- [ ] **Step 1: Write the failing domain tests**

Create `test/features/progress/domain/level_access_test.dart`:

```dart
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/catalog/level_catalog.dart';
import 'package:mohingo/content/models/curriculum_structure.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/progress/domain/level_access.dart';

CourseEnrolment _enrolment({
  required String? levelId,
  DateTime? lastSelectedAt,
  DateTime? unlockedAt,
}) => CourseEnrolment(
  id: 1,
  uuid: 'e-$levelId',
  learnerId: 1,
  courseId: 'EN-${levelId?.toUpperCase()}',
  contentVersion: 'v1',
  enrolledAt: DateTime.utc(2026, 9, 1),
  status: 'active',
  levelId: levelId,
  lastSelectedAt: lastSelectedAt,
  unlockedAt: unlockedAt,
);

const _catalog = [
  LevelCatalogEntry(
    levelId: 'a1',
    cefrCode: 'A1',
    availability: LevelAvailability.available,
    bundleAssetPath: 'a1.json',
  ),
  LevelCatalogEntry(
    levelId: 'a2',
    cefrCode: 'A2',
    availability: LevelAvailability.available,
    bundleAssetPath: 'a2.json',
    prerequisiteLevelId: 'a1',
  ),
  LevelCatalogEntry(
    levelId: 'b1',
    cefrCode: 'B1',
    availability: LevelAvailability.comingSoon,
  ),
];

Unit _unit(String id, {bool counts = true}) => Unit(
  id: id,
  title: id,
  titleAr: id,
  levelRole: counts ? 'core' : 'prerequisite',
  estimatedMinutes: const [10, 20],
  countsTowardLevelMastery: counts,
  lessons: const [],
  mastery: const UnitMastery(
    requiredObjectives: [],
    requiredSkillGroups: [],
    minimumObjectiveScore: null,
    raw: {},
  ),
);

void main() {
  group('currentLevelIdFor', () {
    test('a learner who has chosen nothing is in the base level', () {
      expect(
        currentLevelIdFor(enrolments: const [], catalog: _catalog),
        'a1',
      );
    });

    test('the most recently selected level wins', () {
      final current = currentLevelIdFor(
        enrolments: [
          _enrolment(levelId: 'a1', lastSelectedAt: DateTime.utc(2026, 9, 19)),
          _enrolment(levelId: 'a2', lastSelectedAt: DateTime.utc(2026, 9, 20)),
        ],
        catalog: _catalog,
      );
      expect(current, 'a2');
    });

    test('an enrolment from before levels were tracked reads as the base '
        'level', () {
      expect(
        currentLevelIdFor(
          enrolments: [_enrolment(levelId: null)],
          catalog: _catalog,
        ),
        'a1',
      );
    });

    test('a level that is no longer in the catalogue is ignored', () {
      expect(
        currentLevelIdFor(
          enrolments: [
            _enrolment(levelId: 'zz', lastSelectedAt: DateTime.utc(2026, 9, 20)),
          ],
          catalog: _catalog,
        ),
        'a1',
      );
    });
  });

  group('levelComplete', () {
    test('every unit that counts must be mastered; a starter unit does not '
        'count', () {
      final units = [_unit('A1-U0', counts: false), _unit('A1-U1')];

      expect(
        levelComplete(units: units, masteredUnitIds: {'A1-U1'}),
        isTrue,
      );
      expect(levelComplete(units: units, masteredUnitIds: const {}), isFalse);
      expect(levelComplete(units: const [], masteredUnitIds: const {}), isFalse);
    });
  });

  group('levelAccessFor', () {
    LevelCatalogEntry entry(String id) =>
        _catalog.firstWhere((e) => e.levelId == id);

    test('a level with no prerequisite is always open', () {
      expect(
        levelAccessFor(
          entry: entry('a1'),
          enrolment: null,
          prerequisiteComplete: false,
        ),
        LevelAccess.open,
      );
    });

    test('finishing the level it builds on opens it', () {
      expect(
        levelAccessFor(
          entry: entry('a2'),
          enrolment: null,
          prerequisiteComplete: true,
        ),
        LevelAccess.open,
      );
    });

    test('an unlocked enrolment opens it even when the prerequisite is '
        'unfinished', () {
      expect(
        levelAccessFor(
          entry: entry('a2'),
          enrolment: _enrolment(
            levelId: 'a2',
            unlockedAt: DateTime.utc(2026, 9, 20),
          ),
          prerequisiteComplete: false,
        ),
        LevelAccess.open,
      );
    });

    test('otherwise it is locked behind its prerequisite', () {
      expect(
        levelAccessFor(
          entry: entry('a2'),
          enrolment: _enrolment(levelId: 'a2'),
          prerequisiteComplete: false,
        ),
        LevelAccess.lockedNeedsPrerequisite,
      );
    });

    test('a level that is not released yet cannot be opened at all, however '
        'much the learner has done', () {
      const preview = LevelCatalogEntry(
        levelId: 'a2',
        cefrCode: 'A2',
        availability: LevelAvailability.preview,
        bundleAssetPath: 'a2.json',
        prerequisiteLevelId: 'a1',
      );
      expect(
        levelAccessFor(
          entry: preview,
          enrolment: _enrolment(
            levelId: 'a2',
            unlockedAt: DateTime.utc(2026, 9, 20),
          ),
          prerequisiteComplete: true,
        ),
        LevelAccess.notReleased,
      );
    });

    test('a level with no content at all is just that', () {
      expect(
        levelAccessFor(
          entry: entry('b1'),
          enrolment: null,
          prerequisiteComplete: true,
        ),
        LevelAccess.noContent,
      );
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/progress/domain/level_access_test.dart`
Expected: FAIL — `lib/features/progress/domain/level_access.dart` doesn't exist.

- [ ] **Step 3: Implement the domain**

Create `lib/features/progress/domain/level_access.dart`:

```dart
import '../../../content/catalog/level_catalog.dart';
import '../../../content/models/curriculum_structure.dart';
import '../../../data/local/database.dart';

/// Whether a learner can open a level right now, and if not, why.
enum LevelAccess {
  /// Lessons open normally.
  open,

  /// Released, but the learner hasn't reached it: they can finish the level
  /// it builds on, take the placement test, or open it anyway. A
  /// recommendation, never a wall — see docs/PRODUCT.md flow 5.
  lockedNeedsPrerequisite,

  /// The app hasn't released this level yet: its content is here to look
  /// at, its lessons don't open, and nothing the learner does changes that.
  notReleased,

  /// No content at all — the "coming later" levels.
  noContent,
}

/// The level the learner is working in: the one they selected most
/// recently, or the base level when they have never chosen one.
///
/// An enrolment written before levels were tracked has no `levelId` and
/// reads as the base level, which is the only level that existed then.
String currentLevelIdFor({
  required List<CourseEnrolment> enrolments,
  required List<LevelCatalogEntry> catalog,
}) {
  final known = {for (final entry in catalog) entry.levelId};
  CourseEnrolment? latest;
  for (final enrolment in enrolments) {
    final levelId = enrolment.levelId ?? kBaseLevelId;
    if (!known.contains(levelId)) continue;
    if (enrolment.lastSelectedAt == null) continue;
    if (latest == null ||
        enrolment.lastSelectedAt!.isAfter(latest.lastSelectedAt!)) {
      latest = enrolment;
    }
  }
  return latest?.levelId ?? kBaseLevelId;
}

/// Whether a level's own units are all mastered — every unit that counts
/// towards the level (a starter unit doesn't). A level with no units is
/// never complete.
bool levelComplete({
  required List<Unit> units,
  required Set<String> masteredUnitIds,
}) {
  final counting = units.where((u) => u.countsTowardLevelMastery).toList();
  if (counting.isEmpty) return false;
  return counting.every((u) => masteredUnitIds.contains(u.id));
}

/// Whether [entry] is open for a learner, given their [enrolment] in it and
/// whether they finished the level it builds on.
LevelAccess levelAccessFor({
  required LevelCatalogEntry entry,
  required CourseEnrolment? enrolment,
  required bool prerequisiteComplete,
}) {
  switch (entry.availability) {
    case LevelAvailability.comingSoon:
      return LevelAccess.noContent;
    case LevelAvailability.preview:
      return LevelAccess.notReleased;
    case LevelAvailability.available:
      if (entry.prerequisiteLevelId == null) return LevelAccess.open;
      if (prerequisiteComplete) return LevelAccess.open;
      if (enrolment?.unlockedAt != null) return LevelAccess.open;
      return LevelAccess.lockedNeedsPrerequisite;
  }
}
```

- [ ] **Step 4: Write the failing provider tests**

Create `test/features/progress/providers/level_providers_test.dart`. It uses a real in-memory database and the real repository, overriding only the catalogue and the content loader (the same pattern as `test/content/providers/course_content_providers_test.dart`, whose `_FakeLoader` and `minimalBundleJson` fixture you can import):

```dart
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/catalog/level_catalog.dart';
import 'package:mohingo/content/providers/bundle_asset_loader.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/progress/domain/level_access.dart';
import 'package:mohingo/features/progress/providers/level_providers.dart';

class _FakeLoader implements BundleAssetLoader {
  _FakeLoader(this.assets);
  final Map<String, String> assets;
  @override
  Future<String> load(String assetPath) async => assets[assetPath]!;
}

const _catalog = [
  LevelCatalogEntry(
    levelId: 'a1',
    cefrCode: 'A1',
    availability: LevelAvailability.available,
    bundleAssetPath: 'a1.json',
  ),
  LevelCatalogEntry(
    levelId: 'a2',
    cefrCode: 'A2',
    availability: LevelAvailability.available,
    bundleAssetPath: 'a2.json',
    prerequisiteLevelId: 'a1',
  ),
];

ProviderContainer _container(AppDatabase db) {
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      levelCatalogProvider.overrideWithValue(_catalog),
      bundleAssetLoaderProvider.overrideWithValue(
        _FakeLoader({
          'a1.json': jsonEncode(minimalBundleJson(level: 'A1')),
          'a2.json': jsonEncode(minimalBundleJson(level: 'A2')),
        }),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('a new learner is in the base level', () async {
    final container = _container(db);
    expect(await container.read(currentLevelIdProvider.future), 'a1');
  });

  test('selecting a level enrols the learner in it and makes it current', () async {
    final container = _container(db);
    await container.read(levelSelectionControllerProvider.notifier).select('a2');

    expect(await container.read(currentLevelIdProvider.future), 'a2');
  });

  test('a level that builds on an unfinished one is locked until it is '
      'opened', () async {
    final container = _container(db);
    // levelAccessProvider is auto-disposing: hold a listener so reading its
    // future twice doesn't race its own disposal between reads.
    final subscription = container.listen(
      levelAccessProvider('a2'),
      (_, _) {},
    );
    addTearDown(subscription.close);

    expect(
      await container.read(levelAccessProvider('a2').future),
      LevelAccess.lockedNeedsPrerequisite,
    );

    await container.read(levelSelectionControllerProvider.notifier).unlock('a2');

    expect(
      await container.read(levelAccessProvider('a2').future),
      LevelAccess.open,
    );
  });
}
```

(`minimalBundleJson` comes from `test/content/fixtures/minimal_bundle.dart`; import it with a relative path.)

- [ ] **Step 5: Implement the providers**

Create `lib/features/progress/providers/level_providers.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../content/catalog/level_catalog.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../learning_path/providers/unit_progress_providers.dart';
import '../domain/level_access.dart';
import 'current_learner_provider.dart';
import 'progress_providers.dart';

part 'level_providers.g.dart';

/// Ensures the learner has an enrolment row for [levelId] once its content
/// is loaded. Idempotent — see `LearnerRepository.ensureEnrolled`.
@Riverpod(keepAlive: true)
Future<void> ensureLevelEnrolment(Ref ref, String levelId) async {
  final learner = await ref.watch(currentLearnerProvider.future);
  final index = await ref.watch(courseContentProvider(levelId).future);
  await ref
      .watch(learnerRepositoryProvider)
      .ensureEnrolled(
        learnerId: learner.id,
        levelId: levelId,
        courseId: index.bundle.course.id,
        contentVersion: index.bundle.contentVersion,
      );
}

/// The level the learner is working in — see [currentLevelIdFor]. Every
/// screen that shows "a level" follows this rather than naming one.
@Riverpod(keepAlive: true)
Future<String> currentLevelId(Ref ref) async {
  final learner = await ref.watch(currentLearnerProvider.future);
  final enrolments = await ref
      .watch(learnerRepositoryProvider)
      .enrolments(learnerId: learner.id);
  return currentLevelIdFor(
    enrolments: enrolments,
    catalog: ref.watch(levelCatalogProvider),
  );
}

/// Whether [levelId] is open for the learner right now, and if not, why.
@riverpod
Future<LevelAccess> levelAccess(Ref ref, String levelId) async {
  final entry = levelCatalogEntryIn(ref.watch(levelCatalogProvider), levelId);
  if (entry == null) return LevelAccess.noContent;

  final learner = await ref.watch(currentLearnerProvider.future);
  final repository = ref.watch(learnerRepositoryProvider);
  final enrolment = await repository.enrolmentForLevel(
    learnerId: learner.id,
    levelId: levelId,
  );

  var prerequisiteComplete = false;
  final prerequisiteId = entry.prerequisiteLevelId;
  if (prerequisiteId != null) {
    final prerequisite = await ref.watch(
      courseContentProvider(prerequisiteId).future,
    );
    final progress = await ref.watch(allUnitProgressProvider.future);
    prerequisiteComplete = levelComplete(
      units: prerequisite.bundle.units,
      masteredUnitIds: {
        for (final row in progress)
          if (row.state == 'mastered') row.unitId,
      },
    );
  }

  return levelAccessFor(
    entry: entry,
    enrolment: enrolment,
    prerequisiteComplete: prerequisiteComplete,
  );
}

/// Switching levels and opening a locked one — the two writes behind the
/// Learn tab's level strip and its lock sheet.
@riverpod
class LevelSelectionController extends _$LevelSelectionController {
  @override
  void build() {}

  /// Makes [levelId] the level the learner is working in, enrolling them if
  /// this is their first time in it.
  Future<void> select(String levelId) async {
    final learner = await ref.read(currentLearnerProvider.future);
    await ref.read(ensureLevelEnrolmentProvider(levelId).future);
    await ref
        .read(learnerRepositoryProvider)
        .markLevelSelected(learnerId: learner.id, levelId: levelId);
    ref.invalidate(currentLevelIdProvider);
  }

  /// Opens [levelId] for the learner — from "Open anyway", from finishing
  /// the level it builds on, or from a placement result inside it.
  Future<void> unlock(String levelId) async {
    final learner = await ref.read(currentLearnerProvider.future);
    await ref.read(ensureLevelEnrolmentProvider(levelId).future);
    await ref
        .read(learnerRepositoryProvider)
        .markLevelUnlocked(learnerId: learner.id, levelId: levelId);
    ref.invalidate(levelAccessProvider(levelId));
  }
}
```

Delete `lib/features/progress/providers/ensure_a1_enrollment_provider.dart` and its `.g.dart`, and in `lib/app.dart` replace the `ref.watch(ensureA1EnrollmentProvider);` line (keep the surrounding comment's intent, updated):

```dart
    // Fire-and-forget: enrols the learner in the level they're working in as
    // soon as both the profile and that level's content are ready. Not
    // awaited here — nothing in the UI blocks on it.
    final currentLevelId = ref.watch(currentLevelIdProvider).value;
    if (currentLevelId != null) {
      ref.watch(ensureLevelEnrolmentProvider(currentLevelId));
    }
```

Regenerate: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 6: Run the tests to verify they pass**

Run: `flutter test test/features/progress/ test/content/`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
rm lib/features/progress/providers/ensure_a1_enrollment_provider.dart lib/features/progress/providers/ensure_a1_enrollment_provider.g.dart
git add -A lib test
git commit -m "feat: track which level a learner is in and whether it is open

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: The Learn tab's level strip

> **Superseded in part — read this before reusing Task 7's code.** This
> task's widget code was written before the product owner reviewed the
> mockups, and the mockups changed the design. What shipped is in
> `.superpowers/sdd/2026-09-20-a2-step2a-current-level-and-lock/task-7-fix-1-brief.md`
> (commits d4a1a59, 4912b9d): a segmented track over the levels that have
> content, sitting **below** the course title, with no overline of its own.
> The wrapped six-pill `Wrap` below, the `learnLevelStripTitle` overline and
> the `learnLevelSemanticsComingSoon` string are all gone — the latter two
> keys no longer exist in the ARB files, so any later task that references
> them is referencing dead copy. The rest of this task (strings, wiring,
> access plumbing) stands as written.

**Arabic copy rule for these strings (learned from rendering the mockups):** an Arabic noun always precedes a Latin level code (`المستوى A2`, never a bare `A2` at a sentence boundary), and bidi isolates (`⁨`…`⁩`) are used **only** where two codes share one sentence — the lock sheet's title and body. Two bare codes in one Arabic sentence rendered in the wrong order ("A2 builds on A1" read as "A1 … A2"); isolates fix that, but inside a button they drew as a visible block in the render, so they stay out of button labels. The repo already uses isolates this way (`course_screen.dart`'s `'⁨${unit.title}⁩'`).


**Files:**
- Create: `lib/features/learning_path/presentation/widgets/level_strip.dart`
- Modify: `lib/features/learning_path/presentation/course_screen.dart` (delete `_ComingLater` and `_LevelPill`, follow the current level), `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb` (+ generated)
- Test: `test/features/learning_path/presentation/course_screen_test.dart`

**Interfaces:**
- Consumes: `currentLevelIdProvider`, `levelAccessProvider`, `levelSelectionControllerProvider` (Task 6); `levelCatalogProvider`, `LevelAvailability.preview` (Task 4).
- Produces: `LevelStrip({required List<LevelCatalogEntry> catalog, required String shownLevelId, required Map<String, LevelAccess> access, required void Function(LevelCatalogEntry entry, LevelAccess access) onSelect})`.

- [ ] **Step 1: Add the strings**

Add to `lib/l10n/app_en.arb` (each with an `@key` description; every `{level}` needs `"placeholders": {"level": {"type": "String", "example": "A2"}}`, following the existing `lessonIntroFromLevel` entry):

```json
  "learnLevelStripTitle": "Your levels",
  "learnLevelSemanticsCurrent": "Level {level}, the one you're learning now",
  "learnLevelSemanticsOpen": "Level {level}, open — switch to it",
  "learnLevelSemanticsLocked": "Level {level}, locked",
  "learnLevelSemanticsComingSoon": "Level {level}, coming later",
  "learnLevelComingLaterBody": "More levels are on the way. Everything you learn in {level} carries over."
```

Add to `lib/l10n/app_ar.arb`:

```json
  "learnLevelStripTitle": "مستوياتك",
  "learnLevelSemanticsCurrent": "المستوى {level}، وهو ما تتعلّمه الآن",
  "learnLevelSemanticsOpen": "المستوى {level}، مفتوح — انتقل إليه",
  "learnLevelSemanticsLocked": "المستوى {level}، مقفل",
  "learnLevelSemanticsComingSoon": "المستوى {level}، قادم لاحقًا",
  "learnLevelComingLaterBody": "مستويات أخرى في الطريق، وكل ما تتعلّمه في المستوى {level} يبقى معك."
```

Delete `learnComingLaterBody` and `learnComingLaterTitle` from both files — the strip replaces both (`learnComingLaterBody` also hard-coded "A1", which is what the new parameterised string fixes).

Run: `flutter gen-l10n`

- [ ] **Step 2: Write the failing tests**

`test/features/learning_path/presentation/course_screen_test.dart`'s helper is `Future<AppLocalizations> _pump(WidgetTester tester, {bool midCourse = true})`, which builds its own `ProviderScope` inline and overrides `courseContentProvider('a1')` with an index built from the real A1 bundle. Extend it so it can also stand up a second level, and change its return type to a record — `Future<(ProviderContainer, AppLocalizations)>` — built from an `UncontrolledProviderScope`, the way `test/features/grammar/presentation/grammar_test_harness.dart`'s `pumpGrammar` already does, so a test can read providers directly. Update the existing call sites to `final (_, l10n) = await _pump(tester);`. The extended helper:

- override `levelCatalogProvider` with a three-entry catalogue: `a1` available (`bundleAssetPath: 'a1.json'`), `a2` available with `prerequisiteLevelId: 'a1'`, `b1` comingSoon — unless the test passes `previewLevelIds: {'a2'}`, in which case A2's entry is `LevelAvailability.preview`;
- override `courseContentProvider('a2')` with an index built from `minimalBundleJson(level: 'A2')` (`test/content/fixtures/minimal_bundle.dart`), whose course title is `Test A2`;
- take an `unlockedLevelIds` set, and for each id call the real `DriftLearnerRepository.ensureEnrolled` + `markLevelUnlocked` against the test database before pumping.

Then add:

```dart
  testWidgets('the level strip shows every level, marks the current one and '
      'says which are locked', (tester) async {
    final (_, l10n) = await _pump(tester);

    expect(find.byType(LevelStrip), findsOneWidget);
    expect(
      find.bySemanticsLabel(l10n.learnLevelSemanticsCurrent('A1')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(l10n.learnLevelSemanticsLocked('A2')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(l10n.learnLevelSemanticsComingSoon('B1')),
      findsOneWidget,
    );
  });

  testWidgets('tapping an open level switches the course page to it', (
    tester,
  ) async {
    final (_, l10n) = await _pump(tester, unlockedLevelIds: const {'a2'});

    await tester.tap(find.text('A2'));
    await tester.pumpAndSettle();

    expect(find.text('Test A2'), findsOneWidget);
    expect(
      find.bySemanticsLabel(l10n.learnLevelSemanticsCurrent('A2')),
      findsOneWidget,
    );
  });
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `flutter test test/features/learning_path/presentation/course_screen_test.dart`
Expected: FAIL — `LevelStrip` doesn't exist and the page always shows A1.

- [ ] **Step 4: Write the strip**

Create `lib/features/learning_path/presentation/widgets/level_strip.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../content/catalog/level_catalog.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/overline_style.dart';
import '../../../progress/domain/level_access.dart';

/// Every CEFR level in the catalogue as a pill: the one on screen filled,
/// an open level outlined and tappable, a locked one outlined behind a
/// small lock, and the levels with no content yet outlined and inert.
///
/// A locked level is still tappable — the tap is what opens the
/// explanation and the way forward. Progression here is a recommendation,
/// never a wall; see docs/PRODUCT.md flow 5.
class LevelStrip extends StatelessWidget {
  const LevelStrip({
    required this.catalog,
    required this.shownLevelId,
    required this.access,
    required this.onSelect,
    super.key,
  });

  final List<LevelCatalogEntry> catalog;

  /// The level whose course page is on screen.
  final String shownLevelId;

  /// Each level's access by level id; a level missing from the map is
  /// treated as [LevelAccess.noContent].
  final Map<String, LevelAccess> access;

  final void Function(LevelCatalogEntry entry, LevelAccess access) onSelect;

  LevelAccess _accessFor(LevelCatalogEntry entry) =>
      access[entry.levelId] ?? LevelAccess.noContent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final shownCode = catalog
        .firstWhere(
          (e) => e.levelId == shownLevelId,
          orElse: () => catalog.first,
        )
        .cefrCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.learnLevelStripTitle.toUpperCase(),
          style: overlineStyle(context, color: tokens.textSecondary),
        ),
        const SizedBox(height: AppSpace.xs),
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: [
            for (final entry in catalog)
              _LevelPill(
                entry: entry,
                access: _accessFor(entry),
                isShown: entry.levelId == shownLevelId,
                onTap: () => onSelect(entry, _accessFor(entry)),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          l10n.learnLevelComingLaterBody(shownCode),
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({
    required this.entry,
    required this.access,
    required this.isShown,
    required this.onTap,
  });

  final LevelCatalogEntry entry;
  final LevelAccess access;
  final bool isShown;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final code = entry.cefrCode;
    final tappable = access != LevelAccess.noContent;
    final locked =
        access == LevelAccess.lockedNeedsPrerequisite ||
        access == LevelAccess.notReleased;
    final foreground = isShown ? tokens.onPrimaryInk : tokens.textSecondary;

    final label = isShown
        ? l10n.learnLevelSemanticsCurrent(code)
        : switch (access) {
            LevelAccess.open => l10n.learnLevelSemanticsOpen(code),
            LevelAccess.lockedNeedsPrerequisite ||
            LevelAccess.notReleased => l10n.learnLevelSemanticsLocked(code),
            LevelAccess.noContent => l10n.learnLevelSemanticsComingSoon(code),
          };

    return Semantics(
      button: tappable,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: isShown ? tokens.primaryInk : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: isShown
                ? BorderSide.none
                : BorderSide(
                    color:
                        Color.lerp(tokens.border, tokens.textSecondary, 0.2) ??
                        tokens.border,
                  ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: tappable ? onTap : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44, minWidth: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.sm,
                  vertical: AppSpace.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (locked && !isShown) ...[
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: foreground,
                      ),
                      const SizedBox(width: AppSpace.xs - 2),
                    ],
                    Text(
                      code,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Make the course page follow the current level**

In `course_screen.dart`:

1. `CourseScreen` becomes a `ConsumerStatefulWidget` (Task 9 needs one field of local state; adding it now avoids touching the class twice). Its `build` watches, in order: `currentLevelIdProvider`, `levelCatalogProvider`, `courseContentProvider(shownLevelId)` and — for each catalogue entry — `levelAccessProvider(entry.levelId)`, collecting the resolved ones into a `Map<String, LevelAccess>` (a still-loading entry is simply absent, and the strip renders it as coming later until it resolves). For now `shownLevelId` is the current level; Task 9 introduces the browsing case.
2. Keep the existing `contentAsync.when(loading/error/data)` shape, and treat a loading `currentLevelIdProvider` as loading too.
3. `_CourseBody` takes the strip's inputs and renders `LevelStrip` immediately below the `learnCourseOverline` line, above the course title, with `const SizedBox(height: AppSpace.md)` under it.
4. Delete `_ComingLater` and `_LevelPill` from `course_screen.dart` — the strip replaces them — and remove the now-unused `learnComingLaterTitle`/`learnComingLaterBody` references.
5. `onSelect` handles `LevelAccess.open` by calling `ref.read(levelSelectionControllerProvider.notifier).select(entry.levelId)`; the other cases are Task 8's and Task 9's and can `return;` for now, with a `// Task 8` comment so the gap is visible rather than silent.

- [ ] **Step 6: Run the tests to verify they pass**

Run: `flutter test test/features/learning_path/ test/widget_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/ test/
git commit -m "feat: show every level on the Learn tab and switch between them

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: The lock sheet — why a level isn't open, and the ways in

**Files:**
- Create: `lib/features/learning_path/presentation/widgets/level_lock_sheet.dart`
- Modify: `lib/features/learning_path/presentation/course_screen.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb` (+ generated)
- Test: `test/features/learning_path/presentation/course_screen_test.dart`

**Interfaces:**
- Consumes: `LevelAccess`, `levelSelectionControllerProvider` (Task 6); `LevelStrip.onSelect` (Task 7).
- Produces: `Future<void> showLevelLockSheet(BuildContext context, {required LevelCatalogEntry entry, required String prerequisiteCode, required LevelAccess access, required VoidCallback onTakePlacementTest, required VoidCallback onOpenAnyway, required VoidCallback onBrowse})`.

- [ ] **Step 1: Add the strings**

`lib/l10n/app_en.arb` (placeholder metadata for every `{level}` and `{previous}`, in the order they appear in each message):

```json
  "levelLockTitle": "{level} builds on {previous}",
  "levelLockBody": "Finishing {previous} opens it. You can check where you stand with the placement test — or open {level} anyway.",
  "levelLockTakeTest": "Take the placement test",
  "levelLockOpenAnyway": "Open {level} anyway",
  "levelNotReleasedTitle": "{level} isn't ready yet",
  "levelNotReleasedBody": "Its lessons open when it's ready. Until then you can look at what it covers.",
  "levelNotReleasedBrowse": "See what {level} covers"
```

`lib/l10n/app_ar.arb`:

```json
  "levelLockTitle": "المستوى ⁨{level}⁩ يُبنى على المستوى ⁨{previous}⁩",
  "levelLockBody": "إنهاء ⁨{previous}⁩ يفتحه. ويمكنك معرفة مستواك عبر اختبار تحديد المستوى، أو فتح ⁨{level}⁩ على أي حال.",
  "levelLockTakeTest": "اختبر مستواك",
  "levelLockOpenAnyway": "افتح المستوى {level} على أي حال",
  "levelNotReleasedTitle": "المستوى {level} ليس جاهزًا بعد",
  "levelNotReleasedBody": "ستُفتح دروسه عندما يصبح جاهزًا، ويمكنك الآن الاطلاع على محتواه.",
  "levelNotReleasedBrowse": "اطّلع على محتوى المستوى {level}"
```

Run: `flutter gen-l10n`

- [ ] **Step 2: Write the failing test**

Add to `course_screen_test.dart`:

```dart
  testWidgets('tapping a locked level explains it and offers the placement '
      'test or opening it anyway', (tester) async {
    final (_, l10n) = await _pump(tester);

    await tester.tap(find.text('A2'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.levelLockTitle('A2', 'A1')), findsOneWidget);
    expect(find.text(l10n.levelLockTakeTest), findsOneWidget);

    await tester.tap(find.text(l10n.levelLockOpenAnyway('A2')));
    await tester.pumpAndSettle();

    expect(find.text('Test A2'), findsOneWidget);
    expect(find.text(l10n.levelLockTakeTest), findsNothing);
  });
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/features/learning_path/presentation/course_screen_test.dart`
Expected: FAIL — tapping a locked level does nothing.

- [ ] **Step 4: Write the sheet**

Create `lib/features/learning_path/presentation/widgets/level_lock_sheet.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../content/catalog/level_catalog.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../progress/domain/level_access.dart';

/// Why a level isn't open, and what the learner can do about it.
///
/// Two shapes. A level they haven't reached yet offers the placement test
/// or opening it anyway — the app recommends an order, it doesn't enforce
/// one (docs/PRODUCT.md flow 5). A level the app hasn't released yet offers
/// only to look at what it covers, because there is nothing to open.
Future<void> showLevelLockSheet(
  BuildContext context, {
  required LevelCatalogEntry entry,
  required String prerequisiteCode,
  required LevelAccess access,
  required VoidCallback onTakePlacementTest,
  required VoidCallback onOpenAnyway,
  required VoidCallback onBrowse,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final tokens = theme.extension<AppTokens>()!;
      final l10n = AppLocalizations.of(sheetContext)!;
      final code = entry.cefrCode;
      final notReleased = access == LevelAccess.notReleased;

      void closeThen(VoidCallback action) {
        Navigator.of(sheetContext).pop();
        action();
      }

      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpace.md,
          0,
          AppSpace.md,
          AppSpace.md + MediaQuery.paddingOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              notReleased
                  ? l10n.levelNotReleasedTitle(code)
                  : l10n.levelLockTitle(code, prerequisiteCode),
              style: theme.textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              notReleased
                  ? l10n.levelNotReleasedBody
                  : l10n.levelLockBody(prerequisiteCode, code),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            if (notReleased)
              FilledButton(
                onPressed: () => closeThen(onBrowse),
                child: Text(l10n.levelNotReleasedBrowse(code)),
              )
            else ...[
              FilledButton(
                onPressed: () => closeThen(onTakePlacementTest),
                child: Text(l10n.levelLockTakeTest),
              ),
              const SizedBox(height: AppSpace.xxs),
              TextButton(
                onPressed: () => closeThen(onOpenAnyway),
                child: Text(l10n.levelLockOpenAnyway(code)),
              ),
            ],
          ],
        ),
      );
    },
  );
}
```

- [ ] **Step 5: Wire it up**

In `course_screen.dart`'s `onSelect`, replace Task 7's placeholder `return;` for `LevelAccess.lockedNeedsPrerequisite` with a call to `showLevelLockSheet`, passing:

- `prerequisiteCode`: the `cefrCode` of the catalogue entry named by `entry.prerequisiteLevelId` (fall back to the current level's code if it somehow isn't in the catalogue);
- `onTakePlacementTest`: `context.push('/tests/placement')`;
- `onOpenAnyway`: `await controller.unlock(entry.levelId); await controller.select(entry.levelId);` — unlock first, so the level is open by the time it becomes current;
- `onBrowse`: Task 9's browse callback (until then, `() {}` with a `// Task 9` comment).

`LevelAccess.notReleased` also opens the sheet (its not-released shape); `noContent` stays untappable.

- [ ] **Step 6: Run the tests to verify they pass**

Run: `flutter test test/features/learning_path/`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/ test/
git commit -m "feat: explain a locked level and let the learner open it anyway

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 9: Browsing a level the app hasn't released

**Files:**
- Modify: `lib/features/learning_path/presentation/course_screen.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb` (+ generated)
- Test: `test/features/learning_path/presentation/course_screen_test.dart`

Browsing shows the level's real unit list — what it covers, in order — with every lesson closed. It is a view, not a move: it never becomes the learner's current level, so nothing else in the app starts following an unreleased level.

**Interfaces:**
- Consumes: `LevelAccess.notReleased`, `showLevelLockSheet`'s `onBrowse` (Task 8).
- Produces: the course page's `_browsingLevelId` state and its read-only rendering.

- [ ] **Step 1: Add the strings**

`lib/l10n/app_en.arb`:

```json
  "learnPreviewBannerTitle": "A look at {level}",
  "learnPreviewBannerBody": "These are the units {level} will cover. Its lessons open when it's ready.",
  "learnPreviewBackToCurrent": "Back to {level}"
```

`lib/l10n/app_ar.arb`:

```json
  "learnPreviewBannerTitle": "نظرة على المستوى {level}",
  "learnPreviewBannerBody": "هذه وحدات المستوى {level} التي سيتناولها. ستُفتح دروسه عندما يصبح جاهزًا.",
  "learnPreviewBackToCurrent": "العودة إلى المستوى {level}"
```

Run: `flutter gen-l10n`

- [ ] **Step 2: Write the failing tests**

Add to `course_screen_test.dart`:

```dart
  testWidgets('a level the app has not released can be looked at but not '
      'opened', (tester) async {
    final (container, l10n) = await _pump(tester, previewLevelIds: const {'a2'});

    await tester.tap(find.text('A2'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.levelNotReleasedTitle('A2')), findsOneWidget);
    expect(find.text(l10n.levelLockOpenAnyway('A2')), findsNothing);

    await tester.tap(find.text(l10n.levelNotReleasedBrowse('A2')));
    await tester.pumpAndSettle();

    // Its units are listed, with the banner, and nothing starts a lesson.
    expect(find.text(l10n.learnPreviewBannerTitle('A2')), findsOneWidget);
    expect(find.text('Unit 1'), findsOneWidget);
    expect(find.text(l10n.homeStartLessonCta), findsNothing);
    expect(find.text(l10n.homeContinueLessonCta), findsNothing);

    // Browsing never changes which level the learner is in.
    expect(await container.read(currentLevelIdProvider.future), 'a1');
  });

  testWidgets('leaving the preview returns to the level being learned', (
    tester,
  ) async {
    final (container, l10n) = await _pump(tester, previewLevelIds: const {'a2'});

    await tester.tap(find.text('A2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.levelNotReleasedBrowse('A2')));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.learnPreviewBackToCurrent('A1')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.learnPreviewBannerTitle('A2')), findsNothing);
  });
```


- [ ] **Step 3: Run the tests to verify they fail**

Run: `flutter test test/features/learning_path/presentation/course_screen_test.dart`
Expected: FAIL — browsing does nothing.

- [ ] **Step 4: Implement**

In `course_screen.dart`:

1. Add `String? _browsingLevelId` to the state class. `shownLevelId` becomes `_browsingLevelId ?? currentLevelId`, and `isBrowsing` is `_browsingLevelId != null`.
2. `onBrowse` sets `_browsingLevelId` to the entry's level id; selecting any level with `LevelAccess.open` clears it back to null.
3. `_CourseBody` takes `isBrowsing`. When true:
   - render a banner card above the units — `HairlineCard` with `l10n.learnPreviewBannerTitle(shownCode)` (`titleSmall`), `l10n.learnPreviewBannerBody(shownCode)` (`bodySmall`/`textSecondary`), and a `TextButton` labelled `l10n.learnPreviewBackToCurrent(currentCode)` that clears the browsing state;
   - render every unit through `_UnitSummary` (never `_CurrentUnitCard`), with no `onTap`, so no lesson can start;
   - hide the `_FinishCard` — its route is the Tests tab for a level the learner isn't in;
   - keep `_CourseProgressCard` out too: a level with no attempts would read "0 of 12 mastered", which is noise, not information.
4. Give the unit rows' `Semantics` the same treatment they already have; a non-tappable row must not announce itself as a button.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/features/learning_path/ test/widget_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/ test/
git commit -m "feat: let a learner look at a level the app hasn't released yet

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 10: The content gate waits for the base level only

**Files:**
- Modify: `lib/core/router/app_router.dart`, `lib/core/router/content_load_refresh_listenable.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write the failing test**

Add to `test/widget_test.dart`, using the file's existing whole-app pump helper and adding one override to its list:

```dart
  testWidgets('a later level failing to load never gates the app', (
    tester,
  ) async {
    await pumpApp(
      tester,
      overrides: [
        courseContentProvider('a2').overrideWith(
          (ref) async => throw StateError('A2 is broken'),
        ),
      ],
    );

    expect(find.byType(ContentErrorScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
```

- [ ] **Step 2: Run the test**

Run: `flutter test test/widget_test.dart`
Expected: it may already pass — the Learn tab is not the start screen, so nothing watches A2 on launch. Say which it was in your report; either way the test stays as the regression guard.

- [ ] **Step 3: Implement**

In both router files, replace the `'a1'` literal with `kBaseLevelId` (from `lib/content/catalog/level_catalog.dart`) and update the doc comments: the gate waits for the base level — the one the app cannot run without — so a later level failing to load is handled where that level is shown and never blocks the app.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/widget_test.dart test/core/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/router/ test/
git commit -m "fix: gate the app on the base level, not on whichever level is showing

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 11: Documentation (definition of done)

**Files:**
- Modify: `docs/ARCHITECTURE.md`, `docs/DATA_MODEL.md`, `docs/GLOSSARY.md`, `docs/TESTING.md`, `docs/UX_PRINCIPLES.md`, `docs/PRODUCT.md`, `docs/ROADMAP.md`, `docs/adr/0006-multiple-levels.md`

The list above is derived from the spec's Documentation section **and** CLAUDE.md's Definition-of-done table — the step-1 review found a hand-picked list missed ROADMAP.md. Check both sources again before you start, and add anything they name that isn't listed here.

Every doc edited gets its **Last verified** line bumped to the day of the edit, naming the change and the branch, in that doc's own style.

- [ ] **Step 1: Write the updates**

- **ARCHITECTURE.md** — under the content flow: the catalogue's three availability states and what `preview` means; the `--dart-define=MOHINGO_PREVIEW_LEVELS` flag; levels load lazily on first watch while the router gate waits for `kBaseLevelId` alone; the current level lives in `course_enrolments`, not in preferences, so Reset progress returns to the base level.
- **DATA_MODEL.md** — `course_enrolments` gains `levelId` (nullable, null reads as the base level), `lastSelectedAt`, `unlockedAt`; schema version is 5; note the A2 bundle asset beside A1's.
- **GLOSSARY.md** — add **Current level** ("the level a learner is working in: their most recently selected enrolment, the base level by default") and **Level lock** (the three states: open, locked behind its prerequisite but openable anyway, not released yet). Extend the Content catalogue row with the `preview` state.
- **UX_PRINCIPLES.md** — the lock copy rule: a locked level always says why it is locked and offers a way forward; the app never presents a level the learner cannot act on at all without saying so.
- **PRODUCT.md** — scope: A2 is now in the app as a not-yet-released level; correct "CEFR levels beyond A1 are roadmapped, not built".
- **ROADMAP.md** — Phase 2's row: step 2a landed; what remains.
- **ADR 0006** — update the "Landed so far" line: decisions 1 and 3 are now in code for the Learn tab, decision 4's lock is in place, decision 1's remaining tabs are step 2b.

- [ ] **Step 2: Commit**

```bash
git add docs/
git commit -m "docs: record the current level, the level lock and A2 as a preview

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 12: Full verification

- [ ] **Step 1: Format** — `dart format .` (report how many files changed).
- [ ] **Step 2: Analyze** — `flutter analyze`, expected `No issues found!`.
- [ ] **Step 3: Test** — `flutter test`, report exact counts and any warnings.
- [ ] **Step 4: Check the deferred call sites are still deferred** — `git grep -n "courseContentProvider('a1')" -- lib/` should still list only the step-2b screens (Home, Review, Vocabulary, Grammar, Tests, final mission, final assessment, placement) and nothing in `lib/features/learning_path/` or `lib/core/router/`.
- [ ] **Step 5: Commit any formatting changes** (skip if `git status` is clean).
