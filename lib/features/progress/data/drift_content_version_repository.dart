import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../data/local/database.dart';
import '../domain/repositories/content_version_repository.dart';

class DriftContentVersionRepository implements ContentVersionRepository {
  DriftContentVersionRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> recordIfNew({
    required String contentVersion,
    required String schemaVersion,
    required String courseId,
    required List<String> unitIds,
    required List<String> lessonIds,
    required List<String> activityIds,
    required List<String> canDoIds,
  }) async {
    final existing =
        await (_db.select(_db.contentVersions)..where(
              (t) =>
                  t.courseId.equals(courseId) &
                  t.contentVersion.equals(contentVersion),
            ))
            .getSingleOrNull();
    if (existing != null) return;

    await _db
        .into(_db.contentVersions)
        .insert(
          ContentVersionsCompanion.insert(
            contentVersion: contentVersion,
            schemaVersion: schemaVersion,
            courseId: courseId,
            installedAt: DateTime.now(),
            unitIdsJson: jsonEncode(unitIds),
            lessonIdsJson: jsonEncode(lessonIds),
            activityIdsJson: jsonEncode(activityIds),
            canDoIdsJson: jsonEncode(canDoIds),
          ),
        );
  }

  @override
  Future<ContentVersion?> latest({required String courseId}) {
    return (_db.select(_db.contentVersions)
          ..where((t) => t.courseId.equals(courseId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.installedAt),
            // installedAt alone ties when an upgrade records its row in the
            // same clock tick the previous one was read in, and a tie that
            // resolves the wrong way makes the diff compare a version
            // against itself — indistinguishable from "nothing changed".
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(1))
        .getSingleOrNull();
  }
}
