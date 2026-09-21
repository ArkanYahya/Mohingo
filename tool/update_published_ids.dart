// Records the ids the shipped bundles now publish.
//
//   dart run tool/update_published_ids.dart
//
// Run this after ADDING content, and commit the diff it produces.
//
// It merges. It will never drop an id, change a published mode, drop a
// published objective, or record new ids under an unchanged
// `contentVersion` — if the bundle did any of those it prints what and
// exits non-zero rather than writing. Retiring a published id is a
// deliberate act that means hand-editing the JSON, and the reviewer of
// that commit should be able to say why.
//
// See test/content/published_id_stability_test.dart.
import 'dart:convert';
import 'dart:io';

import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/publication/published_id_snapshot.dart';

const levelBundles = {
  'a1': 'assets/content/en/A1/a1-course-bundle.json',
  'a2': 'assets/content/en/A2/a2-course-bundle.json',
};

String snapshotPathFor(String levelId) =>
    'test/content/published/$levelId-published-ids.json';

void main() {
  var failed = false;

  for (final entry in levelBundles.entries) {
    final bundle = CourseBundleParser.parse(
      File(entry.value).readAsStringSync(),
    );
    final current = PublishedIdSnapshot.fromBundle(bundle);
    final file = File(snapshotPathFor(entry.key));

    PublishedIdSnapshot next;
    if (file.existsSync()) {
      final published = PublishedIdSnapshot.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );
      try {
        next = mergeForPublication(published: published, current: current);
      } on StateError catch (e) {
        stderr.writeln('${entry.key}: ${e.message}');
        failed = true;
        continue;
      }
    } else {
      next = current;
    }

    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(next.toJson())}\n',
    );
    stdout.writeln(
      '${entry.key}: ${next.unitIds.length} units, '
      '${next.lessonIds.length} lessons, '
      '${next.activities.length} activities, '
      '${next.canDoIds.length} objectives '
      '@ ${next.contentVersion}',
    );
  }

  if (failed) exit(1);
}
