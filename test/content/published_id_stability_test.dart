import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/publication/published_id_snapshot.dart';

/// Ids are permanent once a level ships.
///
/// `activity_attempts` stores `activityId`, `lessonId`, `mode` and
/// `canDoId` as plain strings with no foreign key, so a learner's recorded
/// evidence outlives the content it points at: a reused id re-attributes
/// their work, a changed mode re-counts it, a dropped objective strands
/// it. Until this gate existed, the whole enforcement was a comment in
/// `lib/data/local/tables/attempt_tables.dart`.
///
/// `test/content/published/*.json` is the record of what shipped. After
/// adding content, run:
///
///     dart run tool/update_published_ids.dart
///
/// and commit the diff. The script merges — it will not drop an id, and it
/// will not record new ids under an unchanged `contentVersion`.
const _levelBundles = {
  'a1': 'assets/content/en/A1/a1-course-bundle.json',
  'a2': 'assets/content/en/A2/a2-course-bundle.json',
};

PublishedIdSnapshot _published(String levelId) => PublishedIdSnapshot.fromJson(
  jsonDecode(
    File('test/content/published/$levelId-published-ids.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>,
);

PublishedIdSnapshot _current(String levelId) => PublishedIdSnapshot.fromBundle(
  CourseBundleParser.parse(File(_levelBundles[levelId]!).readAsStringSync()),
);

void main() {
  test('every level with a shipped bundle has a published snapshot', () {
    // Otherwise a level added later is guarded by nothing, silently, and
    // the per-level groups below would simply not exist for it.
    for (final levelId in _levelBundles.keys) {
      expect(
        File('test/content/published/$levelId-published-ids.json').existsSync(),
        isTrue,
        reason:
            '$levelId ships a bundle with no published id snapshot; run '
            '`dart run tool/update_published_ids.dart`',
      );
    }
  });

  for (final levelId in _levelBundles.keys) {
    group(levelId.toUpperCase(), () {
      test('the published snapshot is not empty', () {
        // First, because every check below iterates it: an empty snapshot
        // would make them all pass while protecting nothing.
        final published = _published(levelId);
        expect(published.unitIds, isNotEmpty);
        expect(published.lessonIds, isNotEmpty);
        expect(published.activities, isNotEmpty);
        expect(published.canDoIds, isNotEmpty);
      });

      test('nothing published has been removed, re-moded or un-tagged', () {
        final violations = publicationViolations(
          published: _published(levelId),
          current: _current(levelId),
        );

        expect(
          violations,
          isEmpty,
          reason:
              'ids are permanent after publication:\n'
              '${violations.join('\n')}',
        );
      });

      test('the snapshot covers everything the bundle now publishes', () {
        // The forcing function. Without it, content added without running
        // the script would sit outside the guard indefinitely — and
        // nobody would notice, because nothing would fail.
        //
        // Phrased in its own direction rather than by reusing
        // publicationViolations, whose messages are written for the
        // opposite one: "was published and is gone" is exactly backwards
        // for an id the bundle has and the snapshot does not, and a
        // failure message describing the wrong problem sends the next
        // reader hunting for a deletion that never happened.
        final published = _published(levelId);
        final current = _current(levelId);
        final unrecorded = <String>[
          for (final id in current.unitIds.difference(published.unitIds))
            'unit $id',
          for (final id in current.lessonIds.difference(published.lessonIds))
            'lesson $id',
          for (final id in current.activities.keys.toSet().difference(
            published.activities.keys.toSet(),
          ))
            'activity $id',
          for (final id in current.canDoIds.difference(published.canDoIds))
            'objective $id',
        ]..sort();

        expect(
          unrecorded,
          isEmpty,
          reason:
              'the bundle publishes ids the snapshot does not record, so '
              'they are outside this guard. Run '
              '`dart run tool/update_published_ids.dart` and commit the '
              'diff:\n${unrecorded.join('\n')}',
        );
      });

      test('the snapshot was recorded under the bundle\'s own '
          'contentVersion', () {
        // Catches a hand-edited snapshot, and a bundle whose version was
        // bumped without regenerating. The rule the version itself has to
        // keep — that ids may not change under an unchanged version —
        // lives in the script, which is the only place that sees both the
        // old snapshot and the new bundle.
        expect(
          _published(levelId).contentVersion,
          _current(levelId).contentVersion,
          reason:
              'run `dart run tool/update_published_ids.dart` and commit '
              'the diff',
        );
      });
    });
  }
}
