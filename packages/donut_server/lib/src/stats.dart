import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'store.dart';

/// Daily usage numbers for the admin dashboard (admin/ (Donut Admin)).
///
/// Counts only. Who played is never kept: unique players are counted with
/// a keyed one-way hash of each install's id, the key is replaced every
/// month, and the hashes are deleted after 30 days by the bucket's
/// lifecycle rules.
///
///   stats/days/<YYYY-MM-DD>.json     {counter: n}
///   stats/uniques/<YYYY-MM-DD>.json  {"players": [hash, ...]}
///   stats/salts/<YYYY-MM>.json       {"salt": random}
class Stats {
  Stats(this.store, {this.log, Random? random}) : _random = random ?? Random.secure();

  final Store store;
  final void Function(String line)? log;
  final Random _random;
  final Map<String, int> _counts = {};
  final Set<String> _players = {};

  void count(String name, [int by = 1]) => _counts[name] = (_counts[name] ?? 0) + by;

  /// Someone played today (by install id, which is only ever kept hashed).
  void sawPlayer(String id) => _players.add(id);

  /// Saves what this event added. Never throws: the numbers are nice to
  /// have, the game must carry on regardless.
  Future<void> flush(int nowMs) async {
    if (_counts.isEmpty && _players.isEmpty) return;
    final counts = Map.of(_counts);
    final players = Set.of(_players);
    _counts.clear();
    _players.clear();
    final day = DateTime.fromMillisecondsSinceEpoch(nowMs, isUtc: true).toIso8601String().substring(0, 10);
    try {
      if (counts.isNotEmpty) {
        await _merge('stats/days/$day.json', (doc) {
          counts.forEach((name, by) => doc[name] = ((doc[name] as num?) ?? 0).toInt() + by);
          return true;
        });
      }
      if (players.isNotEmpty) {
        final key = utf8.encode(await _salt(day.substring(0, 7)));
        final hashes = {
          for (final id in players) Hmac(sha256, key).convert(utf8.encode(id)).toString().substring(0, 16)
        };
        await _merge('stats/uniques/$day.json', (doc) {
          final seen = Set<String>.from(doc['players'] as List? ?? []);
          final before = seen.length;
          seen.addAll(hashes);
          doc['players'] = seen.toList();
          return seen.length != before;
        });
      }
    } catch (error) {
      log?.call('stats not saved: $error');
    }
  }

  /// Applies [change] to the document at [key], retrying if someone else
  /// wrote it in between. [change] returns false when nothing changed.
  Future<void> _merge(String key, bool Function(Map<String, dynamic> doc) change) async {
    for (var attempt = 0; attempt < 6; attempt++) {
      final stored = await store.get(key);
      final doc = stored == null ? <String, dynamic>{} : Map<String, dynamic>.from(stored.json);
      if (!change(doc)) return;
      try {
        await store.put(key, doc, ifMatch: stored?.etag, ifAbsent: stored == null);
        return;
      } on Conflict {
        continue;
      }
    }
    throw StateError('$key stayed busy');
  }

  /// This month's hashing key, made the first time it's needed.
  Future<String> _salt(String month) async {
    final key = 'stats/salts/$month.json';
    final existing = await store.get(key);
    if (existing != null) return existing.json['salt'] as String;
    final salt = List.generate(32, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    try {
      await store.put(key, {'salt': salt}, ifAbsent: true);
      return salt;
    } on Conflict {
      return (await store.get(key))!.json['salt'] as String;
    }
  }
}
