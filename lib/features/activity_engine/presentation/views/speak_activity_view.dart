import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../content/models/activity.dart';
import '../../../../content/models/evaluation_spec.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../data/local/database.dart' show ActivityAttempt;
import '../../../speech/domain/speech_capability_service.dart';
import '../../../speech/domain/speech_recognition_service.dart';
import '../../../speech/providers/speech_providers.dart';
import '../../domain/activity_submission.dart';
import '../../domain/answer_matching.dart';
import '../../domain/evaluation/evaluation_context.dart';
import '../../domain/evaluation/evaluator.dart';
import '../../domain/sound_effects_service.dart';
import '../../providers/online_refinement_providers.dart';
import '../../providers/sound_effects_providers.dart';
import '../activity_chrome.dart';

enum _SpeakMode {
  checkingCapability,
  requestingPermission,
  recordAvailable,
  recording,
  reviewTranscript,
  typedFallback,
}

/// Renders a `speak` activity.
///
/// Offers real on-device speech recognition when
/// [SpeechCapabilityService] reports it's actually usable right now
/// (locale supported, microphone permission already granted); otherwise
/// offers to request permission; and always falls back to a typed answer —
/// preserving lesson access without ever recording it as speaking evidence.
/// See docs/ARCHITECTURE.md's speech-capability strategy and
/// docs/DATA_MODEL.md.
///
/// The microphone is never touched until the learner deliberately taps
/// "Record" — capability/permission are only *checked*, never requested, on
/// mount. A temporary transcript is always shown for review before
/// submission; nothing is auto-submitted, and no raw audio is ever
/// retained. See docs/SECURITY.md.
class SpeakActivityView extends ConsumerStatefulWidget {
  const SpeakActivityView({
    required this.activity,
    required this.learnerId,
    required this.onSubmitted,
    this.evaluationContext = const EvaluationContext.empty(),
    this.reviewAttempt,
    this.suppressIncorrectBanner = false,
    super.key,
  });

  final SpeakActivity activity;
  final int learnerId;
  final OnActivitySubmitted onSubmitted;
  final EvaluationContext evaluationContext;

  /// When non-null, this view skips its microphone-capability check
  /// entirely and renders read-only straight into its submitted state,
  /// seeded from this recorded attempt — [reviewAttempt].isCorrect/.score
  /// are trusted verbatim, never recomputed. See docs/superpowers/specs/
  /// 2026-09-09-lesson-answer-review-design.md.
  final ActivityAttempt? reviewAttempt;

  /// True only when rendered by the live lesson player — see
  /// [ActivitySubmitOrFeedback.suppressIncorrectBanner]. This view renders
  /// [ActivityFeedbackBanner] directly (no submit button of its own to
  /// share via [ActivitySubmitOrFeedback]), so the same suppression is
  /// applied manually in [build].
  final bool suppressIncorrectBanner;

  @override
  ConsumerState<SpeakActivityView> createState() => _SpeakActivityViewState();
}

class _SpeakActivityViewState extends ConsumerState<SpeakActivityView> {
  static const _localeCode = 'en';

  _SpeakMode _mode = _SpeakMode.checkingCapability;
  DeviceSpeechCapabilities? _capabilities;
  String _liveTranscript = '';
  StreamSubscription<SpeechRecognitionResult>? _recognitionSubscription;

  final _typedController = TextEditingController();
  ActivitySubmission? _submission;

  /// Captured the instant [_submission] goes pending — a resolved attempt
  /// with an older `attemptedAt` belongs to an earlier retry of this same
  /// activity, not this submission, and must not be shown as its result.
  ///
  /// Truncated to whole seconds: `ActivityAttempts.attemptedAt` is stored
  /// at whole-second precision (Drift's `dateTime()` column default), so a
  /// millisecond-precision `DateTime.now()` captured here can otherwise
  /// compare as *after* the very row this submission itself produces a
  /// moment later, in the same wall-clock second — wrongly discarding a
  /// genuinely new result as a stale retry. Same field, same reason, as
  /// `write_activity_view.dart`'s.
  DateTime? _pendingSince;

  DateTime _truncatedToSeconds(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);

  @override
  void initState() {
    super.initState();
    final reviewAttempt = widget.reviewAttempt;
    if (reviewAttempt == null) {
      _checkCapability();
      return;
    }
    _liveTranscript = _decodeText(reviewAttempt.rawAnswer) ?? '';
    _mode = _SpeakMode.reviewTranscript;
    _submission = ActivitySubmission(
      correctness: switch (reviewAttempt.isCorrect) {
        true => ActivityCorrectness.correct,
        false => ActivityCorrectness.incorrect,
        null => ActivityCorrectness.notAutoGraded,
      },
      score: reviewAttempt.score,
      rawAnswerJson: reviewAttempt.rawAnswer,
      wasFallback: reviewAttempt.wasFallback,
    );
  }

  @override
  void dispose() {
    _recognitionSubscription?.cancel();
    _typedController.dispose();
    super.dispose();
  }

  String? _decodeText(String? rawAnswer) {
    if (rawAnswer == null) return null;
    try {
      final decoded = jsonDecode(rawAnswer);
      return decoded is String ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> _checkCapability() async {
    final capabilities = await ref
        .read(speechCapabilityServiceProvider)
        .currentCapabilities(localeCode: _localeCode);
    if (!mounted) return;
    setState(() {
      _capabilities = capabilities;
      _mode = capabilities.canRecordNow
          ? _SpeakMode.recordAvailable
          : (capabilities.canRequestPermission
                ? _SpeakMode.requestingPermission
                : _SpeakMode.typedFallback);
    });
  }

  Future<void> _requestPermission() async {
    final status = await ref
        .read(speechRecognitionServiceProvider)
        .requestPermission();
    if (!mounted) return;
    setState(() {
      _mode = status == SpeechPermissionStatus.granted
          ? _SpeakMode.recordAvailable
          : _SpeakMode.typedFallback;
    });
  }

  void _startRecording() {
    setState(() {
      _mode = _SpeakMode.recording;
      _liveTranscript = '';
    });
    final stream = ref
        .read(speechRecognitionServiceProvider)
        .recognize(
          localeCode: _localeCode,
          listenFor: const Duration(seconds: 20),
        );
    _recognitionSubscription = stream.listen(
      (result) {
        if (!mounted) return;
        setState(() => _liveTranscript = result.transcript);
        if (result.isFinal) {
          setState(() => _mode = _SpeakMode.reviewTranscript);
        }
      },
      onError: (Object _) {
        if (mounted) setState(() => _mode = _SpeakMode.typedFallback);
      },
      onDone: () {
        if (mounted && _mode == _SpeakMode.recording) {
          // Stream ended without a final result (e.g. cancelled/timed out).
          setState(
            () => _mode = _liveTranscript.isEmpty
                ? _SpeakMode.recordAvailable
                : _SpeakMode.reviewTranscript,
          );
        }
      },
    );
  }

  void _stopRecording() {
    // Cancelling the underlying service alone never completes the
    // recognition stream (see DeviceSpeechRecognitionService.recognize —
    // its StreamController is only closed by a final result, not by
    // cancel()), so onDone below would never fire and the UI would stay
    // stuck showing "Stop". Cancel the subscription (which does stop the
    // stream, via its own onCancel handler) and reset the mode directly,
    // mirroring exactly what onDone already does for the natural-
    // completion case.
    _recognitionSubscription?.cancel();
    ref.read(speechRecognitionServiceProvider).cancel();
    setState(() {
      _mode = _liveTranscript.isEmpty
          ? _SpeakMode.recordAvailable
          : _SpeakMode.reviewTranscript;
    });
  }

  void _submitTranscript() => _submit(_liveTranscript, wasFallback: false);

  void _submitTyped() {
    final text = _typedController.text.trim();
    if (text.isEmpty) return;
    _submit(text, wasFallback: true);
  }

  void _submit(String text, {required bool wasFallback}) {
    if (_submission != null) return;

    final ActivitySubmission submission;
    final evaluation = widget.activity.evaluation;
    if (widget.activity.accepted.isNotEmpty) {
      final isCorrect = widget.activity.accepted.any(
        (a) => answersMatch(a, text),
      );
      submission = ActivitySubmission(
        correctness: isCorrect
            ? ActivityCorrectness.correct
            : ActivityCorrectness.incorrect,
        score: isCorrect ? 1.0 : 0.0,
        rawAnswerJson: jsonEncode(text),
        wasFallback: wasFallback,
        correctAnswerLabel: _correctAnswerLabel(),
      );
    } else if (evaluation is KeywordChecklistEvaluationSpec &&
        evaluation.onlineRefinement != null) {
      final localResult = evaluate(evaluation, text);
      submission = ActivitySubmission(
        correctness: ActivityCorrectness.notAutoGraded,
        score: localResult.score,
        rawAnswerJson: jsonEncode(text),
        wasFallback: wasFallback,
        pendingOnlineRefinement: true,
      );
      _pendingSince = _truncatedToSeconds(DateTime.now());
    } else if (evaluation != null) {
      final result = evaluate(
        evaluation,
        text,
        context: widget.evaluationContext,
      );
      submission = ActivitySubmission(
        correctness: result.correctness,
        score: result.score,
        rawAnswerJson: jsonEncode(text),
        wasFallback: wasFallback,
        correctAnswerLabel: _correctAnswerLabel(),
      );
    } else {
      submission = ActivitySubmission(
        correctness: ActivityCorrectness.notAutoGraded,
        rawAnswerJson: jsonEncode(text),
        wasFallback: wasFallback,
      );
    }
    setState(() => _submission = submission);
    widget.onSubmitted(submission);
    // Never for notAutoGraded — nothing definitive to celebrate or flag
    // yet, whether it's a "no automatic check exists" answer or one still
    // queued for deferred online-refinement grading.
    if (submission.correctness != ActivityCorrectness.notAutoGraded) {
      playFeedbackSoundSafely(
        ref.read(soundEffectsServiceProvider),
        submission.correctness == ActivityCorrectness.correct
            ? ActivityFeedbackSound.correct
            : ActivityFeedbackSound.incorrect,
      );
    }
  }

  /// The pending [_submission] recast as its real graded result, once
  /// [attempt] proves to be the one this submission actually became (not a
  /// stale row from an earlier retry — see [_pendingSince]). `null` while
  /// still genuinely waiting.
  ActivitySubmission? _resolvedSubmission(ActivityAttempt? attempt) {
    if (attempt == null) return null;
    if (attempt.attemptedAt.isBefore(_pendingSince!)) return null;
    return ActivitySubmission(
      correctness: attempt.isCorrect == true
          ? ActivityCorrectness.correct
          : ActivityCorrectness.incorrect,
      score: attempt.score,
      rawAnswerJson: _submission!.rawAnswerJson,
      wasFallback: _submission!.wasFallback,
    );
  }

  /// The "correct answer is: ___" reveal shown on an incorrect submission.
  /// [widget.activity.accepted] wins when present (a closed-form answer
  /// list); otherwise falls back to whatever [widget.activity.evaluation]'s
  /// structured rubric can reveal (e.g. the resolved name for a
  /// `letterSequence` rubric) — `null` when neither has anything fixed to
  /// show, e.g. an open-ended `keywordChecklist` rubric.
  String? _correctAnswerLabel() {
    if (widget.activity.accepted.isNotEmpty) {
      return widget.activity.accepted.join(' / ');
    }
    final evaluation = widget.activity.evaluation;
    if (evaluation == null) return null;
    return expectedAnswerLabel(evaluation, widget.evaluationContext);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final submission = _submission;
    final displaySubmission =
        (submission != null && submission.pendingOnlineRefinement)
        ? _resolvedSubmission(
                ref
                    .watch(
                      latestAttemptProvider((
                        learnerId: widget.learnerId,
                        activityId: widget.activity.id,
                      )),
                    )
                    .value,
              ) ??
              submission
        : submission;

    return ActivityChrome(
      prompt: widget.activity.prompt,
      promptAr: widget.activity.promptAr,
      help: _mode == _SpeakMode.typedFallback && _submission == null
          ? Text(
              _capabilities?.micPermission ==
                      SpeechPermissionStatus.permanentlyDenied
                  ? l10n.speakPermissionPermanentlyDenied
                  : l10n.activitySpeechUnavailableUseWriting,
              style: Theme.of(context).textTheme.labelSmall,
            )
          : null,
      body: _buildBody(context, l10n),
      feedback: _buildFeedback(displaySubmission),
    );
  }

  /// Mirrors [ActivitySubmitOrFeedback.suppressIncorrectBanner]'s logic —
  /// this view has no submit button to share that widget with, so the same
  /// suppression is applied here by hand.
  Widget? _buildFeedback(ActivitySubmission? displaySubmission) {
    if (displaySubmission == null) return null;
    final isLiveIncorrect =
        widget.suppressIncorrectBanner &&
        !displaySubmission.pendingOnlineRefinement &&
        displaySubmission.correctness == ActivityCorrectness.incorrect;
    if (isLiveIncorrect) return null;
    return ActivityFeedbackBanner(
      submission: displaySubmission,
      correctAnswerLabel: _correctAnswerLabel(),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    switch (_mode) {
      case _SpeakMode.checkingCapability:
        return const Center(child: CircularProgressIndicator());

      case _SpeakMode.requestingPermission:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.mic),
              onPressed: _requestPermission,
              label: Text(l10n.speakEnableMicrophone),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _mode = _SpeakMode.typedFallback),
              child: Text(l10n.speakUseTypedAnswerInstead),
            ),
          ],
        );

      case _SpeakMode.recordAvailable:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.mic),
              onPressed: _startRecording,
              label: Text(l10n.speakStartRecording),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _mode = _SpeakMode.typedFallback),
              child: Text(l10n.speakUseTypedAnswerInstead),
            ),
          ],
        );

      case _SpeakMode.recording:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mic, color: Colors.red),
                const SizedBox(width: 8),
                Text(l10n.speakListening),
              ],
            ),
            if (_liveTranscript.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _liveTranscript,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _stopRecording,
              child: Text(l10n.speakStopRecording),
            ),
          ],
        );

      case _SpeakMode.reviewTranscript:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Only shown while genuinely about to submit — in review mode
            // (`_submission != null`, seeded straight into this mode from a
            // recorded attempt), nothing is about to be submitted, and
            // "before submitting" would be misleading (doubly so for a
            // typed-fallback attempt, where nothing was ever heard at all).
            if (_submission == null) ...[
              Text(l10n.speakReviewTranscript),
              const SizedBox(height: 4),
            ],
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_liveTranscript, textDirection: TextDirection.ltr),
            ),
            const SizedBox(height: 8),
            if (_submission == null) ...[
              FilledButton(
                onPressed: _submitTranscript,
                child: Text(AppLocalizations.of(context)!.activitySubmitButton),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () =>
                    setState(() => _mode = _SpeakMode.recordAvailable),
                child: Text(l10n.speakRerecord),
              ),
            ],
          ],
        );

      case _SpeakMode.typedFallback:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _typedController,
              enabled: _submission == null,
              maxLines: 2,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if (_submission == null)
              FilledButton(
                onPressed: _typedController.text.trim().isEmpty
                    ? null
                    : _submitTyped,
                child: Text(l10n.activitySubmitButton),
              ),
          ],
        );
    }
  }
}
