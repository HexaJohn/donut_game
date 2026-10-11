import 'package:web_socket_channel/web_socket_channel.dart';

/// Browsers ping on their own.
WebSocketChannel openPartySocket(Uri url) => WebSocketChannel.connect(url);
