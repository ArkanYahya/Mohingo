import 'package:flutter/material.dart';

import '../../../../content/models/domain_definitions.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/l10n/skill_label.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/overline_style.dart';

/// The line above each lesson question naming where the learner is and
/// what they're training — "WARM-UP · LISTENING", "USE IT · SPEAKING" —
/// with the skill's icon.
///
/// Phases map the bundle's activity modes to learner words: encounter is
/// the warm-up, practice is practice, mastery is where they use it.
/// Both speaking skills read "Speaking" here — see [learnerSkillLabel].
class ActivityEyebrow extends StatelessWidget {
  const ActivityEyebrow({required this.mode, required this.skill, super.key});

  final ActivityMode mode;
  final Skill skill;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final phase = switch (mode) {
      ActivityMode.encounter => l10n.lessonPlayerPhaseWarmUp,
      ActivityMode.practice => l10n.lessonPlayerPhasePractice,
      ActivityMode.mastery => l10n.lessonPlayerPhaseUseIt,
    };
    final skillName = learnerSkillLabel(l10n, skill);

    return Row(
      children: [
        Icon(skillIcon(skill), size: 16, color: tokens.textSecondary),
        const SizedBox(width: AppSpace.xs - 2),
        Flexible(
          child: Text(
            l10n.lessonPlayerEyebrow(phase, skillName).toUpperCase(),
            style: overlineStyle(context, color: tokens.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// The icon for [skill] wherever the lesson player names a skill.
IconData skillIcon(Skill skill) => switch (skill) {
  Skill.listening => Icons.headphones_rounded,
  Skill.reading => Icons.menu_book_rounded,
  Skill.writing => Icons.edit_note_rounded,
  Skill.spokenInteraction ||
  Skill.spokenProduction => Icons.record_voice_over_rounded,
  Skill.mediation => Icons.translate_rounded,
};
