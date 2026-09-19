// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Mohingo';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navLearn => 'تعلّم';

  @override
  String get navReview => 'مراجعة';

  @override
  String get navTests => 'الاختبارات';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get comingSoon => 'قريباً';

  @override
  String placeholderScreenBody(String screenName) {
    return '$screenName — قادمة في مرحلة لاحقة.';
  }

  @override
  String get activitySubmitButton => 'تحقّق';

  @override
  String get activityFeedbackCorrect => 'إجابة صحيحة!';

  @override
  String activityFeedbackIncorrectWithAnswer(String correctAnswer) {
    return 'ليست صحيحة — الإجابة الصحيحة هي: $correctAnswer';
  }

  @override
  String get activityFeedbackSavedForReview =>
      'تم الحفظ — سيُراجَع لاحقاً ولن يُصحَّح تلقائياً.';

  @override
  String get activityFeedbackPendingOnlineRefinement =>
      'تم الحفظ — سنكمل تصحيح هذه الإجابة عند اتصالك بالإنترنت';

  @override
  String get activitySpeechUnavailableUseWriting =>
      'التحدث غير متاح على هذا الجهاز حالياً — اكتب إجابتك بدلاً من ذلك.';

  @override
  String get activityContinue => 'متابعة';

  @override
  String get activityFeedbackIncorrectTitle => 'ليست صحيحة';

  @override
  String get activityFeedbackCorrectAnswerLabel => 'الإجابة الصحيحة';

  @override
  String get activityFeedbackSavedTitle => 'حُفظت إجابتك';

  @override
  String get activityListenTitle => 'استمع';

  @override
  String get activityListenHint => 'اضغط للاستماع مرة أخرى';

  @override
  String get activityListenSlower => 'أبطأ';

  @override
  String activityWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count كلمة',
      many: '$count كلمة',
      few: '$count كلمات',
      two: 'كلمتان',
      one: 'كلمة واحدة',
      zero: 'لا كلمات',
    );
    return '$_temp0';
  }

  @override
  String activityWordGuideTarget(int min, int max) {
    return 'المطلوب: $min–$max كلمة';
  }

  @override
  String activityMatchProgress(int matched, int total) {
    return 'تمت مطابقة $matched من $total';
  }

  @override
  String get activityOrderEmptyHint => 'اضغط على الكلمات بالترتيب';

  @override
  String get activityAnswerFieldHint => 'اكتب إجابتك';

  @override
  String get activityShowTranscript => 'عرض النص';

  @override
  String get contentErrorTitle => 'تعذّر تحميل الدروس';

  @override
  String get contentErrorBody =>
      'حدث خطأ أثناء تحميل محتوى الدورة. جرّب إعادة تثبيت التطبيق؛ تقدّمك محفوظ بشكل منفصل ولن يُفقد.';

  @override
  String get unitStateNotStarted => 'لم تبدأ بعد';

  @override
  String get unitStateInProgress => 'قيد التقدّم';

  @override
  String get unitStateMastered => 'أتقنتها';

  @override
  String get unitStateNeedsReview => 'تحتاج مراجعة';

  @override
  String get lessonStateCompleted => 'مكتمل';

  @override
  String get vocabularyStateLearned => 'محفوظة';

  @override
  String unitOverviewLessonsComplete(int completed, int total) {
    return 'أكملت $completed من $total دروس';
  }

  @override
  String get homeAllUnitsMastered => 'أتقنت جميع وحدات A1 حتى الآن!';

  @override
  String homeLevelProgressCaption(int mastered, int total) {
    return 'أتقنت $mastered من $total وحدة';
  }

  @override
  String homeReviewDueTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر بحاجة للمراجعة',
      many: '$count عنصراً بحاجة للمراجعة',
      few: '$count عناصر بحاجة للمراجعة',
      two: 'عنصران بحاجة للمراجعة',
      one: 'عنصر واحد بحاجة للمراجعة',
      zero: 'لا يوجد شيء بحاجة للمراجعة',
    );
    return '$_temp0';
  }

  @override
  String get homeGreetingMorning => 'صباح الخير';

  @override
  String get homeGreetingAfternoon => 'مساء الخير';

  @override
  String get homeGreetingEvening => 'مساء الخير';

  @override
  String homeLevelBadge(String cefr) {
    return '$cefr · مبتدئ';
  }

  @override
  String homeStreakChip(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم',
      many: '$days يوماً',
      few: '$days أيام',
      two: 'يومان',
      one: 'يوم واحد',
      zero: 'لا يوجد تتابع',
    );
    return '$_temp0';
  }

  @override
  String homeUnitLessonOverline(int unit, int lesson) {
    return 'الوحدة $unit · الدرس $lesson';
  }

  @override
  String homeUnitReviewOverline(int unit) {
    return 'الوحدة $unit · مراجعة';
  }

  @override
  String get homeUnitAllLessonsDone =>
      'أنهيت كل الدروس — راجع هذه الوحدة لإتقانها.';

  @override
  String homeActivityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نشاط',
      many: '$count نشاطاً',
      few: '$count أنشطة',
      two: 'نشاطان',
      one: 'نشاط واحد',
    );
    return '$_temp0';
  }

  @override
  String get homeLessonTypeGuided => 'درس موجَّه';

  @override
  String get homeLessonTypePractice => 'تدريب';

  @override
  String get homeLessonTypeConversation => 'محادثة';

  @override
  String get homeLessonTypeMission => 'مهمة';

  @override
  String get homeLessonProgressLabel => 'تقدّم الدرس';

  @override
  String get homeLessonNew => 'درس جديد';

  @override
  String homeLessonPercent(int percent) {
    return '$percent٪';
  }

  @override
  String get homeStartLessonCta => 'ابدأ الدرس';

  @override
  String get homeContinueLessonCta => 'أكمل الدرس';

  @override
  String get homeOpenUnitCta => 'افتح الوحدة';

  @override
  String get homeTodaysGoalTitle => 'هدف اليوم';

  @override
  String homeGoalsDone(int done, int total) {
    return 'أنجزت $done من $total';
  }

  @override
  String get homeJourneyTitle => 'رحلتك';

  @override
  String homeJourneyUnitOf(int current, int total) {
    return 'الوحدة $current من $total';
  }

  @override
  String homeJourneyNow(String title) {
    return 'الآن · $title';
  }

  @override
  String homeJourneyNext(String title) {
    return 'التالي · $title';
  }

  @override
  String get homeReviewNowCta => 'راجع الآن';

  @override
  String get homeTaskFinishLesson => 'أنهِ درساً';

  @override
  String get homeTaskReviewWords => 'راجع 5 كلمات';

  @override
  String get homeTaskSpeakOnce => 'تحدّث مرة';

  @override
  String get lessonCompleteTitle => 'اكتمل الدرس';

  @override
  String lessonCompleteTally(int correct, int total) {
    return 'الإجابات الصحيحة: $correct من $total';
  }

  @override
  String lessonCompletePendingReview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إجابة محفوظة للمراجعة',
      many: '$count إجابةً محفوظة للمراجعة',
      few: '$count إجابات محفوظة للمراجعة',
      two: 'إجابتان محفوظتان للمراجعة',
      one: 'إجابة واحدة محفوظة للمراجعة',
      zero: 'لا توجد إجابات محفوظة للمراجعة',
    );
    return '$_temp0';
  }

  @override
  String get lessonCompleteNextLesson => 'الدرس التالي';

  @override
  String get lessonCompleteBackToUnit => 'العودة إلى الوحدة';

  @override
  String get lessonPlayerClose => 'إغلاق الدرس';

  @override
  String get lessonPlayerPhaseWarmUp => 'إحماء';

  @override
  String get lessonPlayerPhasePractice => 'تدريب';

  @override
  String get lessonPlayerPhaseUseIt => 'تطبيق';

  @override
  String lessonPlayerEyebrow(String phase, String skill) {
    return '$phase · $skill';
  }

  @override
  String get lessonIntroListenTitle => 'استمع إلى المحادثة';

  @override
  String get lessonIntroListenHint => 'اضغط على أي سطر لتسمعه مرة أخرى';

  @override
  String get lessonIntroPlayConversation => 'شغّل المحادثة';

  @override
  String get lessonIntroStopConversation => 'أوقف المحادثة';

  @override
  String get lessonIntroArabicToggle => 'الترجمة العربية';

  @override
  String get lessonIntroPlaying => 'يُقرأ الآن';

  @override
  String get lessonIntroKeyPhrasesTitle => 'عبارات أساسية';

  @override
  String get lessonIntroGrammarTitle => 'القواعد';

  @override
  String get lessonIntroNew => 'جديد';

  @override
  String get lessonIntroStartPractice => 'ابدأ التدريب';

  @override
  String get learnCourseOverline => 'مقررك';

  @override
  String get learnUnitsTitle => 'الوحدات';

  @override
  String learnLessonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count درس',
      many: '$count درساً',
      few: '$count دروس',
      two: 'درسان',
      one: 'درس واحد',
      zero: 'لا دروس',
    );
    return '$_temp0';
  }

  @override
  String learnUnitMinutes(int min, int max) {
    return 'من $min إلى $max دقيقة';
  }

  @override
  String get learnUnitStarter => 'تمهيدية';

  @override
  String learnUnitInProgressOverline(int unit) {
    return 'الوحدة $unit · قيد التعلّم';
  }

  @override
  String learnUnitStartHereOverline(int unit) {
    return 'الوحدة $unit · ابدأ من هنا';
  }

  @override
  String learnUnitLessonsDone(int done, int total) {
    return 'الدروس المكتملة: $done من $total';
  }

  @override
  String learnUnitNodeSemantics(int unit, String state) {
    return 'الوحدة $unit: $state';
  }

  @override
  String learnUnitOverline(int unit) {
    return 'الوحدة $unit';
  }

  @override
  String learnLessonInProgressOverline(int lesson) {
    return 'الدرس $lesson · قيد التعلّم';
  }

  @override
  String learnLessonStartHereOverline(int lesson) {
    return 'الدرس $lesson · ابدأ من هنا';
  }

  @override
  String get learnMissionOverline => 'مهمة الوحدة';

  @override
  String get learnMissionBody => 'تُثبت إتقانك للوحدة';

  @override
  String get learnLessonCompletedReview => 'مكتمل · راجع إجاباتك';

  @override
  String get learnLessonNeedsReviewReview =>
      'بعض الإجابات تحتاج مراجعة · راجع إجاباتك';

  @override
  String learnLessonNodeSemantics(int lesson, String state) {
    return 'الدرس $lesson: $state';
  }

  @override
  String get learnLessonHasConversation => 'يبدأ بمحادثة';

  @override
  String get learnFinishOverline => 'ختام المستوى A1';

  @override
  String get learnFinishTitle => 'المهمة النهائية والتقييم';

  @override
  String get learnFinishBody =>
      'بعد آخر وحدة، أظهر ما تستطيع فعله — في تبويب الاختبارات.';

  @override
  String get learnComingLaterTitle => 'قريباً';

  @override
  String get learnComingLaterBody =>
      'مستويات أخرى في الطريق، وكل ما تتعلّمه في A1 يبقى معك.';

  @override
  String get lessonCompleteCorrectCaption => 'صحيحة';

  @override
  String get lessonCompleteStreakLabel => 'التتابع';

  @override
  String get lessonCompleteAccuracyLabel => 'الدقة';

  @override
  String get lessonCompletePhrasesLabel => 'عبارات';

  @override
  String get lessonCompleteQuestionsLabel => 'أسئلة';

  @override
  String get lessonCompleteSkillsTitle => 'مهارات تدرّبت عليها';

  @override
  String lessonCompleteUpNext(int lesson) {
    return 'التالي · الدرس $lesson';
  }

  @override
  String get lessonCompleteReviewAnswers => 'راجع إجاباتك';

  @override
  String get lessonPlayerNext => 'التالي';

  @override
  String lessonPlayerProgress(int current, int total) {
    return '$current من $total';
  }

  @override
  String lessonReviewOverline(int unit, int lesson) {
    return 'الوحدة $unit · الدرس $lesson · إجاباتك';
  }

  @override
  String lessonReviewScore(int right, int total) {
    return '$right من $total صحيحة';
  }

  @override
  String lessonReviewQuestion(int n) {
    return 'السؤال $n';
  }

  @override
  String lessonReviewQuestionHeader(int n, String skill) {
    return '$n · $skill';
  }

  @override
  String get lessonReviewRight => 'صحيحة';

  @override
  String get lessonReviewNotQuite => 'ليست تماماً';

  @override
  String get lessonReviewSaved => 'محفوظة';

  @override
  String get lessonReviewNotAnsweredPill => 'بلا إجابة';

  @override
  String get lessonReviewFilterAll => 'الكل';

  @override
  String get lessonReviewFilterToRevisit => 'للمراجعة';

  @override
  String get lessonReviewNothingToRevisit =>
      'لا شيء للمراجعة — كل الإجابات صحيحة.';

  @override
  String get lessonReviewPracticeAgain => 'تدرّب على هذا الدرس مجدداً';

  @override
  String get lessonReviewNotAnswered => 'لم تُجب عن هذا السؤال.';

  @override
  String get vocabularyStatDue => 'مستحقة';

  @override
  String get vocabularyStatLearning => 'قيد التعلم';

  @override
  String get vocabularyFilterAll => 'الكل';

  @override
  String get vocabularyFilterSaved => 'المحفوظة';

  @override
  String get vocabularyFilterProductive => 'للتحدث والكتابة';

  @override
  String vocabularyFilterSemantics(String label, int count) {
    return '$label: $count';
  }

  @override
  String get partOfSpeechNoun => 'اسم';

  @override
  String get partOfSpeechVerb => 'فعل';

  @override
  String get partOfSpeechAdjective => 'صفة';

  @override
  String get partOfSpeechAdverb => 'ظرف';

  @override
  String get partOfSpeechNumber => 'عدد';

  @override
  String get partOfSpeechProperNoun => 'اسم علم';

  @override
  String get partOfSpeechPhrase => 'عبارة';

  @override
  String get partOfSpeechInterjection => 'كلمة تعجّب وتحية';

  @override
  String get partOfSpeechPreposition => 'حرف جر';

  @override
  String get partOfSpeechConjunction => 'حرف عطف';

  @override
  String get wordUsageProductive => 'ستستخدم هذه الكلمة في التحدث والكتابة.';

  @override
  String get wordUsageReceptive =>
      'ستحتاج إلى فهم هذه الكلمة عند الاستماع والقراءة.';

  @override
  String get wordStatusNew =>
      'ليست في مراجعاتك بعد — قيّمها في الأسفل لإضافتها.';

  @override
  String get wordStatusDue => 'حان وقت مراجعتها';

  @override
  String get wordMetInOverline => 'أين تعلّمتها';

  @override
  String wordMetInMeta(int unit, int lesson) {
    return 'الوحدة $unit · الدرس $lesson';
  }

  @override
  String get vocabularyTabWords => 'كلمات';

  @override
  String get vocabularyTabChunks => 'عبارات';

  @override
  String get vocabularySearchHint => 'ابحث بالإنجليزية أو العربية';

  @override
  String get vocabularyEmptyResults => 'لا توجد كلمات مطابقة لبحثك.';

  @override
  String get wordDetailExamples => 'أمثلة';

  @override
  String get reviewHowWellKnew => 'كم كنت تعرف هذه الكلمة؟';

  @override
  String get reviewQualityAgain => 'أعد';

  @override
  String get reviewQualityGood => 'جيد';

  @override
  String get reviewQualityEasy => 'سهل';

  @override
  String get grammarEmptyResults => 'لا توجد قواعد تطابق بحثك.';

  @override
  String grammarOverline(int unit) {
    return 'قواعد · الوحدة $unit';
  }

  @override
  String grammarShortForm(String form) {
    return 'الصيغة المختصرة: $form';
  }

  @override
  String get grammarPractisedInOverline => 'أين تتدرّب عليها';

  @override
  String get grammarMarkReviewed => 'ضعها كمُراجَعة';

  @override
  String get grammarReviewed => 'تمت مراجعتها';

  @override
  String get grammarQuickPractice => 'تمرين سريع';

  @override
  String get grammarNoLinkedPractice => 'لا يوجد تمرين مرتبط بعد.';

  @override
  String practiceEyebrow(String title, int n, int total) {
    return 'تدريب · $title · $n من $total';
  }

  @override
  String practiceOverline(String title) {
    return 'تدريب · $title';
  }

  @override
  String get practiceNoMastery =>
      'لا يُحتسب هذا التدريب في الإتقان — الدرس ومهمة وحدته هما ما يُحتسب.';

  @override
  String get practiceAgain => 'تدرّب مجدداً';

  @override
  String get quickPracticeDone => 'تم';

  @override
  String get reviewHubSubtitle => 'حافظ على ما تعلّمته وقوِّ نقاط ضعفك.';

  @override
  String get reviewDueOverline => 'حان وقت مراجعتها';

  @override
  String reviewDueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count كلمة وعبارة',
      few: '$count كلمات وعبارات',
      two: 'كلمتان أو عبارتان',
      one: 'كلمة أو عبارة واحدة',
    );
    return '$_temp0';
  }

  @override
  String reviewDueMore(int count) {
    return 'و$count غيرها';
  }

  @override
  String reviewDueMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'نحو $minutes دقيقة',
      few: 'نحو $minutes دقائق',
      two: 'نحو دقيقتين',
      one: 'نحو دقيقة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get reviewStartCta => 'ابدأ المراجعة';

  @override
  String get reviewCaughtUpTitle => 'أنهيت كل المراجعات';

  @override
  String reviewNextIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'المراجعة التالية بعد $days يوماً',
      few: 'المراجعة التالية بعد $days أيام',
      two: 'المراجعة التالية بعد يومين',
      one: 'المراجعة التالية غداً',
      zero: 'المراجعة التالية لاحقاً اليوم',
    );
    return '$_temp0';
  }

  @override
  String get reviewCaughtUpEmpty =>
      'تعود إليك هنا الكلمات والعبارات من دروسك في اليوم التالي لتعلّمها.';

  @override
  String get reviewWeakSpotsOverline => 'تدرّب على نقاط ضعفك';

  @override
  String get reviewWeakSpotsBody =>
      'أهداف في الوحدات التي تدرسها تحتاج إلى مزيد من التدريب';

  @override
  String reviewWeakSpotMeta(int unit, String skills) {
    return 'الوحدة $unit · $skills';
  }

  @override
  String reviewShowAll(int count) {
    return 'الكل ($count)';
  }

  @override
  String get reviewShowFewer => 'عرض أقل';

  @override
  String get reviewBrowseOverline => 'تصفّح';

  @override
  String get reviewWordsTile => 'الكلمات والعبارات';

  @override
  String reviewWordsTileMeta(int inReview, int total) {
    return '$inReview من $total قيد المراجعة';
  }

  @override
  String reviewGrammarTileMeta(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صيغة',
      few: '$count صيغ',
      two: 'صيغتان',
      one: 'صيغة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get reviewSavedOverline => 'المحفوظة';

  @override
  String get reviewSessionWord => 'كلمة';

  @override
  String get reviewSessionPhrase => 'عبارة';

  @override
  String get reviewSessionPrompt => 'قل معناها، ثم تحقّق.';

  @override
  String get reviewShowAnswer => 'اعرض الإجابة';

  @override
  String reviewSeeAgain(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'بعد $days يوماً',
      few: 'بعد $days أيام',
      two: 'بعد يومين',
      one: 'غداً',
    );
    return '$_temp0';
  }

  @override
  String reviewSessionProgress(int current, int total) {
    return '$current من $total';
  }

  @override
  String get reviewSessionDoneTitle => 'انتهت المراجعة';

  @override
  String reviewSessionDoneBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'راجعت $count كلمة وعبارة',
      few: 'راجعت $count كلمات وعبارات',
      two: 'راجعت كلمتين أو عبارتين',
      one: 'راجعت كلمة أو عبارة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get reviewSessionDoneCta => 'تم';

  @override
  String get reviewSessionEmpty => 'لا شيء للمراجعة الآن.';

  @override
  String get reviewNoFavorites =>
      'لا توجد عناصر مفضلة بعد — أضف كلمات أو عبارات أو قواعد إلى المفضلة لحفظها هنا.';

  @override
  String get reviewNoWeakObjectives =>
      'لا يوجد شيء بحاجة لانتباه — واصل التقدم!';

  @override
  String get speakTapToRecord => 'اضغط للتسجيل';

  @override
  String get speakTapToRecordHint => 'ستتمكن من مراجعة ما سمعناه قبل الإرسال.';

  @override
  String get speakTapToStop => 'اضغط للإيقاف';

  @override
  String get speakEnableMicrophoneHint => 'لا نستمع إليك إلا أثناء التسجيل.';

  @override
  String get speakShowUsefulPhrases => 'اعرض عبارات مفيدة';

  @override
  String get speakHideUsefulPhrases => 'أخفِ العبارات المفيدة';

  @override
  String get speakEnableMicrophone => 'تفعيل الميكروفون';

  @override
  String get speakStartRecording => 'سجّل';

  @override
  String get speakStopRecording => 'إيقاف';

  @override
  String get speakListening => 'جارٍ الاستماع…';

  @override
  String get speakReviewTranscript => 'راجع ما تم سماعه قبل الإرسال:';

  @override
  String get speakUseTypedAnswerInstead => 'اكتب إجابتي بدلاً من ذلك';

  @override
  String get speakRerecord => 'أعد التسجيل';

  @override
  String get speakPermissionPermanentlyDenied =>
      'تم إيقاف الوصول إلى الميكروفون لهذا التطبيق. يمكنك كتابة إجابتك، أو تفعيله من إعدادات جهازك.';

  @override
  String get settingsSpeechTitle => 'الاستماع والتحدث';

  @override
  String get settingsSpeechRate => 'سرعة الصوت';

  @override
  String get settingsSpeechPitch => 'طبقة الصوت';

  @override
  String get speechListen => 'استمع';

  @override
  String get skillListening => 'الاستماع';

  @override
  String get skillReading => 'القراءة';

  @override
  String get skillWriting => 'الكتابة';

  @override
  String get skillSpokenInteraction => 'التحدث التفاعلي';

  @override
  String get skillSpokenProduction => 'التحدث الإنتاجي';

  @override
  String get skillMediation => 'الوساطة اللغوية';

  @override
  String get skillSpeaking => 'التحدث';

  @override
  String get testsHubSubtitle => 'اعرف أين أنت في A1 — وأثبت ذلك في النهاية.';

  @override
  String get testsStartHereOverline => 'ابدأ من هنا';

  @override
  String get testsPlacementHeroTitle => 'اعثر على نقطة البداية';

  @override
  String get testsPlacementHeroBody =>
      'تعرف بعض الإنجليزية؟ اختبار تحديد مستوى قصير يتخطّى ما تعرفه.';

  @override
  String get testsPlacementMeta => 'يتوقف بمجرد أن يحدد مستواك';

  @override
  String get testsPlacementCta => 'ابدأ اختبار تحديد المستوى';

  @override
  String get testsPlacementOverline => 'تحديد المستوى';

  @override
  String get testsPlacementTitle => 'اختبار تحديد المستوى';

  @override
  String testsTakenOn(String date) {
    return 'أُجري في $date';
  }

  @override
  String get testsNotTaken => 'لم يُجرَ بعد';

  @override
  String get testsNotFinished => 'لم يكتمل';

  @override
  String testsPlacementResultUnit(int unit) {
    return 'النتيجة: ابدأ من الوحدة $unit';
  }

  @override
  String get testsPlacementResultMastered => 'النتيجة: أتقنت A1 بالفعل';

  @override
  String get testsFinishOverline => 'أنهِ A1';

  @override
  String testsFinishProgress(int mastered, int total) {
    return 'أتقنت $mastered من $total وحدة — الأفضل بعد إنهاء المقرر.';
  }

  @override
  String testsFinishReady(int total) {
    return 'أتقنت كل الوحدات الـ$total — أنت جاهز.';
  }

  @override
  String get testsMissionBody =>
      'استخدم كل ما تعلّمته في A1 في موقف واقعي واحد، مرحلة بعد مرحلة.';

  @override
  String testsMissionMeta(int tasks, int stages, int min, int max) {
    return '$tasks مهمة · $stages مراحل · $min–$max دقيقة';
  }

  @override
  String get testsAssessmentBody =>
      'تُقيَّم كل مهارة وحدها — لا تختبئ مهارة ضعيفة خلف غيرها.';

  @override
  String testsAssessmentMeta(int questions, int skills, int min, int max) {
    return '$questions سؤالاً · $skills مهارات · $min–$max دقيقة';
  }

  @override
  String get testsPassed => 'نجحت';

  @override
  String get testsNotPassedYet => 'لم تنجح بعد';

  @override
  String testsSkillsPassed(int passed, int total) {
    return 'نجحت في $passed من $total مهارات';
  }

  @override
  String get testsUnitChecksNote =>
      'تُقيَّم كل وحدة أثناء تقدّمك — مهمتها في تبويب «تعلّم».';

  @override
  String get testAnswerSaved => 'حُفظت إجابتك';

  @override
  String get testAnswerSavedBody => 'سترى نتائجك في النهاية.';

  @override
  String get testNextQuestion => 'السؤال التالي';

  @override
  String get testRulesNote =>
      'لا تُصحَّح الإجابات أثناء الاختبار، ولا تظهر نصوص الاستماع. سترى نتائجك في النهاية.';

  @override
  String get testIntroCoversHeading => 'ما يشمله';

  @override
  String get testIntroStagesHeading => 'المراحل';

  @override
  String testIntroQuestionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سؤالاً',
      few: '$count أسئلة',
      two: 'سؤالان',
      one: 'سؤال واحد',
    );
    return '$_temp0';
  }

  @override
  String testIntroTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مهمة',
      few: '$count مهام',
      two: 'مهمتان',
      one: 'مهمة واحدة',
    );
    return '$_temp0';
  }

  @override
  String testQuestionEyebrow(String section, int n, int total) {
    return '$section · $n من $total';
  }

  @override
  String get testsMissionOverline => 'المهمة النهائية';

  @override
  String get testsAssessmentOverline => 'الاختبار النهائي';

  @override
  String get placementCoversReceptive =>
      'أسئلة استماع وقراءة من كل وحدة، من الأسهل إلى الأصعب';

  @override
  String get placementCoversProductive => 'مهمة كتابة أو تحدث واحدة في النهاية';

  @override
  String get placementCoversStops => 'يتوقف عند أول وحدة جديدة عليك';

  @override
  String get placementIntroTitle => 'اختبار تحديد المستوى لـ A1';

  @override
  String get placementIntroBody =>
      'بضعة أسئلة من كل وحدة في A1، من الأسهل إلى الأصعب. يتوقف عند أول وحدة جديدة عليك — فكلما عرفت أكثر، طال الاختبار.';

  @override
  String get placementStartButton => 'ابدأ اختبار تحديد المستوى';

  @override
  String get testsResultHowYouDid => 'كيف كان أداؤك';

  @override
  String testsSkillScore(int right, int total) {
    return '$right من $total';
  }

  @override
  String get testsWaitingReview => 'بانتظار المراجعة';

  @override
  String get testsPendingBody =>
      'إجاباتك محفوظة، وتُقيَّم هذه المهارة بعد مراجعتها.';

  @override
  String testsScorePassMark(int score, int mark) {
    return '$score% · درجة النجاح $mark%';
  }

  @override
  String get placementResultOverline => 'نتيجة تحديد المستوى';

  @override
  String placementResultHeadline(int unit) {
    return 'ابدأ من الوحدة $unit';
  }

  @override
  String get placementResultBodyEssentials =>
      'تمنحك الوحدة 1 الأساسيات التي تُبنى عليها كل الوحدات الأخرى.';

  @override
  String placementResultBodyUnit(int unit) {
    return 'تعرف الوحدات السابقة جيداً. في الوحدة $unit تبدأ الأشياء الجديدة عليك.';
  }

  @override
  String get placementResultMasteredTitle => 'يبدو أنك أتقنت A1';

  @override
  String get placementResultMasteredBody =>
      'خذ الاختبار النهائي لتثبت ذلك. المستويات الأعلى في الطريق.';

  @override
  String get placementResultEarlierOpen =>
      'تبقى الوحدات السابقة مفتوحة — عد إلى أي درس متى شئت.';

  @override
  String placementResultGoToUnitN(int unit) {
    return 'انتقل إلى الوحدة $unit';
  }

  @override
  String get placementConfidence1 => 'لست واثقاً أبداً';

  @override
  String get placementConfidence2 => 'واثق قليلاً';

  @override
  String get placementConfidence3 => 'واثق إلى حدّ ما';

  @override
  String get placementConfidence4 => 'واثق بدرجة كبيرة';

  @override
  String get placementConfidence5 => 'واثق تماماً';

  @override
  String get placementConfidenceNote => 'إجابتك لا تغيّر نتيجتك.';

  @override
  String get missionResultPassedTitle => 'اكتملت المهمة';

  @override
  String get missionResultPassedBody =>
      'نجحت كل المهارات المطلوبة على مدار اليوم.';

  @override
  String get missionResultNotYetTitle => 'لم تنجح بعد';

  @override
  String get missionResultNotYetBody =>
      'بعض المهارات تحتاج إلى مزيد من التدريب — انظر أدناه. يمكنك إعادة المهمة في أي وقت.';

  @override
  String get assessmentResultPassedTitle => 'نجحت في A1';

  @override
  String get assessmentResultNotYetTitle => 'لم تنجح بعد';

  @override
  String assessmentResultBody(int passed, int total) {
    return 'نجحت في $passed من $total مهارات.';
  }

  @override
  String get placementConfidenceQuestion =>
      'بشكل عام، كم شعرت بالثقة في إجاباتك؟';

  @override
  String get placementResultDone => 'تم';

  @override
  String get finalMissionStartButton => 'ابدأ المهمة';

  @override
  String get finalMissionDone => 'تم';

  @override
  String get finalAssessmentIntroBody =>
      'الاختبار الختامي لمستوى A1. تُقيَّم كل مهارة على حدة — لا يعوّض تفوقك في مهارة ضعفك في أخرى.';

  @override
  String get finalAssessmentStartButton => 'ابدأ الاختبار';

  @override
  String get finalAssessmentSkillPassed => 'تم اجتيازها';

  @override
  String get finalAssessmentSkillNotMet => 'لم تُحقَّق بعد';

  @override
  String get finalAssessmentDone => 'تم';

  @override
  String get finalAssessmentWhatsNext => 'واصل التدرّب';

  @override
  String get contentNotFoundTitle => 'لم يتم العثور على المحتوى';

  @override
  String get grammarSectionTitle => 'القواعد';

  @override
  String get favoriteAddTooltip => 'أضف إلى المفضلة';

  @override
  String get favoriteRemoveTooltip => 'أزل من المفضلة';

  @override
  String get settingsAppearanceOverline => 'المظهر';

  @override
  String get settingsLanguageBody =>
      'تبقى الدروس بالإنجليزية؛ هذا يغيّر القوائم والمساعدة.';

  @override
  String get settingsSlower => 'أبطأ';

  @override
  String get settingsFaster => 'أسرع';

  @override
  String get settingsLower => 'أخفض';

  @override
  String get settingsHigher => 'أعلى';

  @override
  String get settingsTryVoice => 'جرّب';

  @override
  String get settingsMicTitle => 'الميكروفون';

  @override
  String get settingsMicAllowed =>
      'مسموح — يمكنك الإجابة على مهام التحدث بصوتك.';

  @override
  String get settingsMicNotYet =>
      'غير مسموح بعد — تحتاجه للإجابة على مهام التحدث بصوتك.';

  @override
  String get settingsMicDenied =>
      'غير مسموح — تحتاجه للإجابة على مهام التحدث بصوتك.';

  @override
  String get settingsMicBlocked =>
      'محظور — فعّله من إعدادات هاتفك لتطبيق Mohingo.';

  @override
  String get settingsMicAllow => 'اسمح';

  @override
  String get settingsSttTitle => 'التعرف على الكلام';

  @override
  String get settingsSttOn => 'متاح للإنجليزية على هذا الجهاز.';

  @override
  String get settingsSttOff =>
      'غير متاح على هذا الجهاز. يمكنك كتابة إجابات التحدث بدلاً من ذلك.';

  @override
  String get settingsDataOverline => 'بياناتك';

  @override
  String get settingsOfflineTitle => 'تبقى على هذا الجهاز';

  @override
  String get settingsOfflineBody =>
      'يعمل دون إنترنت بالكامل. لا يُرفع شيء ولا يوجد حساب.';

  @override
  String get settingsResetProgressBody =>
      'امسح كل الدروس ونتائج الاختبارات والمراجعات على هذا الجهاز.';

  @override
  String settingsVersion(String version) {
    return 'Mohingo · الإصدار $version';
  }

  @override
  String get settingsNameEmpty => 'أضف اسمك';

  @override
  String get settingsProfileMeta => 'تتعلّم الإنجليزية · A1';

  @override
  String get settingsEdit => 'تعديل';

  @override
  String get settingsInterfaceLanguageTitle => 'لغة التطبيق';

  @override
  String get settingsThemeModeTitle => 'السمة';

  @override
  String get settingsThemeModeLight => 'فاتح';

  @override
  String get settingsThemeModeDark => 'داكن';

  @override
  String get settingsThemeModeSystem => 'تلقائي';

  @override
  String get settingsColorThemeTitle => 'اللون';

  @override
  String get settingsNameTitle => 'اسمك';

  @override
  String get settingsNameHint =>
      'يُستخدم في الصفحة الرئيسية وفي بعض تمارين التهجئة.';

  @override
  String get settingsNameSaveButton => 'حفظ';

  @override
  String get settingsNameSaved => 'تم حفظ الاسم';

  @override
  String get settingsResetProgressTitle => 'إعادة تعيين التقدّم';

  @override
  String get settingsResetProgressConfirmTitle => 'إعادة تعيين كل التقدّم؟';

  @override
  String get settingsResetProgressConfirmBody =>
      'سيُمسح كل تقدّمك في الدروس والوحدات ونتائج الاختبارات وجداول المراجعة والكلمات المحفوظة على هذا الجهاز. لا يمكن التراجع عن ذلك.';

  @override
  String get settingsResetProgressConfirmAction => 'إعادة التعيين';

  @override
  String get settingsResetProgressCancel => 'إلغاء';

  @override
  String get settingsResetProgressDone => 'تمت إعادة تعيين التقدّم.';

  @override
  String get settingsBackupTitle => 'النسخ الاحتياطي والمزامنة';

  @override
  String get settingsBackupBody =>
      'إعادة تثبيت التطبيق أو تغيير الهاتف يبدأ من جديد حالياً.';
}
