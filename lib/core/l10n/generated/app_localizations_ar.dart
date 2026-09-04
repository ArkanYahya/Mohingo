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
  String get activitySpeechUnavailableUseWriting =>
      'التحدث غير متاح على هذا الجهاز حالياً — اكتب إجابتك بدلاً من ذلك.';

  @override
  String activityWordGuide(int min, int max) {
    return 'من $min إلى $max كلمة تقريباً';
  }

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
  String get unitPathYouAreHere => 'أنت هنا';

  @override
  String get comingSoonLevelBody =>
      'هذا المستوى غير متاح بعد. المستوى A1 جاهز الآن — ابدأ منه.';

  @override
  String get continueLearningTitle => 'أكمل التعلّم';

  @override
  String get continueLearningCta => 'متابعة';

  @override
  String get homeAllUnitsMastered => 'أتقنت جميع وحدات A1 حتى الآن!';

  @override
  String homeStreakTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'تتابع $days يوم',
      many: 'تتابع $days يوماً',
      few: 'تتابع $days أيام',
      two: 'تتابع يومين',
      one: 'تتابع يوم واحد',
      zero: 'لا يوجد تتابع بعد',
    );
    return '$_temp0';
  }

  @override
  String get homeStreakEncouragement => 'واصل اليوم أيضاً';

  @override
  String get homeLevelProgressTitle => 'تقدّم A1';

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
  String get lessonCompleteTitle => 'اكتمل الدرس';

  @override
  String get lessonCompleteBody =>
      'أحسنت. يمكنك المتابعة أو العودة إلى هذه الوحدة في أي وقت.';

  @override
  String get lessonCompleteDone => 'تم';

  @override
  String lessonCompleteTally(int correct, int total) {
    return '$correct من $total إجابة صحيحة';
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
  String get lessonPlayerNext => 'التالي';

  @override
  String lessonPlayerProgress(int current, int total) {
    return '$current من $total';
  }

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
