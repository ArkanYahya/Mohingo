import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../grammar/providers/grammar_providers.dart';
import '../../vocabulary/providers/vocabulary_providers.dart';
import '../providers/review_providers.dart';

/// Unites due vocabulary/chunks, favourites, and weak Can-Do objectives.
///
/// Vocabulary-memory scheduling (the spaced-review "due" queue) is kept
/// entirely separate from communicative mastery (weak objectives, evidence
/// from real lesson activities) — remembering a flashcard never proves
/// listening/speaking/interaction ability. See docs/ARCHITECTURE.md.
class ReviewHomeScreen extends ConsumerWidget {
  const ReviewHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final contentAsync = ref.watch(courseContentProvider('a1'));
    final dueAsync = ref.watch(dueVocabularyProvider);
    final vocabStateAsync = ref.watch(allVocabularyReviewStateProvider);
    final grammarStateAsync = ref.watch(allGrammarReviewStateProvider);
    final weakAsync = ref.watch(weakObjectivesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navReview),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: l10n.vocabularyTabWords,
            onPressed: () => context.push('/review/vocabulary'),
          ),
          IconButton(
            icon: const Icon(Icons.rule),
            tooltip: l10n.grammarSectionTitle,
            onPressed: () => context.push('/review/grammar'),
          ),
        ],
      ),
      body: contentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (index) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section(
                title: l10n.reviewSectionDue,
                emptyLabel: l10n.reviewNothingDue,
                itemCount: dueAsync.value?.length,
                children: [
                  for (final state in dueAsync.value ?? const [])
                    Builder(
                      builder: (context) {
                        final label = state.lexiconId != null
                            ? index.lexiconById[state.lexiconId]?.headword
                            : index.chunkById[state.chunkId]?.text;
                        if (label == null) return const SizedBox.shrink();
                        return ListTile(
                          title: Text(label, textDirection: TextDirection.ltr),
                          onTap: () => context.push(
                            state.lexiconId != null
                                ? '/review/vocabulary/${state.lexiconId}'
                                : '/review/chunks/${state.chunkId}',
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: l10n.reviewSectionFavorites,
                emptyLabel: l10n.reviewNoFavorites,
                itemCount:
                    (vocabStateAsync.value?.where((s) => s.isFavorite).length ??
                        0) +
                    (grammarStateAsync.value
                            ?.where((s) => s.isFavorite)
                            .length ??
                        0),
                children: [
                  for (final state in vocabStateAsync.value ?? const [])
                    if (state.isFavorite)
                      Builder(
                        builder: (context) {
                          final label = state.lexiconId != null
                              ? index.lexiconById[state.lexiconId]?.headword
                              : index.chunkById[state.chunkId]?.text;
                          if (label == null) return const SizedBox.shrink();
                          return ListTile(
                            title: Text(
                              label,
                              textDirection: TextDirection.ltr,
                            ),
                            leading: const Icon(Icons.star),
                            onTap: () => context.push(
                              state.lexiconId != null
                                  ? '/review/vocabulary/${state.lexiconId}'
                                  : '/review/chunks/${state.chunkId}',
                            ),
                          );
                        },
                      ),
                  for (final state in grammarStateAsync.value ?? const [])
                    if (state.isFavorite)
                      Builder(
                        builder: (context) {
                          final label =
                              index.grammarById[state.grammarId]?.form;
                          if (label == null) return const SizedBox.shrink();
                          return ListTile(
                            title: Text(
                              label,
                              textDirection: TextDirection.ltr,
                            ),
                            leading: const Icon(Icons.star),
                            onTap: () => context.push(
                              '/review/grammar/${state.grammarId}',
                            ),
                          );
                        },
                      ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: l10n.reviewSectionWeakObjectives,
                emptyLabel: l10n.reviewNoWeakObjectives,
                itemCount: weakAsync.value?.length,
                children: [
                  for (final canDoId in weakAsync.value ?? const [])
                    ListTile(
                      title: Text(canDoId, textDirection: TextDirection.ltr),
                      trailing:
                          (index.activitiesByCanDoId[canDoId]?.isNotEmpty ??
                              false)
                          ? const Icon(Icons.chevron_right)
                          : null,
                      onTap:
                          (index.activitiesByCanDoId[canDoId]?.isNotEmpty ??
                              false)
                          ? () => context.push(
                              '/review/practice',
                              extra: index.activitiesByCanDoId[canDoId]!.first,
                            )
                          : null,
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.emptyLabel,
    required this.itemCount,
    required this.children,
  });

  final String title;
  final String emptyLabel;
  final int? itemCount;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        if (itemCount == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          )
        else if (itemCount == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              emptyLabel,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          ...children,
      ],
    );
  }
}
