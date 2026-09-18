// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mohingo';

  @override
  String get navHome => 'Home';

  @override
  String get navLearn => 'Learn';

  @override
  String get navReview => 'Review';

  @override
  String get navTests => 'Tests';

  @override
  String get navSettings => 'Settings';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String placeholderScreenBody(String screenName) {
    return '$screenName — coming in a later phase.';
  }

  @override
  String get activitySubmitButton => 'Check';

  @override
  String get activityFeedbackCorrect => 'Correct!';

  @override
  String activityFeedbackIncorrectWithAnswer(String correctAnswer) {
    return 'Not quite — the correct answer is: $correctAnswer';
  }

  @override
  String get activityFeedbackSavedForReview =>
      'Saved — this will be reviewed, not auto-graded.';

  @override
  String get activityFeedbackPendingOnlineRefinement =>
      'Saved — we\'ll finish checking this once you\'re online';

  @override
  String get activitySpeechUnavailableUseWriting =>
      'Speaking practice isn\'t available on this device yet — type your answer instead.';

  @override
  String get activityContinue => 'Continue';

  @override
  String get activityFeedbackIncorrectTitle => 'Not quite';

  @override
  String get activityFeedbackCorrectAnswerLabel => 'Correct answer';

  @override
  String get activityFeedbackSavedTitle => 'Answer saved';

  @override
  String get activityListenTitle => 'Listen';

  @override
  String get activityListenHint => 'Tap to play again';

  @override
  String get activityListenSlower => 'Slower';

  @override
  String activityWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String activityWordGuideTarget(int min, int max) {
    return 'Aim for $min–$max';
  }

  @override
  String activityMatchProgress(int matched, int total) {
    return '$matched of $total matched';
  }

  @override
  String get activityOrderEmptyHint => 'Tap the words in order';

  @override
  String get activityAnswerFieldHint => 'Type your answer';

  @override
  String get activityShowTranscript => 'Show transcript';

  @override
  String get contentErrorTitle => 'Couldn\'t load your lessons';

  @override
  String get contentErrorBody =>
      'Something went wrong loading the course content. Try reinstalling the app; your progress is saved separately and won\'t be lost.';

  @override
  String get unitStateNotStarted => 'Not started';

  @override
  String get unitStateInProgress => 'In progress';

  @override
  String get unitStateMastered => 'Mastered';

  @override
  String get unitStateNeedsReview => 'Needs review';

  @override
  String get lessonStateCompleted => 'Completed';

  @override
  String get vocabularyStateLearned => 'Learned';

  @override
  String unitOverviewLessonsComplete(int completed, int total) {
    return '$completed of $total lessons complete';
  }

  @override
  String get homeAllUnitsMastered => 'You\'ve mastered every A1 unit so far!';

  @override
  String homeLevelProgressCaption(int mastered, int total) {
    return '$mastered of $total units mastered';
  }

  @override
  String homeReviewDueTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items due for review',
      one: '1 item due for review',
      zero: 'Nothing due for review',
    );
    return '$_temp0';
  }

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String homeLevelBadge(String cefr) {
    return '$cefr · Beginner';
  }

  @override
  String homeStreakChip(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
      zero: 'No streak',
    );
    return '$_temp0';
  }

  @override
  String homeUnitLessonOverline(int unit, int lesson) {
    return 'Unit $unit · Lesson $lesson';
  }

  @override
  String homeUnitReviewOverline(int unit) {
    return 'Unit $unit · Review';
  }

  @override
  String get homeUnitAllLessonsDone =>
      'Every lesson played — review this unit to master it.';

  @override
  String homeActivityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities',
      one: '1 activity',
    );
    return '$_temp0';
  }

  @override
  String get homeLessonTypeGuided => 'Guided lesson';

  @override
  String get homeLessonTypePractice => 'Practice';

  @override
  String get homeLessonTypeConversation => 'Conversation';

  @override
  String get homeLessonTypeMission => 'Mission';

  @override
  String get homeLessonProgressLabel => 'Lesson progress';

  @override
  String get homeLessonNew => 'New lesson';

  @override
  String homeLessonPercent(int percent) {
    return '$percent%';
  }

  @override
  String get homeStartLessonCta => 'Start lesson';

  @override
  String get homeContinueLessonCta => 'Continue lesson';

  @override
  String get homeOpenUnitCta => 'Open unit';

  @override
  String get homeTodaysGoalTitle => 'Today\'s goal';

  @override
  String homeGoalsDone(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get homeJourneyTitle => 'Your journey';

  @override
  String homeJourneyUnitOf(int current, int total) {
    return 'Unit $current of $total';
  }

  @override
  String homeJourneyNow(String title) {
    return 'Now · $title';
  }

  @override
  String homeJourneyNext(String title) {
    return 'Next · $title';
  }

  @override
  String get homeReviewNowCta => 'Review now';

  @override
  String get homeTaskFinishLesson => 'Finish a lesson';

  @override
  String get homeTaskReviewWords => 'Review 5 words';

  @override
  String get homeTaskSpeakOnce => 'Speak once';

  @override
  String get lessonCompleteTitle => 'Lesson complete';

  @override
  String lessonCompleteTally(int correct, int total) {
    return '$correct of $total correct';
  }

  @override
  String lessonCompletePendingReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count answers saved for review',
      one: '1 answer saved for review',
    );
    return '$_temp0';
  }

  @override
  String get lessonCompleteNextLesson => 'Next lesson';

  @override
  String get lessonCompleteBackToUnit => 'Back to unit';

  @override
  String get lessonPlayerClose => 'Close lesson';

  @override
  String get lessonPlayerPhaseWarmUp => 'Warm-up';

  @override
  String get lessonPlayerPhasePractice => 'Practice';

  @override
  String get lessonPlayerPhaseUseIt => 'Use it';

  @override
  String lessonPlayerEyebrow(String phase, String skill) {
    return '$phase · $skill';
  }

  @override
  String get lessonIntroListenTitle => 'Listen to the conversation';

  @override
  String get lessonIntroListenHint => 'Tap any line to hear it again';

  @override
  String get lessonIntroPlayConversation => 'Play the conversation';

  @override
  String get lessonIntroStopConversation => 'Stop the conversation';

  @override
  String get lessonIntroArabicToggle => 'Arabic translation';

  @override
  String get lessonIntroPlaying => 'Playing';

  @override
  String get lessonIntroKeyPhrasesTitle => 'Key phrases';

  @override
  String get lessonIntroGrammarTitle => 'Grammar';

  @override
  String get lessonIntroNew => 'New';

  @override
  String get lessonIntroStartPractice => 'Start practice';

  @override
  String get learnCourseOverline => 'Your course';

  @override
  String get learnUnitsTitle => 'Units';

  @override
  String learnLessonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lessons',
      one: '1 lesson',
    );
    return '$_temp0';
  }

  @override
  String learnUnitMinutes(int min, int max) {
    return '$min–$max min';
  }

  @override
  String get learnUnitStarter => 'Starter';

  @override
  String learnUnitInProgressOverline(int unit) {
    return 'Unit $unit · In progress';
  }

  @override
  String learnUnitStartHereOverline(int unit) {
    return 'Unit $unit · Start here';
  }

  @override
  String learnUnitLessonsDone(int done, int total) {
    return '$done of $total lessons';
  }

  @override
  String learnUnitNodeSemantics(int unit, String state) {
    return 'Unit $unit: $state';
  }

  @override
  String get learnFinishOverline => 'Finish A1';

  @override
  String get learnFinishTitle => 'Final mission & assessment';

  @override
  String get learnFinishBody =>
      'Show what you can do after the last unit — in the Tests tab.';

  @override
  String get learnComingLaterTitle => 'Coming later';

  @override
  String get learnComingLaterBody =>
      'More levels are on the way. Everything you learn in A1 carries over.';

  @override
  String get lessonCompleteCorrectCaption => 'correct';

  @override
  String get lessonCompleteStreakLabel => 'Streak';

  @override
  String get lessonCompleteAccuracyLabel => 'Accuracy';

  @override
  String get lessonCompletePhrasesLabel => 'Phrases';

  @override
  String get lessonCompleteQuestionsLabel => 'Questions';

  @override
  String get lessonCompleteSkillsTitle => 'Skills practised';

  @override
  String lessonCompleteUpNext(int lesson) {
    return 'Up next · Lesson $lesson';
  }

  @override
  String get lessonCompleteReviewAnswers => 'Review answers';

  @override
  String get lessonPlayerNext => 'Next';

  @override
  String lessonPlayerProgress(int current, int total) {
    return '$current of $total';
  }

  @override
  String get lessonReviewPracticeAgain => 'Practice again';

  @override
  String get lessonReviewNotAnswered => 'Not answered';

  @override
  String get vocabularyStatDue => 'Due';

  @override
  String get vocabularyStatLearning => 'Learning';

  @override
  String get vocabularySavedWordsTitle => 'Saved words';

  @override
  String get vocabularyTabWords => 'Words';

  @override
  String get vocabularyTabChunks => 'Phrases';

  @override
  String get vocabularySearchHint => 'Search English or Arabic';

  @override
  String get vocabularyFavoritesOnly => 'Favourites only';

  @override
  String get vocabularyProductiveOnly => 'Productive only';

  @override
  String get vocabularyEmptyResults => 'No words match your search.';

  @override
  String wordDetailIntroducedIn(String unitTitle) {
    return 'Introduced in $unitTitle';
  }

  @override
  String get wordDetailExamples => 'Examples';

  @override
  String get reviewHowWellKnew => 'How well did you know this?';

  @override
  String get reviewQualityAgain => 'Again';

  @override
  String get reviewQualityGood => 'Good';

  @override
  String get reviewQualityEasy => 'Easy';

  @override
  String get reviewConfidenceSaved => 'Saved';

  @override
  String get grammarDetailForm => 'Form';

  @override
  String get grammarDetailLinkedLessons => 'Practiced in';

  @override
  String get grammarMarkReviewed => 'Mark as reviewed';

  @override
  String get grammarReviewed => 'Reviewed';

  @override
  String get grammarQuickPractice => 'Quick practice';

  @override
  String get grammarNoLinkedPractice => 'No linked practice activity yet.';

  @override
  String get quickPracticeDone => 'Done';

  @override
  String get reviewSectionDue => 'Due for review';

  @override
  String get reviewSectionFavorites => 'Favourites';

  @override
  String get reviewSectionWeakObjectives => 'Needs more practice';

  @override
  String get reviewNothingDue => 'Nothing due right now.';

  @override
  String get reviewNoFavorites =>
      'No favourites yet — star words, phrases, or grammar to save them here.';

  @override
  String get reviewNoWeakObjectives => 'Nothing flagged — keep going!';

  @override
  String get speakTapToRecord => 'Tap to record';

  @override
  String get speakTapToRecordHint =>
      'You can check what we heard before you submit.';

  @override
  String get speakTapToStop => 'Tap to stop';

  @override
  String get speakEnableMicrophoneHint => 'We only listen while you record.';

  @override
  String get speakShowUsefulPhrases => 'Show useful phrases';

  @override
  String get speakHideUsefulPhrases => 'Hide useful phrases';

  @override
  String get speakEnableMicrophone => 'Enable microphone';

  @override
  String get speakStartRecording => 'Record';

  @override
  String get speakStopRecording => 'Stop';

  @override
  String get speakListening => 'Listening…';

  @override
  String get speakReviewTranscript =>
      'Review what was heard before submitting:';

  @override
  String get speakUseTypedAnswerInstead => 'Type my answer instead';

  @override
  String get speakRerecord => 'Record again';

  @override
  String get speakPermissionPermanentlyDenied =>
      'Microphone access is turned off for this app. You can still type your answer, or enable it in your device settings.';

  @override
  String get settingsSpeechTitle => 'Speech';

  @override
  String get settingsSpeechRate => 'Speaking rate';

  @override
  String get settingsSpeechPitch => 'Voice pitch';

  @override
  String get settingsMicPermissionGranted => 'Microphone access: allowed';

  @override
  String get settingsMicPermissionDenied => 'Microphone access: not allowed';

  @override
  String get settingsMicPermissionPermanentlyDenied =>
      'Microphone access: blocked — enable it in device settings';

  @override
  String get settingsMicPermissionNotDetermined =>
      'Microphone access: not yet requested';

  @override
  String get settingsSttAvailable =>
      'On-device speech recognition: available for English';

  @override
  String get settingsSttUnavailable =>
      'On-device speech recognition: not available on this device — you can still type answers to speaking tasks';

  @override
  String get speechListen => 'Listen';

  @override
  String get skillListening => 'Listening';

  @override
  String get skillReading => 'Reading';

  @override
  String get skillWriting => 'Writing';

  @override
  String get skillSpokenInteraction => 'Spoken interaction';

  @override
  String get skillSpokenProduction => 'Spoken production';

  @override
  String get skillMediation => 'Mediation';

  @override
  String get skillSpeaking => 'Speaking';

  @override
  String get testsHomePlacementTitle => 'A1 Gateway Placement Test';

  @override
  String get testsHomePlacementSubtitle =>
      'Not sure where to start? Find your best starting point in A1.';

  @override
  String get testsHomeFinalMissionTitle => 'A1 Final Mission';

  @override
  String get testsHomeFinalMissionSubtitle =>
      'A scenario-based capstone that pulls together everything you\'ve learned.';

  @override
  String get testsHomeFinalAssessmentTitle => 'A1 Final Assessment';

  @override
  String get testsHomeFinalAssessmentSubtitle =>
      'A short exit test covering every skill, scored separately — no single score hides a weak skill.';

  @override
  String get testsHomeUnitChecksTitle => 'Unit mastery checks';

  @override
  String get testsHomeUnitChecksSubtitle =>
      'See how each unit is progressing on the Learn tab.';

  @override
  String get testsHomeFutureLevelsTitle => 'A2 and beyond placement';

  @override
  String get testsHomeNotYetTaken => 'Not yet taken';

  @override
  String get testsHomeInProgress => 'In progress';

  @override
  String testsHomeCompletedOn(String date) {
    return 'Completed $date';
  }

  @override
  String get placementIntroTitle => 'A1 Gateway Placement Test';

  @override
  String get placementIntroBody =>
      'A few quick questions across the A1 units, from easiest to hardest. We\'ll stop as soon as we find your starting point — most people finish in a few minutes.';

  @override
  String get placementStartButton => 'Start';

  @override
  String get placementConfidenceQuestion =>
      'Overall, how confident did that feel?';

  @override
  String get placementConfidenceLow => 'Not very';

  @override
  String get placementConfidenceHigh => 'Very confident';

  @override
  String get placementResultTitle => 'Your result';

  @override
  String get placementOutcomeStartWithEssentials =>
      'Start with English Essentials (Unit 0) — it\'ll give you the footing the rest of A1 builds on.';

  @override
  String get placementOutcomeStartA1FromU1 =>
      'You know the essentials — start A1 from Unit 1.';

  @override
  String placementOutcomeStartFromUnit(String unitTitle) {
    return 'You\'re ahead in the early units — start from $unitTitle.';
  }

  @override
  String get placementOutcomeMastered =>
      'A1 appears mastered — great work! Higher-level placement isn\'t available yet, but it\'s coming.';

  @override
  String get placementResultGoToUnit => 'Go to this unit';

  @override
  String get placementResultDone => 'Done';

  @override
  String get finalMissionStartButton => 'Begin';

  @override
  String get finalMissionResultTitle => 'Mission result';

  @override
  String get finalMissionPassed =>
      'Mission complete — every required skill area came through.';

  @override
  String get finalMissionNotYetTitle => 'Not quite there yet';

  @override
  String get finalMissionDone => 'Done';

  @override
  String get finalAssessmentIntroBody =>
      'A short exit test covering every skill from A1. Each skill is scored on its own — a strong score in one never covers for a weak one in another.';

  @override
  String get finalAssessmentStartButton => 'Begin';

  @override
  String get finalAssessmentResultTitle => 'Assessment result';

  @override
  String get finalAssessmentOverallPassed =>
      'Every required skill met the bar for A1.';

  @override
  String get finalAssessmentOverallNotYet =>
      'Not every required skill met the bar yet — see the breakdown below.';

  @override
  String get finalAssessmentSkillPassed => 'Passed';

  @override
  String get finalAssessmentSkillNotMet => 'Not yet met';

  @override
  String get finalAssessmentSkillPendingReview => 'Pending review';

  @override
  String get finalAssessmentDone => 'Done';

  @override
  String finalAssessmentSectionScore(int percent) {
    return '$percent%';
  }

  @override
  String get finalAssessmentWhatsNext => 'Keep practicing';

  @override
  String get contentNotFoundTitle => 'Content not found';

  @override
  String get grammarSectionTitle => 'Grammar';

  @override
  String get grammarFilterAllUnits => 'All';

  @override
  String get vocabularyReceptiveLabel => 'Receptive';

  @override
  String get vocabularyProductiveLabel => 'Productive';

  @override
  String get favoriteAddTooltip => 'Add to favorites';

  @override
  String get favoriteRemoveTooltip => 'Remove from favorites';

  @override
  String get settingsInterfaceLanguageTitle => 'Interface language';

  @override
  String get settingsThemeModeTitle => 'Theme';

  @override
  String get settingsThemeModeLight => 'Light';

  @override
  String get settingsThemeModeDark => 'Dark';

  @override
  String get settingsThemeModeSystem => 'System';

  @override
  String get settingsColorThemeTitle => 'Colour theme';

  @override
  String get settingsNameTitle => 'Your name';

  @override
  String get settingsNameHint => 'Used by a few spelling exercises';

  @override
  String get settingsNameSaveButton => 'Save';

  @override
  String get settingsNameSaved => 'Name saved';

  @override
  String get settingsAboutTitle => 'About';

  @override
  String get settingsAboutBody =>
      'Mohingo works fully offline — your lessons, progress, and any speaking answers stay on this device. Nothing is uploaded anywhere, and there\'s no account to create.';

  @override
  String get settingsResetProgressTitle => 'Reset progress';

  @override
  String get settingsResetProgressButton => 'Reset progress';

  @override
  String get settingsResetProgressConfirmTitle => 'Reset all progress?';

  @override
  String get settingsResetProgressConfirmBody =>
      'This erases every unit\'s progress, mastery evidence, placement/mission/assessment results, and vocabulary/grammar favourites on this device. This can\'t be undone.';

  @override
  String get settingsResetProgressConfirmAction => 'Reset';

  @override
  String get settingsResetProgressCancel => 'Cancel';

  @override
  String get settingsResetProgressDone => 'Progress reset.';

  @override
  String get settingsBackupTitle => 'Backup & sync';

  @override
  String get settingsBackupBody =>
      'Coming soon. For now, your progress stays on this device only — reinstalling the app or switching devices starts fresh.';
}
