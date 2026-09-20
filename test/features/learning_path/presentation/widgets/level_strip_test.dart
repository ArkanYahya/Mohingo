import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/catalog/level_catalog.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/theme/app_theme.dart';
import 'package:mohingo/core/theme/color_seed.dart';
import 'package:mohingo/features/learning_path/presentation/widgets/level_strip.dart';
import 'package:mohingo/features/progress/domain/level_access.dart';

void main() {
  testWidgets('a level whose access has not resolved offers no way to open '
      'it', (tester) async {
    LevelAccess? reported;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light(AppColorSeed.calmTeal),
        home: Scaffold(
          body: LevelStrip(
            catalog: kLevelCatalog,
            currentLevelId: 'a1',
            // Nothing has resolved yet.
            access: const {},
            onSelect: (_, access) => reported = access,
          ),
        ),
      ),
    );

    await tester.tap(find.text('A2'));
    await tester.pump();

    expect(reported, LevelAccess.notReleased);
  });
}
