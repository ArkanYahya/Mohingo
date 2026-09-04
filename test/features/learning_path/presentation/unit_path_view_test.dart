import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/preferences/shared_preferences_provider.dart';
import 'package:mohingo/core/widgets/status_indicator.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/learning_path/presentation/unit_path_view.dart';

// The brief's sample helper returned `CourseBundleParser.parse(json)`
// directly (a `CourseBundle`), but `courseContentProvider` — and this
// widget under test — expects a `CourseContentIndex` (it reads
// `index.bundle.units`). `CourseContentIndex.build` also runs the
// unresolved-reference validation the real content-loading path performs.
// See `CourseContentIndex.build` and the identical fixture pattern in
// test/features/lesson_player/lesson_player_resume_test.dart.
Future<CourseContentIndex> _realA1Index() async {
  final json = File('assets/content/en/A1/a1-course-bundle.json')
      .readAsStringSync();
  final bundle = CourseBundleParser.parse(json);
  return CourseContentIndex.build(bundle);
}

Future<AppDatabase> _seededDb() async {
  final db = AppDatabase(NativeDatabase.memory());
  final learnerId = await db
      .into(db.learners)
      .insert(
        LearnersCompanion.insert(
          uuid: 'learner-1',
          createdAt: DateTime.utc(2026, 9, 2),
        ),
      );
  await db
      .into(db.unitProgress)
      .insert(
        UnitProgressCompanion.insert(
          uuid: 'up-1',
          learnerId: learnerId,
          unitId: 'A1-U0',
          state: 'mastered',
          updatedAt: DateTime.utc(2026, 9, 2),
        ),
      );
  return db;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets(
    'renders one StatusIndicator per unit and a you-are-here marker',
    (tester) async {
      // The spine is a lazy ListView.builder — the default 800x600 test
      // surface only builds the handful of rows that fit on screen, not all
      // 13 units. A tall surface renders every row without needing to scroll
      // a sliver into view first, same technique as
      // test/features/settings/settings_screen_test.dart's _useTallViewport.
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = await _seededDb();
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appDatabaseProvider.overrideWithValue(db),
            courseContentProvider('a1')
                .overrideWith((ref) async => _realA1Index()),
          ],
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const UnitPathView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final index = await _realA1Index();
      expect(
        find.byType(StatusIndicator),
        findsNWidgets(index.bundle.units.length),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(UnitPathView)),
      )!;
      expect(find.text(l10n.unitPathYouAreHere), findsOneWidget);
    },
  );
}
