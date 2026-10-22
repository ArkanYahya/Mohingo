import 'package:flutter/material.dart';

import '../../../../content/models/domain_definitions.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/overline_style.dart';
import '../../../activity_engine/presentation/activity_chrome.dart';
import '../../../lesson_player/presentation/widgets/activity_eyebrow.dart';
import '../../../lesson_player/presentation/widgets/lesson_top_bar.dart';

/// A test question in the lesson player's frame: close and a
/// [TestProgressBar] ([groupSizes], [completed]) at the top, [eyebrow]
/// above the prompt, and Check / the feedback panel pinned to the bottom
/// (see [ActivityFrameScope]). In [testMode] answers are saved, not marked.
/// Free answers are graded on the rubric alone unless [signalsEnabled] —
/// the three tests measure, so only quick practice turns it on (ADR 0011).
class TestQuestionFrame extends StatelessWidget {
  const TestQuestionFrame({
    required this.groupSizes,
    required this.completed,
    required this.eyebrow,
    required this.testMode,
    required this.onContinue,
    required this.child,
    this.signalsEnabled = false,
    super.key,
  });

  final List<int> groupSizes;
  final int completed;
  final Widget eyebrow;
  final bool testMode;
  final VoidCallback onContinue;
  final bool signalsEnabled;

  /// The activity view.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // The bottom bar pads itself for the system inset.
        bottom: false,
        child: Column(
          children: [
            LessonTopBar(
              onClose: () => Navigator.of(context).maybePop(),
              progress: TestProgressBar(
                groupSizes: groupSizes,
                completed: completed,
              ),
            ),
            Expanded(
              child: ActivityFrameScope(
                onContinue: onContinue,
                testMode: testMode,
                signalsEnabled: signalsEnabled,
                header: eyebrow,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "LISTENING · 3 OF 16" with the skill's icon — a test question's place.
class TestEyebrow extends StatelessWidget {
  const TestEyebrow({required this.skill, required this.text, super.key});

  final Skill skill;
  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Row(
      children: [
        ExcludeSemantics(
          child: Icon(skillIcon(skill), size: 16, color: tokens.textSecondary),
        ),
        const SizedBox(width: AppSpace.xs - 2),
        Flexible(
          child: Text(
            text.toUpperCase(),
            style: overlineStyle(context, color: tokens.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// A test's progress: one segment per section ([groupSizes], sized to its
/// questions), each filling in `primaryInk` as its questions are answered —
/// a lesson's one-segment-per-question bar would be 40 dots here.
class TestProgressBar extends StatelessWidget {
  const TestProgressBar({
    required this.groupSizes,
    required this.completed,
    super.key,
  });

  final List<int> groupSizes;

  /// Questions answered so far, across every section.
  final int completed;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final total = groupSizes.fold(0, (sum, size) => sum + size);
    final track = Color.lerp(tokens.border, tokens.textSecondary, 0.15)!;

    var before = 0;
    final segments = <Widget>[];
    for (final size in groupSizes) {
      final done = (completed - before).clamp(0, size);
      segments.add(
        Expanded(
          flex: size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: size == 0 ? 0 : done / size,
              minHeight: 6,
              color: tokens.primaryInk,
              backgroundColor: track,
            ),
          ),
        ),
      );
      before += size;
    }

    return Semantics(
      label: l10n.lessonPlayerProgress(
        (completed + 1).clamp(1, total == 0 ? 1 : total),
        total,
      ),
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (final (i, segment) in segments.indexed) ...[
              if (i > 0) const SizedBox(width: AppSpace.xxs),
              segment,
            ],
          ],
        ),
      ),
    );
  }
}
