import 'package:drift/drift.dart';

/// Append-only log of every curriculum bundle version loaded on-device.
///
/// The id-set snapshots (not the full bundle — content itself is never
/// duplicated into Drift) are what makes detecting removed ids possible when
/// content updates in a future bundle version, without re-parsing history.
/// See docs/DATA_MODEL.md.
class ContentVersions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get contentVersion => text()();
  TextColumn get schemaVersion => text()();
  TextColumn get courseId => text()();
  DateTimeColumn get installedAt => dateTime()();
  TextColumn get unitIdsJson => text()();
  TextColumn get lessonIdsJson => text()();
  TextColumn get activityIdsJson => text()();
  TextColumn get canDoIdsJson => text()();
}
