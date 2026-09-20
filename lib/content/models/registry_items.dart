/// One bilingual example sentence for a [GrammarItem].
class GrammarExample {
  const GrammarExample({required this.en, required this.ar});

  factory GrammarExample.fromJson(Map<String, dynamic> json) {
    return GrammarExample(en: json['en'] as String, ar: json['ar'] as String);
  }

  final String en;
  final String ar;
}

/// One grammar registry record (`grammar[]` in the bundle) — a single
/// grammatical structure with a stable id (e.g. `"A1.G.BE.I_AM"`). See
/// docs/DATA_MODEL.md.
class GrammarItem {
  const GrammarItem({
    required this.id,
    required this.form,
    this.shortForm,
    required this.meaningAr,
    required this.introducedIn,
    required this.examples,
  });

  factory GrammarItem.fromJson(Map<String, dynamic> json) {
    return GrammarItem(
      id: json['id'] as String,
      form: json['form'] as String,
      shortForm: json['shortForm'] as String?,
      meaningAr: json['meaningAr'] as String,
      introducedIn: json['introducedIn'] as String,
      // A couple of chunk-derived grammar records in the real bundle omit
      // `examples` entirely (verified this session) — default to empty
      // rather than crash on a legitimately sparse record.
      examples:
          (json['examples'] as List?)
              ?.map((e) => GrammarExample.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  final String id;
  final String form;
  final String? shortForm;
  final String meaningAr;
  final String introducedIn;
  final List<GrammarExample> examples;
}

/// One example sentence for a [LexiconItem]: English, and its Arabic when
/// the bundle gives one. A1's examples are English strings; A2's are
/// `{en, ar}` objects — both parse.
class LexiconExample {
  const LexiconExample({required this.en, this.ar});

  factory LexiconExample.fromJson(Object json) {
    if (json is String) return LexiconExample(en: json);
    final map = json as Map<String, dynamic>;
    final ar = map['ar'] as String?;
    return LexiconExample(
      en: map['en'] as String,
      ar: ar == null || ar.trim().isEmpty ? null : ar,
    );
  }

  final String en;
  final String? ar;
}

/// One lexicon registry record (`lexicon[]` in the bundle) — a single
/// lexical *sense*. Two records may share a [headword] while being distinct
/// senses (e.g. the bundle's `A1.LEX.PICTURE.N01`/`N02`) — always keyed and
/// compared by [id], never by spelling. See docs/DATA_MODEL.md.
class LexiconItem {
  const LexiconItem({
    required this.id,
    required this.headword,
    required this.partOfSpeech,
    required this.arabic,
    required this.cefr,
    required this.receptive,
    required this.productive,
    required this.meaning,
    required this.examples,
    required this.introducedIn,
    required this.recycledIn,
  });

  factory LexiconItem.fromJson(Map<String, dynamic> json) {
    return LexiconItem(
      id: json['id'] as String,
      headword: json['headword'] as String,
      partOfSpeech: json['partOfSpeech'] as String,
      arabic: json['arabic'] as String,
      cefr: json['cefr'] as String,
      receptive: json['receptive'] as bool,
      productive: json['productive'] as bool,
      meaning: json['meaning'] as String,
      examples: [
        for (final example in json['examples'] as List)
          LexiconExample.fromJson(example as Object),
      ],
      introducedIn: json['introducedIn'] as String,
      recycledIn: List<String>.from(json['recycledIn'] as List),
    );
  }

  final String id;
  final String headword;
  final String partOfSpeech;
  final String arabic;
  final String cefr;
  final bool receptive;
  final bool productive;
  final String meaning;
  final List<LexiconExample> examples;
  final String introducedIn;
  final List<String> recycledIn;
}

/// One chunk registry record (`chunks[]` in the bundle) — a fixed functional
/// phrase (e.g. `"A1.CHUNK.GOOD_MORNING"`). See docs/DATA_MODEL.md.
class ChunkItem {
  const ChunkItem({
    required this.id,
    required this.text,
    required this.arabic,
    required this.cefr,
    required this.introducedIn,
    required this.productive,
    required this.recycledIn,
  });

  factory ChunkItem.fromJson(Map<String, dynamic> json) {
    return ChunkItem(
      id: json['id'] as String,
      text: json['text'] as String,
      arabic: json['arabic'] as String,
      cefr: json['cefr'] as String,
      introducedIn: json['introducedIn'] as String,
      productive: json['productive'] as bool,
      recycledIn: List<String>.from(json['recycledIn'] as List),
    );
  }

  final String id;
  final String text;
  final String arabic;
  final String cefr;
  final String introducedIn;
  final bool productive;
  final List<String> recycledIn;
}
