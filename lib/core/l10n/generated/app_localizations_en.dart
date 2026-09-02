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
}
