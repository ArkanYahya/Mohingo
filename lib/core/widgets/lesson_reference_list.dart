import 'package:flutter/material.dart';

import '../../content/index/course_content_index.dart';
import '../../content/models/curriculum_structure.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_tokens.dart';
import './content_text.dart';
import 'hairline_card.dart';

/// One hairline card listing [lessons] — each its English title, Arabic,
/// and "Unit 2 · Lesson 1" — separated by dividers. Used where a word,
/// phrase or grammar form points back to the lessons that teach it. With
/// [onTap] each row opens its lesson and shows a chevron.
class LessonReferenceList extends StatelessWidget {
  const LessonReferenceList({
    required this.index,
    required this.lessons,
    this.onTap,
    super.key,
  });

  final CourseContentIndex index;
  final List<Lesson> lessons;
  final ValueChanged<Lesson>? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;

    Widget row(Lesson lesson) {
      final unit = index.unitsById[index.unitIdByLessonId[lesson.id]];
      final unitNumber = unit == null
          ? 0
          : index.bundle.units.indexOf(unit) + 1;
      final lessonNumber = unit == null ? 0 : unit.lessons.indexOf(lesson) + 1;
      final content = Padding(
        padding: const EdgeInsets.all(AppSpace.md - 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ContentText.en(
              lesson.title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            ContentText.ar(
              lesson.titleAr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
            Text(
              l10n.wordMetInMeta(unitNumber, lessonNumber),
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
          ],
        ),
      );
      final onTap = this.onTap;
      if (onTap == null) return content;
      return InkWell(
        onTap: () => onTap(lesson),
        child: Row(
          children: [
            Expanded(child: content),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpace.sm),
              child: Icon(
                Icons.chevron_right_rounded,
                color: tokens.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return HairlineCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, lesson) in lessons.indexed) ...[
            if (i > 0) Divider(height: 1, color: tokens.border),
            row(lesson),
          ],
        ],
      ),
    );
  }
}
