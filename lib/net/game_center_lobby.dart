import 'dart:async';
import 'dart:io';

import 'package:donut_copy/donut_copy.dart';
import 'package:donut_game/net/match_controllers.dart';
import 'package:donut_game/net/match_link.dart';
import 'package:donut_game/ui/game/game_screen.dart';
import 'package:donut_game/ui/home/routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_center/game_center.dart';

/// Starts Game Center matches and opens them, whether the player found the
/// match from the home screen or accepted a friend's invite from outside the
/// app.
class GameCenterLobby {
  GameCenterLobby._();
  static final GameCenterLobby instance = GameCenterLobby._();

  /// Up to four at a table: Game Center's limit for matches between devices.
  static const int maxPlayers = 4;

  /// Given to the app, so a match can open from anywhere.
  final navigatorKey = GlobalKey<NavigatorState>();
  final messengerKey = GlobalKey<ScaffoldMessengerState>();

  StreamSubscription<GameCenterEvent>? _subscription;
  bool _inMatch = false;

  bool get supported => GameCenter.supported;

  void _listen() {
    if (!supported || _subscription != null) return;
    _subscription = GameCenter.events.listen((event) {
      switch (event) {
        case MatchStarted():
          _open(event);
        case MatchFailed(:final message) when !_inMatch:
          _say(message);
        default:
          break;
      }
    });
  }

  /// Signs in at launch on iPhone and iPad, so invites from friends can find
  /// the player; Game Center shows its own welcome banner.
  Future<void> signInQuietly() async {
    if (!supported || kIsWeb || !Platform.isIOS) return;
    _listen();
    try {
      await GameCenter.authenticate();
    } catch (e) {
      // Not signed in: the Play with friends button will say so
    }
  }

  /// Signs in if needed and shows Apple's screen for inviting friends or
  /// finding players. The match opens once everyone has joined.
  Future<void> findMatch() async {
    _listen();
    try {
      await GameCenter.authenticate();
      await GameCenter.findMatch(min: 2, max: maxPlayers);
    } on PlatformException catch (e) {
      _say(e.message ?? onlineGameCenterUnavailable());
    } on MissingPluginException {
      _say(onlineGameCenterNoDevice());
    }
  }

  void _open(MatchStarted started) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    final link = GameCenterLink(started);
    final controller = link.isHost ? MatchHostController(link) : MatchClientController(link);
    _inMatch = true;
    navigator.push(gameRoute(GameScreen(controller: controller))).whenComplete(() => _inMatch = false);
  }

  void _say(String message) =>
      messengerKey.currentState?.showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}
