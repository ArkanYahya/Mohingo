import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/registry_items.dart';
import 'package:mohingo/features/lesson_player/presentation/widgets/lesson_key_phrases_step.dart';

import '../activity_engine/test_harness.dart';
import '../speech/fake_speech_services.dart';

void main() {
  testWidgets("an A2 lesson's own new phrase is NEW; phrases and grammar it "
      'reviews from A1 say so', (tester) async {
    await tester.pumpActivityView(
      LessonKeyPhrasesStep(
        overline: 'Unit 1 · Lesson 1',
        lessonId: 'A2-U1-L1',
        phrases: const [
          ChunkItem(
            id: 'A2.CHUNK.ON_WEEKDAYS',
            text: 'on weekdays',
            arabic: 'في أيام العمل',
            cefr: 'A2',
            introducedIn: 'A2-U1-L1',
            productive: true,
            recycledIn: [],
          ),
          ChunkItem(
            id: 'A1.CHUNK.GOOD_MORNING',
            text: 'Good morning.',
            arabic: 'صباح الخير.',
            cefr: 'A1',
            introducedIn: 'A1-U0-L1',
            productive: true,
            recycledIn: [],
          ),
        ],
        grammar: const [
          GrammarItem(
            id: 'A1.G.BE.I_AM',
            form: 'I am',
            shortForm: "I'm",
            meaningAr: 'أنا',
            introducedIn: 'A1-U1-L1',
            examples: [],
          ),
        ],
        continueLabel: 'Continue',
        onContinue: () {},
      ),
    );

    expect(find.text('NEW'), findsOneWidget);
    expect(find.text('FROM A1'), findsNWidgets(2));
  });

  testWidgets("an A1 lesson's own items never say From A1", (tester) async {
    await tester.pumpActivityView(
      LessonKeyPhrasesStep(
        overline: 'Unit 1 · Lesson 1',
        lessonId: 'A1-U1-L1',
        phrases: const [
          ChunkItem(
            id: 'A1.CHUNK.GOOD_MORNING',
            text: 'Good morning.',
            arabic: 'صباح الخير.',
            cefr: 'A1',
            introducedIn: 'A1-U0-L1',
            productive: true,
            recycledIn: [],
          ),
        ],
        grammar: const [],
        continueLabel: 'Continue',
        onContinue: () {},
      ),
    );

    expect(find.text('FROM A1'), findsNothing);
    expect(find.text('NEW'), findsNothing);
  });

  testWidgets('listening to a phrase asks for the raw phrase, slots and all, '
      'in the teacher voice', (tester) async {
    final tts = FakeTextToSpeechService();
    await tester.pumpActivityView(
      LessonKeyPhrasesStep(
        overline: 'Unit 1 · Lesson 1',
        lessonId: 'A1-U1-L1',
        phrases: const [
          ChunkItem(
            id: 'A1.CHUNK.MY_NAME_IS',
            text: 'My name is {name}.',
            arabic: 'اسمي {name}.',
            cefr: 'A1',
            introducedIn: 'A1-U1-L1',
            productive: true,
            recycledIn: [],
          ),
        ],
        grammar: const [],
        continueLabel: 'Continue',
        onContinue: () {},
      ),
      textToSpeechService: tts,
    );

    await tester.tap(find.byIcon(Icons.volume_up_rounded).first);
    await tester.pump();

    // The bundled clip is keyed by the bundle text; the device fallback
    // turns the slot into a pause itself.
    expect(tts.spoken, ['My name is {name}.']);
    expect(tts.speakers, [null]);
  });
}
