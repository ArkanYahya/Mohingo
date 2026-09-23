import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/evaluation_spec.dart';

void main() {
  group('WriteActivity.evaluation', () {
    test('WriteActivity parses a structured evaluation spec', () {
      final activity = Activity.fromJson({
        'id': 'A1-TEST-A01',
        'lessonId': 'A1-TEST-L1',
        'type': 'write',
        'mode': 'mastery',
        'skill': 'writing',
        'canDo': <String>[],
        'prompt': 'Write your name.',
        'accepted': <String>[],
        'evaluation': {'type': 'nonEmpty'},
      }) as WriteActivity;

      expect(activity.evaluation, isA<NonEmptyEvaluationSpec>());
    });

    test('WriteActivity with a not-yet-migrated legacy evaluation string '
        'parses evaluation as null, not a crash', () {
      final activity = Activity.fromJson({
        'id': 'A1-TEST-A02',
        'lessonId': 'A1-TEST-L1',
        'type': 'write',
        'mode': 'mastery',
        'skill': 'writing',
        'canDo': <String>[],
        'prompt': 'Write a message.',
        'accepted': <String>[],
        'evaluation': 'some-legacy-rubric-name',
      }) as WriteActivity;

      expect(activity.evaluation, isNull);
    });
  });

  group('material shown with a task', () {
    Map<String, dynamic> speak(Map<String, dynamic> extra) => {
      'id': 'A1-FINAL-ASSESS-S02',
      'type': 'speak',
      'mode': 'mastery',
      'skill': 'spokenInteraction',
      'canDo': <String>[],
      'prompt': 'Respond to four short examiner turns.',
      ...extra,
    };

    test('any activity may carry a source card', () {
      final activity = Activity.fromJson(
        speak({'sourceCard': 'Bus 14 — 08:00 to Central.'}),
      );
      expect(activity.sourceCard, 'Bus 14 — 08:00 to Central.');
      expect(Activity.fromJson(speak({})).sourceCard, isNull);
      expect(Activity.fromJson(speak({'sourceCard': '  '})).sourceCard, isNull);
    });

    test('a blank sourceText parses as null, not an empty source card that '
        'would also shadow a real sourceCard', () {
      final activity = Activity.fromJson({
        'id': 'A2-TEST-A03',
        'type': 'textChoice',
        'mode': 'practice',
        'skill': 'reading',
        'canDo': <String>[],
        'prompt': 'Choose the correct answer.',
        'options': ['a', 'b'],
        'answer': 'a',
        'sourceText': '',
      }) as TextChoiceActivity;
      expect(activity.sourceText, isNull);
    });

    test("a speaking task's partner lines come from partnerTurns or A1's "
        'examinerTurns', () {
      final partner = Activity.fromJson(
        speak({
          'partnerTurns': ['Hi! How are you?', 'What do you do?'],
        }),
      ) as SpeakActivity;
      expect(partner.partnerTurns, ['Hi! How are you?', 'What do you do?']);

      final examiner = Activity.fromJson(
        speak({
          'examinerTurns': ['Good morning.'],
        }),
      ) as SpeakActivity;
      expect(examiner.partnerTurns, ['Good morning.']);

      expect(
        (Activity.fromJson(speak({})) as SpeakActivity).partnerTurns,
        isEmpty,
      );
    });

    test("a speaking task's partner is whoever partnerSpeaker names — the "
        'voice its lines are read in — or nobody in particular', () {
      final anna = Activity.fromJson(
        speak({
          'partnerTurns': ["Hello. I'm Anna."],
          'partnerSpeaker': 'Anna',
        }),
      ) as SpeakActivity;
      expect(anna.partnerSpeaker, 'Anna');

      expect(
        (Activity.fromJson(
          speak({'partnerSpeaker': '  '}),
        ) as SpeakActivity).partnerSpeaker,
        isNull,
      );
      expect(
        (Activity.fromJson(speak({})) as SpeakActivity).partnerSpeaker,
        isNull,
      );
    });
  });
}
