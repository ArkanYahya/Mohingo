import 'package:flutter/material.dart';

import '../../../../content/models/curriculum_structure.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../speech/presentation/listen_button.dart';
import 'lesson_intro_chrome.dart';

/// A lesson-intro screen for a lesson built around a text — a message, a
/// menu, a profile — that its questions are about: the lesson title, then
/// the text's own title and the English (left-to-right) with a button to
/// hear it, and its Arabic behind a switch, on by default. Not read aloud
/// by itself: it's there to be read.
class LessonReadingStep extends StatefulWidget {
  const LessonReadingStep({
    required this.overline,
    required this.title,
    required this.titleAr,
    required this.reading,
    required this.continueLabel,
    required this.onContinue,
    super.key,
  });

  final String overline;

  /// The lesson's title, in English and Arabic.
  final String title;
  final String titleAr;
  final LessonReadingText reading;
  final String continueLabel;
  final VoidCallback onContinue;

  @override
  State<LessonReadingStep> createState() => _LessonReadingStepState();
}

class _LessonReadingStepState extends State<LessonReadingStep> {
  bool _showArabic = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final reading = widget.reading;
    final textAr = reading.textAr;

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
                  overline: widget.overline,
                  title: widget.title,
                  titleAr: widget.titleAr,
                ),
                const SizedBox(height: AppSpace.md),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.card,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: tokens.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpace.md,
                      AppSpace.xs,
                      AppSpace.xs,
                      AppSpace.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.lessonIntroReadTitle,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ),
                            ListenButton(text: reading.text),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            end: AppSpace.xs,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                reading.title,
                                textDirection: TextDirection.ltr,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: tokens.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpace.xs),
                              Text(
                                reading.text,
                                textDirection: TextDirection.ltr,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: tokens.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                              if (textAr != null && _showArabic) ...[
                                const SizedBox(height: AppSpace.sm),
                                Text(
                                  textAr,
                                  textDirection: TextDirection.rtl,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: tokens.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (textAr != null) ...[
                  const SizedBox(height: AppSpace.xs),
                  MergeSemantics(
                    child: InkWell(
                      onTap: () => setState(() => _showArabic = !_showArabic),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          AppSpace.md,
                          AppSpace.xxs,
                          AppSpace.sm,
                          AppSpace.xxs,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.lessonIntroArabicToggle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: tokens.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Switch(
                              value: _showArabic,
                              onChanged: (value) =>
                                  setState(() => _showArabic = value),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        LessonActionBar(
          label: widget.continueLabel,
          onPressed: widget.onContinue,
        ),
      ],
    );
  }
}
