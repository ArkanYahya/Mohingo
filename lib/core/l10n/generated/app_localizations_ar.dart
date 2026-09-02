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
}
