import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/curriculum_structure.dart';
import 'package:mohingo/features/lesson_player/presentation/widgets/lesson_conversation_step.dart';

import '../activity_engine/test_harness.dart';
import '../speech/fake_speech_services.dart';

/// A text-to-speech fake whose every line lasts until the test says it has
/// finished — the real service completes `speak` when the clip ends, so
/// the conversation step is mid-line for as long as the clip plays.
class _GatedTts extends FakeTextToSpeechService {
  final _gates = <Completer<void>>[];

  /// Lets the line being spoken finish, so the next one starts.
  void finishLine() => _gates.removeAt(0).complete();

  @override
  Future<void> speak(
    String text, {
    required String localeCode,
    double? rate,
    double? pitch,
    String? voiceName,
    String? speaker,
  }) async {
    await super.speak(
      text,
      localeCode: localeCode,
      rate: rate,
      pitch: pitch,
      voiceName: voiceName,
      speaker: speaker,
    );
    final gate = Completer<void>();
    _gates.add(gate);
    await gate.future;
  }

  @override
  Future<void> stop() async {
    await super.stop();
    for (final gate in _gates) {
      if (!gate.isCompleted) gate.complete();
    }
    _gates.clear();
  }
}

/// Twelve lines: far more than a phone-height screen shows at once.
final _lines = [
  for (var i = 0; i < 12; i++)
    EncounterDialogueLine(
      speaker: i.isEven ? 'Maya' : 'Omar',
      en: 'Line number $i of a conversation that is long enough to scroll.',
      ar: 'السطر رقم $i من محادثة طويلة بما يكفي لتتطلب التمرير.',
    ),
];

Future<_GatedTts> _pump(WidgetTester tester, {double height = 560}) async {
  tester.view.physicalSize = Size(400, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final tts = _GatedTts();
  await tester.pumpActivityView(
    LessonConversationStep(
      overline: 'Unit 1 · Lesson 1',
      title: 'My Name',
      titleAr: 'اسمي',
      lines: _lines,
      continueLabel: 'Continue',
      onContinue: () {},
    ),
    textToSpeechService: tts,
  );
  await tester.pump();
  return tts;
}

Rect _viewport(WidgetTester tester) =>
    tester.getRect(find.byType(SingleChildScrollView));

Rect _bubble(WidgetTester tester, int index) =>
    tester.getRect(find.text(_lines[index].en));

double _offset(WidgetTester tester) => tester
    .state<ScrollableState>(find.byType(Scrollable).first)
    .position
    .pixels;

void main() {
  testWidgets('the screen scrolls to keep the line being read in view, so '
      'a line below the fold is on screen by the time it is spoken', (
    tester,
  ) async {
    final tts = await _pump(tester);
    expect(_offset(tester), 0);
    final viewport = _viewport(tester);
    // Sanity: the conversation really does run past the screen.
    expect(
      _bubble(tester, _lines.length - 1).bottom,
      greaterThan(viewport.bottom),
    );

    for (var i = 0; i < _lines.length - 1; i++) {
      tts.finishLine();
      await tester.pumpAndSettle();
      final bubble = _bubble(tester, i + 1);
      expect(
        bubble.top >= viewport.top && bubble.bottom <= viewport.bottom,
        isTrue,
        reason:
            'line ${i + 1} is being read but sits at $bubble, outside '
            'the visible $viewport',
      );
    }
    expect(_offset(tester), greaterThan(0));
    expect(tts.spoken.length, _lines.length);
  });

  testWidgets('a line above the fold — the learner dragged past it — is '
      'brought back on screen when it is read', (tester) async {
    final tts = await _pump(tester);
    for (var i = 0; i < 3; i++) {
      tts.finishLine();
      await tester.pumpAndSettle();
    }
    // Line 3 is being read; the learner drags to the very bottom.
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();
    final dragged = _offset(tester);
    expect(_bubble(tester, 4).top, lessThan(_viewport(tester).top));

    tts.finishLine(); // line 4 starts
    await tester.pumpAndSettle();

    final viewport = _viewport(tester);
    final bubble = _bubble(tester, 4);
    expect(bubble.top, greaterThanOrEqualTo(viewport.top));
    expect(bubble.bottom, lessThanOrEqualTo(viewport.bottom));
    expect(_offset(tester), lessThan(dragged));
  });

  testWidgets('a line that is already on screen does not move the page', (
    tester,
  ) async {
    // Tall enough that the first lines fit under the header and the card.
    final tts = await _pump(tester, height: 900);
    final viewport = _viewport(tester);
    expect(_bubble(tester, 1).bottom, lessThan(viewport.bottom));

    tts.finishLine(); // line 1 starts
    await tester.pumpAndSettle();

    expect(_offset(tester), 0);
  });
}
