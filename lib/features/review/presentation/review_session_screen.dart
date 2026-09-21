import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/feedback_theme_extension.dart';
import '../../../core/theme/overline_style.dart';
import '../../lesson_player/presentation/widgets/lesson_intro_chrome.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../speech/presentation/listen_button.dart';
import '../../vocabulary/domain/spaced_review_scheduler.dart';
import '../../vocabulary/presentation/review_rating_bar.dart';
import '../../vocabulary/providers/vocabulary_providers.dart';
import '../domain/next_review.dart';
import '../domain/review_card.dart';
import '../providers/review_providers.dart';

/// A spaced-review session over every word and phrase due when it opens,
/// oldest first: each card shows the English (with audio), then — after
/// Show answer — its Arabic and an example, and the learner rates their
/// recall Again/Good/Easy, each saying when the item comes back. Ratings
/// are saved card by card (closing early keeps them), through the same
/// [SpacedReviewScheduler] as the word pages. A summary ends the session.
///
/// The queue spans levels: a learner in A2 reviews A1's words here too, and
/// each card is resolved against its own level's content. The cards come
/// from [reviewCardsFor] — the same list the Review tab counted, so what
/// the tab promised is what this session shows.
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
  List<ReviewCard>? _cards;
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
    final content = await ref.read(reviewContentProvider.future);
    final due = await ref.read(dueVocabularyProvider.future);
    if (!mounted) return;
    setState(() => _cards = reviewCardsFor(content: content, due: due));
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
        _ when _revealed => ReviewRatingBar(
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

  final ReviewCard card;
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
