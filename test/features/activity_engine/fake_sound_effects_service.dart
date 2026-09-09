import 'package:mohingo/features/activity_engine/domain/sound_effects_service.dart';

/// Records every [play] call instead of touching a real platform audio
/// engine, which has no platform channel to answer in `flutter test`. See
/// docs/TESTING.md.
class FakeSoundEffectsService implements SoundEffectsService {
  final List<ActivityFeedbackSound> played = [];

  @override
  Future<void> play(ActivityFeedbackSound sound) async {
    played.add(sound);
  }
}
