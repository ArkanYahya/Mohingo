import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/part_of_speech_label.dart';
import 'vocabulary_detail_view.dart';

/// One lexicon entry's page — see [VocabularyDetailView]. Two senses that
/// share a headword (e.g. `A1.LEX.PICTURE.N01`/`N02`) are separate pages,
/// keyed by id.
class WordDetailScreen extends ConsumerWidget {
  const WordDetailScreen({required this.lexiconId, super.key});

  final String lexiconId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(contentIndexForIdProvider(lexiconId));

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
        return VocabularyDetailView(
          index: index,
          lexiconId: item.id,
          kindLabel:
              '${l10n.reviewSessionWord} · '
              '${partOfSpeechLabel(l10n, item.partOfSpeech)}',
          text: item.headword,
          arabic: item.arabic,
          usage: item.productive
              ? l10n.wordUsageProductive
              : l10n.wordUsageReceptive,
          examples: item.examples,
          introducedIn: item.introducedIn,
        );
      },
    );
  }
}
