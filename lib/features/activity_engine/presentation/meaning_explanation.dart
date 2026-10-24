import 'dart:ui' show Locale;

import '../../../content/models/evaluation_spec.dart';
import '../../../core/l10n/generated/app_localizations.dart';

/// The templated explanation of a free answer that left part of the task
/// out (ADR 0014): the missing parts' names, in the content's own words,
/// inside one sentence of app copy per language. Both languages are built
/// at once and stored with the attempt, so the answer review shows the same
/// text later whatever the interface language then is.
///
/// Written by people: the sentence is in the ARB files, the names in the
/// bundle. Nothing here is generated, which is why the panel no longer
/// labels it so.
({String en, String ar})? missingPartsExplanation(List<GroupMeaning> missing) {
  if (missing.isEmpty) return null;
  final en = lookupAppLocalizations(const Locale('en'));
  final ar = lookupAppLocalizations(const Locale('ar'));
  return (
    en: en.activityFeedbackMissingParts(
      missing.map((m) => m.labelEn).join(', '),
    ),
    ar: ar.activityFeedbackMissingParts(
      missing.map((m) => m.labelAr).join('، '),
    ),
  );
}
