import 'sync_records.dart';

/// Combines two copies of the same record — this device's and the
/// account's — into the one both devices should end up holding.
///
/// Deterministic and order-independent: `merge(a, b)` and `merge(b, a)` are
/// equal, and an exact tie is broken by [SyncRecord.canonical], so two
/// devices merging the same pair always agree. No rule here ever lets an
/// older copy erase what a newer one recorded; where two groups of fields
/// change independently (a word's favourite and its review schedule), each
/// group is taken from whichever copy changed *that group* last. The rules,
/// per collection, are documented in
/// docs/adr/0010-optional-accounts-and-progress-sync.md.
SyncRecord mergeRecords(SyncRecord a, SyncRecord b) {
  assert(a.collection == b.collection && a.docId == b.docId);
  if (a == b) return a;
  final merged = switch (a.collection) {
    // Written once and never changed: both copies are the same answer.
    SyncCollection.attempts ||
    SyncCollection.dailyTasks => _tieBreak(a, b).fields,
    SyncCollection.testAttempts => _mergeTestAttempt(a, b),
    SyncCollection.lessonProgress => _newer(a, b, const [
      'updatedAt',
      'lastPositionUpdatedAt',
    ]).fields,
    SyncCollection.vocabularyReview => _mergeVocabulary(a, b),
    SyncCollection.grammarReview => _mergeGrammar(a, b),
    SyncCollection.enrolments => _mergeEnrolment(a, b),
  };
  return SyncRecord(a.collection, a.docId, merged);
}

/// A finished attempt beats an unfinished one (the attempt was started on
/// one device, and only that device can finish it); otherwise the later
/// finish wins.
Map<String, Object?> _mergeTestAttempt(SyncRecord a, SyncRecord b) {
  final aDone = a.fields['completedAt'] != null;
  final bDone = b.fields['completedAt'] != null;
  if (aDone != bDone) return (aDone ? a : b).fields;
  return _newer(a, b, const ['completedAt', 'startedAt']).fields;
}

/// The review schedule comes from whichever copy was reviewed last; the
/// favourite from whichever copy toggled it last.
Map<String, Object?> _mergeVocabulary(SyncRecord a, SyncRecord b) {
  final schedule = _newer(a, b, const ['lastReviewedAt', 'updatedAt']);
  final favorite = _newer(a, b, const ['favoriteUpdatedAt', 'updatedAt']);
  return {
    ...schedule.fields,
    'isFavorite': favorite.fields['isFavorite'],
    'favoriteUpdatedAt': favorite.fields['favoriteUpdatedAt'],
    'updatedAt': _latest(a.fields['updatedAt'], b.fields['updatedAt']),
  };
}

Map<String, Object?> _mergeGrammar(SyncRecord a, SyncRecord b) {
  final favorite = _newer(a, b, const ['favoriteUpdatedAt', 'updatedAt']);
  return {
    ...favorite.fields,
    'markedReviewedAt': _latest(
      a.fields['markedReviewedAt'],
      b.fields['markedReviewedAt'],
    ),
    'updatedAt': _latest(a.fields['updatedAt'], b.fields['updatedAt']),
  };
}

/// The level was first started at the earlier enrolment (which keeps its
/// course and content version); it was last chosen at the later selection;
/// it was opened early at the earlier unlock.
Map<String, Object?> _mergeEnrolment(SyncRecord a, SyncRecord b) {
  final original = _newer(a, b, const ['enrolledAt']) == a ? b : a;
  return {
    ...original.fields,
    'lastSelectedAt': _latest(
      a.fields['lastSelectedAt'],
      b.fields['lastSelectedAt'],
    ),
    'unlockedAt': _earliest(a.fields['unlockedAt'], b.fields['unlockedAt']),
  };
}

/// The copy whose [keys] (compared in order, a missing time lowest) are
/// later; an exact tie falls to [_tieBreak].
SyncRecord _newer(SyncRecord a, SyncRecord b, List<String> keys) {
  for (final key in keys) {
    final order = _compareTimes(a.fields[key], b.fields[key]);
    if (order != 0) return order > 0 ? a : b;
  }
  return _tieBreak(a, b);
}

SyncRecord _tieBreak(SyncRecord a, SyncRecord b) =>
    a.canonical.compareTo(b.canonical) >= 0 ? a : b;

int _compareTimes(Object? a, Object? b) {
  if (a == null && b == null) return 0;
  if (a == null) return -1;
  if (b == null) return 1;
  return (a as DateTime).compareTo(b as DateTime);
}

Object? _latest(Object? a, Object? b) => _compareTimes(a, b) >= 0 ? a : b;

Object? _earliest(Object? a, Object? b) {
  if (a == null) return b;
  if (b == null) return a;
  return _compareTimes(a, b) <= 0 ? a : b;
}
