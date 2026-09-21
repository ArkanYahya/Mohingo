import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/curriculum_structure.dart';
import 'package:mohingo/features/placement_test/domain/placement_classifier.dart';
import 'package:mohingo/features/placement_test/domain/placement_outcome.dart';
import 'package:mohingo/features/placement_test/domain/placement_plan.dart';

Unit _unit(String id) => Unit(
  id: id,
  title: id,
  titleAr: id,
  levelRole: 'core',
  estimatedMinutes: const [],
  countsTowardLevelMastery: true,
  lessons: const [],
  mastery: const UnitMastery(
    requiredObjectives: [],
    requiredSkillGroups: [],
    minimumObjectiveScore: null,
    raw: {},
  ),
);

PlacementLevel _level(String levelId, String code, List<String> unitIds) =>
    PlacementLevel(
      levelId: levelId,
      cefrCode: code,
      units: [for (final id in unitIds) _unit(id)],
    );

final _a1 = _level('a1', 'A1', [for (var i = 0; i <= 12; i++) 'A1-U$i']);
final _a2 = _level('a2', 'A2', [for (var i = 1; i <= 12; i++) 'A2-U$i']);

void main() {
  group('PlacementScoring.unitPassed', () {
    test('never fails a unit from a single item — insufficient sample size '
        'always passes', () {
      expect(PlacementScoring.unitPassed([false]), isTrue);
      expect(PlacementScoring.unitPassed([]), isTrue);
    });

    test('2 items, 1 correct (50%) fails — below the 0.6 threshold', () {
      expect(PlacementScoring.unitPassed([true, false]), isFalse);
    });

    test('2 items, both correct passes', () {
      expect(PlacementScoring.unitPassed([true, true]), isTrue);
    });

    test('3 items, 2 correct (66%) passes — at/above the 0.6 threshold', () {
      expect(PlacementScoring.unitPassed([true, true, false]), isTrue);
    });
  });

  group('PlacementScoring.blockPassed', () {
    test('a 3-unit block passes on 2 of 3 and fails on 1 of 3', () {
      expect(PlacementScoring.blockPassed([true, true, false]), isTrue);
      expect(PlacementScoring.blockPassed([true, false, false]), isFalse);
    });

    test("A1's 4-unit opening block passes on 3 of 4, fails on 2 of 4", () {
      expect(PlacementScoring.blockPassed([true, true, true, false]), isTrue);
      expect(PlacementScoring.blockPassed([true, true, false, false]), isFalse);
    });

    test('a block with no eligible item passes — no evidence blocks '
        'nothing, the same rule as a unit', () {
      expect(PlacementScoring.blockPassed([]), isTrue);
    });

    test('one wrong answer can fail a block, but a failed block only opens '
        'its units up to the per-unit rule — it never recommends one', () {
      expect(PlacementScoring.blockPassed([false]), isFalse);
      expect(PlacementScoring.unitPassed([false]), isTrue);
    });
  });

  group('splitIntoPlacementBlocks', () {
    test("A1's 13 units become U0-U3, U4-U6, U7-U9, U10-U12", () {
      final blocks = splitIntoPlacementBlocks(_a1.units);
      expect(
        [
          for (final block in blocks) [for (final u in block) u.id],
        ],
        [
          ['A1-U0', 'A1-U1', 'A1-U2', 'A1-U3'],
          ['A1-U4', 'A1-U5', 'A1-U6'],
          ['A1-U7', 'A1-U8', 'A1-U9'],
          ['A1-U10', 'A1-U11', 'A1-U12'],
        ],
      );
    });

    test("A2's 12 units become U1-U3, U4-U6, U7-U9, U10-U12", () {
      final blocks = splitIntoPlacementBlocks(_a2.units);
      expect(
        [
          for (final block in blocks) [for (final u in block) u.id],
        ],
        [
          ['A2-U1', 'A2-U2', 'A2-U3'],
          ['A2-U4', 'A2-U5', 'A2-U6'],
          ['A2-U7', 'A2-U8', 'A2-U9'],
          ['A2-U10', 'A2-U11', 'A2-U12'],
        ],
      );
    });

    test('an empty level has no blocks', () {
      expect(splitIntoPlacementBlocks(const []), isEmpty);
    });
  });

  group('PlacementPlan', () {
    final plan = PlacementPlan.across([_a1, _a2]);

    test('covers both levels in order, 8 blocks and 25 units', () {
      expect(plan.blocks, hasLength(8));
      expect(plan.totalUnits, 25);
      expect(plan.blocks.first.level.levelId, 'a1');
      expect(plan.blocks.last.level.levelId, 'a2');
    });

    test('numbers a unit inside its own level, never across levels — '
        'A1-U0 and A2-U1 are both Unit 1', () {
      expect(plan.locate('A1-U0')!.number, 1);
      expect(plan.locate('A1-U0')!.cefrCode, 'A1');
      expect(plan.locate('A2-U1')!.number, 1);
      expect(plan.locate('A2-U1')!.cefrCode, 'A2');
      expect(plan.locate('A1-U12')!.number, 13);
      expect(plan.locate('A2-U12')!.number, 12);
    });

    test('only the level opener is the level start', () {
      expect(plan.locate('A2-U1')!.isFirstInLevel, isTrue);
      expect(plan.locate('A2-U2')!.isFirstInLevel, isFalse);
      expect(plan.locate('A1-U1')!.isFirstInLevel, isFalse);
    });

    test('a unit id no released level holds resolves to nothing rather '
        'than to unit 0 of whatever is on screen', () {
      expect(plan.locate('B1-U1'), isNull);
      expect(plan.locate(null), isNull);
    });

    test('the top level is the highest released one — never a claim above '
        'it', () {
      expect(plan.topLevel.levelId, 'a2');
      expect(PlacementPlan.across([_a1]).topLevel.levelId, 'a1');
    });

    test('scan index runs across levels, so every unit seeds its own '
        'sampling', () {
      expect(plan.locate('A1-U0')!.scanIndex, 0);
      expect(plan.locate('A1-U12')!.scanIndex, 12);
      expect(plan.locate('A2-U1')!.scanIndex, 13);
      expect(plan.locate('A2-U12')!.scanIndex, 24);
    });
  });

  group('PlacementClassifier.classify — all 4 outcomes reachable', () {
    test('failing at A1-U0 -> startWithEssentials', () {
      final result = PlacementClassifier.classify([
        const MapEntry('A1-U0', false),
      ], topLevelId: 'a2');
      expect(result.outcome, PlacementOutcome.startWithEssentials);
      expect(result.recommendedUnitId, 'A1-U0');
    });

    test('passing A1-U0, failing A1-U1 -> startA1FromU1', () {
      final result = PlacementClassifier.classify([
        const MapEntry('A1-U0', true),
        const MapEntry('A1-U1', false),
      ], topLevelId: 'a2');
      expect(result.outcome, PlacementOutcome.startA1FromU1);
      expect(result.recommendedUnitId, 'A1-U1');
    });

    test('passing through A1-U4, failing A1-U5 -> startFromRecommendedUnit '
        'at A1-U5, never auto-skipping ahead further', () {
      final result = PlacementClassifier.classify([
        const MapEntry('A1-U0', true),
        const MapEntry('A1-U1', true),
        const MapEntry('A1-U2', true),
        const MapEntry('A1-U3', true),
        const MapEntry('A1-U4', true),
        const MapEntry('A1-U5', false),
      ], topLevelId: 'a2');
      expect(result.outcome, PlacementOutcome.startFromRecommendedUnit);
      expect(result.recommendedUnitId, 'A1-U5');
    });

    test('a gap inside A2 recommends that A2 unit, not an A1 one', () {
      final result = PlacementClassifier.classify([
        const MapEntry('A2-U4', true),
        const MapEntry('A2-U5', false),
      ], topLevelId: 'a2');
      expect(result.outcome, PlacementOutcome.startFromRecommendedUnit);
      expect(result.recommendedUnitId, 'A2-U5');
      expect(result.storedOutcome, 'startFromRecommendedUnit');
    });

    test('passing every scanned unit -> the top released level is the most '
        'that can be claimed, never a fabricated B1+ result', () {
      final result = PlacementClassifier.classify([
        for (var i = 0; i <= 12; i++) MapEntry('A1-U$i', true),
        for (var i = 1; i <= 12; i++) MapEntry('A2-U$i', true),
      ], topLevelId: 'a2');
      expect(result.outcome, PlacementOutcome.levelMastered);
      expect(result.recommendedUnitId, isNull);
      expect(result.masteredLevelId, 'a2');
      expect(result.storedOutcome, 'a2Mastered');
    });

    test('with only A1 released, a clean sweep still reads as A1 — the '
        'stored value older results already use', () {
      final result = PlacementClassifier.classify(const [], topLevelId: 'a1');
      expect(result.storedOutcome, 'a1Mastered');
    });

    test('every reachable outcome stays within the 4-value enum — the '
        'classifier has no code path that can express a level the app has '
        'no content for', () {
      expect(PlacementOutcome.values, hasLength(4));
    });

    test('stops at the FIRST failing unit even if scan continued past it — '
        'classification never looks past where evidence first weakens', () {
      final result = PlacementClassifier.classify([
        const MapEntry('A1-U0', true),
        const MapEntry('A1-U1', true),
        const MapEntry('A1-U2', false),
        // A caller could still include entries after the first failure
        // (e.g. leftover data); classify() must not be swayed by them.
        const MapEntry('A1-U3', true),
      ], topLevelId: 'a2');
      expect(result.outcome, PlacementOutcome.startFromRecommendedUnit);
      expect(result.recommendedUnitId, 'A1-U2');
    });
  });

  group('stored outcomes stay readable', () {
    test('a result stored before the test covered A2 still names A1', () {
      expect(masteredLevelIdOfStoredOutcome('a1Mastered'), 'a1');
    });

    test('and a result stored now names the level it measured', () {
      expect(masteredLevelIdOfStoredOutcome('a2Mastered'), 'a2');
    });

    test('a unit-based outcome names no level — its unit id does', () {
      expect(masteredLevelIdOfStoredOutcome('startWithEssentials'), isNull);
      expect(masteredLevelIdOfStoredOutcome('startA1FromU1'), isNull);
      expect(
        masteredLevelIdOfStoredOutcome('startFromRecommendedUnit'),
        isNull,
      );
    });
  });
}
