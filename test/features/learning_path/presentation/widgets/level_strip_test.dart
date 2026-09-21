import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

  testWidgets('a segment is a button a screen-reader user can actually '
      'press — switching level is not a sighted-only control', (tester) async {
    final semantics = tester.ensureSemantics();
    LevelCatalogEntry? reported;
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
            access: const {
              'a1': LevelAccess.open,
              'a2': LevelAccess.lockedNeedsPrerequisite,
            },
            onSelect: (entry, _) => reported = entry,
          ),
        ),
      ),
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(LevelStrip)))!;

    // A locked level too: its tap is what opens the lock sheet, the only
    // way forward from it.
    final label = l10n.learnLevelSemanticsLocked('A2');
    expect(
      tester.getSemantics(find.bySemanticsLabel(label)),
      isSemantics(isButton: true, hasTapAction: true),
    );

    tester.semantics.performAction(
      find.semantics.byLabel(label),
      SemanticsAction.tap,
    );
    await tester.pump();
    expect(reported?.levelId, 'a2');
    semantics.dispose();
  });
}
