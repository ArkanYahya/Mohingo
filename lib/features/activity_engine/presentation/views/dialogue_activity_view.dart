import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../content/models/activity.dart';
import '../../domain/activity_submission.dart';
import '../activity_chrome.dart';

/// Renders a `dialogue` activity.
///
/// `dialogue` is declared in the curriculum bundle's `domain.ACTIVITY_TYPES`
/// but has **zero authored instances** in the current A1 content (verified
/// this session) — there is no real shape to render against yet, only
/// [DialogueActivity]'s common fields. This view exists so the registry is
/// complete and testable against a hand-authored fixture (see
/// docs/TESTING.md), not because real content currently reaches it. Treated
/// as an acknowledge-and-continue step, never auto-graded, until real
/// content defines what a dialogue activity actually needs to capture.
class DialogueActivityView extends StatefulWidget {
  const DialogueActivityView({
    required this.activity,
    required this.onSubmitted,
    super.key,
  });

  final DialogueActivity activity;
  final OnActivitySubmitted onSubmitted;

  @override
  State<DialogueActivityView> createState() => _DialogueActivityViewState();
}

class _DialogueActivityViewState extends State<DialogueActivityView> {
  ActivitySubmission? _submission;

  void _submit() {
    if (_submission != null) return;
    final submission = const ActivitySubmission(
      correctness: ActivityCorrectness.notAutoGraded,
    );
    setState(() => _submission = submission);
    widget.onSubmitted(submission);
  }

  @override
  Widget build(BuildContext context) {
    return ActivityChrome(
      prompt: widget.activity.prompt,
      promptAr: widget.activity.promptAr,
      body: Text(
        jsonEncode(widget.activity.raw),
        style: Theme.of(context).textTheme.bodySmall,
        textDirection: TextDirection.ltr,
      ),
      feedback: ActivitySubmitOrFeedback(
        submission: _submission,
        canSubmit: true,
        onSubmit: _submit,
      ),
    );
  }
}
