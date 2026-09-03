import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../domain/spaced_review_scheduler.dart';
import '../providers/vocabulary_providers.dart';

/// The 3-button spaced-review confidence row, shared by word and chunk
/// detail screens. Recording a review here only ever updates the vocabulary
/// memory schedule — it never grants course/Can-Do mastery, which is
/// tracked entirely separately via `MasteryAggregationService`. See
/// docs/DATA_MODEL.md.
class ReviewConfidenceRow extends ConsumerWidget {
  const ReviewConfidenceRow({this.lexiconId, this.chunkId, super.key})
    : assert(
        (lexiconId == null) != (chunkId == null),
        'exactly one of lexiconId/chunkId must be set',
      );

  final String? lexiconId;
  final String? chunkId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.reviewHowWellKnew,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _confidenceButton(
              context,
              ref,
              l10n.reviewQualityAgain,
              ReviewQuality.again,
            ),
            const SizedBox(width: 8),
            _confidenceButton(
              context,
              ref,
              l10n.reviewQualityGood,
              ReviewQuality.good,
            ),
            const SizedBox(width: 8),
            _confidenceButton(
              context,
              ref,
              l10n.reviewQualityEasy,
              ReviewQuality.easy,
            ),
          ],
        ),
      ],
    );
  }

  Widget _confidenceButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    ReviewQuality quality,
  ) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () async {
          final learner = await ref.read(currentLearnerProvider.future);
          await ref
              .read(vocabularyReviewServiceProvider)
              .recordReview(
                learnerId: learner.id,
                lexiconId: lexiconId,
                chunkId: chunkId,
                quality: quality,
              );
          ref.invalidate(allVocabularyReviewStateProvider);
        },
        child: Text(label),
      ),
    );
  }
}
