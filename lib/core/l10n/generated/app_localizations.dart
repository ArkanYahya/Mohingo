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

  /// Shown on Home when there is no next unit to recommend, naming the level the learner is in.
  ///
  /// In en, this message translates to:
  /// **'You\'ve mastered every {level} unit so far!'**
  String homeAllUnitsMastered(String level);

  /// Overline on Home's next-level card, shown once the learner has mastered their level's units and the level after it is released.
  ///
  /// In en, this message translates to:
  /// **'Next level'**
  String get homeNextLevelOverline;

  /// Title and action of Home's next-level card. Tapping the card moves the learner into that level; the app never moves them on its own.
  ///
  /// In en, this message translates to:
  /// **'Start {level}'**
  String homeNextLevelTitle(String level);

  /// Body of Home's next-level card: why it's being offered, and that the choice is the learner's.
  ///
  /// In en, this message translates to:
  /// **'Every {current} unit is mastered, and {next} builds straight on it — move when you\'re ready.'**
  String homeNextLevelBody(String current, String next);

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

  /// Home header chip: the learner's current CEFR level and its plain-language descriptor. The descriptor comes from cefrDescriptorLabel; the chip shows the bare code for a level with no descriptor yet.
  ///
  /// In en, this message translates to:
  /// **'{cefr} · {descriptor}'**
  String homeLevelBadge(String cefr, String descriptor);

  /// Plain-language descriptor for CEFR level A1, shown beside the code.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get cefrDescriptorA1;

  /// Plain-language descriptor for CEFR level A2, shown beside the code. Deliberately not "Beginner" — that is A1, and telling an A2 learner they are a beginner undoes what finishing A1 meant.
  ///
  /// In en, this message translates to:
  /// **'Elementary'**
  String get cefrDescriptorA2;

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

  /// Lesson type label: lessonType integrated-production — a model text, questions on it, then the learner writes their own.
  ///
  /// In en, this message translates to:
  /// **'Put it together'**
  String get homeLessonTypeIntegrated;

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

  /// Badge on a key phrase or grammar form that the lesson reviews from an earlier level, e.g. 'From A1'.
  ///
  /// In en, this message translates to:
  /// **'From {level}'**
  String lessonIntroFromLevel(String level);

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

  /// Status line on a unit whose content changed after the learner worked through it — an activity they answered is no longer in the unit, or the unit now asks for different Can-Do objectives. Their progress is kept: this informs, it never blocks. Written so it reads as the course improving rather than as something the learner did wrong.
  ///
  /// In en, this message translates to:
  /// **'Updated since you last studied it'**
  String get learnUnitContentUpdated;

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

  /// Overline on the card at the end of the unit path, naming the level the path belongs to.
  ///
  /// In en, this message translates to:
  /// **'Finish {level}'**
  String learnFinishOverline(String level);

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

  /// Screen-reader label of the level strip's pill for the level the learner is currently in.
  ///
  /// In en, this message translates to:
  /// **'Level {level}, the one you\'re learning now'**
  String learnLevelSemanticsCurrent(String level);

  /// Screen-reader label of the level strip's pill for a level that is open but isn't the one on screen.
  ///
  /// In en, this message translates to:
  /// **'Level {level}, open — switch to it'**
  String learnLevelSemanticsOpen(String level);

  /// Screen-reader label of the level strip's pill for a level that is released but locked for this learner.
  ///
  /// In en, this message translates to:
  /// **'Level {level}, locked'**
  String learnLevelSemanticsLocked(String level);

  /// Line under the level strip, naming the level the learner is shown as being in.
  ///
  /// In en, this message translates to:
  /// **'More levels are on the way. Everything you learn in {level} carries over.'**
  String learnLevelComingLaterBody(String level);

  /// Title of the lock sheet shown for a level the learner hasn't reached yet.
  ///
  /// In en, this message translates to:
  /// **'{level} builds on {previous}'**
  String levelLockTitle(String level, String previous);

  /// Body of the lock sheet shown for a level the learner hasn't reached yet.
  ///
  /// In en, this message translates to:
  /// **'Finishing {previous} opens it. You can check where you stand with the placement test — or open {level} anyway.'**
  String levelLockBody(String previous, String level);

  /// Button on the lock sheet that opens the placement test.
  ///
  /// In en, this message translates to:
  /// **'Take the placement test'**
  String get levelLockTakeTest;

  /// Button on the lock sheet that opens the level without the placement test.
  ///
  /// In en, this message translates to:
  /// **'Open {level} anyway'**
  String levelLockOpenAnyway(String level);

  /// Title of the lock sheet shown for a level the app hasn't released yet.
  ///
  /// In en, this message translates to:
  /// **'{level} isn\'t ready yet'**
  String levelNotReleasedTitle(String level);

  /// Body of the lock sheet shown for a level the app hasn't released yet.
  ///
  /// In en, this message translates to:
  /// **'Its lessons open when it\'s ready. Until then you can look at what it covers.'**
  String get levelNotReleasedBody;

  /// Button on the lock sheet that lets the learner look at a level's content without opening its lessons.
  ///
  /// In en, this message translates to:
  /// **'See what {level} covers'**
  String levelNotReleasedBrowse(String level);

  /// Title of the banner shown above a level's unit list while the learner is only browsing it, not enrolled in it.
  ///
  /// In en, this message translates to:
  /// **'A look at {level}'**
  String learnPreviewBannerTitle(String level);

  /// Body of the browsing banner, explaining the units are read-only until the level ships.
  ///
  /// In en, this message translates to:
  /// **'These are the units {level} will cover. Its lessons open when it\'s ready.'**
  String learnPreviewBannerBody(String level);

  /// Button in the browsing banner that returns the learner to the level they are actually enrolled in.
  ///
  /// In en, this message translates to:
  /// **'Back to {level}'**
  String learnPreviewBackToCurrent(String level);

  /// Label before the level chips at the top of the words & phrases and grammar lists, saying which level's items the list is showing.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get levelFilterLabel;

  /// Screen-reader label of one level chip on the words & phrases and grammar lists — the chip itself shows only the bare CEFR code.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelFilterSemantics(String level);

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

  /// Lesson player app bar progress indicator, e.g. "3 of 6".
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String lessonPlayerProgress(int current, int total);

  /// Overline on a finished lesson's answer review.
  ///
  /// In en, this message translates to:
  /// **'Unit {unit} · Lesson {lesson} · Your answers'**
  String lessonReviewOverline(int unit, int lesson);

  /// Answer review summary.
  ///
  /// In en, this message translates to:
  /// **'{right} of {total} right'**
  String lessonReviewScore(int right, int total);

  /// A question's number, e.g. in its summary mark's screen-reader label.
  ///
  /// In en, this message translates to:
  /// **'Question {n}'**
  String lessonReviewQuestion(int n);

  /// Above each reviewed question: its number and skill.
  ///
  /// In en, this message translates to:
  /// **'{n} · {skill}'**
  String lessonReviewQuestionHeader(int n, String skill);

  /// A reviewed answer that was right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get lessonReviewRight;

  /// A reviewed answer that was wrong.
  ///
  /// In en, this message translates to:
  /// **'Not quite'**
  String get lessonReviewNotQuite;

  /// A reviewed answer that was saved without a verdict.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get lessonReviewSaved;

  /// A question the learner never answered.
  ///
  /// In en, this message translates to:
  /// **'Not answered'**
  String get lessonReviewNotAnsweredPill;

  /// Answer review filter: every question.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get lessonReviewFilterAll;

  /// Answer review filter: only the wrong answers.
  ///
  /// In en, this message translates to:
  /// **'To revisit'**
  String get lessonReviewFilterToRevisit;

  /// Answer review when To revisit is empty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to revisit — every answer was right.'**
  String get lessonReviewNothingToRevisit;

  /// Button on the lesson review screen (a finished lesson's read-only answer walkthrough) that starts a fresh replay of the lesson.
  ///
  /// In en, this message translates to:
  /// **'Practise this lesson again'**
  String get lessonReviewPracticeAgain;

  /// Placeholder shown on the lesson review screen for an activity with no recorded attempt at all (e.g. content changed after the lesson was finished).
  ///
  /// In en, this message translates to:
  /// **'You didn\'t answer this one.'**
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

  /// Above a quick-practice question: what is practised and which question.
  ///
  /// In en, this message translates to:
  /// **'Practice · {title} · {n} of {total}'**
  String practiceEyebrow(String title, int n, int total);

  /// Overline on the quick-practice summary.
  ///
  /// In en, this message translates to:
  /// **'Practice · {title}'**
  String practiceOverline(String title);

  /// Quick-practice summary: why the weak spot may remain.
  ///
  /// In en, this message translates to:
  /// **'Practice here doesn\'t count towards mastery — the lesson and its unit mission do.'**
  String get practiceNoMastery;

  /// Restarts a quick-practice set.
  ///
  /// In en, this message translates to:
  /// **'Practise again'**
  String get practiceAgain;

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

  /// Under a weak spot's lesson title: its level, its unit within that level, and the skills it practises. Review shows weak spots from every level at once, so the unit number alone would be ambiguous.
  ///
  /// In en, this message translates to:
  /// **'Level {level} · Unit {unit} · {skills}'**
  String reviewWeakSpotMeta(String level, int unit, String skills);

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

  /// Under the Words & phrases tile: how many are in spaced review, out of every word and phrase in every level the learner has reached.
  ///
  /// In en, this message translates to:
  /// **'{inReview} of {total} in review'**
  String reviewWordsTileMeta(int inReview, int total);

  /// Under the Grammar tile: how many grammar forms there are across every level the learner has reached.
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
  /// **'Listening & speaking'**
  String get settingsSpeechTitle;

  /// Settings slider label for TTS playback speed.
  ///
  /// In en, this message translates to:
  /// **'Voice speed'**
  String get settingsSpeechRate;

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

  /// Line under the Tests tab's title, naming the level the learner is in.
  ///
  /// In en, this message translates to:
  /// **'See where you are in {level} — and prove it at the end.'**
  String testsHubSubtitle(String level);

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

  /// The placement test's recommendation on the Tests tab. It covers every released level, so the unit number alone would be ambiguous.
  ///
  /// In en, this message translates to:
  /// **'Result: start at {level} Unit {unit}'**
  String testsPlacementResultUnit(String level, int unit);

  /// The placement test found nothing left to teach in the top released level. Always the level the attempt actually measured — never one that shipped afterwards.
  ///
  /// In en, this message translates to:
  /// **'Result: {level} already mastered'**
  String testsPlacementResultMastered(String level);

  /// Tests tab section heading for the final mission and assessment, naming the level they close.
  ///
  /// In en, this message translates to:
  /// **'Finish {level}'**
  String testsFinishOverline(String level);

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

  /// Tests tab and Final Mission intro description of the final mission.
  ///
  /// In en, this message translates to:
  /// **'Use everything from {level} in one real-life scenario, stage by stage.'**
  String testsMissionBody(String level);

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

  /// Overline on the placement test's intro, naming the highest level it can place a learner in.
  ///
  /// In en, this message translates to:
  /// **'Placement test up to {level}'**
  String placementIntroTitle(String level);

  /// Placement test intro screen body text, naming the highest released level it covers.
  ///
  /// In en, this message translates to:
  /// **'A few questions from each unit, easiest first, all the way up to {level}. It stops at the first unit that\'s new to you — so the more you already know, the longer it runs.'**
  String placementIntroBody(String level);

  /// Which unit a placement question came from, and the level that unit belongs to — the test moves through every released level, so the unit number alone would be ambiguous.
  ///
  /// In en, this message translates to:
  /// **'{level} · Unit {unit}'**
  String placementUnitSection(String level, int unit);

  /// Placement test intro screen start button.
  ///
  /// In en, this message translates to:
  /// **'Start the placement test'**
  String get placementStartButton;

  /// Result screen: heading above the per-skill results.
  ///
  /// In en, this message translates to:
  /// **'How you did'**
  String get testsResultHowYouDid;

  /// A skill's score on the placement result.
  ///
  /// In en, this message translates to:
  /// **'{right} of {total}'**
  String testsSkillScore(int right, int total);

  /// A skill whose answers are saved but not scored yet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for review'**
  String get testsWaitingReview;

  /// Under a skill that's waiting for review.
  ///
  /// In en, this message translates to:
  /// **'Your answers are saved; this skill is scored once they\'re checked.'**
  String get testsPendingBody;

  /// A skill's score and the pass mark.
  ///
  /// In en, this message translates to:
  /// **'{score}% · pass mark {mark}%'**
  String testsScorePassMark(int score, int mark);

  /// Overline on the placement result.
  ///
  /// In en, this message translates to:
  /// **'Placement result'**
  String get placementResultOverline;

  /// The placement result's headline, naming the level as well as the unit.
  ///
  /// In en, this message translates to:
  /// **'{level} Unit {unit} is where to begin'**
  String placementResultHeadline(String level, int unit);

  /// Placement result when starting from the first unit.
  ///
  /// In en, this message translates to:
  /// **'Unit 1 gives you the basics every other unit builds on.'**
  String get placementResultBodyEssentials;

  /// Placement result when the learner passed everything before this level and starts it at its first unit.
  ///
  /// In en, this message translates to:
  /// **'You\'re ready for {level} — start it from the very beginning.'**
  String placementResultBodyLevelStart(String level);

  /// Placement result when starting further in.
  ///
  /// In en, this message translates to:
  /// **'You know the units before it well. Unit {unit} is where new things begin for you.'**
  String placementResultBodyUnit(int unit);

  /// Placement result when every unit of every released level passed. Names the top released level and never one above it — there is no content above it to have been measured.
  ///
  /// In en, this message translates to:
  /// **'{level} looks mastered'**
  String placementResultMasteredTitle(String level);

  /// Placement result body when every unit passed.
  ///
  /// In en, this message translates to:
  /// **'Take the final assessment to prove it. Higher levels are on the way.'**
  String get placementResultMasteredBody;

  /// Placement result note when starting further in.
  ///
  /// In en, this message translates to:
  /// **'Earlier units stay open — go back to any lesson whenever you like.'**
  String get placementResultEarlierOpen;

  /// Placement result button: it moves the learner into that level and opens the unit.
  ///
  /// In en, this message translates to:
  /// **'Start at {level} Unit {unit}'**
  String placementResultStartAtUnit(String level, int unit);

  /// Confidence self-report option 1 of 5.
  ///
  /// In en, this message translates to:
  /// **'Not at all confident'**
  String get placementConfidence1;

  /// Confidence self-report option 2 of 5.
  ///
  /// In en, this message translates to:
  /// **'A little confident'**
  String get placementConfidence2;

  /// Confidence self-report option 3 of 5.
  ///
  /// In en, this message translates to:
  /// **'Fairly confident'**
  String get placementConfidence3;

  /// Confidence self-report option 4 of 5.
  ///
  /// In en, this message translates to:
  /// **'Quite confident'**
  String get placementConfidence4;

  /// Confidence self-report option 5 of 5.
  ///
  /// In en, this message translates to:
  /// **'Very confident'**
  String get placementConfidence5;

  /// Under the confidence question.
  ///
  /// In en, this message translates to:
  /// **'Your answer doesn\'t change your result.'**
  String get placementConfidenceNote;

  /// Final mission result when passed.
  ///
  /// In en, this message translates to:
  /// **'Mission complete'**
  String get missionResultPassedTitle;

  /// Final mission result body when passed.
  ///
  /// In en, this message translates to:
  /// **'Every required skill came through across the day.'**
  String get missionResultPassedBody;

  /// Final mission result when not passed.
  ///
  /// In en, this message translates to:
  /// **'Not passed yet'**
  String get missionResultNotYetTitle;

  /// Final mission result body when not passed.
  ///
  /// In en, this message translates to:
  /// **'Some skills need more practice — see below. You can take the mission again any time.'**
  String get missionResultNotYetBody;

  /// Final assessment result when passed.
  ///
  /// In en, this message translates to:
  /// **'You passed {level}'**
  String assessmentResultPassedTitle(String level);

  /// Final assessment result when not passed.
  ///
  /// In en, this message translates to:
  /// **'Not passed yet'**
  String get assessmentResultNotYetTitle;

  /// Final assessment result summary.
  ///
  /// In en, this message translates to:
  /// **'{passed} of {total} skills passed.'**
  String assessmentResultBody(int passed, int total);

  /// Placement test confidence self-report screen question — supporting info only, never affects the result.
  ///
  /// In en, this message translates to:
  /// **'Overall, how confident did that feel?'**
  String get placementConfidenceQuestion;

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

  /// Final Mission result screen dismiss button.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get finalMissionDone;

  /// Final Assessment intro screen body text.
  ///
  /// In en, this message translates to:
  /// **'The exit test for {level}. Each skill is scored on its own — a strong score in one never covers for a weak one in another.'**
  String finalAssessmentIntroBody(String level);

  /// Final Assessment intro screen start button.
  ///
  /// In en, this message translates to:
  /// **'Start the assessment'**
  String get finalAssessmentStartButton;

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

  /// Final Assessment result screen dismiss button.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get finalAssessmentDone;

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

  /// Settings section heading: language, theme, colour.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceOverline;

  /// Under the app-language setting.
  ///
  /// In en, this message translates to:
  /// **'Lessons stay in English; this changes menus and help.'**
  String get settingsLanguageBody;

  /// Voice speed slider: the slow end.
  ///
  /// In en, this message translates to:
  /// **'Slower'**
  String get settingsSlower;

  /// Voice speed slider: the fast end.
  ///
  /// In en, this message translates to:
  /// **'Faster'**
  String get settingsFaster;

  /// Plays a short sample in the chosen voice settings.
  ///
  /// In en, this message translates to:
  /// **'Try it'**
  String get settingsTryVoice;

  /// Settings row title for microphone access.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get settingsMicTitle;

  /// Microphone access granted.
  ///
  /// In en, this message translates to:
  /// **'Allowed — you can answer speaking tasks aloud.'**
  String get settingsMicAllowed;

  /// Microphone access never requested.
  ///
  /// In en, this message translates to:
  /// **'Not allowed yet — needed to answer speaking tasks aloud.'**
  String get settingsMicNotYet;

  /// Microphone access denied (can ask again).
  ///
  /// In en, this message translates to:
  /// **'Not allowed — needed to answer speaking tasks aloud.'**
  String get settingsMicDenied;

  /// Microphone access permanently denied.
  ///
  /// In en, this message translates to:
  /// **'Blocked — turn it on in your phone\'s settings for Mohingo.'**
  String get settingsMicBlocked;

  /// Button that asks for microphone access.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get settingsMicAllow;

  /// Settings row title for on-device speech recognition.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition'**
  String get settingsSttTitle;

  /// Speech recognition available.
  ///
  /// In en, this message translates to:
  /// **'Available for English on this device.'**
  String get settingsSttOn;

  /// Speech recognition unavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device. You can type your speaking answers instead.'**
  String get settingsSttOff;

  /// Settings section heading: privacy, backup, reset.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get settingsDataOverline;

  /// Settings row title: privacy.
  ///
  /// In en, this message translates to:
  /// **'Works offline'**
  String get settingsOfflineTitle;

  /// Settings row body: privacy.
  ///
  /// In en, this message translates to:
  /// **'Every lesson works without internet. Without an account, your progress stays on this phone.'**
  String get settingsOfflineBody;

  /// Under the Reset progress row.
  ///
  /// In en, this message translates to:
  /// **'Erase every lesson, test result and review on this device.'**
  String get settingsResetProgressBody;

  /// Profile card when the learner has no name yet.
  ///
  /// In en, this message translates to:
  /// **'Add your name'**
  String get settingsNameEmpty;

  /// Settings profile card subtitle: the level the learner is in.
  ///
  /// In en, this message translates to:
  /// **'Learning English · {level}'**
  String settingsProfileMeta(String level);

  /// Profile card button that edits the name.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get settingsEdit;

  /// Settings section title for the Arabic/English interface-language picker.
  ///
  /// In en, this message translates to:
  /// **'App language'**
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
  /// **'Automatic'**
  String get settingsThemeModeSystem;

  /// Section title on Settings for the learner's name field.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get settingsNameTitle;

  /// Helper text under the Settings name field explaining why it's asked.
  ///
  /// In en, this message translates to:
  /// **'Used on Home and in a few spelling exercises.'**
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

  /// Settings section title for the destructive reset-progress action.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get settingsResetProgressTitle;

  /// Confirmation dialog title before erasing progress.
  ///
  /// In en, this message translates to:
  /// **'Reset all progress?'**
  String get settingsResetProgressConfirmTitle;

  /// Confirmation dialog body — states plainly what will be lost before the action is taken, per docs/UX_PRINCIPLES.md.
  ///
  /// In en, this message translates to:
  /// **'This erases every lesson and unit, test result, review schedule and saved word on this device. It can\'t be undone.'**
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
  /// **'Reinstalling the app or changing phones starts fresh for now.'**
  String get settingsBackupBody;

  /// Heading of the card on a speaking question that shows what the other person says before the learner answers.
  ///
  /// In en, this message translates to:
  /// **'The other person says'**
  String get speakPartnerTitle;

  /// Accessibility label of the button that reads the other person's lines aloud again.
  ///
  /// In en, this message translates to:
  /// **'Hear it again'**
  String get speakPartnerPlay;

  /// Title of the card holding a lesson's model text (a message, a menu, a profile) in the lesson intro.
  ///
  /// In en, this message translates to:
  /// **'Read the text'**
  String get lessonIntroReadTitle;

  /// Settings section heading for sign-in and progress sync.
  ///
  /// In en, this message translates to:
  /// **'Account & sync'**
  String get accountSectionTitle;

  /// Settings row title shown to a guest (not signed in).
  ///
  /// In en, this message translates to:
  /// **'Save your progress to an account'**
  String get accountGuestTitle;

  /// Under the guest account row — why signing in is worth it. Signing in is optional.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep your progress safe and carry on from another phone.'**
  String get accountGuestBody;

  /// Small action on the guest account row; opens the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get accountSignInAction;

  /// Account row title when the account has no email to show.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get accountYourAccount;

  /// Account row subtitle while a sync is running.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get accountSyncing;

  /// Account row subtitle before the first successful sync.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get accountNotSyncedYet;

  /// Account row subtitle after a successful sync. {time} is a formatted date and time.
  ///
  /// In en, this message translates to:
  /// **'Last synced {time}'**
  String accountSyncedAt(String time);

  /// Account row subtitle when the last sync could not reach the internet.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Your progress is saved on this phone and will sync when you\'re back online.'**
  String get accountSyncOffline;

  /// Account row subtitle when the last sync failed for another reason; it retries on its own.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync just now. We\'ll try again shortly.'**
  String get accountSyncFailed;

  /// Account row subtitle when the account's sign-in is no longer valid.
  ///
  /// In en, this message translates to:
  /// **'Your sign-in has expired. Sign out and sign in again to keep syncing.'**
  String get accountSyncSignedOut;

  /// Account row note: local changes not uploaded yet.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change waiting to sync} other{{count} changes waiting to sync}}'**
  String accountPendingChanges(int count);

  /// Small action on the account row; starts a sync immediately.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get accountSyncNow;

  /// Settings row title for signing out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOutTitle;

  /// Under the Sign out row.
  ///
  /// In en, this message translates to:
  /// **'Your progress stays in your account.'**
  String get accountSignOutBody;

  /// Sign-out confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get accountSignOutConfirmTitle;

  /// Sign-out confirmation body when everything has synced.
  ///
  /// In en, this message translates to:
  /// **'This phone will show guest progress until you sign in again. Your account keeps its progress.'**
  String get accountSignOutConfirmBody;

  /// Sign-out confirmation body when local changes are still waiting to upload.
  ///
  /// In en, this message translates to:
  /// **'Some progress hasn\'t synced yet. It stays on this phone and syncs the next time you sign in here.'**
  String get accountSignOutPendingBody;

  /// Cancel button in account dialogs.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get accountCancel;

  /// Snackbar after signing out.
  ///
  /// In en, this message translates to:
  /// **'Signed out.'**
  String get accountSignedOut;

  /// Snackbar after signing in.
  ///
  /// In en, this message translates to:
  /// **'Signed in. Your progress will sync.'**
  String get accountSignedIn;

  /// Account row title while the learner hasn't decided whether guest progress joins the account.
  ///
  /// In en, this message translates to:
  /// **'Choose what to do with this phone\'s progress'**
  String get accountDecisionPendingTitle;

  /// Under the pending-decision account row.
  ///
  /// In en, this message translates to:
  /// **'Your account won\'t sync until you choose.'**
  String get accountDecisionPendingBody;

  /// Small action on the pending-decision row; opens the choice dialog.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get accountDecisionAction;

  /// Dialog title after first sign-in on a phone that already has guest progress.
  ///
  /// In en, this message translates to:
  /// **'Add this phone\'s progress to your account?'**
  String get guestProgressTitle;

  /// Dialog body explaining the two choices. Neither choice deletes anything.
  ///
  /// In en, this message translates to:
  /// **'This phone has progress from before you signed in. You can add it to your account, where it joins anything your account already has, or keep it on this phone only.'**
  String get guestProgressBody;

  /// Dialog action: the guest progress becomes the account's.
  ///
  /// In en, this message translates to:
  /// **'Add to my account'**
  String get guestProgressAttach;

  /// Dialog action: the account starts from its own progress; guest progress stays on the phone and returns on sign-out.
  ///
  /// In en, this message translates to:
  /// **'Keep it on this phone'**
  String get guestProgressKeepSeparate;

  /// Sign-in screen title.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInTitle;

  /// Create-account screen title.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get authCreateTitle;

  /// Intro under the sign-in/create-account title.
  ///
  /// In en, this message translates to:
  /// **'Your account keeps your lessons, reviews and test results, so you can carry on from any phone. You can keep learning without one.'**
  String get authIntro;

  /// Email field label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// Password field label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// Second password field on the create-account screen.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordLabel;

  /// Helper under the password field on the create-account screen.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get authPasswordHint;

  /// Accessibility label of the eye button that reveals the password.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// Accessibility label of the eye button that hides the password.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// Primary button on the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInAction;

  /// Primary button on the create-account screen.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAction;

  /// Link to the password-reset screen.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPasswordLink;

  /// Divider text between email sign-in and the Apple and Google sign-in buttons.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// Google sign-in button. 'Google' is a brand name — keep it in Latin script.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authGoogleAction;

  /// Sign in with Apple button, iPhone only. Apple's own approved title; 'Apple' is a brand name — keep it in Latin script.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authAppleAction;

  /// Link from sign-in to create-account.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get authSwitchToCreate;

  /// Link from create-account to sign-in.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authSwitchToSignIn;

  /// Validation error under the email field.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authEmailInvalid;

  /// Validation error when the password field is empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get authPasswordRequired;

  /// Validation error when a new password is too short.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters.'**
  String get authPasswordTooShort;

  /// Validation error when the confirmation differs.
  ///
  /// In en, this message translates to:
  /// **'The passwords don\'t match.'**
  String get authPasswordsDontMatch;

  /// Sign-in error: malformed email.
  ///
  /// In en, this message translates to:
  /// **'That email address doesn\'t look right.'**
  String get authErrorInvalidEmail;

  /// Sign-in error: wrong email or password. Deliberately doesn't say which.
  ///
  /// In en, this message translates to:
  /// **'The email or password is incorrect.'**
  String get authErrorWrongCredentials;

  /// Create-account error: the email is taken.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Try signing in instead.'**
  String get authErrorEmailInUse;

  /// Create-account error: password too weak.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password with at least 6 characters.'**
  String get authErrorWeakPassword;

  /// Sign-in error: account disabled by the developer.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get authErrorUserDisabled;

  /// Sign-in error: rate limited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a few minutes and try again.'**
  String get authErrorTooManyRequests;

  /// Sign-in error: offline. Reassures the learner the app still works.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Connect and try again. You can keep learning offline meanwhile.'**
  String get authErrorNetwork;

  /// Sign-in error: the account uses another provider.
  ///
  /// In en, this message translates to:
  /// **'This email is registered with another sign-in method. Try that method instead.'**
  String get authErrorDifferentMethod;

  /// Sign-in error: accounts not configured in this build.
  ///
  /// In en, this message translates to:
  /// **'Accounts aren\'t available right now.'**
  String get authErrorUnavailable;

  /// Sign-in error: anything else.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorUnknown;

  /// Password-reset screen title.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get authResetTitle;

  /// Password-reset screen intro.
  ///
  /// In en, this message translates to:
  /// **'Enter your account\'s email and we\'ll send you a link to choose a new password.'**
  String get authResetBody;

  /// Password-reset screen primary button.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get authResetAction;

  /// Shown after requesting a reset. Doesn't confirm whether the account exists.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for {email}, a reset link is on its way. Check your inbox.'**
  String authResetSent(String email);

  /// Button returning from the password-reset screen.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authBackToSignIn;

  /// Under the Reset progress row when signed in: the reset applies to every device on the account.
  ///
  /// In en, this message translates to:
  /// **'Erase every lesson, test result and review on all your devices.'**
  String get settingsResetProgressBodyAccount;

  /// Reset confirmation body when signed in, stating plainly that other devices are affected too.
  ///
  /// In en, this message translates to:
  /// **'This erases every lesson and unit, test result, review schedule and saved word, on this phone and on every other phone signed in to your account. It can\'t be undone.'**
  String get settingsResetProgressConfirmBodyAccount;

  /// Offline row title when signed in (progress is also copied to the account).
  ///
  /// In en, this message translates to:
  /// **'Works offline'**
  String get settingsOfflineTitleAccount;

  /// Offline row body when signed in.
  ///
  /// In en, this message translates to:
  /// **'Every lesson works without internet. Your progress is also copied to your account.'**
  String get settingsOfflineBodyAccount;

  /// Title of the generic error state shown when a screen cannot load. Never shows the raw error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGenericTitle;

  /// Body of the generic error state: reassures that progress is safe and says what to do.
  ///
  /// In en, this message translates to:
  /// **'This page couldn\'t be opened. Your progress is safe — go back and try again.'**
  String get errorGenericBody;

  /// Title of the privacy policy document and of the links to it.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legalPrivacyTitle;

  /// Title of the terms of use document and of the links to it.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get legalTermsTitle;

  /// Heading of the first-run agreement screen.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Mohingo'**
  String get welcomeTitle;

  /// What Mohingo is, under the first-run heading.
  ///
  /// In en, this message translates to:
  /// **'An English course for Arabic speakers. It works without internet and keeps your progress on your phone.'**
  String get welcomeSubtitle;

  /// Shown on the agreement screen only to a learner who accepted an earlier version of the documents.
  ///
  /// In en, this message translates to:
  /// **'We\'ve updated the Privacy Policy and Terms of Use. Please take a look, then accept to continue.'**
  String get welcomeUpdatedNotice;

  /// Overline above the four privacy points on the first-run agreement screen.
  ///
  /// In en, this message translates to:
  /// **'Your privacy, in brief'**
  String get welcomePrivacyHeading;

  /// Privacy point: local storage.
  ///
  /// In en, this message translates to:
  /// **'Your progress stays on your phone'**
  String get welcomeLocalTitle;

  /// Privacy point: local storage, and what the app does not do.
  ///
  /// In en, this message translates to:
  /// **'Lessons, answers and settings are saved on this device. No ads, no analytics, no tracking.'**
  String get welcomeLocalBody;

  /// Privacy point: accounts and sync.
  ///
  /// In en, this message translates to:
  /// **'An account is optional'**
  String get welcomeAccountTitle;

  /// Privacy point: what an account uploads, and to whom.
  ///
  /// In en, this message translates to:
  /// **'If you sign in, your progress and name are copied to your account (Google Firebase) so you can use them on other phones. Without an account, your progress is never uploaded.'**
  String get welcomeAccountBody;

  /// Privacy point: the online grammar check.
  ///
  /// In en, this message translates to:
  /// **'Checking some written answers'**
  String get welcomeWritingTitle;

  /// Privacy point: typed answers sent to LanguageTool.
  ///
  /// In en, this message translates to:
  /// **'When you\'re online, the text of some typed answers is sent to LanguageTool, a grammar-checking service, to help mark them. Nothing that identifies you is sent with it.'**
  String get welcomeWritingBody;

  /// Privacy point: speech recognition.
  ///
  /// In en, this message translates to:
  /// **'Speaking tasks'**
  String get welcomeSpeechTitle;

  /// Privacy point: the system speech recogniser, which may process audio online.
  ///
  /// In en, this message translates to:
  /// **'Your phone\'s speech recognition (from Google or Apple) turns your voice into text and may do so online. Mohingo keeps only the text, never the recording.'**
  String get welcomeSpeechBody;

  /// Small line above the accept button on the first-run agreement screen.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to the Terms of Use and confirm you\'ve read the Privacy Policy.'**
  String get welcomeConsentLine;

  /// The first-run agreement button. Must match the label quoted in assets/legal/terms_*.md.
  ///
  /// In en, this message translates to:
  /// **'Accept and continue'**
  String get welcomeAccept;

  /// App guide: which step of how many.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String guideStepCounter(int current, int total);

  /// App guide: closes the guide at once.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get guideSkip;

  /// App guide: the previous step.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get guideBack;

  /// App guide: the next step.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get guideNext;

  /// App guide: closes the guide on its last step.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get guideDone;

  /// App guide, first step title.
  ///
  /// In en, this message translates to:
  /// **'A quick tour'**
  String get guideIntroTitle;

  /// App guide, first step: what the guide is and where to find it again.
  ///
  /// In en, this message translates to:
  /// **'Here\'s where everything is in Mohingo. It takes under a minute, and you can open this guide again from Settings.'**
  String get guideIntroBody;

  /// App guide step pointing at the level and streak pills on Home.
  ///
  /// In en, this message translates to:
  /// **'Your level'**
  String get guideLevelTitle;

  /// App guide: explains the level pill and the streak pill.
  ///
  /// In en, this message translates to:
  /// **'This shows the level you\'re studying (A1 is where beginners start) and your streak: how many days in a row you\'ve studied.'**
  String get guideLevelBody;

  /// App guide step pointing at the continue-lesson card.
  ///
  /// In en, this message translates to:
  /// **'Your next lesson'**
  String get guideContinueTitle;

  /// App guide: how to start a lesson and what a lesson contains.
  ///
  /// In en, this message translates to:
  /// **'Tap here to start your next lesson or carry on where you stopped. Each lesson opens with a short conversation, then practice in listening, reading, speaking and writing.'**
  String get guideContinueBody;

  /// App guide step pointing at the journey card.
  ///
  /// In en, this message translates to:
  /// **'Your path through the level'**
  String get guideJourneyTitle;

  /// App guide: how a level is organised.
  ///
  /// In en, this message translates to:
  /// **'A level is made of units, and each unit of short lessons that end with a unit mission. Each segment of this track is a unit; tap it to see them all.'**
  String get guideJourneyBody;

  /// App guide step pointing at the Learn tab. Same word as the tab label.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get guideLearnTitle;

  /// App guide: the Learn tab, followed by a legend of the progress marks.
  ///
  /// In en, this message translates to:
  /// **'Every unit and lesson, in order. Open a finished lesson to review your answers. These marks show where you are:'**
  String get guideLearnBody;

  /// App guide legend: the green check means a finished lesson or a mastered unit.
  ///
  /// In en, this message translates to:
  /// **'Finished lesson, or mastered unit'**
  String get guideLegendDone;

  /// App guide step pointing at the Review tab.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get guideReviewTitle;

  /// App guide: the Review tab and spaced review.
  ///
  /// In en, this message translates to:
  /// **'The words and grammar from your lessons. Words come back for review just before you\'re likely to forget them, and the number on this tab shows how many are due.'**
  String get guideReviewBody;

  /// App guide step pointing at the Tests tab.
  ///
  /// In en, this message translates to:
  /// **'Tests'**
  String get guideTestsTitle;

  /// App guide: the Tests tab.
  ///
  /// In en, this message translates to:
  /// **'A placement test to find where to start, and at the end of each level a final mission and a final assessment.'**
  String get guideTestsBody;

  /// App guide step pointing at the Settings tab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get guideSettingsTitle;

  /// App guide: the Settings tab, in a build without accounts.
  ///
  /// In en, this message translates to:
  /// **'Change the app language, light or dark mode and the voice speed. This guide is here too, under App guide.'**
  String get guideSettingsBody;

  /// App guide: the Settings tab, in a build with accounts.
  ///
  /// In en, this message translates to:
  /// **'Change the app language, light or dark mode and the voice speed. You can also sign in here to keep your progress on more than one phone — that part is optional. This guide is here too, under App guide.'**
  String get guideSettingsBodyAccount;

  /// Settings section overline above App guide and About.
  ///
  /// In en, this message translates to:
  /// **'Help & information'**
  String get settingsHelpOverline;

  /// Settings row that starts the app guide again.
  ///
  /// In en, this message translates to:
  /// **'App guide'**
  String get settingsGuideTitle;

  /// Under the App guide row.
  ///
  /// In en, this message translates to:
  /// **'A short tour of where everything is.'**
  String get settingsGuideBody;

  /// Settings row, and the title of the About screen.
  ///
  /// In en, this message translates to:
  /// **'About Mohingo'**
  String get settingsAboutTitle;

  /// Under the About row.
  ///
  /// In en, this message translates to:
  /// **'Version, privacy policy and terms'**
  String get settingsAboutBody;

  /// About screen: the installed version, read from the app package.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// About screen: one-paragraph description of the app.
  ///
  /// In en, this message translates to:
  /// **'An English course for Arabic speakers, organised by CEFR level from A1. Every lesson works offline, in Arabic and English.'**
  String get aboutDescription;

  /// About screen: under the Privacy Policy row.
  ///
  /// In en, this message translates to:
  /// **'What the app stores and what can leave your phone'**
  String get aboutPrivacyBody;

  /// About screen: under the Terms of Use row.
  ///
  /// In en, this message translates to:
  /// **'The rules for using Mohingo'**
  String get aboutTermsBody;

  /// About screen: row opening the open-source licences page.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get aboutLicensesTitle;

  /// About screen: under the open-source licences row.
  ///
  /// In en, this message translates to:
  /// **'The software Mohingo is built with'**
  String get aboutLicensesBody;

  /// Settings row, and the final button, for deleting the account.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDeleteTitle;

  /// Under the Delete account row.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and its copy of your progress.'**
  String get accountDeleteBody;

  /// Title of the delete-account confirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get accountDeleteConfirmTitle;

  /// Body of the delete-account confirmation: exactly what goes and what stays.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your Mohingo account, the copy of your progress stored with it, and this account\'s progress on this phone. It can\'t be undone. Progress you made on this phone without signing in is kept.'**
  String get accountDeleteConfirmBody;

  /// Delete-account confirmation: go on to confirm identity.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get accountDeleteContinue;

  /// Title of the step that asks for a fresh sign-in before deleting the account.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you'**
  String get accountDeletePasswordTitle;

  /// Asks for the password before deleting an email account.
  ///
  /// In en, this message translates to:
  /// **'To delete the account, enter the password for {email}.'**
  String accountDeletePasswordBody(String email);

  /// As accountDeletePasswordBody, when the account has no email to show.
  ///
  /// In en, this message translates to:
  /// **'To delete the account, enter its password.'**
  String get accountDeletePasswordBodyNoEmail;

  /// Asks a Google account to sign in again before deleting it.
  ///
  /// In en, this message translates to:
  /// **'To delete the account, choose your Google account again.'**
  String get accountDeleteGoogleBody;

  /// Asks an account made with Sign in with Apple to confirm with Apple before deleting it.
  ///
  /// In en, this message translates to:
  /// **'To delete the account, confirm with Apple that it\'s you.'**
  String get accountDeleteAppleBody;

  /// Shown while the account is being deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account…'**
  String get accountDeleting;

  /// Snackbar after the account was deleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get accountDeleted;

  /// Shown when deleting the account failed for a reason other than a sign-in error.
  ///
  /// In en, this message translates to:
  /// **'Your account couldn\'t be deleted. Check your internet connection and try again.'**
  String get accountDeleteFailed;

  /// The sign-in service wants a fresh sign-in before a sensitive change.
  ///
  /// In en, this message translates to:
  /// **'For your security, please confirm your password or account again.'**
  String get authErrorRecentLogin;

  /// The learner confirmed with a different account from the signed-in one.
  ///
  /// In en, this message translates to:
  /// **'That\'s a different account. Choose the account you\'re signed in with.'**
  String get authErrorWrongAccount;
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
