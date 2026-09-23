import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/error_state_view.dart';
import '../../../content/models/activity.dart';
import '../../../content/models/curriculum_structure.dart';
import '../../../content/models/media_specification.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/skill_label.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/feedback_theme_extension.dart';
import '../../../core/theme/gamification_theme_extension.dart';
import '../../../core/theme/overline_style.dart';
import '../../../core/widgets/content_text.dart';
import '../../../core/widgets/hairline_card.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/local/database.dart';
import '../../activity_engine/presentation/activity_chrome.dart';
import '../../activity_engine/presentation/activity_view_registry.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';
import 'widgets/activity_eyebrow.dart';
import 'widgets/lesson_intro_chrome.dart';

/// Every recorded attempt for one lesson's activities, for one learner —
/// feeds [LessonReviewScreen]'s "latest attempt per activity" reduction.
///
/// Declared as a plain (non-code-generated) provider — see
/// [currentLearnerProvider]'s doc comment for why: riverpod_generator fails
/// on providers returning Drift `DataClass` types directly.
final lessonReviewAttemptsProvider =
    FutureProvider.family<
      List<ActivityAttempt>,
      ({int learnerId, String lessonId})
    >((ref, params) {
      final repository = ref.watch(activityAttemptRepositoryProvider);
      return repository.attemptsForLessons(
        learnerId: params.learnerId,
        lessonIds: [params.lessonId],
      );
    });

/// Reduces [attempts] to the single latest attempt per activity id, for
/// activities that actually belong to [lesson] — the same reduction
/// `lesson_player_screen.dart`'s `_rehydratePreviousAnswers` performs (kept
/// as a separate function here since the two screens use the result for
/// different purposes). Restricted to `sessionType == 'lesson'`:
/// placement/mission/assessment attempts never leak into ordinary lesson
/// review. See docs/DATA_MODEL.md.
Map<String, ActivityAttempt> latestAttemptPerActivity(
  List<ActivityAttempt> attempts,
  Lesson lesson,
) {
  final activityIds = lesson.activities.map((a) => a.id).toSet();
  final latest = <String, ActivityAttempt>{};
  for (final attempt in attempts) {
    if (attempt.sessionType != 'lesson') continue;
    if (!activityIds.contains(attempt.activityId)) continue;
    final existing = latest[attempt.activityId];
    if (existing == null ||
        !attempt.attemptedAt.isBefore(existing.attemptedAt)) {
      latest[attempt.activityId] = attempt;
    }
  }
  return latest;
}

/// Read-only walkthrough of a learner's latest answer to every activity in
/// an already-finished lesson — the Learn tab's answer-review feature. Shown
/// instead of [LessonPlayerScreen] when `UnitOverviewScreen` detects the
/// lesson has already reached its final activity. "Practice again" is the
/// only door back into the real (replaying, evidence-recording) player. See
/// docs/superpowers/specs/2026-09-09-lesson-answer-review-design.md.
///
/// Two known, intentional properties, already discussed and accepted (see
/// this plan's ledger's final whole-branch review), not bugs:
/// - Within a reviewed [ChoiceActivityView], the per-option tile
///   highlighting reflects the *current* curriculum content's answer key
///   (`widget.answer`), while the feedback banner reflects the
///   *historically recorded* judgment (`reviewAttempt.isCorrect`). These can
///   disagree if the curriculum content for that activity changed after the
///   attempt was recorded — showing the current correct answer still has
///   real pedagogical value, so this is accepted rather than "fixed" to
///   agree with the (necessarily untouched, never-re-graded) recorded
///   judgment.
/// - A `dialogue`-type activity has no review-mode support at all and
///   always renders fully live/interactive even inside this read-only
///   screen — deliberate, since no authored `dialogue` instance exists in
///   the current A1 bundle; there is nothing to review yet.
class LessonReviewScreen extends ConsumerWidget {
  const LessonReviewScreen({
    required this.unitId,
    required this.lessonId,
    super.key,
  });

  final String unitId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(contentIndexForIdProvider(lessonId));
    final learnerAsync = ref.watch(currentLearnerProvider);

    return contentAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (error, _) => _ErrorScaffold(message: '$error'),
      data: (index) {
        final lesson = index.lessonsById[lessonId];
        if (lesson == null) {
          final l10n = AppLocalizations.of(context)!;
          return _ErrorScaffold(message: l10n.contentNotFoundTitle);
        }
        return learnerAsync.when(
          loading: () => const _LoadingScaffold(),
          error: (error, _) => _ErrorScaffold(message: '$error'),
          data: (learner) {
            final unit = index.unitsById[unitId];
            return _LessonReviewBody(
              unitId: unitId,
              lesson: lesson,
              unitNumber:
                  index.bundle.units.indexWhere((u) => u.id == unitId) + 1,
              lessonNumber: (unit?.lessons.indexOf(lesson) ?? -1) + 1,
              learnerId: learner.id,
              mediaByKey: index.bundle.mediaSpecifications,
            );
          },
        );
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(message)));
}

/// How one question went, for the review's summary, pills and filter.
enum _Outcome { right, wrong, saved, notAnswered }

_Outcome _outcomeOf(ActivityAttempt? attempt) => switch (attempt?.isCorrect) {
  _ when attempt == null => _Outcome.notAnswered,
  true => _Outcome.right,
  false => _Outcome.wrong,
  null => _Outcome.saved,
};

class _LessonReviewBody extends ConsumerStatefulWidget {
  const _LessonReviewBody({
    required this.unitId,
    required this.lesson,
    required this.unitNumber,
    required this.lessonNumber,
    required this.learnerId,
    required this.mediaByKey,
  });

  final String unitId;
  final Lesson lesson;
  final int unitNumber;
  final int lessonNumber;
  final int learnerId;
  final Map<String, MediaSpecification> mediaByKey;

  @override
  ConsumerState<_LessonReviewBody> createState() => _LessonReviewBodyState();
}

class _LessonReviewBodyState extends ConsumerState<_LessonReviewBody> {
  bool _toRevisitOnly = false;
  late final _cardKeys = [
    for (final _ in widget.lesson.activities) GlobalKey(),
  ];

  Future<void> _jumpTo(int index) async {
    if (_toRevisitOnly) setState(() => _toRevisitOnly = false);
    await WidgetsBinding.instance.endOfFrame;
    final target = _cardKeys[index].currentContext;
    if (target != null && target.mounted) {
      await Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final lesson = widget.lesson;
    final attemptsAsync = ref.watch(
      lessonReviewAttemptsProvider((
        learnerId: widget.learnerId,
        lessonId: lesson.id,
      )),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.xxs),
                child: BackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            Expanded(
              child: attemptsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    ErrorStateView(error: error, stackTrace: stackTrace),
                data: (attempts) {
                  final latest = latestAttemptPerActivity(attempts, lesson);
                  final outcomes = [
                    for (final a in lesson.activities) _outcomeOf(latest[a.id]),
                  ];
                  final right = outcomes
                      .where((o) => o == _Outcome.right)
                      .length;
                  final toRevisit = outcomes
                      .where((o) => o == _Outcome.wrong)
                      .length;
                  final shown = [
                    for (final (i, o) in outcomes.indexed)
                      if (!_toRevisitOnly || o == _Outcome.wrong) i,
                  ];

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.md,
                      0,
                      AppSpace.md,
                      AppSpace.lg,
                    ),
                    children: [
                      Text(
                        l10n
                            .lessonReviewOverline(
                              widget.unitNumber,
                              widget.lessonNumber,
                            )
                            .toUpperCase(),
                        style: overlineStyle(
                          context,
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpace.xxs),
                      ContentText.en(
                        lesson.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: tokens.textPrimary,
                        ),
                      ),
                      ContentText.ar(
                        lesson.titleAr,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: tokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      _Summary(
                        outcomes: outcomes,
                        right: right,
                        toRevisit: toRevisit,
                        toRevisitOnly: _toRevisitOnly,
                        onFilter: (v) => setState(() => _toRevisitOnly = v),
                        onJump: _jumpTo,
                      ),
                      if (shown.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpace.lg),
                          child: Text(
                            l10n.lessonReviewNothingToRevisit,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                      for (final i in shown)
                        Padding(
                          key: _cardKeys[i],
                          padding: const EdgeInsets.only(top: AppSpace.sm),
                          child: _QuestionCard(
                            number: i + 1,
                            activity: lesson.activities[i],
                            outcome: outcomes[i],
                            child: latest[lesson.activities[i].id] == null
                                ? _NotAnsweredCard(
                                    activity: lesson.activities[i],
                                  )
                                : buildActivityView(
                                    // Keyed on the *attempt*, not just the
                                    // activity: this screen stays alive
                                    // under "Practise again"'s player (a
                                    // real Navigator.pop() — e.g. the device
                                    // Back button — reveals it again), so a
                                    // key that never changes across a
                                    // replay would reuse the activity
                                    // view's State, whose reviewAttempt is
                                    // only read once, in initState. See
                                    // docs/superpowers/specs/
                                    // 2026-09-09-lesson-answer-review-design.md.
                                    key: ValueKey(
                                      '${lesson.activities[i].id}-'
                                      '${latest[lesson.activities[i].id]!.id}',
                                    ),
                                    lesson.activities[i],
                                    learnerId: widget.learnerId,
                                    onSubmitted: (_) {},
                                    mediaByKey: widget.mediaByKey,
                                    reviewAttempt:
                                        latest[lesson.activities[i].id],
                                  ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            // Pinned, not the list's last item — always present, never
            // scrolled away (docs/superpowers/specs/
            // 2026-09-09-lesson-answer-review-design.md).
            LessonActionBar(
              label: l10n.lessonReviewPracticeAgain,
              onPressed: () =>
                  context.push('/lesson-player/${widget.unitId}/${lesson.id}'),
            ),
          ],
        ),
      ),
    );
  }
}

/// "3 of 4 right", a numbered mark per question (tap to jump to it), and
/// the All / To revisit filter.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.outcomes,
    required this.right,
    required this.toRevisit,
    required this.toRevisitOnly,
    required this.onFilter,
    required this.onJump,
  });

  final List<_Outcome> outcomes;
  final int right;
  final int toRevisit;
  final bool toRevisitOnly;
  final ValueChanged<bool> onFilter;
  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final feedback = theme.extension<FeedbackTheme>()!;
    final streak = theme.extension<GamificationTheme>()!.streakAccent;
    final l10n = AppLocalizations.of(context)!;

    Widget mark(int i) {
      final outcome = outcomes[i];
      final (Color fill, Color ink, Color? outline) = switch (outcome) {
        _Outcome.right => (
          feedback.successContainer,
          feedback.onSuccessContainer,
          null,
        ),
        _Outcome.wrong => (
          Color.alphaBlend(streak.withValues(alpha: 0.16), tokens.card),
          tokens.textPrimary,
          null,
        ),
        _Outcome.saved => (tokens.cardMuted, tokens.textSecondary, null),
        _Outcome.notAnswered => (
          tokens.card,
          tokens.textSecondary,
          tokens.border,
        ),
      };
      return Semantics(
        button: true,
        label:
            '${l10n.lessonReviewQuestion(i + 1)}: '
            '${_outcomeLabel(l10n, outcome)}',
        child: ExcludeSemantics(
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => onJump(i),
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: outline == null ? null : Border.all(color: outline),
              ),
              child: Text(
                '${i + 1}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget chip(String label, int count, bool selected, bool value) =>
        ChoiceChip(
          showCheckmark: false,
          selected: selected,
          onSelected: (_) => onFilter(value),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              const SizedBox(width: AppSpace.xs - 2),
              Text(
                '$count',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );

    return HairlineCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.lessonReviewScore(right, outcomes.length),
            style: theme.textTheme.titleLarge?.copyWith(
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [for (var i = 0; i < outcomes.length; i++) mark(i)],
          ),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.xs,
            children: [
              chip(
                l10n.lessonReviewFilterAll,
                outcomes.length,
                !toRevisitOnly,
                false,
              ),
              chip(
                l10n.lessonReviewFilterToRevisit,
                toRevisit,
                toRevisitOnly,
                true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _outcomeLabel(AppLocalizations l10n, _Outcome outcome) =>
    switch (outcome) {
      _Outcome.right => l10n.lessonReviewRight,
      _Outcome.wrong => l10n.lessonReviewNotQuite,
      _Outcome.saved => l10n.lessonReviewSaved,
      _Outcome.notAnswered => l10n.lessonReviewNotAnsweredPill,
    };

/// One reviewed question in a hairline card: "2 · READING" and how it went,
/// over the activity shown read-only.
class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.number,
    required this.activity,
    required this.outcome,
    required this.child,
  });

  final int number;
  final Activity activity;
  final _Outcome outcome;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final pill = switch (outcome) {
      _Outcome.right => StatusPill(
        label: l10n.lessonReviewRight,
        tone: StatusTone.success,
        icon: Icons.check_rounded,
      ),
      _Outcome.wrong => StatusPill(
        label: l10n.lessonReviewNotQuite,
        tone: StatusTone.attention,
        icon: Icons.refresh_rounded,
      ),
      _Outcome.saved => StatusPill(label: l10n.lessonReviewSaved),
      _Outcome.notAnswered => StatusPill(
        label: l10n.lessonReviewNotAnsweredPill,
      ),
    };
    return HairlineCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpace.md,
              AppSpace.sm,
              AppSpace.sm,
              0,
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    skillIcon(activity.skill),
                    size: 16,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpace.xs - 2),
                Expanded(
                  child: Text(
                    l10n
                        .lessonReviewQuestionHeader(
                          number,
                          learnerSkillLabel(l10n, activity.skill),
                        )
                        .toUpperCase(),
                    style: overlineStyle(context, color: tokens.textSecondary),
                  ),
                ),
                pill,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _NotAnsweredCard extends StatelessWidget {
  const _NotAnsweredCard({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    return ActivityChrome(
      prompt: activity.prompt,
      promptAr: activity.promptAr,
      body: Text(
        l10n.lessonReviewNotAnswered,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: tokens.textSecondary,
        ),
      ),
    );
  }
}
