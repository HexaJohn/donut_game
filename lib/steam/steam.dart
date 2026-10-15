import 'package:donut_game/steam/steam_start_stub.dart'
    if (dart.library.io) 'package:donut_game/steam/steam_start_io.dart' as platform;

import 'package:flutter/foundation.dart';

/// Donut's app on Steam.
const int steamAppId = 1905500;

/// Steam, for the Windows and macOS builds sold there. Everywhere else (and
/// when Steam isn't running) this is the do-nothing version, so callers
/// never need to check where they are.
class SteamService {
  SteamService({this.problem});

  /// The game's Steam connection; the do-nothing one until [startSteam].
  static SteamService instance = SteamService(problem: 'Not started');

  /// Why Steam isn't available, for the debug panel.
  final String? problem;

  bool get running => false;
  int? get appId => null;
  String? get personaName => null;
  int? get steamId => null;

  /// Recent Steam activity, for the debug panel.
  final ValueNotifier<List<String>> log = ValueNotifier(const []);

  void note(String line) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    final lines = [...log.value, '$time $line'];
    log.value = lines.length > 200 ? lines.sublist(lines.length - 200) : lines;
    debugPrint('Steam: $line');
  }

  /// Whether Steam Cloud is on for this player and game.
  bool get cloudEnabled => false;

  /// The Steam Cloud file [name], or null if there isn't one.
  Uint8List? readCloudFile(String name) => null;

  /// Bytes of Steam Cloud space left for this game, or null if unknown.
  int? get cloudSpaceLeft => null;

  /// Saves [data] to Steam Cloud as [name]. Returns whether it worked.
  bool writeCloudFile(String name, Uint8List data) => false;

  void shutdown() {}
}

/// Connects to Steam if this is a Steam build and Steam is running.
Future<void> startSteam() async {
  SteamService.instance = platform.startPlatformSteam();
}
