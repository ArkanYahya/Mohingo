import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/models/activity.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/placement_test/domain/placement_item_sampler.dart';
import 'package:mohingo/features/placement_test/presentation/placement_test_screen.dart';
import 'package:mohingo/features/speech/domain/speech_capability_service.dart';
import 'package:mohingo/features/speech/domain/speech_recognition_service.dart';
import 'package:mohingo/features/speech/providers/speech_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../speech/fake_speech_services.dart';

/// An end-to-end pass through the A1 Gateway Placement Test against **real**
/// A1 content — every item answered correctly, so the deterministic
/// [placementSeedProvider] override (see that provider's doc comment on why
/// it exists) drives the classifier all the way to `a1Mastered` without
/// ever needing to fabricate a "wrong" answer for an unknown item type.
/// [PlacementClassifier]'s other three outcomes are already covered by
/// placement_classifier_test.dart's pure boundary tests; this test's job is
/// to catch real UI-wiring bugs across the full item/productive/confidence/
/// result flow, the same role lesson_player_e2e_test.dart plays for the
/// lesson player.
CourseContentIndex _realA1Index() {
  final raw = File('assets/content/en/A1/a1-course-bundle.json')
      .readAsStringSync();
  return CourseContentIndex.build(CourseBundleParser.parse(raw));
}

Future<void> _answerCorrectly(WidgetTester tester, Activity activity) async {
  await tester.pumpAndSettle();

  switch (activity) {
    case AudioChoiceActivity a:
      await tester.tap(find.text(a.answer).last);
    case TextChoiceActivity a:
      await tester.tap(find.text(a.answer).last);
    case GapActivity a:
      // `.first`: a gap activity's own distractor options can coincidentally
      // repeat the same word twice (a real content quirk, not a bug in this
      // test) — either duplicate chip represents the same choice.
      await tester.tap(find.widgetWithText(ChoiceChip, a.answer).first);
    case OrderActivity a:
      for (final token in a.answer) {
        await tester.tap(find.text(token).first);
        await tester.pump();
      }
    case MatchActivity a:
      // `.first`: across the whole curriculum, a match activity's left/right
      // option pool can coincidentally repeat the same word (e.g. "Do"
      // pairing with more than one prompt) — any matching duplicate resolves
      // the pair the same way.
      for (final pair in a.pairs) {
        await tester.tap(find.text(pair[0]).first);
        await tester.pump();
        await tester.tap(find.text(pair[1]).first);
        await tester.pump();
      }
    case SpeakActivity a:
      await tester.enterText(
        find.byType(TextField),
        a.accepted.isNotEmpty ? a.accepted.first : 'an answer',
      );
    case WriteActivity a:
      await tester.enterText(
        find.byType(TextField),
        a.accepted.isNotEmpty ? a.accepted.first : 'an answer',
      );
    case FormActivity a:
      final fields = find.byType(TextField);
      for (var i = 0; i < a.fields.length; i++) {
        await tester.enterText(fields.at(i), 'an answer');
      }
    case DialogueActivity _:
      break;
  }
  await tester.pump();

  await tester.tap(find.byType(FilledButton)); // Check
  await tester.pump();
  await tester.tap(find.byType(FilledButton)); // Next
  await tester.pump();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
    'answering every sampled item correctly reaches a1Mastered, records '
    'every attempt under sessionType=placement, and stores exactly one '
    'attempt row',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final index = _realA1Index();
      const seed = 999;

      final expectedSequence = <Activity>[
        for (var i = 0; i < index.bundle.units.length; i++)
          ...PlacementItemSampler.receptiveItemsForUnit(
            index.bundle.units[i],
            seed: seed + i,
          ),
      ];
      final productiveItem = PlacementItemSampler.productiveItemForUnit(
        index.bundle.units.last,
        seed: seed,
      );
      if (productiveItem != null) expectedSequence.add(productiveItem);
      expect(
        expectedSequence,
        isNotEmpty,
        reason: 'the real bundle has practice content in every unit',
      );

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appDatabaseProvider.overrideWithValue(db),
            courseContentProvider('a1').overrideWith((ref) async => index),
            placementSeedProvider.overrideWithValue(seed),
            textToSpeechServiceProvider.overrideWithValue(
              FakeTextToSpeechService(),
            ),
            speechCapabilityServiceProvider.overrideWithValue(
              FakeSpeechCapabilityService(
                const DeviceSpeechCapabilities(
                  sttAvailableForLocale: false,
                  micPermission: SpeechPermissionStatus.notDetermined,
                ),
              ),
            ),
          ],
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const PlacementTestScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton)); // "Start"
      await tester.pumpAndSettle();

      for (final activity in expectedSequence) {
        await _answerCorrectly(tester, activity);
      }
      await tester.pumpAndSettle();

      // Confidence self-report — supporting info only, never affects the
      // classification already implied by answering everything correctly.
      await tester.tap(find.widgetWithText(OutlinedButton, '3'));
      await tester.pumpAndSettle();

      // Reached the result screen.
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);

      final attemptRows = await db.select(db.placementAttempts).get();
      expect(attemptRows, hasLength(1));
      expect(attemptRows.single.outcome, 'a1Mastered');
      expect(attemptRows.single.recommendedUnitId, isNull);
      expect(attemptRows.single.completedAt, isNotNull);
      expect(attemptRows.single.confidenceSelfReports, contains('3'));

      final itemAttempts = await db.select(db.activityAttempts).get();
      expect(itemAttempts, hasLength(expectedSequence.length));
      expect(
        itemAttempts.map((a) => a.sessionType).toSet(),
        {'placement'},
        reason:
            'every item recorded during the test must carry '
            'sessionType=placement, keeping it isolated from ordinary '
            'lesson mastery evidence and Review',
      );
    },
  );
}
