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

  /// Title of the modal bottom sheet shown during live lesson-play when an answer is wrong.
  ///
  /// In en, this message translates to:
  /// **'Not quite'**
  String get activityIncorrectSheetTitle;

  /// Body text of the incorrect-answer bottom sheet, revealing the correct answer for this activity only.
  ///
  /// In en, this message translates to:
  /// **'The correct answer is: {correctAnswer}'**
  String activityIncorrectSheetBody(String correctAnswer);

  /// Button on the incorrect-answer bottom sheet that dismisses it and advances to the next activity.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get activityIncorrectSheetContinue;

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

  /// Button on a listening activity's audio card that reveals the hidden transcript text on demand.
  ///
  /// In en, this message translates to:
  /// **'Show transcript'**
  String get activityShowTranscript;

  /// Suggested word count range for a writing activity.
  ///
  /// In en, this message translates to:
  /// **'About {min}-{max} words'**
  String activityWordGuide(int min, int max);

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

  /// Marker on the Learn journey spine showing the learner's current unit.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get unitPathYouAreHere;

  /// Unit overview header caption — how many of this unit's lessons have been played through to the end.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} lessons complete'**
  String unitOverviewLessonsComplete(int completed, int total);

  /// Shown when a learner opens an A2-C2 level card.
  ///
  /// In en, this message translates to:
  /// **'This level isn\'t available yet. A1 is ready now — start there.'**
  String get comingSoonLevelBody;

  /// Home screen card title for the next recommended unit.
  ///
  /// In en, this message translates to:
  /// **'Continue learning'**
  String get continueLearningTitle;

  /// Button label on the Continue learning card.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLearningCta;

  /// Shown on Home when there is no next unit to recommend.
  ///
  /// In en, this message translates to:
  /// **'You\'ve mastered every A1 unit so far!'**
  String get homeAllUnitsMastered;

  /// Home streak card title.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{No streak yet} =1{1-day streak} other{{days}-day streak}}'**
  String homeStreakTitle(int days);

  /// Home streak card subtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep it going today'**
  String get homeStreakEncouragement;

  /// Home level-progress card title.
  ///
  /// In en, this message translates to:
  /// **'A1 progress'**
  String get homeLevelProgressTitle;

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

  /// Home screen section title above the 3 daily-task tiles.
  ///
  /// In en, this message translates to:
  /// **'Tasks today'**
  String get homeTasksTodayTitle;

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

  /// Vocabulary screen row label — count of favourited words/chunks.
  ///
  /// In en, this message translates to:
  /// **'Saved words'**
  String get vocabularySavedWordsTitle;

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

  /// Vocabulary list filter toggle.
  ///
  /// In en, this message translates to:
  /// **'Favourites only'**
  String get vocabularyFavoritesOnly;

  /// Vocabulary list filter toggle — words the learner is expected to produce, not just recognise.
  ///
  /// In en, this message translates to:
  /// **'Productive only'**
  String get vocabularyProductiveOnly;

  /// Shown when a vocabulary search/filter combination matches nothing.
  ///
  /// In en, this message translates to:
  /// **'No words match your search.'**
  String get vocabularyEmptyResults;

  /// Word/chunk/grammar detail screen — which unit first taught this item.
  ///
  /// In en, this message translates to:
  /// **'Introduced in {unitTitle}'**
  String wordDetailIntroducedIn(String unitTitle);

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

  /// Confirmation shown briefly after tapping a spaced-review confidence button, before returning to the previous screen.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get reviewConfidenceSaved;

  /// Grammar detail screen field label.
  ///
  /// In en, this message translates to:
  /// **'Form'**
  String get grammarDetailForm;

  /// Grammar detail screen — lessons that teach/use this structure.
  ///
  /// In en, this message translates to:
  /// **'Practiced in'**
  String get grammarDetailLinkedLessons;

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

  /// Review tab section heading — vocabulary/chunks due per the spaced-review schedule.
  ///
  /// In en, this message translates to:
  /// **'Due for review'**
  String get reviewSectionDue;

  /// Review tab section heading.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get reviewSectionFavorites;

  /// Review tab section heading — Can-Do objectives with evidence that doesn't yet meet the mastery threshold.
  ///
  /// In en, this message translates to:
  /// **'Needs more practice'**
  String get reviewSectionWeakObjectives;

  /// Empty state for the due-for-review section.
  ///
  /// In en, this message translates to:
  /// **'Nothing due right now.'**
  String get reviewNothingDue;

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

  /// Tests tab card title.
  ///
  /// In en, this message translates to:
  /// **'A1 Gateway Placement Test'**
  String get testsHomePlacementTitle;

  /// Tests tab card subtitle.
  ///
  /// In en, this message translates to:
  /// **'Not sure where to start? Find your best starting point in A1.'**
  String get testsHomePlacementSubtitle;

  /// Tests tab card title.
  ///
  /// In en, this message translates to:
  /// **'A1 Final Mission'**
  String get testsHomeFinalMissionTitle;

  /// Tests tab card subtitle.
  ///
  /// In en, this message translates to:
  /// **'A scenario-based capstone that pulls together everything you\'ve learned.'**
  String get testsHomeFinalMissionSubtitle;

  /// Tests tab card title.
  ///
  /// In en, this message translates to:
  /// **'A1 Final Assessment'**
  String get testsHomeFinalAssessmentTitle;

  /// Tests tab card subtitle.
  ///
  /// In en, this message translates to:
  /// **'A short exit test covering every skill, scored separately — no single score hides a weak skill.'**
  String get testsHomeFinalAssessmentSubtitle;

  /// Tests tab card title — informational, links to the Learn tab rather than opening its own flow.
  ///
  /// In en, this message translates to:
  /// **'Unit mastery checks'**
  String get testsHomeUnitChecksTitle;

  /// Tests tab card subtitle.
  ///
  /// In en, this message translates to:
  /// **'See how each unit is progressing on the Learn tab.'**
  String get testsHomeUnitChecksSubtitle;

  /// Tests tab card title for a not-yet-built feature — disabled, shown with the app-wide comingSoon label.
  ///
  /// In en, this message translates to:
  /// **'A2 and beyond placement'**
  String get testsHomeFutureLevelsTitle;

  /// Tests tab card state line — no attempt exists yet.
  ///
  /// In en, this message translates to:
  /// **'Not yet taken'**
  String get testsHomeNotYetTaken;

  /// Tests tab card state line — an attempt was started but not completed.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get testsHomeInProgress;

  /// Tests tab card state line — an attempt was completed on this date.
  ///
  /// In en, this message translates to:
  /// **'Completed {date}'**
  String testsHomeCompletedOn(String date);

  /// Placement test intro screen app bar title.
  ///
  /// In en, this message translates to:
  /// **'A1 Gateway Placement Test'**
  String get placementIntroTitle;

  /// Placement test intro screen body text.
  ///
  /// In en, this message translates to:
  /// **'A few quick questions across the A1 units, from easiest to hardest. We\'ll stop as soon as we find your starting point — most people finish in a few minutes.'**
  String get placementIntroBody;

  /// Placement test intro screen start button.
  ///
  /// In en, this message translates to:
  /// **'Start'**
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
  /// **'Begin'**
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
  /// **'A short exit test covering every skill from A1. Each skill is scored on its own — a strong score in one never covers for a weak one in another.'**
  String get finalAssessmentIntroBody;

  /// Final Assessment intro screen start button.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
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

  /// Grammar list screen's unit-filter chip that clears the filter and shows every unit's grammar.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get grammarFilterAllUnits;

  /// Chip label on a vocabulary word's detail screen, shown when the word is tagged receptive (recognise, not necessarily produce).
  ///
  /// In en, this message translates to:
  /// **'Receptive'**
  String get vocabularyReceptiveLabel;

  /// Chip label on a vocabulary word's detail screen, shown when the word is tagged productive (expected to actively use it).
  ///
  /// In en, this message translates to:
  /// **'Productive'**
  String get vocabularyProductiveLabel;

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
