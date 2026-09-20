import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/catalog/level_catalog.dart';
import 'package:mohingo/content/models/domain_definitions.dart';

import 'a2_finished_units.dart';

void main() {
  test('answering every mastery item correctly masters the unit', () {
    for (final unit in finishedA2Units()) {
      final evidenced = <String>{};
      // requiredSkillGroups (e.g. ["listening", "reading"]) names natural
      // skills, never canDo objective ids, so its coverage is tracked
      // separately from `evidenced` — mirroring MasteryAggregationService's
      // own coveredSkills, which is built from each attempt's
      // evidenceSkill, not from the canDo id it also carries.
      final evidencedSkills = <String>{};
      for (final a in activitiesOf(unit)) {
        if (a.mode != ActivityMode.mastery) continue;
        evidenced.addAll(a.canDo);
        evidencedSkills.add(a.skill.name);
      }
      for (final objective in unit.mastery.requiredObjectives) {
        expect(
          evidenced,
          contains(objective),
          reason:
              '${unit.id} requires $objective, which no mastery '
              'activity evidences',
        );
      }
      for (final group in unit.mastery.requiredSkillGroups) {
        expect(
          group.any(evidencedSkills.contains),
          isTrue,
          reason: '${unit.id} skill group $group has no evidence',
        );
      }
    }
  });

  test('A2 stays a preview until every unit is finished', () {
    final a2 = kLevelCatalog.firstWhere((e) => e.levelId == 'a2');
    if (a2.availability == LevelAvailability.available) {
      expect(
        a2FinishedUnitIds.length,
        12,
        reason:
            'A2 is marked available with only '
            '${a2FinishedUnitIds.length} finished units',
      );
    }
  });
}
