import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../content/models/activity.dart';
import '../../../../content/models/evaluation_spec.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../data/local/database.dart' show ActivityAttempt;
import '../../../speech/domain/audio_clip_index.dart';
import '../../../speech/domain/speech_capability_service.dart';
import '../../../speech/domain/speech_recognition_service.dart';
import '../../../speech/providers/speech_providers.dart';
import '../../domain/activity_submission.dart';
import '../../domain/answer_matching.dart';
import '../../domain/evaluation/evaluation_context.dart';
import '../../domain/evaluation/evaluator.dart';
import '../../domain/evaluation/grading_signals.dart';
import '../../domain/spoken_answer.dart';
import '../../domain/sound_effects_service.dart';
import '../../providers/online_refinement_providers.dart';
import '../../providers/sound_effects_providers.dart';
import '../activity_chrome.dart';
import '../widgets/activity_partner_turns_card.dart';
import '../widgets/activity_text_field.dart';
import '../widgets/phrase_text.dart';

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
/// the record button — capability/permission are only *checked*, never
/// requested, on mount. A temporary transcript is always shown for review
/// before submission; nothing is auto-submitted, and no raw audio is ever
/// retained. See docs/SECURITY.md.
///
/// Check lives in the shared [ActivitySubmitOrFeedback] slot like every
/// other activity type; it enables once there's a transcript to review or
/// a typed answer.
class SpeakActivityView extends ConsumerStatefulWidget {
  const SpeakActivityView({
    required this.activity,
    required this.learnerId,
    required this.onSubmitted,
    this.evaluationContext = const EvaluationContext.empty(),
    this.reviewAttempt,
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
    final explanation = explanationIn(reviewAttempt.criteriaScores);
    _submission = ActivitySubmission(
      correctness: switch (reviewAttempt.isCorrect) {
        true => ActivityCorrectness.correct,
        false => ActivityCorrectness.incorrect,
        null => ActivityCorrectness.notAutoGraded,
      },
      score: reviewAttempt.score,
      rawAnswerJson: reviewAttempt.rawAnswer,
      wasFallback: reviewAttempt.wasFallback,
      explanationEn: explanation?.en,
      explanationAr: explanation?.ar,
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

  /// True while the meaning signal is being computed for a submitted
  /// answer — Check is disabled, and a second tap is ignored.
  var _grading = false;

  /// Grades [text]. The task's rubric grades when it has one; its
  /// `accepted` list grades only a task without a rubric, and is otherwise
  /// the model answer shown after a miss. A recognised transcript is graded
  /// as it was said ([SpokenAnswer], ADR 0009); a typed fallback as written.
  ///
  /// A `keywordChecklist` task with model answers also gets the on-device
  /// meaning signal (ADR 0011) — see `WriteActivityView._submit` for the
  /// rule, which is the same here. Nothing a learner says ever goes online:
  /// a speak rubric is never marked `onlineRefinement` (a gate), so a
  /// spoken answer is queued only for an installed AI pack to judge on the
  /// device.
  Future<void> _submit(String text, {required bool wasFallback}) async {
    if (_submission != null || _grading) return;

    final ActivitySubmission submission;
    final evaluation = widget.activity.evaluation;
    final spoken = wasFallback
        ? null
        : SpokenAnswer(names: namesInTask(widget.activity));
    if (evaluation is KeywordChecklistEvaluationSpec) {
      final rubric = evaluate(evaluation, text, spoken: spoken);
      final signalsOn = gradingSignalsEnabled(context);
      setState(() => _grading = true);
      // No model answers, no meaning to compare: the service is not asked,
      // so a task without them never waits on the model.
      final meaning = signalsOn && widget.activity.accepted.isNotEmpty
          ? await ref
                .read(meaningSignalServiceProvider)
                .meaning(text, modelAnswers: widget.activity.accepted)
          : null;
      final packAvailable = signalsOn
          ? await ref.read(localJudgementServiceProvider).isAvailable
          : false;
      if (!mounted) return;
      _grading = false;
      final onlineAllowed = evaluation.onlineRefinement != null;
      if (onlineAllowed || packAvailable) {
        submission = ActivitySubmission(
          correctness: ActivityCorrectness.notAutoGraded,
          score: rubric.score,
          rawAnswerJson: jsonEncode(text),
          wasFallback: wasFallback,
          pendingOnlineRefinement: true,
          onlineRefinementAllowed: onlineAllowed,
          meaningSignal: meaning,
        );
        _pendingSince = _truncatedToSeconds(DateTime.now());
      } else {
        final signals = GradingSignals(
          rubric: rubric.score ?? 0.0,
          meaning: meaning,
        );
        final finalScore = combineSignals(signals);
        final passes = passesWithSignals(
          rubricCorrect: rubric.correctness == ActivityCorrectness.correct,
          rubricScore: signals.rubric,
          finalScore: finalScore,
        );
        submission = ActivitySubmission(
          correctness: passes
              ? ActivityCorrectness.correct
              : ActivityCorrectness.incorrect,
          score: finalScore,
          rawAnswerJson: jsonEncode(text),
          wasFallback: wasFallback,
          criteriaScoresJson: meaning == null
              ? null
              : criteriaScoresJson(signals, finalScore: finalScore),
          correctAnswerLabel: _correctAnswerLabel(),
        );
      }
    } else if (evaluation != null) {
      final result = evaluate(
        evaluation,
        text,
        context: widget.evaluationContext,
        spoken: spoken,
      );
      submission = ActivitySubmission(
        correctness: result.correctness,
        score: result.score,
        rawAnswerJson: jsonEncode(text),
        wasFallback: wasFallback,
        correctAnswerLabel: _correctAnswerLabel(),
      );
    } else if (widget.activity.accepted.isNotEmpty) {
      final isCorrect = widget.activity.accepted.any(
        (a) => answersMatch(a, text, spoken: spoken),
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
    // queued for deferred grading.
    if (submission.correctness != ActivityCorrectness.notAutoGraded) {
      if (marksAnswers(context)) {
        playFeedbackSoundSafely(
          ref.read(soundEffectsServiceProvider),
          submission.correctness == ActivityCorrectness.correct
              ? ActivityFeedbackSound.correct
              : ActivityFeedbackSound.incorrect,
        );
      }
    }
  }

  /// The pending [_submission] recast as its real graded result, once
  /// [attempt] proves to be the one this submission actually became (not a
  /// stale row from an earlier retry — see [_pendingSince]). `null` while
  /// still genuinely waiting.
  ActivitySubmission? _resolvedSubmission(ActivityAttempt? attempt) {
    if (attempt == null) return null;
    if (attempt.attemptedAt.isBefore(_pendingSince!)) return null;
    final explanation = explanationIn(attempt.criteriaScores);
    return ActivitySubmission(
      correctness: attempt.isCorrect == true
          ? ActivityCorrectness.correct
          : ActivityCorrectness.incorrect,
      score: attempt.score,
      rawAnswerJson: _submission!.rawAnswerJson,
      wasFallback: _submission!.wasFallback,
      explanationEn: explanation?.en,
      explanationAr: explanation?.ar,
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
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
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
      source: widget.activity.sourceCard,
      help: _help(l10n, theme, tokens),
      body: _withUsefulPhrases(context, _buildBody(context, l10n)),
      feedback: ActivitySubmitOrFeedback(
        submission: displaySubmission,
        canSubmit: _canSubmit,
        onSubmit: _submitCurrent,
        correctAnswerLabel: _correctAnswerLabel(),
        secondaryAction: _secondaryAction(l10n),
      ),
    );
  }

  /// The other person's lines, when the task has any, then — in the typed
  /// fallback, before submission — why the learner is typing.
  Widget? _help(AppLocalizations l10n, ThemeData theme, AppTokens tokens) {
    final turns = widget.activity.partnerTurns;
    final fallbackNote =
        _mode == _SpeakMode.typedFallback && _submission == null
        ? Text(
            _capabilities?.micPermission ==
                    SpeechPermissionStatus.permanentlyDenied
                ? l10n.speakPermissionPermanentlyDenied
                : l10n.activitySpeechUnavailableUseWriting,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.textSecondary,
            ),
          )
        : null;
    if (turns.isEmpty) return fallbackNote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActivityPartnerTurnsCard(
          turns: turns,
          speaker: widget.activity.partnerSpeaker ?? kPartnerSpeaker,
          autoPlay: widget.reviewAttempt == null,
        ),
        if (fallbackNote != null) ...[
          const SizedBox(height: AppSpace.sm),
          fallbackNote,
        ],
      ],
    );
  }

  bool get _canSubmit =>
      !_grading &&
      switch (_mode) {
        _SpeakMode.reviewTranscript => _liveTranscript.trim().isNotEmpty,
        _SpeakMode.typedFallback => _typedController.text.trim().isNotEmpty,
        _ => false,
      };

  void _submitCurrent() {
    switch (_mode) {
      case _SpeakMode.reviewTranscript:
        _submitTranscript();
      case _SpeakMode.typedFallback:
        _submitTyped();
      default:
        break;
    }
  }

  Widget? _secondaryAction(AppLocalizations l10n) => switch (_mode) {
    _SpeakMode.requestingPermission ||
    _SpeakMode.recordAvailable => TextButton.icon(
      icon: const Icon(Icons.keyboard_rounded),
      label: Text(l10n.speakUseTypedAnswerInstead),
      onPressed: () => setState(() => _mode = _SpeakMode.typedFallback),
    ),
    _SpeakMode.reviewTranscript => TextButton.icon(
      icon: const Icon(Icons.replay_rounded),
      label: Text(l10n.speakRerecord),
      onPressed: () => setState(() => _mode = _SpeakMode.recordAvailable),
    ),
    _ => null,
  };

  /// Adds the lesson's own phrases under [body] as optional help, hidden
  /// until asked for — only inside the lesson player (which supplies them
  /// via [ActivityFrameScope.usefulPhrases]) and only before submission.
  Widget _withUsefulPhrases(BuildContext context, Widget body) {
    final phrases =
        ActivityFrameScope.maybeOf(context)?.usefulPhrases ?? const [];
    if (phrases.isEmpty ||
        _submission != null ||
        _mode == _SpeakMode.checkingCapability) {
      return body;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        body,
        const SizedBox(height: AppSpace.md),
        _UsefulPhrases(phrases: phrases),
      ],
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final colorScheme = theme.colorScheme;

    switch (_mode) {
      case _SpeakMode.checkingCapability:
        return const SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        );

      case _SpeakMode.requestingPermission:
        return _MicCard(
          button: _RoundMicButton(
            icon: Icons.mic_rounded,
            tooltip: l10n.speakEnableMicrophone,
            onTap: _requestPermission,
          ),
          title: l10n.speakEnableMicrophone,
          subtitle: l10n.speakEnableMicrophoneHint,
        );

      case _SpeakMode.recordAvailable:
        return _MicCard(
          button: _RoundMicButton(
            icon: Icons.mic_rounded,
            tooltip: l10n.speakStartRecording,
            onTap: _startRecording,
          ),
          title: l10n.speakTapToRecord,
          subtitle: l10n.speakTapToRecordHint,
        );

      case _SpeakMode.recording:
        return _MicCard(
          button: _RoundMicButton(
            icon: Icons.stop_rounded,
            tooltip: l10n.speakStopRecording,
            onTap: _stopRecording,
            color: colorScheme.error,
            onColor: colorScheme.onError,
            halo: colorScheme.errorContainer,
          ),
          title: l10n.speakListening,
          subtitle: _liveTranscript.isEmpty ? l10n.speakTapToStop : null,
          transcript: _liveTranscript.isEmpty ? null : _liveTranscript,
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
              Text(
                l10n.speakReviewTranscript,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpace.xs),
            ],
            DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.card,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: tokens.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.md),
                child: Text(
                  _liveTranscript,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: tokens.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        );

      case _SpeakMode.typedFallback:
        return TextField(
          controller: _typedController,
          enabled: _submission == null,
          minLines: 2,
          maxLines: 4,
          decoration: activityInputDecoration(context),
          onChanged: (_) => setState(() {}),
        );
    }
  }
}

/// The speaking question's centrepiece: one large round button, a caption
/// and a quieter line under it, on a card.
class _MicCard extends StatelessWidget {
  const _MicCard({
    required this.button,
    required this.title,
    this.subtitle,
    this.transcript,
  });

  final Widget button;
  final String title;
  final String? subtitle;

  /// What's been heard so far, while recording.
  final String? transcript;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.lg,
          AppSpace.md,
          AppSpace.md + AppSpace.xxs,
        ),
        child: Column(
          children: [
            button,
            const SizedBox(height: AppSpace.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpace.xxs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
            ],
            if (transcript != null) ...[
              const SizedBox(height: AppSpace.xs),
              Text(
                transcript!,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// An 80dp round button with a soft halo — record, stop, or enable the
/// microphone. [tooltip] is also its accessibility label.
class _RoundMicButton extends StatelessWidget {
  const _RoundMicButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
    this.onColor,
    this.halo,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;
  final Color? onColor;
  final Color? halo;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppTokens>()!;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: halo ?? tokens.primaryInkTint,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Material(
              color: color ?? tokens.primaryInk,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: SizedBox.square(
                  dimension: 80,
                  child: Icon(
                    icon,
                    size: 36,
                    color: onColor ?? tokens.onPrimaryInk,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A collapsed "Show useful phrases" toggle that reveals the lesson's
/// phrases — help the learner opts into, never shown by default, so a
/// speaking answer isn't scaffolded unless they ask.
class _UsefulPhrases extends StatefulWidget {
  const _UsefulPhrases({required this.phrases});

  final List<String> phrases;

  @override
  State<_UsefulPhrases> createState() => _UsefulPhrasesState();
}

class _UsefulPhrasesState extends State<_UsefulPhrases> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => setState(() => _open = !_open),
            icon: Icon(
              _open
                  ? Icons.expand_less_rounded
                  : Icons.lightbulb_outline_rounded,
            ),
            label: Text(
              _open ? l10n.speakHideUsefulPhrases : l10n.speakShowUsefulPhrases,
            ),
          ),
        ),
        if (_open)
          DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: tokens.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < widget.phrases.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: tokens.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.sm,
                    ),
                    child: PhraseText(
                      widget.phrases[i],
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
