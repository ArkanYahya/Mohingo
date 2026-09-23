import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/error_state_view.dart';
import '../domain/legal_documents.dart';
import '../providers/agreement_providers.dart';
import 'simple_markdown.dart';

/// The privacy policy or the terms of use, in the interface language.
/// Reached from the first-run agreement and from About; works offline, since
/// the text ships with the app.
class LegalDocumentScreen extends ConsumerWidget {
  const LegalDocumentScreen({required this.document, super.key});

  final LegalDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final text = ref.watch(legalDocumentTextProvider((document, languageCode)));
    return Scaffold(
      appBar: AppBar(
        title: Text(switch (document) {
          LegalDocument.privacy => l10n.legalPrivacyTitle,
          LegalDocument.terms => l10n.legalTermsTitle,
        }),
      ),
      body: text.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const ErrorStateView(),
        data: (source) => SafeArea(
          top: false,
          child: SelectionArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.sm,
                AppSpace.md,
                AppSpace.xl,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: SimpleMarkdown(source),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
