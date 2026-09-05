import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/curriculum_structure.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/features/learning_path/domain/current_unit_selector.dart';

Unit _unit(String id) => Unit(
  id: id,
  title: id,
  titleAr: id,
  levelRole: 'core',
  estimatedMinutes: const [1, 2],
  countsTowardA1Mastery: true,
  lessons: const [],
  mastery: const UnitMastery(
    requiredObjectives: [],
    requiredSkillGroups: [],
    minimumObjectiveScore: null,
    raw: {},
  ),
);

LessonProgressData _progress({
  required String unitId,
  required String lessonId,
  DateTime? lastPositionUpdatedAt,
}) => LessonProgressData(
  id: 0,
  uuid: '$unitId-$lessonId',
  learnerId: 1,
  lessonId: lessonId,
  unitId: unitId,
  state: 'inProgress',
  lastPositionUpdatedAt: lastPositionUpdatedAt,
  updatedAt: lastPositionUpdatedAt ?? DateTime.utc(2026, 9, 5),
);

void main() {
  final units = [_unit('U0'), _unit('U1'), _unit('U2')];

  test(
    'with no activity anywhere, returns the first not-yet-mastered unit',
    () {
      expect(
        currentUnitId(
          units: units,
          masteredUnitIds: const {},
          allLessonProgress: const [],
        ),
        'U0',
      );
    },
  );

  test('with no activity anywhere and the first unit already mastered, '
      'returns the next not-yet-mastered unit', () {
    expect(
      currentUnitId(
        units: units,
        masteredUnitIds: const {'U0'},
        allLessonProgress: const [],
      ),
      'U1',
    );
  });

  test('tracks the most recently active, not-yet-mastered unit — the '
      'reported bug: a learner who finished U0 imperfectly and moved on to '
      'U1 should show U1, not stay stuck on U0', () {
    expect(
      currentUnitId(
        units: units,
        masteredUnitIds: const {}, // U0 never fully mastered (2 wrong)
        allLessonProgress: [
          _progress(
            unitId: 'U0',
            lessonId: 'U0-L1',
            lastPositionUpdatedAt: DateTime.utc(2026, 9, 1),
          ),
          _progress(
            unitId: 'U1',
            lessonId: 'U1-L1',
            lastPositionUpdatedAt: DateTime.utc(2026, 9, 5),
          ),
        ],
      ),
      'U1',
    );
  });

  test('when the most recently active unit is already fully mastered, '
      'advances to the next not-yet-mastered unit instead of lingering', () {
    expect(
      currentUnitId(
        units: units,
        masteredUnitIds: const {'U0'},
        allLessonProgress: [
          _progress(
            unitId: 'U0',
            lessonId: 'U0-L1',
            lastPositionUpdatedAt: DateTime.utc(2026, 9, 5),
          ),
        ],
      ),
      'U1',
    );
  });

  test('a lesson-progress row with no timestamp yet is ignored', () {
    expect(
      currentUnitId(
        units: units,
        masteredUnitIds: const {},
        allLessonProgress: [
          _progress(unitId: 'U1', lessonId: 'U1-L1'), // no timestamp
        ],
      ),
      'U0', // falls back to curriculum order, since U1's row can't compare
    );
  });

  test('every unit mastered returns null', () {
    expect(
      currentUnitId(
        units: units,
        masteredUnitIds: const {'U0', 'U1', 'U2'},
        allLessonProgress: const [],
      ),
      isNull,
    );
  });
}
