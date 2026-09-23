import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// Renders the small Markdown subset the documents in `assets/legal/` use:
/// `# ` a title, `## ` a section heading, `- ` a bullet, and blank-line
/// separated paragraphs. The paragraph straight after the title is the
/// document's date line and is set smaller. Anything else is shown as
/// plain text, so an unexpected mark never hides words.
///
/// Deliberately not a Markdown package: these four files are the only
/// Markdown in the app, and a renderer this size keeps them readable in
/// both directions — it lays out with start/end, never left/right.
class SimpleMarkdown extends StatelessWidget {
  const SimpleMarkdown(this.source, {super.key});

  final String source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final text = theme.textTheme;
    final body = text.bodyMedium?.copyWith(
      color: tokens.textPrimary,
      height: 1.5,
    );

    final children = <Widget>[];
    var afterTitle = false;
    for (final block in _blocks(source)) {
      switch (block) {
        case _Title(:final text):
          children.add(
            Semantics(
              header: true,
              child: Text(
                text,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
            ),
          );
          afterTitle = true;
          continue;
        case _Heading(:final text):
          children.add(
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.lg),
              child: Semantics(
                header: true,
                child: Text(
                  text,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        case _Paragraph(:final text):
          children.add(
            Padding(
              padding: EdgeInsets.only(
                top: afterTitle ? AppSpace.xs : AppSpace.sm,
              ),
              child: Text(
                text,
                style: afterTitle
                    ? theme.textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                      )
                    : body,
              ),
            ),
          );
        case _Bullet(:final text):
          children.add(
            Padding(
              padding: const EdgeInsetsDirectional.only(
                top: AppSpace.xs,
                start: AppSpace.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(child: Text('•  ', style: body)),
                  Expanded(child: Text(text, style: body)),
                ],
              ),
            ),
          );
      }
      afterTitle = false;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

sealed class _Block {
  const _Block(this.text);
  final String text;
}

class _Title extends _Block {
  const _Title(super.text);
}

class _Heading extends _Block {
  const _Heading(super.text);
}

class _Paragraph extends _Block {
  const _Paragraph(super.text);
}

class _Bullet extends _Block {
  const _Bullet(super.text);
}

Iterable<_Block> _blocks(String source) sync* {
  final paragraph = <String>[];
  Iterable<_Block> flush() sync* {
    if (paragraph.isNotEmpty) {
      yield _Paragraph(paragraph.join(' '));
      paragraph.clear();
    }
  }

  for (final raw in source.replaceAll('\r\n', '\n').split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) {
      yield* flush();
    } else if (line.startsWith('## ')) {
      yield* flush();
      yield _Heading(line.substring(3).trim());
    } else if (line.startsWith('# ')) {
      yield* flush();
      yield _Title(line.substring(2).trim());
    } else if (line.startsWith('- ')) {
      yield* flush();
      yield _Bullet(line.substring(2).trim());
    } else {
      paragraph.add(line);
    }
  }
  yield* flush();
}
