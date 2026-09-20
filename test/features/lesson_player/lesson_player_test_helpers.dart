import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/lesson_player/presentation/widgets/lesson_conversation_step.dart';
import 'package:mohingo/features/lesson_player/presentation/widgets/lesson_key_phrases_step.dart';
import 'package:mohingo/features/lesson_player/presentation/widgets/lesson_reading_step.dart';

/// Taps through a lesson's intro — the conversation or text, then key
/// phrases — until its first question is on screen. A no-op for a lesson
/// that has neither, or one resumed part-way through.
Future<void> passLessonIntro(WidgetTester tester) async {
  await tester.pumpAndSettle();
  while (find.byType(LessonConversationStep).evaluate().isNotEmpty ||
      find.byType(LessonReadingStep).evaluate().isNotEmpty ||
      find.byType(LessonKeyPhrasesStep).evaluate().isNotEmpty) {
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
  }
}
