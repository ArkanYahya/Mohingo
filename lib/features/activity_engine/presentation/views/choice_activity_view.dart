import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../content/models/activity.dart';
import '../../../../content/models/media_specification.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/media/scene_diagram.dart';
import '../../../../core/theme/feedback_theme_extension.dart';
import '../../../../data/local/database.dart' show ActivityAttempt;
import '../../../speech/domain/text_to_speech_service.dart';
import '../../../speech/presentation/listen_button.dart';
import '../../../speech/providers/speech_providers.dart';
import '../../domain/activity_submission.dart';
import '../../domain/sound_effects_service.dart';
import '../../providers/sound_effects_providers.dart';
import '../activity_chrome.dart';

/// Renders `audioChoice` and `textChoice` activities — a prompt plus a
/// single-answer option list. Both types share this widget since their
/// shapes only differ in whether audio (read via on-device TTS once
/// Phase 8's speech layer exists — see [_AudioTranscriptCard]) or source
/// text backs the prompt.
///
/// When the bundle marks `optionMode: "media"` (verified present in the
/// real A1-U2 data — picture-choice items), each option string is a
/// [MediaSpecification] key, not display text, and is rendered via
/// [SceneDiagram] instead of a text button.
class ChoiceActivityView extends ConsumerStatefulWidget {
  ChoiceActivityView.audioChoice({
    required AudioChoiceActivity activity,
    required this.onSubmitted,
    this.mediaByKey = const {},
    this.reviewAttempt,
    Random? random,
    super.key,
  }) : prompt = activity.prompt,
       promptAr = activity.promptAr,
       options = activity.options,
       answer = activity.answer,
       audioTranscript = activity.audioTranscript,
       isMediaOptions = activity.raw['optionMode'] == 'media',
       _random = random ?? Random();

  ChoiceActivityView.textChoice({
    required TextChoiceActivity activity,
    required this.onSubmitted,
    this.mediaByKey = const {},
    this.reviewAttempt,
    Random? random,
    super.key,
  }) : prompt = activity.prompt,
       promptAr = activity.promptAr,
       options = activity.options,
       answer = activity.answer,
       audioTranscript = null,
       isMediaOptions = activity.raw['optionMode'] == 'media',
       _random = random ?? Random();

  final String prompt;
  final String? promptAr;
  final List<String> options;
  final String answer;
  final String? audioTranscript;
  final bool isMediaOptions;
  final Map<String, MediaSpecification> mediaByKey;
  final OnActivitySubmitted onSubmitted;

  /// Used once, at first build, to shuffle [options] for display — see
  /// [_ChoiceActivityViewState._displayOptions]. Injectable so a test can
  /// assert on a deterministic shuffle order; production call sites always
  /// omit it, getting a genuinely random order on every mount (`Random()`
  /// with no seed).
  final Random _random;

  /// When non-null, this view renders read-only straight into its submitted
  /// state, seeded from this recorded attempt — never live-interactive, and
  /// [reviewAttempt].isCorrect/.score are trusted verbatim, never
  /// recomputed. See docs/superpowers/specs/
  /// 2026-09-09-lesson-answer-review-design.md.
  final ActivityAttempt? reviewAttempt;

  @override
  ConsumerState<ChoiceActivityView> createState() => _ChoiceActivityViewState();
}

class _ChoiceActivityViewState extends ConsumerState<ChoiceActivityView> {
  String? _selected;
  ActivitySubmission? _submission;

  /// [widget.options] shuffled once per mount — real A1 content puts the
  /// correct answer as option 0 in 95% of choice activities, so rendering
  /// the bundle's raw order would make the answer guessable without
  /// understanding the content. Computed once (`late final`) so it stays
  /// stable across this instance's own rebuilds (e.g. after selecting an
  /// option) — only a fresh mount (a genuine new attempt, e.g. on replay)
  /// reshuffles.
  late final List<String> _displayOptions = List<String>.from(widget.options)
    ..shuffle(widget._random);

  @override
  void initState() {
    super.initState();
    final reviewAttempt = widget.reviewAttempt;
    if (reviewAttempt == null) return;
    _selected = _decodeSelection(reviewAttempt.rawAnswer);
    _submission = ActivitySubmission(
      correctness: switch (reviewAttempt.isCorrect) {
        true => ActivityCorrectness.correct,
        false => ActivityCorrectness.incorrect,
        null => ActivityCorrectness.notAutoGraded,
      },
      score: reviewAttempt.score,
      rawAnswerJson: reviewAttempt.rawAnswer,
    );
  }

  String? _decodeSelection(String? rawAnswer) {
    if (rawAnswer == null) return null;
    try {
      final decoded = jsonDecode(rawAnswer);
      return decoded is String ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  /// A single tap is a complete answer for this activity type, so
  /// selecting an option submits it immediately — no separate Check tap.
  void _selectAndSubmit(String option) {
    setState(() => _selected = option);
    _submit();
  }

  void _submit() {
    if (_selected == null || _submission != null) return;
    final isCorrect = _selected == widget.answer;
    final submission = ActivitySubmission(
      correctness: isCorrect
          ? ActivityCorrectness.correct
          : ActivityCorrectness.incorrect,
      score: isCorrect ? 1.0 : 0.0,
      rawAnswerJson: jsonEncode(_selected),
    );
    setState(() => _submission = submission);
    widget.onSubmitted(submission);
    playFeedbackSoundSafely(
      ref.read(soundEffectsServiceProvider),
      isCorrect
          ? ActivityFeedbackSound.correct
          : ActivityFeedbackSound.incorrect,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ActivityChrome(
      prompt: widget.prompt,
      promptAr: widget.promptAr,
      help: widget.audioTranscript != null
          ? _AudioTranscriptCard(
              transcript: widget.audioTranscript!,
              // Never in review mode: a review screen can show several of
              // these at once, and none of them is a live listening
              // exercise the learner is being asked to do right now.
              autoPlay: widget.reviewAttempt == null,
            )
          : null,
      body: widget.isMediaOptions
          ? _MediaOptionGrid(
              options: _displayOptions,
              mediaByKey: widget.mediaByKey,
              selected: _selected,
              submitted: _submission != null,
              correctOption: widget.answer,
              onSelected: _submission == null ? _selectAndSubmit : null,
            )
          : _TextOptionList(
              options: _displayOptions,
              selected: _selected,
              submitted: _submission != null,
              correctOption: widget.answer,
              onSelected: _submission == null ? _selectAndSubmit : null,
            ),
      // No Check button is ever reached in practice: a single tap is a
      // complete answer, so `_selectAndSubmit` above always submits before
      // this would render — kept as a safety net, matching the shared
      // ActivitySubmitOrFeedback contract every activity view uses.
      feedback: ActivitySubmitOrFeedback(
        submission: _submission,
        canSubmit: _selected != null,
        onSubmit: _submit,
        correctAnswerLabel: widget.answer,
      ),
    );
  }
}

/// Plays [transcript] aloud via on-device TTS ([ListenButton]) — the
/// bundle ships no pre-recorded audio, so this transcript is the only
/// source for what a listening activity's audio actually says.
///
/// The transcript text stays hidden by default — showing it defeats the
/// point of a listening exercise — but the learner can reveal it manually
/// at any time via [AppLocalizations.activityShowTranscript]. It also
/// auto-reveals the moment the TTS engine reports a playback error: an
/// unavailable/silent TTS engine (see docs/TESTING.md — not verified on a
/// real device) must never leave the activity unusable.
class _AudioTranscriptCard extends ConsumerStatefulWidget {
  const _AudioTranscriptCard({required this.transcript, this.autoPlay = false});

  final String transcript;
  final bool autoPlay;

  @override
  ConsumerState<_AudioTranscriptCard> createState() =>
      _AudioTranscriptCardState();
}

class _AudioTranscriptCardState extends ConsumerState<_AudioTranscriptCard> {
  bool _revealed = false;
  StreamSubscription<TtsPlaybackState>? _playbackSubscription;

  @override
  void initState() {
    super.initState();
    _playbackSubscription = ref
        .read(textToSpeechServiceProvider)
        .playbackState
        .listen((state) {
          if (state == TtsPlaybackState.error && mounted) {
            setState(() => _revealed = true);
          }
        });
  }

  @override
  void dispose() {
    _playbackSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          ListenButton(text: widget.transcript, autoPlay: widget.autoPlay),
          const SizedBox(width: 4),
          Expanded(
            child: _revealed
                ? Text(
                    widget.transcript,
                    textDirection: TextDirection.ltr,
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                : TextButton(
                    onPressed: () => setState(() => _revealed = true),
                    child: Text(l10n.activityShowTranscript),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TextOptionList extends StatelessWidget {
  const _TextOptionList({
    required this.options,
    required this.selected,
    required this.submitted,
    required this.correctOption,
    required this.onSelected,
  });

  final List<String> options;
  final String? selected;
  final bool submitted;
  final String correctOption;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final feedbackTheme = Theme.of(context).extension<FeedbackTheme>()!;
    return Column(
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _OptionTile(
              label: option,
              selected: selected == option,
              // Never reveal correctness before submission — see
              // docs/ARCHITECTURE.md's non-negotiable rules.
              state: !submitted
                  ? _OptionState.neutral
                  : option == correctOption
                  ? _OptionState.correct
                  : (option == selected
                        ? _OptionState.incorrect
                        : _OptionState.neutral),
              colorScheme: colorScheme,
              feedbackTheme: feedbackTheme,
              onTap: onSelected == null ? null : () => onSelected!(option),
            ),
          ),
      ],
    );
  }
}

class _MediaOptionGrid extends StatelessWidget {
  const _MediaOptionGrid({
    required this.options,
    required this.mediaByKey,
    required this.selected,
    required this.submitted,
    required this.correctOption,
    required this.onSelected,
  });

  final List<String> options;
  final Map<String, MediaSpecification> mediaByKey;
  final String? selected;
  final bool submitted;
  final String correctOption;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final feedbackTheme = Theme.of(context).extension<FeedbackTheme>()!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          _MediaOptionCard(
            mediaKey: option,
            spec: mediaByKey[option],
            selected: selected == option,
            state: !submitted
                ? _OptionState.neutral
                : option == correctOption
                ? _OptionState.correct
                : (option == selected
                      ? _OptionState.incorrect
                      : _OptionState.neutral),
            colorScheme: colorScheme,
            feedbackTheme: feedbackTheme,
            onTap: onSelected == null ? null : () => onSelected!(option),
          ),
      ],
    );
  }
}

class _MediaOptionCard extends StatelessWidget {
  const _MediaOptionCard({
    required this.mediaKey,
    required this.spec,
    required this.selected,
    required this.state,
    required this.colorScheme,
    required this.feedbackTheme,
    required this.onTap,
  });

  final String mediaKey;
  final MediaSpecification? spec;
  final bool selected;
  final _OptionState state;
  final ColorScheme colorScheme;
  final FeedbackTheme feedbackTheme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor(colorScheme), width: 2),
          color: colorScheme.surfaceContainer,
        ),
        child: spec != null
            ? SceneDiagram(spec: spec!)
            : Center(
                child: Text(
                  mediaKey,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
      ),
    );
  }

  Color _borderColor(ColorScheme colorScheme) => switch (state) {
    // "Correct" reads as the universal semantic green, not the learner's
    // chosen brand colour — see FeedbackTheme.
    _OptionState.correct => feedbackTheme.success,
    _OptionState.incorrect => colorScheme.error,
    _OptionState.neutral =>
      selected ? colorScheme.primary : colorScheme.outlineVariant,
  };
}

enum _OptionState { neutral, correct, incorrect }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.state,
    required this.colorScheme,
    required this.feedbackTheme,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final _OptionState state;
  final ColorScheme colorScheme;
  final FeedbackTheme feedbackTheme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (Color fill, Color onFill, IconData? icon) = switch (state) {
      // "Correct" reads as the universal semantic green, not the learner's
      // chosen brand colour — see FeedbackTheme.
      _OptionState.correct => (
        feedbackTheme.success,
        feedbackTheme.onSuccess,
        Icons.check,
      ),
      _OptionState.incorrect => (
        colorScheme.error,
        colorScheme.onError,
        Icons.close,
      ),
      _OptionState.neutral => (
        selected
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainer,
        colorScheme.onSurface,
        null,
      ),
    };

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected && state == _OptionState.neutral
                  ? colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: onFill),
                ),
              ),
              if (icon != null) Icon(icon, color: onFill, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
