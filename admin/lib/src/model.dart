import 'dart:async';

import 'package:donut_engine/donut_engine.dart';
import 'package:donut_server/donut_server.dart' show SigV4;
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

/// A player's report, as the server filed it.
class Report {
  const Report(this.key, this.json);

  final String key;
  final Map<String, dynamic> json;

  DateTime get time => DateTime.fromMillisecondsSinceEpoch(json['time'] as int? ?? 0);
  String get reason => '${json['reason'] ?? 'other'}';
  String get code => '${json['code'] ?? ''}';
  bool get public => json['public'] == true;
  String? get note => json['note'] as String?;
  String get reportedId => '${(json['reported'] as Map?)?['id'] ?? ''}';
  String get reportedName => '${(json['reported'] as Map?)?['name'] ?? '?'}';
  String get reporterName => '${(json['reporter'] as Map?)?['name'] ?? '?'}';
  List<Map<String, dynamic>> get chat => [
    for (final line in json['chat'] as List? ?? []) Map<String, dynamic>.from(line as Map),
  ];
}

/// A player kept out of online play.
class Ban {
  const Ban(this.key, this.json);

  final String key;
  final Map<String, dynamic> json;

  String get name => '${json['name'] ?? '?'}';
  String get reason => '${json['reason'] ?? ''}';
  DateTime? get until => json['until'] == null ? null : DateTime.fromMillisecondsSinceEpoch(json['until'] as int);
  bool get active => until == null || until!.isAfter(DateTime.now());
}

/// Everything the admin app shows, refreshed while it's open. Nothing is
/// saved on this Mac; the only changes it makes on the server are
/// moderating reports (dismissing them, banning and unbanning players).
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
  List<Report> reports = [];
  List<Ban> bans = [];
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
    await _refreshModeration();
  }

  Future<void> _refreshModeration() async {
    final reportObjects = await aws.list('reports/');
    final known = {for (final report in reports) report.key: report};
    final nextReports = <Report>[];
    for (final object in reportObjects) {
      final report = known[object.key] ?? Report(object.key, await aws.getJson(object.key) ?? {});
      nextReports.add(report);
    }
    reports = nextReports..sort((a, b) => b.time.compareTo(a.time));
    final banObjects = await aws.list('bans/');
    bans = [for (final object in banObjects) Ban(object.key, await aws.getJson(object.key) ?? {})];
  }

  /// Closes [report] without action.
  Future<void> dismiss(Report report) async {
    await aws.delete(report.key);
    reports = reports.where((other) => other.key != report.key).toList();
    notifyListeners();
  }

  /// Keeps the reported player out of online play for [length] (null: for
  /// good), and closes the report.
  Future<void> ban(Report report, Duration? length) async {
    final until = length == null ? null : DateTime.now().add(length).millisecondsSinceEpoch;
    await aws.putJson('bans/${SigV4.encode(report.reportedId)}.json', {
      'name': report.reportedName,
      'reason': report.reason,
      'until': until,
      'at': DateTime.now().millisecondsSinceEpoch,
    });
    await dismiss(report);
    await _refreshModeration();
    notifyListeners();
  }

  Future<void> unban(Ban ban) async {
    await aws.delete(ban.key);
    bans = bans.where((other) => other.key != ban.key).toList();
    notifyListeners();
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
