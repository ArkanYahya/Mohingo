import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';

/// The typed-answer field style shared by writing, form and the speaking
/// fallback: a white card with a hairline that turns ink while focused.
InputDecoration activityInputDecoration(
  BuildContext context, {
  String? labelText,
}) {
  final theme = Theme.of(context);
  final tokens = theme.extension<AppTokens>()!;

  OutlineInputBorder outline(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.card),
    borderSide: BorderSide(color: color, width: width),
  );

  return InputDecoration(
    labelText: labelText,
    hintText: labelText == null
        ? AppLocalizations.of(context)!.activityAnswerFieldHint
        : null,
    hintStyle: theme.textTheme.bodyLarge?.copyWith(color: tokens.textSecondary),
    filled: true,
    fillColor: tokens.card,
    contentPadding: const EdgeInsets.all(AppSpace.md),
    border: outline(tokens.border, 1),
    enabledBorder: outline(tokens.border, 1),
    disabledBorder: outline(tokens.border, 1),
    focusedBorder: outline(tokens.primaryInk, 2),
  );
}

/// Words in [text]: runs of non-whitespace.
int countWords(String text) =>
    text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
