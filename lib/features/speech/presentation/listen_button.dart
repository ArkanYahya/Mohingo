import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../providers/speech_providers.dart';
import '../providers/tts_preferences_provider.dart';

/// An icon button that reads [text] aloud via the on-device TTS engine.
/// Shared by activity audio prompts and Vocabulary/Grammar pronunciation
/// playback — one place that owns "how does the app speak text out loud".
/// See docs/ARCHITECTURE.md.
class ListenButton extends ConsumerStatefulWidget {
  const ListenButton({
    required this.text,
    this.localeCode = 'en',
    this.autoPlay = false,
    super.key,
  });

  final String text;
  final String localeCode;

  /// When true, plays [text] once automatically on mount — no tap needed.
  /// Used by `_AudioTranscriptCard` (`choice_activity_view.dart`) so a
  /// listening exercise's audio starts the moment the question appears;
  /// every other caller (Vocabulary/Grammar pronunciation) leaves this at
  /// the default `false`, unaffected.
  final bool autoPlay;

  @override
  ConsumerState<ListenButton> createState() => _ListenButtonState();
}

class _ListenButtonState extends ConsumerState<ListenButton> {
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) _play();
  }

  Future<void> _play() async {
    setState(() => _playing = true);
    try {
      await ref
          .read(textToSpeechServiceProvider)
          .speak(
            widget.text,
            localeCode: widget.localeCode,
            rate: ref.read(ttsRatePreferenceProvider),
            pitch: ref.read(ttsPitchPreferenceProvider),
          );
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_playing ? Icons.volume_up : Icons.volume_up_outlined),
      onPressed: _playing ? null : _play,
      tooltip: AppLocalizations.of(context)!.speechListen,
    );
  }
}
