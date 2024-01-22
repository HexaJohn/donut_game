import 'package:donut_game/src/utils/donut_socket.dart';
import 'package:websocket_universal/websocket_universal.dart';

Future handshake() async {
  await DonutSocket.connect();
  await Future<void>.delayed(const Duration(seconds: 3));
  // Disconnecting from server:
  await DonutSocket.disconnect('manual disconnect');
}
