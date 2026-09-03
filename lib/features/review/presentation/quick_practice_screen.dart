import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/activity.dart';
import '../../../content/models/domain_definitions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../activity_engine/domain/activity_submission.dart';
import '../../activity_engine/presentation/activity_view_registry.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';

/// A single practice activity, launched from Grammar's "Quick practice" or
/// Review's "weak objective -> practice this" links.
///
/// Recorded with `sessionType: 'practiceReview'` — deliberately **not**
/// `'lesson'`, so it can never be picked up by
/// `ActivityAttemptRepository.masteryEvidenceForObjective` (which filters
/// to `sessionType='lesson'`) and can never contribute to Can-Do mastery,
/// matching "quick practice... without falsely marking the related Can-Do
/// mastered." See docs/DATA_MODEL.md.
class QuickPracticeScreen extends ConsumerStatefulWidget {
  const QuickPracticeScreen({required this.activity, super.key});

  final Activity activity;

  @override
  ConsumerState<QuickPracticeScreen> createState() =>
      _QuickPracticeScreenState();
}

class _QuickPracticeScreenState extends ConsumerState<QuickPracticeScreen> {
  bool _done = false;

  Future<void> _handleSubmitted(ActivitySubmission submission) async {
    final learner = await ref.read(currentLearnerProvider.future);
    final evidenceSkill =
        submission.wasFallback &&
            widget.activity is SpeakActivity &&
            (widget.activity as SpeakActivity).fallbackSkill != null
        ? Skill.parse((widget.activity as SpeakActivity).fallbackSkill!)
        : widget.activity.skill;

    await ref
        .read(activityAttemptRepositoryProvider)
        .recordAttempt(
          learnerId: learner.id,
          activityId: widget.activity.id,
          sessionType: 'practiceReview',
          mode: widget.activity.mode,
          evidenceSkill: evidenceSkill,
          canDoIds: widget.activity.canDo,
          rawAnswer: submission.rawAnswerJson,
          isCorrect: switch (submission.correctness) {
            ActivityCorrectness.correct => true,
            ActivityCorrectness.incorrect => false,
            ActivityCorrectness.notAutoGraded => null,
          },
          score: submission.score,
          wasFallback: submission.wasFallback,
        );

    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.grammarQuickPractice)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildActivityView(widget.activity, onSubmitted: _handleSubmitted),
              if (_done)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: FilledButton(
                    onPressed: () => context.pop(),
                    child: Text(l10n.quickPracticeDone),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
