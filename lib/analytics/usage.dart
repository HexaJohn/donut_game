import 'dart:async';
import 'dart:convert';

import 'package:donut_game/data/device_id.dart';
import 'package:donut_game/data/settings.dart';
import 'package:donut_game/net/party_client.dart' show partyServerUrl;
import 'package:donut_game/net/party_socket_io.dart'
    if (dart.library.js_interop) 'package:donut_game/net/party_socket_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Anonymous gameplay counts ("campaign.bakery.2.won", "session.minutes"),
/// so the game can be tuned without knowing who anyone is.
///
/// Only tallies: no names, no chat, no timeline of what one player did.
/// Kept on the device (offline play counts too) and sent now and then in one
/// small batch to the party server, which adds them to the day's totals.
/// The install id goes along only so the server can count unique players;
/// it keeps it as a hash it deletes after 30 days. Nothing is kept or sent
/// while "Share anonymous gameplay stats" is off in Settings.
class Usage with WidgetsBindingObserver {
  Usage._();
  static final Usage instance = Usage._();

  static const _pendingKey = 'usagePending';
  static const _dailyKey = 'usageDailyDay';
  static const _sendEvery = Duration(minutes: 30);
  static const _minGap = Duration(minutes: 5);

  /// Event names the server accepts.
  static final RegExp validName = RegExp(r'^[a-zA-Z0-9_.-]{1,48}$');

  /// Where counts are sent (the party server).
  @visibleForTesting
  String url = partyServerUrl;

  SharedPreferences? _prefs;
  Map<String, int> _pending = {};
  DateTime? _sessionStart;
  DateTime? _lastSend;
  Timer? _timer;
  bool _sending = false;

  bool get enabled => Settings.instance.shareUsage.value;

  Future<void> start() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _pending = Map<String, int>.from(jsonDecode(_prefs!.getString(_pendingKey) ?? '{}') as Map);
    } catch (_) {}
    WidgetsBinding.instance.addObserver(this);
    Settings.instance.shareUsage.addListener(_onToggle);
    _beginSession();
    _timer = Timer.periodic(_sendEvery, (_) => send());
    // Give the app a moment to settle before the first send
    Timer(const Duration(seconds: 15), send);
  }

  /// Adds [by] to the tally called [name].
  void count(String name, [int by = 1]) {
    if (!enabled || by <= 0 || !validName.hasMatch(name)) return;
    _pending[name] = (_pending[name] ?? 0) + by;
    _save();
  }

  void _save() => _prefs?.setString(_pendingKey, jsonEncode(_pending));

  void _onToggle() {
    if (enabled) {
      _beginSession();
    } else {
      // Off means nothing kept either
      _pending = {};
      _sessionStart = null;
      _save();
    }
  }

  void _beginSession() {
    if (!enabled) return;
    _sessionStart = DateTime.now();
    count('session.count');
    // Once a day: which platform and version are in use
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    if (_prefs?.getString(_dailyKey) != today) {
      _prefs?.setString(_dailyKey, today);
      count('platform.${kIsWeb ? 'web' : defaultTargetPlatform.name}');
      count('version.$appVersion');
    }
  }

  void _endSession() {
    final start = _sessionStart;
    if (start == null) return;
    _sessionStart = null;
    final minutes = DateTime.now().difference(start).inMinutes;
    if (minutes > 0) count('session.minutes', minutes.clamp(0, 600));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _endSession();
      send();
    } else if (state == AppLifecycleState.resumed && _sessionStart == null) {
      _beginSession();
    }
  }

  /// Sends what's been tallied, if there's anything and it's been a while.
  /// Counts are only dropped once the server has them.
  Future<void> send() async {
    if (!enabled || _sending || _pending.isEmpty) return;
    if (_lastSend != null && DateTime.now().difference(_lastSend!) < _minGap) return;
    _sending = true;
    _lastSend = DateTime.now();
    final batch = Map.of(_pending);
    final channel = openPartySocket(Uri.parse(url));
    try {
      await channel.ready.timeout(const Duration(seconds: 8));
      final acked = channel.stream
          .map((raw) => jsonDecode(raw as String))
          .firstWhere((message) => message is Map && message['k'] == 'ack' && message['n'] == 1)
          .timeout(const Duration(seconds: 8));
      channel.sink.add(jsonEncode({'a': 'usage', 'player': await deviceId(), 'events': batch, 'n': 1}));
      final ack = await acked;
      if ((ack as Map)['ok'] == true) {
        // Keep anything counted while this was sending
        for (final MapEntry(:key, :value) in batch.entries) {
          final left = (_pending[key] ?? 0) - value;
          if (left > 0) {
            _pending[key] = left;
          } else {
            _pending.remove(key);
          }
        }
        _save();
      }
    } catch (_) {
      // Offline or the server's away: try again later
    } finally {
      _sending = false;
      channel.sink.close();
    }
  }

  @visibleForTesting
  Map<String, int> get pending => Map.unmodifiable(_pending);

  @visibleForTesting
  void reset() {
    _pending = {};
    _lastSend = null;
    _timer?.cancel();
  }
}
