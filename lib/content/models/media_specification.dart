/// One entry from the bundle's `mediaSpecifications` map.
///
/// Two kinds exist in the real bundle: `ttsSource` (text to be read aloud by
/// on-device TTS at runtime — no pre-recorded audio file exists anywhere in
/// the bundle) and 7 structured *scene description* types (`peopleCard`,
/// `personCard`, `peopleMap`, `homePlan`, `objectScene`, `distanceScene`,
/// `apartmentPlan`) describing a diagram to render, not artwork. Typed
/// scene-rendering models are Phase 5 scope (the activity-renderer/diagram
/// work) — this Phase 4 model only carries [type] plus the full original
/// [raw] JSON, so [CourseContentIndex] can index and validate media specs
/// (in particular the `ttsSource` -> activity back-reference) without
/// needing every scene type's exact shape yet. See docs/DATA_MODEL.md.
class MediaSpecification {
  const MediaSpecification({required this.type, required this.raw});

  factory MediaSpecification.fromJson(Map<String, dynamic> json) {
    return MediaSpecification(type: json['type'] as String, raw: json);
  }

  final String type;
  final Map<String, dynamic> raw;

  bool get isTtsSource => type == 'ttsSource';

  /// Only meaningful when [isTtsSource] is true.
  String? get ttsTranscript => raw['transcript'] as String?;
  String? get ttsLocale => raw['locale'] as String?;
  String? get ttsVoiceProfile => raw['voiceProfile'] as String?;

  /// The activity this `ttsSource` entry provides audio for. Only meaningful
  /// when [isTtsSource] is true.
  String? get ttsActivityId => raw['activityId'] as String?;
}
