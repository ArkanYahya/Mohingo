import 'dart:io';

import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/course_bundle.dart';
import 'package:mohingo/content/models/curriculum_structure.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';

/// A rule a level is held to at a different value, with the reason written
/// down.
///
/// Deliberately **not** a skip. An excepted unit is still checked, against
/// its own numbers, so drifting further still fails — and the reason is
/// printed in the failure message, so a reader never has to hunt for why
/// this unit is different. There is no boolean anywhere in this file that
/// turns a check off; that is what keeps "hold every level to the same
/// standard" from decaying into "list what each level is allowed to fail".
class DeclaredException<T> {
  const DeclaredException({required this.value, required this.reason});

  final T value;
  final String reason;
}

class Range {
  const Range(this.min, this.max);
  const Range.exactly(int n) : min = n, max = n;

  final int min;
  final int max;

  bool contains(int n) => n >= min && n <= max;

  @override
  String toString() => min == max ? '$min' : '$min-$max';
}

class UnitShape {
  const UnitShape({
    required this.lessons,
    required this.activities,
    required this.encounter,
    required this.practice,
    required this.mastery,
  });

  final int lessons;
  final int activities;
  final int encounter;
  final int practice;
  final int mastery;
}

class SkillBalance {
  const SkillBalance({
    required this.listening,
    required this.reading,
    required this.speaking,
    required this.writing,
    required this.mediation,
  });

  final Range listening;
  final Range reading;

  /// Spoken production and spoken interaction together.
  final Range speaking;
  final Range writing;
  final Range mediation;
}

/// Word-count bands for units up to [throughUnitIndex], inclusive. A level
/// whose texts climb has several tiers; one whose texts do not has one.
class LengthBandTier {
  const LengthBandTier({
    required this.throughUnitIndex,
    required this.listening,
    required this.reading,
    required this.writing,
  });

  final int throughUnitIndex;
  final Range listening;
  final Range reading;
  final Range writing;
}

/// How a level tags its activities with Can-Do objectives, and therefore
/// at what granularity "evidence for an objective is earned through that
/// objective's own skill" can be checked.
///
/// [perActivitySkill]: each activity carries only objectives of its own
/// skill's category, so the rule holds per activity (A2). [unitLevel]: the
/// level's tags cross categories freely (A1 mostly copies each lesson's
/// list onto its activities), so the rule can only hold at unit level —
/// every objective a unit requires is carried by at least one activity of
/// the objective's own category. A different granularity, not a weaker
/// guarantee: it is the one the app's mastery model actually depends on.
/// See `level_design_limits_test.dart`.
enum CanDoTagging { perActivitySkill, unitLevel }

/// Everything one level is judged by. Adding a level means adding one of
/// these; every gate under `test/content/levels/` then runs over it.
class LevelGateConfig {
  const LevelGateConfig({
    required this.levelId,
    required this.bundleAssetPath,
    required this.courseId,
    required this.prerequisiteLevelId,
    required this.finishedUnitIds,
    required this.unitShape,
    required this.skillBalance,
    required this.bandTiers,
    required this.minimumNewSensesPerUnit,
    required this.sourceCardWords,
    required this.maxPromptRepeatsPerUnit,
    required this.maxEnglishToArabicMatchesPerUnit,
    required this.requiresModelTextPerUnit,
    required this.wordGuideMustEqualBand,
    required this.canDoTagging,
    required this.finalMissionId,
    required this.finalAssessmentId,
    required this.capstonePassMark,
    required this.capstoneListeningWords,
    required this.capstoneSourceWords,
    required this.capstoneWordGuide,
    required this.capstoneSuiteFile,
    this.unitShapeExceptions = const {},
    this.skillBalanceExceptions = const {},
  });

  final String levelId;
  final String bundleAssetPath;
  final String courseId;
  final String? prerequisiteLevelId;

  /// The units that claim to be finished content. A unit joins in the batch
  /// that authors it — never before — and a level cannot be marked
  /// `available` until this is every unit in its bundle.
  final List<String> finishedUnitIds;

  final UnitShape unitShape;
  final Map<String, DeclaredException<UnitShape>> unitShapeExceptions;
  final SkillBalance skillBalance;
  final Map<String, DeclaredException<SkillBalance>> skillBalanceExceptions;
  final List<LengthBandTier> bandTiers;
  final int minimumNewSensesPerUnit;

  /// Notices and source cards a unit's mediation tasks hand the learner.
  final Range sourceCardWords;
  final int maxPromptRepeatsPerUnit;
  final int maxEnglishToArabicMatchesPerUnit;

  /// Whether every unit must carry exactly one model text for its
  /// production lesson.
  final bool requiresModelTextPerUnit;

  /// Whether every free-writing task in a unit asks for the same length.
  /// True where the unit's band *is* the guide (A2); false where each task
  /// carries its own guide, which must still sit inside the band (A1).
  final bool wordGuideMustEqualBand;

  final CanDoTagging canDoTagging;
  final String finalMissionId;
  final String finalAssessmentId;
  final double capstonePassMark;

  /// Length bands for capstone material. Separate from [bandTiers] because
  /// a capstone is not a unit: it sits at the end of the level and is
  /// marked against one band, not a per-unit tier.
  final Range capstoneListeningWords;
  final Range capstoneSourceWords;
  final Range capstoneWordGuide;

  /// The focused capstone suite whose existence the release rule asserts,
  /// so the gates cannot be deleted and a release left standing.
  final String capstoneSuiteFile;

  CourseBundle bundle() =>
      CourseBundleParser.parse(File(bundleAssetPath).readAsStringSync());

  List<Unit> finishedUnits() {
    if (finishedUnitIds.isEmpty) {
      throw StateError(
        '$levelId has an empty finished list: every gate would pass while '
        'asserting nothing. Removing the last unit is never the right way '
        'to make this suite green.',
      );
    }
    final byId = {for (final u in bundle().units) u.id: u};
    return [
      for (final id in finishedUnitIds)
        byId[id] ??
            (throw StateError(
              '$levelId names $id, which its bundle does not contain',
            )),
    ];
  }

  UnitShape shapeFor(String unitId) =>
      unitShapeExceptions[unitId]?.value ?? unitShape;

  SkillBalance balanceFor(String unitId) =>
      skillBalanceExceptions[unitId]?.value ?? skillBalance;

  /// Why this unit has its own numbers, for a gate's failure message, or
  /// the empty string when it does not.
  String why(String unitId) {
    final reasons = <String>[
      ?unitShapeExceptions[unitId]?.reason,
      ?skillBalanceExceptions[unitId]?.reason,
    ];
    return reasons.isEmpty ? '' : ' (declared exception: ${reasons.first})';
  }

  LengthBandTier bandsFor(String unitId) {
    final n = int.parse(unitId.split('-U').last);
    for (final tier in bandTiers) {
      if (n <= tier.throughUnitIndex) return tier;
    }
    throw StateError(
      '$levelId has no length band covering $unitId; add a tier rather than '
      'letting a new unit inherit the last one by accident',
    );
  }
}

Iterable<Activity> activitiesOf(Unit unit) =>
    unit.lessons.expand((l) => l.activities);

/// Where each level's shipped bundle lives, whether or not that level is
/// gated yet.
///
/// Kept separate from [kLevelGates] deliberately: a level's earlier-level
/// references must resolve even when the earlier level has no gate config,
/// and reading the path out of the gate list would tie one concern to the
/// other for no reason.
const kLevelBundlePaths = {
  'a1': 'assets/content/en/A1/a1-course-bundle.json',
  'a2': 'assets/content/en/A2/a2-course-bundle.json',
};

/// The bundle of [gate]'s prerequisite level, or null if it builds on
/// nothing. Used by the gates that resolve earlier-level references.
CourseBundle? prerequisiteBundleOf(LevelGateConfig gate) {
  final id = gate.prerequisiteLevelId;
  if (id == null) return null;
  final path =
      kLevelBundlePaths[id] ??
      (throw StateError(
        '${gate.levelId} builds on $id, which has no bundle path recorded '
        'in kLevelBundlePaths',
      ));
  return CourseBundleParser.parse(File(path).readAsStringSync());
}

const _a1 = LevelGateConfig(
  levelId: 'a1',
  bundleAssetPath: 'assets/content/en/A1/a1-course-bundle.json',
  courseId: 'EN-A1-V2',
  prerequisiteLevelId: null,
  finishedUnitIds: [
    'A1-U0',
    'A1-U1',
    'A1-U2',
    'A1-U3',
    'A1-U4',
    'A1-U5',
    'A1-U6',
    'A1-U7',
    'A1-U8',
    'A1-U9',
    'A1-U10',
    'A1-U11',
    'A1-U12',
  ],
  unitShape: UnitShape(
    lessons: 7,
    activities: 36,
    encounter: 6,
    practice: 12,
    mastery: 18,
  ),
  unitShapeExceptions: {
    'A1-U0': DeclaredException(
      value: UnitShape(
        lessons: 5,
        activities: 20,
        encounter: 2,
        practice: 5,
        mastery: 13,
      ),
      reason:
          'A1-U0 is an onboarding unit, deliberately shorter than a teaching '
          'unit. Re-cutting it would move published activity ids, which the '
          'id-stability guard forbids.',
    ),
    'A1-U1': DeclaredException(
      value: UnitShape(
        lessons: 7,
        activities: 30,
        encounter: 5,
        practice: 7,
        mastery: 18,
      ),
      reason:
          'A1-U1 was authored before the 6/12/18 shape settled; U2-U12 all '
          'follow it. Re-cutting U1 would move published activity ids, which '
          'the id-stability guard forbids.',
    ),
  },
  // A1 is deliberately not A2's balance. A learner at A1 can barely read,
  // so the level leans on listening and asks for little writing and one
  // mediation task a unit, where A2 asks for three and two. Set from what
  // an A1 unit is for, not from what A1 happens to contain.
  skillBalance: SkillBalance(
    listening: Range(10, 14),
    reading: Range(10, 14),
    speaking: Range(5, 10),
    writing: Range(3, 5),
    mediation: Range(1, 2),
  ),
  skillBalanceExceptions: {
    'A1-U0': DeclaredException(
      value: SkillBalance(
        listening: Range(8, 14),
        reading: Range(0, 8),
        speaking: Range(5, 15),
        writing: Range(0, 5),
        mediation: Range(0, 2),
      ),
      reason:
          'A1-U0 is onboarding: the learner cannot yet read, write or '
          'mediate, so the unit teaches none of those. Its reading, writing '
          'and mediation floors are 0 rather than the ones U2 onwards keep.',
    ),
    'A1-U1': DeclaredException(
      value: SkillBalance(
        listening: Range(8, 14),
        reading: Range(0, 8),
        speaking: Range(5, 15),
        writing: Range(0, 5),
        mediation: Range(0, 2),
      ),
      reason:
          'A1-U1 predates the shape and introduces no writing or mediation '
          'yet; both start at U2. Same floors as U0.',
    ),
  },
  // One tier, because A1's texts deliberately do not climb: an A1
  // conversation is short at U2 and still short at U12. That is a real
  // curriculum observation about the A1-to-A2 step, recorded in the
  // triage notes — not something this gate should force by narrowing a
  // band A1 was never authored against. The listening band covers both a
  // lesson's whole conversation (4-8 short lines, so up to ~50 words) and
  // each transcript on its own (as short as two words: "Choose Iraq.").
  bandTiers: [
    LengthBandTier(
      throughUnitIndex: 12,
      listening: Range(2, 50),
      reading: Range(10, 60),
      writing: Range(20, 80),
    ),
  ],
  minimumNewSensesPerUnit: 30,
  sourceCardWords: Range(8, 60),
  maxPromptRepeatsPerUnit: 3,
  maxEnglishToArabicMatchesPerUnit: 1,
  // A1 has no one-model-text-per-unit design: 11 of its lessons carry a
  // readingText, spread unevenly across 13 units and across two lesson
  // types. A2 introduced the model text as a per-unit step. The band gate
  // below still checks every model text A1 does have.
  requiresModelTextPerUnit: false,
  // A1 gives each writing task its own guide rather than one guide per
  // unit; the guide must still sit inside the unit's band.
  wordGuideMustEqualBand: false,
  // A1's tags cross skill categories (most activities carry their lesson's
  // whole list). Re-tagging would drop objectives from published
  // activities, which the append-only policy forbids, so the category rule
  // is checked at unit level instead — see level_design_limits_test.dart.
  canDoTagging: CanDoTagging.unitLevel,
  finalMissionId: 'A1-FINAL-MISSION',
  finalAssessmentId: 'A1-FINAL-ASSESSMENT',
  capstonePassMark: 0.6,
  capstoneListeningWords: Range(5, 30),
  capstoneSourceWords: Range(8, 40),
  capstoneWordGuide: Range(30, 60),
  capstoneSuiteFile: 'test/content/levels/level_capstones_test.dart',
);

const _a2 = LevelGateConfig(
  levelId: 'a2',
  bundleAssetPath: 'assets/content/en/A2/a2-course-bundle.json',
  courseId: 'EN-A2-V1',
  prerequisiteLevelId: 'a1',
  finishedUnitIds: [
    'A2-U1',
    'A2-U2',
    'A2-U3',
    'A2-U4',
    'A2-U5',
    'A2-U6',
    'A2-U7',
    'A2-U8',
    'A2-U9',
    'A2-U10',
    'A2-U11',
    'A2-U12',
  ],
  unitShape: UnitShape(
    lessons: 7,
    activities: 36,
    encounter: 6,
    practice: 12,
    mastery: 18,
  ),
  skillBalance: SkillBalance(
    // Transcribed from a2_design_limits_test.dart as it stood before this
    // suite existed: listening had a floor and no ceiling, reading a
    // ceiling and no floor. Preserved exactly, so the port changes no
    // outcome for A2.
    listening: Range(10, 36),
    reading: Range(0, 12),
    speaking: Range(6, 8),
    writing: Range.exactly(3),
    mediation: Range.exactly(2),
  ),
  bandTiers: [
    LengthBandTier(
      throughUnitIndex: 4,
      listening: Range(30, 60),
      reading: Range(60, 100),
      writing: Range(55, 75),
    ),
    LengthBandTier(
      throughUnitIndex: 8,
      listening: Range(50, 90),
      reading: Range(90, 140),
      writing: Range(65, 85),
    ),
    LengthBandTier(
      throughUnitIndex: 12,
      listening: Range(70, 120),
      reading: Range(120, 180),
      writing: Range(75, 100),
    ),
  ],
  minimumNewSensesPerUnit: 30,
  sourceCardWords: Range(15, 60),
  maxPromptRepeatsPerUnit: 3,
  maxEnglishToArabicMatchesPerUnit: 1,
  requiresModelTextPerUnit: true,
  wordGuideMustEqualBand: true,
  canDoTagging: CanDoTagging.perActivitySkill,
  finalMissionId: 'A2-FINAL-MISSION',
  finalAssessmentId: 'A2-FINAL-ASSESSMENT',
  capstonePassMark: 0.6,
  capstoneListeningWords: Range(70, 120),
  capstoneSourceWords: Range(15, 60),
  capstoneWordGuide: Range(70, 90),
  capstoneSuiteFile: 'test/content/levels/level_capstones_test.dart',
);

/// Every level this suite holds to the standard. Adding B1 means adding a
/// config here; every gate in this directory then runs over it.
const kLevelGates = <LevelGateConfig>[_a1, _a2];
