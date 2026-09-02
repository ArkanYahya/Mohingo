import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'database.dart';

part 'database_provider.g.dart';

/// The app-lifetime [AppDatabase] instance. Kept alive so the local progress
/// database is opened once, not per screen. See docs/ARCHITECTURE.md.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase.defaults();
  ref.onDispose(db.close);
  return db;
}
