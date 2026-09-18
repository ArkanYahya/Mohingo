import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/features/lesson_player/domain/lesson_phases.dart';

void main() {
  group('phaseGroupSizes', () {
    test('groups consecutive activities of the same mode — the usual '
        'encounter → practice → mastery lesson', () {
      expect(
        phaseGroupSizes(const [
          ActivityMode.encounter,
          ActivityMode.practice,
          ActivityMode.practice,
          ActivityMode.mastery,
          ActivityMode.mastery,
        ]),
        [1, 2, 2],
      );
    });

    test('a mission lesson (all mastery) is one group', () {
      expect(phaseGroupSizes(List.filled(6, ActivityMode.mastery)), [6]);
    });

    test('a mode that comes back later starts a new group, never merges '
        'with the earlier one — the bar follows the lesson\'s real order', () {
      expect(
        phaseGroupSizes(const [
          ActivityMode.practice,
          ActivityMode.mastery,
          ActivityMode.practice,
        ]),
        [1, 1, 1],
      );
    });

    test('an empty lesson has no groups', () {
      expect(phaseGroupSizes(const []), isEmpty);
    });
  });
}
