import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

String? _cached;

/// A random id for this install, made on first use and kept in shared
/// preferences. Servers pair it with the nickname to give a reconnecting
/// player their old seat back.
Future<String> deviceId() async {
  if (_cached != null) return _cached!;
  try {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('deviceId');
    if (id == null) {
      final random = Random.secure();
      id = List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await prefs.setString('deviceId', id);
    }
    return _cached = id;
  } catch (e) {
    return 'unknown';
  }
}

String? _secret;

/// A private random value for this install, never shown to anyone. Proves
/// to a server that a move really comes from this player, since the device
/// id is visible to everyone at the table.
Future<String> deviceSecret() async {
  if (_secret != null) return _secret!;
  try {
    final prefs = await SharedPreferences.getInstance();
    var secret = prefs.getString('deviceSecret');
    if (secret == null) {
      final random = Random.secure();
      secret = List.generate(32, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await prefs.setString('deviceSecret', secret);
    }
    return _secret = secret;
  } catch (e) {
    // No storage: a secret for this run only
    final random = Random.secure();
    return _secret = List.generate(32, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
}
