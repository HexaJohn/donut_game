import 'package:donut_game/data/remote/donut_socket.dart';

Future handshake() async {
  await DonutSocket.connect();
  await Future<void>.delayed(const Duration(seconds: 3));
  // Disconnecting from server:
  await DonutSocket.disconnect('manual disconnect');
}
