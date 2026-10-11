import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Pings under the hood, so a connection that died quietly (the phone slept,
/// the network changed) is noticed and closed instead of hanging forever.
WebSocketChannel openPartySocket(Uri url) => IOWebSocketChannel.connect(url, pingInterval: const Duration(seconds: 20));
