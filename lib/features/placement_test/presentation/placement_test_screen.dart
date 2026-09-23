import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../content/models/activity.dart';
import '../../../content/models/domain_definitions.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/skill_label.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/overline_style.dart';
import '../../../core/widgets/content_text.dart';
import '../../../core/widgets/section_heading.dart';
import '../../activity_engine/domain/activity_submission.dart';
import '../../activity_engine/domain/evidence_skill_resolver.dart';
import '../../activity_engine/presentation/activity_view_registry.dart';
import '../../activity_engine/presentation/widgets/activity_option_tile.dart';
import '../../activity_engine/presentation/widgets/answer_tile_state.dart';
import '../../lesson_player/presentation/widgets/activity_eyebrow.dart';
import '../../progress/domain/level_access.dart';
import '../../progress/providers/current_learner_provider.dart';
import '../../progress/providers/level_providers.dart';
import '../../progress/providers/progress_providers.dart';
import '../../tests_home/presentation/widgets/test_intro_view.dart';
import '../../tests_home/presentation/widgets/test_question_frame.dart';
import '../../tests_home/presentation/widgets/test_result_view.dart';
import '../../tests_home/providers/tests_home_providers.dart';
import '../domain/placement_classifier.dart';
import '../domain/placement_item_sampler.dart';
import '../domain/placement_outcome.dart';
import '../domain/placement_plan.dart';
import '../providers/placement_providers.dart';

/// The RNG seed used to sample placement-test items each attempt — a real
/// random value in production, overridable in tests so item sampling is
/// deterministic (the same pattern used for the speech services, see
/// `test/features/speech/fake_speech_services.dart`).
final placementSeedProvider = Provider<int>(
  (ref) => Random().nextInt(0x7FFFFFFF),
);

/// The Gateway Placement Test, across every released level.
///
/// Two speeds (Design 4 of
/// docs/superpowers/specs/2026-09-19-a2-level-design.md):
///
/// 1. **Block pass.** Each level's units in blocks of three or four
///    (A1: U0–U3, U4–U6, U7–U9, U10–U12; A2: U1–U3, …), one item per unit,
///    the block passing at 60%. A learner who knows the material answers
///    about 25 items for the whole course instead of 39+.
/// 2. **Drill-down.** A failed block is opened up unit by unit, up to three
///    items each, stopping at the first unit that fails — and *that* unit
///    is the recommendation. If every unit in the block passes after all,
///    the scan carries on with the next block.
///
/// Items are sampled from existing `practice` content ([PlacementItemSampler]
/// — the bundles have no dedicated placement-item pool), seeded per attempt
/// so a retake draws different items. A single productive (write/speak)
/// item follows as supporting evidence only; it never changes the
/// classification, since no rubric evaluator exists yet for free-response
/// answers.
///
/// Everything is recorded under `sessionType='placement'`, which is what
/// keeps it out of mastery evidence and Review — never the source
/// activity's own mode.
///
/// Not resumable mid-test (unlike the lesson player) — a placement attempt
/// is short and a partial attempt is simply discarded if the app closes;
/// see the Phase 9 report for why this scope was kept simple.
class PlacementTestScreen extends ConsumerWidget {
  const PlacementTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(placementPlanProvider);
    final learnerAsync = ref.watch(currentLearnerProvider);
    return planAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (error, _) => _ErrorScaffold(message: '$error'),
      data: (plan) => learnerAsync.when(
        loading: () => const _LoadingScaffold(),
        error: (error, _) => _ErrorScaffold(message: '$error'),
        data: (learner) =>
            _PlacementTestBody(plan: plan, learnerId: learner.id),
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

/// One question the scan asks, with the unit (and therefore the level) it
/// came from — so its eyebrow, its media and "the last unit reached" are
/// all read off the item itself rather than off whichever level the screen
/// started in.
class _ScanItem {
  const _ScanItem({required this.activity, required this.unit});
  final Activity activity;
  final PlacementUnitRef unit;
}

class _PlacementTestBody extends ConsumerStatefulWidget {
  const _PlacementTestBody({required this.plan, required this.learnerId});

  final PlacementPlan plan;
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

  /// Where the scan is: which block, and — once that block has failed —
  /// which of its units is being looked at on its own. Null means the
  /// block's one-item-per-unit pass is still running.
  int _blockIndex = 0;
  int? _drillIndex;

  List<_ScanItem> _items = const [];
  int _itemIndex = 0;
  List<bool> _correctness = [];

  /// Activity ids this attempt has already asked — a unit's drill-down
  /// never repeats the item its block pass asked.
  final Set<String> _askedActivityIds = {};

  /// Per-unit results from drill-downs only, in curriculum order. A block
  /// that passed contributes nothing: it recommends no unit inside it.
  final List<MapEntry<String, bool>> _unitResults = [];
  final Map<Skill, _SkillTally> _skillTally = {};

  /// How far through the course the scan has reached, in units — the
  /// progress bar's fill and the attempt's stored `stageReached`. Only
  /// ever moves forward, so opening a block up unit by unit never rewinds
  /// the bar the block pass already filled.
  int _unitsReached = 0;

  PlacementUnitRef? _lastUnitReached;
  _ScanItem? _productiveItem;
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

  void _reachUnits(int units) {
    if (units > _unitsReached) _unitsReached = units;
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
    _beginBlock(0);
  }

  /// One item per unit in block [blockIndex] — the fast pass.
  void _beginBlock(int blockIndex) {
    final plan = widget.plan;
    if (blockIndex >= plan.blocks.length) {
      _finishReceptiveScan();
      return;
    }
    final block = plan.blocks[blockIndex];
    final items = <_ScanItem>[];
    for (final unit in block.units) {
      final unitRef = plan.locate(unit.id)!;
      final sampled = PlacementItemSampler.receptiveItemsForUnit(
        unit,
        seed: _seed + unitRef.scanIndex,
        limit: 1,
        exclude: _askedActivityIds,
      );
      if (sampled.isEmpty) continue;
      items.add(_ScanItem(activity: sampled.single, unit: unitRef));
    }
    if (items.isEmpty) {
      // Nothing eligible to ask: no evidence blocks nothing (the same rule
      // as a unit with too few items), so move on.
      _reachUnits(plan.unitsBefore(blockIndex) + block.units.length);
      _beginBlock(blockIndex + 1);
      return;
    }
    _reachUnits(plan.unitsBefore(blockIndex));
    setState(() {
      _starting = false;
      _blockIndex = blockIndex;
      _drillIndex = null;
      _items = items;
      _itemIndex = 0;
      _correctness = [];
      _phase = _Phase.item;
    });
  }

  /// Up to three items from one unit of the failed block — the slow pass.
  void _beginDrill(int drillIndex) {
    final plan = widget.plan;
    final block = plan.blocks[_blockIndex];
    if (drillIndex >= block.units.length) {
      // Every unit passed on its own after all: the block's items were
      // unlucky, not the learner. Carry on with the next block.
      _beginBlock(_blockIndex + 1);
      return;
    }
    final unit = block.units[drillIndex];
    final unitRef = plan.locate(unit.id)!;
    final sampled = PlacementItemSampler.receptiveItemsForUnit(
      unit,
      seed: _seed + unitRef.scanIndex,
      exclude: _askedActivityIds,
    );
    if (sampled.isEmpty) {
      _unitResults.add(MapEntry(unit.id, true));
      _beginDrill(drillIndex + 1);
      return;
    }
    setState(() {
      _drillIndex = drillIndex;
      _items = [
        for (final activity in sampled)
          _ScanItem(activity: activity, unit: unitRef),
      ];
      _itemIndex = 0;
      _correctness = [];
      _phase = _Phase.item;
    });
  }

  Future<void> _handleItemSubmitted(
    _ScanItem item,
    ActivitySubmission submission,
  ) async {
    final activity = item.activity;
    final correct = submission.correctness == ActivityCorrectness.correct;
    // Counted before the save so the block/unit result can't miss it.
    _tallySkill(
      activity.skill,
      correct: correct,
      scored: submission.correctness != ActivityCorrectness.notAutoGraded,
    );
    _correctness.add(correct);
    _askedActivityIds.add(activity.id);
    _lastUnitReached = item.unit;
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
    if (_itemIndex < _items.length - 1) {
      setState(() {
        _itemIndex++;
        // A block pass decides one unit per item, so the bar moves with it;
        // a drill-down's three items are all about the one unit, which
        // isn't settled until they are all answered.
        if (_drillIndex == null) {
          _reachUnits(widget.plan.unitsBefore(_blockIndex) + _itemIndex);
        }
      });
      return;
    }
    final drillIndex = _drillIndex;
    if (drillIndex == null) {
      _finishBlockPass();
    } else {
      _finishDrillUnit(drillIndex);
    }
  }

  void _finishBlockPass() {
    final block = widget.plan.blocks[_blockIndex];
    if (PlacementScoring.blockPassed(_correctness)) {
      _reachUnits(widget.plan.unitsBefore(_blockIndex) + block.units.length);
      _beginBlock(_blockIndex + 1);
    } else {
      _beginDrill(0);
    }
  }

  void _finishDrillUnit(int drillIndex) {
    final block = widget.plan.blocks[_blockIndex];
    final unit = block.units[drillIndex];
    final passed = PlacementScoring.unitPassed(_correctness);
    _unitResults.add(MapEntry(unit.id, passed));
    _reachUnits(widget.plan.unitsBefore(_blockIndex) + drillIndex + 1);
    if (passed) {
      _beginDrill(drillIndex + 1);
    } else {
      _finishReceptiveScan();
    }
  }

  void _finishReceptiveScan() {
    final plan = widget.plan;
    // Nothing answered at all (every block had nothing eligible to ask):
    // fall back to the last unit in the plan, if there is one.
    final reached =
        _lastUnitReached ??
        (plan.blocks.isEmpty
            ? null
            : plan.locate(plan.blocks.last.units.last.id));
    final productive = reached == null
        ? null
        : PlacementItemSampler.productiveItemForUnit(reached.unit, seed: _seed);
    if (productive == null || reached == null) {
      setState(() => _phase = _Phase.confidence);
      return;
    }
    setState(() {
      _productiveItem = _ScanItem(activity: productive, unit: reached);
      _phase = _Phase.productive;
    });
  }

  Future<void> _handleProductiveSubmitted(ActivitySubmission submission) async {
    final activity = _productiveItem!.activity;
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
    final classification = PlacementClassifier.classify(
      _unitResults,
      topLevelId: widget.plan.topLevel.levelId,
    );
    await ref
        .read(assessmentAttemptRepositoryProvider)
        .completePlacementAttempt(
          attemptId: _attemptId!,
          stageReached: _unitsReached,
          outcome: classification.storedOutcome,
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
    final plan = widget.plan;
    final topCode = plan.topLevel.cefrCode;
    // One segment per block, sized by its units — the bar advances a unit
    // at a time whichever speed the scan is running at.
    final groupSizes = [for (final block in plan.blocks) block.units.length];
    return switch (_phase) {
      _Phase.intro => TestIntroView(
        overline: l10n.placementIntroTitle(topCode),
        title: l10n.testsPlacementHeroTitle,
        lead: l10n.placementIntroBody(topCode),
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
      _Phase.item => _buildItem(l10n, groupSizes),
      _Phase.productive => TestQuestionFrame(
        groupSizes: groupSizes,
        completed: plan.totalUnits,
        eyebrow: TestEyebrow(
          skill: _productiveItem!.activity.skill,
          text: learnerSkillLabel(l10n, _productiveItem!.activity.skill),
        ),
        testMode: true,
        onContinue: _nextAfterProductive,
        child: buildActivityView(
          key: ValueKey(_productiveItem!.activity.id),
          _productiveItem!.activity,
          learnerId: widget.learnerId,
          onSubmitted: (s) => _recording = _handleProductiveSubmitted(s),
          mediaByKey: _productiveItem!.unit.level.mediaByKey,
        ),
      ),
      _Phase.confidence => _ConfidenceView(onSubmit: _submitConfidence),
      _Phase.result => _ResultView(
        classification: _classification!,
        recommendation: plan.locate(_classification!.recommendedUnitId),
        masteredLevelCode: topCode,
        skillScores: {
          for (final MapEntry(:key, :value) in _skillTally.entries)
            key: (value.correct, value.total),
        },
      ),
    };
  }

  Widget _buildItem(AppLocalizations l10n, List<int> groupSizes) {
    final item = _items[_itemIndex];
    final section = l10n.placementUnitSection(
      item.unit.cefrCode,
      item.unit.number,
    );
    return TestQuestionFrame(
      groupSizes: groupSizes,
      // One segment per block, filled a unit at a time — and never
      // rewound when a block is opened up unit by unit (see [_reachUnits]).
      completed: _unitsReached,
      eyebrow: TestEyebrow(
        skill: item.activity.skill,
        // One item per unit in a block pass, so there is no "n of 3" to
        // report; a drill-down's three items are all from this one unit.
        text: _drillIndex == null
            ? section
            : l10n.testQuestionEyebrow(section, _itemIndex + 1, _items.length),
      ),
      testMode: true,
      onContinue: _nextItem,
      child: buildActivityView(
        key: ValueKey(item.activity.id),
        item.activity,
        learnerId: widget.learnerId,
        onSubmitted: (s) => _recording = _handleItemSubmitted(item, s),
        mediaByKey: item.unit.level.mediaByKey,
      ),
    );
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
  required PlacementUnitRef? recommendation,
  required String masteredLevelCode,
  required SkillScores skillScores,
}) => _ResultView(
  classification: classification,
  recommendation: recommendation,
  masteredLevelCode: masteredLevelCode,
  skillScores: skillScores,
);

/// The placement result: the unit to start from as the headline, that
/// unit as a card, per-skill scores, and a button that starts there —
/// or, when every unit passed, "{top released level} looks mastered" and a
/// pointer to the final assessment.
///
/// A mastered level is somewhere to start too when it isn't the level the
/// learner is in: ADR 0006 decision 4 counts a placement result inside a
/// level as one of the three things that open it, so the button moves them
/// there rather than leaving them a level below with it still locked.
class _ResultView extends ConsumerWidget {
  const _ResultView({
    required this.classification,
    required this.recommendation,
    required this.masteredLevelCode,
    required this.skillScores,
  });

  final PlacementClassification classification;

  /// Where the result points, already resolved in its own level — null for
  /// a "level mastered" result.
  final PlacementUnitRef? recommendation;

  /// The top released level's code, for the mastered headline. Never a
  /// level above it: there is no content above it to have been measured.
  final String masteredLevelCode;

  final SkillScores skillScores;

  /// Makes [levelId] the level the learner is in (unlocking it first if
  /// they haven't reached it) and opens it — at [unitId] when the result
  /// names a unit, at the level itself when it names a whole mastered
  /// level.
  ///
  /// [access] comes from a `watch` in [build], not a `read` here: reading
  /// an auto-dispose provider from a callback that has no listener tears it
  /// down mid-await — the same trap `LevelSelectionController`'s own doc
  /// comment records. Null (still loading) unlocks, which is the safe way
  /// to be wrong.
  Future<void> _startHere(
    BuildContext context,
    WidgetRef ref,
    String levelId,
    String? unitId,
    LevelAccess? access,
  ) async {
    final controller = ref.read(levelSelectionControllerProvider.notifier);
    if (access != LevelAccess.open) {
      await controller.unlock(levelId);
    }
    await controller.select(levelId);
    if (context.mounted) {
      context.go(unitId == null ? '/learn' : '/learn/unit/$unitId');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final recommendation = this.recommendation;
    // A mastered level is only somewhere to *go* when the learner isn't
    // already there. `currentLevelIdProvider` is async, so null means "not
    // known yet" — until it resolves the result stays a plain close, the
    // safe way to be wrong.
    final masteredLevelId = classification.masteredLevelId;
    final masteredElsewhere =
        recommendation == null &&
        masteredLevelId != null &&
        masteredLevelId != ref.watch(currentLevelIdProvider).value;
    final startLevelId =
        recommendation?.levelId ?? (masteredElsewhere ? masteredLevelId : null);
    final access = startLevelId == null
        ? null
        : ref.watch(levelAccessProvider(startLevelId)).value;

    final (title, body) = recommendation == null
        ? (
            l10n.placementResultMasteredTitle(masteredLevelCode),
            l10n.placementResultMasteredBody,
          )
        : (
            l10n.placementResultHeadline(
              recommendation.cefrCode,
              recommendation.number,
            ),
            switch (classification.outcome) {
              PlacementOutcome.startWithEssentials =>
                l10n.placementResultBodyEssentials,
              _ when recommendation.isFirstInLevel =>
                l10n.placementResultBodyLevelStart(recommendation.cefrCode),
              _ => l10n.placementResultBodyUnit(recommendation.number),
            },
          );
    void done() => context.pop();

    return TestResultView(
      overline: l10n.placementResultOverline,
      title: title,
      body: body,
      primaryLabel: switch ((recommendation, masteredElsewhere)) {
        (final r?, _) => l10n.placementResultStartAtUnit(r.cefrCode, r.number),
        (null, true) => l10n.homeNextLevelTitle(masteredLevelCode),
        (null, false) => l10n.placementResultDone,
      },
      primaryArrow: startLevelId != null,
      onPrimary: startLevelId == null
          ? done
          : () => _startHere(
              context,
              ref,
              startLevelId,
              recommendation?.unit.id,
              access,
            ),
      secondaryLabel: startLevelId == null ? null : l10n.placementResultDone,
      onSecondary: done,
      children: [
        if (recommendation != null) ...[
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
                    l10n
                        .placementUnitSection(
                          recommendation.cefrCode,
                          recommendation.number,
                        )
                        .toUpperCase(),
                    style: overlineStyle(context, color: tokens.primaryInk),
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  ContentText.en(
                    recommendation.unit.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: tokens.textPrimary,
                    ),
                  ),
                  ContentText.ar(
                    recommendation.unit.titleAr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                  if (recommendation.unit.estimatedMinutes.length == 2) ...[
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      '${l10n.learnLessonCount(recommendation.unit.lessons.length)} · '
                      '${l10n.learnUnitMinutes(recommendation.unit.estimatedMinutes[0], recommendation.unit.estimatedMinutes[1])}',
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
        if (recommendation != null && recommendation.number > 1) ...[
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
