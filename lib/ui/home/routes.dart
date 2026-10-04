import 'dart:convert';

import 'package:donut_game/modes/bad_batch/bb_controller.dart';
import 'package:donut_game/modes/bad_batch/bb_screen.dart';
import 'package:donut_game/modes/game_mode.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:donut_game/ui/game/game_screen.dart';
import 'package:donut_game/ui/widget/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

/// What the server at [host]:[port] is playing right now.
Future<GameMode> fetchServerMode(String host, int port) async {
  final response =
      await http.get(Uri(scheme: 'http', host: host, port: port, path: '/update')).timeout(const Duration(seconds: 5));
  return GameModeInfo.fromName(jsonDecode(response.body)[0]['mode']);
}

/// The screen for [mode] on an online server. If the host switches games
/// mid-session, it swaps itself for the right one.
Route<void> onlineRoute(GameMode mode, {required String host, required int port, required String username}) {
  void switchMode(BuildContext context, GameMode next) async {
    if (next.adult && !await confirmAdultContent(context)) {
      if (context.mounted) Navigator.pop(context);
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text('The host switched the table to ${next.label}.')));
    Navigator.pushReplacement(context, onlineRoute(next, host: host, port: port, username: username));
  }

  return gameRoute(switch (mode) {
    GameMode.donut => GameScreen(
        controller: OnlineGameController(host: host, port: port, username: username),
        onModeSwitch: switchMode,
      ),
    GameMode.badBatch => BbScreen(
        controller: OnlineBbController(host: host, port: port, username: username),
        onModeSwitch: switchMode,
      ),
  });
}
