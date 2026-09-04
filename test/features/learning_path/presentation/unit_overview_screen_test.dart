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
import 'package:mohingo/features/learning_path/presentation/unit_overview_screen.dart';

// The brief's sample helper returned `CourseBundleParser.parse(json)`
// directly (a `CourseBundle`), but `courseContentProvider` — and this
// screen under test — expects a `CourseContentIndex` (it reads
// `index.unitsById`/`index.bundle.units`). `CourseContentIndex.build` also
// runs the unresolved-reference validation the real content-loading path
// performs. See the identical fixture pattern in
// test/features/learning_path/presentation/unit_path_view_test.dart.
Future<CourseContentIndex> _realA1Index() async {
  final json = File('assets/content/en/A1/a1-course-bundle.json')
      .readAsStringSync();
  final bundle = CourseBundleParser.parse(json);
  return CourseContentIndex.build(bundle);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('shows one StatusIndicator per lesson in the unit', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: 'learner-1',
            createdAt: DateTime.utc(2026, 9, 2),
          ),
        );

    final index = await _realA1Index();
    final unit = index.bundle.units.first;

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
          home: UnitOverviewScreen(unitId: unit.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StatusIndicator), findsNWidgets(unit.lessons.length));
  });
}
