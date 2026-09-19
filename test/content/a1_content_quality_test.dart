import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Checks the shipped A1 bundle for authoring slips a learner would see:
/// Arabic in an English prompt, authoring notes in a grammar meaning, and
/// answer options that are internal keys rather than words.
final _bundle = jsonDecode(
  File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync(),
) as Map<String, dynamic>;

final _arabic = RegExp('[\u0600-\u06FF]');

Iterable<Map<String, dynamic>> _activities() sync* {
  for (final unit in _bundle['units'] as List) {
    for (final lesson in (unit as Map)['lessons'] as List) {
      yield* ((lesson as Map)['activities'] as List)
          .cast<Map<String, dynamic>>();
    }
  }
  yield* ((_bundle['finalMission'] as Map)['activities'] as List)
      .cast<Map<String, dynamic>>();
  for (final section
      in ((_bundle['finalAssessment'] as Map)['sections'] as Map).values) {
    yield* ((section as Map)['activities'] as List)
        .cast<Map<String, dynamic>>();
  }
}

void main() {
  test('English prompts are in English — Arabic goes in promptAr', () {
    final offenders = [
      for (final a in _activities())
        if (_arabic.hasMatch(a['prompt'] as String? ?? '')) a['id'],
    ];
    expect(offenders, isEmpty);
  });

  test('grammar meanings carry no authoring notes', () {
    final note = RegExp(r'مؤجل|تحليل|تعامل ك|إلزامي|وظيفي|U\d');
    final offenders = [
      for (final g in (_bundle['grammar'] as List).cast<Map>())
        if (note.hasMatch(g['meaningAr'] as String)) g['id'],
    ];
    expect(offenders, isEmpty);
  });

  test('choice options are words a learner can read, or pictures the app '
      'can draw — never internal keys', () {
    final key = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)+$');
    final media = (_bundle['mediaSpecifications'] as Map).keys.toSet();
    final offenders = [
      for (final a in _activities())
        for (final option in (a['options'] as List? ?? const []))
          if (option is String &&
              (a['optionMode'] == 'media'
                  ? !media.contains(option)
                  : key.hasMatch(option)))
            '${a['id']}: $option',
    ];
    expect(offenders, isEmpty);
  });
}
