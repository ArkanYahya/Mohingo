import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/curriculum_structure.dart';
import '../../../content/models/domain_definitions.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/overline_style.dart';
import '../../../core/widgets/content_text.dart';
import '../../../core/widgets/hairline_card.dart';
import '../../../core/widgets/lesson_reference_list.dart';
import '../../../core/widgets/section_heading.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';
import '../../review/domain/practice_set.dart';
import '../../speech/presentation/listen_button.dart';
import '../providers/grammar_providers.dart';

/// One grammar form's page: "GRAMMAR · UNIT 2", the form with audio, its
/// short form, the Arabic meaning, examples (English with audio over
/// Arabic), and the lessons that practise it. A star in the app bar saves
/// it; the bottom bar marks it reviewed or opens quick practice of one of
/// its lessons' practice activities (never counted as mastery — see
/// `QuickPracticeScreen`).
class GrammarDetailScreen extends ConsumerWidget {
  const GrammarDetailScreen({required this.grammarId, super.key});

  final String grammarId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(contentIndexForIdProvider(grammarId));

    return contentAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
      data: (index) {
        final theme = Theme.of(context);
        final tokens = theme.extension<AppTokens>()!;
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
        final unitId = index.unitIdByLessonId[item.introducedIn];
        final unitNumber =
            index.bundle.units.indexWhere((u) => u.id == unitId) + 1;

        final state = (ref.watch(allGrammarReviewStateProvider).value ?? [])
            .where((s) => s.grammarId == grammarId)
            .firstOrNull;
        final isFavorite = state?.isFavorite ?? false;
        final isReviewed = state?.markedReviewedAt != null;

        Future<void> setFavorite() async {
          final learner = await ref.read(currentLearnerProvider.future);
          await ref
              .read(reviewStateRepositoryProvider)
              .setGrammarFavorite(
                learnerId: learner.id,
                grammarId: grammarId,
                isFavorite: !isFavorite,
              );
          ref.invalidate(allGrammarReviewStateProvider);
        }

        Future<void> markReviewed() async {
          final learner = await ref.read(currentLearnerProvider.future);
          await ref
              .read(reviewStateRepositoryProvider)
              .markGrammarReviewed(learnerId: learner.id, grammarId: grammarId);
          ref.invalidate(allGrammarReviewStateProvider);
        }

        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                ),
                tooltip: isFavorite
                    ? l10n.favoriteRemoveTooltip
                    : l10n.favoriteAddTooltip,
                onPressed: setFavorite,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              0,
              AppSpace.md,
              AppSpace.lg,
            ),
            children: [
              Text(
                l10n.grammarOverline(unitNumber).toUpperCase(),
                style: overlineStyle(context, color: tokens.textSecondary),
              ),
              const SizedBox(height: AppSpace.xxs),
              Row(
                children: [
                  Expanded(
                    child: ContentText.en(
                      item.form,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ListenButton(text: item.form),
                ],
              ),
              if (item.shortForm != null)
                Text(
                  l10n.grammarShortForm(item.shortForm!),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
              const SizedBox(height: AppSpace.xs),
              ContentText.ar(
                item.meaningAr,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
              if (item.examples.isNotEmpty) ...[
                SectionHeading(l10n.wordDetailExamples),
                for (final example in item.examples) ...[
                  HairlineCard(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpace.md,
                      AppSpace.xs,
                      AppSpace.xxs,
                      AppSpace.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ContentText.en(
                                example.en,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: tokens.textPrimary,
                                ),
                              ),
                              ContentText.ar(
                                example.ar,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: tokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ListenButton(text: example.en),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                ],
              ],
              if (linkedLessons.isNotEmpty) ...[
                SectionHeading(l10n.grammarPractisedInOverline),
                LessonReferenceList(index: index, lessons: linkedLessons),
              ],
            ],
          ),
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.page,
              border: Border(top: BorderSide(color: tokens.border)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpace.md,
                AppSpace.sm,
                AppSpace.md,
                AppSpace.md + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (practiceActivities.isEmpty) ...[
                    Text(
                      l10n.grammarNoLinkedPractice,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                  ],
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: practiceActivities.isEmpty
                        ? null
                        : () => context.push(
                            '/review/practice',
                            extra: practiceSetForGrammar(index, grammarId),
                          ),
                    child: Text(l10n.grammarQuickPractice),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: isReviewed ? null : markReviewed,
                    icon: Icon(
                      isReviewed
                          ? Icons.check_circle_rounded
                          : Icons.check_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isReviewed
                          ? l10n.grammarReviewed
                          : l10n.grammarMarkReviewed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
