import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/features/speech/presentation/listen_button.dart';
import 'package:mohingo/features/speech/providers/speech_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_speech_services.dart';

Future<void> _pumpListenButton(
  WidgetTester tester, {
  required String text,
  bool autoPlay = false,
  required FakeTextToSpeechService tts,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        textToSpeechServiceProvider.overrideWithValue(tts),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: ListenButton(text: text, autoPlay: autoPlay),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'autoPlay: true speaks the text immediately on mount, with no tap',
    (tester) async {
      final tts = FakeTextToSpeechService();
      await _pumpListenButton(
        tester,
        text: 'Good morning.',
        autoPlay: true,
        tts: tts,
      );
      await tester.pump();

      expect(tts.spoken, ['Good morning.']);
    },
  );

  testWidgets(
    'autoPlay: false (the default) never speaks until the button is tapped',
    (tester) async {
      final tts = FakeTextToSpeechService();
      await _pumpListenButton(tester, text: 'Good morning.', tts: tts);
      await tester.pump();

      expect(tts.spoken, isEmpty);

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(tts.spoken, ['Good morning.']);
    },
  );
}
