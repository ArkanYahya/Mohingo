import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/index/course_content_index.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/feedback_theme_extension.dart';
import '../../../core/theme/overline_style.dart';
import '../../../data/local/database.dart';
import '../../lesson_player/presentation/widgets/lesson_intro_chrome.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';
import '../../speech/presentation/listen_button.dart';
import '../../vocabulary/domain/spaced_review_scheduler.dart';
import '../../vocabulary/providers/vocabulary_providers.dart';
import '../domain/next_review.dart';
import '../providers/review_providers.dart';

/// One due word or phrase in a review session.
class _Card {
  const _Card({
    required this.state,
    required this.text,
    required this.arabic,
    required this.isPhrase,
    this.example,
  });

  final VocabularyReviewStateData state;
  final String text;
  final String arabic;
  final bool isPhrase;
  final String? example;

  static _Card? of(CourseContentIndex index, VocabularyReviewStateData s) {
    if (s.lexiconId != null) {
      final item = index.lexiconById[s.lexiconId];
      if (item == null) return null;
      return _Card(
        state: s,
        text: item.headword,
        arabic: item.arabic,
        isPhrase: false,
        example: item.examples.firstOrNull,
      );
    }
    final item = index.chunkById[s.chunkId];
    if (item == null) return null;
    return _Card(
      state: s,
      text: item.text,
      arabic: item.arabic,
      isPhrase: true,
    );
  }
}

/// A spaced-review session over every word and phrase due when it opens,
/// oldest first: each card shows the English (with audio), then — after
/// Show answer — its Arabic and an example, and the learner rates their
/// recall Again/Good/Easy, each saying when the item comes back. Ratings
/// are saved card by card (closing early keeps them), through the same
/// [SpacedReviewScheduler] as the word pages. A summary ends the session.
///
/// Like every vocabulary review, this only updates the memory schedule — it
/// never grants Can-Do mastery. See docs/DATA_MODEL.md.
class ReviewSessionScreen extends ConsumerStatefulWidget {
  const ReviewSessionScreen({super.key});

  @override
  ConsumerState<ReviewSessionScreen> createState() =>
      _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends ConsumerState<ReviewSessionScreen> {
  List<_Card>? _cards;
  int _position = 0;
  bool _revealed = false;
  bool _saving = false;
  final _ratings = <ReviewQuality, int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final index = await ref.read(courseContentProvider('a1').future);
    final learner = await ref.read(currentLearnerProvider.future);
    final due = await ref
        .read(reviewStateRepositoryProvider)
        .dueVocabulary(learnerId: learner.id, asOf: DateTime.now());
    due.sort(
      (a, b) => (a.dueAt ?? DateTime(0)).compareTo(b.dueAt ?? DateTime(0)),
    );
    if (!mounted) return;
    setState(() => _cards = [for (final s in due) ?_Card.of(index, s)]);
  }

  Future<void> _rate(ReviewQuality quality) async {
    if (_saving) return;
    setState(() => _saving = true);
    final card = _cards![_position];
    final learner = await ref.read(currentLearnerProvider.future);
    await ref
        .read(vocabularyReviewServiceProvider)
        .recordReview(
          learnerId: learner.id,
          lexiconId: card.state.lexiconId,
          chunkId: card.state.chunkId,
          quality: quality,
        );
    // Home's review card, the nav badge and the Review tab all read these.
    ref.invalidate(allVocabularyReviewStateProvider);
    ref.invalidate(dueVocabularyProvider);
    if (!mounted) return;
    setState(() {
      _ratings.update(quality, (n) => n + 1, ifAbsent: () => 1);
      _position++;
      _revealed = false;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cards = _cards;
    final Widget body;
    if (cards == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (cards.isEmpty) {
      body = Center(child: Text(l10n.reviewSessionEmpty));
    } else if (_position >= cards.length) {
      body = _SessionSummary(reviewed: cards.length, ratings: _ratings);
    } else {
      body = _CardView(
        key: ValueKey(_position),
        card: cards[_position],
        revealed: _revealed,
      );
    }
    final inSession = cards != null && _position < cards.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              position: inSession ? _position : null,
              total: cards?.length ?? 0,
            ),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: switch (cards) {
        null || [] => null,
        _ when _position >= cards.length => LessonActionBar(
          label: l10n.reviewSessionDoneCta,
          showArrow: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
        _ when _revealed => _RatingBar(
          state: cards[_position].state,
          enabled: !_saving,
          onRate: _rate,
        ),
        _ => LessonActionBar(
          label: l10n.reviewShowAnswer,
          showArrow: false,
          onPressed: () => setState(() => _revealed = true),
        ),
      },
    );
  }
}

/// Close, how far through the session, and "3 of 8".
class _TopBar extends StatelessWidget {
  const _TopBar({required this.position, required this.total});

  /// Null once the session is over (or before it starts).
  final int? position;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final position = this.position;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpace.xxs,
        AppSpace.xxs,
        AppSpace.md,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
          ),
          if (position != null && total > 0) ...[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: position / total,
                  minHeight: 6,
                  color: tokens.primaryInk,
                  backgroundColor: Color.lerp(
                    tokens.border,
                    tokens.textSecondary,
                    0.15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Text(
              l10n.reviewSessionProgress(position + 1, total),
              style: theme.textTheme.labelLarge?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One card: WORD/PHRASE, the English with audio, and either a hint to
/// recall the meaning or — once revealed — the Arabic and an example.
class _CardView extends StatelessWidget {
  const _CardView({required this.card, required this.revealed, super.key});

  final _Card card;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.xl,
        AppSpace.lg,
        AppSpace.lg,
      ),
      child: Column(
        children: [
          Text(
            (card.isPhrase ? l10n.reviewSessionPhrase : l10n.reviewSessionWord)
                .toUpperCase(),
            style: overlineStyle(context, color: tokens.textSecondary),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            card.text,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: tokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          ListenButton(text: card.text),
          const SizedBox(height: AppSpace.lg),
          if (!revealed)
            Text(
              l10n.reviewSessionPrompt,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: tokens.textSecondary,
              ),
            )
          else ...[
            Semantics(
              liveRegion: true,
              child: Text(
                card.arabic,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
            ),
            if (card.example != null) ...[
              const SizedBox(height: AppSpace.lg),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.card,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: tokens.border),
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpace.md,
                    AppSpace.xs,
                    AppSpace.xs,
                    AppSpace.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            card.example!,
                            textDirection: TextDirection.ltr,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: tokens.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      ListenButton(text: card.example!),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// "How well did you know it?" and Again / Good / Easy, each with when it
/// brings the item back.
class _RatingBar extends StatelessWidget {
  const _RatingBar({
    required this.state,
    required this.enabled,
    required this.onRate,
  });

  final VocabularyReviewStateData state;
  final bool enabled;
  final ValueChanged<ReviewQuality> onRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();

    // Side by side normally; stacked full-width rows when the screen is
    // narrow for the text size, so a hint like "tomorrow" never breaks.
    final stacked =
        MediaQuery.sizeOf(context).width /
            MediaQuery.textScalerOf(context).scale(1) <
        340;

    Widget button(ReviewQuality quality, String label, {Color? color}) {
      final days = SpacedReviewScheduler.schedule(
        currentEaseFactor: state.easeFactor,
        currentIntervalDays: state.intervalDays,
        currentRepetitions: state.repetitions,
        quality: quality,
        now: now,
      ).intervalDays;
      final hint = Text(
        l10n.reviewSeeAgain(days),
        style: theme.textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
      );
      final outlined = OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxs),
          foregroundColor: color ?? tokens.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
        onPressed: enabled ? () => onRate(quality) : null,
        child: stacked
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                child: Row(
                  children: [
                    Expanded(child: Text(label)),
                    const SizedBox(width: AppSpace.xs),
                    hint,
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [Text(label), hint],
              ),
      );
      return stacked ? outlined : Expanded(child: outlined);
    }

    final buttons = [
      button(
        ReviewQuality.again,
        l10n.reviewQualityAgain,
        color: theme.colorScheme.error,
      ),
      button(ReviewQuality.good, l10n.reviewQualityGood),
      button(ReviewQuality.easy, l10n.reviewQualityEasy),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.page,
        border: Border(top: BorderSide(color: tokens.border)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.sm,
          AppSpace.md,
          AppSpace.md + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.reviewHowWellKnew,
              style: theme.textTheme.titleSmall?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            if (stacked)
              for (final (i, b) in buttons.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpace.xs),
                b,
              ]
            else
              Row(
                children: [
                  for (final (i, b) in buttons.indexed) ...[
                    if (i > 0) const SizedBox(width: AppSpace.xs),
                    b,
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// The end of a session: how many were reviewed, how each was rated, and
/// when the next review is.
class _SessionSummary extends ConsumerWidget {
  const _SessionSummary({required this.reviewed, required this.ratings});

  final int reviewed;
  final Map<ReviewQuality, int> ratings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final feedback = theme.extension<FeedbackTheme>()!;
    final l10n = AppLocalizations.of(context)!;
    final states = ref.watch(allVocabularyReviewStateProvider).value;
    final nextDays = states == null
        ? null
        : daysUntilNextReview(states, DateTime.now());

    Widget figure(ReviewQuality quality, String label) => Expanded(
      child: MergeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
          child: Column(
            children: [
              Text(
                '${ratings[quality] ?? 0}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpace.lg),
          ExcludeSemantics(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: feedback.successContainer,
              child: Icon(
                Icons.check_rounded,
                size: 36,
                color: feedback.success,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.reviewSessionDoneTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xxs),
          Text(
            l10n.reviewSessionDoneBody(reviewed),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: tokens.border),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  figure(ReviewQuality.easy, l10n.reviewQualityEasy),
                  VerticalDivider(width: 1, color: tokens.border),
                  figure(ReviewQuality.good, l10n.reviewQualityGood),
                  VerticalDivider(width: 1, color: tokens.border),
                  figure(ReviewQuality.again, l10n.reviewQualityAgain),
                ],
              ),
            ),
          ),
          if (nextDays != null) ...[
            const SizedBox(height: AppSpace.md),
            Text(
              l10n.reviewNextIn(nextDays),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
