// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:donut_game/constants.dart';
import 'package:donut_game/modules/game.dart';
import 'package:donut_game/modules/players.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:shelf_static/shelf_static.dart' as shelf_static;

Game game = Game();

Future main() async {
  // game.addBot();
  // If the "PORT" environment variable is set, listen to it. Otherwise, 8080.
  // https://cloud.google.com/run/docs/reference/container-contract#port
  final port = int.parse('54221' ?? '8080');

  // See https://pub.dev/documentation/shelf/latest/shelf/Cascade-class.html
  final cascade = Cascade()
      // First, serve files from the 'public' directory
      // .add(_staticHandler) // This is having issues
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
}

// Serve files from the file system.
// final _staticHandler = shelf_static.createStaticHandler('build/web',
//     defaultDocument: 'index.html');

// Router instance to handler requests.
final _router = shelf_router.Router()
  ..get('/helloworld', _helloWorldHandler)
  ..post('/connect', _newConnectionHandler)
  ..get('/update', _activeConnection)
  ..post('/vote', _voteResponse)
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
  // game.deal();
  var scores = [
    {'players': _playersToJson(), 'game': gameStateToString[game.state.value]!}
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
      'swaps': player.swaps.value
    });
  }
  return compound;
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
