import 'dart:async';

import 'package:donut_engine/donut_engine.dart';
import 'package:flutter/foundation.dart';

import 'aws.dart';

/// A table on the party server, as last read.
class LiveTable {
  const LiveTable(this.state, this.modified);

  final TableState state;
  final DateTime modified;

  String get code => state.code;
  Iterable<Seat> get humans => state.seats.where((seat) => seat.human);
  Iterable<Seat> get online => humans.where((seat) => seat.connected);
  DateTime get lastMove => DateTime.fromMillisecondsSinceEpoch(state.updatedAt);

  /// Someone's connected and it moved recently.
  bool get active => online.isNotEmpty && DateTime.now().difference(modified) < AdminModel.activeFor;
}

/// One day's counts from the server's stats.
class DayStats {
  const DayStats(this.day, this.counts, this.players);

  final String day;
  final Map<String, int> counts;

  /// Hashed install ids that played (only the last 30 days are kept).
  final Set<String> players;

  int operator [](String key) => counts[key] ?? 0;
  int get matches => this['matchesStartedParty'] + this['matchesStartedPublic'];
}

/// Everything the admin app shows, refreshed while it's open. Read-only:
/// nothing is changed on the server and nothing is saved on this Mac.
class AdminModel extends ChangeNotifier {
  AdminModel(this.aws);

  final AdminAws aws;

  /// How recently a table must have moved to count as live.
  static const activeFor = Duration(minutes: 15);
  static const _tablesEvery = Duration(seconds: 10);
  static const _statsEvery = Duration(minutes: 2);

  Map<String, LiveTable> _tables = {};
  List<DayStats> days = [];
  int openConnections = 0;
  String? error;
  DateTime? updated;
  bool loading = false;
  Timer? _timer;
  DateTime? _statsAt;

  List<LiveTable> get tables => _tables.values.toList()..sort((a, b) => b.modified.compareTo(a.modified));
  List<LiveTable> get activeTables => tables.where((table) => table.active).toList();

  void start() {
    refresh();
    _timer = Timer.periodic(_tablesEvery, (_) => refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> refresh({bool stats = false}) async {
    if (loading) return;
    loading = true;
    notifyListeners();
    try {
      await _refreshTables();
      if (stats || _statsAt == null || DateTime.now().difference(_statsAt!) > _statsEvery) await _refreshStats();
      error = null;
      updated = DateTime.now();
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Lists the tables and reads only the ones that changed since last time.
  Future<void> _refreshTables() async {
    final listed = (await aws.list('tables/')).where((object) => object.key.endsWith('/state.json')).toList();
    final next = <String, LiveTable>{};
    final changed = <S3Object>[];
    for (final object in listed) {
      final code = object.key.split('/')[1];
      final known = _tables[code];
      if (known != null && known.modified == object.modified) {
        next[code] = known;
      } else {
        changed.add(object);
      }
    }
    // A handful at a time, newest first
    changed.sort((a, b) => b.modified.compareTo(a.modified));
    for (var i = 0; i < changed.length; i += 8) {
      await Future.wait([
        for (final object in changed.skip(i).take(8))
          () async {
            final json = await aws.getJson(object.key);
            if (json == null) return;
            final state = TableState.fromJson(json);
            next[state.code] = LiveTable(state, object.modified);
          }(),
      ]);
    }
    _tables = next;
    openConnections = (await aws.list('conns/')).length;
  }

  Future<void> _refreshStats() async {
    final dayObjects = await aws.list('stats/days/');
    final uniqueObjects = await aws.list('stats/uniques/');
    String dayOf(String key) => key.split('/').last.replaceAll('.json', '');
    final counts = <String, Map<String, int>>{};
    final players = <String, Set<String>>{};
    await Future.wait([
      for (final object in dayObjects)
        () async {
          final json = await aws.getJson(object.key) ?? {};
          counts[dayOf(object.key)] = {
            for (final e in json.entries)
              if (e.value is num) e.key: (e.value as num).toInt(),
          };
        }(),
      for (final object in uniqueObjects)
        () async {
          final json = await aws.getJson(object.key) ?? {};
          players[dayOf(object.key)] = Set<String>.from(json['players'] as List? ?? []);
        }(),
    ]);
    final all = {...counts.keys, ...players.keys}.toList()..sort();
    days = [for (final day in all) DayStats(day, counts[day] ?? {}, players[day] ?? {})];
    _statsAt = DateTime.now();
  }

  /// Unique players over the last [n] days (from the hashes still kept).
  int playersOver(int n) {
    final today = DateTime.now().toUtc();
    final since = today.subtract(Duration(days: n - 1)).toIso8601String().substring(0, 10);
    return {for (final day in days.where((d) => d.day.compareTo(since) >= 0)) ...day.players}.length;
  }

  int total(String key) => days.fold(0, (sum, day) => sum + day[key]);
}
