import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/models/registry_items.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/speech/providers/speech_providers.dart';
import 'package:mohingo/features/vocabulary/presentation/vocabulary_detail_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../review/presentation/review_test_harness.dart';
import '../../speech/fake_speech_services.dart';

void main() {
  testWidgets('an example with Arabic shows both lines', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          textToSpeechServiceProvider.overrideWithValue(
            FakeTextToSpeechService(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppColorSeed.calmTeal),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: VocabularyDetailView(
            index: reviewTestIndex,
            lexiconId: 'A1.LEX.HAVE.V01',
            kindLabel: 'Word',
            text: 'stay',
            arabic: 'يقيم',
            introducedIn: 'A1-U2-L2',
            examples: const [
              LexiconExample(
                en: 'We are staying near the centre.',
                ar: 'نقيم قرب المركز.',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('We are staying near the centre.'), findsOneWidget);
    expect(find.text('نقيم قرب المركز.'), findsOneWidget);
  });
}
