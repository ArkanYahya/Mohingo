import '../../../../data/local/database.dart';

/// Append-only log of every curriculum bundle version loaded on-device.
///
/// The id-set snapshots recorded here (not the full bundle — content is
/// never duplicated into Drift) are what makes detecting removed ids
/// possible when content updates in a future bundle version, without
/// re-parsing history. See docs/DATA_MODEL.md.
abstract interface class ContentVersionRepository {
  /// Records that [contentVersion] was loaded, if not already recorded.
  Future<void> recordIfNew({
    required String contentVersion,
    required String schemaVersion,
    required String courseId,
    required List<String> unitIds,
    required List<String> lessonIds,
    required List<String> activityIds,
    required List<String> canDoIds,
  });

  Future<ContentVersion?> latest({required String courseId});
}
