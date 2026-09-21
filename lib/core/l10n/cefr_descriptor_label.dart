import 'generated/app_localizations.dart';

/// The plain-language name of a CEFR level ("Beginner", "Elementary"), or
/// null for a level that has no descriptor yet — callers show the bare code
/// then, rather than calling an A2 learner a beginner.
///
/// Levels are matched case-insensitively on the catalogue's CEFR code, so
/// both `"a2"` and `"A2"` resolve.
String? cefrDescriptorLabel(AppLocalizations l10n, String cefrCode) {
  return switch (cefrCode.toUpperCase()) {
    'A1' => l10n.cefrDescriptorA1,
    'A2' => l10n.cefrDescriptorA2,
    _ => null,
  };
}
