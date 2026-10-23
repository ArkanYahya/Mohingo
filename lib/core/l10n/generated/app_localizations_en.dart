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
  String get activityFeedbackPendingLocalJudgement =>
      'Saved — checking this on your phone';

  @override
  String get activityFeedbackExplanationLabel => 'Explanation';

  @override
  String get activityFeedbackGeneratedLabel => 'Generated on your phone';

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
  String homeAllUnitsMastered(String level) {
    return 'You\'ve mastered every $level unit so far!';
  }

  @override
  String get homeNextLevelOverline => 'Next level';

  @override
  String homeNextLevelTitle(String level) {
    return 'Start $level';
  }

  @override
  String homeNextLevelBody(String current, String next) {
    return 'Every $current unit is mastered, and $next builds straight on it — move when you\'re ready.';
  }

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
  String homeLevelBadge(String cefr, String descriptor) {
    return '$cefr · $descriptor';
  }

  @override
  String get cefrDescriptorA1 => 'Beginner';

  @override
  String get cefrDescriptorA2 => 'Elementary';

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
  String get homeLessonTypeIntegrated => 'Put it together';

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
  String lessonIntroFromLevel(String level) {
    return 'From $level';
  }

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
  String get learnUnitContentUpdated => 'Updated since you last studied it';

  @override
  String learnUnitNodeSemantics(int unit, String state) {
    return 'Unit $unit: $state';
  }

  @override
  String learnUnitOverline(int unit) {
    return 'Unit $unit';
  }

  @override
  String learnLessonInProgressOverline(int lesson) {
    return 'Lesson $lesson · In progress';
  }

  @override
  String learnLessonStartHereOverline(int lesson) {
    return 'Lesson $lesson · Start here';
  }

  @override
  String get learnMissionOverline => 'Unit mission';

  @override
  String get learnMissionBody => 'Shows you\'ve mastered the unit';

  @override
  String get learnLessonCompletedReview => 'Completed · review answers';

  @override
  String get learnLessonNeedsReviewReview =>
      'Some answers to revisit · review answers';

  @override
  String learnLessonNodeSemantics(int lesson, String state) {
    return 'Lesson $lesson: $state';
  }

  @override
  String get learnLessonHasConversation => 'Opens with a conversation';

  @override
  String learnFinishOverline(String level) {
    return 'Finish $level';
  }

  @override
  String get learnFinishTitle => 'Final mission & assessment';

  @override
  String get learnFinishBody =>
      'Show what you can do after the last unit — in the Tests tab.';

  @override
  String learnLevelSemanticsCurrent(String level) {
    return 'Level $level, the one you\'re learning now';
  }

  @override
  String learnLevelSemanticsOpen(String level) {
    return 'Level $level, open — switch to it';
  }

  @override
  String learnLevelSemanticsLocked(String level) {
    return 'Level $level, locked';
  }

  @override
  String learnLevelComingLaterBody(String level) {
    return 'More levels are on the way. Everything you learn in $level carries over.';
  }

  @override
  String levelLockTitle(String level, String previous) {
    return '$level builds on $previous';
  }

  @override
  String levelLockBody(String previous, String level) {
    return 'Finishing $previous opens it. You can check where you stand with the placement test — or open $level anyway.';
  }

  @override
  String get levelLockTakeTest => 'Take the placement test';

  @override
  String levelLockOpenAnyway(String level) {
    return 'Open $level anyway';
  }

  @override
  String levelNotReleasedTitle(String level) {
    return '$level isn\'t ready yet';
  }

  @override
  String get levelNotReleasedBody =>
      'Its lessons open when it\'s ready. Until then you can look at what it covers.';

  @override
  String levelNotReleasedBrowse(String level) {
    return 'See what $level covers';
  }

  @override
  String learnPreviewBannerTitle(String level) {
    return 'A look at $level';
  }

  @override
  String learnPreviewBannerBody(String level) {
    return 'These are the units $level will cover. Its lessons open when it\'s ready.';
  }

  @override
  String learnPreviewBackToCurrent(String level) {
    return 'Back to $level';
  }

  @override
  String get levelFilterLabel => 'Level';

  @override
  String levelFilterSemantics(String level) {
    return 'Level $level';
  }

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
  String lessonPlayerProgress(int current, int total) {
    return '$current of $total';
  }

  @override
  String lessonReviewOverline(int unit, int lesson) {
    return 'Unit $unit · Lesson $lesson · Your answers';
  }

  @override
  String lessonReviewScore(int right, int total) {
    return '$right of $total right';
  }

  @override
  String lessonReviewQuestion(int n) {
    return 'Question $n';
  }

  @override
  String lessonReviewQuestionHeader(int n, String skill) {
    return '$n · $skill';
  }

  @override
  String get lessonReviewRight => 'Right';

  @override
  String get lessonReviewNotQuite => 'Not quite';

  @override
  String get lessonReviewSaved => 'Saved';

  @override
  String get lessonReviewNotAnsweredPill => 'Not answered';

  @override
  String get lessonReviewFilterAll => 'All';

  @override
  String get lessonReviewFilterToRevisit => 'To revisit';

  @override
  String get lessonReviewNothingToRevisit =>
      'Nothing to revisit — every answer was right.';

  @override
  String get lessonReviewPracticeAgain => 'Practise this lesson again';

  @override
  String get lessonReviewNotAnswered => 'You didn\'t answer this one.';

  @override
  String get vocabularyStatDue => 'Due';

  @override
  String get vocabularyStatLearning => 'Learning';

  @override
  String get vocabularyFilterAll => 'All';

  @override
  String get vocabularyFilterSaved => 'Saved';

  @override
  String get vocabularyFilterProductive => 'Speaking & writing';

  @override
  String vocabularyFilterSemantics(String label, int count) {
    return '$label: $count';
  }

  @override
  String get partOfSpeechNoun => 'noun';

  @override
  String get partOfSpeechVerb => 'verb';

  @override
  String get partOfSpeechAdjective => 'adjective';

  @override
  String get partOfSpeechAdverb => 'adverb';

  @override
  String get partOfSpeechNumber => 'number';

  @override
  String get partOfSpeechProperNoun => 'name';

  @override
  String get partOfSpeechPhrase => 'phrase';

  @override
  String get partOfSpeechInterjection => 'interjection';

  @override
  String get partOfSpeechPreposition => 'preposition';

  @override
  String get partOfSpeechConjunction => 'conjunction';

  @override
  String get wordUsageProductive =>
      'You\'ll use this word when speaking and writing.';

  @override
  String get wordUsageReceptive =>
      'You\'ll need to understand this word when listening and reading.';

  @override
  String get wordStatusNew =>
      'Not in your reviews yet — rate it below to add it.';

  @override
  String get wordStatusDue => 'Due for review now';

  @override
  String get wordMetInOverline => 'Where you met it';

  @override
  String wordMetInMeta(int unit, int lesson) {
    return 'Unit $unit · Lesson $lesson';
  }

  @override
  String get vocabularyTabWords => 'Words';

  @override
  String get vocabularyTabChunks => 'Phrases';

  @override
  String get vocabularySearchHint => 'Search English or Arabic';

  @override
  String get vocabularyEmptyResults => 'No words match your search.';

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
  String get grammarEmptyResults => 'No grammar matches your search.';

  @override
  String grammarOverline(int unit) {
    return 'Grammar · Unit $unit';
  }

  @override
  String grammarShortForm(String form) {
    return 'Short form: $form';
  }

  @override
  String get grammarPractisedInOverline => 'Where you practise it';

  @override
  String get grammarMarkReviewed => 'Mark as reviewed';

  @override
  String get grammarReviewed => 'Reviewed';

  @override
  String get grammarQuickPractice => 'Quick practice';

  @override
  String get grammarNoLinkedPractice => 'No linked practice activity yet.';

  @override
  String practiceEyebrow(String title, int n, int total) {
    return 'Practice · $title · $n of $total';
  }

  @override
  String practiceOverline(String title) {
    return 'Practice · $title';
  }

  @override
  String get practiceNoMastery =>
      'Practice here doesn\'t count towards mastery — the lesson and its unit mission do.';

  @override
  String get practiceAgain => 'Practise again';

  @override
  String get quickPracticeDone => 'Done';

  @override
  String get reviewHubSubtitle => 'Keep words fresh and strengthen weak spots.';

  @override
  String get reviewDueOverline => 'Due now';

  @override
  String reviewDueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words and phrases',
      one: '1 word or phrase',
    );
    return '$_temp0';
  }

  @override
  String reviewDueMore(int count) {
    return 'and $count more';
  }

  @override
  String reviewDueMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'about $minutes min',
      one: 'about 1 min',
    );
    return '$_temp0';
  }

  @override
  String get reviewStartCta => 'Start review';

  @override
  String get reviewCaughtUpTitle => 'All caught up';

  @override
  String reviewNextIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Next review in $days days',
      one: 'Next review tomorrow',
      zero: 'Next review later today',
    );
    return '$_temp0';
  }

  @override
  String get reviewCaughtUpEmpty =>
      'Words and phrases from your lessons come back here the day after you learn them.';

  @override
  String get reviewWeakSpotsOverline => 'Practise weak spots';

  @override
  String get reviewWeakSpotsBody =>
      'Goals in the units you\'re working on that need more practice';

  @override
  String reviewWeakSpotMeta(String level, int unit, String skills) {
    return 'Level $level · Unit $unit · $skills';
  }

  @override
  String reviewShowAll(int count) {
    return 'All $count';
  }

  @override
  String get reviewShowFewer => 'Show fewer';

  @override
  String get reviewBrowseOverline => 'Browse';

  @override
  String get reviewWordsTile => 'Words & phrases';

  @override
  String reviewWordsTileMeta(int inReview, int total) {
    return '$inReview of $total in review';
  }

  @override
  String reviewGrammarTileMeta(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count forms',
      one: '1 form',
    );
    return '$_temp0';
  }

  @override
  String get reviewSavedOverline => 'Saved';

  @override
  String get reviewSessionWord => 'Word';

  @override
  String get reviewSessionPhrase => 'Phrase';

  @override
  String get reviewSessionPrompt => 'Say what it means, then check.';

  @override
  String get reviewShowAnswer => 'Show answer';

  @override
  String reviewSeeAgain(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'in $days days',
      one: 'tomorrow',
    );
    return '$_temp0';
  }

  @override
  String reviewSessionProgress(int current, int total) {
    return '$current of $total';
  }

  @override
  String get reviewSessionDoneTitle => 'Review done';

  @override
  String reviewSessionDoneBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words and phrases reviewed',
      one: '1 word or phrase reviewed',
    );
    return '$_temp0';
  }

  @override
  String get reviewSessionDoneCta => 'Done';

  @override
  String get reviewSessionEmpty => 'Nothing to review right now.';

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
  String get settingsSpeechTitle => 'Listening & speaking';

  @override
  String get settingsSpeechRate => 'Voice speed';

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
  String testsHubSubtitle(String level) {
    return 'See where you are in $level — and prove it at the end.';
  }

  @override
  String get testsStartHereOverline => 'Start here';

  @override
  String get testsPlacementHeroTitle => 'Find your starting point';

  @override
  String get testsPlacementHeroBody =>
      'Already know some English? A short placement test skips what you know.';

  @override
  String get testsPlacementMeta => 'Stops as soon as it finds your level';

  @override
  String get testsPlacementCta => 'Take the placement test';

  @override
  String get testsPlacementOverline => 'Placement';

  @override
  String get testsPlacementTitle => 'Placement test';

  @override
  String testsTakenOn(String date) {
    return 'Taken $date';
  }

  @override
  String get testsNotTaken => 'Not taken';

  @override
  String get testsNotFinished => 'Not finished';

  @override
  String testsPlacementResultUnit(String level, int unit) {
    return 'Result: start at $level Unit $unit';
  }

  @override
  String testsPlacementResultMastered(String level) {
    return 'Result: $level already mastered';
  }

  @override
  String testsFinishOverline(String level) {
    return 'Finish $level';
  }

  @override
  String testsFinishProgress(int mastered, int total) {
    return '$mastered of $total units mastered — best taken when you\'ve finished the course.';
  }

  @override
  String testsFinishReady(int total) {
    return 'All $total units mastered — you\'re ready.';
  }

  @override
  String testsMissionBody(String level) {
    return 'Use everything from $level in one real-life scenario, stage by stage.';
  }

  @override
  String testsMissionMeta(int tasks, int stages, int min, int max) {
    return '$tasks tasks · $stages stages · $min–$max min';
  }

  @override
  String get testsAssessmentBody =>
      'Every skill is scored on its own — a weak skill can\'t hide behind the others.';

  @override
  String testsAssessmentMeta(int questions, int skills, int min, int max) {
    return '$questions questions · $skills skills · $min–$max min';
  }

  @override
  String get testsPassed => 'Passed';

  @override
  String get testsNotPassedYet => 'Not passed yet';

  @override
  String testsSkillsPassed(int passed, int total) {
    return '$passed of $total skills passed';
  }

  @override
  String get testsUnitChecksNote =>
      'Each unit is checked as you go — its mission is on the Learn tab.';

  @override
  String get testAnswerSaved => 'Answer saved';

  @override
  String get testAnswerSavedBody => 'You\'ll see your results at the end.';

  @override
  String get testNextQuestion => 'Next question';

  @override
  String get testRulesNote =>
      'Answers aren\'t marked as you go and transcripts are hidden. You\'ll see your results at the end.';

  @override
  String get testIntroCoversHeading => 'What it covers';

  @override
  String get testIntroStagesHeading => 'The stages';

  @override
  String testIntroQuestionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questions',
      one: '1 question',
    );
    return '$_temp0';
  }

  @override
  String testIntroTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
    );
    return '$_temp0';
  }

  @override
  String testQuestionEyebrow(String section, int n, int total) {
    return '$section · $n of $total';
  }

  @override
  String get testsMissionOverline => 'Final mission';

  @override
  String get testsAssessmentOverline => 'Final assessment';

  @override
  String get placementCoversReceptive =>
      'Listening and reading questions from each unit, easiest first';

  @override
  String get placementCoversProductive =>
      'One writing or speaking task at the end';

  @override
  String get placementCoversStops =>
      'Stops at the first unit that\'s new to you';

  @override
  String placementIntroTitle(String level) {
    return 'Placement test up to $level';
  }

  @override
  String placementIntroBody(String level) {
    return 'A few questions from each unit, easiest first, all the way up to $level. It stops at the first unit that\'s new to you — so the more you already know, the longer it runs.';
  }

  @override
  String placementUnitSection(String level, int unit) {
    return '$level · Unit $unit';
  }

  @override
  String get placementStartButton => 'Start the placement test';

  @override
  String get testsResultHowYouDid => 'How you did';

  @override
  String testsSkillScore(int right, int total) {
    return '$right of $total';
  }

  @override
  String get testsWaitingReview => 'Waiting for review';

  @override
  String get testsPendingBody =>
      'Your answers are saved; this skill is scored once they\'re checked.';

  @override
  String testsScorePassMark(int score, int mark) {
    return '$score% · pass mark $mark%';
  }

  @override
  String get placementResultOverline => 'Placement result';

  @override
  String placementResultHeadline(String level, int unit) {
    return '$level Unit $unit is where to begin';
  }

  @override
  String get placementResultBodyEssentials =>
      'Unit 1 gives you the basics every other unit builds on.';

  @override
  String placementResultBodyLevelStart(String level) {
    return 'You\'re ready for $level — start it from the very beginning.';
  }

  @override
  String placementResultBodyUnit(int unit) {
    return 'You know the units before it well. Unit $unit is where new things begin for you.';
  }

  @override
  String placementResultMasteredTitle(String level) {
    return '$level looks mastered';
  }

  @override
  String get placementResultMasteredBody =>
      'Take the final assessment to prove it. Higher levels are on the way.';

  @override
  String get placementResultEarlierOpen =>
      'Earlier units stay open — go back to any lesson whenever you like.';

  @override
  String placementResultStartAtUnit(String level, int unit) {
    return 'Start at $level Unit $unit';
  }

  @override
  String get placementConfidence1 => 'Not at all confident';

  @override
  String get placementConfidence2 => 'A little confident';

  @override
  String get placementConfidence3 => 'Fairly confident';

  @override
  String get placementConfidence4 => 'Quite confident';

  @override
  String get placementConfidence5 => 'Very confident';

  @override
  String get placementConfidenceNote =>
      'Your answer doesn\'t change your result.';

  @override
  String get missionResultPassedTitle => 'Mission complete';

  @override
  String get missionResultPassedBody =>
      'Every required skill came through across the day.';

  @override
  String get missionResultNotYetTitle => 'Not passed yet';

  @override
  String get missionResultNotYetBody =>
      'Some skills need more practice — see below. You can take the mission again any time.';

  @override
  String assessmentResultPassedTitle(String level) {
    return 'You passed $level';
  }

  @override
  String get assessmentResultNotYetTitle => 'Not passed yet';

  @override
  String assessmentResultBody(int passed, int total) {
    return '$passed of $total skills passed.';
  }

  @override
  String get placementConfidenceQuestion =>
      'Overall, how confident did that feel?';

  @override
  String get placementResultDone => 'Done';

  @override
  String get finalMissionStartButton => 'Begin the mission';

  @override
  String get finalMissionDone => 'Done';

  @override
  String finalAssessmentIntroBody(String level) {
    return 'The exit test for $level. Each skill is scored on its own — a strong score in one never covers for a weak one in another.';
  }

  @override
  String get finalAssessmentStartButton => 'Start the assessment';

  @override
  String get finalAssessmentSkillPassed => 'Passed';

  @override
  String get finalAssessmentSkillNotMet => 'Not yet met';

  @override
  String get finalAssessmentDone => 'Done';

  @override
  String get finalAssessmentWhatsNext => 'Keep practicing';

  @override
  String get contentNotFoundTitle => 'Content not found';

  @override
  String get grammarSectionTitle => 'Grammar';

  @override
  String get favoriteAddTooltip => 'Add to favorites';

  @override
  String get favoriteRemoveTooltip => 'Remove from favorites';

  @override
  String get settingsAppearanceOverline => 'Appearance';

  @override
  String get settingsLanguageBody =>
      'Lessons stay in English; this changes menus and help.';

  @override
  String get settingsSlower => 'Slower';

  @override
  String get settingsFaster => 'Faster';

  @override
  String get settingsTryVoice => 'Try it';

  @override
  String get settingsMicTitle => 'Microphone';

  @override
  String get settingsMicAllowed =>
      'Allowed — you can answer speaking tasks aloud.';

  @override
  String get settingsMicNotYet =>
      'Not allowed yet — needed to answer speaking tasks aloud.';

  @override
  String get settingsMicDenied =>
      'Not allowed — needed to answer speaking tasks aloud.';

  @override
  String get settingsMicBlocked =>
      'Blocked — turn it on in your phone\'s settings for Mohingo.';

  @override
  String get settingsMicAllow => 'Allow';

  @override
  String get settingsSttTitle => 'Speech recognition';

  @override
  String get settingsSttOn => 'Available for English on this device.';

  @override
  String get settingsSttOff =>
      'Not available on this device. You can type your speaking answers instead.';

  @override
  String get settingsDataOverline => 'Your data';

  @override
  String get settingsOfflineTitle => 'Works offline';

  @override
  String get settingsOfflineBody =>
      'Every lesson works without internet. Without an account, your progress stays on this phone.';

  @override
  String get settingsResetProgressBody =>
      'Erase every lesson, test result and review on this device.';

  @override
  String get settingsNameEmpty => 'Add your name';

  @override
  String settingsProfileMeta(String level) {
    return 'Learning English · $level';
  }

  @override
  String get settingsEdit => 'Edit';

  @override
  String get settingsInterfaceLanguageTitle => 'App language';

  @override
  String get settingsThemeModeTitle => 'Theme';

  @override
  String get settingsThemeModeLight => 'Light';

  @override
  String get settingsThemeModeDark => 'Dark';

  @override
  String get settingsThemeModeSystem => 'Automatic';

  @override
  String get settingsNameTitle => 'Your name';

  @override
  String get settingsNameHint =>
      'Used on Home and in a few spelling exercises.';

  @override
  String get settingsNameSaveButton => 'Save';

  @override
  String get settingsNameSaved => 'Name saved';

  @override
  String get settingsResetProgressTitle => 'Reset progress';

  @override
  String get settingsResetProgressConfirmTitle => 'Reset all progress?';

  @override
  String get settingsResetProgressConfirmBody =>
      'This erases every lesson and unit, test result, review schedule and saved word on this device. It can\'t be undone.';

  @override
  String get settingsResetProgressConfirmAction => 'Reset';

  @override
  String get settingsResetProgressCancel => 'Cancel';

  @override
  String get settingsResetProgressDone => 'Progress reset.';

  @override
  String get settingsSmartFeedbackTitle => 'Smart feedback';

  @override
  String get settingsSmartFeedbackBodyUnavailable =>
      'A one-time download that explains your writing and speaking answers, on your phone. Not in this version yet.';

  @override
  String get settingsSmartFeedbackBodyNotInstalled =>
      'A one-time download that explains your writing and speaking answers, on your phone. Works offline once downloaded.';

  @override
  String get settingsSmartFeedbackBodyDownloading => 'Downloading…';

  @override
  String get settingsSmartFeedbackBodyInstalled =>
      'Explaining your answers on this phone. Nothing leaves it.';

  @override
  String get settingsSmartFeedbackDownload => 'Download';

  @override
  String get settingsSmartFeedbackDelete => 'Delete';

  @override
  String get settingsBackupTitle => 'Backup & sync';

  @override
  String get settingsBackupBody =>
      'Reinstalling the app or changing phones starts fresh for now.';

  @override
  String get speakPartnerTitle => 'The other person says';

  @override
  String get speakPartnerPlay => 'Hear it again';

  @override
  String get lessonIntroReadTitle => 'Read the text';

  @override
  String get accountSectionTitle => 'Account & sync';

  @override
  String get accountGuestTitle => 'Save your progress to an account';

  @override
  String get accountGuestBody =>
      'Sign in to keep your progress safe and carry on from another phone.';

  @override
  String get accountSignInAction => 'Sign in';

  @override
  String get accountYourAccount => 'Your account';

  @override
  String get accountSyncing => 'Syncing…';

  @override
  String get accountNotSyncedYet => 'Not synced yet';

  @override
  String accountSyncedAt(String time) {
    return 'Last synced $time';
  }

  @override
  String get accountSyncOffline =>
      'You\'re offline. Your progress is saved on this phone and will sync when you\'re back online.';

  @override
  String get accountSyncFailed =>
      'Couldn\'t sync just now. We\'ll try again shortly.';

  @override
  String get accountSyncSignedOut =>
      'Your sign-in has expired. Sign out and sign in again to keep syncing.';

  @override
  String accountPendingChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to sync',
      one: '1 change waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String get accountSyncNow => 'Sync now';

  @override
  String get accountSignOutTitle => 'Sign out';

  @override
  String get accountSignOutBody => 'Your progress stays in your account.';

  @override
  String get accountSignOutConfirmTitle => 'Sign out?';

  @override
  String get accountSignOutConfirmBody =>
      'This phone will show guest progress until you sign in again. Your account keeps its progress.';

  @override
  String get accountSignOutPendingBody =>
      'Some progress hasn\'t synced yet. It stays on this phone and syncs the next time you sign in here.';

  @override
  String get accountCancel => 'Cancel';

  @override
  String get accountSignedOut => 'Signed out.';

  @override
  String get accountSignedIn => 'Signed in. Your progress will sync.';

  @override
  String get accountDecisionPendingTitle =>
      'Choose what to do with this phone\'s progress';

  @override
  String get accountDecisionPendingBody =>
      'Your account won\'t sync until you choose.';

  @override
  String get accountDecisionAction => 'Choose';

  @override
  String get guestProgressTitle =>
      'Add this phone\'s progress to your account?';

  @override
  String get guestProgressBody =>
      'This phone has progress from before you signed in. You can add it to your account, where it joins anything your account already has, or keep it on this phone only.';

  @override
  String get guestProgressAttach => 'Add to my account';

  @override
  String get guestProgressKeepSeparate => 'Keep it on this phone';

  @override
  String get authSignInTitle => 'Sign in';

  @override
  String get authCreateTitle => 'Create an account';

  @override
  String get authIntro =>
      'Your account keeps your lessons, reviews and test results, so you can carry on from any phone. You can keep learning without one.';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authPasswordHint => 'At least 6 characters';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authSignInAction => 'Sign in';

  @override
  String get authCreateAction => 'Create account';

  @override
  String get authForgotPasswordLink => 'Forgot password?';

  @override
  String get authOr => 'or';

  @override
  String get authGoogleAction => 'Continue with Google';

  @override
  String get authAppleAction => 'Continue with Apple';

  @override
  String get authSwitchToCreate => 'New here? Create an account';

  @override
  String get authSwitchToSignIn => 'Already have an account? Sign in';

  @override
  String get authEmailInvalid => 'Enter a valid email address.';

  @override
  String get authPasswordRequired => 'Enter your password.';

  @override
  String get authPasswordTooShort => 'Use at least 6 characters.';

  @override
  String get authPasswordsDontMatch => 'The passwords don\'t match.';

  @override
  String get authErrorInvalidEmail => 'That email address doesn\'t look right.';

  @override
  String get authErrorWrongCredentials => 'The email or password is incorrect.';

  @override
  String get authErrorEmailInUse =>
      'An account with this email already exists. Try signing in instead.';

  @override
  String get authErrorWeakPassword =>
      'Choose a stronger password with at least 6 characters.';

  @override
  String get authErrorUserDisabled => 'This account has been disabled.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Wait a few minutes and try again.';

  @override
  String get authErrorNetwork =>
      'No internet connection. Connect and try again. You can keep learning offline meanwhile.';

  @override
  String get authErrorDifferentMethod =>
      'This email is registered with another sign-in method. Try that method instead.';

  @override
  String get authErrorUnavailable => 'Accounts aren\'t available right now.';

  @override
  String get authErrorUnknown => 'Something went wrong. Please try again.';

  @override
  String get authResetTitle => 'Reset your password';

  @override
  String get authResetBody =>
      'Enter your account\'s email and we\'ll send you a link to choose a new password.';

  @override
  String get authResetAction => 'Send link';

  @override
  String authResetSent(String email) {
    return 'If an account exists for $email, a reset link is on its way. Check your inbox.';
  }

  @override
  String get authBackToSignIn => 'Back to sign in';

  @override
  String get settingsResetProgressBodyAccount =>
      'Erase every lesson, test result and review on all your devices.';

  @override
  String get settingsResetProgressConfirmBodyAccount =>
      'This erases every lesson and unit, test result, review schedule and saved word, on this phone and on every other phone signed in to your account. It can\'t be undone.';

  @override
  String get settingsOfflineTitleAccount => 'Works offline';

  @override
  String get settingsOfflineBodyAccount =>
      'Every lesson works without internet. Your progress is also copied to your account.';

  @override
  String get errorGenericTitle => 'Something went wrong';

  @override
  String get errorGenericBody =>
      'This page couldn\'t be opened. Your progress is safe — go back and try again.';

  @override
  String get legalPrivacyTitle => 'Privacy Policy';

  @override
  String get legalTermsTitle => 'Terms of Use';

  @override
  String get welcomeTitle => 'Welcome to Mohingo';

  @override
  String get welcomeSubtitle =>
      'An English course for Arabic speakers. It works without internet and keeps your progress on your phone.';

  @override
  String get welcomeUpdatedNotice =>
      'We\'ve updated the Privacy Policy and Terms of Use. Please take a look, then accept to continue.';

  @override
  String get welcomePrivacyHeading => 'Your privacy, in brief';

  @override
  String get welcomeLocalTitle => 'Your progress stays on your phone';

  @override
  String get welcomeLocalBody =>
      'Lessons, answers and settings are saved on this device. No ads, no analytics, no tracking.';

  @override
  String get welcomeAccountTitle => 'An account is optional';

  @override
  String get welcomeAccountBody =>
      'If you sign in, your progress and name are copied to your account (Google Firebase) so you can use them on other phones. Without an account, your progress is never uploaded.';

  @override
  String get welcomeWritingTitle => 'Checking some written answers';

  @override
  String get welcomeWritingBody =>
      'When you\'re online, the text of some typed answers is sent to LanguageTool, a grammar-checking service, to help mark them. Nothing that identifies you is sent with it.';

  @override
  String get welcomeSpeechTitle => 'Speaking tasks';

  @override
  String get welcomeSpeechBody =>
      'Your phone\'s speech recognition (from Google or Apple) turns your voice into text and may do so online. Mohingo keeps only the text, never the recording.';

  @override
  String get welcomeConsentLine =>
      'By continuing, you agree to the Terms of Use and confirm you\'ve read the Privacy Policy.';

  @override
  String get welcomeAccept => 'Accept and continue';

  @override
  String guideStepCounter(int current, int total) {
    return '$current of $total';
  }

  @override
  String get guideSkip => 'Skip';

  @override
  String get guideBack => 'Back';

  @override
  String get guideNext => 'Next';

  @override
  String get guideDone => 'Done';

  @override
  String get guideIntroTitle => 'A quick tour';

  @override
  String get guideIntroBody =>
      'Here\'s where everything is in Mohingo. It takes under a minute, and you can open this guide again from Settings.';

  @override
  String get guideLevelTitle => 'Your level';

  @override
  String get guideLevelBody =>
      'This shows the level you\'re studying (A1 is where beginners start) and your streak: how many days in a row you\'ve studied.';

  @override
  String get guideContinueTitle => 'Your next lesson';

  @override
  String get guideContinueBody =>
      'Tap here to start your next lesson or carry on where you stopped. Each lesson opens with a short conversation, then practice in listening, reading, speaking and writing.';

  @override
  String get guideJourneyTitle => 'Your path through the level';

  @override
  String get guideJourneyBody =>
      'A level is made of units, and each unit of short lessons that end with a unit mission. Each segment of this track is a unit; tap it to see them all.';

  @override
  String get guideLearnTitle => 'Learn';

  @override
  String get guideLearnBody =>
      'Every unit and lesson, in order. Open a finished lesson to review your answers. These marks show where you are:';

  @override
  String get guideLegendDone => 'Finished lesson, or mastered unit';

  @override
  String get guideReviewTitle => 'Review';

  @override
  String get guideReviewBody =>
      'The words and grammar from your lessons. Words come back for review just before you\'re likely to forget them, and the number on this tab shows how many are due.';

  @override
  String get guideTestsTitle => 'Tests';

  @override
  String get guideTestsBody =>
      'A placement test to find where to start, and at the end of each level a final mission and a final assessment.';

  @override
  String get guideSettingsTitle => 'Settings';

  @override
  String get guideSettingsBody =>
      'Change the app language, light or dark mode and the voice speed. This guide is here too, under App guide.';

  @override
  String get guideSettingsBodyAccount =>
      'Change the app language, light or dark mode and the voice speed. You can also sign in here to keep your progress on more than one phone — that part is optional. This guide is here too, under App guide.';

  @override
  String get settingsHelpOverline => 'Help & information';

  @override
  String get settingsGuideTitle => 'App guide';

  @override
  String get settingsGuideBody => 'A short tour of where everything is.';

  @override
  String get settingsAboutTitle => 'About Mohingo';

  @override
  String get settingsAboutBody => 'Version, privacy policy and terms';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutDescription =>
      'An English course for Arabic speakers, organised by CEFR level from A1. Every lesson works offline, in Arabic and English.';

  @override
  String get aboutPrivacyBody =>
      'What the app stores and what can leave your phone';

  @override
  String get aboutTermsBody => 'The rules for using Mohingo';

  @override
  String get aboutLicensesTitle => 'Open-source licences';

  @override
  String get aboutLicensesBody => 'The software Mohingo is built with';

  @override
  String get accountDeleteTitle => 'Delete account';

  @override
  String get accountDeleteBody =>
      'Permanently delete your account and its copy of your progress.';

  @override
  String get accountDeleteConfirmTitle => 'Delete your account?';

  @override
  String get accountDeleteConfirmBody =>
      'This permanently deletes your Mohingo account, the copy of your progress stored with it, and this account\'s progress on this phone. It can\'t be undone. Progress you made on this phone without signing in is kept.';

  @override
  String get accountDeleteContinue => 'Continue';

  @override
  String get accountDeletePasswordTitle => 'Confirm it\'s you';

  @override
  String accountDeletePasswordBody(String email) {
    return 'To delete the account, enter the password for $email.';
  }

  @override
  String get accountDeletePasswordBodyNoEmail =>
      'To delete the account, enter its password.';

  @override
  String get accountDeleteGoogleBody =>
      'To delete the account, choose your Google account again.';

  @override
  String get accountDeleteAppleBody =>
      'To delete the account, confirm with Apple that it\'s you.';

  @override
  String get accountDeleting => 'Deleting your account…';

  @override
  String get accountDeleted => 'Your account has been deleted.';

  @override
  String get accountDeleteFailed =>
      'Your account couldn\'t be deleted. Check your internet connection and try again.';

  @override
  String get authErrorRecentLogin =>
      'For your security, please confirm your password or account again.';

  @override
  String get authErrorWrongAccount =>
      'That\'s a different account. Choose the account you\'re signed in with.';
}
