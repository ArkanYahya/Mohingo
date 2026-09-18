import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/features/activity_engine/presentation/widgets/phrase_text.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(AppColorSeed.calmTeal),
    home: Scaffold(body: child),
  ),
);

void main() {
  test('phraseForSpeech reads a placeholder as a pause, not its key', () {
    expect(phraseForSpeech('My name is {name}.'), 'My name is ….');
    expect(phraseForSpeech('Nice to meet you.'), 'Nice to meet you.');
  });

  testWidgets('an English phrase shows each {placeholder} as a labelled '
      'slot, lower-cased, and reads naturally to a screen reader', (
    tester,
  ) async {
    await _pump(tester, const PhraseText('This is {Person}.'));

    expect(find.byType(PhraseSlot), findsOneWidget);
    expect(tester.widget<PhraseSlot>(find.byType(PhraseSlot)).label, 'person');
    expect(find.bySemanticsLabel('This is person.'), findsOneWidget);
  });

  testWidgets('an Arabic phrase shows placeholders as an ellipsis — the '
      'keys are English and Arabic attaches suffixes to them', (tester) async {
    await _pump(
      tester,
      const PhraseText('هو {relation}ي.', textDirection: TextDirection.rtl),
    );

    expect(find.byType(PhraseSlot), findsNothing);
    expect(find.text('هو …ي.'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('هو …ي.')).textDirection,
      TextDirection.rtl,
    );
  });

  testWidgets('a phrase with no placeholder is plain text', (tester) async {
    await _pump(tester, const PhraseText('Nice to meet you.'));

    expect(find.byType(PhraseSlot), findsNothing);
    expect(find.text('Nice to meet you.'), findsOneWidget);
  });
}
