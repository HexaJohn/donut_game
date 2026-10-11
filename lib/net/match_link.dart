import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:game_center/game_center.dart';

/// Someone in a match.
class MatchPeer {
  const MatchPeer(this.id, this.name);

  final String id;
  final String name;
}

/// What a link reports during a match.
sealed class LinkEvent {
  const LinkEvent();
}

class LinkMessage extends LinkEvent {
  const LinkMessage(this.from, this.message);

  final String from;
  final Map<String, dynamic> message;
}

class LinkPeerLeft extends LinkEvent {
  const LinkPeerLeft(this.id);

  final String id;
}

class LinkFailed extends LinkEvent {
  const LinkFailed(this.message);

  final String message;
}

/// A started match between a few players: who's in it, and a way to pass
/// messages. The host is the player with the lowest id, which every device
/// works out the same way without asking.
abstract class MatchLink {
  String get localId;

  /// Everyone, the local player included.
  List<MatchPeer> get peers;

  Stream<LinkEvent> get events;

  /// Sends [message] to everyone else, or only to [to].
  Future<void> send(Map<String, dynamic> message, {String? to});

  Future<void> close();

  String get hostId => (peers.map((peer) => peer.id).toList()..sort()).first;

  bool get isHost => hostId == localId;
}

/// Messages are JSON, gzipped: a table description shrinks from ~20 KB to a
/// few, well under Game Center's limit for a reliable message.
Uint8List encodeMessage(Map<String, dynamic> message) =>
    Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(message))));

Map<String, dynamic> decodeMessage(Uint8List data) =>
    Map<String, dynamic>.from(jsonDecode(utf8.decode(gzip.decode(data))) as Map);

/// A Game Center match.
class GameCenterLink extends MatchLink {
  GameCenterLink(MatchStarted started)
      : localId = started.localId,
        peers = [for (final player in started.players) MatchPeer(player.id, player.alias)] {
    _subscription = GameCenter.events.listen((event) {
      switch (event) {
        case MatchData(:final from, :final data):
          try {
            _events.add(LinkMessage(from, decodeMessage(data)));
          } catch (e) {
            // A garbled message isn't worth ending the match over
          }
        case PlayerLeft(:final id):
          _events.add(LinkPeerLeft(id));
        case MatchFailed(:final message):
          _events.add(LinkFailed(message));
        case MatchStarted() || MatchCancelled():
          break;
      }
    });
  }

  @override
  final String localId;

  @override
  final List<MatchPeer> peers;

  final _events = StreamController<LinkEvent>.broadcast();
  late final StreamSubscription<GameCenterEvent> _subscription;

  @override
  Stream<LinkEvent> get events => _events.stream;

  @override
  Future<void> send(Map<String, dynamic> message, {String? to}) =>
      GameCenter.send(encodeMessage(message), to: to == null ? null : [to]);

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await _events.close();
    await GameCenter.disconnect();
  }
}
