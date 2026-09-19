import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/core/app_version.dart';

void main() {
  test('kAppVersion matches the version in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*([0-9.]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(kAppVersion, version);
  });
}
