import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/content/index/course_content_index.dart';
import 'package:mohingo/content/parsing/course_bundle_parser.dart';
import 'package:mohingo/content/providers/course_content_providers.dart';
import 'package:mohingo/data/local/database.dart';
import 'package:mohingo/data/local/database_provider.dart';
import 'package:mohingo/features/activity_engine/domain/evaluation/grammar_check_service.dart';
import 'package:mohingo/features/activity_engine/providers/online_refinement_providers.dart';
import 'package:mohingo/features/lesson_player/presentation/lesson_review_screen.dart';
import 'package:uuid/uuid.dart';

import '../fake_connectivity_service.dart';
import '../fake_grammar_check_service.dart';

CourseContentIndex _realA1Index() {
  final raw = File('assets/content/en/A1/a1-course-bundle.json')
      .readAsStringSync();
  return CourseContentIndex.build(CourseBundleParser.parse(raw));
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test(
    'watching the drainer while already online drains the queue, records a '
    'real attempt, and refreshes the resolved unit\'s cached mastery state',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final index = _realA1Index();
      final learnerId = await db
          .into(db.learners)
          .insert(
            LearnersCompanion.insert(
              uuid: const Uuid().v4(),
              createdAt: DateTime.utc(2026, 9, 8),
            ),
          );
      await db
          .into(db.pendingOnlineRefinements)
          .insert(
            PendingOnlineRefinementsCompanion.insert(
              uuid: const Uuid().v4(),
              learnerId: learnerId,
              activityId: 'A1-U0-L5-A01',
              lessonId: 'A1-U0-L5',
              unitId: 'A1-U0',
              canDoIds: '["A1.U0.INTERACTION.REGISTER_FOR_CLASS"]',
              rawAnswer: 'Hi there!',
              evidenceSkill: 'spokenInteraction',
              mode: 'mastery',
              localScore: 1.0,
              submittedAt: DateTime.utc(2026, 9, 8),
            ),
          );

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider('a1').overrideWith((ref) async => index),
          connectivityServiceProvider.overrideWithValue(
            FakeConnectivityService(online: true),
          ),
          grammarCheckServiceProvider.overrideWithValue(
            FakeGrammarCheckService(
              result: const GrammarCheckResult(errorCount: 0, wordCount: 2),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(pendingRefinementDrainerProvider);
      // The drain, and the async unit-progress refresh it triggers, are
      // both fire-and-forget started at provider creation — give them a
      // few turns to run.
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(await db.select(db.pendingOnlineRefinements).get(), isEmpty);
      final attempts = await (db.select(
        db.activityAttempts,
      )..where((t) => t.activityId.equals('A1-U0-L5-A01'))).get();
      expect(attempts, hasLength(1));

      final unitProgress = await (db.select(
        db.unitProgress,
      )..where((t) => t.unitId.equals('A1-U0'))).get();
      expect(
        unitProgress,
        hasLength(1),
        reason:
            'refreshUnitProgress must have run for A1-U0 as a direct '
            'result of the resolved item — proves onItemResolved is wired, '
            'not just present',
      );
    },
  );

  test('a connectivity-regained event triggers another drain', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final index = _realA1Index();
    final learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: const Uuid().v4(),
            createdAt: DateTime.utc(2026, 9, 8),
          ),
        );
    final connectivity = FakeConnectivityService(online: false);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        courseContentProvider('a1').overrideWith((ref) async => index),
        connectivityServiceProvider.overrideWithValue(connectivity),
        grammarCheckServiceProvider.overrideWithValue(
          FakeGrammarCheckService(
            result: const GrammarCheckResult(errorCount: 0, wordCount: 2),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(pendingRefinementDrainerProvider);
    await Future<void>.delayed(Duration.zero);

    // Enqueue only after the drainer is already listening, then simulate
    // coming online.
    await db
        .into(db.pendingOnlineRefinements)
        .insert(
          PendingOnlineRefinementsCompanion.insert(
            uuid: const Uuid().v4(),
            learnerId: learnerId,
            activityId: 'A1-U0-L5-A01',
            lessonId: 'A1-U0-L5',
            unitId: 'A1-U0',
            canDoIds: '[]',
            rawAnswer: 'answer',
            evidenceSkill: 'spokenInteraction',
            mode: 'mastery',
            localScore: 1.0,
            submittedAt: DateTime.utc(2026, 9, 8),
          ),
        );
    connectivity.setOnline(true);
    for (var i = 0; i < 4; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    final remaining = await db.select(db.pendingOnlineRefinements).get();
    expect(remaining, isEmpty);
  });

  test(
    'a device that is never online still resolves a queued row via the '
    'bounded local-only fallback — the drain is not gated on connectivity',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final index = _realA1Index();
      final learnerId = await db
          .into(db.learners)
          .insert(
            LearnersCompanion.insert(
              uuid: const Uuid().v4(),
              createdAt: DateTime.utc(2026, 9, 8),
            ),
          );
      await db
          .into(db.pendingOnlineRefinements)
          .insert(
            PendingOnlineRefinementsCompanion.insert(
              uuid: const Uuid().v4(),
              learnerId: learnerId,
              activityId: 'A1-U0-L5-A01',
              lessonId: 'A1-U0-L5',
              unitId: 'A1-U0',
              canDoIds: '[]',
              rawAnswer: '"Hi there!"',
              evidenceSkill: 'spokenInteraction',
              mode: 'mastery',
              localScore: 0.8,
              // Old enough to be past the drain service's age bound, so
              // the very first failed check finalizes it locally.
              submittedAt: DateTime.now().subtract(const Duration(days: 30)),
            ),
          );

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider('a1').overrideWith((ref) async => index),
          // Offline for the whole test — never comes online, never fires an
          // onlineChanges event.
          connectivityServiceProvider.overrideWithValue(
            FakeConnectivityService(online: false),
          ),
          grammarCheckServiceProvider.overrideWithValue(
            FakeGrammarCheckService(
              failure: const GrammarCheckUnavailableException('offline'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(pendingRefinementDrainerProvider);
      await _settle();

      expect(await db.select(db.pendingOnlineRefinements).get(), isEmpty);
      final attempts = await db.select(db.activityAttempts).get();
      expect(
        attempts,
        hasLength(1),
        reason:
            'the bounded local-only fallback lives inside drainOnce(), so a '
            'never-online device must still reach it',
      );
      expect(attempts.single.score, 0.8); // local-only score, unrefined
    },
  );

  test(
    'a resolved queued item invalidates the lesson review screen\'s cached '
    'attempts, so a learner who opened review while grading was still in '
    'flight sees the freshly-resolved result rather than a stale one',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final index = _realA1Index();
      final learnerId = await db
          .into(db.learners)
          .insert(
            LearnersCompanion.insert(
              uuid: const Uuid().v4(),
              createdAt: DateTime.utc(2026, 9, 8),
            ),
          );
      await db
          .into(db.pendingOnlineRefinements)
          .insert(
            PendingOnlineRefinementsCompanion.insert(
              uuid: const Uuid().v4(),
              learnerId: learnerId,
              activityId: 'A1-U0-L5-A01',
              lessonId: 'A1-U0-L5',
              unitId: 'A1-U0',
              canDoIds: '["A1.U0.INTERACTION.REGISTER_FOR_CLASS"]',
              rawAnswer: 'Hi there!',
              evidenceSkill: 'spokenInteraction',
              mode: 'mastery',
              localScore: 1.0,
              submittedAt: DateTime.utc(2026, 9, 8),
            ),
          );

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          courseContentProvider('a1').overrideWith((ref) async => index),
          connectivityServiceProvider.overrideWithValue(
            FakeConnectivityService(online: true),
          ),
          grammarCheckServiceProvider.overrideWithValue(
            FakeGrammarCheckService(
              result: const GrammarCheckResult(errorCount: 0, wordCount: 2),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Read (and cache) the review screen's attempts BEFORE the item
      // resolves — mirrors a learner opening LessonReviewScreen while the
      // answer is still queued.
      final before = await container.read(
        lessonReviewAttemptsProvider((
          learnerId: learnerId,
          lessonId: 'A1-U0-L5',
        )).future,
      );
      expect(before, isEmpty);

      container.read(pendingRefinementDrainerProvider);
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      final after = await container.read(
        lessonReviewAttemptsProvider((
          learnerId: learnerId,
          lessonId: 'A1-U0-L5',
        )).future,
      );
      expect(
        after.map((a) => a.activityId),
        contains('A1-U0-L5-A01'),
        reason:
            'the cached provider must reflect the freshly-resolved attempt, '
            'not the stale empty read from before the drain',
      );
    },
  );

  test('two overlapping drains record the queued answer only once — the '
      're-entrancy guard', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final index = _realA1Index();
    final learnerId = await db
        .into(db.learners)
        .insert(
          LearnersCompanion.insert(
            uuid: const Uuid().v4(),
            createdAt: DateTime.utc(2026, 9, 8),
          ),
        );
    await db
        .into(db.pendingOnlineRefinements)
        .insert(
          PendingOnlineRefinementsCompanion.insert(
            uuid: const Uuid().v4(),
            learnerId: learnerId,
            activityId: 'A1-U0-L5-A01',
            lessonId: 'A1-U0-L5',
            unitId: 'A1-U0',
            canDoIds: '[]',
            rawAnswer: '"Hi there!"',
            evidenceSkill: 'spokenInteraction',
            mode: 'mastery',
            localScore: 1.0,
            submittedAt: DateTime.utc(2026, 9, 8),
          ),
        );

    final connectivity = FakeConnectivityService(online: true);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        courseContentProvider('a1').overrideWith((ref) async => index),
        connectivityServiceProvider.overrideWithValue(connectivity),
        grammarCheckServiceProvider.overrideWithValue(
          FakeGrammarCheckService(
            result: const GrammarCheckResult(errorCount: 0, wordCount: 2),
            // Long enough that a second trigger lands while the first
            // drain is still awaiting its check — the real wifi-to-mobile
            // handoff window.
            delay: const Duration(milliseconds: 200),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Trigger one: provider creation. Trigger two: a connectivity-regained
    // event fired while that first drain is still in flight.
    container.read(pendingRefinementDrainerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    connectivity.setOnline(true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await _settle();

    expect(await db.select(db.pendingOnlineRefinements).get(), isEmpty);
    expect(
      await db.select(db.activityAttempts).get(),
      hasLength(1),
      reason:
          'both drains would otherwise snapshot the same queue row and '
          'record the same answer as mastery evidence twice',
    );
  });
}

/// Both drain triggers are fire-and-forget, and a resolved item then runs
/// an async unit-progress refresh — give the microtask queue enough turns
/// for all of it to finish.
Future<void> _settle({int turns = 30}) async {
  for (var i = 0; i < turns; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
