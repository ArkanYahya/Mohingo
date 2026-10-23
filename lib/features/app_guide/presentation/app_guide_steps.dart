import '../../../core/l10n/generated/app_localizations.dart';

/// What a guide step points at.
enum AppGuideAnchor {
  /// Nothing — the card sits in the middle of the screen.
  none,

  /// Home's level and streak pills.
  levelBadges,

  /// Home's continue-lesson card.
  continueCard,

  /// Home's journey card (the level's units).
  journey,

  /// One destination of the tab bar ([AppGuideStep.tabIndex]).
  tab,
}

/// One stop of the app guide.
class AppGuideStep {
  const AppGuideStep({
    required this.title,
    required this.body,
    this.anchor = AppGuideAnchor.none,
    this.tabIndex,
    this.showStatusLegend = false,
  }) : assert((anchor == AppGuideAnchor.tab) == (tabIndex != null));

  final String title;
  final String body;
  final AppGuideAnchor anchor;

  /// For [AppGuideAnchor.tab]: the destination's index in the tab bar
  /// (Home 0, Learn 1, Review 2, Tests 3, Settings 4).
  final int? tabIndex;

  /// Shows the four progress marks Learn uses, each with its meaning.
  final bool showStatusLegend;
}

/// The guide, in order. It teaches the app as it is: what Home shows, how
/// a level is organised, what the progress marks mean, and what each tab is
/// for — every step points at the real control it describes. The Settings
/// step mentions accounts only in builds where accounts exist.
List<AppGuideStep> appGuideSteps(
  AppLocalizations l10n, {
  required bool accountsAvailable,
}) => [
  AppGuideStep(title: l10n.guideIntroTitle, body: l10n.guideIntroBody),
  AppGuideStep(
    title: l10n.guideLevelTitle,
    body: l10n.guideLevelBody,
    anchor: AppGuideAnchor.levelBadges,
  ),
  AppGuideStep(
    title: l10n.guideContinueTitle,
    body: l10n.guideContinueBody,
    anchor: AppGuideAnchor.continueCard,
  ),
  AppGuideStep(
    title: l10n.guideJourneyTitle,
    body: l10n.guideJourneyBody,
    anchor: AppGuideAnchor.journey,
  ),
  AppGuideStep(
    title: l10n.guideLearnTitle,
    body: l10n.guideLearnBody,
    anchor: AppGuideAnchor.tab,
    tabIndex: 1,
    showStatusLegend: true,
  ),
  AppGuideStep(
    title: l10n.guideReviewTitle,
    body: l10n.guideReviewBody,
    anchor: AppGuideAnchor.tab,
    tabIndex: 2,
  ),
  AppGuideStep(
    title: l10n.guideTestsTitle,
    body: l10n.guideTestsBody,
    anchor: AppGuideAnchor.tab,
    tabIndex: 3,
  ),
  AppGuideStep(
    title: l10n.guideSettingsTitle,
    body: accountsAvailable
        ? l10n.guideSettingsBodyAccount
        : l10n.guideSettingsBody,
    anchor: AppGuideAnchor.tab,
    tabIndex: 4,
  ),
];
