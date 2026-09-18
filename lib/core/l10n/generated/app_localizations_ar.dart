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
  String get lessonReviewPracticeAgain => 'تدرّب مرة أخرى';

  @override
  String get lessonReviewNotAnswered => 'لم تتم الإجابة';

  @override
  String get vocabularyStatDue => 'مستحقة';

  @override
  String get vocabularyStatLearning => 'قيد التعلم';

  @override
  String get vocabularySavedWordsTitle => 'الكلمات المحفوظة';

  @override
  String get vocabularyTabWords => 'كلمات';

  @override
  String get vocabularyTabChunks => 'عبارات';

  @override
  String get vocabularySearchHint => 'ابحث بالإنجليزية أو العربية';

  @override
  String get vocabularyFavoritesOnly => 'المفضلة فقط';

  @override
  String get vocabularyProductiveOnly => 'إنتاجية فقط';

  @override
  String get vocabularyEmptyResults => 'لا توجد كلمات مطابقة لبحثك.';

  @override
  String wordDetailIntroducedIn(String unitTitle) {
    return 'قُدّمت في $unitTitle';
  }

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
  String get reviewConfidenceSaved => 'تم الحفظ';

  @override
  String get grammarDetailForm => 'الصيغة';

  @override
  String get grammarDetailLinkedLessons => 'تُمارس في';

  @override
  String get grammarMarkReviewed => 'ضعها كمُراجَعة';

  @override
  String get grammarReviewed => 'تمت مراجعتها';

  @override
  String get grammarQuickPractice => 'تمرين سريع';

  @override
  String get grammarNoLinkedPractice => 'لا يوجد تمرين مرتبط بعد.';

  @override
  String get quickPracticeDone => 'تم';

  @override
  String get reviewSectionDue => 'بحاجة للمراجعة';

  @override
  String get reviewSectionFavorites => 'المفضلة';

  @override
  String get reviewSectionWeakObjectives => 'بحاجة لمزيد من التدريب';

  @override
  String get reviewNothingDue => 'لا يوجد شيء بحاجة للمراجعة الآن.';

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
  String get settingsSpeechTitle => 'الصوت';

  @override
  String get settingsSpeechRate => 'سرعة الكلام';

  @override
  String get settingsSpeechPitch => 'حدة الصوت';

  @override
  String get settingsMicPermissionGranted => 'الوصول إلى الميكروفون: مسموح';

  @override
  String get settingsMicPermissionDenied => 'الوصول إلى الميكروفون: غير مسموح';

  @override
  String get settingsMicPermissionPermanentlyDenied =>
      'الوصول إلى الميكروفون: محظور — فعّله من إعدادات الجهاز';

  @override
  String get settingsMicPermissionNotDetermined =>
      'الوصول إلى الميكروفون: لم يُطلب بعد';

  @override
  String get settingsSttAvailable =>
      'التعرف على الكلام على الجهاز: متاح للإنجليزية';

  @override
  String get settingsSttUnavailable =>
      'التعرف على الكلام على الجهاز: غير متاح على هذا الجهاز — يمكنك كتابة إجابات مهام التحدث';

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
  String get testsHomePlacementTitle => 'اختبار تحديد المستوى لـ A1';

  @override
  String get testsHomePlacementSubtitle =>
      'لست متأكداً من أين تبدأ؟ اكتشف أفضل نقطة بداية لك في A1.';

  @override
  String get testsHomeFinalMissionTitle => 'المهمة الختامية لمستوى A1';

  @override
  String get testsHomeFinalMissionSubtitle =>
      'مهمة ختامية قائمة على سيناريو تجمع كل ما تعلمته.';

  @override
  String get testsHomeFinalAssessmentTitle => 'التقييم الختامي لمستوى A1';

  @override
  String get testsHomeFinalAssessmentSubtitle =>
      'اختبار ختامي قصير يغطي كل مهارة على حدة — لا تُخفي درجة إجمالية أي ضعف في مهارة بعينها.';

  @override
  String get testsHomeUnitChecksTitle => 'تقييم إتقان الوحدات';

  @override
  String get testsHomeUnitChecksSubtitle =>
      'تابع تقدّم كل وحدة من تبويب تعلّم.';

  @override
  String get testsHomeFutureLevelsTitle => 'تحديد المستوى لما بعد A1';

  @override
  String get testsHomeNotYetTaken => 'لم تبدأ المحاولة بعد';

  @override
  String get testsHomeInProgress => 'قيد التقدّم';

  @override
  String testsHomeCompletedOn(String date) {
    return 'اكتملت المحاولة في $date';
  }

  @override
  String get placementIntroTitle => 'اختبار تحديد المستوى لـ A1';

  @override
  String get placementIntroBody =>
      'بضعة أسئلة سريعة عبر وحدات A1، من الأسهل إلى الأصعب. سنتوقف بمجرد أن نجد نقطة بدايتك — يُنهي معظم المستخدمين الاختبار خلال دقائق.';

  @override
  String get placementStartButton => 'ابدأ';

  @override
  String get placementConfidenceQuestion =>
      'بشكل عام، كم شعرت بالثقة في إجاباتك؟';

  @override
  String get placementConfidenceLow => 'ليست كبيرة';

  @override
  String get placementConfidenceHigh => 'ثقة كبيرة';

  @override
  String get placementResultTitle => 'نتيجتك';

  @override
  String get placementOutcomeStartWithEssentials =>
      'ابدأ بأساسيات اللغة الإنجليزية (الوحدة 0) — ستمنحك القاعدة التي يُبنى عليها بقية مستوى A1.';

  @override
  String get placementOutcomeStartA1FromU1 =>
      'أساسياتك جيدة — ابدأ مستوى A1 من الوحدة الأولى.';

  @override
  String placementOutcomeStartFromUnit(String unitTitle) {
    return 'أنت متقدّم في الوحدات الأولى — ابدأ من $unitTitle.';
  }

  @override
  String get placementOutcomeMastered =>
      'يبدو أنك أتقنت مستوى A1 بالكامل — عمل رائع! تحديد المستويات الأعلى غير متاح بعد، لكنه قادم.';

  @override
  String get placementResultGoToUnit => 'اذهب إلى هذه الوحدة';

  @override
  String get placementResultDone => 'تم';

  @override
  String get finalMissionStartButton => 'ابدأ';

  @override
  String get finalMissionResultTitle => 'نتيجة المهمة';

  @override
  String get finalMissionPassed =>
      'أكملت المهمة — كل مهارة مطلوبة تحققت بنجاح.';

  @override
  String get finalMissionNotYetTitle => 'لم تصل بعد';

  @override
  String get finalMissionDone => 'تم';

  @override
  String get finalAssessmentIntroBody =>
      'اختبار ختامي قصير يغطي كل مهارات مستوى A1. تُقيَّم كل مهارة على حدة — لا يعوّض تفوقك في مهارة عن ضعفك في أخرى.';

  @override
  String get finalAssessmentStartButton => 'ابدأ';

  @override
  String get finalAssessmentResultTitle => 'نتيجة التقييم';

  @override
  String get finalAssessmentOverallPassed =>
      'كل مهارة مطلوبة حققت الحد المطلوب لمستوى A1.';

  @override
  String get finalAssessmentOverallNotYet =>
      'لم تحقق كل المهارات المطلوبة الحد المطلوب بعد — راجع التفاصيل أدناه.';

  @override
  String get finalAssessmentSkillPassed => 'تم اجتيازها';

  @override
  String get finalAssessmentSkillNotMet => 'لم تُحقَّق بعد';

  @override
  String get finalAssessmentSkillPendingReview => 'قيد المراجعة';

  @override
  String get finalAssessmentDone => 'تم';

  @override
  String finalAssessmentSectionScore(int percent) {
    return '$percent٪';
  }

  @override
  String get finalAssessmentWhatsNext => 'واصل التدرّب';

  @override
  String get contentNotFoundTitle => 'لم يتم العثور على المحتوى';

  @override
  String get grammarSectionTitle => 'القواعد';

  @override
  String get grammarFilterAllUnits => 'الكل';

  @override
  String get vocabularyReceptiveLabel => 'استيعابية';

  @override
  String get vocabularyProductiveLabel => 'إنتاجية';

  @override
  String get favoriteAddTooltip => 'أضف إلى المفضلة';

  @override
  String get favoriteRemoveTooltip => 'أزل من المفضلة';

  @override
  String get settingsInterfaceLanguageTitle => 'لغة الواجهة';

  @override
  String get settingsThemeModeTitle => 'المظهر';

  @override
  String get settingsThemeModeLight => 'فاتح';

  @override
  String get settingsThemeModeDark => 'داكن';

  @override
  String get settingsThemeModeSystem => 'حسب النظام';

  @override
  String get settingsColorThemeTitle => 'لون الواجهة';

  @override
  String get settingsNameTitle => 'اسمك';

  @override
  String get settingsNameHint => 'يُستخدم في بعض تمارين التهجئة';

  @override
  String get settingsNameSaveButton => 'حفظ';

  @override
  String get settingsNameSaved => 'تم حفظ الاسم';

  @override
  String get settingsAboutTitle => 'حول التطبيق';

  @override
  String get settingsAboutBody =>
      'يعمل Mohingo دون اتصال بالإنترنت بالكامل — تبقى دروسك وتقدّمك وأي إجابات صوتية على هذا الجهاز فقط. لا شيء يُرفَع إلى أي مكان، ولا حاجة لإنشاء حساب.';

  @override
  String get settingsResetProgressTitle => 'إعادة تعيين التقدّم';

  @override
  String get settingsResetProgressButton => 'إعادة تعيين التقدّم';

  @override
  String get settingsResetProgressConfirmTitle => 'إعادة تعيين كل التقدّم؟';

  @override
  String get settingsResetProgressConfirmBody =>
      'سيؤدي هذا إلى محو تقدّمك في جميع الوحدات، وأدلة الإتقان، ونتائج اختبار تحديد المستوى والمهمة والتقييم الختاميين، والكلمات والقواعد المفضّلة على هذا الجهاز. لا يمكن التراجع عن هذا الإجراء.';

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
      'قريباً. حالياً يبقى تقدّمك على هذا الجهاز فقط — إعادة تثبيت التطبيق أو الانتقال لجهاز آخر يبدأ من جديد.';
}
