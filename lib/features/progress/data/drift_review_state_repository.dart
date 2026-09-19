import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/database.dart';
import '../domain/repositories/review_state_repository.dart';

class DriftReviewStateRepository implements ReviewStateRepository {
  DriftReviewStateRepository(this._db, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  @override
  Future<VocabularyReviewStateData?> vocabularyState({
    required int learnerId,
    String? lexiconId,
    String? chunkId,
  }) {
    assert(
      (lexiconId == null) != (chunkId == null),
      'exactly one of lexiconId/chunkId must be set',
    );
    final query = _db.select(_db.vocabularyReviewState)
      ..where((t) => t.learnerId.equals(learnerId));
    if (lexiconId != null) {
      query.where((t) => t.lexiconId.equals(lexiconId));
    } else {
      query.where((t) => t.chunkId.equals(chunkId!));
    }
    return query.getSingleOrNull();
  }

  @override
  Future<void> setVocabularyFavorite({
    required int learnerId,
    String? lexiconId,
    String? chunkId,
    required bool isFavorite,
  }) async {
    final now = DateTime.now();
    final existing = await vocabularyState(
      learnerId: learnerId,
      lexiconId: lexiconId,
      chunkId: chunkId,
    );
    if (existing == null) {
      await _db
          .into(_db.vocabularyReviewState)
          .insert(
            VocabularyReviewStateCompanion.insert(
              uuid: _uuid.v4(),
              learnerId: learnerId,
              lexiconId: Value(lexiconId),
              chunkId: Value(chunkId),
              isFavorite: Value(isFavorite),
              updatedAt: now,
            ),
          );
    } else {
      await (_db.update(
        _db.vocabularyReviewState,
      )..where((t) => t.id.equals(existing.id))).write(
        VocabularyReviewStateCompanion(
          isFavorite: Value(isFavorite),
          updatedAt: Value(now),
        ),
      );
    }
  }

  @override
  Future<List<VocabularyReviewStateData>> allVocabularyState({
    required int learnerId,
  }) {
    return (_db.select(
      _db.vocabularyReviewState,
    )..where((t) => t.learnerId.equals(learnerId))).get();
  }

  @override
  Future<void> upsertVocabularyReviewOutcome({
    required int learnerId,
    String? lexiconId,
    String? chunkId,
    required double easeFactor,
    required int intervalDays,
    required int repetitions,
    required DateTime dueAt,
    required String confidenceMarker,
  }) async {
    final now = DateTime.now();
    final existing = await vocabularyState(
      learnerId: learnerId,
      lexiconId: lexiconId,
      chunkId: chunkId,
    );
    if (existing == null) {
      await _db
          .into(_db.vocabularyReviewState)
          .insert(
            VocabularyReviewStateCompanion.insert(
              uuid: _uuid.v4(),
              learnerId: learnerId,
              lexiconId: Value(lexiconId),
              chunkId: Value(chunkId),
              easeFactor: Value(easeFactor),
              intervalDays: Value(intervalDays),
              repetitions: Value(repetitions),
              dueAt: Value(dueAt),
              lastReviewedAt: Value(now),
              confidenceMarker: Value(confidenceMarker),
              updatedAt: now,
            ),
          );
    } else {
      await (_db.update(
        _db.vocabularyReviewState,
      )..where((t) => t.id.equals(existing.id))).write(
        VocabularyReviewStateCompanion(
          easeFactor: Value(easeFactor),
          intervalDays: Value(intervalDays),
          repetitions: Value(repetitions),
          dueAt: Value(dueAt),
          lastReviewedAt: Value(now),
          confidenceMarker: Value(confidenceMarker),
          updatedAt: Value(now),
        ),
      );
    }
  }

  @override
  Future<void> enrollVocabulary({
    required int learnerId,
    required List<String> lexiconIds,
    required List<String> chunkIds,
    required DateTime dueAt,
  }) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      for (final (lexiconId, chunkId) in [
        for (final id in lexiconIds) (id, null),
        for (final id in chunkIds) (null, id),
      ]) {
        final existing = await vocabularyState(
          learnerId: learnerId,
          lexiconId: lexiconId,
          chunkId: chunkId,
        );
        if (existing == null) {
          await _db
              .into(_db.vocabularyReviewState)
              .insert(
                VocabularyReviewStateCompanion.insert(
                  uuid: _uuid.v4(),
                  learnerId: learnerId,
                  lexiconId: Value(lexiconId),
                  chunkId: Value(chunkId),
                  dueAt: Value(dueAt),
                  updatedAt: now,
                ),
              );
        } else if (existing.dueAt == null) {
          await (_db.update(
            _db.vocabularyReviewState,
          )..where((t) => t.id.equals(existing.id))).write(
            VocabularyReviewStateCompanion(
              dueAt: Value(dueAt),
              updatedAt: Value(now),
            ),
          );
        }
      }
    });
  }

  @override
  Future<List<VocabularyReviewStateData>> dueVocabulary({
    required int learnerId,
    required DateTime asOf,
  }) {
    return (_db.select(_db.vocabularyReviewState)..where(
          (t) =>
              t.learnerId.equals(learnerId) &
              t.dueAt.isSmallerOrEqualValue(asOf),
        ))
        .get();
  }

  @override
  Future<GrammarReviewStateData?> grammarState({
    required int learnerId,
    required String grammarId,
  }) {
    return (_db.select(_db.grammarReviewState)..where(
          (t) => t.learnerId.equals(learnerId) & t.grammarId.equals(grammarId),
        ))
        .getSingleOrNull();
  }

  @override
  Future<List<GrammarReviewStateData>> allGrammarState({
    required int learnerId,
  }) {
    return (_db.select(
      _db.grammarReviewState,
    )..where((t) => t.learnerId.equals(learnerId))).get();
  }

  @override
  Future<void> setGrammarFavorite({
    required int learnerId,
    required String grammarId,
    required bool isFavorite,
  }) async {
    final now = DateTime.now();
    final existing = await grammarState(
      learnerId: learnerId,
      grammarId: grammarId,
    );
    if (existing == null) {
      await _db
          .into(_db.grammarReviewState)
          .insert(
            GrammarReviewStateCompanion.insert(
              uuid: _uuid.v4(),
              learnerId: learnerId,
              grammarId: grammarId,
              isFavorite: Value(isFavorite),
              updatedAt: now,
            ),
          );
    } else {
      await (_db.update(
        _db.grammarReviewState,
      )..where((t) => t.id.equals(existing.id))).write(
        GrammarReviewStateCompanion(
          isFavorite: Value(isFavorite),
          updatedAt: Value(now),
        ),
      );
    }
  }

  @override
  Future<void> markGrammarReviewed({
    required int learnerId,
    required String grammarId,
  }) async {
    final now = DateTime.now();
    final existing = await grammarState(
      learnerId: learnerId,
      grammarId: grammarId,
    );
    if (existing == null) {
      await _db
          .into(_db.grammarReviewState)
          .insert(
            GrammarReviewStateCompanion.insert(
              uuid: _uuid.v4(),
              learnerId: learnerId,
              grammarId: grammarId,
              markedReviewedAt: Value(now),
              updatedAt: now,
            ),
          );
    } else {
      await (_db.update(
        _db.grammarReviewState,
      )..where((t) => t.id.equals(existing.id))).write(
        GrammarReviewStateCompanion(
          markedReviewedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    }
  }
}
