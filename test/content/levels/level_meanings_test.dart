import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/content/models/evaluation_spec.dart';

import 'level_gate_config.dart';

/// ADR 0014: the inference model reads a free answer against each rubric
/// group's meaning statement, and the feedback names a missing part in the
/// content's own words. A group without a meaning is read by keywords and
/// the similarity fallback alone — the gap the model exists to close — so
/// every keyword-graded mastery task of a released level carries one per
/// group, well-formed: a statement about the answer in plain English ending
/// in a full stop, and a name for the part in English and in Arabic script.
void main() {
  for (final gate in kLevelGates) {
    group(gate.levelId.toUpperCase(), () {
      test('every meaning authored is well-formed', () {
        final bad = <String>[];
        for (final unit in gate.finishedUnits()) {
          for (final a in activitiesOf(unit)) {
            final spec = _specOf(a);
            if (spec == null) continue;
            final raw = _rawMeanings(a);
            if (raw != null && spec.meanings == null) {
              bad.add(
                '${unit.id} ${a.id}: meanings present but not parsed (count '
                'or a field is wrong)',
              );
              continue;
            }
            for (final m in spec.meanings ?? const <GroupMeaning>[]) {
              final says = m.hypothesis.trim();
              if (!says.endsWith('.') || says.startsWith('@')) {
                bad.add('${unit.id} ${a.id}: not a statement: "$says"');
              }
              if (RegExp(r'[\u0600-\u06FF]').hasMatch(says) ||
                  RegExp(r'[\u0600-\u06FF]').hasMatch(m.labelEn)) {
                bad.add('${unit.id} ${a.id}: Arabic in an English field');
              }
              if (!RegExp(r'[\u0600-\u06FF]').hasMatch(m.labelAr)) {
                bad.add(
                  '${unit.id} ${a.id}: ar label is not Arabic: "${m.labelAr}"',
                );
              }
            }
          }
        }
        expect(bad, isEmpty, reason: bad.join('\n'));
      });

      test('keyword-graded mastery tasks carry meanings (coverage rule)', () {
        var total = 0;
        var covered = 0;
        final missing = <String>[];
        for (final unit in gate.finishedUnits()) {
          for (final a in activitiesOf(unit)) {
            if (a.mode != ActivityMode.mastery) continue;
            final spec = _specOf(a);
            if (spec == null) continue;
            total++;
            if (spec.hasMeanings) {
              covered++;
            } else {
              missing.add('${unit.id} ${a.id}');
            }
          }
        }
        final coverage = total == 0 ? 1.0 : covered / total;
        final why = gate.meaningsCoverageException?.reason;
        expect(
          coverage,
          greaterThanOrEqualTo(gate.minMeaningsCoverage),
          reason:
              '${gate.levelId}: $covered of $total keyword-graded mastery tasks '
              'carry meanings (${(coverage * 100).toStringAsFixed(0)}%), below '
              'the declared ${(gate.minMeaningsCoverage * 100).toStringAsFixed(0)}%'
              '${why == null ? '' : ' ($why)'}.\nMissing:\n${missing.join('\n')}',
        );
      });
    });
  }
}

KeywordChecklistEvaluationSpec? _specOf(Activity a) {
  final spec = switch (a) {
    SpeakActivity s => s.evaluation,
    WriteActivity w => w.evaluation,
    _ => null,
  };
  return spec is KeywordChecklistEvaluationSpec ? spec : null;
}

/// The bundle's raw `meanings` list, if the author wrote one — so a list the
/// parser dropped (wrong length, a missing field) fails loudly here instead
/// of silently grading by keywords.
Object? _rawMeanings(Activity a) {
  final evaluation = a.raw['evaluation'];
  return evaluation is Map ? evaluation['meanings'] : null;
}
