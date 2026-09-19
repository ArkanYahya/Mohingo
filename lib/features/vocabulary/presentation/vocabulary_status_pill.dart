import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/widgets/status_pill.dart';
import '../domain/vocabulary_status.dart';

/// A word's or phrase's review status as a [StatusPill]: "Due" (attention,
/// refresh mark), "Learning" (neutral), "Learned" (success, check).
/// Nothing for an item not in review yet — most of the list, so it stays
/// quiet.
class VocabularyStatusPill extends StatelessWidget {
  const VocabularyStatusPill({required this.status, super.key});

  final VocabularyStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (status) {
      VocabularyStatus.newItem => const SizedBox.shrink(),
      VocabularyStatus.due => StatusPill(
        label: l10n.vocabularyStatDue,
        tone: StatusTone.attention,
        icon: Icons.refresh_rounded,
      ),
      VocabularyStatus.learning => StatusPill(
        label: l10n.vocabularyStatLearning,
      ),
      VocabularyStatus.learned => StatusPill(
        label: l10n.vocabularyStateLearned,
        tone: StatusTone.success,
        icon: Icons.check_rounded,
      ),
    };
  }
}
