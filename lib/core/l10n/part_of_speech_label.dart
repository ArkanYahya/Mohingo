import 'generated/app_localizations.dart';

/// A lexicon entry's `partOfSpeech` in the interface language; an unknown
/// value falls back to the bundle's own English.
String partOfSpeechLabel(AppLocalizations l10n, String partOfSpeech) {
  return switch (partOfSpeech) {
    'noun' => l10n.partOfSpeechNoun,
    'verb' => l10n.partOfSpeechVerb,
    'adjective' => l10n.partOfSpeechAdjective,
    'adverb' => l10n.partOfSpeechAdverb,
    'number' => l10n.partOfSpeechNumber,
    'properNoun' => l10n.partOfSpeechProperNoun,
    'phrase' => l10n.partOfSpeechPhrase,
    'interjection' => l10n.partOfSpeechInterjection,
    'preposition' => l10n.partOfSpeechPreposition,
    'conjunction' => l10n.partOfSpeechConjunction,
    _ => partOfSpeech,
  };
}
