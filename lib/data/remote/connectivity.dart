import 'package:donut_game/data/remote/connectivity_io.dart'
    if (dart.library.js_interop) 'package:donut_game/data/remote/connectivity_web.dart' as platform;
import 'package:http/http.dart' as http;

class NetworkStatus {
  const NetworkStatus({this.internet, this.serverReachable = false});

  /// Null when it could not be determined (web).
  final bool? internet;
  final bool serverReachable;
}

/// Whether the device can reach the internet. Null if unknown.
Future<bool?> checkInternet() => platform.checkInternet();

/// Whether a Donut server answers at [host]:[port].
Future<bool> checkServer(String host, int port) async {
  try {
    final response = await http
        .get(Uri(scheme: 'http', host: host, port: port, path: '/helloworld'))
        .timeout(const Duration(seconds: 2));
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}
