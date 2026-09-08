import 'dart:async';

import 'package:mohingo/features/activity_engine/domain/evaluation/connectivity_service.dart';

/// A fake [ConnectivityService] with a test-controlled online/offline state
/// and a manually-fireable change stream — standing in for
/// `connectivity_plus`'s platform channel, which can't be exercised in a
/// `flutter test` environment. See docs/TESTING.md.
class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService({this._online = true});

  bool _online;
  final _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> isOnline() async => _online;

  @override
  Stream<bool> get onlineChanges => _controller.stream;

  /// Test hook: simulates the device's connectivity state changing.
  void setOnline(bool online) {
    _online = online;
    _controller.add(online);
  }
}
