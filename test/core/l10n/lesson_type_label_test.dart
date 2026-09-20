import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/core/l10n/generated/app_localizations.dart';
import 'package:mohingo/core/l10n/lesson_type_label.dart';

void main() {
  test("A2's text-based lessons have a name in both languages", () {
    final en = lookupAppLocalizations(const Locale('en'));
    final ar = lookupAppLocalizations(const Locale('ar'));
    expect(
      lessonTypeLabel(en, 'integrated-production'),
      en.homeLessonTypeIntegrated,
    );
    expect(
      lessonTypeLabel(ar, 'integrated-production'),
      ar.homeLessonTypeIntegrated,
    );
    expect(en.homeLessonTypeIntegrated, isNot(ar.homeLessonTypeIntegrated));
  });
}
