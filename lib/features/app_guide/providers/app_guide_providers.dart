import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/shared_preferences_provider.dart';

/// The version of the app guide. Raise it when the guide changes enough
/// that learners who have already seen it should see it once more (a tab
/// added or moved, say); it then starts automatically one more time.
const kAppGuideVersion = 1;

const _completedVersionKey = 'appGuide.completedVersion';

/// Where the guide is: not showing, or showing step [step].
class AppGuideState {
  const AppGuideState.idle() : active = false, step = 0;
  const AppGuideState.at(this.step) : active = true;

  final bool active;
  final int step;
}

/// Runs the app guide — the coach-mark tour over the real Home screen and
/// tab bar ([AppGuideOverlay]). It starts by itself once, the first time
/// the app opens after the agreement is accepted, and again whenever the
/// learner chooses Settings → App guide. Finishing or skipping records
/// [kAppGuideVersion], so it does not start by itself again.
class AppGuideController extends Notifier<AppGuideState> {
  @override
  AppGuideState build() => const AppGuideState.idle();

  /// Whether the guide should start by itself: the learner has not
  /// finished or skipped this version of it.
  bool get isDue =>
      (ref.read(sharedPreferencesProvider).getInt(_completedVersionKey) ?? 0) <
      kAppGuideVersion;

  void start() => state = const AppGuideState.at(0);

  void next(int stepCount) {
    if (!state.active) return;
    if (state.step + 1 >= stepCount) {
      finish();
    } else {
      state = AppGuideState.at(state.step + 1);
    }
  }

  void back() {
    if (!state.active || state.step == 0) return;
    state = AppGuideState.at(state.step - 1);
  }

  /// Done or Skip: closes the guide and remembers it was seen.
  Future<void> finish() async {
    state = const AppGuideState.idle();
    await ref
        .read(sharedPreferencesProvider)
        .setInt(_completedVersionKey, kAppGuideVersion);
  }
}

final appGuideControllerProvider =
    NotifierProvider<AppGuideController, AppGuideState>(AppGuideController.new);

/// The widgets the guide points at, keyed so the overlay can find where
/// they are on screen. Home attaches [levelBadges], [continueCard] and
/// [journey]; the tab bar attaches [navigationBar].
class AppGuideTargets {
  final levelBadges = GlobalKey(debugLabel: 'appGuide.levelBadges');
  final continueCard = GlobalKey(debugLabel: 'appGuide.continueCard');
  final journey = GlobalKey(debugLabel: 'appGuide.journey');
  final navigationBar = GlobalKey(debugLabel: 'appGuide.navigationBar');
}

final appGuideTargetsProvider = Provider<AppGuideTargets>(
  (ref) => AppGuideTargets(),
);
