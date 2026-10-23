import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/error_state_view.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/skill_label.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/feedback_theme_extension.dart';
import '../../../core/theme/gamification_theme_extension.dart';
import '../../../core/theme/overline_style.dart';
import '../../../core/widgets/content_text.dart';
import '../../../data/local/database.dart';
import '../../grammar/providers/grammar_providers.dart';
import '../../lesson_player/presentation/widgets/activity_eyebrow.dart';
import '../../vocabulary/providers/vocabulary_providers.dart';
import '../domain/next_review.dart';
import '../domain/practice_set.dart';
import '../domain/review_card.dart';
import '../domain/review_content.dart';
import '../domain/weak_spots.dart';
import '../providers/review_providers.dart';

/// The Review tab.
///
/// One job at the top: the words and phrases due for spaced review, with a
/// button into a review session (or, when nothing is due, when the next
/// review is). Then the Can-Do goals that need more practice, named by the
/// lesson that teaches them; tiles into the words and grammar lists; and
/// the learner's saved items.
///
/// This is the one tab that does **not** follow the learner's current
/// level: everything here spans every level they have reached, because an
/// A2 learner has to keep meeting A1's words in spaced review. See
/// [ReviewContent] and docs/adr/0006-multiple-levels.md.
///
/// Vocabulary-memory scheduling (the spaced-review "due" queue) is kept
/// entirely separate from communicative mastery (weak objectives, evidence
/// from real lesson activities) — remembering a flashcard never proves
/// listening/speaking/interaction ability. See docs/ARCHITECTURE.md.
class ReviewHomeScreen extends ConsumerWidget {
  const ReviewHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(reviewContentProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: contentAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              ErrorStateView(error: error, stackTrace: stackTrace),
          data: (content) => _ReviewBody(content: content),
        ),
      ),
    );
  }
}

class _ReviewBody extends ConsumerWidget {
  const _ReviewBody({required this.content});

  final ReviewContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final due = ref.watch(dueVocabularyProvider).value;
    // The same list the session builds from, so the count on this tab is
    // never a promise the session can't keep.
    final cards = due == null
        ? null
        : reviewCardsFor(content: content, due: due);
    final vocabState =
        ref.watch(allVocabularyReviewStateProvider).value ?? const [];
    final grammarState =
        ref.watch(allGrammarReviewStateProvider).value ?? const [];
    final weakSpots = ref.watch(weakSpotsProvider).value ?? const <WeakSpot>[];

    final saved = <_SavedItem>[
      for (final s in vocabState)
        if (s.isFavorite) ?_SavedItem.vocabulary(content, s),
      for (final s in grammarState)
        if (s.isFavorite) ?_SavedItem.grammar(content, s),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
      ),
      children: [
        Text(
          l10n.navReview,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpace.xxs),
        Text(
          l10n.reviewHubSubtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpace.md),
        if (cards == null)
          const SizedBox.shrink()
        else if (cards.isEmpty)
          _CaughtUpCard(
            daysUntilNext: daysUntilNextReview(vocabState, DateTime.now()),
          )
        else
          _DueCard(cards: cards),
        _Section(
          overline: l10n.reviewWeakSpotsOverline,
          body: weakSpots.isEmpty
              ? l10n.reviewNoWeakObjectives
              : l10n.reviewWeakSpotsBody,
          rows: [for (final spot in weakSpots) _WeakSpotRow(spot: spot)],
        ),
        const SizedBox(height: AppSpace.lg),
        Text(
          l10n.reviewBrowseOverline.toUpperCase(),
          style: overlineStyle(context, color: tokens.textSecondary),
        ),
        const SizedBox(height: AppSpace.xs),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _BrowseTile(
                  icon: Icons.translate_rounded,
                  title: l10n.reviewWordsTile,
                  meta: l10n.reviewWordsTileMeta(
                    vocabState.length,
                    content.wordAndPhraseCount,
                  ),
                  onTap: () => context.push('/review/vocabulary'),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: _BrowseTile(
                  icon: Icons.account_tree_outlined,
                  title: l10n.grammarSectionTitle,
                  meta: l10n.reviewGrammarTileMeta(content.grammarCount),
                  onTap: () => context.push('/review/grammar'),
                ),
              ),
            ],
          ),
        ),
        _Section(
          overline: l10n.reviewSavedOverline,
          body: saved.isEmpty ? l10n.reviewNoFavorites : null,
          rows: [for (final item in saved) _SavedRow(item: item)],
        ),
      ],
    );
  }
}

/// The Review tab's one emphasised card: how many words and phrases are
/// due, the first few, roughly how long, and Start review.
///
/// [cards] is exactly what Start review opens, whatever levels the items
/// come from — see [reviewCardsFor].
class _DueCard extends StatelessWidget {
  const _DueCard({required this.cards});

  final List<ReviewCard> cards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final shown = cards.take(3).map((c) => '\u2068${c.text}\u2069').join(' · ');
    final more = cards.length > 3
        ? ' ${l10n.reviewDueMore(cards.length - 3)}'
        : '';
    final minutes = (cards.length * 20 / 60).ceil().clamp(1, 999);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: tokens.primaryInk, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.reviewDueOverline.toUpperCase(),
              style: overlineStyle(context, color: tokens.primaryInk),
            ),
            const SizedBox(height: AppSpace.xxs),
            Text(
              l10n.reviewDueCount(cards.length),
              style: theme.textTheme.titleLarge?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpace.xxs),
            Text(
              '$shown$more · ${l10n.reviewDueMinutes(minutes)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => context.push('/review/session'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(l10n.reviewStartCta)),
                  const SizedBox(width: AppSpace.xs),
                  // arrow_forward mirrors itself in right-to-left layouts.
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nothing due: says so, and when the next review is — or, before
/// anything is in review, that words from lessons will come back here.
class _CaughtUpCard extends StatelessWidget {
  const _CaughtUpCard({required this.daysUntilNext});

  final int? daysUntilNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final feedback = theme.extension<FeedbackTheme>()!;
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Row(
          children: [
            ExcludeSemantics(
              child: CircleAvatar(
                radius: 22,
                backgroundColor: feedback.successContainer,
                child: Icon(Icons.check_rounded, color: feedback.success),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.reviewCaughtUpTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    daysUntilNext == null
                        ? l10n.reviewCaughtUpEmpty
                        : l10n.reviewNextIn(daysUntilNext!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An overline, an optional line under it, and a card of [rows] showing
/// the first three until "All N" is tapped.
class _Section extends StatefulWidget {
  const _Section({required this.overline, required this.rows, this.body});

  final String overline;
  final String? body;
  final List<Widget> rows;

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  static const _collapsedCount = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final rows = widget.rows;
    final canExpand = rows.length > _collapsedCount;
    final visible = _expanded || !canExpand
        ? rows
        : rows.take(_collapsedCount).toList();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.overline.toUpperCase(),
                  style: overlineStyle(context, color: tokens.textSecondary),
                ),
              ),
              if (canExpand)
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded
                        ? l10n.reviewShowFewer
                        : l10n.reviewShowAll(rows.length),
                  ),
                ),
            ],
          ),
          if (widget.body != null)
            Text(
              widget.body!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
          if (visible.isNotEmpty) ...[
            const SizedBox(height: AppSpace.xs),
            Material(
              color: tokens.card,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                side: BorderSide(color: tokens.border),
              ),
              child: Column(
                children: [
                  for (final (i, row) in visible.indexed) ...[
                    if (i > 0) Divider(height: 1, color: tokens.border),
                    row,
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A lesson whose goals need more practice: its title and Arabic, the
/// level and unit it sits in, and the skills it practises; tapping opens a
/// practice activity from it. The level is named because weak spots come
/// from every level the learner has units in progress in at once.
class _WeakSpotRow extends StatelessWidget {
  const _WeakSpotRow({required this.spot});

  final WeakSpot spot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final practice = practiceSetForWeakSpot(spot);
    final skills = spot.skills
        .map((s) => learnerSkillLabel(l10n, s))
        .join(' · ');

    return InkWell(
      onTap: practice.activities.isEmpty
          ? null
          : () => context.push('/review/practice', extra: practice),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md - 2,
          vertical: AppSpace.sm,
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: CircleAvatar(
                radius: 18,
                backgroundColor: tokens.primaryInkTint,
                child: Icon(
                  spot.skills.isEmpty
                      ? Icons.school_outlined
                      : skillIcon(spot.skills.first),
                  size: 20,
                  color: tokens.primaryInk,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: _TwoLanguageText(
                english: spot.lesson.title,
                arabic: spot.lesson.titleAr,
                meta: l10n.reviewWeakSpotMeta(
                  spot.levelCode,
                  spot.unitNumber,
                  skills,
                ),
              ),
            ),
            if (practice.activities.isNotEmpty)
              Icon(Icons.chevron_right_rounded, color: tokens.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// English (left-to-right) over its Arabic, with an optional meta line.
class _TwoLanguageText extends StatelessWidget {
  const _TwoLanguageText({
    required this.english,
    required this.arabic,
    this.meta,
  });

  final String english;
  final String arabic;
  final String? meta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ContentText.en(
          english,
          style: theme.textTheme.titleMedium?.copyWith(
            color: tokens.textPrimary,
          ),
        ),
        ContentText.ar(
          arabic,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: tokens.textSecondary,
          ),
        ),
        if (meta != null)
          Text(
            meta!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _BrowseTile extends StatelessWidget {
  const _BrowseTile({
    required this.icon,
    required this.title,
    required this.meta,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    return Material(
      color: tokens.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: tokens.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md - 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: tokens.primaryInkTint,
                  child: Icon(icon, size: 20, color: tokens.primaryInk),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                meta,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedItem {
  const _SavedItem({
    required this.text,
    required this.arabic,
    required this.route,
  });

  final String text;
  final String arabic;
  final String route;

  /// A saved word or phrase, or null when its level isn't loaded or its id
  /// no longer resolves there.
  static _SavedItem? vocabulary(
    ReviewContent content,
    VocabularyReviewStateData s,
  ) {
    final lexiconId = s.lexiconId;
    if (lexiconId != null) {
      final item = content.lexicon(lexiconId);
      if (item == null) return null;
      return _SavedItem(
        text: item.headword,
        arabic: item.arabic,
        route: '/review/vocabulary/${item.id}',
      );
    }
    final chunkId = s.chunkId;
    if (chunkId == null) return null;
    final item = content.chunk(chunkId);
    if (item == null) return null;
    return _SavedItem(
      text: item.text,
      arabic: item.arabic,
      route: '/review/chunks/${item.id}',
    );
  }

  /// A saved grammar form — see [vocabulary].
  static _SavedItem? grammar(ReviewContent content, GrammarReviewStateData s) {
    final item = content.grammar(s.grammarId);
    if (item == null) return null;
    return _SavedItem(
      text: item.form,
      arabic: item.meaningAr,
      route: '/review/grammar/${item.id}',
    );
  }
}

class _SavedRow extends StatelessWidget {
  const _SavedRow({required this.item});

  final _SavedItem item;

  @override
  Widget build(BuildContext context) {
    final streak = Theme.of(context).extension<GamificationTheme>()!;
    return InkWell(
      onTap: () => context.push(item.route),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md - 2,
          vertical: AppSpace.sm - 2,
        ),
        child: Row(
          children: [
            Expanded(
              child: _TwoLanguageText(english: item.text, arabic: item.arabic),
            ),
            ExcludeSemantics(
              child: Icon(
                Icons.star_rounded,
                size: 20,
                color: streak.streakAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
