# A2 Step 1 — App Foundations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the app's content layer and lesson rendering ready for a second level — content IDs know their level, a level can build on an earlier one, A2's data shapes parse, and texts the app has never shown (reading passages, lesson texts, source cards, partner lines) are shown — without changing anything a learner sees about levels yet.

**Architecture:** Every bundle ID starts with its level (`A1-U3`, `A2.LEX…`), so a pure function maps an ID to its catalogue level and a keep-alive provider (`contentIndexForIdProvider`) hands any "open this item" screen the right level's index. The level catalogue gains `prerequisiteLevelId`; a level with a prerequisite is indexed with the prerequisite's index attached, so its lessons may reference the earlier level's grammar, words and phrases (`resolveGrammar/Lexicon/Chunk`). Rendering fixes live in the shared activity chrome and the lesson player's intro, so A1 benefits immediately.

**Not in this plan (step 2's):** anything a learner sees about levels — the current level, the A1 | A2 switcher, locks, Home/Tests following a level, shared Review (including the review session's and Review home's word lookups), Vocabulary/Grammar filters, per-level enrolment, the router gate, "A1" in wording, and placement. A2 stays "Coming later" throughout; nothing here loads it.

**Tech Stack:** Flutter, Riverpod 3 (`riverpod_annotation` codegen), Drift, `flutter_test`, ARB l10n (`flutter gen-l10n`).

**Spec:** [docs/superpowers/specs/2026-09-19-a2-level-design.md](../specs/2026-09-19-a2-level-design.md) — this plan implements "Order of work" step 1 (Design 3's content loading, cross-level lookup, rendering, content model).

## Global Constraints

- Every user-facing string is added to **both** `lib/l10n/app_en.arb` (with an `@key` description) and `lib/l10n/app_ar.arb`, the Arabic written as natural Arabic — never a word-for-word translation. Run `flutter gen-l10n` after editing ARB files; the generated files under `lib/core/l10n/generated/` are committed.
- No hard-coded left/right: use `EdgeInsetsDirectional`, `AlignmentDirectional`, start/end. English content text is always given `textDirection: TextDirection.ltr`; Arabic content `TextDirection.rtl`.
- Nothing here may need the network. No new dependencies.
- After editing any `@riverpod`/`@Riverpod` function, run `dart run build_runner build --delete-conflicting-outputs`; generated `*.g.dart` files are committed.
- `lib/content/` never imports from `lib/features/`.
- Answers, `accepted` lists and evaluation specs are never shown before submission.
- Commands: tests `flutter test <path>`; lint `dart format .` then `flutter analyze`.
- Commit messages: short imperative summary with a type prefix as in `git log` (`feat:`, `fix:`, `content:`, `docs:`, `test:`), ending with the line `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>` after a blank line.
- Work on branch `feature/a2-foundations` (Task 1 creates it).

## File map

| File | Status | Responsibility |
|---|---|---|
| `lib/content/catalog/content_level.dart` | new | `levelIdOfContentId` — level of any bundle ID |
| `lib/content/catalog/level_catalog.dart` | modify | `prerequisiteLevelId`, `levelCatalogEntryIn` |
| `lib/content/models/registry_items.dart` | modify | `LexiconExample` (`en` + optional `ar`) |
| `lib/content/models/curriculum_structure.dart` | modify | `LessonReadingText`, `Lesson.readingText`, `Unit.countsTowardLevelMastery` |
| `lib/content/models/activity.dart` | modify | `Activity.sourceCard`, `SpeakActivity.partnerTurns` |
| `lib/content/index/course_content_index.dart` | modify | `prerequisite`, `resolveGrammar/Lexicon/Chunk`, validation through them |
| `lib/content/providers/bundle_asset_loader.dart` | new | `BundleAssetLoader` seam over `rootBundle` |
| `lib/content/providers/course_content_providers.dart` | modify | `levelCatalogProvider`, `bundleAssetLoaderProvider`, prerequisite-aware `courseContentProvider`, `contentIndexForIdProvider` |
| `lib/features/activity_engine/presentation/widgets/activity_source_card.dart` | new | The text a question is about |
| `lib/features/activity_engine/presentation/widgets/activity_partner_turns_card.dart` | new | What the other person says in a speaking task |
| `lib/features/activity_engine/presentation/activity_chrome.dart` | modify | `source` slot |
| `lib/features/activity_engine/presentation/views/{choice,write,speak}_activity_view.dart` | modify | Pass source / partner turns |
| `lib/features/lesson_player/presentation/widgets/lesson_reading_step.dart` | new | A lesson's model text in the intro |
| `lib/features/lesson_player/presentation/lesson_player_screen.dart` | modify | Intro steps list; per-ID index; resolved phrases/grammar |
| `lib/features/lesson_player/presentation/widgets/lesson_key_phrases_step.dart` | modify | "From A1" badge |
| `lib/core/l10n/lesson_type_label.dart` | modify | `integrated-production` label |
| 8 screens/providers (Task 5) | modify | Open items through `contentIndexForIdProvider` |
| `assets/content/en/A1/a1-course-bundle.json` | modify | Complete the 11 truncated `readingText.textAr` |
| `docs/adr/0006-multiple-levels.md` + 5 docs | new/modify | Definition of done |

---

### Task 1: Branch and commit the design documents

**Files:**
- Commit: `docs/superpowers/specs/2026-09-19-a2-level-design.md`, `docs/superpowers/plans/2026-09-19-a2-step1-app-foundations.md`

- [ ] **Step 1: Create the branch**

```bash
git checkout -b feature/a2-foundations
```

- [ ] **Step 2: Commit the spec and this plan**

```bash
git add docs/superpowers/specs/2026-09-19-a2-level-design.md docs/superpowers/plans/2026-09-19-a2-step1-app-foundations.md
git commit -m "docs: design A2 and plan its app foundations

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: A content ID's level, and a catalogue that knows prerequisites

**Files:**
- Create: `lib/content/catalog/content_level.dart`
- Modify: `lib/content/catalog/level_catalog.dart`
- Test: `test/content/catalog/content_level_test.dart` (new), `test/content/catalog/level_catalog_test.dart`

**Interfaces:**
- Produces: `String? levelIdOfContentId(String contentId)`; `LevelCatalogEntry.prerequisiteLevelId` (`String?`); `LevelCatalogEntry? levelCatalogEntryIn(List<LevelCatalogEntry> catalog, String levelId)`.

- [ ] **Step 1: Write the failing tests**

Create `test/content/catalog/content_level_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/catalog/content_level.dart';

void main() {
  test('reads the level from unit, lesson and activity ids', () {
    expect(levelIdOfContentId('A1-U3'), 'a1');
    expect(levelIdOfContentId('A1-U3-L2'), 'a1');
    expect(levelIdOfContentId('A2-U1-L1-A01'), 'a2');
    expect(levelIdOfContentId('A1-FINAL-MISSION-A01'), 'a1');
    expect(levelIdOfContentId('A2-FA-LISTEN-01'), 'a2');
  });

  test('reads the level from grammar, word and phrase ids', () {
    expect(levelIdOfContentId('A1.G.BE.I_AM'), 'a1');
    expect(levelIdOfContentId('A1.LEX.PICTURE.N01'), 'a1');
    expect(levelIdOfContentId('A2.LEX.STAY_V01'), 'a2');
    expect(levelIdOfContentId('A2.CHUNK.ON_WEEKDAYS'), 'a2');
  });

  test('an id with no level prefix has no level', () {
    expect(levelIdOfContentId('TEST-U1'), isNull);
    expect(levelIdOfContentId('U1'), isNull);
    expect(levelIdOfContentId(''), isNull);
  });
}
```

Add to `test/content/catalog/level_catalog_test.dart`, inside `main()`:

```dart
  test('A2 builds on A1; A1 builds on nothing', () {
    expect(levelCatalogEntry('a1')!.prerequisiteLevelId, isNull);
    expect(levelCatalogEntry('a2')!.prerequisiteLevelId, 'a1');
  });

  test('levelCatalogEntryIn looks an entry up in any catalogue', () {
    const catalog = [
      LevelCatalogEntry(
        levelId: 'x1',
        cefrCode: 'X1',
        availability: LevelAvailability.available,
        bundleAssetPath: 'x1.json',
      ),
    ];
    expect(levelCatalogEntryIn(catalog, 'x1')!.bundleAssetPath, 'x1.json');
    expect(levelCatalogEntryIn(catalog, 'a1'), isNull);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/content/catalog/`
Expected: FAIL — `content_level.dart` doesn't exist; `prerequisiteLevelId` and `levelCatalogEntryIn` aren't defined.

- [ ] **Step 3: Implement**

Create `lib/content/catalog/content_level.dart`:

```dart
/// Every unit, lesson, activity and registry id in a curriculum bundle
/// starts with its CEFR level: `A1-U3-L2-A01`, `A1.LEX.PICTURE.N01`,
/// `A2.G.BE_PAST`, `A1-FINAL-MISSION-A01`.
final _levelPrefix = RegExp(r'^([A-Za-z][0-9])[-.]');

/// The catalogue level id (`"a1"`) that [contentId] belongs to, read from
/// its prefix — or null when it has none.
///
/// The prefix is what keeps ids unique across levels, and what lets a
/// screen that opens one unit, lesson, word, phrase or grammar point find
/// the right level's content without being told the level. See
/// `contentIndexForIdProvider`.
String? levelIdOfContentId(String contentId) =>
    _levelPrefix.firstMatch(contentId)?.group(1)!.toLowerCase();
```

In `lib/content/catalog/level_catalog.dart`, change `LevelCatalogEntry`'s constructor and add the field:

```dart
class LevelCatalogEntry {
  const LevelCatalogEntry({
    required this.levelId,
    required this.cefrCode,
    required this.availability,
    this.bundleAssetPath,
    this.prerequisiteLevelId,
  });
```

and, after the `bundleAssetPath` field:

```dart
  /// The level this one builds on (A2 builds on A1), or null. Its content
  /// loads first, and this level's lessons may reference its grammar,
  /// words and phrases by id — shown to learners as "From A1". App-owned,
  /// like the rest of this table: bundles never declare it.
  final String? prerequisiteLevelId;
```

Change the A2 entry in `kLevelCatalog`:

```dart
  LevelCatalogEntry(
    levelId: 'a2',
    cefrCode: 'A2',
    availability: LevelAvailability.comingSoon,
    prerequisiteLevelId: 'a1',
  ),
```

Replace `levelCatalogEntry` at the end of the file with:

```dart
LevelCatalogEntry? levelCatalogEntry(String levelId) =>
    levelCatalogEntryIn(kLevelCatalog, levelId);

/// [levelCatalogEntry] over any catalogue — the app reads the catalogue
/// through `levelCatalogProvider`, which tests override.
LevelCatalogEntry? levelCatalogEntryIn(
  List<LevelCatalogEntry> catalog,
  String levelId,
) {
  for (final entry in catalog) {
    if (entry.levelId == levelId) return entry;
  }
  return null;
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/content/catalog/`
Expected: PASS (all tests, including the three existing catalogue tests).

- [ ] **Step 5: Commit**

```bash
git add lib/content/catalog/ test/content/catalog/
git commit -m "feat: read a content id's level and declare A2's prerequisite

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: The content model accepts A2's shapes

**Files:**
- Modify: `lib/content/models/registry_items.dart`, `lib/content/models/curriculum_structure.dart`, `lib/content/models/activity.dart`
- Modify (consumers): `lib/features/vocabulary/presentation/vocabulary_detail_view.dart`, `lib/features/review/presentation/review_session_screen.dart`
- Modify (tests that build `Unit`): `test/features/home/domain/home_domain_test.dart`, `test/features/learning_path/domain/current_unit_selector_test.dart`, `test/features/progress/domain/mastery_aggregation_service_test.dart`
- Test: `test/content/models/registry_items_test.dart` (new), `test/content/models/curriculum_structure_test.dart` (new), `test/content/models/activity_test.dart`, `test/features/vocabulary/presentation/vocabulary_detail_example_test.dart` (new)

**Interfaces:**
- Produces: `class LexiconExample { final String en; final String? ar; }` and `LexiconItem.examples` is `List<LexiconExample>`; `class LessonReadingText { final String title; final String text; final String? textAr; }` and `Lesson.readingText` (`LessonReadingText?`); `Unit.countsTowardLevelMastery` (`bool`, replaces `countsTowardA1Mastery`); `Activity.sourceCard` (`String?` getter); `SpeakActivity.partnerTurns` (`List<String>` getter); `VocabularyDetailView.examples` is `List<LexiconExample>`.

- [ ] **Step 1: Write the failing tests**

Create `test/content/models/registry_items_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/registry_items.dart';

Map<String, dynamic> _lexicon(List<Object> examples) => {
  'id': 'A2.LEX.STAY_V01',
  'headword': 'stay',
  'partOfSpeech': 'verb',
  'arabic': 'يقيم',
  'cefr': 'A2',
  'receptive': true,
  'productive': true,
  'meaning': 'stay',
  'examples': examples,
  'introducedIn': 'A2-U1-L2',
  'recycledIn': <String>[],
};

void main() {
  test("A1's examples are English sentences", () {
    final item = LexiconItem.fromJson(_lexicon(['I have one brother.']));
    expect(item.examples.single.en, 'I have one brother.');
    expect(item.examples.single.ar, isNull);
  });

  test("A2's examples carry their Arabic", () {
    final item = LexiconItem.fromJson(
      _lexicon([
        {'en': 'We are staying near the centre.', 'ar': 'نقيم قرب المركز.'},
      ]),
    );
    expect(item.examples.single.en, 'We are staying near the centre.');
    expect(item.examples.single.ar, 'نقيم قرب المركز.');
  });

  test('an empty Arabic example counts as none', () {
    final item = LexiconItem.fromJson(
      _lexicon([
        {'en': 'Stay here.', 'ar': ''},
      ]),
    );
    expect(item.examples.single.ar, isNull);
  });
}
```

Create `test/content/models/curriculum_structure_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/curriculum_structure.dart';

Map<String, dynamic> _lesson({Map<String, dynamic>? readingText}) => {
  'id': 'A1-U2-L6',
  'title': 'A People Profile',
  'titleAr': 'ملف عن الناس',
  'lessonType': 'encounter-focus-practice',
  'canDo': <String>[],
  'activities': <Map<String, dynamic>>[],
  'readingText': ?readingText,
};

Map<String, dynamic> _unit(Map<String, dynamic> countsToward) => {
  'id': 'A2-U1',
  'title': 'Life Now',
  'titleAr': 'حياتي الآن',
  'levelRole': 'core',
  'estimatedMinutes': [95, 130],
  ...countsToward,
  'lessons': <Map<String, dynamic>>[],
  'mastery': {'requiredObjectives': <String>[]},
};

void main() {
  test("a lesson's model text is parsed with its Arabic", () {
    final lesson = Lesson.fromJson(
      _lesson(
        readingText: {
          'title': "Maya's Family",
          'text': 'My name is Maya.',
          'textAr': 'اسمي مايا.',
        },
      ),
    );
    expect(lesson.readingText!.title, "Maya's Family");
    expect(lesson.readingText!.text, 'My name is Maya.');
    expect(lesson.readingText!.textAr, 'اسمي مايا.');
  });

  test('a lesson without a model text has none', () {
    expect(Lesson.fromJson(_lesson()).readingText, isNull);
  });

  test('whether a unit counts towards its level is read from any level '
      'name the bundle uses', () {
    expect(
      Unit.fromJson(_unit({'countsTowardA1Mastery': false}))
          .countsTowardLevelMastery,
      isFalse,
    );
    expect(
      Unit.fromJson(_unit({'countsTowardA2Mastery': true}))
          .countsTowardLevelMastery,
      isTrue,
    );
    expect(
      Unit.fromJson(_unit({'countsTowardLevelMastery': true}))
          .countsTowardLevelMastery,
      isTrue,
    );
  });
}
```

Add to `test/content/models/activity_test.dart`, inside `main()`:

```dart
  group('material shown with a task', () {
    Map<String, dynamic> speak(Map<String, dynamic> extra) => {
      'id': 'A1-FINAL-ASSESS-S02',
      'type': 'speak',
      'mode': 'mastery',
      'skill': 'spokenInteraction',
      'canDo': <String>[],
      'prompt': 'Respond to four short examiner turns.',
      ...extra,
    };

    test('any activity may carry a source card', () {
      final activity = Activity.fromJson(
        speak({'sourceCard': 'Bus 14 — 08:00 to Central.'}),
      );
      expect(activity.sourceCard, 'Bus 14 — 08:00 to Central.');
      expect(Activity.fromJson(speak({})).sourceCard, isNull);
      expect(Activity.fromJson(speak({'sourceCard': '  '})).sourceCard, isNull);
    });

    test("a speaking task's partner lines come from partnerTurns or A1's "
        'examinerTurns', () {
      final partner =
          Activity.fromJson(speak({
                'partnerTurns': ['Hi! How are you?', 'What do you do?'],
              }))
              as SpeakActivity;
      expect(partner.partnerTurns, ['Hi! How are you?', 'What do you do?']);

      final examiner =
          Activity.fromJson(speak({
                'examinerTurns': ['Good morning.'],
              }))
              as SpeakActivity;
      expect(examiner.partnerTurns, ['Good morning.']);

      expect((Activity.fromJson(speak({})) as SpeakActivity).partnerTurns,
          isEmpty);
    });
  });
```

Create `test/features/vocabulary/presentation/vocabulary_detail_example_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/registry_items.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/speech/providers/speech_providers.dart';
import 'package:mohingo/features/vocabulary/presentation/vocabulary_detail_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../review/presentation/review_test_harness.dart';
import '../../speech/fake_speech_services.dart';

void main() {
  testWidgets('an example with Arabic shows both lines', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          textToSpeechServiceProvider.overrideWithValue(
            FakeTextToSpeechService(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppColorSeed.calmTeal),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: VocabularyDetailView(
            index: reviewTestIndex,
            lexiconId: 'A1.LEX.HAVE.V01',
            kindLabel: 'Word',
            text: 'stay',
            arabic: 'يقيم',
            introducedIn: 'A1-U2-L2',
            examples: const [
              LexiconExample(
                en: 'We are staying near the centre.',
                ar: 'نقيم قرب المركز.',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('We are staying near the centre.'), findsOneWidget);
    expect(find.text('نقيم قرب المركز.'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/content/models/ test/features/vocabulary/presentation/vocabulary_detail_example_test.dart`
Expected: FAIL — `LexiconExample`, `readingText`, `countsTowardLevelMastery`, `sourceCard`, `partnerTurns` don't exist.

- [ ] **Step 3: Implement the model changes**

In `lib/content/models/registry_items.dart`, add above `LexiconItem`:

```dart
/// One example sentence for a [LexiconItem]: English, and its Arabic when
/// the bundle gives one. A1's examples are English strings; A2's are
/// `{en, ar}` objects — both parse.
class LexiconExample {
  const LexiconExample({required this.en, this.ar});

  factory LexiconExample.fromJson(Object json) {
    if (json is String) return LexiconExample(en: json);
    final map = json as Map<String, dynamic>;
    final ar = map['ar'] as String?;
    return LexiconExample(
      en: map['en'] as String,
      ar: ar == null || ar.trim().isEmpty ? null : ar,
    );
  }

  final String en;
  final String? ar;
}
```

In `LexiconItem.fromJson`, replace `examples: List<String>.from(json['examples'] as List),` with:

```dart
      examples: [
        for (final example in json['examples'] as List)
          LexiconExample.fromJson(example as Object),
      ],
```

and change the field to `final List<LexiconExample> examples;`.

In `lib/content/models/curriculum_structure.dart`, add above `Lesson`:

```dart
/// A lesson's model text — a message, a menu, a profile — that its
/// questions are about and that the learner's own writing follows. Shown
/// in the lesson player's intro. `textAr` is null when absent or blank.
class LessonReadingText {
  const LessonReadingText({
    required this.title,
    required this.text,
    this.textAr,
  });

  factory LessonReadingText.fromJson(Map<String, dynamic> json) {
    final textAr = json['textAr'] as String?;
    return LessonReadingText(
      title: json['title'] as String,
      text: json['text'] as String,
      textAr: textAr == null || textAr.trim().isEmpty ? null : textAr,
    );
  }

  final String title;
  final String text;
  final String? textAr;
}
```

In `Lesson`: add `this.readingText,` to the constructor after `required this.activities,`; in `Lesson.fromJson` add after `activities: …toList(),`:

```dart
      readingText: json['readingText'] == null
          ? null
          : LessonReadingText.fromJson(
              json['readingText'] as Map<String, dynamic>,
            ),
```

add the field after `final List<Activity> activities;`:

```dart
  /// The lesson's model text, when it has one (A1's L6 lessons do).
  final LessonReadingText? readingText;
```

and in `Lesson`'s class doc comment, change the list of un-modelled raw fields to drop `readingText`:
`` (`scenario`, `uiPolicy`, `privacyNote`, `numberScope`, `placeLanguage`, `pedagogyNote`, `reference`) ``.

In `Unit`: rename the constructor parameter and field `countsTowardA1Mastery` → `countsTowardLevelMastery`; in `Unit.fromJson` replace `countsTowardA1Mastery: json['countsTowardA1Mastery'] as bool,` with:

```dart
      countsTowardLevelMastery:
          (json['countsTowardLevelMastery'] ??
                  json['countsTowardA1Mastery'] ??
                  json['countsTowardA2Mastery'])
              as bool,
```

and give the field a doc comment:

```dart
  /// Whether the unit counts towards its level's mastery (A1's starter unit
  /// doesn't). Bundles name it per level — `countsTowardA1Mastery`,
  /// `countsTowardA2Mastery` — so it's read under any of those names.
  final bool countsTowardLevelMastery;
```

In `lib/content/models/activity.dart`, add to the `Activity` base class after the `raw` field:

```dart
  /// Material the learner works from — a notice, a timetable, two short
  /// profiles — shown as a card with the question. Any activity type may
  /// carry one (A1's final-assessment mediation tasks and A2's mediation
  /// tasks do). Null when absent or blank.
  String? get sourceCard {
    final value = raw['sourceCard'];
    return value is String && value.trim().isNotEmpty ? value : null;
  }
```

and to `SpeakActivity`, after `fallbackSkill`:

```dart
  /// What the other person says, read aloud before the learner answers —
  /// the bundle's `partnerTurns`, or A1's older `examinerTurns`. Empty
  /// when the task has none.
  List<String> get partnerTurns {
    final value = raw['partnerTurns'] ?? raw['examinerTurns'];
    if (value is! List) return const [];
    return [
      for (final turn in value)
        if (turn is String && turn.trim().isNotEmpty) turn,
    ];
  }
```

- [ ] **Step 4: Update the consumers**

In `lib/features/vocabulary/presentation/vocabulary_detail_view.dart`: add `import '../../../content/models/registry_items.dart';`, change `final List<String> examples;` to `final List<LexiconExample> examples;`, and replace the example row's `Expanded(child: Align(… Text(example …))), ListenButton(text: example),` with:

```dart
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            example.en,
                            textDirection: TextDirection.ltr,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: tokens.textPrimary,
                            ),
                          ),
                          if (example.ar != null)
                            Text(
                              example.ar!,
                              textDirection: TextDirection.rtl,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: tokens.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    ListenButton(text: example.en),
```

In `lib/features/review/presentation/review_session_screen.dart`, replace `example: item.examples.firstOrNull,` with `example: item.examples.firstOrNull?.en,`.

In the three test files that construct `Unit(...)` (`home_domain_test.dart`, `current_unit_selector_test.dart`, `mastery_aggregation_service_test.dart`), rename the argument `countsTowardA1Mastery: true,` to `countsTowardLevelMastery: true,`. JSON fixtures that say `'countsTowardA1Mastery': true` stay as they are — that key still parses.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/content/ test/features/vocabulary/ test/features/review/ test/features/home/ test/features/learning_path/ test/features/progress/`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/content/models/ lib/features/vocabulary/ lib/features/review/presentation/review_session_screen.dart test/
git commit -m "feat: parse bilingual word examples, lesson texts, source cards and partner lines

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: A level that builds on another loads and resolves through it

**Files:**
- Create: `lib/content/providers/bundle_asset_loader.dart`, `test/content/fixtures/minimal_bundle.dart`, `test/content/index/course_content_index_prerequisite_test.dart`, `test/content/providers/course_content_providers_test.dart`
- Modify: `lib/content/index/course_content_index.dart`, `lib/content/providers/course_content_providers.dart` (+ regenerated `.g.dart`)

**Interfaces:**
- Consumes: `levelCatalogEntryIn`, `LevelCatalogEntry.prerequisiteLevelId` (Task 2).
- Produces: `CourseContentIndex.build(CourseBundle bundle, {CourseContentIndex? prerequisite})`; `CourseContentIndex.prerequisite`; `GrammarItem? resolveGrammar(String id)`, `LexiconItem? resolveLexicon(String id)`, `ChunkItem? resolveChunk(String id)`; `abstract interface class BundleAssetLoader { Future<String> load(String assetPath); }`; `levelCatalogProvider` (`List<LevelCatalogEntry>`), `bundleAssetLoaderProvider` (`BundleAssetLoader`); test helpers `minimalBundleJson(...)`, `grammarRecord(id)`, `lexiconRecord(id)`, `chunkRecord(id)`.

- [ ] **Step 1: Write the test fixture**

Create `test/content/fixtures/minimal_bundle.dart`:

```dart
/// A minimal-but-structurally-complete bundle for [level] (`"A1"`,
/// `"A2"`) with one unit and one lesson, for tests of loading, indexing and
/// reference resolution that shouldn't depend on a real bundle. Every id
/// carries the level prefix, as real bundles do.
Map<String, dynamic> minimalBundleJson({
  String level = 'A1',
  List<Map<String, dynamic>> grammar = const [],
  List<Map<String, dynamic>> lexicon = const [],
  List<Map<String, dynamic>> chunks = const [],
  List<String> lessonGrammar = const [],
  List<String> lessonLexicon = const [],
  List<String> lessonChunks = const [],
}) {
  final canDo = '$level.TEST.CANDO';
  return {
    'schemaVersion': '2.0.0',
    'contentVersion': '$level-TEST-1',
    'locale': {
      'targetLanguage': 'en',
      'supportLanguage': 'ar',
      'direction': {'target': 'ltr', 'support': 'rtl'},
    },
    'course': {
      'id': 'EN-$level-TEST',
      'title': 'Test $level',
      'titleAr': 'اختبار $level',
      'status': 'test',
      'finalMissionId': '$level-FINAL-MISSION',
      'finalAssessmentId': '$level-FINAL-ASSESSMENT',
    },
    'domain': {
      'CAN_DO': {'TEST': canDo},
      'MASTERY_POLICY': {
        'minimumObjectiveScore': 0.75,
        'minimumEvidencePerRequiredObjective': 2,
        'requireProductiveEvidenceWhereDeclared': true,
        'practiceCountsAsMastery': false,
        'allowSpeechFallbackToWriting': true,
        'speechCriteria': <String>[],
        'speechAccuracyWeight': 0.2,
      },
    },
    'grammar': grammar,
    'lexicon': lexicon,
    'chunks': chunks,
    'units': [
      {
        'id': '$level-U1',
        'title': 'Unit 1',
        'titleAr': 'الوحدة 1',
        'levelRole': 'core',
        'estimatedMinutes': [10, 20],
        'countsToward${level}Mastery': true,
        'lessons': [
          {
            'id': '$level-U1-L1',
            'title': 'Lesson 1',
            'titleAr': 'الدرس 1',
            'lessonType': 'encounter-focus-practice',
            'canDo': [canDo],
            'grammar': lessonGrammar,
            'lexicon': lessonLexicon,
            'chunks': lessonChunks,
            'activities': <Map<String, dynamic>>[],
          },
        ],
        'mastery': {
          'requiredObjectives': <String>[],
          'requiredSkillGroups': <List<String>>[],
          'minimumObjectiveScore': 0.75,
        },
      },
    ],
    'mediaSpecifications': <String, dynamic>{},
    'finalMission': {
      'id': '$level-FINAL-MISSION',
      'title': 'Mission',
      'titleAr': 'مهمة',
      'scenario': 'x',
      'canDo': <String>[],
      'stages': <Map<String, dynamic>>[],
      'activities': <Map<String, dynamic>>[],
      'scoring': {
        'requiredSkillGroups': <List<String>>[],
        'minimumCriterionScore': 0.6,
        'noSingleAverageCompensation': true,
      },
    },
    'finalAssessment': {
      'id': '$level-FINAL-ASSESSMENT',
      'title': 'Assessment',
      'titleAr': 'اختبار',
      'sourcePolicy': 'unseen',
      'sections': <String, dynamic>{},
      'scoring': {
        'decisionRule': {
          'required': <String>[],
          'noSingleOverallAverage': true,
        },
        'accessibility': {'fallbackDoesNotCreateSpeakingEvidence': true},
      },
    },
  };
}

Map<String, dynamic> grammarRecord(String id) => {
  'id': id,
  'form': 'form of $id',
  'meaningAr': 'معنى',
  'introducedIn': 'lesson',
  'examples': <Map<String, dynamic>>[],
};

Map<String, dynamic> lexiconRecord(String id) => {
  'id': id,
  'headword': 'word of $id',
  'partOfSpeech': 'noun',
  'arabic': 'كلمة',
  'cefr': 'A1',
  'receptive': true,
  'productive': true,
  'meaning': 'word',
  'examples': <Object>[],
  'introducedIn': 'lesson',
  'recycledIn': <String>[],
};

Map<String, dynamic> chunkRecord(String id) => {
  'id': id,
  'text': 'phrase of $id',
  'arabic': 'عبارة',
  'cefr': 'A1',
  'introducedIn': 'lesson',
  'productive': true,
  'recycledIn': <String>[],
};
```

- [ ] **Step 2: Write the failing tests**

Create `test/content/index/course_content_index_prerequisite_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/exceptions.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';

import '../fixtures/minimal_bundle.dart';

CourseContentIndex _index(Map<String, dynamic> json, {CourseContentIndex? prerequisite}) =>
    CourseContentIndex.build(
      CourseBundleParser.parse(jsonEncode(json)),
      prerequisite: prerequisite,
    );

void main() {
  final a1 = _index(
    minimalBundleJson(
      level: 'A1',
      grammar: [grammarRecord('A1.G.BE.I_AM')],
      lexicon: [lexiconRecord('A1.LEX.HOME.N01')],
      chunks: [chunkRecord('A1.CHUNK.GOOD_MORNING')],
    ),
  );

  Map<String, dynamic> a2Reviewing() => minimalBundleJson(
    level: 'A2',
    grammar: [grammarRecord('A2.G.BE_PAST')],
    lessonGrammar: ['A2.G.BE_PAST', 'A1.G.BE.I_AM'],
    lessonLexicon: ['A1.LEX.HOME.N01'],
    lessonChunks: ['A1.CHUNK.GOOD_MORNING'],
  );

  test("an A2 lesson may reference A1's grammar, words and phrases through "
      'its prerequisite', () {
    final a2 = _index(a2Reviewing(), prerequisite: a1);

    expect(a2.prerequisite, same(a1));
    expect(a2.resolveGrammar('A1.G.BE.I_AM')!.id, 'A1.G.BE.I_AM');
    expect(a2.resolveLexicon('A1.LEX.HOME.N01')!.id, 'A1.LEX.HOME.N01');
    expect(a2.resolveChunk('A1.CHUNK.GOOD_MORNING')!.id,
        'A1.CHUNK.GOOD_MORNING');
  });

  test('its own records come first and stay out of the prerequisite', () {
    final a2 = _index(a2Reviewing(), prerequisite: a1);

    expect(a2.resolveGrammar('A2.G.BE_PAST')!.id, 'A2.G.BE_PAST');
    expect(a2.grammarById.keys, ['A2.G.BE_PAST']);
    expect(a1.resolveGrammar('A2.G.BE_PAST'), isNull);
    expect(a2.resolveGrammar('A1.G.NOT_THERE'), isNull);
  });

  test('without its prerequisite the same references are unresolved', () {
    expect(
      () => _index(a2Reviewing()),
      throwsA(isA<UnresolvedContentReferenceException>()),
    );
  });
}
```

Create `test/content/providers/course_content_providers_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/catalog/level_catalog.dart';
import 'package:mohingo/content/providers/bundle_asset_loader.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';

import '../fixtures/minimal_bundle.dart';

class _FakeLoader implements BundleAssetLoader {
  _FakeLoader(this.assets);

  final Map<String, String> assets;
  final loaded = <String>[];

  @override
  Future<String> load(String assetPath) async {
    loaded.add(assetPath);
    return assets[assetPath]!;
  }
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
  LevelCatalogEntry(
    levelId: 'b1',
    cefrCode: 'B1',
    availability: LevelAvailability.comingSoon,
  ),
];

ProviderContainer _container(_FakeLoader loader) {
  final container = ProviderContainer(
    overrides: [
      levelCatalogProvider.overrideWithValue(_catalog),
      bundleAssetLoaderProvider.overrideWithValue(loader),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

_FakeLoader _loader() => _FakeLoader({
  'a1.json': jsonEncode(
    minimalBundleJson(level: 'A1', grammar: [grammarRecord('A1.G.BE.I_AM')]),
  ),
  'a2.json': jsonEncode(
    minimalBundleJson(level: 'A2', lessonGrammar: ['A1.G.BE.I_AM']),
  ),
});

void main() {
  test('a level with a prerequisite loads it first and resolves references '
      'to it', () async {
    final loader = _loader();
    final container = _container(loader);

    final a2 = await container.read(courseContentProvider('a2').future);
    final a1 = await container.read(courseContentProvider('a1').future);

    expect(a2.prerequisite, same(a1));
    expect(a2.resolveGrammar('A1.G.BE.I_AM'), isNotNull);
    expect(loader.loaded, containsAll(['a1.json', 'a2.json']));
  });

  test('a level without a prerequisite has none', () async {
    final container = _container(_loader());
    final a1 = await container.read(courseContentProvider('a1').future);
    expect(a1.prerequisite, isNull);
  });

  test('a level with no content fails with a StateError', () async {
    final container = _container(_loader());
    await expectLater(
      container.read(courseContentProvider('b1').future),
      throwsStateError,
    );
  });
}
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `flutter test test/content/index/course_content_index_prerequisite_test.dart test/content/providers/course_content_providers_test.dart`
Expected: FAIL — `prerequisite:`, `resolveGrammar`, `BundleAssetLoader`, `levelCatalogProvider` don't exist.

- [ ] **Step 4: Implement the index changes**

In `lib/content/index/course_content_index.dart`:

1. Add `required this.prerequisite,` to the private constructor's parameter list.
2. Change the factory signature and doc:

```dart
  /// Builds and validates the index. Throws
  /// [UnresolvedContentReferenceException] if any lesson/activity/unit
  /// references a Can-Do/grammar/lexicon/chunk id that doesn't resolve —
  /// grammar, words and phrases may also resolve in [prerequisite], the
  /// earlier level this one builds on (an A2 lesson reviewing A1's `I am`).
  factory CourseContentIndex.build(
    CourseBundle bundle, {
    CourseContentIndex? prerequisite,
  }) {
```

3. Pass `prerequisite: prerequisite,` in the `CourseContentIndex._(…)` call.
4. Add after `final Map<String, ChunkItem> chunkById;`:

```dart
  /// The earlier level's index, when this level builds on one (A2 on A1) —
  /// see `LevelCatalogEntry.prerequisiteLevelId`. Null for A1.
  final CourseContentIndex? prerequisite;

  /// This level's grammar record [id], or the prerequisite's. The
  /// `*ById` maps hold this level's own records only; use these for ids a
  /// lesson lists, which may point to an earlier level.
  GrammarItem? resolveGrammar(String id) =>
      grammarById[id] ?? prerequisite?.resolveGrammar(id);

  /// See [resolveGrammar].
  LexiconItem? resolveLexicon(String id) =>
      lexiconById[id] ?? prerequisite?.resolveLexicon(id);

  /// See [resolveGrammar].
  ChunkItem? resolveChunk(String id) =>
      chunkById[id] ?? prerequisite?.resolveChunk(id);
```

5. In `_validateReferences`, replace `checkRegistry` and its three calls:

```dart
    void checkRegistry(
      String context,
      Iterable<String> ids,
      Object? Function(String id) resolve,
      String kind,
    ) {
      for (final id in ids) {
        if (resolve(id) == null) {
          errors.add('$context references unknown $kind id "$id"');
        }
      }
    }
```

```dart
        checkRegistry(
          'Lesson ${lesson.id}.grammar',
          lesson.grammar,
          resolveGrammar,
          'grammar',
        );
        checkRegistry(
          'Lesson ${lesson.id}.lexicon',
          lesson.lexicon,
          resolveLexicon,
          'lexicon',
        );
        checkRegistry(
          'Lesson ${lesson.id}.chunks',
          lesson.chunks,
          resolveChunk,
          'chunk',
        );
```

- [ ] **Step 5: Implement the loading changes**

Create `lib/content/providers/bundle_asset_loader.dart`:

```dart
import 'package:flutter/services.dart' show rootBundle;

/// Reads a curriculum bundle asset's raw JSON. The app uses
/// [RootBundleAssetLoader]; tests override `bundleAssetLoaderProvider`
/// with a fake so loading can be exercised without real assets.
abstract interface class BundleAssetLoader {
  Future<String> load(String assetPath);
}

class RootBundleAssetLoader implements BundleAssetLoader {
  const RootBundleAssetLoader();

  @override
  Future<String> load(String assetPath) => rootBundle.loadString(assetPath);
}
```

Replace the body of `lib/content/providers/course_content_providers.dart` (keep the `part 'course_content_providers.g.dart';` line) with:

```dart
import 'dart:isolate';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../catalog/level_catalog.dart';
import '../index/course_content_index.dart';
import '../models/course_bundle.dart';
import '../parsing/course_bundle_parser.dart';
import 'bundle_asset_loader.dart';

part 'course_content_providers.g.dart';

/// The level catalogue ([kLevelCatalog]); overridden in tests.
@Riverpod(keepAlive: true)
List<LevelCatalogEntry> levelCatalog(Ref ref) => kLevelCatalog;

/// Reads bundle assets; overridden in tests.
@Riverpod(keepAlive: true)
BundleAssetLoader bundleAssetLoader(Ref ref) => const RootBundleAssetLoader();

/// Loads, parses (off the UI isolate), and indexes the curriculum bundle for
/// [levelId]. Kept alive so a level's bundle is parsed once, not per screen
/// — see docs/ARCHITECTURE.md's content-loading strategy.
///
/// A level with a `prerequisiteLevelId` (A2 builds on A1) waits for that
/// level's index and is built with it attached, so its lessons can
/// reference the earlier level's grammar, words and phrases.
///
/// A [LevelAvailability.comingSoon] or unknown [levelId] fails fast with a
/// [StateError] — callers should check the catalogue before invoking this
/// provider, not rely on it to report unavailability.
///
/// Failures surface as this provider's [AsyncError]: an
/// `UnsupportedContentSchemaException`/`ContentParseException`/
/// `UnresolvedContentReferenceException` (see `lib/content/models/exceptions.dart`)
/// — the app's content-load route gate distinguishes these to route to the
/// "unsupported content" screen rather than crash.
@Riverpod(keepAlive: true)
Future<CourseContentIndex> courseContent(Ref ref, String levelId) async {
  final entry = levelCatalogEntryIn(ref.watch(levelCatalogProvider), levelId);
  if (entry == null || entry.availability != LevelAvailability.available) {
    throw StateError('Level "$levelId" has no content bundle to load');
  }
  final loader = ref.watch(bundleAssetLoaderProvider);
  final prerequisiteId = entry.prerequisiteLevelId;
  final prerequisiteFuture = prerequisiteId == null
      ? null
      : ref.watch(courseContentProvider(prerequisiteId).future);

  final rawJson = await loader.load(entry.bundleAssetPath!);
  if (prerequisiteFuture == null) {
    return Isolate.run(
      () => CourseContentIndex.build(CourseBundleParser.parse(rawJson)),
    );
  }
  final prerequisite = await prerequisiteFuture;
  final CourseBundle bundle = await Isolate.run(
    () => CourseBundleParser.parse(rawJson),
  );
  return CourseContentIndex.build(bundle, prerequisite: prerequisite);
}
```

(The prerequisite's index is attached on the UI isolate because an index is built once and never sent anywhere; only parsing, the expensive part, runs off it.)

Regenerate: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 6: Run the tests to verify they pass**

Run: `flutter test test/content/`
Expected: PASS — the new tests and every existing content test (the real A1 bundle still builds with no prerequisite).

- [ ] **Step 7: Commit**

```bash
git add lib/content/ test/content/
git commit -m "feat: build a level on its prerequisite and resolve earlier-level references

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Screens that open one item use that item's level

**Files:**
- Modify: `lib/content/providers/course_content_providers.dart` (+ `.g.dart`)
- Modify: `lib/features/learning_path/presentation/unit_overview_screen.dart:44`, `lib/features/lesson_player/presentation/lesson_player_screen.dart:72,97-98`, `lib/features/lesson_player/presentation/lesson_review_screen.dart:102`, `lib/features/vocabulary/presentation/word_detail_screen.dart:19`, `lib/features/vocabulary/presentation/chunk_detail_screen.dart:16`, `lib/features/grammar/presentation/grammar_detail_screen.dart:33`, `lib/features/review/presentation/quick_practice_screen.dart:140`, `lib/features/learning_path/providers/unit_progress_providers.dart:87`, `lib/features/activity_engine/providers/online_refinement_providers.dart:133`
- Modify (fixture ids): `test/features/lesson_player/lesson_player_resume_test.dart`
- Test: `test/content/providers/course_content_providers_test.dart`

**Interfaces:**
- Consumes: `levelIdOfContentId` (Task 2); `resolveChunk`, `resolveGrammar` (Task 4).
- Produces: `contentIndexForIdProvider(String contentId)` → `Future<CourseContentIndex>`, keep-alive.

- [ ] **Step 1: Write the failing tests**

Add to `test/content/providers/course_content_providers_test.dart`, inside `main()`:

```dart
  test('an item opens in the level its id belongs to', () async {
    final container = _container(_loader());

    final forUnit = await container.read(
      contentIndexForIdProvider('A2-U1').future,
    );
    final forGrammar = await container.read(
      contentIndexForIdProvider('A1.G.BE.I_AM').future,
    );

    expect(forUnit, same(await container.read(courseContentProvider('a2').future)));
    expect(
      forGrammar,
      same(await container.read(courseContentProvider('a1').future)),
    );
  });

  test('an id with no level prefix fails with a StateError', () async {
    final container = _container(_loader());
    await expectLater(
      container.read(contentIndexForIdProvider('TEST-U1').future),
      throwsStateError,
    );
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/content/providers/course_content_providers_test.dart`
Expected: FAIL — `contentIndexForIdProvider` isn't defined.

- [ ] **Step 3: Implement the provider**

Add to `lib/content/providers/course_content_providers.dart` (and `import '../catalog/content_level.dart';`):

```dart
/// The index of the level [contentId] belongs to — for a screen that opens
/// one unit, lesson, activity, word, phrase or grammar point, so it shows
/// the right level without being told it. See [levelIdOfContentId].
///
/// Kept alive: it only hands on the already kept-alive level index, and
/// callers that `read` it from a callback (the refinement drain) must not
/// see it disposed mid-load.
@Riverpod(keepAlive: true)
Future<CourseContentIndex> contentIndexForId(
  Ref ref,
  String contentId,
) async {
  final levelId = levelIdOfContentId(contentId);
  if (levelId == null) {
    throw StateError('"$contentId" has no level prefix');
  }
  return ref.watch(courseContentProvider(levelId).future);
}
```

Regenerate: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: Run the provider tests to verify they pass**

Run: `flutter test test/content/providers/course_content_providers_test.dart`
Expected: PASS.

- [ ] **Step 5: Move the item screens onto it**

Make exactly these replacements (each file already imports `course_content_providers.dart`):

| File | Replace | With |
|---|---|---|
| `unit_overview_screen.dart` | `ref.watch(courseContentProvider('a1'))` | `ref.watch(contentIndexForIdProvider(unitId))` |
| `lesson_player_screen.dart` | `ref.watch(courseContentProvider('a1'))` | `ref.watch(contentIndexForIdProvider(lessonId))` |
| `lesson_player_screen.dart` | `phrases: [for (final id in lesson.chunks) ?index.chunkById[id]],` | `phrases: [for (final id in lesson.chunks) ?index.resolveChunk(id)],` |
| `lesson_player_screen.dart` | `grammar: [for (final id in lesson.grammar) ?index.grammarById[id]],` | `grammar: [for (final id in lesson.grammar) ?index.resolveGrammar(id)],` |
| `lesson_review_screen.dart` | `ref.watch(courseContentProvider('a1'))` | `ref.watch(contentIndexForIdProvider(lessonId))` |
| `word_detail_screen.dart` | `ref.watch(courseContentProvider('a1'))` | `ref.watch(contentIndexForIdProvider(lexiconId))` |
| `chunk_detail_screen.dart` | `ref.watch(courseContentProvider('a1'))` | `ref.watch(contentIndexForIdProvider(chunkId))` |
| `grammar_detail_screen.dart` | `ref.watch(courseContentProvider('a1'))` | `ref.watch(contentIndexForIdProvider(grammarId))` |
| `unit_progress_providers.dart` | `await ref.watch(courseContentProvider('a1').future)` | `await ref.watch(contentIndexForIdProvider(params.unitId).future)` |
| `online_refinement_providers.dart` | `await ref.read(courseContentProvider('a1').future)` | `await ref.read(contentIndexForIdProvider(unitId).future)` |

In `quick_practice_screen.dart`'s `_summary`, replace

```dart
    final index = ref.watch(courseContentProvider('a1')).value;
    final lesson = widget.set.lesson;
```

with

```dart
    final lesson = widget.set.lesson;
    final index = lesson == null
        ? null
        : ref.watch(contentIndexForIdProvider(lesson.id)).value;
```

In `test/features/lesson_player/lesson_player_resume_test.dart`, give the fixture's unit and lessons a level prefix, as every real id has — replace every `'TEST-U1` with `'A1-TEST-U1` (this covers `TEST-U1`, `TEST-U1-L1` and `TEST-U1-L2`; leave `TEST-1`, `TEST-FINAL-MISSION`, `TEST-FINAL-ASSESSMENT` alone):

```bash
sed -i "s/'TEST-U1/'A1-TEST-U1/g" test/features/lesson_player/lesson_player_resume_test.dart
```

- [ ] **Step 6: Run the affected tests**

Run: `flutter test test/features/learning_path/ test/features/lesson_player/ test/features/vocabulary/ test/features/grammar/ test/features/review/ test/features/activity_engine/providers/`
Expected: PASS — these screens' tests override `courseContentProvider('a1')`, which `contentIndexForIdProvider` reads through.

- [ ] **Step 7: Commit**

```bash
git add lib/ test/
git commit -m "feat: open units, lessons, words and grammar in their own level

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Show the text a question is about

Fixes A1: 27 reading questions whose `sourceText` was never shown, and the final assessment's mediation cards.

**Files:**
- Create: `lib/features/activity_engine/presentation/widgets/activity_source_card.dart`
- Modify: `lib/features/activity_engine/presentation/activity_chrome.dart`, `views/choice_activity_view.dart`, `views/write_activity_view.dart`, `views/speak_activity_view.dart`
- Test: `test/features/activity_engine/choice_activity_view_test.dart`, `test/features/activity_engine/write_activity_view_test.dart`, `test/features/activity_engine/speak_activity_view_test.dart`

**Interfaces:**
- Consumes: `Activity.sourceCard` (Task 3), `TextChoiceActivity.sourceText` (existing).
- Produces: `ActivitySourceCard({required String text})`; `ActivityChrome(source: String?)`.

- [ ] **Step 1: Write the failing tests**

Add to `test/features/activity_engine/choice_activity_view_test.dart` (add imports `package:mohingo/features/activity_engine/presentation/activity_chrome.dart` and `package:mohingo/features/activity_engine/presentation/widgets/activity_source_card.dart`):

```dart
  TextChoiceActivity readingQuestion() => const TextChoiceActivity(
    id: 'A1-U4-L7-A02',
    lessonId: 'A1-U4-L7',
    mode: ActivityMode.mastery,
    skill: Skill.reading,
    canDo: [],
    prompt: 'Choose the correct comparison.',
    promptAr: 'اختر المقارنة الصحيحة.',
    raw: {},
    options: ['Rana starts earlier.', 'Hassan starts earlier.'],
    answer: 'Rana starts earlier.',
    sourceText: 'Rana gets up at 6:30. Hassan gets up at 7:00.',
  );

  testWidgets('a reading question shows the text it asks about, left to '
      'right even in Arabic', (tester) async {
    await tester.pumpActivityView(
      ChoiceActivityView.textChoice(
        activity: readingQuestion(),
        onSubmitted: (_) {},
      ),
      locale: const Locale('ar'),
    );

    expect(find.byType(ActivitySourceCard), findsOneWidget);
    final text = tester.widget<Text>(
      find.text('Rana gets up at 6:30. Hassan gets up at 7:00.'),
    );
    expect(text.textDirection, TextDirection.ltr);
  });

  testWidgets('a test that hides marking still shows the text', (
    tester,
  ) async {
    await tester.pumpActivityView(
      ActivityFrameScope(
        onContinue: () {},
        testMode: true,
        child: ChoiceActivityView.textChoice(
          activity: readingQuestion(),
          onSubmitted: (_) {},
        ),
      ),
    );

    expect(
      find.text('Rana gets up at 6:30. Hassan gets up at 7:00.'),
      findsOneWidget,
    );
  });
```

Add to `test/features/activity_engine/write_activity_view_test.dart`:

```dart
  testWidgets('a mediation write shows its source card', (tester) async {
    await tester.pumpActivityView(
      WriteActivityView(
        activity: const WriteActivity(
          id: 'A1-FINAL-ASSESS-M02',
          lessonId: null,
          mode: ActivityMode.mastery,
          skill: Skill.mediation,
          canDo: [],
          prompt: 'Relay the clinic notice.',
          promptAr: 'انقل ملاحظة العيادة.',
          raw: {'sourceCard': 'Clinic B, 2nd floor. Appointment 14:30.'},
          accepted: [],
        ),
        learnerId: 1,
        onSubmitted: (_) {},
      ),
    );

    expect(
      find.text('Clinic B, 2nd floor. Appointment 14:30.'),
      findsOneWidget,
    );
  });
```

Add to `test/features/activity_engine/speak_activity_view_test.dart`, inside `main()`:

```dart
  testWidgets('a mediation speak shows its source card', (tester) async {
    await _pumpSpeak(
      tester,
      capabilities: const DeviceSpeechCapabilities(
        sttAvailableForLocale: false,
        micPermission: SpeechPermissionStatus.notDetermined,
      ),
      activity: const SpeakActivity(
        id: 'A1-FINAL-ASSESS-M01',
        lessonId: null,
        mode: ActivityMode.mastery,
        skill: Skill.mediation,
        canDo: [],
        prompt: 'Tell a friend the journey.',
        promptAr: 'أخبر صديقك بالرحلة.',
        raw: {'sourceCard': 'Bus 14 — 08:00 to Central.'},
        accepted: [],
        fallbackSkill: 'writing',
      ),
    );

    expect(find.text('Bus 14 — 08:00 to Central.'), findsOneWidget);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/activity_engine/choice_activity_view_test.dart test/features/activity_engine/write_activity_view_test.dart test/features/activity_engine/speak_activity_view_test.dart`
Expected: FAIL — `ActivitySourceCard` doesn't exist; no source text rendered.

- [ ] **Step 3: Implement**

Create `lib/features/activity_engine/presentation/widgets/activity_source_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';

/// The text a question is about — a message, a notice, a menu, two short
/// profiles — shown between the prompt and the answers. English content,
/// so always left-to-right, starting at the layout's start edge in either
/// interface language. Shown in test mode too: it is the question's input,
/// not its answer.
class ActivitySourceCard extends StatelessWidget {
  const ActivitySourceCard({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            text,
            textDirection: TextDirection.ltr,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: tokens.textPrimary,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }
}
```

In `activity_chrome.dart`: import `'widgets/activity_source_card.dart'`; add `this.source,` to `ActivityChrome`'s constructor after `this.promptAr,`; add the field with a doc comment:

```dart
  /// The text the question is about ([ActivitySourceCard]) — a reading
  /// question's passage, a mediation task's notice. Null for none.
  final String? source;
```

and in `build`, directly before `if (help != null) ...[`, add:

```dart
        if (source != null) ...[
          const SizedBox(height: AppSpace.sm),
          ActivitySourceCard(text: source!),
        ],
```

In `choice_activity_view.dart`: in `ChoiceActivityView.audioChoice`'s initializer list add `source = activity.sourceCard,`; in `ChoiceActivityView.textChoice`'s add `source = activity.sourceText ?? activity.sourceCard,`; add the field `final String? source;` after `final String? audioTranscript;`; and in `build` add `source: widget.source,` after `promptAr: widget.promptAr,` in the `ActivityChrome(...)` call.

In `write_activity_view.dart` and `speak_activity_view.dart`, add `source: widget.activity.sourceCard,` after `promptAr: widget.activity.promptAr,` in their `ActivityChrome(...)` calls.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/activity_engine/ test/features/tests_home/ test/features/lesson_player/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/activity_engine/ test/features/activity_engine/
git commit -m "fix: show the text a reading or mediation question is about

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: Speaking tasks read the other person's lines aloud

Fixes A1's `A1-FINAL-ASSESS-S02` ("Respond to four short examiner turns"), whose turns were never played.

**Files:**
- Create: `lib/features/activity_engine/presentation/widgets/activity_partner_turns_card.dart`
- Modify: `lib/features/activity_engine/presentation/views/speak_activity_view.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb` (+ generated l10n)
- Test: `test/features/activity_engine/speak_activity_view_test.dart`

**Interfaces:**
- Consumes: `SpeakActivity.partnerTurns` (Task 3).
- Produces: `ActivityPartnerTurnsCard({required List<String> turns, bool autoPlay = true})`; l10n `speakPartnerTitle`, `speakPartnerPlay`.

- [ ] **Step 1: Write the failing tests**

Add to `test/features/activity_engine/speak_activity_view_test.dart` (imports: `package:mohingo/core/preferences/shared_preferences_provider.dart`, `package:mohingo/features/activity_engine/presentation/widgets/activity_partner_turns_card.dart`, `package:shared_preferences/shared_preferences.dart`; `ActivityAttempt` is already importable from `database.dart`):

```dart
  SpeakActivity partnerSpeak() => const SpeakActivity(
    id: 'A1-FINAL-ASSESS-S02',
    lessonId: null,
    mode: ActivityMode.mastery,
    skill: Skill.spokenInteraction,
    canDo: [],
    prompt: 'Respond to each turn.',
    promptAr: 'ردّ على كل جملة.',
    raw: {
      'examinerTurns': ['Good morning.', 'What time do you start your day?'],
    },
    accepted: [],
    fallbackSkill: 'writing',
  );

  Future<FakeTextToSpeechService> pumpPartner(
    WidgetTester tester, {
    ActivityAttempt? reviewAttempt,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final tts = FakeTextToSpeechService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          speechCapabilityServiceProvider.overrideWithValue(
            FakeSpeechCapabilityService(
              const DeviceSpeechCapabilities(
                sttAvailableForLocale: false,
                micPermission: SpeechPermissionStatus.notDetermined,
              ),
            ),
          ),
          speechRecognitionServiceProvider.overrideWithValue(
            FakeSpeechRecognitionService(),
          ),
          textToSpeechServiceProvider.overrideWithValue(tts),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppColorSeed.calmTeal),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SpeakActivityView(
              activity: partnerSpeak(),
              learnerId: 1,
              onSubmitted: (_) {},
              reviewAttempt: reviewAttempt,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tts;
  }

  testWidgets("the other person's lines are shown and read aloud in order "
      'when the question opens', (tester) async {
    final tts = await pumpPartner(tester);

    expect(find.byType(ActivityPartnerTurnsCard), findsOneWidget);
    expect(find.text('Good morning.'), findsOneWidget);
    expect(find.text('What time do you start your day?'), findsOneWidget);
    expect(tts.spoken, ['Good morning.', 'What time do you start your day?']);
  });

  testWidgets('the lines can be heard again', (tester) async {
    final tts = await pumpPartner(tester);
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;

    await tester.tap(find.byTooltip(l10n.speakPartnerPlay));
    await tester.pumpAndSettle();

    expect(tts.spoken, hasLength(4));
  });

  testWidgets('reviewing an old answer never plays the lines by itself', (
    tester,
  ) async {
    final tts = await pumpPartner(
      tester,
      reviewAttempt: ActivityAttempt(
        id: 1,
        uuid: 'attempt-1',
        learnerId: 1,
        activityId: 'A1-FINAL-ASSESS-S02',
        sessionType: 'finalAssessment',
        mode: 'mastery',
        evidenceSkill: 'spokenInteraction',
        rawAnswer: jsonEncode('Good morning to you.'),
        isCorrect: null,
        score: null,
        wasFallback: false,
        attemptedAt: DateTime.utc(2026, 9, 19),
        updatedAt: DateTime.utc(2026, 9, 19),
      ),
    );

    expect(find.text('Good morning.'), findsOneWidget);
    expect(tts.spoken, isEmpty);
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/activity_engine/speak_activity_view_test.dart`
Expected: FAIL — `ActivityPartnerTurnsCard` and `speakPartnerPlay` don't exist.

- [ ] **Step 3: Add the strings**

Add to the end of `lib/l10n/app_en.arb` (put a comma after the current last entry):

```json
  "speakPartnerTitle": "The other person says",
  "@speakPartnerTitle": {"description": "Heading of the card on a speaking question that shows what the other person says before the learner answers."},
  "speakPartnerPlay": "Hear it again",
  "@speakPartnerPlay": {"description": "Accessibility label of the button that reads the other person's lines aloud again."}
```

Add to the end of `lib/l10n/app_ar.arb`:

```json
  "speakPartnerTitle": "يقول الطرف الآخر",
  "speakPartnerPlay": "استمع مرة أخرى"
```

Run: `flutter gen-l10n`

- [ ] **Step 4: Implement the card**

Create `lib/features/activity_engine/presentation/widgets/activity_partner_turns_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../speech/domain/text_to_speech_service.dart';
import '../../../speech/providers/speech_providers.dart';
import '../../../speech/providers/tts_preferences_provider.dart';

/// What the other person in a speaking task says, before the learner
/// answers: each line in English, read aloud in order when the question
/// opens (never in answer review — see [autoPlay]), with a button to hear
/// them again. Spoken interaction means responding to someone; this is the
/// someone. Shown in test mode too: it's the task's input, not its answer.
class ActivityPartnerTurnsCard extends ConsumerStatefulWidget {
  const ActivityPartnerTurnsCard({
    required this.turns,
    this.autoPlay = true,
    super.key,
  });

  final List<String> turns;

  /// False on a review screen, which can show several at once and where
  /// nothing is being asked right now.
  final bool autoPlay;

  @override
  ConsumerState<ActivityPartnerTurnsCard> createState() =>
      _ActivityPartnerTurnsCardState();
}

class _ActivityPartnerTurnsCardState
    extends ConsumerState<ActivityPartnerTurnsCard> {
  late final TextToSpeechService _tts = ref.read(textToSpeechServiceProvider);
  bool _playing = false;

  /// Bumped to cancel a reading in progress — a newer request wins.
  int _playToken = 0;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _play();
      });
    }
  }

  @override
  void dispose() {
    _playToken++;
    if (_playing) _tts.stop();
    super.dispose();
  }

  Future<void> _play() async {
    final token = ++_playToken;
    if (_playing) await _tts.stop();
    setState(() => _playing = true);
    final rate = ref.read(ttsRatePreferenceProvider);
    final pitch = ref.read(ttsPitchPreferenceProvider);
    for (final turn in widget.turns) {
      if (!mounted || token != _playToken) return;
      await _tts.speak(turn, localeCode: 'en', rate: rate, pitch: pitch);
    }
    if (mounted && token == _playToken) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpace.md,
          AppSpace.xs,
          AppSpace.xs,
          AppSpace.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.speakPartnerTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _play,
                  tooltip: l10n.speakPartnerPlay,
                  icon: Icon(
                    _playing ? Icons.volume_up : Icons.volume_up_outlined,
                  ),
                ),
              ],
            ),
            for (final turn in widget.turns) ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  turn,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xxs),
            ],
          ],
        ),
      ),
    );
  }
}
```

In `speak_activity_view.dart`: import `'../widgets/activity_partner_turns_card.dart'`, and replace the `help:` argument of `ActivityChrome` with:

```dart
      help: _help(l10n, theme, tokens),
```

adding this method to `_SpeakActivityViewState`:

```dart
  /// The other person's lines, when the task has any, then — in the typed
  /// fallback, before submission — why the learner is typing.
  Widget? _help(AppLocalizations l10n, ThemeData theme, AppTokens tokens) {
    final turns = widget.activity.partnerTurns;
    final fallbackNote = _mode == _SpeakMode.typedFallback && _submission == null
        ? Text(
            _capabilities?.micPermission ==
                    SpeechPermissionStatus.permanentlyDenied
                ? l10n.speakPermissionPermanentlyDenied
                : l10n.activitySpeechUnavailableUseWriting,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.textSecondary,
            ),
          )
        : null;
    if (turns.isEmpty) return fallbackNote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActivityPartnerTurnsCard(
          turns: turns,
          autoPlay: widget.reviewAttempt == null,
        ),
        if (fallbackNote != null) ...[
          const SizedBox(height: AppSpace.sm),
          fallbackNote,
        ],
      ],
    );
  }
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/features/activity_engine/ test/features/tests_home/`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/ test/features/activity_engine/
git commit -m "feat: read the other person's lines aloud on speaking tasks

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: Complete the Arabic of A1's lesson texts

The 11 A1 `readingText.textAr` values are stubs that stop after a few words. Task 9 starts showing them, so they must be whole first.

**Files:**
- Modify: `assets/content/en/A1/a1-course-bundle.json`
- Test: `test/content/a1_content_quality_test.dart`

- [ ] **Step 1: Write the failing test**

Add to `test/content/a1_content_quality_test.dart`, inside `main()`:

```dart
  test('every lesson text carries its whole Arabic, not a stub', () {
    bool isStub(String? ar) {
      final text = ar?.trim() ?? '';
      return text.isEmpty || text.endsWith('...') || text.endsWith('…');
    }

    final offenders = [
      for (final unit in _bundle['units'] as List)
        for (final lesson in (unit as Map)['lessons'] as List)
          if ((lesson as Map)['readingText'] case final Map reading)
            if (isStub(reading['textAr'] as String?)) lesson['id'],
    ];
    expect(offenders, isEmpty);
  });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/content/a1_content_quality_test.dart`
Expected: FAIL listing `A1-U2-L6` … `A1-U12-L6` (11 lessons).

- [ ] **Step 3: Replace the 11 stubs**

In `assets/content/en/A1/a1-course-bundle.json`, make these exact string replacements with the Edit tool (each old value occurs exactly once; do not reformat the file):

| Lesson | Old `textAr` | New `textAr` |
|---|---|---|
| A1-U2-L6 | `اسمي مايا. لدي أخ وأخت...` | `اسمي مايا. لديّ أخ واحد وأخت واحدة. اسم أخي كريم، وعمره عشرون عامًا. إنه هادئ لكنه ودود. أختي نور عمرها ثمانية عشر عامًا، وهي لطيفة ومرحة. نعيش في كركوك.` |
| A1-U3-L6 | `أسكن في شقة صغيرة...` | `أسكن في شقة صغيرة. فيها غرفة نوم واحدة وغرفة معيشة ومطبخ وحمّام. غرفة المعيشة صغيرة لكنها نظيفة. هناك أريكة بجانب النافذة، وعلى الحائط لوحتان. أحبّ بيتي.` |
| A1-U4-L6 | `صباحان مختلفان...` | `تستيقظ مايا في السادسة والنصف وتبدأ عملها في الثامنة. ويستيقظ عمر في السابعة والنصف ويبدأ عمله في التاسعة. مايا تتناول الفطور دائمًا، أما عمر فيتناوله أحيانًا.` |
| A1-U5-L6 | `مرحباً سارة...` | `مرحبًا سارة. وقتي فارغ بعد ظهر يوم السبت. أحبّ المشي والتقاط الصور. هل تودّين أن نلتقي في الحديقة الساعة الرابعة؟ لا أستطيع البقاء بعد السادسة. أرسلي لي رسالة من فضلك.` |
| A1-U6-L6 | `قائمة مقهى الحديقة...` | `الفطور: شطيرة بيض — 3,000 دينار. الغداء: دجاج مع رز — 7,000 دينار. شوربة — 3,500 دينار. المشروبات: شاي — 1,000 دينار؛ ماء — 500 دينار؛ عصير — 1,500 دينار.` |
| A1-U7-L6 | `تخفيضات نهاية الأسبوع...` | `قمصان بيضاء: 12 دولارًا. قمصان زرقاء: 15 دولارًا. بناطيل سوداء: 18 دولارًا. حقائب حمراء صغيرة: 10 دولارات. حقائب سوداء كبيرة: 22 دولارًا. نقبل الدفع بالبطاقة ونقدًا.` |
| A1-U8-L6 | `اعثر على مكتبنا...` | `ابدأ من المحطة. امشِ مباشرة في شارع بارك. انعطف يسارًا عند البنك، ثم تجاوز المقهى. مكتبنا بين الصيدلية والمكتبة. ادخل من المدخل الأزرق.` |
| A1-U9-L6 | `مسار المطار...` | `تغادر الحافلة رقم 20 محطة المدينة الساعة 07:30 وتصل إلى المحطة المركزية الساعة 08:00. بدّل هناك إلى قطار المطار A من الرصيف رقم 5. يغادر الساعة 08:15 ويصل إلى المطار الساعة 08:45. السعر الإجمالي: 6 دولارات.` |
| A1-U10-L6 | `ملاحظة للعيادة...` | `الاسم: سامي كريم. عندي سعال وألم في الحلق. أشعر بالتعب، لكن ليست عندي حمّى. بدأت الأعراض هذا الصباح. أستطيع الحضور بعد الساعة 4:00. أرجو تأكيد موعد لي.` |
| A1-U11-L6 | `رسالة من داليا...` | `مرحبًا! الجو مشمس ودافئ في أربيل اليوم، ونحن جالسون في الخارج في مقهى. سيكون الجو غدًا أبرد مع رياح، لذلك سآخذ سترتي. هل الطقس جميل عندكم؟` |
| A1-U12-L6 | `خطة ليوم السبت...` | `مرحبًا داليا. سأزور سوق المدينة الجديد صباح يوم السبت. هل تودّين المجيء معي؟ يمكننا أن نلتقي عند موقف الحافلات الساعة 9:00. قد يكون الجو ممطرًا، لذا أحضري مظلة من فضلك. هل تناسبك الساعة التاسعة؟` |

- [ ] **Step 4: Run the content tests**

Run: `flutter test test/content/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add assets/content/en/A1/a1-course-bundle.json test/content/a1_content_quality_test.dart
git commit -m "content: write out the Arabic of A1's lesson texts

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 9: The lesson player shows a lesson's model text

**Files:**
- Create: `lib/features/lesson_player/presentation/widgets/lesson_reading_step.dart`
- Modify: `lib/features/lesson_player/presentation/lesson_player_screen.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb` (+ generated), `test/features/lesson_player/lesson_player_test_helpers.dart`, `test/features/lesson_player/lesson_player_e2e_test.dart`
- Test: `test/features/lesson_player/lesson_intro_test.dart`

**Interfaces:**
- Consumes: `Lesson.readingText` (Task 3).
- Produces: `LessonReadingStep({required String overline, required String title, required String titleAr, required LessonReadingText reading, required String continueLabel, required VoidCallback onContinue})`; l10n `lessonIntroReadTitle`.

- [ ] **Step 1: Write the failing test**

Add to `test/features/lesson_player/lesson_intro_test.dart` (import `package:mohingo/features/lesson_player/presentation/widgets/lesson_reading_step.dart`), inside `main()`:

```dart
  testWidgets('a lesson built around a text opens on it — its title, the '
      'English and its Arabic, which the switch hides — then key phrases, '
      'then the first question', (tester) async {
    await _pumpPlayer(tester, unitId: 'A1-U2', lessonId: 'A1-U2-L6');

    expect(find.byType(LessonReadingStep), findsOneWidget);
    expect(find.text('A People Profile'), findsOneWidget);
    expect(find.text("Maya's Family"), findsOneWidget);
    expect(find.textContaining('My name is Maya.'), findsOneWidget);
    expect(find.textContaining('اسمي مايا.'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.textContaining('اسمي مايا.'), findsNothing);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byType(LessonKeyPhrasesStep), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityChrome), findsOneWidget);
  });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/lesson_player/lesson_intro_test.dart`
Expected: FAIL — `LessonReadingStep` doesn't exist.

- [ ] **Step 3: Add the string**

`lib/l10n/app_en.arb` (end of file, comma after the previous entry):

```json
  "lessonIntroReadTitle": "Read the text",
  "@lessonIntroReadTitle": {"description": "Title of the card holding a lesson's model text (a message, a menu, a profile) in the lesson intro."}
```

`lib/l10n/app_ar.arb`:

```json
  "lessonIntroReadTitle": "اقرأ النص"
```

Run: `flutter gen-l10n`

- [ ] **Step 4: Implement the step**

Create `lib/features/lesson_player/presentation/widgets/lesson_reading_step.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../content/models/curriculum_structure.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../speech/presentation/listen_button.dart';
import 'lesson_intro_chrome.dart';

/// A lesson-intro screen for a lesson built around a text — a message, a
/// menu, a profile — that its questions are about: the lesson title, then
/// the text's own title and the English (left-to-right) with a button to
/// hear it, and its Arabic behind a switch, on by default. Not read aloud
/// by itself: it's there to be read.
class LessonReadingStep extends StatefulWidget {
  const LessonReadingStep({
    required this.overline,
    required this.title,
    required this.titleAr,
    required this.reading,
    required this.continueLabel,
    required this.onContinue,
    super.key,
  });

  final String overline;

  /// The lesson's title, in English and Arabic.
  final String title;
  final String titleAr;
  final LessonReadingText reading;
  final String continueLabel;
  final VoidCallback onContinue;

  @override
  State<LessonReadingStep> createState() => _LessonReadingStepState();
}

class _LessonReadingStepState extends State<LessonReadingStep> {
  bool _showArabic = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final reading = widget.reading;
    final textAr = reading.textAr;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.xs,
              AppSpace.md,
              AppSpace.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LessonIntroHeader(
                  overline: widget.overline,
                  title: widget.title,
                  titleAr: widget.titleAr,
                ),
                const SizedBox(height: AppSpace.md),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.card,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: tokens.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpace.md,
                      AppSpace.xs,
                      AppSpace.xs,
                      AppSpace.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.lessonIntroReadTitle,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ),
                            ListenButton(text: reading.text),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            end: AppSpace.xs,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                reading.title,
                                textDirection: TextDirection.ltr,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: tokens.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpace.xs),
                              Text(
                                reading.text,
                                textDirection: TextDirection.ltr,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: tokens.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                              if (textAr != null && _showArabic) ...[
                                const SizedBox(height: AppSpace.sm),
                                Text(
                                  textAr,
                                  textDirection: TextDirection.rtl,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: tokens.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (textAr != null) ...[
                  const SizedBox(height: AppSpace.xs),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.lessonIntroArabicToggle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Switch(
                        value: _showArabic,
                        onChanged: (value) =>
                            setState(() => _showArabic = value),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        LessonActionBar(
          label: widget.continueLabel,
          onPressed: widget.onContinue,
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Put it in the lesson player's intro**

In `lesson_player_screen.dart`: import `'widgets/lesson_reading_step.dart'`; add at file level (below the imports):

```dart
/// The lesson player's intro screens, in the order they appear.
enum _IntroStep { conversation, reading, keyPhrases }
```

replace the `_introCount` field and its doc comment with:

```dart
  /// The lesson's intro screens, in order: its conversation, its model
  /// text, then key phrases — the last only after a conversation or a
  /// text, and only when there are phrases or grammar to show.
  late final List<_IntroStep> _introSteps = [
    if (widget.lesson.encounterDialogue.isNotEmpty) _IntroStep.conversation,
    if (widget.lesson.readingText != null) _IntroStep.reading,
    if ((widget.lesson.encounterDialogue.isNotEmpty ||
            widget.lesson.readingText != null) &&
        (widget.phrases.isNotEmpty || widget.grammar.isNotEmpty))
      _IntroStep.keyPhrases,
  ];

  /// How many intro screens this lesson has (see [_introSteps]).
  late final int _introCount = _introSteps.length;
```

update the `_introIndex` doc comment to `/// The intro screen showing (an index into [_introSteps]), or null once the activities have started.`, and replace the `return introIndex == 0 ? LessonConversationStep(…) : LessonKeyPhrasesStep(…);` expression in `_buildIntro` with:

```dart
    return switch (_introSteps[introIndex]) {
      _IntroStep.conversation => LessonConversationStep(
        key: const ValueKey('intro-conversation'),
        overline: overline,
        title: lesson.title,
        titleAr: lesson.titleAr,
        lines: lesson.encounterDialogue,
        sceneAr:
            (lesson.raw['encounter'] as Map<String, dynamic>?)?['sceneAr']
                as String?,
        continueLabel: continueLabel,
        onContinue: onContinue,
      ),
      _IntroStep.reading => LessonReadingStep(
        key: const ValueKey('intro-reading'),
        overline: overline,
        title: lesson.title,
        titleAr: lesson.titleAr,
        reading: lesson.readingText!,
        continueLabel: continueLabel,
        onContinue: onContinue,
      ),
      _IntroStep.keyPhrases => LessonKeyPhrasesStep(
        key: const ValueKey('intro-key-phrases'),
        overline: overline,
        lessonId: lesson.id,
        phrases: widget.phrases,
        grammar: widget.grammar,
        continueLabel: continueLabel,
        onContinue: onContinue,
      ),
    };
```

- [ ] **Step 6: Teach the tests about the new intro screen**

In `test/features/lesson_player/lesson_player_test_helpers.dart`: import `package:mohingo/features/lesson_player/presentation/widgets/lesson_reading_step.dart`, update the doc comment to "…the conversation or text, then key phrases…", and extend the loop condition:

```dart
  while (find.byType(LessonConversationStep).evaluate().isNotEmpty ||
      find.byType(LessonReadingStep).evaluate().isNotEmpty ||
      find.byType(LessonKeyPhrasesStep).evaluate().isNotEmpty) {
```

In `test/features/lesson_player/lesson_player_e2e_test.dart`, the two tests that open `A1-U5-L6` from its start ("an onlineRefinement activity is queued in pending_online_refinements…" and the drain-while-online test) now land on its text: in each, directly after the `await tester.pumpAndSettle();` that follows `pumpWidget(...)`, add

```dart
      await passLessonIntro(tester);
```

- [ ] **Step 7: Run the tests to verify they pass**

Run: `flutter test test/features/lesson_player/`
Expected: PASS — including the existing "a lesson without a conversation starts on its first question" (`A1-U1-L4` has no text either).

- [ ] **Step 8: Commit**

```bash
git add lib/ test/features/lesson_player/
git commit -m "feat: open text-based lessons on their text

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 10: Mark earlier-level items "From A1", and name A2's text-based lesson type

**Files:**
- Modify: `lib/features/lesson_player/presentation/widgets/lesson_key_phrases_step.dart`, `lib/core/l10n/lesson_type_label.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb` (+ generated)
- Test: `test/features/lesson_player/lesson_key_phrases_step_test.dart` (new), `test/core/l10n/lesson_type_label_test.dart` (new)

**Interfaces:**
- Consumes: `levelIdOfContentId` (Task 2).
- Produces: l10n `lessonIntroFromLevel(String level)`, `homeLessonTypeIntegrated`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/lesson_player/lesson_key_phrases_step_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/registry_items.dart';
import 'package:mohingo/features/lesson_player/presentation/widgets/lesson_key_phrases_step.dart';

import '../activity_engine/test_harness.dart';

void main() {
  testWidgets("an A2 lesson's own new phrase is NEW; phrases and grammar it "
      'reviews from A1 say so', (tester) async {
    await tester.pumpActivityView(
      LessonKeyPhrasesStep(
        overline: 'Unit 1 · Lesson 1',
        lessonId: 'A2-U1-L1',
        phrases: const [
          ChunkItem(
            id: 'A2.CHUNK.ON_WEEKDAYS',
            text: 'on weekdays',
            arabic: 'في أيام العمل',
            cefr: 'A2',
            introducedIn: 'A2-U1-L1',
            productive: true,
            recycledIn: [],
          ),
          ChunkItem(
            id: 'A1.CHUNK.GOOD_MORNING',
            text: 'Good morning.',
            arabic: 'صباح الخير.',
            cefr: 'A1',
            introducedIn: 'A1-U0-L1',
            productive: true,
            recycledIn: [],
          ),
        ],
        grammar: const [
          GrammarItem(
            id: 'A1.G.BE.I_AM',
            form: 'I am',
            shortForm: "I'm",
            meaningAr: 'أنا',
            introducedIn: 'A1-U1-L1',
            examples: [],
          ),
        ],
        continueLabel: 'Continue',
        onContinue: () {},
      ),
    );

    expect(find.text('NEW'), findsOneWidget);
    expect(find.text('FROM A1'), findsNWidgets(2));
  });

  testWidgets("an A1 lesson's own items never say From A1", (tester) async {
    await tester.pumpActivityView(
      LessonKeyPhrasesStep(
        overline: 'Unit 1 · Lesson 1',
        lessonId: 'A1-U1-L1',
        phrases: const [
          ChunkItem(
            id: 'A1.CHUNK.GOOD_MORNING',
            text: 'Good morning.',
            arabic: 'صباح الخير.',
            cefr: 'A1',
            introducedIn: 'A1-U0-L1',
            productive: true,
            recycledIn: [],
          ),
        ],
        grammar: const [],
        continueLabel: 'Continue',
        onContinue: () {},
      ),
    );

    expect(find.text('FROM A1'), findsNothing);
    expect(find.text('NEW'), findsNothing);
  });
}
```

Create `test/core/l10n/lesson_type_label_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/l10n/lesson_type_label.dart';

void main() {
  test("A2's text-based lessons have a name in both languages", () {
    final en = lookupAppLocalizations(const Locale('en'));
    final ar = lookupAppLocalizations(const Locale('ar'));
    expect(lessonTypeLabel(en, 'integrated-production'), en.homeLessonTypeIntegrated);
    expect(lessonTypeLabel(ar, 'integrated-production'), ar.homeLessonTypeIntegrated);
    expect(en.homeLessonTypeIntegrated, isNot(ar.homeLessonTypeIntegrated));
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/lesson_player/lesson_key_phrases_step_test.dart test/core/l10n/lesson_type_label_test.dart`
Expected: FAIL — no "FROM A1" badge; `homeLessonTypeIntegrated` doesn't exist.

- [ ] **Step 3: Add the strings**

`lib/l10n/app_en.arb`:

```json
  "lessonIntroFromLevel": "From {level}",
  "@lessonIntroFromLevel": {"description": "Badge on a key phrase or grammar form that the lesson reviews from an earlier level, e.g. 'From A1'.", "placeholders": {"level": {"type": "String", "example": "A1"}}},
  "homeLessonTypeIntegrated": "Put it together",
  "@homeLessonTypeIntegrated": {"description": "Lesson type label: lessonType integrated-production — a model text, questions on it, then the learner writes their own."}
```

`lib/l10n/app_ar.arb`:

```json
  "lessonIntroFromLevel": "من {level}",
  "homeLessonTypeIntegrated": "اجمع ما تعلّمته"
```

Run: `flutter gen-l10n`

- [ ] **Step 4: Implement**

In `lib/core/l10n/lesson_type_label.dart`, add to the switch:

```dart
    'integrated-production' => l10n.homeLessonTypeIntegrated,
```

In `lesson_key_phrases_step.dart`:

1. Import `'../../../../content/catalog/content_level.dart'`.
2. Update the class doc: "Each phrase shows its fill-in slots, its Arabic, a NEW badge when this lesson is where it's introduced — or "From A1" when it comes from an earlier level — and a button to hear it. Grammar rows show the form, its short form, the registry's first example, and "From A1" when it comes from an earlier level."
3. In `build`, after `final l10n = …;`, add:

```dart
    final lessonLevel = levelIdOfContentId(lessonId);

    /// "From A1" for an item from an earlier level than this lesson.
    String? fromLevelBadge(String itemId) {
      final itemLevel = levelIdOfContentId(itemId);
      if (itemLevel == null || itemLevel == lessonLevel) return null;
      return l10n.lessonIntroFromLevel(itemLevel.toUpperCase());
    }
```

4. Build phrase rows with `badge: fromLevelBadge(phrase.id) ?? (phrase.introducedIn == lessonId ? l10n.lessonIntroNew : null),` instead of `isNew: …`, and grammar rows with `_GrammarRow(item: item, badge: fromLevelBadge(item.id))`.
5. Add a shared badge widget and use it in both rows:

```dart
/// A small pill on a key-phrases row: NEW, or From A1.
class _Badge extends StatelessWidget {
  const _Badge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs, vertical: 3),
      decoration: BoxDecoration(
        color: tokens.primaryInkTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: overlineStyle(context, color: tokens.primaryInk),
      ),
    );
  }
}
```

In `_PhraseRow`: replace `final bool isNew;` / `required this.isNew,` with `final String? badge;` / `required this.badge,`, and replace the `if (isNew) ...[ … Container(…) ]` block with:

```dart
          if (badge != null) ...[
            const SizedBox(width: AppSpace.xs),
            _Badge(badge!),
          ],
```

In `_GrammarRow`: add `this.badge` (`const _GrammarRow({required this.item, this.badge});`, field `final String? badge;`), and wrap the form line so the badge sits at its end:

```dart
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpace.xs,
                      children: [
                        Text(item.form, style: formStyle),
                        if (shortForm != null) ...[
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: tokens.textSecondary,
                          ),
                          Text(shortForm, style: formStyle),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: AppSpace.xs),
                _Badge(badge!),
              ],
            ],
          ),
```

(this replaces the existing `Align(alignment: AlignmentDirectional.centerStart, child: Directionality(…))` block).

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/features/lesson_player/ test/core/`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/ test/features/lesson_player/lesson_key_phrases_step_test.dart test/core/l10n/
git commit -m "feat: mark phrases and grammar reviewed from an earlier level

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 11: Documentation (definition of done)

**Files:**
- Create: `docs/adr/0006-multiple-levels.md`
- Modify: `docs/adr/README.md`, `docs/ARCHITECTURE.md`, `docs/DATA_MODEL.md`, `docs/GLOSSARY.md`, `docs/TESTING.md`

Every doc edited gets its **Last verified** line bumped to the day of the edit, naming the change and this branch.

- [ ] **Step 1: Write ADR 0006**

Create `docs/adr/0006-multiple-levels.md`:

```markdown
# 0006: More than one level — a current level, earlier-level references, and level locks

**Status:** Accepted

## Context

The app was built for A1 alone. An A2 curriculum (from `reference/a2-modular-course/`) is being adapted to continue it — see docs/superpowers/specs/2026-09-19-a2-level-design.md. A2 has to feel like the next stage of the same course: its lessons review A1 language, a learner's A1 words keep coming up for review while they study A2, and a learner who already knows A1 must be able to start A2 without being blocked. The A2 reference also re-registered 30 A1 words and several A1 grammar points under new A2 ids, which breaks the curriculum's own rule ("reuse the id, never copy the record").

## Decision

1. **Levels are one journey with a current level.** The learner works in one current level (stored with their progress, so "Reset progress" returns them to A1). Home and Tests follow it; Review is shared across levels; Vocabulary and Grammar open on it with a filter.
2. **A level may build on an earlier one.** The app-owned catalogue declares `prerequisiteLevelId` (A2 → A1). The earlier level loads first and the later level's index is built with it attached, so a lesson may list the earlier level's grammar, word and phrase ids — shown to learners as "From A1". Bundles stay self-contained files; the dependency lives in the catalogue.
3. **Items open in their own level.** Every bundle id starts with its level (`A1-U3`, `A2.LEX…`); a screen that opens one item finds the level from the id.
4. **Levels lock softly.** Before a level is released it is a locked preview (titles and topics browsable, lessons closed). After release A2 opens once A1 is complete, after a placement result in A2, or when the learner chooses "Open A2 anyway". Units within a level stay recommendation-only.

## Alternatives considered

- **Separate courses per level** (switching level switches the whole app, Review included) — rejected: A1 words would stop being reviewed exactly when A2 starts relying on them.
- **Strict order (A2 only after A1 is finished)** — rejected: contradicts "recommend, never lock", and would block adults who already know A1.
- **Copying A1 records into the A2 bundle** — rejected: two ids for one sense, two review schedules for one word.
- **One merged bundle for all levels** — rejected: larger startup cost and every level's edits in one file; the catalogue already makes levels additive.

## Consequences

- A2's index depends on A1's: if A1 fails to load, A2 does too (A2 failing never takes A1 down).
- Ids must keep their level prefix; a test fixture without one can't be opened by id.
- Later levels (B1+) reuse the same mechanism: each declares the level it builds on.
```

In `docs/adr/README.md`, add rows for 0005 (missing from the index) and 0006:

```markdown
| [0005](0005-narrow-network-exception-for-open-ended-grading.md) | A narrow, bounded network exception for open-ended answer grading | Accepted |
| [0006](0006-multiple-levels.md) | More than one level — a current level, earlier-level references, and level locks | Accepted |
```

- [ ] **Step 2: Update ARCHITECTURE.md**

- Folder structure: change the `catalog/` line to `# app-owned level-availability table (A1 = available, A2-C2 = comingSoon), each level's prerequisite, and levelIdOfContentId`.
- Under "Key flows" → "Content", add a paragraph **Levels and earlier-level references**: `levelCatalogProvider`/`bundleAssetLoaderProvider` (overridable in tests) feed `courseContentProvider(levelId)`; a level with `prerequisiteLevelId` is indexed with the earlier level's index attached, and `resolveGrammar/resolveLexicon/resolveChunk` look there after the level's own records (the `*ById` maps hold own records only); `contentIndexForIdProvider(contentId)` gives any screen that opens one unit, lesson, word, phrase or grammar point the index of that item's level via `levelIdOfContentId`. See ADR 0006.
- Under "Test hosting" or a new short paragraph **What the question frame shows**: `ActivityChrome` shows a question's `source` (`ActivitySourceCard` — a textChoice's `sourceText` or any activity's `sourceCard`), in test mode too; `SpeakActivityView` shows and reads aloud `partnerTurns`/`examinerTurns` (`ActivityPartnerTurnsCard`, never auto-playing in review); the lesson player's intro is conversation → model text (`LessonReadingStep`) → key phrases, the key phrases marking earlier-level items "From A1".

- [ ] **Step 3: Update DATA_MODEL.md**

- Unit: `countsTowardA1Mastery` → `countsTowardLevelMastery` (read from `countsTowardLevelMastery`, `countsTowardA1Mastery` or `countsTowardA2Mastery`).
- Lesson: `readingText: {title, text, textAr}` is now modelled (`LessonReadingText`) and shown by the lesson player; lesson `grammar`/`lexicon`/`chunks` may list ids from the level's prerequisite.
- Activity: any activity may carry `sourceCard` (string, shown with the question); `speak` may carry `partnerTurns: [string]` (A1's `examinerTurns` is read the same way).
- Lexicon: `examples: [string | {en, ar}]` (A1 strings, A2 objects).
- Content catalogue: add `prerequisiteLevelId`.

- [ ] **Step 4: Update GLOSSARY.md**

Add a row:

```markdown
| Earlier-level reference | A lesson's grammar, word or phrase id that belongs to an earlier level (an A2 lesson listing `A1.G.BE.I_AM`) — the earlier record is reviewed, never copied. Shown to learners as "From A1". Declared by the catalogue's `prerequisiteLevelId`. | Not a new record: the id, its review schedule and its page stay the earlier level's. |
```

and extend the "Content catalogue" row's definition with "…and, per level, the level it builds on (`prerequisiteLevelId`: A2 → A1)."

- [ ] **Step 5: Update TESTING.md**

- "Curriculum content": add "a level's prerequisite loads first and resolves its earlier-level references, which stay unresolved without it (`course_content_index_prerequisite_test.dart`, `course_content_providers_test.dart` with `test/content/fixtures/minimal_bundle.dart`); a content id's level (`content_level_test.dart`); A2 shapes parse — bilingual word examples, lesson texts, source cards, partner lines (`test/content/models/`)".
- "Lesson intro": add "a lesson built around a text opens on it (title, English, Arabic behind the switch), then key phrases; key phrases mark earlier-level items From A1 (`lesson_key_phrases_step_test.dart`)".
- Add a bullet: "**Question material:** a reading question shows its text, left to right, in test mode too; mediation tasks show their source card; a speaking task's partner lines show and are read aloud in order on opening, and can be replayed, but never auto-play in review."
- Content quality: `a1_content_quality_test.dart` also checks every lesson text carries its whole Arabic.

- [ ] **Step 6: Commit**

```bash
git add docs/
git commit -m "docs: record multiple levels and the new question material

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 12: Full verification

- [ ] **Step 1: Format**

Run: `dart format .`
Expected: files formatted; if any changed, they're part of this plan's work — include them in the commit below.

- [ ] **Step 2: Analyze**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: Run the whole suite**

Run: `flutter test`
Expected: all tests pass. Report the count.

- [ ] **Step 4: Check nothing still hard-codes A1 in the screens this plan moved**

Run: `git grep -n "courseContentProvider('a1')" -- lib/features/learning_path/presentation/unit_overview_screen.dart lib/features/lesson_player lib/features/vocabulary/presentation/word_detail_screen.dart lib/features/vocabulary/presentation/chunk_detail_screen.dart lib/features/grammar/presentation/grammar_detail_screen.dart lib/features/review/presentation/quick_practice_screen.dart lib/features/learning_path/providers lib/features/activity_engine`
Expected: no output. (The remaining `'a1'` uses — Home, Learn, Review, Vocabulary/Grammar lists, Tests, router, enrolment — are step 2's work.)

- [ ] **Step 5: Commit any formatting changes**

```bash
git add -A
git commit -m "chore: format

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

(Skip if `git status` is clean.)
