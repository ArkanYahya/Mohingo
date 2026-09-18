import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../content/models/registry_items.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/overline_style.dart';
import '../../../activity_engine/presentation/widgets/phrase_text.dart';
import '../../../speech/providers/speech_providers.dart';
import '../../../speech/providers/tts_preferences_provider.dart';
import 'lesson_intro_chrome.dart';

/// The second lesson-intro screen: the lesson's own phrases (from the
/// bundle's chunk registry) and grammar forms, right after the
/// conversation that used them.
///
/// Each phrase shows its fill-in slots, its Arabic, a NEW badge when this
/// lesson is where it's introduced, and a button to hear it. Grammar rows
/// show the form, its short form, and the registry's first example.
class LessonKeyPhrasesStep extends ConsumerWidget {
  const LessonKeyPhrasesStep({
    required this.overline,
    required this.lessonId,
    required this.phrases,
    required this.grammar,
    required this.continueLabel,
    required this.onContinue,
    super.key,
  });

  final String overline;

  /// Decides which phrases are NEW (introduced in this lesson).
  final String lessonId;
  final List<ChunkItem> phrases;
  final List<GrammarItem> grammar;
  final String continueLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;

    void speak(String text) => ref
        .read(textToSpeechServiceProvider)
        .speak(
          phraseForSpeech(text),
          localeCode: 'en',
          rate: ref.read(ttsRatePreferenceProvider),
          pitch: ref.read(ttsPitchPreferenceProvider),
        );

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.xs,
              AppSpace.md,
              AppSpace.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LessonIntroHeader(
                  overline: overline,
                  title: l10n.lessonIntroKeyPhrasesTitle,
                  titleIsContent: false,
                ),
                if (phrases.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.md),
                  _ListCard(
                    children: [
                      for (final phrase in phrases)
                        _PhraseRow(
                          phrase: phrase,
                          isNew: phrase.introducedIn == lessonId,
                          onListen: () => speak(phrase.text),
                        ),
                    ],
                  ),
                ],
                if (grammar.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.lg),
                  Row(
                    children: [
                      Icon(
                        Icons.schema_outlined,
                        size: 16,
                        color: tokens.textSecondary,
                      ),
                      const SizedBox(width: AppSpace.xs - 2),
                      Text(
                        l10n.lessonIntroGrammarTitle.toUpperCase(),
                        style: overlineStyle(
                          context,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xs),
                  _ListCard(
                    children: [
                      for (final item in grammar) _GrammarRow(item: item),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        LessonActionBar(label: continueLabel, onPressed: onContinue),
      ],
    );
  }
}

/// A card of rows split by hairlines.
class _ListCard extends StatelessWidget {
  const _ListCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: tokens.border),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _PhraseRow extends StatelessWidget {
  const _PhraseRow({
    required this.phrase,
    required this.isNew,
    required this.onListen,
  });

  final ChunkItem phrase;
  final bool isNew;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpace.md,
        AppSpace.sm,
        AppSpace.sm,
        AppSpace.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhraseText(
                  phrase.text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                PhraseText(
                  phrase.arabic,
                  textDirection: TextDirection.rtl,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isNew) ...[
            const SizedBox(width: AppSpace.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.xs,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: tokens.primaryInkTint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.lessonIntroNew.toUpperCase(),
                style: overlineStyle(context, color: tokens.primaryInk),
              ),
            ),
          ],
          const SizedBox(width: AppSpace.xxs),
          IconButton(
            onPressed: onListen,
            tooltip: l10n.speechListen,
            style: IconButton.styleFrom(
              side: BorderSide(color: tokens.border),
              foregroundColor: tokens.primaryInk,
            ),
            icon: const Icon(Icons.volume_up_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _GrammarRow extends StatelessWidget {
  const _GrammarRow({required this.item});

  final GrammarItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final formStyle = theme.textTheme.titleSmall?.copyWith(
      color: tokens.textPrimary,
    );
    final shortForm = item.shortForm;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // English grammar reads left-to-right in either interface
          // language, arrow included — while still starting at the
          // layout's start edge.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpace.xs,
                children: [
                  Text(item.form, style: formStyle),
                  if (shortForm != null) ...[
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: tokens.textSecondary,
                    ),
                    Text(shortForm, style: formStyle),
                  ],
                ],
              ),
            ),
          ),
          if (item.examples.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              item.examples.first.en,
              textDirection: TextDirection.ltr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
