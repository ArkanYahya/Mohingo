import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/status_indicator.dart';
import '../../account/providers/account_providers.dart';
import '../providers/app_guide_providers.dart';
import 'app_guide_steps.dart';

/// The number of destinations in the app shell's tab bar.
const _tabCount = 5;

/// The app guide drawn over the app shell: the screen dimmed except for a
/// highlighted cut-out around the control a step describes, and a card
/// beside it with the explanation and Back / Next / Skip / Done.
///
/// Placed over the whole shell (Home and the tab bar) by
/// `AppShellScaffold`; draws nothing while the guide is idle. Each step
/// finds its control through [AppGuideTargets], scrolls it into view if it
/// is below the fold, and measures it after layout, so the highlight is
/// always where the control actually is — at any screen size, text size or
/// reading direction. A control that is not on screen (Home still loading,
/// say) is never pointed at: the card is centred instead.
class AppGuideOverlay extends ConsumerStatefulWidget {
  const AppGuideOverlay({super.key});

  @override
  ConsumerState<AppGuideOverlay> createState() => _AppGuideOverlayState();
}

class _AppGuideOverlayState extends ConsumerState<AppGuideOverlay> {
  /// The highlighted area, in this widget's coordinates; null for none.
  Rect? _hole;

  /// The step being measured, and the layout it was measured in.
  int? _resolvedStep;
  Size? _resolvedSize;

  /// The step [_hole] was measured for. Until the current step's control
  /// has been found (and scrolled into view), its card waits, so it never
  /// appears beside the previous step's control.
  int? _measuredStep;

  /// Bumped for every new measurement, so a slow earlier one is dropped.
  int _generation = 0;

  @override
  Widget build(BuildContext context) {
    final guide = ref.watch(appGuideControllerProvider);
    if (!guide.active) {
      _resolvedStep = null;
      _measuredStep = null;
      _hole = null;
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final steps = appGuideSteps(
      l10n,
      accountsAvailable: ref.watch(authRepositoryProvider).isAvailable,
    );
    final index = guide.step.clamp(0, steps.length - 1);
    final step = steps[index];

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (_resolvedStep != index) {
          _resolvedStep = index;
          _resolvedSize = size;
          _scheduleMeasure(step, index, scroll: true);
        } else if (_resolvedSize != size) {
          // Rotation, split screen, keyboard: measure again where it is.
          _resolvedSize = size;
          _scheduleMeasure(step, index, scroll: false);
        }
        return PopScope(
          canPop: false,
          // System back closes the guide, as it would any overlay.
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              ref.read(appGuideControllerProvider.notifier).finish();
            }
          },
          child: BlockSemantics(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Taps on the dimmed area do nothing: the guide never
                // triggers the control under it by accident.
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: _Scrim(hole: _hole, size: size),
                ),
                if (_measuredStep == index)
                  _placeCard(
                    context,
                    size,
                    _GuideCard(
                      key: ValueKey(index),
                      step: step,
                      index: index,
                      count: steps.length,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _placeCard(BuildContext context, Size size, Widget card) {
    const margin = AppSpace.md;
    const gap = AppSpace.sm;
    final padding = MediaQuery.paddingOf(context);
    final width = math.min(size.width - 2 * margin, 420.0);
    final left = (size.width - width) / 2;
    final hole = _hole?.inflate(_holePadding);
    final animated = AnimatedSwitcher(
      duration: _duration(context, 200),
      child: card,
    );

    if (hole == null) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width,
            maxHeight: size.height - padding.vertical - 2 * margin,
          ),
          child: animated,
        ),
      );
    }
    final below = size.height - hole.bottom - padding.bottom - gap - margin;
    final above = hole.top - padding.top - gap - margin;
    return below >= above
        ? Positioned(
            left: left,
            width: width,
            top: hole.bottom + gap,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: math.max(below, 120)),
              child: animated,
            ),
          )
        : Positioned(
            left: left,
            width: width,
            bottom: size.height - hole.top + gap,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: math.max(above, 120)),
              child: animated,
            ),
          );
  }

  void _scheduleMeasure(AppGuideStep step, int index, {required bool scroll}) {
    final generation = ++_generation;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_measure(step, index, generation, scroll: scroll)),
    );
  }

  Future<void> _measure(
    AppGuideStep step,
    int index,
    int generation, {
    required bool scroll,
  }) async {
    bool current() => mounted && generation == _generation;
    final scrollDuration = _duration(context, 300);
    final targets = ref.read(appGuideTargetsProvider);
    final key = switch (step.anchor) {
      AppGuideAnchor.none => null,
      AppGuideAnchor.levelBadges => targets.levelBadges,
      AppGuideAnchor.continueCard => targets.continueCard,
      AppGuideAnchor.journey => targets.journey,
      AppGuideAnchor.tab => targets.navigationBar,
    };
    if (key == null) {
      if (current()) _show(index, null);
      return;
    }
    // Home may still be loading its course when the guide starts; wait
    // for the control briefly rather than pointing at empty space.
    var target = key.currentContext;
    for (var i = 0; target == null && i < 30; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!current()) return;
      target = key.currentContext;
    }
    if (target == null || !target.mounted) {
      if (current()) _show(index, null);
      return;
    }
    if (scroll && step.anchor != AppGuideAnchor.tab) {
      await Scrollable.ensureVisible(
        target,
        alignment: 0.15,
        duration: scrollDuration,
        curve: Curves.easeOutCubic,
      );
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!current()) return;
    _show(index, _rectOf(key, step));
  }

  void _show(int index, Rect? hole) => setState(() {
    _measuredStep = index;
    _hole = hole;
  });

  Rect? _rectOf(GlobalKey key, AppGuideStep step) {
    final box = key.currentContext?.findRenderObject();
    final overlay = context.findRenderObject();
    if (box is! RenderBox ||
        overlay is! RenderBox ||
        !box.attached ||
        !box.hasSize) {
      return null;
    }
    final rect = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
    if (step.anchor != AppGuideAnchor.tab) return rect;
    // The tab bar lays its destinations out in equal slots, in reading
    // order — right to left in Arabic.
    final slot = rect.width / _tabCount;
    final i = step.tabIndex!;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final start = rtl ? rect.right - (i + 1) * slot : rect.left + i * slot;
    // Only the destination itself, not the system inset under the bar.
    return Rect.fromLTWH(start, rect.top, slot, math.min(rect.height, 80));
  }
}

const _holePadding = 6.0;

Duration _duration(BuildContext context, int milliseconds) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Duration(milliseconds: milliseconds);

/// The dimmed screen with a rounded cut-out at [hole], which glides from
/// one control to the next.
class _Scrim extends StatelessWidget {
  const _Scrim({required this.hole, required this.size});

  final Rect? hole;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final ring = Theme.of(context).colorScheme.primary;
    return TweenAnimationBuilder<Rect?>(
      // No control: an empty cut-out in the middle, so the highlight
      // closes towards the centred card rather than a corner.
      tween: RectTween(
        end:
            hole?.inflate(_holePadding) ??
            Rect.fromCenter(
              center: size.center(Offset.zero),
              width: 0,
              height: 0,
            ),
      ),
      duration: _duration(context, 280),
      curve: Curves.easeOutCubic,
      builder: (context, rect, _) => CustomPaint(
        size: Size.infinite,
        painter: _ScrimPainter(hole: rect, ring: ring),
      ),
    );
  }
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter({required this.hole, required this.ring});

  final Rect? hole;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Path()..addRect(Offset.zero & size);
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.62);
    final hole = this.hole;
    if (hole == null || hole.isEmpty) {
      canvas.drawPath(screen, scrim);
      return;
    }
    final cutout = RRect.fromRectAndRadius(hole, const Radius.circular(16));
    canvas.drawPath(
      Path.combine(PathOperation.difference, screen, Path()..addRRect(cutout)),
      scrim,
    );
    canvas.drawRRect(
      cutout,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.hole != hole || old.ring != ring;
}

/// The explanation card: step count and Skip, the title and text, and
/// Back / Next (Done on the last step).
class _GuideCard extends ConsumerWidget {
  const _GuideCard({
    required this.step,
    required this.index,
    required this.count,
    super.key,
  });

  final AppGuideStep step;
  final int index;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(appGuideControllerProvider.notifier);
    final last = index == count - 1;

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: step.title,
      child: Material(
        color: tokens.card,
        elevation: 6,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: tokens.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.md,
            AppSpace.xs,
            AppSpace.xs,
            AppSpace.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.guideStepCounter(index + 1, count),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                  ),
                  // Keeps the row's height when Skip is absent.
                  SizedBox(
                    height: 48,
                    child: last
                        ? null
                        : TextButton(
                            onPressed: controller.finish,
                            child: Text(l10n.guideSkip),
                          ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpace.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        step.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      step.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    if (step.showStatusLegend) ...[
                      const SizedBox(height: AppSpace.sm),
                      const _StatusLegend(),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  if (index > 0)
                    TextButton(
                      onPressed: controller.back,
                      child: Text(l10n.guideBack),
                    ),
                  const Spacer(),
                  FilledButton(
                    autofocus: true,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(96, 44),
                    ),
                    onPressed: () => controller.next(count),
                    child: Text(last ? l10n.guideDone : l10n.guideNext),
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

/// The progress marks Learn uses, each with what it means.
class _StatusLegend extends StatelessWidget {
  const _StatusLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>()!;
    final l10n = AppLocalizations.of(context)!;
    final entries = [
      (ProgressState.notStarted, l10n.unitStateNotStarted),
      (ProgressState.inProgress, l10n.unitStateInProgress),
      (ProgressState.needsReview, l10n.unitStateNeedsReview),
      (ProgressState.mastered, l10n.guideLegendDone),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (state, label) in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: MergeSemantics(
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: StatusIndicator(state: state, size: 20),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
