import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// The application name, shown as the OS app title. Not translated per-locale — brand name stays the same in both languages.
  ///
  /// In en, this message translates to:
  /// **'Mohingo'**
  String get appTitle;

  /// Bottom navigation label for the Home tab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation label for the Learn tab (level catalogue and guided unit path).
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get navLearn;

  /// Bottom navigation label for the Review tab (vocabulary, grammar, due items).
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get navReview;

  /// Bottom navigation label for the Tests tab (placement, unit checks, final mission/assessment).
  ///
  /// In en, this message translates to:
  /// **'Tests'**
  String get navTests;

  /// Bottom navigation label for the Settings tab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Label shown on a CEFR level card (A2-C2) that has no content yet and cannot be selected.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// Body text for a scaffold screen that has no real content yet.
  ///
  /// In en, this message translates to:
  /// **'{screenName} — coming in a later phase.'**
  String placeholderScreenBody(String screenName);

  /// Button label to submit an answer for grading.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get activitySubmitButton;

  /// Feedback shown when the learner's answer was right.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get activityFeedbackCorrect;

  /// Feedback shown when the learner's answer was wrong, revealing the correct answer for this activity only (never other activities).
  ///
  /// In en, this message translates to:
  /// **'Not quite — the correct answer is: {correctAnswer}'**
  String activityFeedbackIncorrectWithAnswer(String correctAnswer);

  /// Feedback shown for writing/speaking activities, which need a task-specific rubric rather than an automatic right/wrong check.
  ///
  /// In en, this message translates to:
  /// **'Saved — this will be reviewed, not auto-graded.'**
  String get activityFeedbackSavedForReview;

  /// Feedback banner shown after submitting an open-ended writing/speaking answer whose full grading is deferred until the device is online (Tier 2 online refinement).
  ///
  /// In en, this message translates to:
  /// **'Saved — we\'ll finish checking this once you\'re online'**
  String get activityFeedbackPendingOnlineRefinement;

  /// Shown on a speak activity's typed-answer accessibility fallback. Never phrased as a permanent limitation of the learner's ability, only the device/build.
  ///
  /// In en, this message translates to:
  /// **'Speaking practice isn\'t available on this device yet — type your answer instead.'**
  String get activitySpeechUnavailableUseWriting;

  /// Button in the lesson player's feedback panel that moves on to the next question.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get activityContinue;

  /// Title of the lesson player's feedback panel after a wrong answer.
  ///
  /// In en, this message translates to:
  /// **'Not quite'**
  String get activityFeedbackIncorrectTitle;

  /// Small label above the correct answer in the lesson player's feedback panel after a wrong answer.
  ///
  /// In en, this message translates to:
  /// **'Correct answer'**
  String get activityFeedbackCorrectAnswerLabel;

  /// Title of the lesson player's feedback panel for an answer that is saved rather than graded right away.
  ///
  /// In en, this message translates to:
  /// **'Answer saved'**
  String get activityFeedbackSavedTitle;

  /// Title on the audio card of a listening question.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get activityListenTitle;

  /// Hint under the audio card title of a listening question.
  ///
  /// In en, this message translates to:
  /// **'Tap to play again'**
  String get activityListenHint;

  /// Button on the audio card that replays the audio at a slower speed.
  ///
  /// In en, this message translates to:
  /// **'Slower'**
  String get activityListenSlower;

  /// Live word count under a writing answer.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word} other{{count} words}}'**
  String activityWordCount(int count);

  /// Suggested length shown next to the live word count of a writing answer.
  ///
  /// In en, this message translates to:
  /// **'Aim for {min}–{max}'**
  String activityWordGuideTarget(int min, int max);

  /// Progress line under a matching question.
  ///
  /// In en, this message translates to:
  /// **'{matched} of {total} matched'**
  String activityMatchProgress(int matched, int total);

  /// Placeholder in the empty answer area of a build-the-sentence question.
  ///
  /// In en, this message translates to:
  /// **'Tap the words in order'**
  String get activityOrderEmptyHint;

  /// Placeholder inside a typed-answer field.
  ///
  /// In en, this message translates to:
  /// **'Type your answer'**
  String get activityAnswerFieldHint;

  /// Button on a listening activity's audio card that reveals the hidden transcript text on demand.
  ///
  /// In en, this message translates to:
  /// **'Show transcript'**
  String get activityShowTranscript;

  /// Title shown when the curriculum bundle fails to parse or has an unsupported schema version.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your lessons'**
  String get contentErrorTitle;

  /// Body text for the unsupported-content error screen. Reassures the learner that progress (stored separately from content) is safe.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong loading the course content. Try reinstalling the app; your progress is saved separately and won\'t be lost.'**
  String get contentErrorBody;

  /// Unit progress badge.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get unitStateNotStarted;

  /// Unit progress badge.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get unitStateInProgress;

  /// Unit progress badge.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get unitStateMastered;

  /// Unit/lesson progress badge — was mastered but evidence or content has gone stale.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get unitStateNeedsReview;

  /// Lesson-row status label for a lesson the learner has played to its last activity. Deliberately NOT "Mastered": mastery is course/Can-Do evidence meeting MasteryAggregationService's policy (see docs/GLOSSARY.md), which simply reaching a lesson's end does not establish.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get lessonStateCompleted;

  /// Vocabulary/chunk row status label for an item recalled enough times to have graduated the spaced-review schedule. Deliberately NOT "Mastered": memorising a word is not course mastery (see docs/GLOSSARY.md).
  ///
  /// In en, this message translates to:
  /// **'Learned'**
  String get vocabularyStateLearned;

  /// Unit overview header caption — how many of this unit's lessons have been played through to the end.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} lessons complete'**
  String unitOverviewLessonsComplete(int completed, int total);

  /// Shown on Home when there is no next unit to recommend.
  ///
  /// In en, this message translates to:
  /// **'You\'ve mastered every A1 unit so far!'**
  String get homeAllUnitsMastered;

  /// Home level-progress card caption.
  ///
  /// In en, this message translates to:
  /// **'{mastered} of {total} units mastered'**
  String homeLevelProgressCaption(int mastered, int total);

  /// Home review-due card title.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing due for review} =1{1 item due for review} other{{count} items due for review}}'**
  String homeReviewDueTitle(int count);

  /// Home header greeting, 05:00–11:59.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreetingMorning;

  /// Home header greeting, 12:00–16:59.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGreetingAfternoon;

  /// Home header greeting, 17:00–04:59.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGreetingEvening;

  /// Home header chip: the learner's current CEFR level and its plain-language descriptor.
  ///
  /// In en, this message translates to:
  /// **'{cefr} · Beginner'**
  String homeLevelBadge(String cefr);

  /// Home header streak chip, next to a flame icon.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{No streak} =1{1 day} other{{days} days}}'**
  String homeStreakChip(int days);

  /// Overline on the continue-lesson hero card.
  ///
  /// In en, this message translates to:
  /// **'Unit {unit} · Lesson {lesson}'**
  String homeUnitLessonOverline(int unit, int lesson);

  /// Overline on the hero card when every lesson in the unit has been played but the unit isn't mastered yet.
  ///
  /// In en, this message translates to:
  /// **'Unit {unit} · Review'**
  String homeUnitReviewOverline(int unit);

  /// Hero card body when the current unit's lessons are all played but it isn't mastered.
  ///
  /// In en, this message translates to:
  /// **'Every lesson played — review this unit to master it.'**
  String get homeUnitAllLessonsDone;

  /// Hero card meta line — how many activities the current lesson has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 activity} other{{count} activities}}'**
  String homeActivityCount(int count);

  /// Hero card meta: lessonType encounter-focus-practice (a presented model, then focused practice).
  ///
  /// In en, this message translates to:
  /// **'Guided lesson'**
  String get homeLessonTypeGuided;

  /// Hero card meta: lessonType focus-practice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get homeLessonTypePractice;

  /// Hero card meta: lessonType communication.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get homeLessonTypeConversation;

  /// Hero card meta: lessonType mission (a unit's capstone task).
  ///
  /// In en, this message translates to:
  /// **'Mission'**
  String get homeLessonTypeMission;

  /// Label above the hero card's lesson progress bar.
  ///
  /// In en, this message translates to:
  /// **'Lesson progress'**
  String get homeLessonProgressLabel;

  /// Shown in place of a percentage when the current lesson hasn't been started.
  ///
  /// In en, this message translates to:
  /// **'New lesson'**
  String get homeLessonNew;

  /// Lesson progress percentage on the hero card.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String homeLessonPercent(int percent);

  /// Hero card primary button when the current lesson hasn't been started.
  ///
  /// In en, this message translates to:
  /// **'Start lesson'**
  String get homeStartLessonCta;

  /// Hero card primary button when the current lesson is part-way through.
  ///
  /// In en, this message translates to:
  /// **'Continue lesson'**
  String get homeContinueLessonCta;

  /// Hero card primary button when every lesson is played but the unit isn't mastered.
  ///
  /// In en, this message translates to:
  /// **'Open unit'**
  String get homeOpenUnitCta;

  /// Section title above the three daily-goal rows.
  ///
  /// In en, this message translates to:
  /// **'Today\'s goal'**
  String get homeTodaysGoalTitle;

  /// Summary next to the Today's goal title.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String homeGoalsDone(int done, int total);

  /// Title of the level-progress card.
  ///
  /// In en, this message translates to:
  /// **'Your journey'**
  String get homeJourneyTitle;

  /// Level-progress card: the learner's position in the level's unit sequence.
  ///
  /// In en, this message translates to:
  /// **'Unit {current} of {total}'**
  String homeJourneyUnitOf(int current, int total);

  /// Level-progress card: the unit the learner is on.
  ///
  /// In en, this message translates to:
  /// **'Now · {title}'**
  String homeJourneyNow(String title);

  /// Level-progress card: the unit (or final mission) that comes after the current one.
  ///
  /// In en, this message translates to:
  /// **'Next · {title}'**
  String homeJourneyNext(String title);

  /// Button on the review-due card when items are due.
  ///
  /// In en, this message translates to:
  /// **'Review now'**
  String get homeReviewNowCta;

  /// Home daily-task tile label — finish 1 lesson today.
  ///
  /// In en, this message translates to:
  /// **'Finish a lesson'**
  String get homeTaskFinishLesson;

  /// Home daily-task tile label — review 5 vocabulary words today.
  ///
  /// In en, this message translates to:
  /// **'Review 5 words'**
  String get homeTaskReviewWords;

  /// Home daily-task tile label — complete 1 speaking activity today.
  ///
  /// In en, this message translates to:
  /// **'Speak once'**
  String get homeTaskSpeakOnce;

  /// Shown after finishing the last activity in a lesson.
  ///
  /// In en, this message translates to:
  /// **'Lesson complete'**
  String get lessonCompleteTitle;

  /// Lesson-complete screen: auto-graded correct/total tally.
  ///
  /// In en, this message translates to:
  /// **'{correct} of {total} correct'**
  String lessonCompleteTally(int correct, int total);

  /// Lesson-complete screen: writing/speaking answers not auto-graded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 answer saved for review} other{{count} answers saved for review}}'**
  String lessonCompletePendingReview(int count);

  /// Lesson-complete screen CTA when more lessons remain in the unit.
  ///
  /// In en, this message translates to:
  /// **'Next lesson'**
  String get lessonCompleteNextLesson;

  /// Lesson-complete screen CTA when this was the unit's last lesson.
  ///
  /// In en, this message translates to:
  /// **'Back to unit'**
  String get lessonCompleteBackToUnit;

  /// Accessibility label of the close button at the top of the lesson player.
  ///
  /// In en, this message translates to:
  /// **'Close lesson'**
  String get lessonPlayerClose;

  /// Lesson phase for first-exposure (encounter) questions.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get lessonPlayerPhaseWarmUp;

  /// Lesson phase for practice questions.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get lessonPlayerPhasePractice;

  /// Lesson phase for mastery questions, where the learner uses what they learned.
  ///
  /// In en, this message translates to:
  /// **'Use it'**
  String get lessonPlayerPhaseUseIt;

  /// Line above each question naming its lesson phase and skill, e.g. 'Practice · Reading'.
  ///
  /// In en, this message translates to:
  /// **'{phase} · {skill}'**
  String lessonPlayerEyebrow(String phase, String skill);

  /// Title of the conversation card at the start of a lesson.
  ///
  /// In en, this message translates to:
  /// **'Listen to the conversation'**
  String get lessonIntroListenTitle;

  /// Hint under the conversation card title: each line is tappable.
  ///
  /// In en, this message translates to:
  /// **'Tap any line to hear it again'**
  String get lessonIntroListenHint;

  /// Accessibility label of the button that plays every line of the lesson conversation.
  ///
  /// In en, this message translates to:
  /// **'Play the conversation'**
  String get lessonIntroPlayConversation;

  /// Accessibility label of the same button while the conversation is playing.
  ///
  /// In en, this message translates to:
  /// **'Stop the conversation'**
  String get lessonIntroStopConversation;

  /// Switch that shows or hides the Arabic translation under each conversation line.
  ///
  /// In en, this message translates to:
  /// **'Arabic translation'**
  String get lessonIntroArabicToggle;

  /// Small label next to the speaker name on the conversation line being read aloud.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get lessonIntroPlaying;

  /// Title of the lesson's key phrases screen, shown after the conversation.
  ///
  /// In en, this message translates to:
  /// **'Key phrases'**
  String get lessonIntroKeyPhrasesTitle;

  /// Section title for the lesson's grammar forms on the key phrases screen.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get lessonIntroGrammarTitle;

  /// Badge on a key phrase this lesson introduces for the first time.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get lessonIntroNew;

  /// Button that leaves the lesson intro for its first question.
  ///
  /// In en, this message translates to:
  /// **'Start practice'**
  String get lessonIntroStartPractice;

  /// Overline above the course title at the top of the Learn tab.
  ///
  /// In en, this message translates to:
  /// **'Your course'**
  String get learnCourseOverline;

  /// Section title above the course's unit path.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get learnUnitsTitle;

  /// Number of lessons, in a unit or the whole course.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 lesson} other{{count} lessons}}'**
  String learnLessonCount(int count);

  /// Estimated time to finish a unit.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max} min'**
  String learnUnitMinutes(int min, int max);

  /// Tag on the course's introductory unit, which prepares for the rest and doesn't count towards A1 mastery.
  ///
  /// In en, this message translates to:
  /// **'Starter'**
  String get learnUnitStarter;

  /// Overline on the highlighted card for the unit the learner is working on.
  ///
  /// In en, this message translates to:
  /// **'Unit {unit} · In progress'**
  String learnUnitInProgressOverline(int unit);

  /// Overline on the highlighted card for the unit a learner who hasn't started it yet should begin with.
  ///
  /// In en, this message translates to:
  /// **'Unit {unit} · Start here'**
  String learnUnitStartHereOverline(int unit);

  /// Lessons finished in a unit.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} lessons'**
  String learnUnitLessonsDone(int done, int total);

  /// Screen-reader label of a unit's circle on the path.
  ///
  /// In en, this message translates to:
  /// **'Unit {unit}: {state}'**
  String learnUnitNodeSemantics(int unit, String state);

  /// Overline above the unit title on a unit page.
  ///
  /// In en, this message translates to:
  /// **'Unit {unit}'**
  String learnUnitOverline(int unit);

  /// Overline on the highlighted card for the lesson the learner is part-way through.
  ///
  /// In en, this message translates to:
  /// **'Lesson {lesson} · In progress'**
  String learnLessonInProgressOverline(int lesson);

  /// Overline on the highlighted card for the next lesson to start.
  ///
  /// In en, this message translates to:
  /// **'Lesson {lesson} · Start here'**
  String learnLessonStartHereOverline(int lesson);

  /// Overline on a unit's mission lesson.
  ///
  /// In en, this message translates to:
  /// **'Unit mission'**
  String get learnMissionOverline;

  /// Line on a unit's mission lesson explaining what it's for.
  ///
  /// In en, this message translates to:
  /// **'Shows you\'ve mastered the unit'**
  String get learnMissionBody;

  /// Status line on a finished lesson, which opens its answer review when tapped.
  ///
  /// In en, this message translates to:
  /// **'Completed · review answers'**
  String get learnLessonCompletedReview;

  /// Status line on a finished lesson whose latest answers include mistakes; tapping opens its answer review.
  ///
  /// In en, this message translates to:
  /// **'Some answers to revisit · review answers'**
  String get learnLessonNeedsReviewReview;

  /// Screen-reader label of a lesson's circle on the unit page.
  ///
  /// In en, this message translates to:
  /// **'Lesson {lesson}: {state}'**
  String learnLessonNodeSemantics(int lesson, String state);

  /// Accessibility label of the small icon on lessons that open with an encounter conversation.
  ///
  /// In en, this message translates to:
  /// **'Opens with a conversation'**
  String get learnLessonHasConversation;

  /// Overline on the card at the end of the unit path.
  ///
  /// In en, this message translates to:
  /// **'Finish A1'**
  String get learnFinishOverline;

  /// Title of the card at the end of the unit path.
  ///
  /// In en, this message translates to:
  /// **'Final mission & assessment'**
  String get learnFinishTitle;

  /// Body of the card at the end of the unit path; it opens the Tests tab.
  ///
  /// In en, this message translates to:
  /// **'Show what you can do after the last unit — in the Tests tab.'**
  String get learnFinishBody;

  /// Section title above the list of levels that aren't available yet.
  ///
  /// In en, this message translates to:
  /// **'Coming later'**
  String get learnComingLaterTitle;

  /// Line under the not-yet-available levels.
  ///
  /// In en, this message translates to:
  /// **'More levels are on the way. Everything you learn in A1 carries over.'**
  String get learnComingLaterBody;

  /// Small word under the correct/total fraction inside the lesson-complete score ring, e.g. '3/4' over 'correct'.
  ///
  /// In en, this message translates to:
  /// **'correct'**
  String get lessonCompleteCorrectCaption;

  /// Label of the streak figure on the lesson-complete screen.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get lessonCompleteStreakLabel;

  /// Label of the percentage-correct figure on the lesson-complete screen.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get lessonCompleteAccuracyLabel;

  /// Label of the count of the lesson's key phrases on the lesson-complete screen.
  ///
  /// In en, this message translates to:
  /// **'Phrases'**
  String get lessonCompletePhrasesLabel;

  /// Label of the count of questions answered, used on the lesson-complete screen when the lesson has no key phrases.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get lessonCompleteQuestionsLabel;

  /// Section title above the skills the lesson's questions trained.
  ///
  /// In en, this message translates to:
  /// **'Skills practised'**
  String get lessonCompleteSkillsTitle;

  /// Overline on the card previewing the next lesson in the unit.
  ///
  /// In en, this message translates to:
  /// **'Up next · Lesson {lesson}'**
  String lessonCompleteUpNext(int lesson);

  /// Secondary action on the lesson-complete screen that opens the lesson's answer review.
  ///
  /// In en, this message translates to:
  /// **'Review answers'**
  String get lessonCompleteReviewAnswers;

  /// Button to advance to the next activity after seeing feedback.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get lessonPlayerNext;

  /// Lesson player app bar progress indicator, e.g. "3 of 6".
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String lessonPlayerProgress(int current, int total);

  /// Button on the lesson review screen (a finished lesson's read-only answer walkthrough) that starts a fresh replay of the lesson.
  ///
  /// In en, this message translates to:
  /// **'Practice again'**
  String get lessonReviewPracticeAgain;

  /// Placeholder shown on the lesson review screen for an activity with no recorded attempt at all (e.g. content changed after the lesson was finished).
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get lessonReviewNotAnswered;

  /// Vocabulary screen stat tile label — count of words overdue for spaced review.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get vocabularyStatDue;

  /// Vocabulary screen stat tile label — count of words recalled at least once but not yet graduated the spaced-review schedule.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get vocabularyStatLearning;

  /// Filter chip on the words and phrases list: no status filter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get vocabularyFilterAll;

  /// Filter chip on the words and phrases list: starred items only.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get vocabularyFilterSaved;

  /// Filter chip on the words list: only words the learner is expected to use when speaking and writing.
  ///
  /// In en, this message translates to:
  /// **'Speaking & writing'**
  String get vocabularyFilterProductive;

  /// Screen-reader label of a status filter chip with its count.
  ///
  /// In en, this message translates to:
  /// **'{label}: {count}'**
  String vocabularyFilterSemantics(String label, int count);

  /// Part of speech shown above a word.
  ///
  /// In en, this message translates to:
  /// **'noun'**
  String get partOfSpeechNoun;

  /// Part of speech shown above a word.
  ///
  /// In en, this message translates to:
  /// **'verb'**
  String get partOfSpeechVerb;

  /// Part of speech shown above a word.
  ///
  /// In en, this message translates to:
  /// **'adjective'**
  String get partOfSpeechAdjective;

  /// Part of speech shown above a word.
  ///
  /// In en, this message translates to:
  /// **'adverb'**
  String get partOfSpeechAdverb;

  /// Part of speech shown above a word.
  ///
  /// In en, this message translates to:
  /// **'number'**
  String get partOfSpeechNumber;

  /// Part of speech shown above a word: a proper noun.
  ///
  /// In en, this message translates to:
  /// **'name'**
  String get partOfSpeechProperNoun;

  /// Part of speech shown above a word.
  ///
  /// In en, this message translates to:
  /// **'phrase'**
  String get partOfSpeechPhrase;

  /// Part of speech shown above a word.
  ///
  /// In en, this message translates to:
  /// **'interjection'**
  String get partOfSpeechInterjection;

  /// Part of speech shown above a word.
  ///
  /// In en, this message translates to:
  /// **'preposition'**
  String get partOfSpeechPreposition;

  /// Part of speech shown above a word.
  ///
  /// In en, this message translates to:
  /// **'conjunction'**
  String get partOfSpeechConjunction;

  /// Word page: the word is one the learner should be able to produce.
  ///
  /// In en, this message translates to:
  /// **'You\'ll use this word when speaking and writing.'**
  String get wordUsageProductive;

  /// Word page: the word only needs to be recognised.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to understand this word when listening and reading.'**
  String get wordUsageReceptive;

  /// Word or phrase page: the item has never been rated.
  ///
  /// In en, this message translates to:
  /// **'Not in your reviews yet — rate it below to add it.'**
  String get wordStatusNew;

  /// Word or phrase page: the item is due for review.
  ///
  /// In en, this message translates to:
  /// **'Due for review now'**
  String get wordStatusDue;

  /// Word or phrase page: heading above the lesson that introduces it.
  ///
  /// In en, this message translates to:
  /// **'Where you met it'**
  String get wordMetInOverline;

  /// Under the lesson that introduces a word: its unit and lesson numbers.
  ///
  /// In en, this message translates to:
  /// **'Unit {unit} · Lesson {lesson}'**
  String wordMetInMeta(int unit, int lesson);

  /// Vocabulary screen tab label.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get vocabularyTabWords;

  /// Vocabulary screen tab label for functional chunks.
  ///
  /// In en, this message translates to:
  /// **'Phrases'**
  String get vocabularyTabChunks;

  /// Vocabulary search field hint text.
  ///
  /// In en, this message translates to:
  /// **'Search English or Arabic'**
  String get vocabularySearchHint;

  /// Shown when a vocabulary search/filter combination matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No words match your search.'**
  String get vocabularyEmptyResults;

  /// Section heading on word/grammar detail screens.
  ///
  /// In en, this message translates to:
  /// **'Examples'**
  String get wordDetailExamples;

  /// Prompt above the spaced-review confidence buttons.
  ///
  /// In en, this message translates to:
  /// **'How well did you know this?'**
  String get reviewHowWellKnew;

  /// Spaced-review confidence button — did not recall it.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get reviewQualityAgain;

  /// Spaced-review confidence button — recalled it correctly.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get reviewQualityGood;

  /// Spaced-review confidence button — recalled it easily.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get reviewQualityEasy;

  /// Grammar list when the search matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No grammar matches your search.'**
  String get grammarEmptyResults;

  /// Overline on a grammar page: the unit that introduces the form.
  ///
  /// In en, this message translates to:
  /// **'Grammar · Unit {unit}'**
  String grammarOverline(int unit);

  /// Under a grammar form: its contracted form.
  ///
  /// In en, this message translates to:
  /// **'Short form: {form}'**
  String grammarShortForm(String form);

  /// Grammar page: heading above the lessons that practise the form.
  ///
  /// In en, this message translates to:
  /// **'Where you practise it'**
  String get grammarPractisedInOverline;

  /// Button on grammar detail screen.
  ///
  /// In en, this message translates to:
  /// **'Mark as reviewed'**
  String get grammarMarkReviewed;

  /// Shown once a grammar item has been marked reviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get grammarReviewed;

  /// Button on grammar detail screen linking to a practice activity.
  ///
  /// In en, this message translates to:
  /// **'Quick practice'**
  String get grammarQuickPractice;

  /// Shown when a grammar item has no linked practice activity to launch.
  ///
  /// In en, this message translates to:
  /// **'No linked practice activity yet.'**
  String get grammarNoLinkedPractice;

  /// Button to leave the quick-practice screen.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get quickPracticeDone;

  /// Line under the Review tab's title.
  ///
  /// In en, this message translates to:
  /// **'Keep words fresh and strengthen weak spots.'**
  String get reviewHubSubtitle;

  /// Overline on the Review tab's card of words and phrases due for review.
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get reviewDueOverline;

  /// How many words and phrases are due for review.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word or phrase} other{{count} words and phrases}}'**
  String reviewDueCount(int count);

  /// After the first few due words: how many others are due.
  ///
  /// In en, this message translates to:
  /// **'and {count} more'**
  String reviewDueMore(int count);

  /// Rough time a review session will take.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{about 1 min} other{about {minutes} min}}'**
  String reviewDueMinutes(int minutes);

  /// Button that starts a review session of the due words and phrases.
  ///
  /// In en, this message translates to:
  /// **'Start review'**
  String get reviewStartCta;

  /// Review tab card when nothing is due for review.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get reviewCaughtUpTitle;

  /// When the next word or phrase comes due, in calendar days from today.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Next review later today} =1{Next review tomorrow} other{Next review in {days} days}}'**
  String reviewNextIn(int days);

  /// Review tab card when the learner has nothing in spaced review yet.
  ///
  /// In en, this message translates to:
  /// **'Words and phrases from your lessons come back here the day after you learn them.'**
  String get reviewCaughtUpEmpty;

  /// Review tab section of Can-Do goals that need more practice.
  ///
  /// In en, this message translates to:
  /// **'Practise weak spots'**
  String get reviewWeakSpotsOverline;

  /// Line under the weak-spots section heading.
  ///
  /// In en, this message translates to:
  /// **'Goals in the units you\'re working on that need more practice'**
  String get reviewWeakSpotsBody;

  /// Under a weak spot's lesson title: its unit and the skills it practises.
  ///
  /// In en, this message translates to:
  /// **'Unit {unit} · {skills}'**
  String reviewWeakSpotMeta(int unit, String skills);

  /// Expands a shortened Review tab list to show every item.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String reviewShowAll(int count);

  /// Collapses an expanded Review tab list.
  ///
  /// In en, this message translates to:
  /// **'Show fewer'**
  String get reviewShowFewer;

  /// Review tab section linking to the words and grammar lists.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get reviewBrowseOverline;

  /// Review tab tile that opens the words and phrases list.
  ///
  /// In en, this message translates to:
  /// **'Words & phrases'**
  String get reviewWordsTile;

  /// Under the Words & phrases tile: how many are in spaced review out of all.
  ///
  /// In en, this message translates to:
  /// **'{inReview} of {total} in review'**
  String reviewWordsTileMeta(int inReview, int total);

  /// Under the Grammar tile: how many grammar forms the course has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 form} other{{count} forms}}'**
  String reviewGrammarTileMeta(int count);

  /// Review tab section of starred words, phrases and grammar.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get reviewSavedOverline;

  /// Overline on a review card for a single word.
  ///
  /// In en, this message translates to:
  /// **'Word'**
  String get reviewSessionWord;

  /// Overline on a review card for a phrase.
  ///
  /// In en, this message translates to:
  /// **'Phrase'**
  String get reviewSessionPhrase;

  /// Hint on the front of a review card.
  ///
  /// In en, this message translates to:
  /// **'Say what it means, then check.'**
  String get reviewSessionPrompt;

  /// Button that reveals a review card's meaning.
  ///
  /// In en, this message translates to:
  /// **'Show answer'**
  String get reviewShowAnswer;

  /// Under each rating button: when the item will come back.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{tomorrow} other{in {days} days}}'**
  String reviewSeeAgain(int days);

  /// Position in the review session.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String reviewSessionProgress(int current, int total);

  /// Title at the end of a review session.
  ///
  /// In en, this message translates to:
  /// **'Review done'**
  String get reviewSessionDoneTitle;

  /// How many items the session reviewed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word or phrase reviewed} other{{count} words and phrases reviewed}}'**
  String reviewSessionDoneBody(int count);

  /// Closes the finished review session.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get reviewSessionDoneCta;

  /// Review session opened with nothing due.
  ///
  /// In en, this message translates to:
  /// **'Nothing to review right now.'**
  String get reviewSessionEmpty;

  /// Empty state for the favourites section.
  ///
  /// In en, this message translates to:
  /// **'No favourites yet — star words, phrases, or grammar to save them here.'**
  String get reviewNoFavorites;

  /// Empty state for the weak-objectives section.
  ///
  /// In en, this message translates to:
  /// **'Nothing flagged — keep going!'**
  String get reviewNoWeakObjectives;

  /// Caption under the microphone button of a speaking question.
  ///
  /// In en, this message translates to:
  /// **'Tap to record'**
  String get speakTapToRecord;

  /// Reassurance under the record caption: nothing is submitted without review.
  ///
  /// In en, this message translates to:
  /// **'You can check what we heard before you submit.'**
  String get speakTapToRecordHint;

  /// Caption under the stop button while a speaking answer is being recorded.
  ///
  /// In en, this message translates to:
  /// **'Tap to stop'**
  String get speakTapToStop;

  /// Privacy reassurance under the enable-microphone caption.
  ///
  /// In en, this message translates to:
  /// **'We only listen while you record.'**
  String get speakEnableMicrophoneHint;

  /// Toggle under a speaking question that reveals the lesson's phrases as optional help.
  ///
  /// In en, this message translates to:
  /// **'Show useful phrases'**
  String get speakShowUsefulPhrases;

  /// The same toggle once the phrases are showing.
  ///
  /// In en, this message translates to:
  /// **'Hide useful phrases'**
  String get speakHideUsefulPhrases;

  /// Button shown when speech recognition is available but microphone permission hasn't been granted yet.
  ///
  /// In en, this message translates to:
  /// **'Enable microphone'**
  String get speakEnableMicrophone;

  /// Button to start speaking into the microphone.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get speakStartRecording;

  /// Button to stop recording and review the transcript.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get speakStopRecording;

  /// Shown while the microphone is actively recording.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get speakListening;

  /// Label above the temporary transcript, shown before the learner submits.
  ///
  /// In en, this message translates to:
  /// **'Review what was heard before submitting:'**
  String get speakReviewTranscript;

  /// Lets the learner switch to the typed fallback even when the microphone is available.
  ///
  /// In en, this message translates to:
  /// **'Type my answer instead'**
  String get speakUseTypedAnswerInstead;

  /// Button to discard the current transcript and record again.
  ///
  /// In en, this message translates to:
  /// **'Record again'**
  String get speakRerecord;

  /// Shown when the OS reports microphone permission as permanently denied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is turned off for this app. You can still type your answer, or enable it in your device settings.'**
  String get speakPermissionPermanentlyDenied;

  /// Settings section/screen title for TTS/STT options.
  ///
  /// In en, this message translates to:
  /// **'Speech'**
  String get settingsSpeechTitle;

  /// Settings slider label for TTS playback speed.
  ///
  /// In en, this message translates to:
  /// **'Speaking rate'**
  String get settingsSpeechRate;

  /// Settings slider label for TTS pitch.
  ///
  /// In en, this message translates to:
  /// **'Voice pitch'**
  String get settingsSpeechPitch;

  /// Settings speech section status line.
  ///
  /// In en, this message translates to:
  /// **'Microphone access: allowed'**
  String get settingsMicPermissionGranted;

  /// Settings speech section status line.
  ///
  /// In en, this message translates to:
  /// **'Microphone access: not allowed'**
  String get settingsMicPermissionDenied;

  /// Settings speech section status line.
  ///
  /// In en, this message translates to:
  /// **'Microphone access: blocked — enable it in device settings'**
  String get settingsMicPermissionPermanentlyDenied;

  /// Settings speech section status line.
  ///
  /// In en, this message translates to:
  /// **'Microphone access: not yet requested'**
  String get settingsMicPermissionNotDetermined;

  /// Settings speech section status line.
  ///
  /// In en, this message translates to:
  /// **'On-device speech recognition: available for English'**
  String get settingsSttAvailable;

  /// Settings speech section status line.
  ///
  /// In en, this message translates to:
  /// **'On-device speech recognition: not available on this device — you can still type answers to speaking tasks'**
  String get settingsSttUnavailable;

  /// Accessible label/tooltip for the icon button that plays text aloud via on-device TTS.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get speechListen;

  /// Skill name shown in a per-skill evidence breakdown (placement/mission/assessment results).
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get skillListening;

  /// Skill name shown in a per-skill evidence breakdown.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get skillReading;

  /// Skill name shown in a per-skill evidence breakdown.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get skillWriting;

  /// Skill name shown in a per-skill evidence breakdown.
  ///
  /// In en, this message translates to:
  /// **'Spoken interaction'**
  String get skillSpokenInteraction;

  /// Skill name shown in a per-skill evidence breakdown.
  ///
  /// In en, this message translates to:
  /// **'Spoken production'**
  String get skillSpokenProduction;

  /// Skill name shown in a per-skill evidence breakdown.
  ///
  /// In en, this message translates to:
  /// **'Mediation'**
  String get skillMediation;

  /// Final Assessment section label — merges spoken interaction/production into one bucket, matching the bundle's own section key.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get skillSpeaking;

  /// Line under the Tests tab's title.
  ///
  /// In en, this message translates to:
  /// **'See where you are in A1 — and prove it at the end.'**
  String get testsHubSubtitle;

  /// Overline on the Tests tab's placement card for a brand-new learner.
  ///
  /// In en, this message translates to:
  /// **'Start here'**
  String get testsStartHereOverline;

  /// Title of the Tests tab's placement card for a brand-new learner.
  ///
  /// In en, this message translates to:
  /// **'Find your starting point'**
  String get testsPlacementHeroTitle;

  /// Body of the Tests tab's placement card for a brand-new learner.
  ///
  /// In en, this message translates to:
  /// **'Already know some English? A short placement test skips what you know.'**
  String get testsPlacementHeroBody;

  /// How long the placement test is: it's adaptive.
  ///
  /// In en, this message translates to:
  /// **'Stops as soon as it finds your level'**
  String get testsPlacementMeta;

  /// Button on the Tests tab's placement card.
  ///
  /// In en, this message translates to:
  /// **'Take the placement test'**
  String get testsPlacementCta;

  /// Tests tab section heading for the placement test.
  ///
  /// In en, this message translates to:
  /// **'Placement'**
  String get testsPlacementOverline;

  /// Tests tab row title for the placement test.
  ///
  /// In en, this message translates to:
  /// **'Placement test'**
  String get testsPlacementTitle;

  /// When a test was last finished.
  ///
  /// In en, this message translates to:
  /// **'Taken {date}'**
  String testsTakenOn(String date);

  /// Status of a test never finished.
  ///
  /// In en, this message translates to:
  /// **'Not taken'**
  String get testsNotTaken;

  /// Status of a test started but not finished.
  ///
  /// In en, this message translates to:
  /// **'Not finished'**
  String get testsNotFinished;

  /// The placement test's recommendation.
  ///
  /// In en, this message translates to:
  /// **'Result: start from Unit {unit}'**
  String testsPlacementResultUnit(int unit);

  /// The placement test found A1 mastered.
  ///
  /// In en, this message translates to:
  /// **'Result: A1 already mastered'**
  String get testsPlacementResultMastered;

  /// Tests tab section heading for the final mission and assessment.
  ///
  /// In en, this message translates to:
  /// **'Finish A1'**
  String get testsFinishOverline;

  /// Course progress above the final mission and assessment.
  ///
  /// In en, this message translates to:
  /// **'{mastered} of {total} units mastered — best taken when you\'ve finished the course.'**
  String testsFinishProgress(int mastered, int total);

  /// Course progress when every unit is mastered.
  ///
  /// In en, this message translates to:
  /// **'All {total} units mastered — you\'re ready.'**
  String testsFinishReady(int total);

  /// Tests tab description of the final mission.
  ///
  /// In en, this message translates to:
  /// **'Use everything from A1 in one real-life scenario, stage by stage.'**
  String get testsMissionBody;

  /// Size and time of the final mission.
  ///
  /// In en, this message translates to:
  /// **'{tasks} tasks · {stages} stages · {min}–{max} min'**
  String testsMissionMeta(int tasks, int stages, int min, int max);

  /// Tests tab description of the final assessment.
  ///
  /// In en, this message translates to:
  /// **'Every skill is scored on its own — a weak skill can\'t hide behind the others.'**
  String get testsAssessmentBody;

  /// Size and time of the final assessment.
  ///
  /// In en, this message translates to:
  /// **'{questions} questions · {skills} skills · {min}–{max} min'**
  String testsAssessmentMeta(int questions, int skills, int min, int max);

  /// Status of a passed final mission.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get testsPassed;

  /// Status of a finished but not passed final mission.
  ///
  /// In en, this message translates to:
  /// **'Not passed yet'**
  String get testsNotPassedYet;

  /// Status of a finished final assessment.
  ///
  /// In en, this message translates to:
  /// **'{passed} of {total} skills passed'**
  String testsSkillsPassed(int passed, int total);

  /// Note at the end of the Tests tab.
  ///
  /// In en, this message translates to:
  /// **'Each unit is checked as you go — its mission is on the Learn tab.'**
  String get testsUnitChecksNote;

  /// After Check in a test (placement, final assessment): the answer is saved, not marked.
  ///
  /// In en, this message translates to:
  /// **'Answer saved'**
  String get testAnswerSaved;

  /// Under "Answer saved" in a test.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see your results at the end.'**
  String get testAnswerSavedBody;

  /// Button after an answer is saved in a test.
  ///
  /// In en, this message translates to:
  /// **'Next question'**
  String get testNextQuestion;

  /// Test intro: how a no-marking test works.
  ///
  /// In en, this message translates to:
  /// **'Answers aren\'t marked as you go and transcripts are hidden. You\'ll see your results at the end.'**
  String get testRulesNote;

  /// Test intro: heading above the sections.
  ///
  /// In en, this message translates to:
  /// **'What it covers'**
  String get testIntroCoversHeading;

  /// Final mission intro: heading above its stages.
  ///
  /// In en, this message translates to:
  /// **'The stages'**
  String get testIntroStagesHeading;

  /// Test intro: how many questions a section has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 question} other{{count} questions}}'**
  String testIntroQuestionCount(int count);

  /// Final mission intro: how many tasks a stage has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task} other{{count} tasks}}'**
  String testIntroTaskCount(int count);

  /// Above a test question: its section and position in it.
  ///
  /// In en, this message translates to:
  /// **'{section} · {n} of {total}'**
  String testQuestionEyebrow(String section, int n, int total);

  /// Overline on the final mission's intro.
  ///
  /// In en, this message translates to:
  /// **'Final mission'**
  String get testsMissionOverline;

  /// Overline on the final assessment's intro.
  ///
  /// In en, this message translates to:
  /// **'Final assessment'**
  String get testsAssessmentOverline;

  /// Placement intro: what the test asks.
  ///
  /// In en, this message translates to:
  /// **'Listening and reading questions from each unit, easiest first'**
  String get placementCoversReceptive;

  /// Placement intro: the productive task.
  ///
  /// In en, this message translates to:
  /// **'One writing or speaking task at the end'**
  String get placementCoversProductive;

  /// Placement intro: why its length varies.
  ///
  /// In en, this message translates to:
  /// **'Stops at the first unit that\'s new to you'**
  String get placementCoversStops;

  /// Placement test intro screen app bar title.
  ///
  /// In en, this message translates to:
  /// **'A1 Gateway Placement Test'**
  String get placementIntroTitle;

  /// Placement test intro screen body text.
  ///
  /// In en, this message translates to:
  /// **'A few questions from each A1 unit, easiest first. It stops at the first unit that\'s new to you — so the more you already know, the longer it runs.'**
  String get placementIntroBody;

  /// Placement test intro screen start button.
  ///
  /// In en, this message translates to:
  /// **'Start the placement test'**
  String get placementStartButton;

  /// Placement test confidence self-report screen question — supporting info only, never affects the result.
  ///
  /// In en, this message translates to:
  /// **'Overall, how confident did that feel?'**
  String get placementConfidenceQuestion;

  /// Label at the low end of the 1-5 confidence scale.
  ///
  /// In en, this message translates to:
  /// **'Not very'**
  String get placementConfidenceLow;

  /// Label at the high end of the 1-5 confidence scale.
  ///
  /// In en, this message translates to:
  /// **'Very confident'**
  String get placementConfidenceHigh;

  /// Placement test result screen app bar title.
  ///
  /// In en, this message translates to:
  /// **'Your result'**
  String get placementResultTitle;

  /// Placement outcome 1 of 4: recommend starting at A1-U0.
  ///
  /// In en, this message translates to:
  /// **'Start with English Essentials (Unit 0) — it\'ll give you the footing the rest of A1 builds on.'**
  String get placementOutcomeStartWithEssentials;

  /// Placement outcome 2 of 4: recommend starting at A1-U1.
  ///
  /// In en, this message translates to:
  /// **'You know the essentials — start A1 from Unit 1.'**
  String get placementOutcomeStartA1FromU1;

  /// Placement outcome 3 of 4: recommend starting at a specific later unit.
  ///
  /// In en, this message translates to:
  /// **'You\'re ahead in the early units — start from {unitTitle}.'**
  String placementOutcomeStartFromUnit(String unitTitle);

  /// Placement outcome 4 of 4: no A2+ claim is ever made, only that A1 shows no gaps.
  ///
  /// In en, this message translates to:
  /// **'A1 appears mastered — great work! Higher-level placement isn\'t available yet, but it\'s coming.'**
  String get placementOutcomeMastered;

  /// Placement result screen CTA linking to the recommended starting unit.
  ///
  /// In en, this message translates to:
  /// **'Go to this unit'**
  String get placementResultGoToUnit;

  /// Placement result screen dismiss button.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get placementResultDone;

  /// Final Mission intro screen start button.
  ///
  /// In en, this message translates to:
  /// **'Begin the mission'**
  String get finalMissionStartButton;

  /// Final Mission result screen app bar title.
  ///
  /// In en, this message translates to:
  /// **'Mission result'**
  String get finalMissionResultTitle;

  /// Final Mission result: every required skill group passed independently.
  ///
  /// In en, this message translates to:
  /// **'Mission complete — every required skill area came through.'**
  String get finalMissionPassed;

  /// Final Mission result: at least one required skill group didn't clear the bar yet.
  ///
  /// In en, this message translates to:
  /// **'Not quite there yet'**
  String get finalMissionNotYetTitle;

  /// Final Mission result screen dismiss button.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get finalMissionDone;

  /// Final Assessment intro screen body text.
  ///
  /// In en, this message translates to:
  /// **'The exit test for A1. Each skill is scored on its own — a strong score in one never covers for a weak one in another.'**
  String get finalAssessmentIntroBody;

  /// Final Assessment intro screen start button.
  ///
  /// In en, this message translates to:
  /// **'Start the assessment'**
  String get finalAssessmentStartButton;

  /// Final Assessment result screen app bar title.
  ///
  /// In en, this message translates to:
  /// **'Assessment result'**
  String get finalAssessmentResultTitle;

  /// Final Assessment overall summary when every required section passed.
  ///
  /// In en, this message translates to:
  /// **'Every required skill met the bar for A1.'**
  String get finalAssessmentOverallPassed;

  /// Final Assessment overall summary when at least one required section didn't pass.
  ///
  /// In en, this message translates to:
  /// **'Not every required skill met the bar yet — see the breakdown below.'**
  String get finalAssessmentOverallNotYet;

  /// Final Assessment per-section status label.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get finalAssessmentSkillPassed;

  /// Final Assessment per-section status label.
  ///
  /// In en, this message translates to:
  /// **'Not yet met'**
  String get finalAssessmentSkillNotMet;

  /// Final Assessment per-section status label — shown when a section has a free-response item this app can't auto-grade yet.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get finalAssessmentSkillPendingReview;

  /// Final Assessment result screen dismiss button.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get finalAssessmentDone;

  /// Final Assessment result screen — a section's average score as a percentage.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String finalAssessmentSectionScore(int percent);

  /// Final Assessment result screen CTA shown when the overall result isn't yet a pass, linking back to the Learn tab.
  ///
  /// In en, this message translates to:
  /// **'Keep practicing'**
  String get finalAssessmentWhatsNext;

  /// Shown when a deep link or stored reference (e.g. a favourited word) points at a word/chunk/grammar/unit id that no longer resolves against the current content bundle.
  ///
  /// In en, this message translates to:
  /// **'Content not found'**
  String get contentNotFoundTitle;

  /// Grammar section title — used as the Grammar list screen's app bar title and as the Review screen's link tooltip to it.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get grammarSectionTitle;

  /// Screen-reader label/tooltip for the star toggle button when the item is not currently a favorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get favoriteAddTooltip;

  /// Screen-reader label/tooltip for the star toggle button when the item is currently a favorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get favoriteRemoveTooltip;

  /// Settings section title for the Arabic/English interface-language picker.
  ///
  /// In en, this message translates to:
  /// **'Interface language'**
  String get settingsInterfaceLanguageTitle;

  /// Settings section title for the light/dark/system theme-mode picker.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeModeTitle;

  /// Theme-mode option label.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeModeLight;

  /// Theme-mode option label.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeModeDark;

  /// Theme-mode option label — follows the device's own light/dark setting.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeModeSystem;

  /// Settings section title for the colour-seed picker (see AppColorSeed).
  ///
  /// In en, this message translates to:
  /// **'Colour theme'**
  String get settingsColorThemeTitle;

  /// Section title on Settings for the learner's name field.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get settingsNameTitle;

  /// Helper text under the Settings name field explaining why it's asked.
  ///
  /// In en, this message translates to:
  /// **'Used by a few spelling exercises'**
  String get settingsNameHint;

  /// Button to save the learner's name in Settings.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsNameSaveButton;

  /// Snackbar confirmation after saving the learner's name in Settings.
  ///
  /// In en, this message translates to:
  /// **'Name saved'**
  String get settingsNameSaved;

  /// Settings section title for app/privacy information.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutTitle;

  /// Settings About section body — a plain-language privacy summary, not a full legal privacy policy (v1 has none published yet).
  ///
  /// In en, this message translates to:
  /// **'Mohingo works fully offline — your lessons, progress, and any speaking answers stay on this device. Nothing is uploaded anywhere, and there\'s no account to create.'**
  String get settingsAboutBody;

  /// Settings section title for the destructive reset-progress action.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get settingsResetProgressTitle;

  /// Button that opens the reset-progress confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get settingsResetProgressButton;

  /// Confirmation dialog title before erasing progress.
  ///
  /// In en, this message translates to:
  /// **'Reset all progress?'**
  String get settingsResetProgressConfirmTitle;

  /// Confirmation dialog body — states plainly what will be lost before the action is taken, per docs/UX_PRINCIPLES.md.
  ///
  /// In en, this message translates to:
  /// **'This erases every unit\'s progress, mastery evidence, placement/mission/assessment results, and vocabulary/grammar favourites on this device. This can\'t be undone.'**
  String get settingsResetProgressConfirmBody;

  /// Confirmation dialog's destructive confirm button.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settingsResetProgressConfirmAction;

  /// Confirmation dialog's cancel button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsResetProgressCancel;

  /// Snackbar shown after progress is successfully reset.
  ///
  /// In en, this message translates to:
  /// **'Progress reset.'**
  String get settingsResetProgressDone;

  /// Settings section title for the not-yet-built backup/sync feature.
  ///
  /// In en, this message translates to:
  /// **'Backup & sync'**
  String get settingsBackupTitle;

  /// Settings Backup & sync section body — an honest coming-soon placeholder, not a working feature.
  ///
  /// In en, this message translates to:
  /// **'Coming soon. For now, your progress stays on this device only — reinstalling the app or switching devices starts fresh.'**
  String get settingsBackupBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
