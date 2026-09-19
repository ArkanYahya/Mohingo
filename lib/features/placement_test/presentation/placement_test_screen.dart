import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/activity.dart';
import '../../../content/models/curriculum_structure.dart';
import '../../../content/models/domain_definitions.dart';
import '../../../content/models/media_specification.dart';
import '../../../content/providers/course_content_providers.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/skill_label.dart';
import '../../activity_engine/domain/activity_submission.dart';
import '../../activity_engine/domain/evidence_skill_resolver.dart';
import '../../activity_engine/presentation/activity_view_registry.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';
import '../../tests_home/presentation/widgets/test_intro_view.dart';
import '../../tests_home/presentation/widgets/test_question_frame.dart';
import '../../tests_home/providers/tests_home_providers.dart';
import '../domain/placement_classifier.dart';
import '../domain/placement_item_sampler.dart';
import '../domain/placement_outcome.dart';

/// The RNG seed used to sample placement-test items each attempt — a real
/// random value in production, overridable in tests so item sampling is
/// deterministic (the same pattern used for the speech services, see
/// `test/features/speech/fake_speech_services.dart`).
final placementSeedProvider = Provider<int>(
  (ref) => Random().nextInt(0x7FFFFFFF),
);

/// The A1 Gateway Placement Test.
///
/// Scans the curriculum's units in order (`A1-U0` first), sampling a
/// handful of listening/reading `practice` items per unit (see
/// [PlacementItemSampler] — the bundle has no dedicated placement-item pool,
/// this samples from existing training content instead) and stopping at the
/// first unit that fails. That stopping point *is* the useful signal, so
/// this collapses the master prompt's "fixed foundation stage + adaptive
/// receptive stage" into one continuous adaptive scan — see
/// [PlacementClassifier]. A single productive (write/speak) item is sampled
/// afterward as supporting evidence only; it never changes the
/// classification, since no rubric evaluator exists yet for free-response
/// answers.
///
/// Not resumable mid-test (unlike the lesson player) — a placement attempt
/// is short and a partial attempt is simply discarded if the app closes;
/// see the Phase 9 report for why this scope was kept simple.
class PlacementTestScreen extends ConsumerWidget {
  const PlacementTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(courseContentProvider('a1'));
    final learnerAsync = ref.watch(currentLearnerProvider);
    return contentAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (error, _) => _ErrorScaffold(message: '$error'),
      data: (index) => learnerAsync.when(
        loading: () => const _LoadingScaffold(),
        error: (error, _) => _ErrorScaffold(message: '$error'),
        data: (learner) => _PlacementTestBody(
          units: index.bundle.units,
          mediaByKey: index.bundle.mediaSpecifications,
          learnerId: learner.id,
        ),
      ),
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

enum _Phase { intro, item, productive, confidence, result }

class _SkillTally {
  int correct = 0;
  int total = 0;
}

class _PlacementTestBody extends ConsumerStatefulWidget {
  const _PlacementTestBody({
    required this.units,
    required this.mediaByKey,
    required this.learnerId,
  });

  final List<Unit> units;
  final Map<String, MediaSpecification> mediaByKey;
  final int learnerId;

  @override
  ConsumerState<_PlacementTestBody> createState() => _PlacementTestBodyState();
}

class _PlacementTestBodyState extends ConsumerState<_PlacementTestBody> {
  _Phase _phase = _Phase.intro;
  bool _starting = false;

  int? _attemptId;
  String? _sessionUuid;
  int _seed = 0;

  int _unitIndex = 0;
  List<Activity> _unitItems = const [];
  int _itemIndex = 0;
  List<bool> _unitCorrectness = [];
  final List<MapEntry<String, bool>> _unitResults = [];
  final Map<Skill, _SkillTally> _skillTally = {};

  Activity? _productiveActivity;
  PlacementClassification? _classification;

  /// The current answer's save, awaited before moving on — the feedback
  /// panel (and its Next button) appears as soon as Check is tapped.
  Future<void>? _recording;

  void _tallySkill(Skill skill, {required bool correct, required bool scored}) {
    if (!scored) return;
    final tally = _skillTally.putIfAbsent(skill, () => _SkillTally());
    tally.total++;
    if (correct) tally.correct++;
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    final seed = ref.read(placementSeedProvider);
    final repository = ref.read(assessmentAttemptRepositoryProvider);
    final attemptId = await repository.startPlacementAttempt(
      learnerId: widget.learnerId,
      itemSamplingSeed: seed.toString(),
    );
    final attemptRow = await repository.latestPlacementAttempt(
      learnerId: widget.learnerId,
    );
    _attemptId = attemptId;
    _sessionUuid = attemptRow!.uuid;
    _seed = seed;
    _beginUnit(0);
  }

  void _beginUnit(int unitIndex) {
    if (unitIndex >= widget.units.length) {
      _finishReceptiveScan(widget.units.last);
      return;
    }
    final unit = widget.units[unitIndex];
    final items = PlacementItemSampler.receptiveItemsForUnit(
      unit,
      seed: _seed + unitIndex,
    );
    if (items.isEmpty) {
      _unitResults.add(MapEntry(unit.id, true));
      _beginUnit(unitIndex + 1);
      return;
    }
    setState(() {
      _starting = false;
      _unitIndex = unitIndex;
      _unitItems = items;
      _itemIndex = 0;
      _unitCorrectness = [];
      _phase = _Phase.item;
    });
  }

  Future<void> _handleItemSubmitted(
    Activity activity,
    ActivitySubmission submission,
  ) async {
    final correct = submission.correctness == ActivityCorrectness.correct;
    // Counted before the save so the unit's result can't miss it.
    _tallySkill(
      activity.skill,
      correct: correct,
      scored: submission.correctness != ActivityCorrectness.notAutoGraded,
    );
    _unitCorrectness.add(correct);
    await ref
        .read(activityAttemptRepositoryProvider)
        .recordAttempt(
          learnerId: widget.learnerId,
          activityId: activity.id,
          sessionType: 'placement',
          sessionId: _sessionUuid,
          mode: activity.mode,
          evidenceSkill: activity.skill,
          canDoIds: activity.canDo,
          rawAnswer: submission.rawAnswerJson,
          isCorrect: switch (submission.correctness) {
            ActivityCorrectness.correct => true,
            ActivityCorrectness.incorrect => false,
            ActivityCorrectness.notAutoGraded => null,
          },
          score: submission.score,
        );
  }

  Future<void> _nextItem() async {
    await _recording;
    if (!mounted) return;
    if (_itemIndex < _unitItems.length - 1) {
      setState(() {
        _itemIndex++;
      });
      return;
    }
    final unit = widget.units[_unitIndex];
    final passed = PlacementScoring.unitPassed(_unitCorrectness);
    _unitResults.add(MapEntry(unit.id, passed));
    if (passed) {
      _beginUnit(_unitIndex + 1);
    } else {
      _finishReceptiveScan(unit);
    }
  }

  void _finishReceptiveScan(Unit stoppedAtUnit) {
    final productive = PlacementItemSampler.productiveItemForUnit(
      stoppedAtUnit,
      seed: _seed,
    );
    if (productive == null) {
      setState(() => _phase = _Phase.confidence);
      return;
    }
    setState(() {
      _productiveActivity = productive;
      _phase = _Phase.productive;
    });
  }

  Future<void> _handleProductiveSubmitted(ActivitySubmission submission) async {
    final activity = _productiveActivity!;
    final evidenceSkill = resolveEvidenceSkill(activity, submission);
    final correct = submission.correctness == ActivityCorrectness.correct;
    await ref
        .read(activityAttemptRepositoryProvider)
        .recordAttempt(
          learnerId: widget.learnerId,
          activityId: activity.id,
          sessionType: 'placement',
          sessionId: _sessionUuid,
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
    _tallySkill(
      evidenceSkill,
      correct: correct,
      scored: submission.correctness != ActivityCorrectness.notAutoGraded,
    );
  }

  Future<void> _submitConfidence(int value) async {
    final classification = PlacementClassifier.classify(_unitResults);
    await ref
        .read(assessmentAttemptRepositoryProvider)
        .completePlacementAttempt(
          attemptId: _attemptId!,
          stageReached: _unitResults.length,
          outcome: classification.outcome.name,
          recommendedUnitId: classification.recommendedUnitId,
          confidenceSelfReportsJson: jsonEncode({'overall': value}),
        );
    // The Tests tab's placement card reads the latest attempt from a cached
    // provider — refresh it now that this attempt is persisted.
    ref.invalidate(latestPlacementAttemptProvider);
    if (mounted) {
      setState(() {
        _classification = classification;
        _phase = _Phase.result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final units = widget.units;
    return switch (_phase) {
      _Phase.intro => TestIntroView(
        overline: l10n.testsPlacementTitle,
        title: l10n.testsPlacementHeroTitle,
        lead: l10n.placementIntroBody,
        heading: l10n.testIntroCoversHeading,
        rows: [
          TestIntroRow(
            icon: Icons.headphones_rounded,
            title: l10n.placementCoversReceptive,
          ),
          TestIntroRow(
            icon: Icons.edit_note_rounded,
            title: l10n.placementCoversProductive,
          ),
          TestIntroRow(
            icon: Icons.flag_outlined,
            title: l10n.placementCoversStops,
          ),
        ],
        note: l10n.testRulesNote,
        startLabel: l10n.placementStartButton,
        starting: _starting,
        onStart: _start,
      ),
      _Phase.item => TestQuestionFrame(
        // One segment per unit: the scan moves through the course.
        groupSizes: [for (final _ in units) 1],
        completed: _unitIndex,
        eyebrow: TestEyebrow(
          skill: _unitItems[_itemIndex].skill,
          text: l10n.testQuestionEyebrow(
            l10n.learnUnitOverline(_unitIndex + 1),
            _itemIndex + 1,
            _unitItems.length,
          ),
        ),
        testMode: true,
        onContinue: _nextItem,
        child: buildActivityView(
          key: ValueKey(_unitItems[_itemIndex].id),
          _unitItems[_itemIndex],
          learnerId: widget.learnerId,
          onSubmitted: (s) =>
              _recording = _handleItemSubmitted(_unitItems[_itemIndex], s),
          mediaByKey: widget.mediaByKey,
        ),
      ),
      _Phase.productive => TestQuestionFrame(
        groupSizes: [for (final _ in units) 1],
        completed: units.length,
        eyebrow: TestEyebrow(
          skill: _productiveActivity!.skill,
          text: learnerSkillLabel(l10n, _productiveActivity!.skill),
        ),
        testMode: true,
        onContinue: _nextAfterProductive,
        child: buildActivityView(
          key: ValueKey(_productiveActivity!.id),
          _productiveActivity!,
          learnerId: widget.learnerId,
          onSubmitted: (s) => _recording = _handleProductiveSubmitted(s),
          mediaByKey: widget.mediaByKey,
        ),
      ),
      _Phase.confidence => _ConfidenceView(onSubmit: _submitConfidence),
      _Phase.result => _ResultView(
        classification: _classification!,
        units: widget.units,
        skillTally: _skillTally,
      ),
    };
  }

  Future<void> _nextAfterProductive() async {
    await _recording;
    if (mounted) setState(() => _phase = _Phase.confidence);
  }
}

class _ConfidenceView extends StatelessWidget {
  const _ConfidenceView({required this.onSubmit});

  final void Function(int value) onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.placementConfidenceQuestion)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.placementConfidenceQuestion,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var value = 1; value <= 5; value++)
                    OutlinedButton(
                      onPressed: () => onSubmit(value),
                      child: Text('$value'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.placementConfidenceLow,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    l10n.placementConfidenceHigh,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.classification,
    required this.units,
    required this.skillTally,
  });

  final PlacementClassification classification;
  final List<Unit> units;
  final Map<Skill, _SkillTally> skillTally;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final recommendedUnit = classification.recommendedUnitId == null
        ? null
        : units.firstWhere((u) => u.id == classification.recommendedUnitId);

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final message = switch (classification.outcome) {
      PlacementOutcome.startWithEssentials =>
        l10n.placementOutcomeStartWithEssentials,
      PlacementOutcome.startA1FromU1 => l10n.placementOutcomeStartA1FromU1,
      PlacementOutcome.startFromRecommendedUnit =>
        l10n.placementOutcomeStartFromUnit(
          isArabic ? recommendedUnit!.titleAr : recommendedUnit!.title,
        ),
      PlacementOutcome.a1Mastered => l10n.placementOutcomeMastered,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.placementResultTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.flag_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              if (skillTally.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final entry in skillTally.entries)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(skillLabel(l10n, entry.key)),
                                Text(
                                  '${entry.value.correct}/${entry.value.total}',
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              if (recommendedUnit != null)
                FilledButton(
                  onPressed: () =>
                      context.go('/learn/unit/${recommendedUnit.id}'),
                  child: Text(l10n.placementResultGoToUnit),
                ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.pop(),
                child: Text(l10n.placementResultDone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
