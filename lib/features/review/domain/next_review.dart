import '../../../data/local/database.dart';

/// Calendar days from [now] until the soonest word or phrase in [states]
/// comes due — 0 for later today, 1 for tomorrow. Items already due, or
/// never scheduled, don't count; null when nothing is scheduled ahead.
int? daysUntilNextReview(List<VocabularyReviewStateData> states, DateTime now) {
  DateTime? soonest;
  for (final s in states) {
    final due = s.dueAt;
    if (due == null || !due.isAfter(now)) continue;
    if (soonest == null || due.isBefore(soonest)) soonest = due;
  }
  if (soonest == null) return null;
  // Both on the learner's own calendar, counted in UTC so a daylight-saving
  // change between them can't shorten a day.
  final from = now.toLocal();
  final to = soonest.toLocal();
  final today = DateTime.utc(from.year, from.month, from.day);
  final dueDay = DateTime.utc(to.year, to.month, to.day);
  return dueDay.difference(today).inDays;
}
