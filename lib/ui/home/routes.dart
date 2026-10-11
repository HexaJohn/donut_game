import 'package:donut_game/net/party_client.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:donut_game/ui/game/game_screen.dart';
import 'package:flutter/material.dart';

/// Fades and settles a game screen in.
Route<void> gameRoute(Widget screen) => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => screen,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: Tween(begin: 1.04, end: 1.0).animate(curved), child: child),
        );
      },
    );

/// The game on the server at [host]:[port].
Route<void> onlineRoute({required String host, required int port, required String username}) =>
    gameRoute(GameScreen(controller: OnlineGameController(host: host, port: port, username: username)));

/// A party on the party server: a new one hosted by this player, or [code].
Route<void> partyRoute({String? code, required String nickname}) =>
    gameRoute(GameScreen(controller: PartyController(code: code, nickname: nickname)));
