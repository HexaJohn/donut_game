import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;

import 'package:donut_game/res/resources.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/ui/server_home/server_home.dart';
import 'package:flutter/material.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:shelf_static/shelf_static.dart' as shelf_static;

Game serverGame = Game();

Future main() async {
  serverGame.addBot();
  serverGame.addBot();
  // If the "PORT" environment variable is set, listen to it. Otherwise, 8080.
  // https://cloud.google.com/run/docs/reference/container-contract#port
  final port = int.parse(/*'54221'*/ '27960');

  // See https://pub.dev/documentation/shelf/latest/shelf/Cascade-class.html
  final cascade = Cascade()
      // First, serve files from the 'public' directory
      .add(_staticHandler) // This is having issues
      // If a corresponding file is not found, send requests to a `Router`
      .add(_router.call);

  // See https://pub.dev/documentation/shelf/latest/shelf_io/serve.html
  final server = await shelf_io.serve(
    // See https://pub.dev/documentation/shelf/latest/shelf/logRequests.html
    logRequests(
      logger: (message, isError) {
        serverGame.log.putIfAbsent(message, () => isError);
        serverGame.flipFlop.notifyListeners();
        developer.log(message);
      },
    )
        // See https://pub.dev/documentation/shelf/latest/shelf/MiddlewareExtensions/addHandler.html
        .addHandler(cascade.handler),
    InternetAddress.anyIPv4, // Allows external connections
    port,
  );

  developer.log('Serving at http://${server.address.host}:${server.port}');
  runApp(const ServerHome());
}

// Serve files from the file system.
final _staticHandler = shelf_static.createStaticHandler(r'C:/Users/johnj/Documents/GitHub/donut_game/build/web',
    defaultDocument: 'index.html', serveFilesOutsidePath: true);

// Router instance to handler requests.
final _router = shelf_router.Router()
  ..get('/helloworld', _helloWorldHandler)
  ..post('/connect', _newConnectionHandler)
  ..get('/update', _activeConnection)
  ..post('/vote', _voteResponse)
  ..post('/swap', _executeSwap)
  ..post('/play', _executePlay)
  ..post('/swapvote', _finalizeSwap)
  ..get('/reset', _executeReset)
  ..get(
    '/time',
    (request) => Response.ok(DateTime.now().toUtc().toIso8601String()),
  )
  ..get('/sum/<a|[0-9]+>/<b|[0-9]+>', _sumHandler);

Response _helloWorldHandler(Request request) => Response.ok('Hello, World!');

Future<Response> _newConnectionHandler(Request request) async {
  developer.log('Connected successfully');
  String playerData = await request.readAsString();
  final playerJson = jsonDecode(playerData);
  final player = GamePlayer('${playerJson['username']}', 0, true);
  player.id = playerJson['id'] + playerJson['username'];
  serverGame.addLocalPlayer(player);
  if (serverGame.playerDB.length == 2) {
    serverGame.protectedActive = 1;
    serverGame.protectedDealer = 0;
    serverGame.state.value = GameState.waitingToDeal;
  }
  return Response.ok('Welcome, $playerData');
}

Future<Response> _activeConnection(Request request) async {
  if (serverGame.playerDB.length > 2 && serverGame.state.value == GameState.waitingForPlayers) {
    serverGame.state.value = GameState.waitingToDeal;
  }
  var scores = [
    {
      'players': _playersToJson(),
      'game': {
        'state': gameStateToString[serverGame.state.value]!,
        'table': GameCard.jsonArray(serverGame.table.cards.value),
        'discard': GameCard.jsonArray(serverGame.discard.cards.value),
        'deck': GameCard.jsonArray(serverGame.deck.contents),
        'active': serverGame.protectedActive,
        'dealer': serverGame.protectedDealer,
        'trump': suitToString[serverGame.trumpSuit.value],
        'leading_card': serverGame.leadingCard?.toJson()
      }
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
    developer.log(e.toString());
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
      'folds': player.folds
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
  if (target == CardState.held) {
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

Future<Response> _executePlay(Request request) async {
  developer.log('recieved play request');
  String playData = await request.readAsString();
  final playJson = jsonDecode(playData);
  String player = playJson['id'];
  int cardIndex = playJson['card'];

  serverGame.playerDB[player]!.cardToPlay = serverGame.playerDB[player]!.hand.cards.value[cardIndex];

  return Response.ok('');
}

Future<Response> _finalizeSwap(Request request) async {
  String swapData = await request.readAsString();
  final swapJson = jsonDecode(swapData);
  String player = swapJson['id'];
  serverGame.playerDB[player]!.notReady = !serverGame.playerDB[player]!.notReady;

  return Response.ok('');
}

void evaluateDeal() {
  if (serverGame.playerDB.values.where((element) => element.voteToDeal == false).isEmpty) {
    serverGame.deal(shuffle: true);
    developer.log('dealing');
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
