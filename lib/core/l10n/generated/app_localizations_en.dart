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
  String get lessonPlayerNext => 'Next';

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
  String get settingsSpeechPitch => 'Voice pitch';

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
  String testsPlacementResultUnit(int unit) {
    return 'Result: start from Unit $unit';
  }

  @override
  String get testsPlacementResultMastered => 'Result: A1 already mastered';

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
  String get placementIntroTitle => 'A1 Gateway Placement Test';

  @override
  String get placementIntroBody =>
      'A few questions from each A1 unit, easiest first. It stops at the first unit that\'s new to you — so the more you already know, the longer it runs.';

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
  String placementResultHeadline(int unit) {
    return 'Start from Unit $unit';
  }

  @override
  String get placementResultBodyEssentials =>
      'Unit 1 gives you the basics every other unit builds on.';

  @override
  String placementResultBodyUnit(int unit) {
    return 'You know the units before it well. Unit $unit is where new things begin for you.';
  }

  @override
  String get placementResultMasteredTitle => 'A1 looks mastered';

  @override
  String get placementResultMasteredBody =>
      'Take the final assessment to prove it. Higher levels are on the way.';

  @override
  String get placementResultEarlierOpen =>
      'Earlier units stay open — go back to any lesson whenever you like.';

  @override
  String placementResultGoToUnitN(int unit) {
    return 'Go to Unit $unit';
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
  String get settingsLower => 'Lower';

  @override
  String get settingsHigher => 'Higher';

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
  String get settingsOfflineTitle => 'Stays on this device';

  @override
  String get settingsOfflineBody =>
      'Works fully offline. Nothing is uploaded and there is no account.';

  @override
  String get settingsResetProgressBody =>
      'Erase every lesson, test result and review on this device.';

  @override
  String settingsVersion(String version) {
    return 'Mohingo · version $version';
  }

  @override
  String get settingsNameEmpty => 'Add your name';

  @override
  String get settingsProfileMeta => 'Learning English · A1';

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
  String get settingsColorThemeTitle => 'Colour';

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
}
