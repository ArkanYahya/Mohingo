import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/audio/speakable_strings.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/features/speech/domain/audio_clip_index.dart';

import '../fixtures/minimal_bundle.dart';

Map<String, dynamic> _activity(
  String type,
  String id, {
  String skill = 'listening',
  Map<String, dynamic> extra = const {},
}) => {
  'type': type,
  'id': id,
  'mode': 'practice',
  'skill': skill,
  'canDo': <String>[],
  'prompt': 'Prompt $id',
  'options': ['a', 'b'],
  'answer': 'a',
  ...extra,
};

void main() {
  test('lists every spoken string with the role the app asks for', () {
    final json = minimalBundleJson(
      chunks: [
        {...chunkRecord('A1.CHUNK.X'), 'text': 'My name is {name}.'},
      ],
      lexicon: [
        {
          ...lexiconRecord('A1.LEX.X'),
          'headword': 'name',
          'examples': [
            'My name is Omar.',
            {'en': 'Name?', 'ar': ''},
          ],
        },
      ],
      grammar: [
        {
          ...grammarRecord('A1.G.X'),
          'form': 'I am',
          'examples': [
            {'en': "I'm Omar.", 'ar': ''},
          ],
        },
      ],
    );
    final lesson =
        (json['units'] as List).first['lessons'].first as Map<String, dynamic>;
    lesson['encounter'] = {
      'sceneAr': '',
      'dialogue': [
        {'speaker': 'Maya', 'en': 'Hi.', 'ar': ''},
        {'speaker': 'Omar', 'en': '  ', 'ar': ''},
      ],
    };
    lesson['readingText'] = {'title': 't', 'text': 'A text.'};
    lesson['activities'] = [
      _activity('audioChoice', 'A1', extra: {'audioTranscript': 'Listen.'}),
      _activity('audioChoice', 'A2', extra: {'audioTranscript': ''}),
      _activity(
        'speak',
        'A3',
        skill: 'spokenInteraction',
        extra: {
          'partnerTurns': ['Turn one.', ''],
        },
      ),
      _activity(
        'speak',
        'A4',
        skill: 'spokenInteraction',
        extra: {
          'examinerTurns': ['Old turn.'],
        },
      ),
      _activity('textChoice', 'A5', skill: 'reading'),
      _activity(
        'speak',
        'A6',
        skill: 'spokenInteraction',
        extra: {
          'partnerTurns': ['Named turn.'],
          'partnerSpeaker': 'Anna',
        },
      ),
    ];
    (json['finalMission'] as Map<String, dynamic>)['activities'] = [
      _activity('audioChoice', 'M1', extra: {'audioTranscript': 'Mission.'}),
    ];
    (json['finalAssessment'] as Map<String, dynamic>)['sections'] = {
      'speaking': {
        'activities': [
          _activity(
            'speak',
            'S1',
            skill: 'spokenInteraction',
            extra: {
              'partnerTurns': ['Assess.'],
            },
          ),
        ],
      },
    };

    final bundle = CourseBundleParser.parse(jsonEncode(json));
    final got = {for (final s in speakableStringsOf(bundle)) (s.text, s.role)};

    expect(got, {
      ('Hi.', 'Maya'),
      ('A text.', kTeacherRole),
      ('Listen.', kTeacherRole),
      ('Turn one.', kPartnerSpeaker),
      ('Old turn.', kPartnerSpeaker),
      ('Named turn.', 'Anna'),
      ('Mission.', kTeacherRole),
      ('Assess.', kPartnerSpeaker),
      ('My name is {name}.', kTeacherRole),
      ('name', kTeacherRole),
      ('My name is Omar.', kTeacherRole),
      ('Name?', kTeacherRole),
      ('I am', kTeacherRole),
      ("I'm Omar.", kTeacherRole),
    });
  });

  test('the shipped bundles produce the census counts', () {
    // Pinned from the 2026-09-22 census; tool/audio/tests/test_speakables.py
    // pins the same numbers from the tool's side. A change here without a
    // matching change there means the app and the tool disagree about what
    // is spoken.
    int distinct(String path) {
      final bundle = CourseBundleParser.parse(File(path).readAsStringSync());
      return {
        for (final s in speakableStringsOf(bundle))
          (textKeyFor(s.text), s.role),
      }.length;
    }

    expect(distinct('assets/content/en/A1/a1-course-bundle.json'), 1576);
    expect(distinct('assets/content/en/A2/a2-course-bundle.json'), 1624);
  });
}
