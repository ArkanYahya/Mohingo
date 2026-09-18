import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../speech/domain/text_to_speech_service.dart';
import '../../../speech/providers/speech_providers.dart';
import '../../../speech/providers/tts_preferences_provider.dart';

/// The audio of a listening question, read by on-device TTS — the bundle
/// ships no recordings, so [transcript] is the only source for what the
/// audio says.
///
/// One large play button, a "Slower" replay at 60% of the learner's
/// speaking-rate setting, and a transcript that stays hidden by default —
/// showing it defeats the point of a listening exercise — until the
/// learner asks for it. It also reveals itself the moment the TTS engine
/// reports a playback error: an unavailable or silent engine (see
/// docs/TESTING.md — not verified on a real device) must never leave the
/// question unanswerable.
class ActivityAudioCard extends ConsumerStatefulWidget {
  const ActivityAudioCard({
    required this.transcript,
    this.autoPlay = false,
    super.key,
  });

  final String transcript;

  /// Plays once on mount, so the audio starts when the question appears.
  final bool autoPlay;

  @override
  ConsumerState<ActivityAudioCard> createState() => _ActivityAudioCardState();
}

class _ActivityAudioCardState extends ConsumerState<ActivityAudioCard> {
  static const _slowFactor = 0.6;

  bool _revealed = false;
  bool _playing = false;
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
    if (widget.autoPlay) _play();
  }

  @override
  void dispose() {
    _playbackSubscription?.cancel();
    super.dispose();
  }

  Future<void> _play({bool slow = false}) async {
    setState(() => _playing = true);
    final rate = ref.read(ttsRatePreferenceProvider);
    try {
      await ref
          .read(textToSpeechServiceProvider)
          .speak(
            widget.transcript,
            localeCode: 'en',
            rate: slow ? rate * _slowFactor : rate,
            pitch: ref.read(ttsPitchPreferenceProvider),
          );
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;

    return Material(
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
            padding: const EdgeInsets.all(AppSpace.sm),
            child: Row(
              children: [
                Tooltip(
                  message: l10n.speechListen,
                  child: Material(
                    color: tokens.primaryInk,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _playing ? null : _play,
                      child: SizedBox.square(
                        dimension: 56,
                        child: Icon(
                          _playing
                              ? Icons.graphic_eq_rounded
                              : Icons.volume_up_rounded,
                          color: tokens.onPrimaryInk,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                // A Wrap, so on a narrow screen or at large text "Slower"
                // drops under the title instead of squeezing it.
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpace.xs,
                    runSpacing: AppSpace.xs,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.activityListenTitle,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: tokens.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.activityListenHint,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: _playing ? null : () => _play(slow: true),
                        icon: const Icon(
                          Icons.slow_motion_video_rounded,
                          size: 18,
                        ),
                        label: Text(l10n.activityListenSlower),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: tokens.textPrimary,
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.sm,
                          ),
                          textStyle: theme.textTheme.labelMedium?.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border),
          if (_revealed)
            Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Text(
                widget.transcript,
                textDirection: TextDirection.ltr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.textPrimary,
                ),
              ),
            )
          else
            InkWell(
              onTap: () => setState(() => _revealed = true),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.subject_rounded,
                        size: 20,
                        color: tokens.primaryInk,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Text(
                          l10n.activityShowTranscript,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: tokens.primaryInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
