import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../content/models/activity.dart';
import '../../domain/activity_submission.dart';
import '../activity_chrome.dart';

/// Renders a `form` activity: one text field per declared field name.
///
/// Submissions are always recorded as `notAutoGraded`. [FormActivity]
/// parses its `evaluation` field into a structured `EvaluationSpec` just
/// like `write`/`speak` do, but this view deliberately doesn't read or
/// grade it yet: a `form` activity has several independently named
/// [FormActivity.fields], and how a single spec should apply across them
/// isn't designed — no shipped `form` activity currently authors an
/// `evaluation` that needs it. Wiring grading up is a future task, once
/// real content asks for it. See docs/superpowers/specs/
/// 2026-09-07-offline-answer-evaluation-design.md and docs/DATA_MODEL.md.
class FormActivityView extends StatefulWidget {
  const FormActivityView({
    required this.activity,
    required this.onSubmitted,
    super.key,
  });

  final FormActivity activity;
  final OnActivitySubmitted onSubmitted;

  @override
  State<FormActivityView> createState() => _FormActivityViewState();
}

class _FormActivityViewState extends State<FormActivityView> {
  late final Map<String, TextEditingController> _controllers = {
    for (final field in widget.activity.fields) field: TextEditingController(),
  };
  ActivitySubmission? _submission;

  bool get _allFilled =>
      _controllers.values.every((c) => c.text.trim().isNotEmpty);

  void _submit() {
    if (!_allFilled || _submission != null) return;
    final answers = {
      for (final entry in _controllers.entries) entry.key: entry.value.text,
    };
    final submission = ActivitySubmission(
      correctness: ActivityCorrectness.notAutoGraded,
      rawAnswerJson: jsonEncode(answers),
    );
    setState(() => _submission = submission);
    widget.onSubmitted(submission);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ActivityChrome(
      prompt: widget.activity.prompt,
      promptAr: widget.activity.promptAr,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final field in widget.activity.fields)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _controllers[field],
                enabled: _submission == null,
                decoration: InputDecoration(
                  labelText: field,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
        ],
      ),
      feedback: ActivitySubmitOrFeedback(
        submission: _submission,
        canSubmit: _allFilled,
        onSubmit: _submit,
      ),
    );
  }
}
