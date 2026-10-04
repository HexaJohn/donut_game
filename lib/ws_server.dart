import 'dart:convert';
import 'dart:io';

import 'package:donut_game/res/resources.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
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

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isDesktop) {
    // Same native runner as the game, so give this window its own name
    await windowManager.ensureInitialized();
    await windowManager.setTitle('Donut Server');
  }
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
  ..get('/update', _activeConnection)
  ..post('/vote', _voteResponse)
  ..post('/swap', _executeSwap)
  ..post('/play', _executePlay)
  ..post('/swapvote', _finalizeSwap)
  ..post('/fold', _executeFold)
  ..post('/chat', _executeChat)
  ..post('/shoot', _executeShoot)
  ..post('/draw', _executeDraw)
  ..post('/flashbang', _executeFlashbang)
  ..get('/reset', _executeReset)
  ..get(
    '/time',
    (request) => Response.ok(DateTime.now().toUtc().toIso8601String()),
  )
  ..get('/sum/<a|[0-9]+>/<b|[0-9]+>', _sumHandler);

Response _helloWorldHandler(Request request) => Response.ok('Hello, World!');

Future<Response> _newConnectionHandler(Request request) async {
  String playerData = await request.readAsString();
  final playerJson = jsonDecode(playerData);
  final player = GamePlayer('${playerJson['username']}', 0, true);
  player.id = playerJson['id'] + playerJson['username'];
  // Reconnecting keeps the existing seat
  final rejoining = serverGame.playerDB.containsKey(player.id);
  if (!rejoining) {
    serverGame.addLocalPlayer(player);
    serverGame.say('', '${player.name} joined the game.', system: true);
  }
  if (serverGame.playerDB.length == 2) {
    serverGame.protectedActive = 1;
    serverGame.protectedDealer = 0;
    serverGame.state.value = GameState.waitingToDeal;
  }

  return Response.ok('{"topic": "generic", "error": "", "data": "Welcome, ${player.name}"}');
}

/// [inkRevision] is the drawing the client already has; the strokes are only
/// sent when the table has changed since.
Map<String, dynamic> _gameToJson({int? inkRevision}) {
  return {
    'state': gameStateToString[serverGame.state.value]!,
    'table': GameCard.jsonArray(serverGame.table.cards.value),
    'discard': GameCard.jsonArray(serverGame.discard.cards.value),
    'deck': GameCard.jsonArray(serverGame.deck.contents),
    'active': serverGame.protectedActive,
    'dealer': serverGame.protectedDealer,
    'trump': suitToString[serverGame.trumpSuit.value],
    'leading_card': serverGame.leadingCard?.toJson(),
    'sudden_death': serverGame.suddenDeath.map((e) => e.name).toList(),
    'champion': serverGame.champion.value?.name,
    'elapsed_ms': serverGame.matchElapsed.inMilliseconds,
    'clock_running': serverGame.matchStarted != null && serverGame.matchEnded == null,
    'hand': serverGame.handNumber,
    'trick_serial': serverGame.trickSerial,
    'trick_winner': serverGame.lastTrickWinner?.name,
    'chat': serverGame.chat.value.map((e) => e.toJson()).toList(),
    'holes': serverGame.holes.value.map((e) => e.toJson()).toList(),
    'spins': serverGame.spins.value,
    'ink_rev': serverGame.inkRevision,
    'flash': {
      'serial': serverGame.flashSerial,
      'x': serverGame.flashAt.dx,
      'y': serverGame.flashAt.dy,
      'by': serverGame.flashBy,
      'ready': serverGame.flashReady,
    },
    if (inkRevision != serverGame.inkRevision) 'ink': serverGame.ink.value.map((e) => e.toJson()).toList(),
    'now_ms': DateTime.now().millisecondsSinceEpoch,
  };
}

Future<Response> _activeConnection(Request request) async {
  if (serverGame.playerDB.length > 2 && serverGame.state.value == GameState.waitingForPlayers) {
    serverGame.state.value = GameState.waitingToDeal;
  }
  var scores = [
    {
      'players': _playersToJson(),
      'game': _gameToJson(inkRevision: int.tryParse(request.url.queryParameters['ink_rev'] ?? ''))
    }
  ];

  var jsonText = jsonEncode(scores);
  return Response.ok(jsonText);
}

Future<Response> _voteResponse(Request request) async {
  try {
    String playerData = await request.readAsString();
    final playerJson = jsonDecode(playerData);
    final player = serverGame.playerDB[playerJson['id']]!;
    player.voteToDeal = true;
    evaluateDeal();
    return Response.ok('');
  } catch (e) {
    return Response.badRequest();
  }
}

List<Map<String, dynamic>> _playersToJson() {
  List<Map<String, dynamic>> compound = [];
  for (var player in serverGame.players) {
    if (!player.human) {
      player.voteToDeal = true;
    }
    compound.add({
      'username': player.name,
      'id': player.id + player.name,
      'human': player.human.toString(),
      'voteDeal': player.voteToDeal.toString(),
      'cards': player.hand.toJsonArray(),
      'swaps': player.swaps.value,
      'notReady': player.notReady.toString(),
      'score': player.score.value,
      'donuts': player.donuts.value,
      'winner': player.winner.value,
      'folds': player.folds,
      'tricks': player.tricks,
      'skip': player.skip.toString(),
      'awaitingCard': player.awaitingCard.toString()
    });
  }
  return compound;
}

Future<Response> _executeSwap(Request request) async {
  String swapData = await request.readAsString();
  final swapJson = jsonDecode(swapData);
  String player = swapJson['id'];
  int cardIndex = swapJson['swap'];
  var target = serverGame.playerDB[player]!.hand.cards.value[cardIndex].state;
  if (target == CardState.held && serverGame.playerDB[player]!.swaps.value > 0) {
    serverGame.playerDB[player]!.hand.cards.value[cardIndex].state = CardState.swap;
    serverGame.playerDB[player]!.swaps.value--;

    return Response.ok('');
  }

  if (target == CardState.swap) {
    serverGame.playerDB[player]!.hand.cards.value[cardIndex].state = CardState.held;
    serverGame.playerDB[player]!.swaps.value++;

    return Response.ok('');
  }
  return Response.badRequest();
}

Future<Response> _executeReset(Request request) async {
  Game.reset();
  return Response.ok('');
}

/// Only accepted while the game is waiting for this player's card. Anything
/// earlier (say, during the pause after winning a trick) would be wiped when
/// the turn really starts, so it's refused and the client un-marks the card.
Future<Response> _executePlay(Request request) async {
  final playJson = jsonDecode(await request.readAsString());
  final player = serverGame.playerDB[playJson['id']];
  final cardIndex = playJson['card'];
  if (player == null || cardIndex is! int) return Response.badRequest();
  final hand = player.hand.cards.value;
  if (!player.awaitingCard || cardIndex < 0 || cardIndex >= hand.length) {
    return Response(409, body: 'Not your turn to play');
  }
  player.cardToPlay = hand[cardIndex];
  return Response.ok('');
}

/// {"id", "x", "y"}: throws a flashbang onto the table. 429 while the last
/// one is still cooling down.
Future<Response> _executeFlashbang(Request request) async {
  final body = jsonDecode(await request.readAsString());
  final player = serverGame.playerDB[body['id']];
  if (player == null || body['x'] is! num || body['y'] is! num) return Response.badRequest();
  final thrown = serverGame.throwFlashbang(player.name, (body['x'] as num).toDouble(), (body['y'] as num).toDouble());
  return thrown ? Response.ok('') : Response(429, body: 'Flashbang cooling down');
}

/// Markers and eraser: {"id", "stroke", "color", "width", "erase", "points"}
/// with points flattened as [x1, y1, x2, y2...], all 0..1 across the felt.
/// Repeated calls with the same stroke id extend it.
Future<Response> _executeDraw(Request request) async {
  final body = jsonDecode(await request.readAsString());
  final player = serverGame.playerDB[body['id']];
  final flat = body['points'];
  if (player == null || body['stroke'] is! String || flat is! List) return Response.badRequest();
  final points = <Offset>[];
  for (var i = 0; i + 1 < flat.length && points.length < 500; i += 2) {
    if (flat[i] is num && flat[i + 1] is num)
      points.add(Offset((flat[i] as num).toDouble(), (flat[i + 1] as num).toDouble()));
  }
  serverGame.draw(
    player.name,
    body['stroke'],
    color: body['color'] is int ? body['color'] : 0xFF000000,
    width: ((body['width'] as num?) ?? 0.004).toDouble().clamp(0.001, 0.06),
    erase: body['erase'] == true,
    points: points,
  );
  return Response.ok('');
}

/// The revolver: {"id", "x", "y"} puts a hole in the table, {"id", "seat"}
/// spins that player's placard.
Future<Response> _executeShoot(Request request) async {
  final shot = jsonDecode(await request.readAsString());
  final player = serverGame.playerDB[shot['id']];
  if (player == null) return Response.badRequest();
  if (shot['seat'] is String) {
    serverGame.shootSeat(player.name, shot['seat']);
  } else if (shot['x'] is num && shot['y'] is num) {
    serverGame.shootTable(player.name, (shot['x'] as num).toDouble(), (shot['y'] as num).toDouble(),
        seed: shot['seed'] is int ? shot['seed'] : null);
  } else {
    return Response.badRequest();
  }
  return Response.ok('');
}

Future<Response> _executeChat(Request request) async {
  final chatJson = jsonDecode(await request.readAsString());
  final player = serverGame.playerDB[chatJson['id']];
  final String text = (chatJson['text'] ?? '').toString().trim();
  if (player == null || text.isEmpty) return Response.badRequest();
  serverGame.say(player.name, text.length > 280 ? text.substring(0, 280) : text);
  return Response.ok('');
}

Future<Response> _executeFold(Request request) async {
  final foldJson = jsonDecode(await request.readAsString());
  final player = serverGame.playerDB[foldJson['id']];
  if (player == null ||
      serverGame.state.value != GameState.waitingForPlayerToSwap ||
      serverGame.activePlayerLazy != player ||
      !serverGame.fold(player)) {
    return Response.badRequest();
  }
  return Response.ok('');
}

Future<Response> _finalizeSwap(Request request) async {
  String swapData = await request.readAsString();
  final swapJson = jsonDecode(swapData);
  String player = swapJson['id'];
  serverGame.playerDB[player]!.notReady = !serverGame.playerDB[player]!.notReady;

  return Response.ok('');
// return Response.badRequest();
}

void evaluateDeal() {
  if (serverGame.playerDB.values.where((element) => element.voteToDeal == false).isEmpty) {
    serverGame.deal(shuffle: true);
  }
}

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
