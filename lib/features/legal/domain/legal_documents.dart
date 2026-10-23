/// The version of the privacy policy and terms of use a learner accepts on
/// first launch.
///
/// Raise it only when the documents change in a way that matters — what is
/// collected, who receives it, or what the learner agrees to — and edit the
/// "Agreement version" line at the top of all four documents to match.
/// Every learner whose accepted version is lower sees the agreement screen
/// again, with a note that the documents changed, before they continue.
/// Typo fixes and rewording keep the same version. It is independent of the
/// app version: most releases change neither document.
const kAgreementVersion = 1;

/// A document the learner can read in the app. The text lives in
/// `assets/legal/`, one Markdown file per language, so it can be reviewed
/// or replaced without touching app code; `SimpleMarkdown` renders it.
enum LegalDocument {
  privacy('privacy'),
  terms('terms');

  const LegalDocument(this.slug);

  /// The route segment (`/legal/<slug>`) and file-name stem.
  final String slug;

  /// Arabic and English copies exist; any other language reads English.
  String assetPath(String languageCode) =>
      'assets/legal/${slug}_${languageCode == 'ar' ? 'ar' : 'en'}.md';

  static LegalDocument? fromSlug(String slug) {
    for (final document in values) {
      if (document.slug == slug) return document;
    }
    return null;
  }
}
