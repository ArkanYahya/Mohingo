import '../../content/models/domain_definitions.dart';
import 'generated/app_localizations.dart';

/// The bilingual display label for one [Skill] — shared by the placement
/// test, final mission, and final assessment result screens, all of which
/// show a per-skill evidence breakdown. Kept in one place so the six skill
/// names are translated once, not per feature.
String skillLabel(AppLocalizations l10n, Skill skill) {
  return switch (skill) {
    Skill.listening => l10n.skillListening,
    Skill.reading => l10n.skillReading,
    Skill.writing => l10n.skillWriting,
    Skill.spokenInteraction => l10n.skillSpokenInteraction,
    Skill.spokenProduction => l10n.skillSpokenProduction,
    Skill.mediation => l10n.skillMediation,
  };
}

/// Same, but for a final-assessment section key (`"listening"`, `"reading"`,
/// `"writing"`, `"speaking"`, `"mediation"`) — the assessment merges
/// `spokenInteraction`/`spokenProduction` into one `"speaking"` bucket, so
/// this isn't quite the same lookup as [skillLabel].
String sectionLabel(AppLocalizations l10n, String sectionKey) {
  return switch (sectionKey) {
    'listening' => l10n.skillListening,
    'reading' => l10n.skillReading,
    'writing' => l10n.skillWriting,
    'speaking' => l10n.skillSpeaking,
    'mediation' => l10n.skillMediation,
    _ => sectionKey,
  };
}
