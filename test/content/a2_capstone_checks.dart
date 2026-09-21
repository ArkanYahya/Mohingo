import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/course_bundle.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/content/models/evaluation_spec.dart';

/// The A2 capstone content rules, as pure functions over a parsed bundle.
///
/// They live here rather than inline in `a2_capstones_test.dart` because two
/// files have to apply them: that file, which runs them gate by gate on every
/// `flutter test`, and `a2_masterable_test.dart`'s release rule, which must
/// re-run them the day A2 is marked `available`. Deleting this file breaks
/// both, which is the point — the release gate cannot be satisfied by a level
/// whose capstone checks no longer exist.
///
/// Each function returns a list of human-readable offenders rather than
/// calling `expect` itself, so the same rule reads identically from a
/// focused gate and from the release gate, and so a failure always names the
/// activity and the value that broke it.
///
/// Scope note: `bundle.units` gates (see `a2_finished_units.dart`) walk the
/// twelve units. Nothing there ever looks at `finalMission` or
/// `finalAssessment`, so without this file the two capstones — the only two
/// objects a learner must clear to leave A2 — are ungated.

/// Arabic script. A field that merely repeats its English string — the
/// cheapest way to pass a "has Arabic" check — never matches this.
final _arabic = RegExp(r'[؀-ۿ]');

/// Word counting, matching `a2_design_limits_test.dart`'s `_words`.
final _wordPattern = RegExp(r"[A-Za-z']+");

/// Overlap tokens. Broader than [_wordPattern] on purpose: a reused run like
/// "the bus leaves at 8 40" is the same reuse whether or not it has digits
/// in it, so the unseen-input gate must not be blind to numbers.
final _tokenPattern = RegExp(r"[a-z0-9']+");

/// The run length the unseen-input gate treats as reuse. Six words is long
/// enough that ordinary A2 phrasing ("what time does the bus leave") does
/// not trip it by coincidence, and short enough to catch a sentence lifted
/// from a unit and lightly edited at its ends.
const capstoneOverlapWindow = 6;

/// The pass mark both A2 exits share, matching A1's. Both are keyword-marked
/// by the same evaluator, so "passed the A2 mission" and "passed the A2
/// assessment" have to mean the same thing. The import shipped 0.75; it was
/// lowered deliberately, and this constant is what stops it drifting back.
const capstonePassMark = 0.6;

int _words(String? value) => _wordPattern.allMatches(value ?? '').length;

String? _string(Object? value) => value is String ? value : null;

/// One capstone activity, labelled by where it lives, so a violation reads
/// `finalAssessment.speaking A2-FA-SPEAK-01 ...` rather than just an id.
typedef CapstoneActivity = ({String where, Activity activity});

/// Every activity in both capstones: the mission's flat `activities` list,
/// then each assessment section's own list.
List<CapstoneActivity> capstoneActivities(CourseBundle bundle) => [
  for (final a in bundle.finalMission.activities)
    (where: 'finalMission', activity: a),
  for (final entry in bundle.finalAssessment.sections.entries)
    for (final a in entry.value.activities)
      (where: 'finalAssessment.${entry.key}', activity: a),
];

String _label(CapstoneActivity e) => '${e.where} ${e.activity.id}';

/// Guards every other gate here against passing vacuously.
///
/// Each rule below iterates the capstones and reports what it finds wrong.
/// An empty mission, an empty section, or a capstone with no productive,
/// mediation or listening work in it would satisfy all of them while
/// asserting nothing — which is exactly the shape a skeleton capstone has.
List<String> capstoneStructureViolations(CourseBundle bundle) {
  final out = <String>[];
  final mission = bundle.finalMission;
  if (mission.activities.isEmpty) {
    out.add('${mission.id} has no activities');
  }
  if (mission.stages.isEmpty) {
    out.add('${mission.id} has no stages');
  }
  final assessment = bundle.finalAssessment;
  if (assessment.sections.isEmpty) {
    out.add('${assessment.id} has no sections');
  }
  for (final entry in assessment.sections.entries) {
    if (entry.value.activities.isEmpty) {
      out.add('${assessment.id} section "${entry.key}" has no activities');
    }
  }
  final all = capstoneActivities(bundle);
  bool has(bool Function(Activity a) test) => all.any((e) => test(e.activity));
  if (!has((a) => a is SpeakActivity || a is WriteActivity)) {
    out.add(
      'the A2 capstones contain no speak/write task — the grader gate '
      'would assert nothing',
    );
  }
  if (!has((a) => a.skill == Skill.mediation)) {
    out.add('the A2 capstones contain no mediation task');
  }
  if (!has((a) => a.skill == Skill.spokenInteraction)) {
    out.add('the A2 capstones contain no spokenInteraction task');
  }
  if (!has((a) => a.skill == Skill.listening)) {
    out.add('the A2 capstones contain no listening task');
  }
  return out;
}

/// Every learner-facing string in the capstones carries real Arabic.
///
/// Both capstone titles, every mission stage title and every activity prompt.
/// Non-empty is not the bar: copying the English into the Arabic field passes
/// a presence check and ships a monolingual exit test, so the Arabic has to
/// contain Arabic script.
List<String> capstoneBilingualViolations(CourseBundle bundle) {
  final out = <String>[];
  void check(String label, String? value) {
    final ar = value?.trim() ?? '';
    if (ar.isEmpty) {
      out.add('$label is missing its Arabic');
      return;
    }
    if (!_arabic.hasMatch(ar)) {
      out.add('$label has no Arabic script: "$ar"');
    }
  }

  final mission = bundle.finalMission;
  check('${mission.id}.titleAr', mission.titleAr);
  for (final stage in mission.stages) {
    check('${stage.id}.titleAr', stage.titleAr);
  }
  check('${bundle.finalAssessment.id}.titleAr', bundle.finalAssessment.titleAr);
  for (final e in capstoneActivities(bundle)) {
    check('${_label(e)}.promptAr', e.activity.promptAr);
  }
  return out;
}

/// Every productive task in the capstones is actually marked.
///
/// A speak or write item with no working grader scores `notAutoGraded`, which
/// both `FinalMissionScoring` and `FinalAssessmentScoring` treat as pending
/// review — so a single ungraded item makes its whole skill group, and with it
/// the exit, impossible to pass. The raw-shape checks and the parsed check are
/// both needed: `EvaluationSpec.fromJson` returns null for a malformed spec
/// rather than throwing, so an item can carry an `evaluation` object, satisfy
/// a JSON-shape check, and still reach the app ungradeable.
List<String> capstoneGraderViolations(CourseBundle bundle) {
  final out = <String>[];
  for (final e in capstoneActivities(bundle)) {
    final a = e.activity;
    if (a is! SpeakActivity && a is! WriteActivity) continue;
    final label = _label(e);
    final spec = a.raw['evaluation'];
    if (spec is! Map) {
      out.add(
        '$label carries no structured evaluation (found ${spec.runtimeType})',
      );
      continue;
    }
    if (spec['type'] != 'keywordChecklist') {
      out.add(
        '$label evaluation.type is ${spec['type']}, '
        'not keywordChecklist',
      );
    }
    final groups = spec['requiredGroups'];
    if (groups is! List || groups.isEmpty) {
      out.add('$label has no requiredGroups');
    } else {
      for (var i = 0; i < groups.length; i++) {
        final group = groups[i];
        if (group is! List || group.isEmpty) {
          out.add('$label requiredGroups[$i] is empty');
        }
      }
    }
    final minimum = spec['minGroupsMatched'];
    if (minimum is! int) {
      out.add('$label minGroupsMatched is not an int (found $minimum)');
    } else if (minimum < 1) {
      // minGroupsMatched: 0 satisfies a naive presence check while
      // evaluator.dart's _keywordChecklist scores every answer 1.0
      // (matchedGroups >= 0 is always true) — worse than no rubric at all.
      out.add(
        '$label has minGroupsMatched=$minimum — the evaluator marks '
        'every answer correct regardless of content',
      );
    } else if (groups is List && minimum > groups.length) {
      out.add(
        '$label requires $minimum of only ${groups.length} groups — '
        'this can never be satisfied',
      );
    }
    final parsed = a is SpeakActivity
        ? a.evaluation
        : (a as WriteActivity).evaluation;
    if (parsed == null) {
      out.add(
        '$label reaches the app with no grader — the parser dropped '
        'its evaluation to null',
      );
    } else if (parsed is! KeywordChecklistEvaluationSpec) {
      out.add(
        '$label parses to ${parsed.runtimeType}, '
        'not a keyword checklist',
      );
    }
  }
  return out;
}

/// Every capstone task gives the learner what it asks them to work from.
///
/// Mediation relays a source card; a spoken interaction needs a partner to
/// reply to; a listening item needs something to play; a reading item needs a
/// text. The partner-turn check reads the parsed `partnerTurns`, not the raw
/// field, because that accessor filters blanks — a raw `["", ""]` passes a
/// raw-field check and reaches the learner as an interaction with no partner
/// at all.
///
/// The reading rule is stricter here than the equivalent unit gate in
/// `a2_answerable_test.dart`, which accepts a lesson-level `readingText` as
/// the material. A capstone item has no lesson behind it, so the text has to
/// be on the item.
List<String> capstoneAnswerableViolations(CourseBundle bundle) {
  final out = <String>[];
  for (final e in capstoneActivities(bundle)) {
    final a = e.activity;
    final label = _label(e);
    if (a.skill == Skill.mediation && (a.sourceCard?.trim() ?? '').isEmpty) {
      out.add('$label asks the learner to relay nothing');
    }
    if (a.skill == Skill.spokenInteraction) {
      if (a is! SpeakActivity) {
        out.add('$label is a spokenInteraction task but not a SpeakActivity');
      } else if (a.partnerTurns.isEmpty) {
        out.add('$label is an interaction with no partner');
      }
    }
    if (a.skill == Skill.listening) {
      final transcript = _string(a.raw['audioTranscript'])?.trim() ?? '';
      if (transcript.isEmpty) {
        out.add('$label has no audioTranscript to speak');
      }
    }
    if (a.skill == Skill.reading) {
      final text = _string(a.raw['sourceText'])?.trim() ?? '';
      if (text.isEmpty && (a.sourceCard?.trim() ?? '').isEmpty) {
        out.add('$label asks about a text the learner was never given');
      }
    }
  }
  return out;
}

/// The capstones' input and output lengths.
///
/// An exit test at the top of A2 uses the level's longest band: listening
/// 70-120 words, notices and source cards 15-60, and a single writing guide
/// of 70-90 for both capstones so the two exits demand the same amount of
/// writing. A writing task with no `wordGuide` at all is a violation too —
/// otherwise deleting the field is the cheapest way to satisfy this gate.
List<String> capstoneLengthViolations(CourseBundle bundle) {
  final out = <String>[];
  for (final e in capstoneActivities(bundle)) {
    final a = e.activity;
    final label = _label(e);
    if (a.skill == Skill.listening) {
      final words = _words(_string(a.raw['audioTranscript']));
      if (words < 70 || words > 120) {
        out.add('$label transcript is $words words, outside 70-120');
      }
    }
    for (final key in ['sourceText', 'sourceCard']) {
      final value = _string(a.raw[key]);
      if (value == null || value.trim().isEmpty) continue;
      final words = _words(value);
      if (words < 15 || words > 60) {
        out.add('$label.$key is $words words, outside 15-60');
      }
    }
    final guide = a.raw['wordGuide'];
    if (a.skill == Skill.writing && guide == null) {
      out.add('$label is a writing task with no wordGuide');
      continue;
    }
    if (guide == null) continue;
    if (guide is! List ||
        guide.length != 2 ||
        guide[0] != 70 ||
        guide[1] != 90) {
      out.add('$label wordGuide is $guide, not [70, 90]');
    }
  }
  return out;
}

/// Both exits are marked to the same bar, and that bar is A1's.
///
/// The mission's `minimumCriterionScore` and every score threshold the
/// assessment reads per section. The parsed accessors are checked alongside
/// the raw fields because `FinalAssessment.minimumScoreForSection` falls back
/// to 0.6 when a field is absent — so deleting a threshold would quietly pass
/// a value-only check while removing the authored intent.
///
/// The sweep at the end is the anti-drift net: any *new* fractional
/// `minimum...` added to the assessment's scoring block has to be 0.6 too.
/// Integer minimums (`minimumCompletedTasks: 3`) are counts, not scores, and
/// are deliberately left alone.
List<String> capstonePassMarkViolations(CourseBundle bundle) {
  final out = <String>[];
  final mission = bundle.finalMission;
  if (mission.minimumCriterionScore != capstonePassMark) {
    out.add(
      '${mission.id} scoring.minimumCriterionScore is '
      '${mission.minimumCriterionScore}, not $capstonePassMark',
    );
  }
  final missionRaw = (mission.raw['scoring'] as Map?)?['minimumCriterionScore'];
  if (missionRaw is! num) {
    out.add('${mission.id} scoring.minimumCriterionScore is missing');
  }

  final assessment = bundle.finalAssessment;
  final scoring = assessment.raw['scoring'] as Map<String, dynamic>;
  final checkedPaths = <String>{};
  for (final sectionKey in assessment.sections.keys) {
    // Mirrors FinalAssessment.minimumScoreForSection's own mapping.
    final configKey = switch (sectionKey) {
      'listening' || 'reading' => 'receptive',
      _ => sectionKey,
    };
    final fieldKey = switch (sectionKey) {
      'listening' || 'reading' => 'minimumPerSkill',
      'writing' || 'speaking' => 'minimumTaskCriterionAverage',
      'mediation' => 'minimumCriterionAverage',
      _ => 'minimumPerSkill',
    };
    // `listening` and `reading` share `receptive.minimumPerSkill`, so report
    // that field once rather than once per section it governs.
    final config = scoring[configKey];
    final value = config is Map ? config[fieldKey] : null;
    if (checkedPaths.add('$configKey.$fieldKey')) {
      if (value is! num) {
        out.add(
          '${assessment.id} scoring.$configKey.$fieldKey is missing — '
          'minimumScoreForSection("$sectionKey") would silently fall back '
          'to $capstonePassMark',
        );
      } else if (value.toDouble() != capstonePassMark) {
        out.add(
          '${assessment.id} scoring.$configKey.$fieldKey is $value, '
          'not $capstonePassMark',
        );
      }
    }
    final resolved = assessment.minimumScoreForSection(sectionKey);
    if (resolved != capstonePassMark) {
      out.add(
        '${assessment.id} minimumScoreForSection("$sectionKey") '
        'resolves to $resolved, not $capstonePassMark',
      );
    }
  }

  void sweep(String path, Object? node) {
    if (node is Map) {
      node.forEach(
        (key, value) => sweep(path.isEmpty ? '$key' : '$path.$key', value),
      );
      return;
    }
    if (node is! num) return;
    final name = path.split('.').last;
    if (!name.startsWith('minimum')) return;
    if (checkedPaths.contains(path)) return;
    final isFraction = node != node.truncate();
    if (isFraction && node.toDouble() != capstonePassMark) {
      out.add(
        '${assessment.id} scoring.$path is $node, '
        'not $capstonePassMark',
      );
    }
  }

  sweep('', scoring);
  return out;
}

/// The property that makes an exit test an exit test: its inputs are unseen.
///
/// Every capstone transcript, source text, source card and partner turn is
/// checked for a run of [capstoneOverlapWindow] consecutive words that also
/// appears in any unit's conversation, model text, transcript, source text,
/// source card or partner turn. Unit partner turns are in the haystack
/// deliberately — a line the learner's practice partner said is material they
/// have already met, the same as a conversation line.
List<String> capstoneUnseenInputViolations(CourseBundle bundle) {
  Iterable<String> shingles(String? text) sync* {
    final tokens = _tokenPattern
        .allMatches((text ?? '').toLowerCase())
        .map((m) => m[0]!)
        .toList();
    for (var i = 0; i + capstoneOverlapWindow <= tokens.length; i++) {
      yield tokens.sublist(i, i + capstoneOverlapWindow).join(' ');
    }
  }

  final seen = <String, String>{};
  void absorb(String where, String? text) {
    for (final shingle in shingles(text)) {
      seen.putIfAbsent(shingle, () => where);
    }
  }

  for (final unit in bundle.units) {
    for (final lesson in unit.lessons) {
      for (final line in lesson.encounterDialogue) {
        absorb('${lesson.id} conversation', line.en);
      }
      absorb('${lesson.id} readingText', lesson.readingText?.title);
      absorb('${lesson.id} readingText', lesson.readingText?.text);
      for (final a in lesson.activities) {
        absorb('${a.id}.audioTranscript', _string(a.raw['audioTranscript']));
        absorb('${a.id}.sourceText', _string(a.raw['sourceText']));
        absorb('${a.id}.sourceCard', _string(a.raw['sourceCard']));
        if (a is SpeakActivity) {
          for (final turn in a.partnerTurns) {
            absorb('${a.id}.partnerTurns', turn);
          }
        }
      }
    }
  }

  final out = <String>[];
  for (final e in capstoneActivities(bundle)) {
    final a = e.activity;
    final label = _label(e);
    final inputs = <(String, String?)>[
      ('$label.audioTranscript', _string(a.raw['audioTranscript'])),
      ('$label.sourceText', _string(a.raw['sourceText'])),
      ('$label.sourceCard', _string(a.raw['sourceCard'])),
      if (a is SpeakActivity)
        for (var i = 0; i < a.partnerTurns.length; i++)
          ('$label.partnerTurns[$i]', a.partnerTurns[i]),
    ];
    for (final (inputLabel, text) in inputs) {
      for (final shingle in shingles(text)) {
        final where = seen[shingle];
        if (where != null) {
          // One report per field: the first reused run names the offender,
          // and a lifted sentence would otherwise emit a line per window.
          out.add('$inputLabel reuses "$shingle" from $where');
          break;
        }
      }
    }
  }
  return out;
}

/// Every A2 capstone rule in one list, for the release gate.
List<String> allCapstoneViolations(CourseBundle bundle) => [
  ...capstoneStructureViolations(bundle),
  ...capstoneBilingualViolations(bundle),
  ...capstoneGraderViolations(bundle),
  ...capstoneAnswerableViolations(bundle),
  ...capstoneLengthViolations(bundle),
  ...capstonePassMarkViolations(bundle),
  ...capstoneUnseenInputViolations(bundle),
];
