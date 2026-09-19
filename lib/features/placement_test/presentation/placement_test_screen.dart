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
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/overline_style.dart';
import '../../../core/widgets/section_heading.dart';
import '../../activity_engine/domain/activity_submission.dart';
import '../../activity_engine/domain/evidence_skill_resolver.dart';
import '../../activity_engine/presentation/activity_view_registry.dart';
import '../../activity_engine/presentation/widgets/activity_option_tile.dart';
import '../../activity_engine/presentation/widgets/answer_tile_state.dart';
import '../../lesson_player/presentation/widgets/activity_eyebrow.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/progress_providers.dart';
import '../../tests_home/presentation/widgets/test_intro_view.dart';
import '../../tests_home/presentation/widgets/test_question_frame.dart';
import '../../tests_home/presentation/widgets/test_result_view.dart';
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
        skillScores: {
          for (final MapEntry(:key, :value) in _skillTally.entries)
            key: (value.correct, value.total),
        },
      ),
    };
  }

  Future<void> _nextAfterProductive() async {
    await _recording;
    if (mounted) setState(() => _phase = _Phase.confidence);
  }
}

/// "Overall, how confident did that feel?" — five labelled options; the
/// answer is stored as supporting information and never changes the
/// result.
class _ConfidenceView extends StatelessWidget {
  const _ConfidenceView({required this.onSubmit});

  final void Function(int value) onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.placementConfidence1,
      l10n.placementConfidence2,
      l10n.placementConfidence3,
      l10n.placementConfidence4,
      l10n.placementConfidence5,
    ];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.md,
            AppSpace.lg,
            AppSpace.md,
            AppSpace.lg,
          ),
          children: [
            Text(
              l10n.testsPlacementTitle.toUpperCase(),
              style: overlineStyle(context, color: tokens.textSecondary),
            ),
            const SizedBox(height: AppSpace.xxs),
            Text(
              l10n.placementConfidenceQuestion,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              l10n.placementConfidenceNote,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            for (final (i, label) in labels.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.xs),
                child: ActivityOptionTile(
                  label: label,
                  state: AnswerTileState.idle,
                  onTap: () => onSubmit(i + 1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A placement result's per-skill score: (right, scored).
typedef SkillScores = Map<Skill, (int, int)>;

/// Test-only construction path for [_ResultView], mirroring
/// `buildFinalAssessmentResultViewForTest`.
@visibleForTesting
Widget buildPlacementResultViewForTest({
  required PlacementClassification classification,
  required List<Unit> units,
  required SkillScores skillScores,
}) => _ResultView(
  classification: classification,
  units: units,
  skillScores: skillScores,
);

/// The placement result: the unit to start from as the headline, that
/// unit as a card, per-skill scores, and a button straight to the unit —
/// or, when every unit passed, a pointer to the final assessment.
class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.classification,
    required this.units,
    required this.skillScores,
  });

  final PlacementClassification classification;
  final List<Unit> units;
  final SkillScores skillScores;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final unitId = classification.recommendedUnitId;
    final unitIndex = unitId == null
        ? -1
        : units.indexWhere((u) => u.id == unitId);
    final unit = unitIndex < 0 ? null : units[unitIndex];
    final unitNumber = unitIndex + 1;

    final (title, body) = unit == null
        ? (l10n.placementResultMasteredTitle, l10n.placementResultMasteredBody)
        : (
            l10n.placementResultHeadline(unitNumber),
            unitNumber == 1
                ? l10n.placementResultBodyEssentials
                : l10n.placementResultBodyUnit(unitNumber),
          );
    void done() => context.pop();

    return TestResultView(
      overline: l10n.placementResultOverline,
      title: title,
      body: body,
      primaryLabel: unit == null
          ? l10n.placementResultDone
          : l10n.placementResultGoToUnitN(unitNumber),
      primaryArrow: unit != null,
      onPrimary: unit == null
          ? done
          : () => context.go('/learn/unit/${unit.id}'),
      secondaryLabel: unit == null ? null : l10n.placementResultDone,
      onSecondary: done,
      children: [
        if (unit != null) ...[
          const SizedBox(height: AppSpace.md),
          DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: tokens.primaryInk, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.learnUnitOverline(unitNumber).toUpperCase(),
                    style: overlineStyle(context, color: tokens.primaryInk),
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      unit.title,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      unit.titleAr,
                      textDirection: TextDirection.rtl,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                  ),
                  if (unit.estimatedMinutes.length == 2) ...[
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      '${l10n.learnLessonCount(unit.lessons.length)} · '
                      '${l10n.learnUnitMinutes(unit.estimatedMinutes[0], unit.estimatedMinutes[1])}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        if (skillScores.isNotEmpty) ...[
          SectionHeading(l10n.testsResultHowYouDid),
          ResultRowsCard(
            rows: [
              for (final MapEntry(key: skill, value: (right, total))
                  in skillScores.entries)
                SkillResultRow(
                  icon: skillIcon(skill),
                  label: skillLabel(l10n, skill),
                  trailing: Text(
                    l10n.testsSkillScore(right, total),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: tokens.textPrimary,
                    ),
                  ),
                  progress: total == 0 ? 0 : right / total,
                ),
            ],
          ),
        ],
        if (unit != null && unitNumber > 1) ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            l10n.placementResultEarlierOpen,
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
