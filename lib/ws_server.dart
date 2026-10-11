import 'dart:convert';
import 'dart:io';

import 'package:donut_game/progression/emblem.dart';
import 'package:donut_game/data/settings.dart';
import 'package:donut_game/net/table_host.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/ui/server_home/server_home.dart';
import 'package:donut_game/ui/widget/title_bar.dart';
import 'package:flutter/material.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:shelf_static/shelf_static.dart' as shelf_static;
import 'package:window_manager/window_manager.dart';

Game serverGame = Game();

/// Seats players and applies their moves; shared with Game Center matches.
final TableHost tableHost = TableHost(checkSecrets: true);

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isDesktop) {
    // Same native runner as the game, so give this window its own name
    await windowManager.ensureInitialized();
    await windowManager.setTitle('Donut Server');
  }
  // Settings are shared with the game app on this machine
  await Settings.instance.load();
  serverGame.addBot();
  serverGame.addBot();
  // DONUT_PORT (environment variable or --dart-define) runs a second server
  // alongside the usual one, e.g. for testing without touching a live game
  const definedPort = String.fromEnvironment('DONUT_PORT');
  final port = int.tryParse(Platform.environment['DONUT_PORT'] ?? definedPort) ?? 27960;

  var ws = await HttpServer.bind(InternetAddress.loopbackIPv4, port + 1);

  // See https://pub.dev/documentation/shelf/latest/shelf/Cascade-class.html
  var cascade = Cascade();
  // Serve the web build if there is one, then fall through to the API router
  if (Directory(_webBuildPath).existsSync()) {
    cascade = cascade.add(
        shelf_static.createStaticHandler(_webBuildPath, defaultDocument: 'index.html', serveFilesOutsidePath: true));
  }
  cascade = cascade.add(_router.call);

  // See https://pub.dev/documentation/shelf/latest/shelf_io/serve.html
  final server = await shelf_io.serve(
    // See https://pub.dev/documentation/shelf/latest/shelf/logRequests.html
    logRequests(
      logger: (message, isError) {
        serverGame.log.putIfAbsent(message, () => isError);
        serverGame.flipFlop.notifyListeners();
      },
    )
        // See https://pub.dev/documentation/shelf/latest/shelf/MiddlewareExtensions/addHandler.html
        .addHandler(cascade.handler),
    InternetAddress.anyIPv4, // Allows external connections
    port,
  );

  runApp(const ServerHome());

  await for (HttpRequest request in ws) {
    if (request.uri.path == '/ws') {
      // Upgrade an HttpRequest to a WebSocket connection
      var socket = await WebSocketTransformer.upgrade(request);

      // Listen for incoming messages from the client
      socket.listen((message) {
        socket.add('{"topic": "generic", "error": "", "data": "Hello, world!"}');
        final topic = jsonDecode(message)['topic'];
        final Map<String, dynamic> data = jsonDecode(message);

        switch (topic) {
          case 'update':
            if (serverGame.playerDB.length > 2 && serverGame.state.value == GameState.waitingForPlayers) {
              serverGame.state.value = GameState.waitingToDeal;
            }
            // game.deal();
            var scores = [
              {'players': _playersToJson(), 'game': _gameToJson()}
            ];

            var jsonText = jsonEncode(scores);
            // print(jsonText);
            socket.add(jsonText);
            break;

          case 'connect':
            final GamePlayer player = GamePlayer.fromJson(data);
            serverGame.addLocalPlayer(player);
            if (serverGame.playerDB.length == 2) {
              serverGame.protectedActive = 1;
              serverGame.protectedDealer = 0;
              serverGame.state.value = GameState.waitingToDeal;
            }
            print(player.name);
            socket.add('{"topic": "generic", "error": "", "data": "Welcome ${player.name}"}');
            break;
        }
      });
    } else {
      request.response.statusCode = HttpStatus.forbidden;
      request.response.close();
    }
  }
}

class DonutConnection {
  String username;
  String id;
  DonutConnection(this.username, this.id);

  String toJson() {
    return jsonEncode({'username': username, 'id': id});
  }
}

// Serve files from the file system.
const _webBuildPath = 'build/web';

// Router instance to handler requests.
final _router = shelf_router.Router()
  ..get('/helloworld', _helloWorldHandler)
  ..post('/connect', _newConnectionHandler)
  ..post('/update', _activeConnection)
  ..post('/vote', (Request request) => _act(request, 'vote'))
  ..post('/swap', (Request request) => _act(request, 'swap'))
  ..post('/play', (Request request) => _act(request, 'play'))
  ..post('/swapvote', (Request request) => _act(request, 'swapvote'))
  ..post('/fold', (Request request) => _act(request, 'fold'))
  ..post('/chat', (Request request) => _act(request, 'chat'))
  ..post('/shoot', (Request request) => _act(request, 'shoot'))
  ..post('/draw', (Request request) => _act(request, 'draw'))
  ..post('/flashbang', (Request request) => _act(request, 'flashbang'))
  ..post('/newMatch', (Request request) => _act(request, 'newMatch'))
  ..get(
    '/time',
    (request) => Response.ok(DateTime.now().toUtc().toIso8601String()),
  )
  ..get('/sum/<a|[0-9]+>/<b|[0-9]+>', _sumHandler);

Response _helloWorldHandler(Request request) => Response.ok('Hello, World!');

Future<Response> _newConnectionHandler(Request request) async {
  final playerJson = jsonDecode(await request.readAsString());
  final id = '${playerJson['id']}${playerJson['username']}';
  final result = tableHost.join(id, '${playerJson['username']}',
      back: playerJson['back'] is String ? playerJson['back'] : null,
      face: playerJson['face'] is String ? playerJson['face'] : null,
      emblem: Emblem.tryParse(playerJson['emblem']),
      secret: playerJson['secret'] is String ? playerJson['secret'] : null);
  if (!result.ok) return _respond(result);
  return Response.ok(jsonEncode({'topic': 'generic', 'error': '', 'data': 'Welcome, ${playerJson['username']}'}));
}

Response _respond(ActionResult result) => result.ok ? Response.ok('') : Response(result.status, body: result.message);

/// Applies one player's move from a request body {"id", ...}.
Future<Response> _act(Request request, String action) async {
  try {
    final body = Map<String, dynamic>.from(jsonDecode(await request.readAsString()));
    return _respond(tableHost.act('${body['id']}', action, body));
  } catch (e) {
    return Response.badRequest();
  }
}

Map<String, dynamic> _gameToJson({int? inkRevision}) => tableHost.gameJson(inkRevision: inkRevision);

/// The table as one player may see it: {"id", "secret", "ink_rev"}. Without a
/// valid secret it's a spectator's view, with every hand face down. A POST,
/// so the secret stays out of the request log.
Future<Response> _activeConnection(Request request) async {
  if (serverGame.playerDB.length > 2 && serverGame.state.value == GameState.waitingForPlayers) {
    serverGame.state.value = GameState.waitingToDeal;
  }
  Map<String, dynamic> body;
  try {
    body = Map<String, dynamic>.from(jsonDecode(await request.readAsString()));
  } catch (e) {
    body = {};
  }
  final id = '${body['id']}';
  final viewer = tableHost.verify(id, body['secret']) ? id : null;
  var scores = [
    {
      'players': tableHost.playersJson(viewer: viewer),
      'game': _gameToJson(inkRevision: body['ink_rev'] is int ? body['ink_rev'] : null),
    }
  ];

  var jsonText = jsonEncode(scores);
  return Response.ok(jsonText);
}

List<Map<String, dynamic>> _playersToJson() => tableHost.playersJson();

Response _sumHandler(request, String a, String b) {
  final aNum = int.parse(a);
  final bNum = int.parse(b);
  return Response.ok(
    const JsonEncoder.withIndent(' ').convert({'a': aNum, 'b': bNum, 'sum': aNum + bNum}),
    headers: {
      'content-type': 'application/json',
      'Cache-Control': 'public, max-age=604800',
    },
  );
}
