import 'dart:async';
import 'dart:convert';

import 'package:donut_game/steam/steam.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the save (progress, cosmetics, settings) in Steam Cloud, so it
/// follows the player between computers, Windows and Mac alike. The save is
/// one JSON snapshot of the game's preferences; whichever copy was written
/// last wins.
class CloudSave {
  CloudSave._();

  static const file = 'donut_save.json';

  /// When the local save last matched the cloud.
  static const _stampKey = 'cloud.savedAt';

  /// Kept per install: the identity online tables seat (two computers on
  /// one account mustn't collide) and the anonymous stats queue.
  static const _localOnly = {_stampKey, 'deviceId', 'deviceSecret', 'usagePending', 'usageDailyDay'};

  static Timer? _timer;
  static String? _lastUploaded;

  /// Nothing is uploaded until the cloud's copy has been checked: a new
  /// computer's blank save must never overwrite the real one.
  static bool _checked = false;

  @visibleForTesting
  static void resetForTest() {
    _checked = false;
    _lastUploaded = null;
  }

  /// Before anything reads the save: takes the cloud's copy if it's newer.
  static Future<void> restore() async {
    final steam = SteamService.instance;
    if (!steam.running) return;
    if (!steam.cloudEnabled) {
      steam.note('Steam Cloud is off for this game or this account');
      return;
    }
    try {
      await _restore(steam);
    } finally {
      _checked = true;
    }
  }

  static Future<void> _restore(SteamService steam) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = steam.readCloudFile(file);
      if (data == null) {
        steam.note('No cloud save yet');
        return;
      }
      final save = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      final savedAt = save['savedAt'] as int? ?? 0;
      if (savedAt <= (prefs.getInt(_stampKey) ?? 0)) {
        steam.note('This computer\'s save is current');
        return;
      }
      final values = Map<String, dynamic>.from(save['values'] as Map);
      for (final MapEntry(:key, :value) in values.entries) {
        if (_localOnly.contains(key)) continue;
        switch (value) {
          case bool v:
            await prefs.setBool(key, v);
          case int v:
            await prefs.setInt(key, v);
          case double v:
            await prefs.setDouble(key, v);
          case String v:
            await prefs.setString(key, v);
          case List v:
            await prefs.setStringList(key, v.cast<String>());
        }
      }
      await prefs.setInt(_stampKey, savedAt);
      _lastUploaded = _snapshot(prefs);
      steam.note('Restored the cloud save from ${DateTime.fromMillisecondsSinceEpoch(savedAt)}');
    } catch (e) {
      steam.note('Cloud save not restored: $e');
    }
  }

  /// Uploads changes every half minute, and whenever [upload] is called
  /// (leaving or closing the game).
  static void start() {
    if (!SteamService.instance.running) return;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => upload());
  }

  /// Saves the current state to the cloud, if it changed.
  static Future<void> upload() async {
    final steam = SteamService.instance;
    if (!steam.running || !steam.cloudEnabled || !_checked) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final snapshot = _snapshot(prefs);
      if (snapshot == _lastUploaded) return;
      final savedAt = DateTime.now().millisecondsSinceEpoch;
      final body = utf8.encode('{"savedAt":$savedAt,"values":$snapshot}');
      if (steam.writeCloudFile(file, Uint8List.fromList(body))) {
        _lastUploaded = snapshot;
        await prefs.setInt(_stampKey, savedAt);
        steam.note('Saved to the cloud (${body.length} bytes)');
      } else {
        final left = steam.cloudSpaceLeft;
        steam.note(left == 0
            ? 'Cloud save failed: no Steam Cloud space (set a quota in Steamworks)'
            : 'Cloud save failed (${left ?? '?'} bytes free)');
      }
    } catch (e) {
      steam.note('Cloud save failed: $e');
    }
  }

  /// Everything worth syncing, in a stable order so unchanged saves compare
  /// equal.
  static String _snapshot(SharedPreferences prefs) {
    final keys = prefs.getKeys().where((key) => !_localOnly.contains(key)).toList()..sort();
    return jsonEncode({for (final key in keys) key: prefs.get(key)});
  }
}
