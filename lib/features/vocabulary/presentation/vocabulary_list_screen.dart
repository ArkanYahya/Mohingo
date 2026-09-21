import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/index/course_content_index.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/gamification_theme_extension.dart';
import '../../../core/widgets/level_filter_chips.dart';
import '../../../core/widgets/search_field.dart';
import '../../../data/local/database.dart';
import '../../progress/providers/level_providers.dart';
import '../domain/vocabulary_status.dart';
import '../providers/vocabulary_providers.dart';
import 'vocabulary_status_pill.dart';

/// Which status the list is narrowed to.
enum _Filter { all, due, learning, learned, saved }

/// One row: a word or a phrase.
class _Entry {
  const _Entry({
    required this.text,
    required this.arabic,
    required this.searchable,
    required this.route,
    required this.status,
    required this.saved,
    required this.productive,
  });

  final String text;
  final String arabic;
  final List<String> searchable;
  final String route;
  final VocabularyStatus status;
  final bool saved;
  final bool productive;

  bool matches(_Filter filter) => switch (filter) {
    _Filter.all => true,
    _Filter.due => status == VocabularyStatus.due,
    _Filter.learning => status == VocabularyStatus.learning,
    _Filter.learned => status == VocabularyStatus.learned,
    _Filter.saved => saved,
  };
}

/// Words & phrases: every lexicon entry or chunk, searchable by English or
/// Arabic, switchable between words and phrases, and narrowed by review
/// status (with counts) or to saved items; words can also be narrowed to
/// those the learner should use when speaking and writing. Rows show the
/// English over the Arabic with a small status label. Two lexical senses
/// that share a headword (e.g. `A1.LEX.PICTURE.N01`/`N02`) are always
/// distinct rows, keyed by id, never merged by spelling. See
/// docs/ARCHITECTURE.md.
///
/// Opens on the level the learner is in ([currentLevelIdProvider]), so an
/// A2 learner sees the words A2 teaches — and carries a [LevelFilterChips]
/// row so they can still look back at A1's, which are in spaced review and
/// turn up in A2's texts. Picking a level here only changes what the list
/// shows; it never moves the learner between levels. Each row's id already
/// carries its level, so tapping one opens the right word page whichever
/// level is on screen (`contentIndexForIdProvider`).
class VocabularyListScreen extends ConsumerStatefulWidget {
  const VocabularyListScreen({super.key});

  @override
  ConsumerState<VocabularyListScreen> createState() =>
      _VocabularyListScreenState();
}

class _VocabularyListScreenState extends ConsumerState<VocabularyListScreen> {
  final _searchController = TextEditingController();
  bool _phrases = false;
  _Filter _filter = _Filter.all;
  bool _productiveOnly = false;

  /// A level the learner has filtered to. Null until they pick one, when
  /// the list follows the level they are actually in.
  String? _levelId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_Entry> _entries(
    CourseContentIndex index,
    List<VocabularyReviewStateData> states,
    DateTime now,
  ) {
    final byLexicon = {
      for (final s in states)
        if (s.lexiconId != null) s.lexiconId!: s,
    };
    final byChunk = {
      for (final s in states)
        if (s.chunkId != null) s.chunkId!: s,
    };
    if (_phrases) {
      return [
        for (final c in index.bundle.chunks)
          _Entry(
            text: c.text,
            arabic: c.arabic,
            searchable: [c.text, c.arabic],
            route: '/review/chunks/${c.id}',
            status: vocabularyStatus(byChunk[c.id], now),
            saved: byChunk[c.id]?.isFavorite ?? false,
            productive: c.productive,
          ),
      ];
    }
    return [
      for (final w in index.bundle.lexicon)
        _Entry(
          text: w.headword,
          arabic: w.arabic,
          searchable: [w.headword, w.arabic, w.meaning],
          route: '/review/vocabulary/${w.id}',
          status: vocabularyStatus(byLexicon[w.id], now),
          saved: byLexicon[w.id]?.isFavorite ?? false,
          productive: w.productive,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final catalog = ref.watch(levelCatalogProvider);
    final currentLevelIdAsync = ref.watch(currentLevelIdProvider);
    final shownLevelId = _levelId ?? currentLevelIdAsync.value;
    final AsyncValue<CourseContentIndex> contentAsync;
    if (currentLevelIdAsync.hasError) {
      contentAsync = AsyncValue.error(
        currentLevelIdAsync.error!,
        currentLevelIdAsync.stackTrace!,
      );
    } else if (shownLevelId != null) {
      contentAsync = ref.watch(courseContentProvider(shownLevelId));
    } else {
      contentAsync = const AsyncValue.loading();
    }
    final states =
        ref.watch(allVocabularyReviewStateProvider).value ?? const [];

    // The level row sits outside the content's loading/error branch: a
    // level whose bundle fails to load must not strand the learner on an
    // error page with no way back to their own level.
    final levelFilter = shownLevelId == null
        ? const SizedBox.shrink()
        : LevelFilterChips(
            catalog: catalog,
            selectedLevelId: shownLevelId,
            onSelect: (levelId) => setState(() => _levelId = levelId),
          );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewWordsTile)),
      body: contentAsync.when(
        loading: () => Column(
          children: [
            levelFilter,
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
        error: (error, _) => Column(
          children: [
            levelFilter,
            Expanded(child: Center(child: Text('$error'))),
          ],
        ),
        data: (index) {
          final query = _searchController.text.trim().toLowerCase();
          final kindEntries = _entries(
            index,
            states,
            DateTime.now(),
          ).where((e) => !_productiveOnly || _phrases || e.productive).toList();
          final shown = kindEntries
              .where(
                (e) =>
                    e.matches(_filter) &&
                    (query.isEmpty ||
                        e.searchable.any(
                          (s) => s.toLowerCase().contains(query),
                        )),
              )
              .toList();

          return Column(
            children: [
              levelFilter,
              _Controls(
                searchController: _searchController,
                onSearch: () => setState(() {}),
                phrases: _phrases,
                wordCount: index.bundle.lexicon.length,
                phraseCount: index.bundle.chunks.length,
                onKind: (phrases) => setState(() => _phrases = phrases),
                filter: _filter,
                counts: {
                  for (final f in _Filter.values)
                    f: kindEntries.where((e) => e.matches(f)).length,
                },
                onFilter: (f) => setState(() => _filter = f),
                productiveOnly: _productiveOnly,
                onProductive: (v) => setState(() => _productiveOnly = v),
              ),
              Expanded(
                child: shown.isEmpty
                    ? Center(child: Text(l10n.vocabularyEmptyResults))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpace.md,
                          0,
                          AppSpace.md,
                          AppSpace.lg,
                        ),
                        itemCount: shown.length,
                        itemBuilder: (context, i) => _EntryRow(
                          entry: shown[i],
                          isFirst: i == 0,
                          isLast: i == shown.length - 1,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Search, Words/Phrases, and the filter chips.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.searchController,
    required this.onSearch,
    required this.phrases,
    required this.wordCount,
    required this.phraseCount,
    required this.onKind,
    required this.filter,
    required this.counts,
    required this.onFilter,
    required this.productiveOnly,
    required this.onProductive,
  });

  final TextEditingController searchController;
  final VoidCallback onSearch;
  final bool phrases;
  final int wordCount;
  final int phraseCount;
  final ValueChanged<bool> onKind;
  final _Filter filter;
  final Map<_Filter, int> counts;
  final ValueChanged<_Filter> onFilter;
  final bool productiveOnly;
  final ValueChanged<bool> onProductive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final countStyle = theme.textTheme.labelMedium?.copyWith(
      color: tokens.textSecondary,
    );

    // Scales down rather than wrapping mid-word on a narrow screen with
    // large text.
    Widget kind(String label, int count) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: AppSpace.xs - 2),
          Text('$count', style: countStyle),
        ],
      ),
    );

    Widget chip(_Filter f, String label) {
      final count = counts[f] ?? 0;
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
        child: ChoiceChip(
          showCheckmark: false,
          selected: filter == f,
          onSelected: (_) => onFilter(f),
          label: Semantics(
            label: l10n.vocabularyFilterSemantics(label, count),
            child: ExcludeSemantics(
              child: Row(
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
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.xxs,
        AppSpace.md,
        AppSpace.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchField(
            controller: searchController,
            hintText: l10n.vocabularySearchHint,
            onChanged: (_) => onSearch(),
          ),
          const SizedBox(height: AppSpace.sm),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: false,
                label: kind(l10n.vocabularyTabWords, wordCount),
              ),
              ButtonSegment(
                value: true,
                label: kind(l10n.vocabularyTabChunks, phraseCount),
              ),
            ],
            selected: {phrases},
            onSelectionChanged: (s) => onKind(s.first),
          ),
          const SizedBox(height: AppSpace.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                chip(_Filter.all, l10n.vocabularyFilterAll),
                chip(_Filter.due, l10n.vocabularyStatDue),
                chip(_Filter.learning, l10n.vocabularyStatLearning),
                chip(_Filter.learned, l10n.vocabularyStateLearned),
                chip(_Filter.saved, l10n.vocabularyFilterSaved),
                if (!phrases)
                  FilterChip(
                    showCheckmark: true,
                    selected: productiveOnly,
                    onSelected: onProductive,
                    label: Text(l10n.vocabularyFilterProductive),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A word or phrase: English over Arabic, a star when saved, and its
/// status label. Rows join into one rounded card.
class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.isFirst,
    required this.isLast,
  });

  final _Entry entry;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    const radius = Radius.circular(AppRadius.card);

    return Column(
      children: [
        Material(
          color: tokens.card,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: isFirst ? radius : Radius.zero,
              bottom: isLast ? radius : Radius.zero,
            ),
          ),
          child: InkWell(
            onTap: () => context.push(entry.route),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.md - 2,
                vertical: AppSpace.sm - 2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            entry.text,
                            textDirection: TextDirection.ltr,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            entry.arabic,
                            textDirection: TextDirection.rtl,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: tokens.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entry.saved) ...[
                    Icon(
                      Icons.star_rounded,
                      size: 18,
                      semanticLabel: l10n.vocabularyFilterSaved,
                      color: theme.extension<GamificationTheme>()!.streakAccent,
                    ),
                    const SizedBox(width: AppSpace.xs),
                  ],
                  VocabularyStatusPill(status: entry.status),
                ],
              ),
            ),
          ),
        ),
        if (!isLast) Divider(height: 1, color: tokens.border),
      ],
    );
  }
}
