import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/activity_engine/presentation/activity_chrome.dart';

import 'test_harness.dart';

void main() {
  testWidgets('the English prompt is always rendered LTR, even under an Arabic '
      'locale/RTL ambient directionality', (tester) async {
    await tester.pumpActivityView(
      const ActivityChrome(
        prompt: "Complete: I'm ___ Iraq.",
        promptAr: 'أكمل: أنا ___ العراق.',
        body: SizedBox.shrink(),
      ),
      locale: const Locale('ar'),
    );

    final englishText = tester.widget<Text>(
      find.text("Complete: I'm ___ Iraq."),
    );
    expect(englishText.textDirection, TextDirection.ltr);
  });

  testWidgets(
    'an Arabic prompt with an embedded Latin word/phrase renders RTL — '
    'Flutter\'s Unicode Bidi Algorithm keeps the embedded Latin run '
    'internally LTR without any manual span-splitting here',
    (tester) async {
      const promptArWithEmbeddedEnglish =
          'اختر الترجمة الصحيحة لكلمة "hello" باللغة الإنجليزية.';

      await tester.pumpActivityView(
        const ActivityChrome(
          prompt: 'Choose the correct translation of "hello".',
          promptAr: promptArWithEmbeddedEnglish,
          body: SizedBox.shrink(),
        ),
        locale: const Locale('ar'),
      );

      final arabicText = tester.widget<Text>(
        find.text(promptArWithEmbeddedEnglish),
      );
      // The Arabic Text widget itself is explicitly RTL — this is the
      // paragraph-level direction; Flutter's bidi algorithm handles the
      // embedded "hello" run's internal LTR ordering automatically once
      // this is set, so no additional widget-level work is needed or done.
      expect(arabicText.textDirection, TextDirection.rtl);
      // The full string (embedded Latin included) reaches the render tree
      // unmodified — confirms nothing upstream reverses or mangles it.
      expect(arabicText.data, promptArWithEmbeddedEnglish);
    },
  );

  testWidgets(
    'the ambient app Directionality still follows the interface locale '
    '(RTL for Arabic) around the LTR-pinned English prompt',
    (tester) async {
      await tester.pumpActivityView(
        const ActivityChrome(
          prompt: 'English prompt',
          promptAr: 'موجه عربي',
          body: SizedBox.shrink(),
        ),
        locale: const Locale('ar'),
      );

      final context = tester.element(find.byType(ActivityChrome));
      expect(Directionality.of(context), TextDirection.rtl);
    },
  );
}
