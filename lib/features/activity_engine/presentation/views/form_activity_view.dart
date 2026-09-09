import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../content/models/activity.dart';
import '../../../../data/local/database.dart' show ActivityAttempt;
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
    this.reviewAttempt,
    super.key,
  });

  final FormActivity activity;
  final OnActivitySubmitted onSubmitted;

  /// When non-null, this view renders read-only straight into its submitted
  /// state, pre-filled from this recorded attempt — never live-editable.
  /// Always the neutral `notAutoGraded` treatment, exactly like a live
  /// submission — forms are never auto-graded. See docs/superpowers/specs/
  /// 2026-09-09-lesson-answer-review-design.md.
  final ActivityAttempt? reviewAttempt;

  @override
  State<FormActivityView> createState() => _FormActivityViewState();
}

class _FormActivityViewState extends State<FormActivityView> {
  // Decoded in a `late final` field initializer rather than in `initState`
  // (unlike its 6 sibling views): `_controllers` below is itself a `late
  // final` field whose own initializer needs each TextEditingController's
  // starting text up front, and field initializers run before `initState`
  // — by the time `initState` would run, it's too late to seed
  // `_controllers`' starting text.
  late final Map<String, String> _reviewAnswers =
      _decodeAnswers(widget.reviewAttempt?.rawAnswer) ?? const {};

  late final Map<String, TextEditingController> _controllers = {
    for (final field in widget.activity.fields)
      field: TextEditingController(text: _reviewAnswers[field] ?? ''),
  };
  ActivitySubmission? _submission;

  @override
  void initState() {
    super.initState();
    final reviewAttempt = widget.reviewAttempt;
    if (reviewAttempt == null) return;
    _submission = ActivitySubmission(
      correctness: ActivityCorrectness.notAutoGraded,
      rawAnswerJson: reviewAttempt.rawAnswer,
    );
  }

  Map<String, String>? _decodeAnswers(String? rawAnswer) {
    if (rawAnswer == null) return null;
    try {
      final decoded = jsonDecode(rawAnswer);
      return decoded is Map ? Map<String, String>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

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
