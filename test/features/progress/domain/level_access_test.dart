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
      expect(currentLevelIdFor(enrolments: const [], catalog: _catalog), 'a1');
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
      // The pre-tracking enrolment must actually win the "most recent"
      // comparison — otherwise this proves nothing about the null->base
      // mapping, only that an enrolment skipped for having no
      // lastSelectedAt falls back to the base level like having none at
      // all does (see "a learner who has chosen nothing" above).
      final current = currentLevelIdFor(
        enrolments: [
          _enrolment(levelId: null, lastSelectedAt: DateTime.utc(2026, 9, 20)),
          _enrolment(levelId: 'a2', lastSelectedAt: DateTime.utc(2026, 9, 19)),
        ],
        catalog: _catalog,
      );
      expect(current, 'a1');
    });

    test('a level that is no longer in the catalogue is ignored', () {
      expect(
        currentLevelIdFor(
          enrolments: [
            _enrolment(
              levelId: 'zz',
              lastSelectedAt: DateTime.utc(2026, 9, 20),
            ),
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

      expect(levelComplete(units: units, masteredUnitIds: {'A1-U1'}), isTrue);
      expect(levelComplete(units: units, masteredUnitIds: const {}), isFalse);
      expect(
        levelComplete(units: const [], masteredUnitIds: const {}),
        isFalse,
      );
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
