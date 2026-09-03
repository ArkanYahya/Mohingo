import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/exceptions.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';

String _readRealBundle() =>
    File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync();

void main() {
  group('CourseContentIndex against the real A1 bundle', () {
    late CourseContentIndex index;

    setUpAll(() {
      final bundle = CourseBundleParser.parse(_readRealBundle());
      index = CourseContentIndex.build(bundle);
    });

    test('indexes every unit by id, including U0 and U12', () {
      expect(index.unitsById, hasLength(13));
      expect(index.unitsById['A1-U0'], isNotNull);
      expect(index.unitsById['A1-U12'], isNotNull);
    });

    test('indexes every lesson by id and maps it back to its unit', () {
      expect(index.lessonsById, hasLength(89));
      expect(index.unitIdByLessonId['A1-U1-L1'], 'A1-U1');
    });

    test('indexes every training activity by id, findable by known id', () {
      expect(index.activitiesById['A1-U1-L1-A01'], isNotNull);
      expect(index.activitiesById['A1-FINAL-MISSION-A01'], isNotNull);
    });

    test('final-assessment items are indexed by id but excluded from the '
        'canDo reverse index (never surfaced as ordinary practice)', () {
      expect(index.activitiesById['A1-FINAL-ASSESS-L01'], isNotNull);
      final fromCanDoIndex = index.activitiesByCanDoId.values
          .expand((list) => list)
          .where((a) => a.id == 'A1-FINAL-ASSESS-L01');
      expect(fromCanDoIndex, isEmpty);
    });

    test('activitiesByCanDoId resolves a known Can-Do objective', () {
      final activities =
          index.activitiesByCanDoId['A1.U1.LISTENING.UNDERSTAND_PERSONAL_INFO'];
      expect(activities, isNotNull);
      expect(activities, isNotEmpty);
    });

    test('lessonExists is true for a real lesson, false for a bad id', () {
      expect(index.lessonExists('A1-U1', 'A1-U1-L1'), isTrue);
      expect(index.lessonExists('A1-U1', 'A1-U1-L999'), isFalse);
      expect(index.lessonExists('A1-U999', 'A1-U1-L1'), isFalse);
    });

    test('grammar/lexicon/chunk registries are fully indexed', () {
      expect(index.grammarById, hasLength(85));
      expect(index.lexiconById, hasLength(354));
      expect(index.chunkById, hasLength(143));
      // Two distinct senses of the same headword stay distinct records.
      expect(index.lexiconById['A1.LEX.PICTURE.N01'], isNotNull);
      expect(index.lexiconById['A1.LEX.PICTURE.N02'], isNotNull);
    });
  });

  group('CourseContentIndex unresolved-reference detection', () {
    test('throws when a lesson references an unknown Can-Do id', () {
      final json = _minimalBundleWithOneLesson(
        lessonCanDo: ['A1.NOT.A.REAL.OBJECTIVE'],
      );
      final bundle = CourseBundleParser.parse(jsonEncode(json));

      expect(
        () => CourseContentIndex.build(bundle),
        throwsA(isA<UnresolvedContentReferenceException>()),
      );
    });

    test('throws when a lesson references an unknown grammar id', () {
      final json = _minimalBundleWithOneLesson(
        lessonGrammar: ['A1.G.DOES.NOT.EXIST'],
      );
      final bundle = CourseBundleParser.parse(jsonEncode(json));

      expect(
        () => CourseContentIndex.build(bundle),
        throwsA(isA<UnresolvedContentReferenceException>()),
      );
    });

    test('a bundle with only resolvable references builds cleanly', () {
      final json = _minimalBundleWithOneLesson();
      final bundle = CourseBundleParser.parse(jsonEncode(json));

      expect(() => CourseContentIndex.build(bundle), returnsNormally);
    });
  });
}

/// A minimal-but-structurally-complete bundle with one unit/lesson, used to
/// exercise [CourseContentIndex]'s reference validation without depending on
/// the full real bundle.
Map<String, dynamic> _minimalBundleWithOneLesson({
  List<String> lessonCanDo = const ['A1.TEST.CANDO'],
  List<String> lessonGrammar = const [],
}) {
  return {
    'schemaVersion': '2.0.0',
    'contentVersion': 'TEST-1',
    'locale': {
      'targetLanguage': 'en',
      'supportLanguage': 'ar',
      'direction': {'target': 'ltr', 'support': 'rtl'},
    },
    'course': {
      'id': 'EN-TEST',
      'title': 'Test',
      'titleAr': 'اختبار',
      'status': 'test',
      'finalMissionId': 'TEST-FINAL-MISSION',
      'finalAssessmentId': 'TEST-FINAL-ASSESSMENT',
    },
    'domain': {
      'CAN_DO': {'TEST': 'A1.TEST.CANDO'},
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
    'grammar': [
      {
        'id': 'A1.G.TEST',
        'form': 'test',
        'meaningAr': 'اختبار',
        'introducedIn': 'A1-U1-L1',
        'examples': <Map<String, dynamic>>[],
      },
    ],
    'lexicon': <Map<String, dynamic>>[],
    'chunks': <Map<String, dynamic>>[],
    'units': [
      {
        'id': 'A1-U1',
        'title': 'Unit 1',
        'titleAr': 'الوحدة 1',
        'levelRole': 'core',
        'estimatedMinutes': [10, 20],
        'countsTowardA1Mastery': true,
        'lessons': [
          {
            'id': 'A1-U1-L1',
            'title': 'Lesson 1',
            'titleAr': 'الدرس 1',
            'lessonType': 'focus-practice',
            'canDo': lessonCanDo,
            'grammar': lessonGrammar,
            'lexicon': <String>[],
            'chunks': <String>[],
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
      'id': 'TEST-FINAL-MISSION',
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
      'id': 'TEST-FINAL-ASSESSMENT',
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
