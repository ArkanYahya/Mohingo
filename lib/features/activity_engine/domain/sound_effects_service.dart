import 'dart:async';
import 'dart:developer' as developer;

/// Which short feedback sound to play when a live submission resolves.
enum ActivityFeedbackSound { correct, incorrect }

/// Plays a short feedback sound the moment a live activity submission
/// resolves to [ActivityFeedbackSound.correct]/`.incorrect` — never for a
/// `notAutoGraded` result (nothing to celebrate or flag), and never in
/// review mode (nothing was just submitted). Called from each activity
/// view's own `_submit()`, the one place that already knows a live
/// submission just happened. See docs/ARCHITECTURE.md's platform-service
/// seam pattern — same shape as `TextToSpeechService`.
abstract interface class SoundEffectsService {
  Future<void> play(ActivityFeedbackSound sound);
}

/// Plays [sound] via [service] fire-and-forget, swallowing any failure —
/// same rationale as `PendingRefinementDrainer.triggerDrain()`: a sound
/// effect is cosmetic, and a missing platform audio engine or permissions
/// issue must never crash the app or block the activity flow that's
/// already moved on. Call this from every activity view's `_submit()`
/// rather than calling [SoundEffectsService.play] directly.
void playFeedbackSoundSafely(
  SoundEffectsService service,
  ActivityFeedbackSound sound,
) {
  unawaited(
    service.play(sound).catchError((Object error, StackTrace stackTrace) {
      developer.log(
        'Sound effect playback failed',
        name: 'mohingo.audio',
        error: error,
        stackTrace: stackTrace,
      );
    }),
  );
}
