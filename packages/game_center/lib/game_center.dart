import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The signed-in Game Center player.
class GameCenterPlayer {
  const GameCenterPlayer(this.id, this.alias);

  /// Stable for this player in this game (gamePlayerID).
  final String id;
  final String alias;
}

/// Something that happened with the current match.
sealed class GameCenterEvent {
  const GameCenterEvent();
}

/// Everyone has joined. [players] includes the local player.
class MatchStarted extends GameCenterEvent {
  const MatchStarted(this.localId, this.players);

  final String localId;
  final List<GameCenterPlayer> players;
}

class MatchData extends GameCenterEvent {
  const MatchData(this.from, this.data);

  final String from;
  final Uint8List data;
}

class PlayerLeft extends GameCenterEvent {
  const PlayerLeft(this.id);

  final String id;
}

/// The player closed the matchmaking screen.
class MatchCancelled extends GameCenterEvent {
  const MatchCancelled();
}

class MatchFailed extends GameCenterEvent {
  const MatchFailed(this.message);

  final String message;
}

/// Game Center sign-in and real-time matches, on iOS and macOS.
class GameCenter {
  GameCenter._();

  static const _methods = MethodChannel('donut/game_center');
  static const _events = EventChannel('donut/game_center/events');

  /// Whether this platform has Game Center at all.
  static bool get supported => !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  static Stream<GameCenterEvent>? _stream;

  /// Match events, shared by every listener.
  static Stream<GameCenterEvent> get events => _stream ??= _events
      .receiveBroadcastStream()
      .map((raw) => _parse(Map<String, dynamic>.from(raw as Map)))
      .where((event) => event != null)
      .cast<GameCenterEvent>()
      .asBroadcastStream();

  static GameCenterEvent? _parse(Map<String, dynamic> raw) => switch (raw['type']) {
        'matchStarted' => MatchStarted(raw['localId'] as String, [
            for (final player in raw['players'] as List)
              GameCenterPlayer((player as Map)['id'] as String, player['alias'] as String),
          ]),
        'data' => MatchData(raw['from'] as String, raw['data'] as Uint8List),
        'playerLeft' => PlayerLeft(raw['id'] as String),
        'cancelled' => const MatchCancelled(),
        'failed' => MatchFailed('${raw['message']}'),
        _ => null,
      };

  /// Signs in, showing Apple's sign-in screen if needed. Throws a
  /// [PlatformException] with a readable message if the player isn't signed
  /// in.
  static Future<GameCenterPlayer> authenticate() async {
    final info = Map<String, dynamic>.from(await _methods.invokeMethod('authenticate') as Map);
    return GameCenterPlayer(info['id'] as String, info['alias'] as String);
  }

  /// Shows Apple's matchmaking screen. The result arrives on [events]:
  /// [MatchStarted], [MatchCancelled] or [MatchFailed].
  static Future<void> findMatch({int min = 2, int max = 4}) =>
      _methods.invokeMethod('findMatch', {'min': min, 'max': max});

  /// Sends [data] to everyone in the match, or just the players in [to].
  static Future<void> send(Uint8List data, {List<String>? to, bool reliable = true}) =>
      _methods.invokeMethod('send', {'data': data, 'to': to, 'reliable': reliable});

  static Future<void> disconnect() => _methods.invokeMethod('disconnect');
}
