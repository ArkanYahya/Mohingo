import '../models/activity.dart';
import '../models/course_bundle.dart';
import '../models/curriculum_structure.dart';
import '../models/exceptions.dart';
import '../models/registry_items.dart';

/// An id-keyed in-memory index over a parsed [CourseBundle], built once at
/// startup and held for the app's lifetime — never rebuilt per screen. See
/// docs/ARCHITECTURE.md's content-loading strategy.
///
/// Also performs defense-in-depth unresolved-reference validation
/// ([_validateReferences]) — redundant with the curriculum package's own
/// `unresolvedReferencesForbidden` build-time guarantee, but cheap insurance
/// against a corrupted or stale asset shipped by accident.
class CourseContentIndex {
  CourseContentIndex._({
    required this.bundle,
    required this.unitsById,
    required this.lessonsById,
    required this.activitiesById,
    required this.grammarById,
    required this.lexiconById,
    required this.chunkById,
    required this.activitiesByCanDoId,
    required this.unitIdByLessonId,
    required this.prerequisite,
  });

  /// Builds and validates the index. Throws
  /// [UnresolvedContentReferenceException] if any lesson/activity/unit
  /// references a Can-Do/grammar/lexicon/chunk id that doesn't resolve —
  /// grammar, words and phrases may also resolve in [prerequisite], the
  /// earlier level this one builds on (an A2 lesson reviewing A1's `I am`).
  factory CourseContentIndex.build(
    CourseBundle bundle, {
    CourseContentIndex? prerequisite,
  }) {
    final unitsById = <String, Unit>{};
    final lessonsById = <String, Lesson>{};
    final activitiesById = <String, Activity>{};
    final unitIdByLessonId = <String, String>{};
    final activitiesByCanDoId = <String, List<Activity>>{};

    void indexActivity(Activity activity, {bool indexByCanDo = true}) {
      activitiesById[activity.id] = activity;
      if (indexByCanDo) {
        for (final canDoId in activity.canDo) {
          activitiesByCanDoId.putIfAbsent(canDoId, () => []).add(activity);
        }
      }
    }

    for (final unit in bundle.units) {
      unitsById[unit.id] = unit;
      for (final lesson in unit.lessons) {
        lessonsById[lesson.id] = lesson;
        unitIdByLessonId[lesson.id] = unit.id;
        for (final activity in lesson.activities) {
          indexActivity(activity);
        }
      }
    }

    for (final activity in bundle.finalMission.activities) {
      indexActivity(activity);
    }

    // Final-assessment items are indexed by id (so a route/deep-link can
    // resolve them) but deliberately NOT added to activitiesByCanDoId — that
    // reverse index backs "practice this weak objective" links in Review,
    // and assessment items must never be surfaced there. See
    // docs/DATA_MODEL.md's isolation invariant.
    for (final activity in bundle.finalAssessment.allActivities) {
      indexActivity(activity, indexByCanDo: false);
    }

    final index = CourseContentIndex._(
      bundle: bundle,
      unitsById: unitsById,
      lessonsById: lessonsById,
      activitiesById: activitiesById,
      grammarById: {for (final g in bundle.grammar) g.id: g},
      lexiconById: {for (final l in bundle.lexicon) l.id: l},
      chunkById: {for (final c in bundle.chunks) c.id: c},
      activitiesByCanDoId: activitiesByCanDoId,
      unitIdByLessonId: unitIdByLessonId,
      prerequisite: prerequisite,
    );

    index._validateReferences();
    return index;
  }

  final CourseBundle bundle;
  final Map<String, Unit> unitsById;
  final Map<String, Lesson> lessonsById;
  final Map<String, Activity> activitiesById;
  final Map<String, GrammarItem> grammarById;
  final Map<String, LexiconItem> lexiconById;
  final Map<String, ChunkItem> chunkById;

  /// The earlier level's index, when this level builds on one (A2 on A1) —
  /// see `LevelCatalogEntry.prerequisiteLevelId`. Null for A1.
  final CourseContentIndex? prerequisite;

  /// This level's grammar record [id], or the prerequisite's. The
  /// `*ById` maps hold this level's own records only; use these for ids a
  /// lesson lists, which may point to an earlier level.
  GrammarItem? resolveGrammar(String id) =>
      grammarById[id] ?? prerequisite?.resolveGrammar(id);

  /// See [resolveGrammar].
  LexiconItem? resolveLexicon(String id) =>
      lexiconById[id] ?? prerequisite?.resolveLexicon(id);

  /// See [resolveGrammar].
  ChunkItem? resolveChunk(String id) =>
      chunkById[id] ?? prerequisite?.resolveChunk(id);

  /// Reverse index used by Review's "weak objective -> practice this" links.
  /// Training content only — see [CourseContentIndex.build]'s note on why
  /// final-assessment items are excluded.
  final Map<String, List<Activity>> activitiesByCanDoId;
  final Map<String, String> unitIdByLessonId;

  bool lessonExists(String unitId, String lessonId) {
    final unit = unitsById[unitId];
    if (unit == null) return false;
    return unit.lessons.any((l) => l.id == lessonId);
  }

  void _validateReferences() {
    final errors = <String>[];

    void checkCanDo(String context, Iterable<String> ids) {
      for (final id in ids) {
        if (!bundle.domain.canDoIds.contains(id)) {
          errors.add('$context references unknown Can-Do id "$id"');
        }
      }
    }

    void checkRegistry(
      String context,
      Iterable<String> ids,
      Object? Function(String id) resolve,
      String kind,
    ) {
      for (final id in ids) {
        if (resolve(id) == null) {
          errors.add('$context references unknown $kind id "$id"');
        }
      }
    }

    for (final unit in bundle.units) {
      checkCanDo(
        'Unit ${unit.id}.mastery.requiredObjectives',
        unit.mastery.requiredObjectives,
      );
      for (final lesson in unit.lessons) {
        checkCanDo('Lesson ${lesson.id}.canDo', lesson.canDo);
        checkRegistry(
          'Lesson ${lesson.id}.grammar',
          lesson.grammar,
          resolveGrammar,
          'grammar',
        );
        checkRegistry(
          'Lesson ${lesson.id}.lexicon',
          lesson.lexicon,
          resolveLexicon,
          'lexicon',
        );
        checkRegistry(
          'Lesson ${lesson.id}.chunks',
          lesson.chunks,
          resolveChunk,
          'chunk',
        );
        for (final activity in lesson.activities) {
          checkCanDo('Activity ${activity.id}.canDo', activity.canDo);
        }
      }
    }

    checkCanDo('FinalMission.canDo', bundle.finalMission.canDo);
    for (final activity in bundle.finalMission.activities) {
      checkCanDo('Activity ${activity.id}.canDo', activity.canDo);
    }
    for (final activity in bundle.finalAssessment.allActivities) {
      checkCanDo('Activity ${activity.id}.canDo', activity.canDo);
    }

    if (errors.isNotEmpty) {
      throw UnresolvedContentReferenceException(errors.join('; '));
    }
  }
}
