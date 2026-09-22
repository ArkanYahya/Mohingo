import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';

export '../../../speech/domain/speech_text.dart' show phraseForSpeech;

/// A registry phrase's fill-in slots — `"My name is {name}."`.
final _placeholder = RegExp(r'\{(\w+)\}');

/// A chunk-registry phrase with its `{placeholder}` slots made visible.
///
/// English ([TextDirection.ltr]) phrases show each slot as a small labelled
/// [PhraseSlot] ("My name is [name]."), so the learner sees what to put
/// there. Arabic phrases show an ellipsis instead: the keys are English,
/// and the Arabic text often attaches a suffix straight to the slot
/// (`هو {relation}ي`), which a boxed label would break apart.
class PhraseText extends StatelessWidget {
  const PhraseText(
    this.text, {
    this.style,
    this.textDirection = TextDirection.ltr,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    if (textDirection == TextDirection.rtl || !_placeholder.hasMatch(text)) {
      return Text(
        text.replaceAll(_placeholder, '…'),
        textDirection: textDirection,
        style: style,
      );
    }

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in _placeholder.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: PhraseSlot(label: match.group(1)!.toLowerCase()),
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));

    return Text.rich(
      TextSpan(children: spans),
      textDirection: TextDirection.ltr,
      style: style,
      semanticsLabel: text.replaceAllMapped(
        _placeholder,
        (m) => m.group(1)!.toLowerCase(),
      ),
    );
  }
}

/// The small muted box standing in for a phrase's fill-in word.
class PhraseSlot extends StatelessWidget {
  const PhraseSlot({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    return ExcludeSemantics(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: tokens.cardMuted,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
