import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/feedback_theme_extension.dart';

/// One daily objective: what it is, how far along, and its target.
class DailyGoal {
  const DailyGoal({
    required this.icon,
    required this.label,
    required this.done,
    required this.target,
  });

  final IconData icon;
  final String label;
  final int done;
  final int target;

  bool get complete => done >= target;
  double get fraction => target == 0 ? 1 : (done / target).clamp(0, 1);
}

/// Today's goal as a single compact card — three objectives side by side
/// with a progress ring each — replacing the old three full-width solid
/// tiles that out-shouted the lesson itself. Neutral surface; colour only
/// where it carries meaning (progress, completion).
class DailyGoalSection extends StatelessWidget {
  const DailyGoalSection({required this.goals, super.key});

  final List<DailyGoal> goals;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final feedback = Theme.of(context).extension<FeedbackTheme>()!;
    final doneCount = goals.where((g) => g.complete).length;
    final allDone = doneCount == goals.length;

    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.homeTodaysGoalTitle,
                    style: text.titleSmall?.copyWith(color: tokens.textPrimary),
                  ),
                ),
              ),
              if (allDone) ...[
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: feedback.success,
                ),
                const SizedBox(width: AppSpace.xxs),
              ],
              Text(
                l10n.homeGoalsDone(doneCount, goals.length),
                style: text.labelMedium?.copyWith(
                  color: allDone ? feedback.success : tokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < goals.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpace.xs),
                Expanded(child: DailyGoalItem(goal: goals[i])),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A 40px progress ring around the objective's icon, which swaps to a
/// filled success-green check once the target is reached.
class DailyGoalItem extends StatelessWidget {
  const DailyGoalItem({required this.goal, super.key});

  final DailyGoal goal;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final feedback = Theme.of(context).extension<FeedbackTheme>()!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final shown = goal.done.clamp(0, goal.target);

    return Semantics(
      label: '${goal.label}, $shown/${goal.target}',
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: goal.complete
                  ? DecoratedBox(
                      key: const ValueKey('done'),
                      decoration: BoxDecoration(
                        color: feedback.success,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 22,
                          color: feedback.onSuccess,
                        ),
                      ),
                    )
                  : Stack(
                      key: const ValueKey('progress'),
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: goal.fraction,
                          strokeWidth: 3,
                          strokeCap: StrokeCap.round,
                          color: tokens.primaryInk,
                          backgroundColor: tokens.cardMuted,
                        ),
                        Center(
                          child: Icon(
                            goal.icon,
                            size: 18,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            goal.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.labelMedium?.copyWith(color: tokens.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            '$shown/${goal.target}',
            style: text.bodySmall?.copyWith(color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}
