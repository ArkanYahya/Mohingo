import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/curriculum_structure.dart';
import '../../../content/models/domain_definitions.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';
import '../../speech/presentation/listen_button.dart';
import '../providers/grammar_providers.dart';

class GrammarDetailScreen extends ConsumerWidget {
  const GrammarDetailScreen({required this.grammarId, super.key});

  final String grammarId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(courseContentProvider('a1'));

    return contentAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
      data: (index) {
        final l10n = AppLocalizations.of(context)!;
        final item = index.grammarById[grammarId];
        if (item == null) {
          return Scaffold(body: Center(child: Text(l10n.contentNotFoundTitle)));
        }

        final linkedLessons = <Lesson>[
          for (final unit in index.bundle.units)
            for (final lesson in unit.lessons)
              if (lesson.grammar.contains(grammarId)) lesson,
        ];
        final practiceActivities = [
          for (final lesson in linkedLessons)
            for (final activity in lesson.activities)
              if (activity.mode == ActivityMode.practice) activity,
        ];

        final reviewStateAsync = ref.watch(allGrammarReviewStateProvider);
        final state = (reviewStateAsync.value ?? const []).where(
          (s) => s.grammarId == grammarId,
        );
        final isFavorite = state.any((s) => s.isFavorite);
        final isReviewed = state.any((s) => s.markedReviewedAt != null);

        return Scaffold(
          appBar: AppBar(
            title: Text(item.form),
            actions: [
              IconButton(
                icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                tooltip: isFavorite
                    ? l10n.favoriteRemoveTooltip
                    : l10n.favoriteAddTooltip,
                onPressed: () async {
                  final learner = await ref.read(currentLearnerProvider.future);
                  await ref
                      .read(reviewStateRepositoryProvider)
                      .setGrammarFavorite(
                        learnerId: learner.id,
                        grammarId: grammarId,
                        isFavorite: !isFavorite,
                      );
                  ref.invalidate(allGrammarReviewStateProvider);
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.grammarDetailForm,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Row(
                children: [
                  Text(
                    item.form,
                    textDirection: TextDirection.ltr,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  ListenButton(text: item.form),
                ],
              ),
              if (item.shortForm != null)
                Text(
                  item.shortForm!,
                  textDirection: TextDirection.ltr,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              Text(
                item.meaningAr,
                textDirection: TextDirection.rtl,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (item.examples.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.wordDetailExamples,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (final example in item.examples) ...[
                  Row(
                    children: [
                      Text(example.en, textDirection: TextDirection.ltr),
                      ListenButton(text: example.en),
                    ],
                  ),
                  Text(
                    example.ar,
                    textDirection: TextDirection.rtl,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                ],
              ],
              if (linkedLessons.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.grammarDetailLinkedLessons,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (final lesson in linkedLessons)
                  Text(lesson.title, textDirection: TextDirection.ltr),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isReviewed
                          ? null
                          : () async {
                              final learner = await ref.read(
                                currentLearnerProvider.future,
                              );
                              await ref
                                  .read(reviewStateRepositoryProvider)
                                  .markGrammarReviewed(
                                    learnerId: learner.id,
                                    grammarId: grammarId,
                                  );
                              ref.invalidate(allGrammarReviewStateProvider);
                            },
                      child: Text(
                        isReviewed
                            ? l10n.grammarReviewed
                            : l10n.grammarMarkReviewed,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: practiceActivities.isEmpty
                          ? null
                          : () => context.push(
                              '/review/practice',
                              extra: practiceActivities.first,
                            ),
                      child: Text(l10n.grammarQuickPractice),
                    ),
                  ),
                ],
              ),
              if (practiceActivities.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.grammarNoLinkedPractice,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
