// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:donut_game/constants.dart';
import 'package:donut_game/modules/cards.dart';
import 'package:donut_game/modules/game.dart';
import 'package:donut_game/modules/players.dart';
import 'package:donut_game/screens/server_gui.dart';
import 'package:flutter/material.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:shelf_static/shelf_static.dart' as shelf_static;

Game game = Game();

Future main() async {
  game.addBot();
  game.addBot();
  // If the "PORT" environment variable is set, listen to it. Otherwise, 8080.
  // https://cloud.google.com/run/docs/reference/container-contract#port
  final port = int.parse(/*'54221'*/ '443');

  // See https://pub.dev/documentation/shelf/latest/shelf/Cascade-class.html
  final cascade = Cascade()
      // First, serve files from the 'public' directory
      .add(_staticHandler) // This is having issues
      // If a corresponding file is not found, send requests to a `Router`
      .add(_router);

  // See https://pub.dev/documentation/shelf/latest/shelf_io/serve.html
  final server = await shelf_io.serve(
    // See https://pub.dev/documentation/shelf/latest/shelf/logRequests.html
    logRequests()
        // See https://pub.dev/documentation/shelf/latest/shelf/MiddlewareExtensions/addHandler.html
        .addHandler(cascade.handler),
    InternetAddress.anyIPv4, // Allows external connections
    port,
  );

  print('Serving at http://${server.address.host}:${server.port}');
  runApp(const ServerApp());
}

// Serve files from the file system.
final _staticHandler = shelf_static.createStaticHandler(
    '/Users/johnperoutka/Documents/donut_game/donut_game/build/web',
    defaultDocument: 'index.html',
    serveFilesOutsidePath: true);

// Router instance to handler requests.
final _router = shelf_router.Router()
  ..get('/helloworld', _helloWorldHandler)
  ..post('/connect', _newConnectionHandler)
  ..get('/update', _activeConnection)
  ..post('/vote', _voteResponse)
  ..post('/swap', _executeSwap)
  ..post('/play', _executePlay)
  ..post('/swapvote', _finalizeSwap)
  ..get(
    '/time',
    (request) => Response.ok(DateTime.now().toUtc().toIso8601String()),
  )
  ..get('/sum/<a|[0-9]+>/<b|[0-9]+>', _sumHandler);

Response _helloWorldHandler(Request request) => Response.ok('Hello, World!');

Future<Response> _newConnectionHandler(Request request) async {
  print('Connected successfully');
  String playerData = await request.readAsString();
  final playerJson = jsonDecode(playerData);
  final player = GamePlayer('${playerJson['username']}', 0, true);
  player.id = playerJson['id'] + playerJson['username'];
  game.addLocalPlayer(player);
  if (game.playerDB.length == 2) {
    game.protectedActive = 1;
    game.protectedDealer = 0;
    game.state.value = GameState.waitingToDeal;
  }
  return Response.ok('Welcome, ${playerData}');
}

Future<Response> _activeConnection(Request request) async {
  if (game.playerDB.length > 2 &&
      game.state.value == GameState.waitingForPlayers) {
    game.state.value = GameState.waitingToDeal;
  }
  // game.deal();
  var scores = [
    {
      'players': _playersToJson(),
      'game': {
        'state': gameStateToString[game.state.value]!,
        'table': GameCard.jsonArray(game.table.cards.value),
        'discard': GameCard.jsonArray(game.discard.cards.value),
        'deck': GameCard.jsonArray(game.deck.contents),
        'active': game.protectedActive,
        'dealer': game.protectedDealer,
        'trump': suitToString[game.trumpSuit.value],
        'leading_card': game.leadingCard?.toJson()
      }
    }
  ];

  var jsonText = jsonEncode(scores);
  // print(jsonText);
  return Response.ok(jsonText);
}

Future<Response> _voteResponse(Request request) async {
  try {
    String playerData = await request.readAsString();
    final playerJson = jsonDecode(playerData);
    final player = game.playerDB[playerJson['id']]!;
    // print(playerJson);
    // print(playerJson['voteDeal'] == 'true' ? true : false);
    // player.voteToDeal = !player.voteToDeal;
    player.voteToDeal = true;
    evaluateDeal();
    return Response.ok('');
  } catch (e) {
    print(e);
    return Response.badRequest();
  }
}

List<Map<String, dynamic>> _playersToJson() {
  List<Map<String, dynamic>> compound = [];
  for (var player in game.players) {
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
  var target = game.playerDB[player]!.hand.cards.value[cardIndex].state;
  print(game.playerDB[player]!.hand.cards.value[cardIndex].state);
  if (target == CardState.held) {
    game.playerDB[player]!.hand.cards.value[cardIndex].state = CardState.swap;
    game.playerDB[player]!.swaps.value--;

    return Response.ok('');
  }

  if (target == CardState.swap) {
    game.playerDB[player]!.hand.cards.value[cardIndex].state = CardState.held;
    game.playerDB[player]!.swaps.value++;

    return Response.ok('');
  }
  print(game.playerDB[player]!.hand.cards.value[cardIndex].state);
  return Response.badRequest();
}

Future<Response> _executePlay(Request request) async {
  print('recieved play request');
  String playData = await request.readAsString();
  final playJson = jsonDecode(playData);
  String player = playJson['id'];
  int cardIndex = playJson['card'];

  print(game.playerDB[player]!.hand.cards.value[cardIndex].state);

  game.playerDB[player]!.cardToPlay =
      game.playerDB[player]!.hand.cards.value[cardIndex];

  print(game.playerDB[player]!.cardToPlay);
  try {
    print('playing card');
    // game.playerDB[player]!
    // .play(game.playerDB[player]!.cardToPlay!, sender: 'server');
  } catch (e) {
    rethrow;
  }
  return Response.ok('');
}

Future<Response> _executeFold(Request request) async {
  print('recieved fold request');
  String playData = await request.readAsString();
  final playJson = jsonDecode(playData);
  String player = playJson['id'];

  try {
    game.playerDB[player]?.skip = true;
    game.playerDB[player]?.notReady = true;
    game.playerDB[player]?.donut = true;
  } catch (e) {
    rethrow;
  }
  return Response.ok('');
}

Future<Response> _finalizeSwap(Request request) async {
  String swapData = await request.readAsString();
  final swapJson = jsonDecode(swapData);
  String player = swapJson['id'];
  game.playerDB[player]!.notReady = !game.playerDB[player]!.notReady;

  return Response.ok('');
// return Response.badRequest();
}

void evaluateDeal() {
  if (game.playerDB.values
      .where((element) => element.voteToDeal == false)
      .isEmpty) {
    game.deal(shuffle: true);
    print('dealing');
  }
}

Response _sumHandler(request, String a, String b) {
  final aNum = int.parse(a);
  final bNum = int.parse(b);
  return Response.ok(
    const JsonEncoder.withIndent(' ')
        .convert({'a': aNum, 'b': bNum, 'sum': aNum + bNum}),
    headers: {
      'content-type': 'application/json',
      'Cache-Control': 'public, max-age=604800',
    },
  );
}
