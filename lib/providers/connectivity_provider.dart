import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `true` when the device has any network route. Assumes online when the
/// platform check itself fails (avoids false offline banners in tests).
final StreamProvider<bool> connectivityProvider =
    StreamProvider<bool>((Ref ref) async* {
  final Connectivity connectivity = Connectivity();
  List<ConnectivityResult> current;
  try {
    current = await connectivity.checkConnectivity();
  } catch (_) {
    current = const <ConnectivityResult>[ConnectivityResult.wifi];
  }
  bool online(List<ConnectivityResult> results) =>
      results.any((ConnectivityResult r) => r != ConnectivityResult.none);
  yield online(current);
  await for (final List<ConnectivityResult> results
      in connectivity.onConnectivityChanged) {
    yield online(results);
  }
});
