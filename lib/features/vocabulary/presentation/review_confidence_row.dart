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
///
/// After a tap: shows a brief saved confirmation, then pops the current
/// route — the screen this row lives on (a word/chunk detail screen) was
/// pushed to review this one item, so returning is the natural "done"
/// action. See docs/superpowers/specs/
/// 2026-09-04-ui-navigation-redesign-design.md.
class ReviewConfidenceRow extends ConsumerStatefulWidget {
  const ReviewConfidenceRow({this.lexiconId, this.chunkId, super.key})
    : assert(
        (lexiconId == null) != (chunkId == null),
        'exactly one of lexiconId/chunkId must be set',
      );

  final String? lexiconId;
  final String? chunkId;

  @override
  ConsumerState<ReviewConfidenceRow> createState() =>
      _ReviewConfidenceRowState();
}

class _ReviewConfidenceRowState extends ConsumerState<ReviewConfidenceRow> {
  ReviewQuality? _selected;

  Future<void> _record(ReviewQuality quality) async {
    setState(() => _selected = quality);
    final learner = await ref.read(currentLearnerProvider.future);
    await ref
        .read(vocabularyReviewServiceProvider)
        .recordReview(
          learnerId: learner.id,
          lexiconId: widget.lexiconId,
          chunkId: widget.chunkId,
          quality: quality,
        );
    ref.invalidate(allVocabularyReviewStateProvider);
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_selected != null) {
      return _SavedConfirmation();
    }
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
            _confidenceButton(l10n.reviewQualityAgain, ReviewQuality.again),
            const SizedBox(width: 8),
            _confidenceButton(l10n.reviewQualityGood, ReviewQuality.good),
            const SizedBox(width: 8),
            _confidenceButton(l10n.reviewQualityEasy, ReviewQuality.easy),
          ],
        ),
      ],
    );
  }

  Widget _confidenceButton(String label, ReviewQuality quality) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _record(quality),
        child: Text(label),
      ),
    );
  }
}

class _SavedConfirmation extends StatelessWidget {
  const _SavedConfirmation();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: colorScheme.onPrimaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.reviewConfidenceSaved,
                style: TextStyle(color: colorScheme.onPrimaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
