import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/publication/published_id_snapshot.dart';

PublishedIdSnapshot _snap({
  String contentVersion = 'V1',
  Set<String> units = const {'U1'},
  Set<String> lessons = const {'U1-L1'},
  Map<String, PublishedActivity> activities = const {},
  Set<String> canDoIds = const {'X.LISTENING.1'},
}) => PublishedIdSnapshot(
  courseId: 'EN-A2-V1',
  contentVersion: contentVersion,
  unitIds: units,
  lessonIds: lessons,
  activities: activities,
  canDoIds: canDoIds,
);

const _a01 = 'U1-L1-A01';
const _mastery = PublishedActivity(mode: 'mastery', canDo: {'X.LISTENING.1'});

void main() {
  test('an unchanged bundle is a legal successor', () {
    final published = _snap(activities: const {_a01: _mastery});

    expect(
      publicationViolations(published: published, current: published),
      isEmpty,
    );
  });

  test('added content is legal: a new unit, a new activity, a new tag', () {
    final violations = publicationViolations(
      published: _snap(activities: const {_a01: _mastery}),
      current: _snap(
        units: const {'U1', 'U2'},
        lessons: const {'U1-L1', 'U2-L1'},
        activities: const {
          _a01: PublishedActivity(
            mode: 'mastery',
            canDo: {'X.LISTENING.1', 'X.LISTENING.2'},
          ),
          'U2-L1-A01': PublishedActivity(mode: 'practice', canDo: {'X.R.1'}),
        },
        canDoIds: const {'X.LISTENING.1', 'X.LISTENING.2', 'X.R.1'},
      ),
    );

    expect(violations, isEmpty);
  });

  test('a removed activity id is a violation that names it', () {
    final violations = publicationViolations(
      published: _snap(activities: const {_a01: _mastery}),
      current: _snap(activities: const {}),
    );

    expect(violations, hasLength(1));
    expect(violations.single, contains(_a01));
  });

  test('a changed mode is a violation, and says both modes', () {
    final violations = publicationViolations(
      published: _snap(
        activities: const {
          _a01: PublishedActivity(mode: 'practice', canDo: {'X.LISTENING.1'}),
        },
      ),
      current: _snap(activities: const {_a01: _mastery}),
    );

    expect(violations.single, allOf(contains('practice'), contains('mastery')));
  });

  test('a dropped canDo tag is a violation — canDo is append-only', () {
    final violations = publicationViolations(
      published: _snap(
        activities: const {
          _a01: PublishedActivity(
            mode: 'mastery',
            canDo: {'X.LISTENING.1', 'X.LISTENING.2'},
          ),
        },
      ),
      current: _snap(activities: const {_a01: _mastery}),
    );

    expect(violations.single, contains('X.LISTENING.2'));
  });

  test('a removed unit, lesson and objective are each reported, not just '
      'the first', () {
    final violations = publicationViolations(
      published: _snap(
        units: const {'U1', 'U2'},
        lessons: const {'U1-L1', 'U2-L1'},
        canDoIds: const {'X.LISTENING.1', 'X.R.1'},
      ),
      current: _snap(),
    );

    expect(violations, hasLength(3));
  });

  test('a changed course id is a violation on its own', () {
    final violations = publicationViolations(
      published: _snap(),
      current: PublishedIdSnapshot(
        courseId: 'EN-A2-V2',
        contentVersion: 'V1',
        unitIds: const {'U1'},
        lessonIds: const {'U1-L1'},
        activities: const {},
        canDoIds: const {'X.LISTENING.1'},
      ),
    );

    expect(
      violations.single,
      allOf(contains('EN-A2-V1'), contains('EN-A2-V2')),
    );
  });

  test('publishedIdsDiffer sees an addition, a removal and neither', () {
    final base = _snap(activities: const {_a01: _mastery});

    expect(publishedIdsDiffer(base, base), isFalse);
    expect(
      publishedIdsDiffer(
        base,
        _snap(units: const {'U1', 'U2'}, activities: const {_a01: _mastery}),
      ),
      isTrue,
    );
    expect(publishedIdsDiffer(base, _snap()), isTrue);
    // A changed mode is not an id change: the version gate is about which
    // ids exist, and publicationViolations already refuses this one.
    expect(
      publishedIdsDiffer(
        base,
        _snap(
          activities: const {
            _a01: PublishedActivity(mode: 'practice', canDo: {'X.LISTENING.1'}),
          },
        ),
      ),
      isFalse,
    );
  });

  test('mergeForPublication adds what is new and keeps what was published', () {
    final merged = mergeForPublication(
      published: _snap(activities: const {_a01: _mastery}),
      current: _snap(
        contentVersion: 'V2',
        units: const {'U1', 'U2'},
        activities: const {
          _a01: PublishedActivity(
            mode: 'mastery',
            canDo: {'X.LISTENING.1', 'X.LISTENING.2'},
          ),
        },
      ),
    );

    expect(merged.unitIds, {'U1', 'U2'});
    expect(merged.contentVersion, 'V2');
    expect(merged.activities[_a01]!.canDo, {'X.LISTENING.1', 'X.LISTENING.2'});
  });

  test(
    'mergeForPublication refuses to launder a removal into the snapshot',
    () {
      // This is the whole point of the script being a merge. If regenerating
      // the snapshot could erase an id, the gate would be one command away
      // from meaningless.
      expect(
        () => mergeForPublication(
          published: _snap(activities: const {_a01: _mastery}),
          current: _snap(contentVersion: 'V2', activities: const {}),
        ),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('mergeForPublication refuses to record new ids under an unchanged '
      'contentVersion', () {
    // A learner's device treats an unchanged contentVersion as "not an
    // upgrade" and skips the whole diff, so content that changed without
    // bumping it is invisible to stale detection on every device. A2's
    // string went unchanged through the entire authoring of the level.
    expect(
      () => mergeForPublication(
        published: _snap(activities: const {_a01: _mastery}),
        current: _snap(
          units: const {'U1', 'U2'},
          activities: const {_a01: _mastery},
        ),
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('contentVersion'),
        ),
      ),
    );
  });

  test('an unchanged contentVersion is fine when no id moved', () {
    // Prose, transcripts and rubrics change without ids moving, and a
    // version bump is not required for those. The gate fires in one
    // direction only.
    final published = _snap(activities: const {_a01: _mastery});

    expect(
      () => mergeForPublication(published: published, current: published),
      returnsNormally,
    );
  });

  test('a snapshot survives a round trip through JSON', () {
    final snapshot = _snap(activities: const {_a01: _mastery});
    final restored = PublishedIdSnapshot.fromJson(snapshot.toJson());

    expect(
      publicationViolations(published: snapshot, current: restored),
      isEmpty,
    );
    expect(
      publicationViolations(published: restored, current: snapshot),
      isEmpty,
    );
    expect(restored.contentVersion, snapshot.contentVersion);
  });
}
