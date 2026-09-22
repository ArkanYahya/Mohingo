import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/core/widgets/content_text.dart';

const _box = Key('box');

/// [child] in a 300px-wide, start-aligned column under [direction] — the
/// shape of every header, card and list row that shows curriculum text.
Widget _app(Widget child, {required TextDirection direction}) => MaterialApp(
  home: Directionality(
    textDirection: direction,
    child: Scaffold(
      body: Center(
        child: SizedBox(
          key: _box,
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [child],
          ),
        ),
      ),
    ),
  ),
);

void main() {
  const english = 'Where Are You From?';
  const arabic = 'من أين أنت؟';

  for (final direction in TextDirection.values) {
    group('in a ${direction.name} layout', () {
      testWidgets('an English line reads left-to-right and starts at the '
          'left edge', (tester) async {
        await tester.pumpWidget(
          _app(const ContentText.en(english), direction: direction),
        );

        final box = tester.getRect(find.byKey(_box));
        final line = tester.getRect(find.text(english));
        expect(line.left, box.left);
        expect(line.right, lessThan(box.right));
        expect(
          tester.widget<Text>(find.text(english)).textDirection,
          TextDirection.ltr,
        );
      });

      testWidgets('an Arabic line reads right-to-left and starts at the '
          'right edge', (tester) async {
        await tester.pumpWidget(
          _app(const ContentText.ar(arabic), direction: direction),
        );

        final box = tester.getRect(find.byKey(_box));
        final line = tester.getRect(find.text(arabic));
        expect(line.right, box.right);
        expect(line.left, greaterThan(box.left));
        expect(
          tester.widget<Text>(find.text(arabic)).textDirection,
          TextDirection.rtl,
        );
      });

      testWidgets('a line that wraps fills the width and keeps its own '
          "script's alignment, so a long title and a short one line up", (
        tester,
      ) async {
        const long =
            'A very long English lesson title that certainly wraps onto a '
            'second line at this width';
        await tester.pumpWidget(
          _app(
            const ContentText.en(long, style: TextStyle(fontSize: 20)),
            direction: direction,
          ),
        );

        final box = tester.getRect(find.byKey(_box));
        final line = tester.getRect(find.text(long));
        expect(line.left, box.left);
        expect(line.right, box.right);
        final text = tester.widget<Text>(find.text(long));
        expect(text.textDirection, TextDirection.ltr);
        expect(text.textAlign, TextAlign.start);
      });
    });
  }

  testWidgets('style, maxLines and overflow reach the text', (tester) async {
    await tester.pumpWidget(
      _app(
        const ContentText.en(
          english,
          style: TextStyle(fontSize: 30),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        direction: TextDirection.ltr,
      ),
    );
    final text = tester.widget<Text>(find.text(english));
    expect(text.style?.fontSize, 30);
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  test('contentAlignment is the left edge for English and the right edge '
      'for Arabic', () {
    expect(contentAlignment(TextDirection.ltr), Alignment.centerLeft);
    expect(contentAlignment(TextDirection.rtl), Alignment.centerRight);
  });
}
