/// Every unit, lesson, activity and registry id in a curriculum bundle
/// starts with its CEFR level: `A1-U3-L2-A01`, `A1.LEX.PICTURE.N01`,
/// `A2.G.BE_PAST`, `A1-FINAL-MISSION-A01`.
final _levelPrefix = RegExp(r'^([A-Za-z][0-9])[-.]');

/// The catalogue level id (`"a1"`) that [contentId] belongs to, read from
/// its prefix — or null when it has none.
///
/// The prefix is what keeps ids unique across levels, and what lets a
/// screen that opens one unit, lesson, word, phrase or grammar point find
/// the right level's content without being told the level. See
/// `contentIndexForIdProvider`.
String? levelIdOfContentId(String contentId) =>
    _levelPrefix.firstMatch(contentId)?.group(1)!.toLowerCase();
