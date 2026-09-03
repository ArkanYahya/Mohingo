import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
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
            return _VocabularyRow(
              headword: item.headword,
              arabic: item.arabic,
              isFavorite: isFavorite,
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
            return _VocabularyRow(
              headword: item.text,
              arabic: item.arabic,
              isFavorite: isFavorite,
              onTap: () => context.push('/review/chunks/${item.id}'),
            );
          },
        );
      },
    );
  }
}

class _VocabularyRow extends StatelessWidget {
  const _VocabularyRow({
    required this.headword,
    required this.arabic,
    required this.isFavorite,
    required this.onTap,
  });

  final String headword;
  final String arabic;
  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(headword, textDirection: TextDirection.ltr),
      subtitle: Text(arabic, textDirection: TextDirection.rtl),
      trailing: isFavorite
          ? Icon(Icons.star, color: Theme.of(context).colorScheme.tertiary)
          : null,
    );
  }
}
