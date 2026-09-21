import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/index/course_content_index.dart';
import '../../../content/models/registry_items.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/gamification_theme_extension.dart';
import '../../../core/theme/overline_style.dart';
import '../../../core/widgets/level_filter_chips.dart';
import '../../../core/widgets/search_field.dart';
import '../../progress/providers/level_providers.dart';
import '../providers/grammar_providers.dart';

/// Browses one level's grammar registry, grouped by the unit that
/// introduces each form ("UNIT 2 · HELLO, I'M…") — the closest structure to
/// "topic" in the real data — and searchable by form or Arabic meaning.
/// Units with no match drop out. See docs/ARCHITECTURE.md.
///
/// The level is the one the learner is in ([currentLevelIdProvider]), with
/// a [LevelFilterChips] row for looking back at an earlier level's forms —
/// A2's lessons keep using A1's. Picking a level here only changes what the
/// list shows; it never moves the learner between levels. The units and
/// their lesson ids always come from the same index as the grammar records
/// being grouped, so a form is never filed under another level's unit
/// numbering.
class GrammarListScreen extends ConsumerStatefulWidget {
  const GrammarListScreen({super.key});

  @override
  ConsumerState<GrammarListScreen> createState() => _GrammarListScreenState();
}

class _GrammarListScreenState extends ConsumerState<GrammarListScreen> {
  final _searchController = TextEditingController();

  /// A level the learner has filtered to. Null until they pick one, when
  /// the list follows the level they are actually in.
  String? _levelId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final catalog = ref.watch(levelCatalogProvider);
    final currentLevelIdAsync = ref.watch(currentLevelIdProvider);
    final shownLevelId = _levelId ?? currentLevelIdAsync.value;
    final AsyncValue<CourseContentIndex> contentAsync;
    if (currentLevelIdAsync.hasError) {
      contentAsync = AsyncValue.error(
        currentLevelIdAsync.error!,
        currentLevelIdAsync.stackTrace!,
      );
    } else if (shownLevelId != null) {
      contentAsync = ref.watch(courseContentProvider(shownLevelId));
    } else {
      contentAsync = const AsyncValue.loading();
    }
    final saved = {
      for (final s in ref.watch(allGrammarReviewStateProvider).value ?? [])
        if (s.isFavorite) s.grammarId,
    };

    // The level row sits outside the content's loading/error branch: a
    // level whose bundle fails to load must not strand the learner on an
    // error page with no way back to their own level.
    final levelFilter = shownLevelId == null
        ? const SizedBox.shrink()
        : LevelFilterChips(
            catalog: catalog,
            selectedLevelId: shownLevelId,
            onSelect: (levelId) => setState(() => _levelId = levelId),
          );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.grammarSectionTitle)),
      body: contentAsync.when(
        loading: () => Column(
          children: [
            levelFilter,
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
        error: (error, _) => Column(
          children: [
            levelFilter,
            Expanded(child: Center(child: Text('$error'))),
          ],
        ),
        data: (index) {
          final query = _searchController.text.trim().toLowerCase();
          bool matches(GrammarItem g) =>
              query.isEmpty ||
              g.form.toLowerCase().contains(query) ||
              g.meaningAr.contains(query);

          final sections = <Widget>[];
          for (final (u, unit) in index.bundle.units.indexed) {
            final lessonIds = {for (final l in unit.lessons) l.id};
            final items = index.bundle.grammar
                .where((g) => lessonIds.contains(g.introducedIn))
                .where(matches)
                .toList();
            if (items.isEmpty) continue;
            sections.add(
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpace.md,
                  bottom: AppSpace.xs,
                ),
                child: Text(
                  '${l10n.learnUnitOverline(u + 1)} · '
                          '\u2068${unit.title}\u2069'
                      .toUpperCase(),
                  style: overlineStyle(context, color: tokens.textSecondary),
                ),
              ),
            );
            sections.add(
              Material(
                color: tokens.card,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Column(
                  children: [
                    for (final (i, item) in items.indexed) ...[
                      if (i > 0) Divider(height: 1, color: tokens.border),
                      _GrammarRow(item: item, saved: saved.contains(item.id)),
                    ],
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              levelFilter,
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.md,
                  AppSpace.xxs,
                  AppSpace.md,
                  AppSpace.xs,
                ),
                child: SearchField(
                  controller: _searchController,
                  hintText: l10n.vocabularySearchHint,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: sections.isEmpty
                    ? Center(child: Text(l10n.grammarEmptyResults))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpace.md,
                          0,
                          AppSpace.md,
                          AppSpace.lg,
                        ),
                        children: sections,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A form (LTR) over its Arabic meaning, a star when saved, a chevron.
class _GrammarRow extends StatelessWidget {
  const _GrammarRow({required this.item, required this.saved});

  final GrammarItem item;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () => context.push('/review/grammar/${item.id}'),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpace.md - 2,
          AppSpace.sm - 2,
          AppSpace.xs,
          AppSpace.sm - 2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      item.form,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      item.meaningAr,
                      textDirection: TextDirection.rtl,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (saved)
              Icon(
                Icons.star_rounded,
                size: 18,
                semanticLabel: l10n.vocabularyFilterSaved,
                color: theme.extension<GamificationTheme>()!.streakAccent,
              ),
            Icon(Icons.chevron_right_rounded, color: tokens.textSecondary),
          ],
        ),
      ),
    );
  }
}
