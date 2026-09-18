import 'generated/app_localizations.dart';

/// The learner-facing name of a lesson's `lessonType` ("Guided lesson",
/// "Mission"…), or null for a type with no label yet — shared by Home's
/// continue-lesson card and the lesson-complete "Up next" card.
String? lessonTypeLabel(AppLocalizations l10n, String lessonType) {
  return switch (lessonType) {
    'encounter-focus-practice' => l10n.homeLessonTypeGuided,
    'focus-practice' => l10n.homeLessonTypePractice,
    'communication' => l10n.homeLessonTypeConversation,
    'mission' => l10n.homeLessonTypeMission,
    _ => null,
  };
}
