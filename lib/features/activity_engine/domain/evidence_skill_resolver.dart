import '../../../content/models/activity.dart';
import '../../../content/models/domain_definitions.dart';
import 'activity_submission.dart';

/// The skill an attempt should be recorded as evidence for — normally
/// [Activity.skill], but the bundle's declared `fallbackSkill` when a
/// `speak` activity was answered via its typed accessibility fallback.
///
/// Shared by every screen that records attempts (lesson player, placement
/// test, final mission, final assessment) so the "a fallback never counts
/// as speaking evidence" rule is decided in exactly one place, not
/// re-implemented per call site. See docs/DATA_MODEL.md.
Skill resolveEvidenceSkill(Activity activity, ActivitySubmission submission) {
  if (submission.wasFallback &&
      activity is SpeakActivity &&
      activity.fallbackSkill != null) {
    return Skill.parse(activity.fallbackSkill!);
  }
  return activity.skill;
}
