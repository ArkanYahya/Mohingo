import '../../../content/catalog/content_level.dart';
import '../../../content/index/course_content_index.dart';
import '../../../content/models/registry_items.dart';

/// The content the Review tab renders against: **every** level the learner
/// has touched, held at once.
///
/// Review is deliberately the one tab that does not follow the learner's
/// current level. A learner who moves up to A2 has to keep meeting A1's
/// words in spaced review — that is the moment they need them most, since
/// A2 is built on them — which is why "separate courses per level" was
/// rejected outright in [ADR 0006](docs/adr/0006-multiple-levels.md), and
/// why the design gives Review "due words/phrases from every level; weak
/// spots across every level".
///
/// Every lookup resolves against the index of the level the item's own id
/// names ([levelIdOfContentId]) — the same rule `contentIndexForIdProvider`
/// applies for a screen that opens one item — never against "the current
/// level's" index, which would silently drop the other level's items.
///
/// A level that failed to load is simply absent here: its items are skipped
/// and every other level stays reviewable, rather than one missing bundle
/// taking down the whole tab.
class ReviewContent {
  const ReviewContent({
    required this.indexesByLevelId,
    required this.cefrCodesByLevelId,
  });

  static const empty = ReviewContent(
    indexesByLevelId: {},
    cefrCodesByLevelId: {},
  );

  /// The levels that loaded, keyed by catalogue level id (`"a1"`), in
  /// catalogue order.
  final Map<String, CourseContentIndex> indexesByLevelId;

  /// The CEFR code each loaded level is named by (`"a1"` → `"A1"`) — what
  /// labels a weak spot, so "Unit 3" is never ambiguous between two levels.
  final Map<String, String> cefrCodesByLevelId;

  /// The index [contentId] belongs to, or null when its level isn't loaded
  /// (or its id carries no level prefix at all).
  CourseContentIndex? indexFor(String contentId) {
    final levelId = levelIdOfContentId(contentId);
    return levelId == null ? null : indexesByLevelId[levelId];
  }

  /// The CEFR code of [contentId]'s level, or null — see [indexFor].
  String? cefrCodeFor(String contentId) {
    final levelId = levelIdOfContentId(contentId);
    return levelId == null ? null : cefrCodesByLevelId[levelId];
  }

  /// Each `*ById` map holds one level's own records, so these deliberately
  /// look in that level's index alone rather than through
  /// `resolveLexicon`/`resolveChunk`/`resolveGrammar`, which would also
  /// answer from a prerequisite and file an A1 word under A2.
  LexiconItem? lexicon(String id) => indexFor(id)?.lexiconById[id];

  /// See [lexicon].
  ChunkItem? chunk(String id) => indexFor(id)?.chunkById[id];

  /// See [lexicon].
  GrammarItem? grammar(String id) => indexFor(id)?.grammarById[id];

  /// Every word and phrase across every level the learner has reached —
  /// what the browse tile's "N of M in review" counts against, since the N
  /// beside it is their whole review schedule, which spans levels too.
  int get wordAndPhraseCount => indexesByLevelId.values.fold(
    0,
    (total, index) =>
        total + index.bundle.lexicon.length + index.bundle.chunks.length,
  );

  /// Every grammar form across every level the learner has reached.
  int get grammarCount => indexesByLevelId.values.fold(
    0,
    (total, index) => total + index.bundle.grammar.length,
  );
}
