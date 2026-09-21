import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/curriculum_structure.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/placement_test/domain/placement_item_sampler.dart';
import 'package:mohingo/features/placement_test/domain/placement_plan.dart';
import 'package:mohingo/features/placement_test/presentation/placement_test_screen.dart';
import 'package:mohingo/features/speech/domain/speech_capability_service.dart';
import 'package:mohingo/features/speech/domain/speech_recognition_service.dart';
import 'package:mohingo/features/speech/providers/speech_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../activity_engine/answer_activity.dart';
import '../speech/fake_speech_services.dart';

/// End-to-end passes through the Gateway Placement Test against **real**
/// A1 and A2 content, one per learner profile the design names: a complete
/// beginner, a learner with a gap inside A2, and a learner who knows the
/// whole course.
///
/// The seeded [placementSeedProvider] override (see that provider's doc
/// comment on why it exists) lets each test compute the exact items the
/// scan will draw, answer them right or wrong on purpose, and then assert
/// both the recommendation and how many questions it took to get there —
/// which is the whole point of the block pass.
CourseContentIndex _indexOf(String level) => CourseContentIndex.build(
  CourseBundleParser.parse(
    File('assets/content/en/$level/${level.toLowerCase()}-course-bundle.json')
        .readAsStringSync(),
  ),
);

final _a1 = _indexOf('A1');
final _a2 = _indexOf('A2');

final _plan = PlacementPlan.across([
  PlacementLevel(
    levelId: 'a1',
    cefrCode: 'A1',
    units: _a1.bundle.units,
    mediaByKey: _a1.bundle.mediaSpecifications,
  ),
  PlacementLevel(
    levelId: 'a2',
    cefrCode: 'A2',
    units: _a2.bundle.units,
    mediaByKey: _a2.bundle.mediaSpecifications,
  ),
]);

const _seed = 999;

/// The one item per unit a block pass asks, in unit order.
List<Activity> _blockItems(PlacementBlock block, Set<String> asked) => [
  for (final unit in block.units)
    ...PlacementItemSampler.receptiveItemsForUnit(
      unit,
      seed: _seed + _plan.locate(unit.id)!.scanIndex,
      limit: 1,
      exclude: asked,
    ),
];

/// The up-to-three fresh items a drill-down asks about one unit.
List<Activity> _drillItems(Unit unit, Set<String> asked) =>
    PlacementItemSampler.receptiveItemsForUnit(
      unit,
      seed: _seed + _plan.locate(unit.id)!.scanIndex,
      exclude: asked,
    );

/// Answers [items] in order, correctly or not, and remembers them as
/// asked — the scan never repeats an item within one attempt.
Future<void> _answer(
  WidgetTester tester,
  List<Activity> items,
  Set<String> asked, {
  required bool correctly,
}) async {
  for (final activity in items) {
    await answerCheckAndAdvance(tester, activity, correctly: correctly);
    asked.add(activity.id);
  }
}

Future<(AppLocalizations, AppDatabase)> _startTest(WidgetTester tester) async {
  // A2's questions are longer than A1's; the default 800x600 test viewport
  // pushes their last option under the Check bar.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
        courseContentProvider('a1').overrideWith((ref) async => _a1),
        courseContentProvider('a2').overrideWith((ref) async => _a2),
        placementSeedProvider.overrideWithValue(_seed),
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
        theme: AppTheme.light(AppColorSeed.calmTeal),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const PlacementTestScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final l10n = AppLocalizations.of(
    tester.element(find.byType(Scaffold).first),
  )!;
  await tester.tap(find.byType(FilledButton)); // "Start"
  await tester.pumpAndSettle();
  return (l10n, db);
}

/// The unscored productive item the scan ends on, drawn from the last unit
/// it reached.
Future<void> _finishWithProductiveAndConfidence(
  WidgetTester tester,
  AppLocalizations l10n,
  Unit lastUnitReached,
) async {
  final productive = PlacementItemSampler.productiveItemForUnit(
    lastUnitReached,
    seed: _seed,
  );
  if (productive != null) {
    await answerCheckAndAdvance(tester, productive);
  }
  await tester.pumpAndSettle();
  await tester.tap(find.text(l10n.placementConfidence3));
  await tester.pumpAndSettle();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('a complete beginner is sent to English Essentials after one '
      'failed block and one failed unit — 7 scored questions, not 39', (
    tester,
  ) async {
    final (l10n, db) = await _startTest(tester);
    final asked = <String>{};

    // Block 1 of A1 (U0-U3), one item per unit, all wrong.
    final block = _blockItems(_plan.blocks.first, asked);
    expect(block, hasLength(4));
    await _answer(tester, block, asked, correctly: false);

    // The failed block opens up unit by unit, starting at its first.
    final essentials = _plan.blocks.first.units.first;
    expect(essentials.id, 'A1-U0');
    final drill = _drillItems(essentials, asked);
    expect(drill, hasLength(3));
    expect(
      find.text(
        l10n
            .testQuestionEyebrow(l10n.placementUnitSection('A1', 1), 1, 3)
            .toUpperCase(),
      ),
      findsOneWidget,
      reason: 'A1-U0 is A1\'s Unit 1, numbered inside its own level',
    );
    await _answer(tester, drill, asked, correctly: false);

    await _finishWithProductiveAndConfidence(tester, l10n, essentials);

    expect(find.text(l10n.placementResultHeadline('A1', 1)), findsOneWidget);
    expect(find.text(l10n.placementResultBodyEssentials), findsOneWidget);

    final attempt = (await db.select(db.placementAttempts).get()).single;
    expect(attempt.outcome, 'startWithEssentials');
    expect(attempt.recommendedUnitId, 'A1-U0');

    final scored = await db.select(db.activityAttempts).get();
    expect(
      scored.where((a) => asked.contains(a.activityId)),
      hasLength(7),
      reason: 'four block items plus three in the opened-up unit',
    );
    expect(scored.map((a) => a.sessionType).toSet(), {'placement'});
  });

  testWidgets('a learner who knows A1 but has a gap inside A2 is drilled '
      'down to that A2 unit, numbered inside A2', (tester) async {
    final (l10n, db) = await _startTest(tester);
    final asked = <String>{};

    // All four A1 blocks and A2's first block: 13 + 3 items, all right.
    for (final block in _plan.blocks.take(5)) {
      await _answer(tester, _blockItems(block, asked), asked, correctly: true);
    }
    expect(asked, hasLength(16));

    // A2's U4-U6 block fails.
    final failing = _plan.blocks[5];
    expect([for (final u in failing.units) u.id], ['A2-U4', 'A2-U5', 'A2-U6']);
    expect(
      find.text(l10n.placementUnitSection('A2', 4).toUpperCase()),
      findsOneWidget,
      reason: 'a block-pass question names the level and the unit',
    );
    await _answer(tester, _blockItems(failing, asked), asked, correctly: false);

    // Opened up: U4 holds, U5 doesn't — and the scan stops there.
    await _answer(
      tester,
      _drillItems(failing.units[0], asked),
      asked,
      correctly: true,
    );
    expect(
      find.text(
        l10n
            .testQuestionEyebrow(l10n.placementUnitSection('A2', 5), 1, 3)
            .toUpperCase(),
      ),
      findsOneWidget,
    );
    await _answer(
      tester,
      _drillItems(failing.units[1], asked),
      asked,
      correctly: false,
    );

    await _finishWithProductiveAndConfidence(tester, l10n, failing.units[1]);

    expect(asked, hasLength(25));
    expect(find.text(l10n.placementResultHeadline('A2', 5)), findsOneWidget);
    expect(find.text(l10n.placementResultBodyUnit(5)), findsOneWidget);

    final attempt = (await db.select(db.placementAttempts).get()).single;
    expect(attempt.outcome, 'startFromRecommendedUnit');
    expect(attempt.recommendedUnitId, 'A2-U5');
  });

  testWidgets('answering every block correctly reaches "A2 looks mastered" '
      '— the top released level and never a claim above it', (tester) async {
    final (l10n, db) = await _startTest(tester);
    final asked = <String>{};

    for (final block in _plan.blocks) {
      await _answer(tester, _blockItems(block, asked), asked, correctly: true);
    }
    expect(
      asked,
      hasLength(25),
      reason: 'one item per unit across both levels, no drill-down',
    );

    await _finishWithProductiveAndConfidence(
      tester,
      l10n,
      _plan.blocks.last.units.last,
    );

    expect(find.text(l10n.placementResultMasteredTitle('A2')), findsOneWidget);
    expect(find.text(l10n.placementResultMasteredTitle('B1')), findsNothing);

    final attempts = await db.select(db.placementAttempts).get();
    expect(attempts, hasLength(1));
    expect(
      attempts.single.outcome,
      'a2Mastered',
      reason: 'the level actually measured, stored the way a1Mastered was',
    );
    expect(attempts.single.recommendedUnitId, isNull);
    expect(attempts.single.completedAt, isNotNull);
    expect(attempts.single.confidenceSelfReports, contains('3'));

    final itemAttempts = await db.select(db.activityAttempts).get();
    expect(
      itemAttempts.map((a) => a.sessionType).toSet(),
      {'placement'},
      reason:
          'every item recorded during the test must carry '
          'sessionType=placement, keeping it isolated from ordinary '
          'lesson mastery evidence and Review',
    );
  });
}
