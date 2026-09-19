import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../content/models/activity.dart';
import '../../../../content/models/media_specification.dart';
import '../../../../core/media/scene_diagram.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../data/local/database.dart' show ActivityAttempt;
import '../../domain/activity_submission.dart';
import '../../domain/sound_effects_service.dart';
import '../../providers/sound_effects_providers.dart';
import '../activity_chrome.dart';
import '../widgets/activity_audio_card.dart';
import '../widgets/activity_option_tile.dart';
import '../widgets/answer_tile_state.dart';

/// Renders `audioChoice` and `textChoice` activities — a prompt plus a
/// single-answer option list. Both types share this widget since their
/// shapes only differ in whether audio (read via on-device TTS — see
/// [ActivityAudioCard]) or source text backs the prompt.
///
/// Tapping an option selects it; Check submits. The learner can change a
/// mis-tap before committing, the same as every other activity type.
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

  void _select(String option) => setState(() => _selected = option);

  void _submit() {
    if (_selected == null || _submission != null) return;
    final isCorrect = _selected == widget.answer;
    final submission = ActivitySubmission(
      correctness: isCorrect
          ? ActivityCorrectness.correct
          : ActivityCorrectness.incorrect,
      score: isCorrect ? 1.0 : 0.0,
      rawAnswerJson: jsonEncode(_selected),
      correctAnswerLabel: widget.answer,
    );
    setState(() => _submission = submission);
    widget.onSubmitted(submission);
    if (marksAnswers(context)) {
      playFeedbackSoundSafely(
        ref.read(soundEffectsServiceProvider),
        isCorrect
            ? ActivityFeedbackSound.correct
            : ActivityFeedbackSound.incorrect,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitted = _submission != null;
    return ActivityChrome(
      prompt: widget.prompt,
      promptAr: widget.promptAr,
      help: widget.audioTranscript != null
          ? ActivityAudioCard(
              transcript: widget.audioTranscript!,
              // Never in review mode: a review screen can show several of
              // these at once, and none of them is a live listening
              // exercise the learner is being asked to do right now.
              autoPlay: widget.reviewAttempt == null,
            )
          : null,
      body: widget.isMediaOptions
          ? Wrap(
              spacing: AppSpace.xs,
              runSpacing: AppSpace.xs,
              children: [
                for (final option in _displayOptions)
                  _MediaOptionCard(
                    mediaKey: option,
                    spec: widget.mediaByKey[option],
                    state: _stateOf(option),
                    onTap: submitted ? null : () => _select(option),
                  ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final option in _displayOptions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.xs),
                    child: ActivityOptionTile(
                      label: option,
                      state: _stateOf(option),
                      onTap: submitted ? null : () => _select(option),
                    ),
                  ),
              ],
            ),
      feedback: ActivitySubmitOrFeedback(
        submission: _submission,
        canSubmit: _selected != null,
        onSubmit: _submit,
        correctAnswerLabel: widget.answer,
      ),
    );
  }

  /// Never reveals correctness before submission — see
  /// docs/ARCHITECTURE.md's non-negotiable rules.
  AnswerTileState _stateOf(String option) => singleChoiceState(
    // In a test the pick stays selected — never marked.
    submitted: _submission != null && marksAnswers(context),
    isSelected: option == _selected,
    isCorrect: option == widget.answer,
  );
}

/// A picture option — a [SceneDiagram] drawn from the option's
/// [MediaSpecification] — framed like [ActivityOptionTile].
class _MediaOptionCard extends StatelessWidget {
  const _MediaOptionCard({
    required this.mediaKey,
    required this.spec,
    required this.state,
    required this.onTap,
  });

  final String mediaKey;
  final MediaSpecification? spec;
  final AnswerTileState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = answerTileColors(context, state);
    final card = Material(
      color: colors.fill,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: colors.outline, width: colors.outlineWidth),
      ),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 148,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xs),
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
        ),
      ),
    );
    return Semantics(
      selected: state == AnswerTileState.selected,
      inMutuallyExclusiveGroup: true,
      child: state == AnswerTileState.dimmed
          ? Opacity(opacity: 0.5, child: card)
          : card,
    );
  }
}
