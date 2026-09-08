import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mohingo/features/activity_engine/data/device_connectivity_service.dart';

void main() {
  group('isOnlineFromResults', () {
    test('a single non-none result is online', () {
      expect(isOnlineFromResults([ConnectivityResult.wifi]), isTrue);
    });

    test('a list of only none is offline', () {
      expect(isOnlineFromResults([ConnectivityResult.none]), isFalse);
    });

    test('an empty list is offline', () {
      expect(isOnlineFromResults(const []), isFalse);
    });

    test('mixed none and a real connection is online', () {
      expect(
        isOnlineFromResults([
          ConnectivityResult.none,
          ConnectivityResult.mobile,
        ]),
        isTrue,
      );
    });
  });
}
