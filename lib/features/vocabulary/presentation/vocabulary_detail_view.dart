import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/index/course_content_index.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/overline_style.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';
import '../../review/domain/next_review.dart';
import '../../review/providers/review_providers.dart';
import '../../speech/presentation/listen_button.dart';
import '../domain/spaced_review_scheduler.dart';
import '../domain/vocabulary_status.dart';
import '../providers/vocabulary_providers.dart';
import 'review_rating_bar.dart';
import 'vocabulary_status_pill.dart';

/// The page for one word or phrase: what it is ([kindLabel]), the English
/// with audio, the Arabic, what it's for ([usage]), where it stands in
/// review, [examples] with audio, and the lesson that introduced it. A star
/// in the app bar saves it. While it's new or due, the rating bar is pinned
/// to the bottom; rating saves to the review schedule and the page stays,
/// showing when it comes back.
///
/// Exactly one of [lexiconId]/[chunkId] is set.
class VocabularyDetailView extends ConsumerStatefulWidget {
  const VocabularyDetailView({
    required this.index,
    required this.kindLabel,
    required this.text,
    required this.arabic,
    required this.introducedIn,
    this.usage,
    this.examples = const [],
    this.lexiconId,
    this.chunkId,
    super.key,
  }) : assert((lexiconId == null) != (chunkId == null));

  final CourseContentIndex index;
  final String kindLabel;
  final String text;
  final String arabic;
  final String? usage;
  final List<String> examples;

  /// The lesson id that introduces the item.
  final String introducedIn;
  final String? lexiconId;
  final String? chunkId;

  @override
  ConsumerState<VocabularyDetailView> createState() =>
      _VocabularyDetailViewState();
}

class _VocabularyDetailViewState extends ConsumerState<VocabularyDetailView> {
  bool _saving = false;

  Future<void> _rate(ReviewQuality quality) async {
    setState(() => _saving = true);
    final learner = await ref.read(currentLearnerProvider.future);
    await ref
        .read(vocabularyReviewServiceProvider)
        .recordReview(
          learnerId: learner.id,
          lexiconId: widget.lexiconId,
          chunkId: widget.chunkId,
          quality: quality,
        );
    // Home's review card, the nav badge and the Review tab read these too.
    ref.invalidate(allVocabularyReviewStateProvider);
    ref.invalidate(dueVocabularyProvider);
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _setFavorite(bool isFavorite) async {
    final learner = await ref.read(currentLearnerProvider.future);
    await ref
        .read(reviewStateRepositoryProvider)
        .setVocabularyFavorite(
          learnerId: learner.id,
          lexiconId: widget.lexiconId,
          chunkId: widget.chunkId,
          isFavorite: isFavorite,
        );
    ref.invalidate(allVocabularyReviewStateProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final statesAsync = ref.watch(allVocabularyReviewStateProvider);
    final state = (statesAsync.value ?? const [])
        .where(
          (s) => widget.lexiconId != null
              ? s.lexiconId == widget.lexiconId
              : s.chunkId == widget.chunkId,
        )
        .firstOrNull;
    final now = DateTime.now();
    final status = vocabularyStatus(state, now);
    final isFavorite = state?.isFavorite ?? false;
    final canRate =
        statesAsync.hasValue &&
        (status == VocabularyStatus.newItem || status == VocabularyStatus.due);

    final statusText = switch (status) {
      VocabularyStatus.newItem => l10n.wordStatusNew,
      VocabularyStatus.due => l10n.wordStatusDue,
      _ => l10n.reviewNextIn(daysUntilNextReview([state!], now) ?? 0),
    };

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
            ),
            tooltip: isFavorite
                ? l10n.favoriteRemoveTooltip
                : l10n.favoriteAddTooltip,
            onPressed: () => _setFavorite(!isFavorite),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          0,
          AppSpace.md,
          AppSpace.lg,
        ),
        children: [
          Text(
            widget.kindLabel.toUpperCase(),
            style: overlineStyle(context, color: tokens.textSecondary),
          ),
          const SizedBox(height: AppSpace.xxs),
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    widget.text,
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              ListenButton(text: widget.text),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              widget.arabic,
              textDirection: TextDirection.rtl,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
          ),
          if (widget.usage != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              widget.usage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          Semantics(
            liveRegion: true,
            container: true,
            child: _Box(
              child: Row(
                children: [
                  if (status != VocabularyStatus.newItem) ...[
                    VocabularyStatusPill(status: status),
                    const SizedBox(width: AppSpace.sm),
                  ],
                  Expanded(
                    child: Text(
                      statusText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.examples.isNotEmpty) ...[
            _Heading(l10n.wordDetailExamples),
            for (final example in widget.examples) ...[
              _Box(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpace.md,
                  AppSpace.xxs,
                  AppSpace.xxs,
                  AppSpace.xxs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          example,
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: tokens.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    ListenButton(text: example),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xs),
            ],
          ],
          ..._metIn(context),
        ],
      ),
      bottomNavigationBar: canRate
          ? ReviewRatingBar(state: state, enabled: !_saving, onRate: _rate)
          : null,
    );
  }

  List<Widget> _metIn(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final lesson = widget.index.lessonsById[widget.introducedIn];
    final unit = widget
        .index
        .unitsById[widget.index.unitIdByLessonId[widget.introducedIn]];
    if (lesson == null || unit == null) return const [];
    final unitNumber = widget.index.bundle.units.indexOf(unit) + 1;
    final lessonNumber = unit.lessons.indexOf(lesson) + 1;
    return [
      _Heading(l10n.wordMetInOverline),
      _Box(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                lesson.title,
                textDirection: TextDirection.ltr,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                lesson.titleAr,
                textDirection: TextDirection.rtl,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
            ),
            Text(
              l10n.wordMetInMeta(unitNumber, lessonNumber),
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.lg, bottom: AppSpace.xs),
      child: Text(
        text.toUpperCase(),
        style: overlineStyle(context, color: tokens.textSecondary),
      ),
    );
  }
}

/// A hairline card.
class _Box extends StatelessWidget {
  const _Box({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.md - 2),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
