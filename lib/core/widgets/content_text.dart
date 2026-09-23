import 'package:flutter/material.dart';

/// The edge a line of content written in [direction] starts from: the left
/// for English, the right for Arabic — the text's own edge, never the
/// layout's.
Alignment contentAlignment(TextDirection direction) =>
    AlignmentDirectional.centerStart.resolve(direction);

/// One line or paragraph of curriculum content in a single language — an
/// English or Arabic title, prompt, phrase, gloss or passage.
///
/// Content keeps its own script's direction and edge whatever the
/// interface language: English reads and aligns left-to-right, Arabic
/// right-to-left, so a short title and a long one that wraps line up, and
/// "Where Are You From?" never sits flush right under an Arabic interface.
/// Interface copy is different — it follows the layout — and stays a plain
/// [Text]. See docs/DESIGN_SYSTEM.md, "Direction".
///
/// Fills the width it is given (a column, a list row, an `Expanded`) and
/// shrink-wraps where the width is unbounded (a `Wrap`, a plain `Row`).
class ContentText extends StatelessWidget {
  /// English content: left-to-right, from the left edge.
  const ContentText.en(
    this.text, {
    this.style,
    this.maxLines,
    this.overflow,
    super.key,
  }) : direction = TextDirection.ltr;

  /// Arabic content: right-to-left, from the right edge.
  const ContentText.ar(
    this.text, {
    this.style,
    this.maxLines,
    this.overflow,
    super.key,
  }) : direction = TextDirection.rtl;

  final String text;
  final TextDirection direction;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: contentAlignment(direction),
      child: Text(
        text,
        textDirection: direction,
        textAlign: TextAlign.start,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}
