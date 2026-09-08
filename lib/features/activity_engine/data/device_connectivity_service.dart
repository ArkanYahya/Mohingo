import 'package:connectivity_plus/connectivity_plus.dart';

import '../domain/evaluation/connectivity_service.dart';

/// Online unless every reported connection type is [ConnectivityResult.none]
/// — a device can report more than one simultaneous connection (e.g. wifi
/// and a VPN), so this only needs one of them to be real.
bool isOnlineFromResults(List<ConnectivityResult> results) =>
    results.any((r) => r != ConnectivityResult.none);

class DeviceConnectivityService implements ConnectivityService {
  DeviceConnectivityService() : _connectivity = Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return isOnlineFromResults(results);
  }

  @override
  Stream<bool> get onlineChanges =>
      _connectivity.onConnectivityChanged.map(isOnlineFromResults);
}
