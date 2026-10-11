import 'dart:convert';

import 'package:donut_game/campaign/campaign.dart';
import 'package:donut_game/progression/catalog.dart';
import 'package:donut_game/progression/emblem.dart';
import 'package:donut_game/progression/ranks.dart';
import 'package:donut_game/progression/rewards.dart';
import 'package:donut_game/progression/slot_machine.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lifetime numbers shown on the career card.
class CareerStats {
  int matches = 0;
  int wins = 0;
  int tricks = 0;
  int donuts = 0;
  int handsPlayed = 0;
  int badBatchGames = 0;
  int badBatchWins = 0;
  int jackpots = 0;
  int slotPulls = 0;

  Map<String, dynamic> toJson() => {
        'matches': matches,
        'wins': wins,
        'tricks': tricks,
        'donuts': donuts,
        'hands': handsPlayed,
        'bbGames': badBatchGames,
        'bbWins': badBatchWins,
        'jackpots': jackpots,
        'slotPulls': slotPulls,
      };

  static CareerStats fromJson(Map<String, dynamic>? json) {
    final stats = CareerStats();
    if (json == null) return stats;
    stats
      ..matches = json['matches'] ?? 0
      ..wins = json['wins'] ?? 0
      ..tricks = json['tricks'] ?? 0
      ..donuts = json['donuts'] ?? 0
      ..handsPlayed = json['hands'] ?? 0
      ..badBatchGames = json['bbGames'] ?? 0
      ..badBatchWins = json['bbWins'] ?? 0
      ..jackpots = json['jackpots'] ?? 0
      ..slotPulls = json['slotPulls'] ?? 0;
    return stats;
  }
}

/// The local player's career: XP, currencies, unlocks and emblem. Saved to
/// shared preferences as one JSON blob. Notifies on every change.
class PlayerProfile extends ChangeNotifier {
  PlayerProfile();

  static final PlayerProfile instance = PlayerProfile();

  static const _key = 'profile';
  SharedPreferences? _prefs;

  int _xp = 0;
  int _crumbs = 0;
  int _glaze = 0;
  final Set<String> _owned = {...starterItems};
  String _cardPattern = 'pattern.classic';
  String _cardFace = 'face.classic';
  String _environment = 'env.theme';
  Emblem _emblem = const Emblem();

  /// Best difficulty each campaign stage was cleared on, by stage id.
  final Map<String, Difficulty> _stageClears = {};
  Difficulty _campaignDifficulty = Difficulty.standard;
  CareerStats stats = CareerStats();

  /// Calendar day of the last first-win bonus, as yyyy-mm-dd.
  String? _lastDailyWin;

  int get xp => _xp;
  int get crumbs => _crumbs;
  int get glaze => _glaze;
  Rank get rank => rankFor(_xp);
  Rank? get nextRank => nextRankFor(_xp);
  double get rankProgressValue => rankProgress(_xp);
  Set<String> get owned => Set.unmodifiable(_owned);
  String get cardPattern => _cardPattern;
  String get cardFace => _cardFace;
  String get environment => _environment;
  Emblem get emblem => _emblem;
  Difficulty get campaignDifficulty => _campaignDifficulty;

  /// The best difficulty [stage] was cleared on, or null if never.
  Difficulty? bestClear(Stage stage) => _stageClears[stage.id];

  /// The first stage is always open; each after it once the one before is
  /// cleared.
  bool isStageUnlocked(Stage stage) {
    final stages = allStages;
    final i = stages.indexOf(stage);
    return i <= 0 || _stageClears.containsKey(stages[i - 1].id);
  }

  /// Stars earned across the whole campaign.
  int get campaignStars => _stageClears.values.fold(0, (sum, d) => sum + d.stars);

  bool owns(String id) => _owned.contains(id);

  bool get firstWinTodayAvailable => _lastDailyWin != _today();

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      return;
    }
    final raw = _prefs!.getString(_key);
    if (raw != null) {
      try {
        _apply(jsonDecode(raw));
      } catch (e) {
        // A corrupt profile starts over rather than crashing the game
      }
    }
    notifyListeners();
  }

  void _apply(Map<String, dynamic> json) {
    _xp = json['xp'] ?? 0;
    _crumbs = json['crumbs'] ?? 0;
    _glaze = json['glaze'] ?? 0;
    _owned
      ..clear()
      ..addAll(starterItems)
      ..addAll(List<String>.from(json['owned'] ?? []));
    // Items from ranks already held, for careers saved before rank rewards
    // existed
    for (final item in catalog) {
      if (item.rankOnly && item.rank <= rank.index) _owned.add(item.id);
    }
    _cardPattern = json['cardPattern'] ?? _cardPattern;
    _cardFace = json['cardFace'] ?? _cardFace;
    _environment = json['environment'] ?? _environment;
    if (!_owned.contains(_cardPattern)) _cardPattern = 'pattern.classic';
    if (!_owned.contains(_cardFace)) _cardFace = 'face.classic';
    if (!_owned.contains(_environment)) _environment = 'env.theme';
    _emblem = Emblem.fromJson(json['emblem']);
    _stageClears.clear();
    for (final MapEntry(:key, :value) in Map<String, dynamic>.from(json['stages'] ?? {}).entries) {
      final difficulty = Difficulty.values.where((d) => d.name == value).firstOrNull;
      if (difficulty != null) _stageClears[key] = difficulty;
    }
    _campaignDifficulty =
        Difficulty.values.where((d) => d.name == json['campaignDifficulty']).firstOrNull ?? Difficulty.standard;
    stats = CareerStats.fromJson(json['stats']);
    _lastDailyWin = json['lastDailyWin'];
  }

  Map<String, dynamic> toJson() => {
        'xp': _xp,
        'crumbs': _crumbs,
        'glaze': _glaze,
        'owned': _owned.toList(),
        'cardPattern': _cardPattern,
        'cardFace': _cardFace,
        'environment': _environment,
        'emblem': _emblem.toJson(),
        'stages': {for (final MapEntry(:key, :value) in _stageClears.entries) key: value.name},
        'campaignDifficulty': _campaignDifficulty.name,
        'stats': stats.toJson(),
        'lastDailyWin': _lastDailyWin,
      };

  /// Replaces everything from a saved blob. For tests and imports.
  void restore(Map<String, dynamic> json) {
    _apply(json);
    _save();
  }

  void _save() {
    _prefs?.setString(_key, jsonEncode(toJson()));
    notifyListeners();
  }

  /// Adds XP and currency, and banks the reward of every rank reached on
  /// the way. Returns the ranks reached, lowest first.
  List<Rank> grant({int xp = 0, int crumbs = 0, int glaze = 0}) {
    final before = rank;
    _xp += xp;
    _crumbs += crumbs;
    _glaze += glaze;
    final reached = ranks.sublist(before.index + 1, rank.index + 1);
    for (final rank in reached) {
      final reward = rankReward(rank);
      _crumbs += reward.crumbs;
      _glaze += reward.glaze;
      if (reward.item != null) _owned.add(reward.item!);
    }
    _save();
    return reached;
  }

  /// Records a finished Donut match and pays [rewards] for it. Returns the
  /// ranks reached.
  List<Rank> recordDonutMatch(DonutMatchSummary match, MatchRewards rewards) {
    stats.matches++;
    stats.tricks += match.tricks;
    stats.donuts += match.donuts;
    stats.handsPlayed += match.hands;
    if (match.won) {
      stats.wins++;
      _lastDailyWin = _today();
    }
    return grant(xp: rewards.xp, crumbs: rewards.crumbs, glaze: rewards.glaze);
  }

  List<Rank> recordBadBatch(BadBatchSummary game, MatchRewards rewards) {
    stats.badBatchGames++;
    if (game.won) {
      stats.badBatchWins++;
      _lastDailyWin = _today();
    }
    return grant(xp: rewards.xp, crumbs: rewards.crumbs, glaze: rewards.glaze);
  }

  List<Rank> recordSlots(SlotResult result) {
    stats.slotPulls++;
    if (result.jackpot) stats.jackpots++;
    return grant(xp: result.xp, crumbs: result.crumbs, glaze: result.glaze);
  }

  /// Whether [item]'s rank requirement is met.
  bool hasUnlocked(ShopItem item) => item.rank <= rank.index;

  /// Whether the item [item] upgrades, if any, is owned.
  bool hasRequirement(ShopItem item) => item.requires == null || owns(item.requires!);

  bool canAfford(ShopItem item) => switch (item.currency) {
        Currency.crumbs => _crumbs >= item.price,
        Currency.glaze => _glaze >= item.price,
      };

  /// Buys and equips [item]. False if it's not for sale, still locked, an
  /// upgrade to something not owned, or can't be afforded.
  bool buy(ShopItem item) {
    if (owns(item.id) || item.rankOnly || !hasUnlocked(item) || !hasRequirement(item) || !canAfford(item)) {
      return false;
    }
    switch (item.currency) {
      case Currency.crumbs:
        _crumbs -= item.price;
      case Currency.glaze:
        _glaze -= item.price;
    }
    _owned.add(item.id);
    _equipIfCosmetic(item);
    _save();
    return true;
  }

  void _equipIfCosmetic(ShopItem item) {
    switch (item.kind) {
      case ItemKind.cardPattern:
        _cardPattern = item.id;
      case ItemKind.cardFace:
        _cardFace = item.id;
      case ItemKind.environment:
        _environment = item.id;
      case ItemKind.gadget:
        break;
    }
  }

  /// Wears an owned pattern, face or environment. Gadgets are always on once owned.
  bool equip(String id) {
    final item = itemById(id);
    if (item == null || !owns(id)) return false;
    _equipIfCosmetic(item);
    _save();
    return true;
  }

  bool isEquipped(String id) => id == _cardPattern || id == _cardFace || id == _environment;

  set campaignDifficulty(Difficulty difficulty) {
    _campaignDifficulty = difficulty;
    _save();
  }

  /// Records a win on [stage] at [difficulty], keeping the best clear.
  void recordStageClear(Stage stage, Difficulty difficulty) {
    final best = _stageClears[stage.id];
    if (best == null || difficulty.index > best.index) _stageClears[stage.id] = difficulty;
    _save();
  }

  void setEmblem(Emblem emblem) {
    _emblem = emblem;
    _save();
  }

  /// Wipes the career. Used by the reset button, after confirmation.
  void reset() {
    _apply({});
    _save();
  }
}
