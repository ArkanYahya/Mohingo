import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/content_text.dart';
import '../../../speech/domain/audio_clip_index.dart';
import '../../../speech/domain/text_to_speech_service.dart';
import '../../../speech/providers/speech_providers.dart';
import '../../../speech/providers/tts_preferences_provider.dart';

/// What the other person in a speaking task says, before the learner
/// answers: each line in English, read aloud in order when the question
/// opens (never in answer review — see [autoPlay]), with a button to hear
/// them again. Spoken interaction means responding to someone; this is the
/// someone. Shown in test mode too: it's the task's input, not its answer.
class ActivityPartnerTurnsCard extends ConsumerStatefulWidget {
  const ActivityPartnerTurnsCard({
    required this.turns,
    this.autoPlay = true,
    super.key,
  });

  final List<String> turns;

  /// False on a review screen, which can show several at once and where
  /// nothing is being asked right now.
  final bool autoPlay;

  @override
  ConsumerState<ActivityPartnerTurnsCard> createState() =>
      _ActivityPartnerTurnsCardState();
}

class _ActivityPartnerTurnsCardState
    extends ConsumerState<ActivityPartnerTurnsCard> {
  late final TextToSpeechService _tts = ref.read(textToSpeechServiceProvider);
  bool _playing = false;

  /// Bumped to cancel a reading in progress — a newer request wins.
  int _playToken = 0;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _play();
      });
    }
  }

  @override
  void dispose() {
    _playToken++;
    if (_playing) _tts.stop();
    super.dispose();
  }

  Future<void> _play() async {
    final token = ++_playToken;
    if (_playing) await _tts.stop();
    if (!mounted || token != _playToken) return;
    setState(() => _playing = true);
    final rate = ref.read(ttsRatePreferenceProvider);
    final pitch = ref.read(ttsPitchPreferenceProvider);
    for (final turn in widget.turns) {
      if (!mounted || token != _playToken) return;
      await _tts.speak(
        turn,
        localeCode: 'en',
        rate: rate,
        pitch: pitch,
        speaker: kPartnerSpeaker,
      );
    }
    if (mounted && token == _playToken) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpace.md,
          AppSpace.xs,
          AppSpace.xs,
          AppSpace.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.speakPartnerTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _play,
                  tooltip: l10n.speakPartnerPlay,
                  icon: Icon(
                    _playing ? Icons.volume_up : Icons.volume_up_outlined,
                  ),
                ),
              ],
            ),
            for (final turn in widget.turns) ...[
              ContentText.en(
                turn,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpace.xxs),
            ],
          ],
        ),
      ),
    );
  }
}
