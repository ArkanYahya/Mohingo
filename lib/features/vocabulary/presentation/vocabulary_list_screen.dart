import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/feedback_theme_extension.dart';
import '../../../core/widgets/status_indicator.dart';
import '../providers/vocabulary_providers.dart';

/// The Vocabulary area: separate Word and Chunk views, searchable by
/// English word or Arabic meaning, filterable by favourite/productive
/// status. Two lexical senses that share a headword (e.g. the bundle's
/// `A1.LEX.PICTURE.N01`/`N02`) are always distinct rows, keyed by id, never
/// merged by spelling. See docs/ARCHITECTURE.md.
class VocabularyListScreen extends StatefulWidget {
  const VocabularyListScreen({super.key});

  @override
  State<VocabularyListScreen> createState() => _VocabularyListScreenState();
}

class _VocabularyListScreenState extends State<VocabularyListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );
  final _searchController = TextEditingController();
  bool _favoritesOnly = false;
  bool _productiveOnly = false;

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navReview),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.vocabularyTabWords),
            Tab(text: l10n.vocabularyTabChunks),
          ],
        ),
      ),
      body: Column(
        children: [
          const _VocabularyStatsHeader(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.vocabularySearchHint,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text(l10n.vocabularyFavoritesOnly),
                      selected: _favoritesOnly,
                      onSelected: (v) => setState(() => _favoritesOnly = v),
                    ),
                    FilterChip(
                      label: Text(l10n.vocabularyProductiveOnly),
                      selected: _productiveOnly,
                      onSelected: (v) => setState(() => _productiveOnly = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _WordListView(
                  query: _searchController.text,
                  favoritesOnly: _favoritesOnly,
                  productiveOnly: _productiveOnly,
                ),
                _ChunkListView(
                  query: _searchController.text,
                  favoritesOnly: _favoritesOnly,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

bool _matchesQuery(String query, List<String> haystack) {
  if (query.trim().isEmpty) return true;
  final lower = query.trim().toLowerCase();
  return haystack.any((s) => s.toLowerCase().contains(lower));
}

/// The 3 stat tiles (Due / Learning / Learned) plus the saved-words count
/// row, above the search/tab UI. Counts are aggregated across *both* words
/// and chunks — one combined "vocabulary" picture, even though the list
/// below splits them into tabs. See docs/DESIGN_SYSTEM.md.
class _VocabularyStatsHeader extends ConsumerWidget {
  const _VocabularyStatsHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final feedbackTheme = Theme.of(context).extension<FeedbackTheme>()!;
    final contentAsync = ref.watch(courseContentProvider('a1'));
    final reviewStateAsync = ref.watch(allVocabularyReviewStateProvider);

    final index = contentAsync.value;
    if (index == null) return const SizedBox.shrink();

    final reviewState = reviewStateAsync.value ?? const [];
    final reviewStateByLexiconId = {
      for (final s in reviewState)
        if (s.lexiconId != null) s.lexiconId!: s,
    };
    final reviewStateByChunkId = {
      for (final s in reviewState)
        if (s.chunkId != null) s.chunkId!: s,
    };
    final favoritesCount = reviewState.where((s) => s.isFavorite).length;

    var due = 0;
    var learning = 0;
    var learned = 0;
    final now = DateTime.now();
    void tally(ProgressState state) {
      switch (state) {
        case ProgressState.needsReview:
          due++;
        case ProgressState.inProgress:
          learning++;
        case ProgressState.mastered:
          learned++;
        case ProgressState.notStarted:
          break;
      }
    }

    for (final item in index.bundle.lexicon) {
      final state = reviewStateByLexiconId[item.id];
      tally(
        _vocabularyProgressState(
          repetitions: state?.repetitions ?? 0,
          dueAt: state?.dueAt,
          now: now,
        ),
      );
    }
    for (final item in index.bundle.chunks) {
      final state = reviewStateByChunkId[item.id];
      tally(
        _vocabularyProgressState(
          repetitions: state?.repetitions ?? 0,
          dueAt: state?.dueAt,
          now: now,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          // IntrinsicHeight, not Row(crossAxisAlignment: stretch) — this
          // Row sits in an unbounded-height context (a plain, non-Expanded
          // Column child), and `stretch` there asks its flex children for
          // infinite height.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.replay,
                    label: l10n.vocabularyStatDue,
                    count: due,
                    fill: colorScheme.error,
                    onFill: colorScheme.onError,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    icon: Icons.hourglass_bottom,
                    label: l10n.vocabularyStatLearning,
                    count: learning,
                    fill: colorScheme.primary,
                    onFill: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    icon: Icons.check,
                    label: l10n.vocabularyStateLearned,
                    count: learned,
                    fill: feedbackTheme.success,
                    onFill: feedbackTheme.onSuccess,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.bookmark, color: colorScheme.onPrimaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.vocabularySavedWordsTitle,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: colorScheme.onPrimaryContainer),
                  ),
                ),
                Text(
                  '$favoritesCount',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.fill,
    required this.onFill,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color fill;
  final Color onFill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: onFill, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: onFill, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            '$count',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: onFill, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _WordListView extends ConsumerWidget {
  const _WordListView({
    required this.query,
    required this.favoritesOnly,
    required this.productiveOnly,
  });

  final String query;
  final bool favoritesOnly;
  final bool productiveOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final contentAsync = ref.watch(courseContentProvider('a1'));
    final reviewStateAsync = ref.watch(allVocabularyReviewStateProvider);

    return contentAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (index) {
        final favoriteLexiconIds = {
          for (final s in reviewStateAsync.value ?? const [])
            if (s.isFavorite && s.lexiconId != null) s.lexiconId,
        };
        final reviewStateByLexiconId = {
          for (final s in reviewStateAsync.value ?? const [])
            if (s.lexiconId != null) s.lexiconId!: s,
        };

        final items = index.bundle.lexicon.where((item) {
          if (!_matchesQuery(query, [
            item.headword,
            item.arabic,
            item.meaning,
          ])) {
            return false;
          }
          if (favoritesOnly && !favoriteLexiconIds.contains(item.id)) {
            return false;
          }
          if (productiveOnly && !item.productive) return false;
          return true;
        }).toList();

        if (items.isEmpty) {
          return Center(child: Text(l10n.vocabularyEmptyResults));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            final isFavorite = favoriteLexiconIds.contains(item.id);
            final reviewState = reviewStateByLexiconId[item.id];
            return _VocabularyRow(
              headword: item.headword,
              arabic: item.arabic,
              isFavorite: isFavorite,
              progressState: _vocabularyProgressState(
                repetitions: reviewState?.repetitions ?? 0,
                dueAt: reviewState?.dueAt,
                now: DateTime.now(),
              ),
              onTap: () => context.push('/review/vocabulary/${item.id}'),
            );
          },
        );
      },
    );
  }
}

class _ChunkListView extends ConsumerWidget {
  const _ChunkListView({required this.query, required this.favoritesOnly});

  final String query;
  final bool favoritesOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final contentAsync = ref.watch(courseContentProvider('a1'));
    final reviewStateAsync = ref.watch(allVocabularyReviewStateProvider);

    return contentAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (index) {
        final favoriteChunkIds = {
          for (final s in reviewStateAsync.value ?? const [])
            if (s.isFavorite && s.chunkId != null) s.chunkId,
        };
        final reviewStateByChunkId = {
          for (final s in reviewStateAsync.value ?? const [])
            if (s.chunkId != null) s.chunkId!: s,
        };

        final items = index.bundle.chunks.where((item) {
          if (!_matchesQuery(query, [item.text, item.arabic])) return false;
          if (favoritesOnly && !favoriteChunkIds.contains(item.id)) {
            return false;
          }
          return true;
        }).toList();

        if (items.isEmpty) {
          return Center(child: Text(l10n.vocabularyEmptyResults));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            final isFavorite = favoriteChunkIds.contains(item.id);
            final reviewState = reviewStateByChunkId[item.id];
            return _VocabularyRow(
              headword: item.text,
              arabic: item.arabic,
              isFavorite: isFavorite,
              progressState: _vocabularyProgressState(
                repetitions: reviewState?.repetitions ?? 0,
                dueAt: reviewState?.dueAt,
                now: DateTime.now(),
              ),
              onTap: () => context.push('/review/chunks/${item.id}'),
            );
          },
        );
      },
    );
  }
}

/// Maps one vocabulary/chunk review row onto the shared 4-state
/// [ProgressState]: no row (or never successfully recalled) is
/// [ProgressState.notStarted]; overdue is [ProgressState.needsReview];
/// recalled at least once but not yet graduated (repetitions < 3, matching
/// [SpacedReviewScheduler]'s interval steps: 1st repetition -> 1 day, 2nd ->
/// 6 days, 3rd+ -> ease-factor-driven) is [ProgressState.inProgress];
/// repetitions >= 3 is [ProgressState.mastered]. See docs/superpowers/specs/
/// 2026-09-04-ui-navigation-redesign-design.md.
ProgressState _vocabularyProgressState({
  required int repetitions,
  required DateTime? dueAt,
  required DateTime now,
}) {
  if (repetitions == 0) return ProgressState.notStarted;
  if (dueAt != null && dueAt.isBefore(now)) return ProgressState.needsReview;
  if (repetitions >= 3) return ProgressState.mastered;
  return ProgressState.inProgress;
}

class _VocabularyRow extends StatelessWidget {
  const _VocabularyRow({
    required this.headword,
    required this.arabic,
    required this.isFavorite,
    required this.progressState,
    required this.onTap,
  });

  final String headword;
  final String arabic;
  final bool isFavorite;
  final ProgressState progressState;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final feedbackTheme = Theme.of(context).extension<FeedbackTheme>()!;

    // A bigger circular icon node, matching the unit overview's lesson-path
    // treatment (see unit_overview_screen.dart's _LessonNode) — the row
    // card itself stays plain (surfaceContainer) rather than tinted, since
    // this list can run to 100+ items and a tinted row per state would be
    // visual noise at that density; only the circle carries the colour.
    final (
      Color circleFill,
      Color? circleBorder,
      Color iconColor,
    ) = switch (progressState) {
      ProgressState.mastered => (
        feedbackTheme.success,
        null,
        feedbackTheme.onSuccess,
      ),
      ProgressState.needsReview => (
        colorScheme.errorContainer,
        null,
        colorScheme.error,
      ),
      ProgressState.inProgress => (
        colorScheme.primaryContainer,
        null,
        colorScheme.primary,
      ),
      ProgressState.notStarted => (
        colorScheme.surface,
        colorScheme.outlineVariant,
        colorScheme.onSurfaceVariant,
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: circleFill,
                    border: circleBorder != null
                        ? Border.all(color: circleBorder, width: 2)
                        : null,
                  ),
                  child: Center(
                    // A graduated item announces "Learned", not the shared
                    // "Mastered" label: memorising a word is a
                    // spaced-review outcome, never course mastery (see
                    // docs/GLOSSARY.md and [ReviewConfidenceRow]).
                    child: StatusIndicator(
                      state: progressState,
                      size: 20,
                      colorOverride: iconColor,
                      semanticLabelOverride:
                          progressState == ProgressState.mastered
                          ? l10n.vocabularyStateLearned
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(headword, textDirection: TextDirection.ltr),
                      Text(
                        arabic,
                        textDirection: TextDirection.rtl,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isFavorite) Icon(Icons.star, color: colorScheme.tertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
