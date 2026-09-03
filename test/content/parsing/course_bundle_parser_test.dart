import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/exceptions.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';

String _readRealBundle() =>
    File('assets/content/en/A1/a1-course-bundle.json').readAsStringSync();

void main() {
  group('CourseBundleParser against the real A1 bundle', () {
    test('parses successfully and reports expected top-level shape', () {
      final bundle = CourseBundleParser.parse(_readRealBundle());

      expect(bundle.schemaVersion, '2.0.0');
      expect(bundle.course.id, 'EN-A1-V2');
      expect(bundle.locale.targetLanguage, 'en');
      expect(bundle.locale.supportLanguage, 'ar');
      expect(bundle.units, hasLength(13));
      expect(bundle.grammar, hasLength(85));
      expect(bundle.lexicon, hasLength(354));
      expect(bundle.chunks, hasLength(143));
    });

    test('parses every declared activity type present in the real data', () {
      final bundle = CourseBundleParser.parse(_readRealBundle());
      final types = <String>{};
      for (final unit in bundle.units) {
        for (final lesson in unit.lessons) {
          for (final activity in lesson.activities) {
            types.add(activity.runtimeType.toString());
          }
        }
      }
      expect(
        types,
        containsAll(<String>{
          'AudioChoiceActivity',
          'TextChoiceActivity',
          'MatchActivity',
          'OrderActivity',
          'GapActivity',
          'FormActivity',
          'SpeakActivity',
          'WriteActivity',
        }),
      );
    });

    test('parses the Final Mission and Final Assessment', () {
      final bundle = CourseBundleParser.parse(_readRealBundle());
      expect(bundle.finalMission.id, 'A1-FINAL-MISSION');
      expect(bundle.finalMission.activities, hasLength(12));
      expect(bundle.finalAssessment.id, 'A1-FINAL-ASSESSMENT');
      expect(
        bundle.finalAssessment.fallbackDoesNotCreateSpeakingEvidence,
        isTrue,
      );
      expect(
        bundle.finalAssessment.requiredSkills,
        containsAll(<String>[
          'listening',
          'reading',
          'writing',
          'speaking',
          'mediation',
        ]),
      );
    });
  });

  group('CourseBundleParser schema/parse failure handling', () {
    Map<String, dynamic> validMinimalJson() => {
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
        'CAN_DO': <String, String>{},
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
      'grammar': <Map<String, dynamic>>[],
      'lexicon': <Map<String, dynamic>>[],
      'chunks': <Map<String, dynamic>>[],
      'units': <Map<String, dynamic>>[],
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

    test('rejects an unsupported schemaVersion without crashing', () {
      final json = validMinimalJson();
      json['schemaVersion'] = '99.0.0';

      expect(
        () => CourseBundleParser.parse(jsonEncode(json)),
        throwsA(isA<UnsupportedContentSchemaException>()),
      );
    });

    test('rejects malformed JSON as a ContentParseException, not a crash', () {
      expect(
        () => CourseBundleParser.parse('{ not valid json'),
        throwsA(isA<ContentParseException>()),
      );
    });

    test('a schema-valid, structurally-complete minimal bundle parses', () {
      final bundle = CourseBundleParser.parse(jsonEncode(validMinimalJson()));
      expect(bundle.course.id, 'EN-TEST');
      expect(bundle.units, isEmpty);
    });
  });
}
