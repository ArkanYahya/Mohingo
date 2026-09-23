import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/models/domain_definitions.dart';
import 'package:mohingo/features/activity_engine/domain/spoken_answer.dart';

SpeakActivity _speak({
  String prompt = 'Say something.',
  List<String> accepted = const [],
  Map<String, Object?> raw = const {},
}) => SpeakActivity(
  id: 'X',
  lessonId: null,
  mode: ActivityMode.mastery,
  skill: Skill.spokenProduction,
  canDo: const [],
  prompt: prompt,
  promptAr: null,
  raw: raw,
  accepted: accepted,
  fallbackSkill: 'writing',
);

void main() {
  group('phoneticKey', () {
    test("the recogniser's spellings of the course's names share a key with "
        'the names as written', () {
      const pairs = [
        ('Sara', 'Sarah'),
        ('Maya', 'Maia'),
        ('Omar', 'Umar'),
        ('Ali', 'Aly'),
        ('Anna', 'Ana'),
        ('Lina', 'Leena'),
        ('Noor', 'Nur'),
        ('Noor', 'Nour'),
        ('Huda', 'Hoda'),
        ('Daniel', 'Danial'),
        ('Karim', 'Kareem'),
        ('Munir', 'Muneer'),
        ('Nadia', 'Nadya'),
        ('Layla', 'Leila'),
        ('Rania', 'Ranya'),
        ('Iman', 'Eman'),
        ('Hisham', 'Hesham'),
        ('Sami', 'Samy'),
        ('Hana', 'Hannah'),
      ];
      for (final (a, b) in pairs) {
        expect(phoneticKey(a), phoneticKey(b), reason: '$a / $b');
      }
    });

    test('different names keep different keys', () {
      const pairs = [
        ('Sara', 'Maya'),
        ('Omar', 'Ali'),
        ('Anna', 'Lina'),
        ('Daniel', 'Sam'),
        ('he', 'she'),
        ('brother', 'mother'),
        ('sister', 'mister'),
      ];
      for (final (a, b) in pairs) {
        expect(phoneticKey(a), isNot(phoneticKey(b)), reason: '$a / $b');
      }
    });

    test('is coarse about vowels — which is why it is kept to names', () {
      expect(phoneticKey('bag'), phoneticKey('big'));
      expect(phoneticKey('this'), phoneticKey('these'));
    });

    test('ignores case and non-letters; an empty word has an empty key', () {
      expect(phoneticKey('SARA'), phoneticKey("sara's".replaceAll("'s", '')));
      expect(phoneticKey('S-A-R-A'), phoneticKey('sara'));
      expect(phoneticKey(''), '');
      expect(phoneticKey('123'), '');
    });
  });

  group('namesInTask', () {
    test('every word the task capitalises mid-sentence, across its texts', () {
      final names = namesInTask(
        _speak(
          prompt: "Say: Noor is Sami's daughter and Omar's sister.",
          accepted: const ["Noor is Sami's daughter and Omar's sister."],
          raw: const {
            'partnerTurns': ["Hello, I'm Anna. Ask me anything!"],
            'partnerSpeaker': 'Anna',
            'sourceCard': 'Bus 14 to Central Station.',
          },
        ),
      );
      expect(names, containsAll(['noor', 'sami', 'omar', 'anna', 'central']));
    });

    test('a word capitalised only because it starts a sentence is not a '
        'name, and neither is I', () {
      final names = namesInTask(
        _speak(
          prompt: "Introduce yourself. Say where I'm from. Ask Sara.",
          accepted: const ["Hi. I'm from Iraq."],
        ),
      );
      expect(names, {'sara', 'iraq'});
    });

    test("the possessive is stripped: Sara's names Sara", () {
      expect(namesInTask(_speak(prompt: "It belongs to Sara's brother.")), {
        'sara',
      });
    });
  });

  group('spokenWordsMatch', () {
    const spoken = SpokenAnswer(names: {'sara', 'omar'});

    test('the same word matches', () {
      expect(spokenWordsMatch('friend', 'friend', spoken), isTrue);
    });

    test("a name the recogniser spelled its own way counts as the task's "
        'name, possessive included', () {
      expect(spokenWordsMatch('sara', 'sarah', spoken), isTrue);
      expect(spokenWordsMatch("sara's", "sarah's", spoken), isTrue);
      expect(spokenWordsMatch('omar', 'umar', spoken), isTrue);
    });

    test("a name and its possessive are not the same word", () {
      expect(spokenWordsMatch("sara's", 'sarah', spoken), isFalse);
    });

    test('sound is never enough for an ordinary word', () {
      expect(spokenWordsMatch('bag', 'big', spoken), isFalse);
      expect(spokenWordsMatch('this', 'these', spoken), isFalse);
      // "maya" sounds like "maia", but this task never names Maya.
      expect(spokenWordsMatch('maya', 'maia', spoken), isFalse);
    });

    test('a homophone is the same word either way round', () {
      expect(spokenWordsMatch('two', 'to', spoken), isTrue);
      expect(spokenWordsMatch('for', 'four', spoken), isTrue);
      expect(spokenWordsMatch('their', 'there', spoken), isTrue);
      expect(spokenWordsMatch('know', 'no', spoken), isTrue);
    });
  });

  test('withNumbersAsWords writes a digit token as its spoken words', () {
    expect(withNumbersAsWords(['at', '7']), ['at', 'seven']);
    expect(withNumbersAsWords(["i'm", '25']), ["i'm", 'twenty', 'five']);
    expect(withNumbersAsWords(['bus', '14b']), ['bus', '14b']);
  });
}
