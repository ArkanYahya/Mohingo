import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/activity.dart';
import '../../../content/models/curriculum_structure.dart';
import '../../../content/models/domain_definitions.dart';
import '../../../content/models/media_specification.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../activity_engine/domain/activity_submission.dart';
import '../../activity_engine/domain/evidence_skill_resolver.dart';
import '../../activity_engine/presentation/activity_view_registry.dart';
import '../../learning_path/providers/unit_progress_providers.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';

/// Sequences through one lesson's activities, rendering each via the
/// activity-engine registry, recording every submission, and refreshing
/// unit mastery once the lesson is complete.
///
/// Resume behaviour: if [LessonProgressData.lastActivityId] exists and
/// isn't the lesson's final activity, playback resumes right after it
/// (interrupted mid-lesson). Otherwise — no prior progress, or the lesson
/// was previously finished — playback starts at activity 0; revisiting a
/// finished lesson is a full replay, which appends fresh evidence rather
/// than overwriting history (`ActivityAttemptRepository.recordAttempt` is
/// insert-only). See docs/DATA_MODEL.md.
class LessonPlayerScreen extends ConsumerWidget {
  const LessonPlayerScreen({
    required this.unitId,
    required this.lessonId,
    super.key,
  });

  final String unitId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(courseContentProvider('a1'));
    final learnerAsync = ref.watch(currentLearnerProvider);

    return contentAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (error, _) => _ErrorScaffold(message: '$error'),
      data: (index) {
        final lesson = index.lessonsById[lessonId];
        final unit = index.unitsById[unitId];
        if (lesson == null || unit == null) {
          return const _ErrorScaffold(message: 'Lesson not found');
        }
        return learnerAsync.when(
          loading: () => const _LoadingScaffold(),
          error: (error, _) => _ErrorScaffold(message: '$error'),
          data: (learner) => _LessonPlayerBody(
            unitId: unitId,
            unit: unit,
            lesson: lesson,
            learnerId: learner.id,
            masteryPolicy: index.bundle.domain.masteryPolicy,
            mediaByKey: index.bundle.mediaSpecifications,
          ),
        );
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(message)));
}

class _LessonPlayerBody extends ConsumerStatefulWidget {
  const _LessonPlayerBody({
    required this.unitId,
    required this.unit,
    required this.lesson,
    required this.learnerId,
    required this.masteryPolicy,
    required this.mediaByKey,
  });

  final String unitId;
  final Unit unit;
  final Lesson lesson;
  final int learnerId;
  final MasteryPolicy masteryPolicy;
  final Map<String, MediaSpecification> mediaByKey;

  @override
  ConsumerState<_LessonPlayerBody> createState() => _LessonPlayerBodyState();
}

class _LessonPlayerBodyState extends ConsumerState<_LessonPlayerBody> {
  int? _currentIndex;
  ActivitySubmission? _lastSubmission;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _resolveStartIndex();
  }

  Future<void> _resolveStartIndex() async {
    final repository = ref.read(unitLessonProgressRepositoryProvider);
    final existing = await repository.lessonProgress(
      learnerId: widget.learnerId,
      lessonId: widget.lesson.id,
    );
    final activities = widget.lesson.activities;
    var startIndex = 0;
    final lastActivityId = existing?.lastActivityId;
    if (lastActivityId != null && activities.isNotEmpty) {
      final lastIndex = activities.indexWhere((a) => a.id == lastActivityId);
      if (lastIndex != -1 && lastIndex < activities.length - 1) {
        startIndex = lastIndex + 1;
      }
      // else: lastActivityId was the final activity (lesson previously
      // completed) -> intentional replay from the start.
    }
    if (mounted) setState(() => _currentIndex = startIndex);
  }

  Future<void> _handleSubmitted(
    Activity activity,
    ActivitySubmission submission,
  ) async {
    final evidenceSkill = resolveEvidenceSkill(activity, submission);

    await ref
        .read(activityAttemptRepositoryProvider)
        .recordAttempt(
          learnerId: widget.learnerId,
          activityId: activity.id,
          lessonId: widget.lesson.id,
          sessionType: 'lesson',
          mode: activity.mode,
          evidenceSkill: evidenceSkill,
          canDoIds: activity.canDo,
          rawAnswer: submission.rawAnswerJson,
          isCorrect: switch (submission.correctness) {
            ActivityCorrectness.correct => true,
            ActivityCorrectness.incorrect => false,
            ActivityCorrectness.notAutoGraded => null,
          },
          score: submission.score,
          wasFallback: submission.wasFallback,
        );

    await ref
        .read(unitLessonProgressRepositoryProvider)
        .recordLessonPosition(
          learnerId: widget.learnerId,
          lessonId: widget.lesson.id,
          unitId: widget.unitId,
          lastActivityId: activity.id,
        );

    if (mounted) setState(() => _lastSubmission = submission);
  }

  Future<void> _next() async {
    final activities = widget.lesson.activities;
    final isLastActivity = _currentIndex! >= activities.length - 1;

    if (!isLastActivity) {
      setState(() {
        _currentIndex = _currentIndex! + 1;
        _lastSubmission = null;
      });
      return;
    }

    await ref
        .read(masteryAggregationServiceProvider)
        .refreshUnitProgress(
          learnerId: widget.learnerId,
          unit: widget.unit,
          masteryPolicy: widget.masteryPolicy,
        );
    ref.invalidate(allUnitProgressProvider);

    if (mounted) setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == null) {
      return const _LoadingScaffold();
    }
    if (_finished) {
      return const _LessonCompleteScreen();
    }

    final l10n = AppLocalizations.of(context)!;
    final activities = widget.lesson.activities;
    final activity = activities[_currentIndex!];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.lessonPlayerProgress(_currentIndex! + 1, activities.length),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildActivityView(
                key: ValueKey(activity.id),
                activity,
                onSubmitted: (submission) =>
                    _handleSubmitted(activity, submission),
                mediaByKey: widget.mediaByKey,
              ),
              if (_lastSubmission != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: FilledButton(
                    onPressed: _next,
                    child: Text(l10n.lessonPlayerNext),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonCompleteScreen extends StatelessWidget {
  const _LessonCompleteScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.celebration, size: 48, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                l10n.lessonCompleteTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(l10n.lessonCompleteBody, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.pop(),
                child: Text(l10n.lessonCompleteDone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
