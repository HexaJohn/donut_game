import 'dart:async';

import 'package:donut_game/ws_server.dart';
import 'package:websocket_universal/websocket_universal.dart';
import 'dart:developer' as developer;

class DonutSocket {
  /// Postman echo ws server (you can use your own server URI)
  /// 'wss://ws.postman-echo.com/raw'
  /// For local server it could look like 'ws://127.0.0.1:42627/websocket'
  static const websocketConnectionUri = 'ws://127.0.0.1:27961/ws';
  static const textMessageToServer = 'Hello server!';
  static const connectionOptions = SocketConnectionOptions(
    pingIntervalMs: 3000, // send Ping message every 3000 ms
    timeoutConnectionMs: 4000, // connection fail timeout after 4000 ms
    /// see ping/pong messages in [logEventStream] stream
    skipPingMessages: true,

    /// Set this attribute to `true` if do not need any ping/pong
    /// messages and ping measurement. Default is `false`
    pingRestrictionForce: true,
  );

  /// Example with simple text messages exchanges with server
  /// (not recommended for applications)
  /// [<String, String>] generic types mean that we receive [String] messages
  /// after deserialization and send [String] messages to server.
  static final IMessageProcessor<String, String> textSocketProcessor = SocketSimpleTextProcessor();
  static final textSocketHandler = IWebSocketHandler<String, String>.createClient(
    websocketConnectionUri, // Postman echo ws server
    textSocketProcessor,
    connectionOptions: connectionOptions,
  );

  static Future update() async {
    DonutSocket.textSocketHandler.sendMessage('update');
  }

  static final controller = StreamController<String>.broadcast();

  static Stream<String> connect() async* {
    /// Complex example:
    /// Example using [ISocketMessage] and [IMessageToServer]
    /// (recommended for applications, server must deserialize
    /// [ISocketMessage] serialized string to [ISocketMessage] object)
    final IMessageProcessor<ISocketMessage<Object?>, IMessageToServer> messageProcessor = SocketMessageProcessor();
    final socketHandler = IWebSocketHandler<ISocketMessage<Object?>, IMessageToServer>.createClient(
      websocketConnectionUri,
      messageProcessor,
      connectionOptions: connectionOptions,
    );

    // Listening to debug events inside webSocket
    // socketHandler.logEventStream.listen((debugEvent) {
    //   developer.log('> debug event: ${debugEvent.socketLogEventType}'
    //       ' ping=${debugEvent.pingMs} ms. Debug message=${debugEvent.message}');
    // });

    controller.addStream(socketHandler.logEventStream.map((event) {
      // print('event.message: ${event.data}');
      return event.data ?? '';
    }));

    //  socketHandler.logEventStream.listen((event) {}).onData((data) {
    //   developer.log('> debug event: ${data.socketLogEventType}'
    //       ' ping=${data.pingMs} ms. Debug message=${data.message}');
    //   yield data.message;
    // });

    // Listening to webSocket status changes
    socketHandler.socketStateStream.listen((stateEvent) {
      developer.log('> status changed to ${stateEvent.status}');
    });

    // [IMessageToServer] also implements [ISocketMessage] interface.
    // So basically we are sending and receiving equally-typed messages.
    const messageTypeStr = '[ISocketMessage]';
    // Listening to server responses:
    // socketHandler.incomingMessagesStream.listen((inMsg) {
    //   developer.log('> webSocket  got $messageTypeStr: $inMsg');
    // });

    socketHandler.incomingMessagesStream.listen((inMsg) {
      developer.log('> webSocket recieved: $messageTypeStr: $inMsg');
    });

    // Listening to outgoing messages:
    socketHandler.outgoingMessagesStream.listen((inMsg) {
      developer.log('> webSocket sent: $messageTypeStr: $inMsg');
    });

    // Connecting to server:
    final isConnected = await socketHandler.connect();

    if (!isConnected) {
      developer.log('Connection to [$websocketConnectionUri] failed for some reason!');
      return;
    }

    // Sending message with routing path 'test' and simple JSON payload:
    final outMsg = MessageToServer.onlyHost(
      host: 'connect',
      data: '{"payload": "${DonutConnection('John', 'ABC 123').toJson()}}"}',
      error: null,
    );
    // IMessageToServer outMsg = MessageToServer.fromJson(DonutConnection('John', 'ABC 123').toJson());
    socketHandler.sendMessage(outMsg);
    yield* DonutSocket.controller.stream;
  }

  static Future disconnect(String s) async {
    await textSocketHandler.disconnect('manual disconnect');
    // Disposing webSocket:
    // DonutSocket.textSocketHandler.close();
  }
}
