import 'package:donut_game/data/remote/donut_socket.dart';

Stream<String> handshake() async* {
  print('starting handshake');
  final connection = DonutSocket.connect();
  final connected = await connection.firstWhere((event) => event.contains('Welcome'));
  yield connected;
  print('connection finished');
  await Future<void>.delayed(const Duration(seconds: 3));
  // Disconnecting from server:
  await DonutSocket.disconnect('manual disconnect');
  yield 'Disconnected';
  print('handshake done');
  return;
}
