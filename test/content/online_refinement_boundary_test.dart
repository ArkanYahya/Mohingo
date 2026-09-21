import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ADR 0005's boundary, enforced against every shipped bundle.
///
/// [ADR 0005](docs/adr/0005-narrow-network-exception-for-open-ended-grading.md)
/// permits exactly one thing to leave the device: an open-ended answer on a
/// rubric explicitly marked `onlineRefinement`, sent to the public
/// LanguageTool API. It names its own limit in as many words — "never any
/// other PII, never audio, never a speech transcript verbatim".
///
/// A `speak` rubric marked that way breaks it. `SpeakActivityView._submit`
/// honours `onlineRefinement` on whatever activity carries it, so the text
/// it queues is the learner's **recognised speech** — a verbatim transcript,
/// leaving the device, which is the one thing the ADR rules out.
///
/// This is not hypothetical. A2's authoring applied one rubric template to
/// speaking and writing alike and marked 114 `speak` tasks plus 6 in the
/// Final Mission; commit `1893e23` unmarked all 120. Nothing would have
/// caught it, and nothing would catch it coming back, because the rule lived
/// only in an ADR. It lives here now.
///
/// Every bundle under `assets/content/en/` is walked, not a hardcoded pair,
/// so a level added later is covered the day its file lands rather than the
/// day somebody remembers this test.
List<File> _shippedBundles() {
  final root = Directory('assets/content/en');
  final bundles = [
    for (final entity in root.listSync(recursive: true))
      if (entity is File && entity.path.endsWith('-course-bundle.json')) entity,
  ];
  // Guards the walk below against passing vacuously: a renamed asset folder
  // would otherwise turn this gate green while checking nothing.
  expect(
    bundles.length,
    greaterThanOrEqualTo(2),
    reason:
        'expected at least the A1 and A2 bundles under ${root.path}, found '
        '${bundles.map((f) => f.path)}',
  );
  return bundles;
}

/// Every activity object in [bundle] — units, Final Mission, and each Final
/// Assessment section — paired with where it was found.
Iterable<({String where, Map<String, dynamic> activity})> _activities(
  Map<String, dynamic> bundle,
) sync* {
  for (final unit in bundle['units'] as List) {
    for (final lesson in (unit as Map)['lessons'] as List) {
      for (final a in (lesson as Map)['activities'] as List) {
        yield (
          where: lesson['id'] as String,
          activity: a as Map<String, dynamic>,
        );
      }
    }
  }
  final mission = bundle['finalMission'] as Map;
  for (final a in mission['activities'] as List) {
    yield (where: mission['id'] as String, activity: a as Map<String, dynamic>);
  }
  final assessment = bundle['finalAssessment'] as Map;
  for (final entry in (assessment['sections'] as Map).entries) {
    for (final a in (entry.value as Map)['activities'] as List) {
      yield (
        where: '${assessment['id']}.${entry.key}',
        activity: a as Map<String, dynamic>,
      );
    }
  }
}

void main() {
  test('no speaking task sends its transcript off the device', () {
    final offenders = <String>[];
    var speakTasks = 0;
    for (final file in _shippedBundles()) {
      final bundle =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final e in _activities(bundle)) {
        if (e.activity['type'] != 'speak') continue;
        speakTasks++;
        final evaluation = e.activity['evaluation'];
        if (evaluation is! Map) continue;
        if (evaluation['onlineRefinement'] == null) continue;
        offenders.add(
          '${e.activity['id']} (${e.where}, ${file.path}) is a speak task '
          'marked onlineRefinement: ${evaluation['onlineRefinement']} — '
          'SpeakActivityView would send the learner\'s recognised speech to '
          'the public LanguageTool API, which ADR 0005 rules out in as many '
          'words',
        );
      }
    }
    // Same reason as the bundle-count guard: a schema change that renamed
    // the type would leave nothing to find and nothing to report.
    expect(
      speakTasks,
      greaterThan(0),
      reason: 'no speak activities were found to check at all',
    );
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
