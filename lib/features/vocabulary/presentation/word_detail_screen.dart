import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';
import '../../speech/presentation/listen_button.dart';
import '../providers/vocabulary_providers.dart';
import 'review_confidence_row.dart';

class WordDetailScreen extends ConsumerWidget {
  const WordDetailScreen({required this.lexiconId, super.key});

  final String lexiconId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(courseContentProvider('a1'));

    return contentAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
      data: (index) {
        final l10n = AppLocalizations.of(context)!;
        final item = index.lexiconById[lexiconId];
        if (item == null) {
          return Scaffold(body: Center(child: Text(l10n.contentNotFoundTitle)));
        }
        final unitTitle =
            index.unitsById[index.unitIdByLessonId[item.introducedIn]]?.title ??
            item.introducedIn;
        final reviewStateAsync = ref.watch(allVocabularyReviewStateProvider);
        final isFavorite = (reviewStateAsync.value ?? const []).any(
          (s) => s.lexiconId == item.id && s.isFavorite,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(item.headword),
            actions: [
              IconButton(
                icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                tooltip: isFavorite
                    ? l10n.favoriteRemoveTooltip
                    : l10n.favoriteAddTooltip,
                onPressed: () => _toggleFavorite(ref, item.id, !isFavorite),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Text(
                    item.headword,
                    textDirection: TextDirection.ltr,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  ListenButton(text: item.headword),
                ],
              ),
              Text(
                item.arabic,
                textDirection: TextDirection.rtl,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(item.partOfSpeech)),
                  if (item.receptive)
                    Chip(label: Text(l10n.vocabularyReceptiveLabel)),
                  if (item.productive)
                    Chip(label: Text(l10n.vocabularyProductiveLabel)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.wordDetailIntroducedIn(unitTitle),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (item.examples.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.wordDetailExamples,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (final example in item.examples)
                  Text(example, textDirection: TextDirection.ltr),
              ],
              const SizedBox(height: 24),
              ReviewConfidenceRow(lexiconId: item.id),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleFavorite(
    WidgetRef ref,
    String lexiconId,
    bool isFavorite,
  ) async {
    final learner = await ref.read(currentLearnerProvider.future);
    await ref
        .read(reviewStateRepositoryProvider)
        .setVocabularyFavorite(
          learnerId: learner.id,
          lexiconId: lexiconId,
          isFavorite: isFavorite,
        );
    ref.invalidate(allVocabularyReviewStateProvider);
  }
}
