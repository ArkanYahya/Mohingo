import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/catalog/level_catalog.dart';

import 'level_gate_config.dart';

/// The gate suite's own gate.
///
/// Every file in this directory iterates [kLevelGates] and trusts what a
/// config says. These tests are what stops a config from quietly excusing
/// a level: an exception must name a unit that exists and say why, the
/// band tiers must cover every unit, and a released level must be in the
/// list at all.
void main() {
  test('every released level is gated', () {
    // If a level can ship without a config, this whole suite is optional
    // for it — which is exactly the state A1 was in.
    final released = [
      for (final entry in kLevelCatalog)
        if (entry.availability == LevelAvailability.available) entry.levelId,
    ];

    expect(released, isNotEmpty);
    expect(
      kLevelGates.map((g) => g.levelId),
      containsAll(released),
      reason:
          'a level is marked available in kLevelCatalog with no entry in '
          'kLevelGates, so none of the content gates run over it',
    );
  });

  for (final gate in kLevelGates) {
    group(gate.levelId.toUpperCase(), () {
      test('the config names the bundle it actually loads', () {
        expect(gate.bundle().course.id, gate.courseId);
      });

      test('the finished list is not empty and names real, distinct '
          'units', () {
        expect(gate.finishedUnitIds, isNotEmpty);
        expect(
          gate.finishedUnitIds.toSet().length,
          gate.finishedUnitIds.length,
          reason: '${gate.levelId} finished list contains a duplicate',
        );
        final inBundle = {for (final u in gate.bundle().units) u.id};
        expect(
          inBundle.containsAll(gate.finishedUnitIds),
          isTrue,
          reason:
              '${gate.levelId} names a unit its bundle does not contain: '
              '${gate.finishedUnitIds.toSet().difference(inBundle)}',
        );
      });

      test('every declared exception names a finished unit and says why', () {
        // A stale exception is worse than none: it silently excuses a unit
        // that no longer needs excusing, and nothing would ever say so.
        final unitIds = gate.finishedUnitIds.toSet();
        final excepted = {
          ...gate.unitShapeExceptions.keys,
          ...gate.skillBalanceExceptions.keys,
        };
        for (final unitId in excepted) {
          expect(
            unitIds,
            contains(unitId),
            reason:
                '${gate.levelId} excepts $unitId, which is not one of its '
                'finished units',
          );
          expect(
            gate.why(unitId).trim(),
            isNotEmpty,
            reason: 'an exception with no reason is a skip wearing a hat',
          );
        }
      });

      test('the band tiers cover every finished unit', () {
        // Without this, adding U13 to a level would silently reuse the
        // last tier's numbers instead of failing.
        for (final unit in gate.finishedUnits()) {
          expect(
            () => gate.bandsFor(unit.id),
            returnsNormally,
            reason: 'no length band covers ${unit.id}',
          );
        }
      });

      test('the capstones the config names are the ones the bundle has', () {
        final bundle = gate.bundle();
        expect(bundle.finalMission.id, gate.finalMissionId);
        expect(bundle.finalAssessment.id, gate.finalAssessmentId);
      });

      test('the prerequisite the config names is a level that exists', () {
        final prerequisite = gate.prerequisiteLevelId;
        if (prerequisite == null) return;
        expect(
          kLevelGates.map((g) => g.levelId),
          contains(prerequisite),
          reason:
              '${gate.levelId} builds on $prerequisite, which has no gate '
              'config — its earlier-level references would resolve against '
              'nothing',
        );
      });
    });
  }

  test('no id is shared between any two levels', () {
    // A shared id means one learner's attempt is evidence in two levels at
    // once, and there is no foreign key anywhere to notice.
    final owner = <String, String>{};
    for (final gate in kLevelGates) {
      for (final unit in gate.bundle().units) {
        for (final id in <String>[
          unit.id,
          for (final lesson in unit.lessons) ...[
            lesson.id,
            for (final activity in lesson.activities) activity.id,
          ],
        ]) {
          expect(
            owner[id],
            isNull,
            reason: '$id belongs to both ${owner[id]} and ${gate.levelId}',
          );
          owner[id] = gate.levelId;
        }
      }
    }
    expect(owner, isNotEmpty);
  });
}
