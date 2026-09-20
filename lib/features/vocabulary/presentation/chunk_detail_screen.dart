import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import 'vocabulary_detail_view.dart';

/// One chunk's (phrase's) page — see [VocabularyDetailView].
class ChunkDetailScreen extends ConsumerWidget {
  const ChunkDetailScreen({required this.chunkId, super.key});

  final String chunkId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(contentIndexForIdProvider(chunkId));

    return contentAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
      data: (index) {
        final l10n = AppLocalizations.of(context)!;
        final item = index.chunkById[chunkId];
        if (item == null) {
          return Scaffold(body: Center(child: Text(l10n.contentNotFoundTitle)));
        }
        return VocabularyDetailView(
          index: index,
          chunkId: item.id,
          kindLabel: l10n.reviewSessionPhrase,
          text: item.text,
          arabic: item.arabic,
          introducedIn: item.introducedIn,
        );
      },
    );
  }
}
