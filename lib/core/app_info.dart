import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The installed app's name, version and build number, read from the
/// platform package (Android's versionName/versionCode, iOS's
/// CFBundleShortVersionString/CFBundleVersion), which the build takes from
/// `version:` in pubspec.yaml. The one source of the version the app shows:
/// there is no second copy to keep in step.
final appPackageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);
