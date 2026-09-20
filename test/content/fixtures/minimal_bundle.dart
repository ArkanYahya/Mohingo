/// A minimal-but-structurally-complete bundle for [level] (`"A1"`,
/// `"A2"`) with one unit and one lesson, for tests of loading, indexing and
/// reference resolution that shouldn't depend on a real bundle. Every id
/// carries the level prefix, as real bundles do.
Map<String, dynamic> minimalBundleJson({
  String level = 'A1',
  List<Map<String, dynamic>> grammar = const [],
  List<Map<String, dynamic>> lexicon = const [],
  List<Map<String, dynamic>> chunks = const [],
  List<String> lessonGrammar = const [],
  List<String> lessonLexicon = const [],
  List<String> lessonChunks = const [],
}) {
  final canDo = '$level.TEST.CANDO';
  return {
    'schemaVersion': '2.0.0',
    'contentVersion': '$level-TEST-1',
    'locale': {
      'targetLanguage': 'en',
      'supportLanguage': 'ar',
      'direction': {'target': 'ltr', 'support': 'rtl'},
    },
    'course': {
      'id': 'EN-$level-TEST',
      'title': 'Test $level',
      'titleAr': 'اختبار $level',
      'status': 'test',
      'finalMissionId': '$level-FINAL-MISSION',
      'finalAssessmentId': '$level-FINAL-ASSESSMENT',
    },
    'domain': {
      'CAN_DO': {'TEST': canDo},
      'MASTERY_POLICY': {
        'minimumObjectiveScore': 0.75,
        'minimumEvidencePerRequiredObjective': 2,
        'requireProductiveEvidenceWhereDeclared': true,
        'practiceCountsAsMastery': false,
        'allowSpeechFallbackToWriting': true,
        'speechCriteria': <String>[],
        'speechAccuracyWeight': 0.2,
      },
    },
    'grammar': grammar,
    'lexicon': lexicon,
    'chunks': chunks,
    'units': [
      {
        'id': '$level-U1',
        'title': 'Unit 1',
        'titleAr': 'الوحدة 1',
        'levelRole': 'core',
        'estimatedMinutes': [10, 20],
        'countsToward${level}Mastery': true,
        'lessons': [
          {
            'id': '$level-U1-L1',
            'title': 'Lesson 1',
            'titleAr': 'الدرس 1',
            'lessonType': 'encounter-focus-practice',
            'canDo': [canDo],
            'grammar': lessonGrammar,
            'lexicon': lessonLexicon,
            'chunks': lessonChunks,
            'activities': <Map<String, dynamic>>[],
          },
        ],
        'mastery': {
          'requiredObjectives': <String>[],
          'requiredSkillGroups': <List<String>>[],
          'minimumObjectiveScore': 0.75,
        },
      },
    ],
    'mediaSpecifications': <String, dynamic>{},
    'finalMission': {
      'id': '$level-FINAL-MISSION',
      'title': 'Mission',
      'titleAr': 'مهمة',
      'scenario': 'x',
      'canDo': <String>[],
      'stages': <Map<String, dynamic>>[],
      'activities': <Map<String, dynamic>>[],
      'scoring': {
        'requiredSkillGroups': <List<String>>[],
        'minimumCriterionScore': 0.6,
        'noSingleAverageCompensation': true,
      },
    },
    'finalAssessment': {
      'id': '$level-FINAL-ASSESSMENT',
      'title': 'Assessment',
      'titleAr': 'اختبار',
      'sourcePolicy': 'unseen',
      'sections': <String, dynamic>{},
      'scoring': {
        'decisionRule': {
          'required': <String>[],
          'noSingleOverallAverage': true,
        },
        'accessibility': {'fallbackDoesNotCreateSpeakingEvidence': true},
      },
    },
  };
}

Map<String, dynamic> grammarRecord(String id) => {
  'id': id,
  'form': 'form of $id',
  'meaningAr': 'معنى',
  'introducedIn': 'lesson',
  'examples': <Map<String, dynamic>>[],
};

Map<String, dynamic> lexiconRecord(String id) => {
  'id': id,
  'headword': 'word of $id',
  'partOfSpeech': 'noun',
  'arabic': 'كلمة',
  'cefr': 'A1',
  'receptive': true,
  'productive': true,
  'meaning': 'word',
  'examples': <Object>[],
  'introducedIn': 'lesson',
  'recycledIn': <String>[],
};

Map<String, dynamic> chunkRecord(String id) => {
  'id': id,
  'text': 'phrase of $id',
  'arabic': 'عبارة',
  'cefr': 'A1',
  'introducedIn': 'lesson',
  'productive': true,
  'recycledIn': <String>[],
};
