import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../content/models/curriculum_structure.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../speech/domain/text_to_speech_service.dart';
import '../../../speech/providers/speech_providers.dart';
import '../../../speech/providers/tts_preferences_provider.dart';
import 'lesson_intro_chrome.dart';

/// The first screen of a lesson that has an encounter conversation: the
/// dialogue the lesson is built around, before any question about it.
///
/// Lines are chat bubbles — the first speaker at the start edge, the
/// second at the end — each with its speaker, its Arabic (behind a switch,
/// on by default) and a tap to hear it. The whole conversation reads aloud
/// once, line by line, when the screen opens; the play button replays or
/// stops it, and the line being read is outlined.
class LessonConversationStep extends ConsumerStatefulWidget {
  const LessonConversationStep({
    required this.overline,
    required this.title,
    required this.titleAr,
    required this.lines,
    this.sceneAr,
    required this.continueLabel,
    required this.onContinue,
    super.key,
  });

  final String overline;
  final String title;
  final String titleAr;
  final List<EncounterDialogueLine> lines;

  /// An optional Arabic description of the scene.
  final String? sceneAr;
  final String continueLabel;
  final VoidCallback onContinue;

  @override
  ConsumerState<LessonConversationStep> createState() =>
      _LessonConversationStepState();
}

class _LessonConversationStepState
    extends ConsumerState<LessonConversationStep> {
  late final TextToSpeechService _tts = ref.read(textToSpeechServiceProvider);
  bool _showArabic = true;
  int? _playingIndex;

  /// Bumped to cancel whatever is playing — a newer request wins.
  int _playToken = 0;

  /// Distinct speakers in order of first appearance: the first gets the
  /// start edge, the second the end edge.
  late final List<String> _speakers = {
    for (final line in widget.lines) line.speaker,
  }.toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _play(from: 0, to: widget.lines.length);
    });
  }

  @override
  void dispose() {
    if (_playingIndex != null) _tts.stop();
    _playToken++;
    super.dispose();
  }

  /// Reads lines [from]..[to) in order, highlighting each as it's read.
  Future<void> _play({required int from, required int to}) async {
    final token = ++_playToken;
    if (_playingIndex != null) await _tts.stop();
    final rate = ref.read(ttsRatePreferenceProvider);
    final pitch = ref.read(ttsPitchPreferenceProvider);
    for (var i = from; i < to; i++) {
      if (!mounted || token != _playToken) return;
      setState(() => _playingIndex = i);
      await _tts.speak(
        widget.lines[i].en,
        localeCode: 'en',
        rate: rate,
        pitch: pitch,
        speaker: widget.lines[i].speaker,
      );
    }
    if (mounted && token == _playToken) setState(() => _playingIndex = null);
  }

  void _stop() {
    _playToken++;
    _tts.stop();
    setState(() => _playingIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final playing = _playingIndex != null;
    final roomy =
        MediaQuery.sizeOf(context).width /
            MediaQuery.textScalerOf(context).scale(1) >=
        340;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.xs,
              AppSpace.md,
              AppSpace.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LessonIntroHeader(
                  overline: widget.overline,
                  title: widget.title,
                  titleAr: widget.titleAr,
                ),
                const SizedBox(height: AppSpace.md),
                Material(
                  color: tokens.card,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    side: BorderSide(color: tokens.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          AppSpace.md,
                          AppSpace.sm,
                          AppSpace.sm,
                          AppSpace.sm,
                        ),
                        child: Row(
                          children: [
                            // Decorative, so they give way first: on a
                            // narrow screen or at large text the title
                            // keeps the room instead of breaking mid-word.
                            if (roomy) ...[
                              _SpeakerAvatars(speakers: _speakers),
                              const SizedBox(width: AppSpace.sm),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.lessonIntroListenTitle,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: tokens.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.lessonIntroListenHint,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: tokens.textSecondary,
                                    ),
                                  ),
                                  if (widget.sceneAr != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.sceneAr!,
                                      textDirection: TextDirection.rtl,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: tokens.textSecondary,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpace.xs),
                            IconButton.filled(
                              onPressed: playing
                                  ? _stop
                                  : () =>
                                        _play(from: 0, to: widget.lines.length),
                              tooltip: playing
                                  ? l10n.lessonIntroStopConversation
                                  : l10n.lessonIntroPlayConversation,
                              style: IconButton.styleFrom(
                                backgroundColor: tokens.primaryInk,
                                foregroundColor: tokens.onPrimaryInk,
                                fixedSize: const Size.square(48),
                              ),
                              icon: Icon(
                                playing
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: tokens.border),
                      MergeSemantics(
                        child: InkWell(
                          onTap: () =>
                              setState(() => _showArabic = !_showArabic),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              AppSpace.md,
                              AppSpace.xxs,
                              AppSpace.sm,
                              AppSpace.xxs,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.translate_rounded,
                                  size: 20,
                                  color: tokens.textSecondary,
                                ),
                                const SizedBox(width: AppSpace.sm),
                                Expanded(
                                  child: Text(
                                    l10n.lessonIntroArabicToggle,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: tokens.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: _showArabic,
                                  onChanged: (value) =>
                                      setState(() => _showArabic = value),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                LayoutBuilder(
                  builder: (context, constraints) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < widget.lines.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpace.sm),
                        _DialogueBubble(
                          line: widget.lines[i],
                          atEnd: _speakers
                              .indexOf(widget.lines[i].speaker)
                              .isOdd,
                          showArabic: _showArabic,
                          playing: _playingIndex == i,
                          maxWidth: constraints.maxWidth * 0.84,
                          onTap: () => _play(from: i, to: i + 1),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        LessonActionBar(
          label: widget.continueLabel,
          onPressed: widget.onContinue,
        ),
      ],
    );
  }
}

/// One or two overlapping initials for the conversation's speakers.
class _SpeakerAvatars extends StatelessWidget {
  const _SpeakerAvatars({required this.speakers});

  final List<String> speakers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    Widget avatar(int index) {
      final second = index.isOdd;
      final name = speakers[index];
      return Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: second ? tokens.primaryInkTint : tokens.cardMuted,
          shape: BoxShape.circle,
          border: Border.all(color: tokens.card, width: 2),
        ),
        child: Text(
          name.isEmpty ? '?' : name.characters.first.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: second ? tokens.primaryInk : tokens.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final shown = speakers.length.clamp(1, 2);
    return ExcludeSemantics(
      child: SizedBox(
        width: 36.0 + (shown - 1) * 26,
        height: 36,
        child: Stack(
          children: [
            for (var i = 0; i < shown; i++)
              PositionedDirectional(start: i * 26.0, child: avatar(i)),
          ],
        ),
      ),
    );
  }
}

/// One line of the conversation as a chat bubble: speaker above, the
/// English line (LTR) and, when shown, its Arabic (RTL) inside. The first
/// speaker's lines sit at the start edge on a card; the second speaker's at
/// the end edge on an ink tint. Tap to hear the line.
class _DialogueBubble extends StatelessWidget {
  const _DialogueBubble({
    required this.line,
    required this.atEnd,
    required this.showArabic,
    required this.playing,
    required this.maxWidth,
    required this.onTap,
  });

  final EncounterDialogueLine line;
  final bool atEnd;
  final bool showArabic;
  final bool playing;
  final double maxWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    const corner = Radius.circular(AppRadius.card);
    const tail = Radius.circular(4);

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: atEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  line.speaker,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpace.xxs),
                Icon(
                  playing ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                  size: 14,
                  color: playing ? tokens.primaryInk : tokens.textSecondary,
                ),
                if (playing) ...[
                  const SizedBox(width: AppSpace.xxs),
                  Text(
                    l10n.lessonIntroPlaying,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: tokens.primaryInk,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xxs),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Material(
              color: atEnd ? tokens.primaryInkTint : tokens.card,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusDirectional.only(
                  topStart: atEnd ? corner : tail,
                  topEnd: atEnd ? tail : corner,
                  bottomStart: corner,
                  bottomEnd: corner,
                ),
                side: playing
                    ? BorderSide(color: tokens.primaryInk, width: 2)
                    : atEnd
                    ? BorderSide.none
                    : BorderSide(color: tokens.border),
              ),
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm + 2,
                    vertical: AppSpace.xs + 2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.en,
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: tokens.textPrimary,
                        ),
                      ),
                      if (showArabic) ...[
                        const SizedBox(height: 2),
                        Text(
                          line.ar,
                          textDirection: TextDirection.rtl,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
