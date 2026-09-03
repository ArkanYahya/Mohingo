import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/features/placement_test/domain/placement_item_sampler.dart';

/// Exercises [PlacementItemSampler] against the real A1 bundle asset — the
/// same "no fixture, real content" approach used by
/// test/features/lesson_player/lesson_player_e2e_test.dart, since the
/// sampler's whole job is to draw honestly from real `practice` content.
void main() {
  final raw = File('assets/content/en/A1/a1-course-bundle.json')
      .readAsStringSync();
  final bundle = CourseBundleParser.parse(raw);
  final unitWithContent = bundle.units.firstWhere((u) => u.id == 'A1-U1');

  group('PlacementItemSampler.receptiveItemsForUnit', () {
    test('only samples practice-mode listening/reading items — never '
        'mastery (training evidence) or encounter (first exposure)', () {
      final items = PlacementItemSampler.receptiveItemsForUnit(
        unitWithContent,
        seed: 1,
      );
      expect(items, isNotEmpty);
      for (final item in items) {
        expect(item.mode, ActivityMode.practice);
        expect(item.skill, anyOf(Skill.listening, Skill.reading));
      }
    });

    test('never returns more than maxReceptiveItemsPerUnit', () {
      final items = PlacementItemSampler.receptiveItemsForUnit(
        unitWithContent,
        seed: 42,
      );
      expect(
        items.length,
        lessThanOrEqualTo(PlacementItemSampler.maxReceptiveItemsPerUnit),
      );
    });

    test('same seed is deterministic — a retake with the same seed would '
        'draw the exact same items', () {
      final first = PlacementItemSampler.receptiveItemsForUnit(
        unitWithContent,
        seed: 7,
      );
      final second = PlacementItemSampler.receptiveItemsForUnit(
        unitWithContent,
        seed: 7,
      );
      expect(first.map((a) => a.id), second.map((a) => a.id));
    });

    test('empty for a unit with no lessons at all', () {
      final emptyUnit = bundle.units.firstWhere(
        (u) => u.lessons.isEmpty,
        orElse: () => unitWithContent,
      );
      if (emptyUnit.id == unitWithContent.id) return; // no such unit exists
      expect(
        PlacementItemSampler.receptiveItemsForUnit(emptyUnit, seed: 1),
        isEmpty,
      );
    });
  });

  group('PlacementItemSampler.productiveItemForUnit', () {
    test('samples a write/speak item regardless of mode — verified against '
        'the real bundle, every unit except A1-U0 has zero practice-mode '
        'write/speak activities at all, so restricting to practice-mode '
        'would silently skip this step almost everywhere', () {
      final item = PlacementItemSampler.productiveItemForUnit(
        unitWithContent, // A1-U1: write/speak activities exist, all mastery-mode
        seed: 1,
      );
      expect(item, isNotNull);
      expect(item, anyOf(isA<WriteActivity>(), isA<SpeakActivity>()));
    });

    test('null for a unit with no write/speak activities at all', () {
      final noProductiveUnit = bundle.units.firstWhere(
        (u) => u.lessons.every(
          (l) => l.activities.every(
            (a) => a is! WriteActivity && a is! SpeakActivity,
          ),
        ),
        orElse: () => unitWithContent,
      );
      if (noProductiveUnit.id == unitWithContent.id) return; // none exist
      expect(
        PlacementItemSampler.productiveItemForUnit(noProductiveUnit, seed: 1),
        isNull,
      );
    });
  });
}
