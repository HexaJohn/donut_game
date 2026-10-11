import 'dart:convert';

import 'package:donut_game/progression/battle_pass.dart';
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
  final Set<int> _claimedTiers = {};
  String _cardPattern = 'pattern.classic';
  String _environment = 'env.theme';
  Emblem _emblem = const Emblem();
  CareerStats stats = CareerStats();

  /// Calendar day of the last first-win bonus, as yyyy-mm-dd.
  String? _lastDailyWin;

  int get xp => _xp;
  int get crumbs => _crumbs;
  int get glaze => _glaze;
  Rank get rank => rankFor(_xp);
  Rank? get nextRank => nextRankFor(_xp);
  double get rankProgressValue => rankProgress(_xp);
  int get passTier => passTierFor(_xp);
  Set<String> get owned => Set.unmodifiable(_owned);
  Set<int> get claimedTiers => Set.unmodifiable(_claimedTiers);
  String get cardPattern => _cardPattern;
  String get environment => _environment;
  Emblem get emblem => _emblem;

  bool owns(String id) => _owned.contains(id);
  bool isClaimed(int tier) => _claimedTiers.contains(tier);

  /// Pass tiers unlocked but not yet claimed.
  List<PassTier> get unclaimedTiers =>
      passTiers.where((tier) => tier.tier <= passTier && !_claimedTiers.contains(tier.tier)).toList();

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
    _claimedTiers
      ..clear()
      ..addAll(List<int>.from(json['claimed'] ?? []));
    _cardPattern = json['cardPattern'] ?? _cardPattern;
    _environment = json['environment'] ?? _environment;
    if (!_owned.contains(_cardPattern)) _cardPattern = 'pattern.classic';
    if (!_owned.contains(_environment)) _environment = 'env.theme';
    _emblem = Emblem.fromJson(json['emblem']);
    stats = CareerStats.fromJson(json['stats']);
    _lastDailyWin = json['lastDailyWin'];
  }

  Map<String, dynamic> toJson() => {
        'xp': _xp,
        'crumbs': _crumbs,
        'glaze': _glaze,
        'owned': _owned.toList(),
        'claimed': _claimedTiers.toList(),
        'cardPattern': _cardPattern,
        'environment': _environment,
        'emblem': _emblem.toJson(),
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

  /// Rank-ups pay Glaze on top: one per grade, more at family boundaries.
  int _rankUpGlaze(Rank from, Rank to) {
    var glaze = 0;
    for (var i = from.index + 1; i <= to.index; i++) {
      glaze += ranks[i].family != ranks[i - 1].family ? 2 : 1;
    }
    return glaze;
  }

  /// Adds XP and currency. Returns Glaze paid for any rank-ups.
  int grant({int xp = 0, int crumbs = 0, int glaze = 0}) {
    final before = rank;
    _xp += xp;
    _crumbs += crumbs;
    _glaze += glaze;
    final bonus = _rankUpGlaze(before, rank);
    _glaze += bonus;
    _save();
    return bonus;
  }

  /// Records a finished Donut match and pays [rewards] for it.
  void recordDonutMatch(DonutMatchSummary match, MatchRewards rewards) {
    stats.matches++;
    stats.tricks += match.tricks;
    stats.donuts += match.donuts;
    stats.handsPlayed += match.hands;
    if (match.won) {
      stats.wins++;
      _lastDailyWin = _today();
    }
    grant(xp: rewards.xp, crumbs: rewards.crumbs, glaze: rewards.glaze);
  }

  void recordBadBatch(BadBatchSummary game, MatchRewards rewards) {
    stats.badBatchGames++;
    if (game.won) {
      stats.badBatchWins++;
      _lastDailyWin = _today();
    }
    grant(xp: rewards.xp, crumbs: rewards.crumbs, glaze: rewards.glaze);
  }

  void recordSlots(SlotResult result) {
    stats.slotPulls++;
    if (result.jackpot) stats.jackpots++;
    grant(xp: result.xp, crumbs: result.crumbs, glaze: result.glaze);
  }

  bool canAfford(ShopItem item) => switch (item.currency) {
        Currency.crumbs => _crumbs >= item.price,
        Currency.glaze => _glaze >= item.price,
      };

  /// Buys and equips [item]. False if it's not for sale or can't be afforded.
  bool buy(ShopItem item) {
    if (owns(item.id) || item.passOnly || !canAfford(item)) return false;
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
      case ItemKind.environment:
        _environment = item.id;
      case ItemKind.gadget:
        break;
    }
  }

  /// Wears an owned pattern or environment. Gadgets are always on once owned.
  bool equip(String id) {
    final item = itemById(id);
    if (item == null || !owns(id)) return false;
    _equipIfCosmetic(item);
    _save();
    return true;
  }

  bool isEquipped(String id) => id == _cardPattern || id == _environment;

  void setEmblem(Emblem emblem) {
    _emblem = emblem;
    _save();
  }

  /// Claims the reward of an unlocked pass tier. False if locked or claimed.
  bool claimTier(int tier) {
    if (tier > passTier || _claimedTiers.contains(tier) || tier < 1 || tier > passTierCount) return false;
    final reward = passTiers[tier - 1];
    _claimedTiers.add(tier);
    _crumbs += reward.crumbs;
    _glaze += reward.glaze;
    if (reward.item != null) _owned.add(reward.item!);
    _save();
    return true;
  }

  /// Claims everything that's ready. Returns how many tiers were claimed.
  int claimAll() {
    final ready = unclaimedTiers;
    for (final tier in ready) {
      claimTier(tier.tier);
    }
    return ready.length;
  }

  /// Wipes the career. Used by the reset button, after confirmation.
  void reset() {
    _apply({});
    _save();
  }
}
