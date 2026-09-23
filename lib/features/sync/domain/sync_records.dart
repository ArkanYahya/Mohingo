import 'dart:convert';

/// A learner's progress as it travels to and from their account: one
/// record per cloud document, independent of both Drift and Firestore.
///
/// Fields are plain Dart values — `String`, `int`, `double`, `bool`,
/// `List<String>`, and `DateTime` (always UTC) — so the Firestore adapter
/// only has to translate `DateTime` to and from its `Timestamp`, and tests
/// can use an in-memory cloud. The schema of each collection is
/// [SyncCollection.fields]; `firestore.rules` enforces the same
/// schema on the server. See docs/API_CONTRACT.md.
class SyncRecord {
  SyncRecord(this.collection, this.docId, Map<String, Object?> fields)
    : fields = Map.unmodifiable(fields);

  final SyncCollection collection;

  /// The document id: the record's natural key, so writing the same record
  /// twice lands on the same document (see [SyncCollection.docIdFor]).
  final String docId;
  final Map<String, Object?> fields;

  /// Parses a downloaded document, or returns null if it doesn't match the
  /// collection's schema — a malformed document is skipped, never applied.
  static SyncRecord? tryParse(
    SyncCollection collection,
    String docId,
    Map<String, Object?> raw,
  ) {
    final fields = <String, Object?>{};
    for (final MapEntry(key: name, value: type) in collection.fields.entries) {
      final value = _coerce(raw[name], type);
      if (value == null && raw[name] != null) return null;
      if (value == null && collection.requiredFields.contains(name)) {
        return null;
      }
      fields[name] = value;
    }
    return SyncRecord(collection, docId, fields);
  }

  /// A stable text form of [fields], used to break exact ties when merging
  /// so every device picks the same winner.
  String get canonical => canonicalEncode(fields);

  @override
  bool operator ==(Object other) =>
      other is SyncRecord &&
      other.collection == collection &&
      other.docId == docId &&
      other.canonical == canonical;

  @override
  int get hashCode => Object.hash(collection, docId, canonical);

  @override
  String toString() => 'SyncRecord(${collection.path}/$docId)';
}

/// The value types a synced field can hold.
enum FieldType { string, integer, decimal, boolean, time, stringList }

/// The per-learner collections under `users/{uid}/`.
///
/// [appendOnly] collections hold records that never change once written
/// (answers, daily-task events), so the two devices' copies are simply
/// combined. The others are merged field by field — see `sync_merge.dart`.
enum SyncCollection {
  attempts(
    'attempts',
    appendOnly: true,
    fields: {
      'uuid': FieldType.string,
      'activityId': FieldType.string,
      'lessonId': FieldType.string,
      'sessionType': FieldType.string,
      'sessionId': FieldType.string,
      'mode': FieldType.string,
      'evidenceSkill': FieldType.string,
      'rawAnswer': FieldType.string,
      'isCorrect': FieldType.boolean,
      'score': FieldType.decimal,
      'criteriaScores': FieldType.string,
      'wasFallback': FieldType.boolean,
      'attemptedAt': FieldType.time,
      'updatedAt': FieldType.time,
      'canDoIds': FieldType.stringList,
    },
    requiredFields: {
      'uuid',
      'activityId',
      'sessionType',
      'mode',
      'evidenceSkill',
      'wasFallback',
      'attemptedAt',
      'updatedAt',
      'canDoIds',
    },
  ),

  /// Placement, Final Mission and Final Assessment attempts, told apart by
  /// `kind`.
  testAttempts(
    'testAttempts',
    appendOnly: false,
    fields: {
      'uuid': FieldType.string,
      'kind': FieldType.string,
      'courseId': FieldType.string,
      'startedAt': FieldType.time,
      'completedAt': FieldType.time,
      'stageReached': FieldType.integer,
      'outcome': FieldType.string,
      'recommendedUnitId': FieldType.string,
      'confidenceSelfReports': FieldType.string,
      'itemSamplingSeed': FieldType.string,
      'stagesCompleted': FieldType.string,
      'sectionResults': FieldType.string,
      'outcomeSummary': FieldType.string,
    },
    requiredFields: {'uuid', 'kind', 'startedAt'},
  ),
  lessonProgress(
    'lessonProgress',
    appendOnly: false,
    fields: {
      'lessonId': FieldType.string,
      'unitId': FieldType.string,
      'state': FieldType.string,
      'lastActivityId': FieldType.string,
      'lastPositionUpdatedAt': FieldType.time,
      'updatedAt': FieldType.time,
    },
    requiredFields: {'lessonId', 'unitId', 'state', 'updatedAt'},
  ),
  vocabularyReview(
    'vocabularyReview',
    appendOnly: false,
    fields: {
      'lexiconId': FieldType.string,
      'chunkId': FieldType.string,
      'isFavorite': FieldType.boolean,
      'favoriteUpdatedAt': FieldType.time,
      'confidenceMarker': FieldType.string,
      'easeFactor': FieldType.decimal,
      'intervalDays': FieldType.integer,
      'repetitions': FieldType.integer,
      'dueAt': FieldType.time,
      'lastReviewedAt': FieldType.time,
      'updatedAt': FieldType.time,
    },
    requiredFields: {
      'isFavorite',
      'easeFactor',
      'intervalDays',
      'repetitions',
      'updatedAt',
    },
  ),
  grammarReview(
    'grammarReview',
    appendOnly: false,
    fields: {
      'grammarId': FieldType.string,
      'isFavorite': FieldType.boolean,
      'favoriteUpdatedAt': FieldType.time,
      'markedReviewedAt': FieldType.time,
      'updatedAt': FieldType.time,
    },
    requiredFields: {'grammarId', 'isFavorite', 'updatedAt'},
  ),
  enrolments(
    'enrolments',
    appendOnly: false,
    fields: {
      'levelId': FieldType.string,
      'courseId': FieldType.string,
      'contentVersion': FieldType.string,
      'enrolledAt': FieldType.time,
      'status': FieldType.string,
      'lastSelectedAt': FieldType.time,
      'unlockedAt': FieldType.time,
    },
    requiredFields: {
      'levelId',
      'courseId',
      'contentVersion',
      'enrolledAt',
      'status',
    },
  ),
  dailyTasks(
    'dailyTasks',
    appendOnly: true,
    fields: {
      'uuid': FieldType.string,
      'taskType': FieldType.string,
      'occurredAt': FieldType.time,
    },
    requiredFields: {'uuid', 'taskType', 'occurredAt'},
  );

  const SyncCollection(
    this.path, {
    required this.appendOnly,
    required this.fields,
    required this.requiredFields,
  });

  /// The collection's name under `users/{uid}/`.
  final String path;
  final bool appendOnly;
  final Map<String, FieldType> fields;
  final Set<String> requiredFields;

  /// The document id for a record of this collection with [fields]: the
  /// uuid for attempts, tests and daily tasks, the curriculum id otherwise.
  /// Ids are URI-encoded so a `/` in a curriculum id can never open a
  /// sub-path.
  String docIdFor(Map<String, Object?> fields) {
    final key = switch (this) {
      attempts || testAttempts || dailyTasks => fields['uuid'],
      lessonProgress => fields['lessonId'],
      vocabularyReview =>
        fields['lexiconId'] != null
            ? 'lexicon:${fields['lexiconId']}'
            : 'chunk:${fields['chunkId']}',
      grammarReview => fields['grammarId'],
      enrolments => fields['levelId'],
    };
    return Uri.encodeComponent(key! as String);
  }
}

Object? _coerce(Object? value, FieldType type) {
  return switch ((type, value)) {
    (_, null) => null,
    (FieldType.string, final String v) => v,
    (FieldType.integer, final int v) => v,
    (FieldType.integer, final double v) when v == v.roundToDouble() =>
      v.toInt(),
    (FieldType.decimal, final num v) => v.toDouble(),
    (FieldType.boolean, final bool v) => v,
    (FieldType.time, final DateTime v) => v.toUtc(),
    (FieldType.stringList, final List<Object?> v)
        when v.every((e) => e is String) =>
      List<String>.unmodifiable(v.cast<String>()),
    _ => null,
  };
}

/// JSON with sorted keys and times as microseconds — equal field maps always
/// encode to the same text.
String canonicalEncode(Map<String, Object?> fields) {
  final keys = fields.keys.toList()..sort();
  return jsonEncode({
    for (final key in keys)
      key: switch (fields[key]) {
        final DateTime t => t.toUtc().microsecondsSinceEpoch,
        final Object? v => v,
      },
  });
}
