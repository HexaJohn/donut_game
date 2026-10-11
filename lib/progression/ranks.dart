import 'package:donut_game/progression/catalog.dart';

/// Career ranks, Halo Reach style: a long ladder of named grades climbed with
/// XP. Spending never costs rank; only XP counts.
class Rank {
  const Rank({required this.index, required this.family, required this.name, required this.grade, required this.xp});

  /// Position on the ladder, 0 for the first rank.
  final int index;

  /// Which named family this grade belongs to, 0 for the first.
  final int family;
  final String name;

  /// 0 when the family has a single grade, else 1..3.
  final int grade;

  /// Total XP needed to hold this rank.
  final int xp;

  String get title => grade == 0 ? name : '$name ${_roman[grade]}';

  @override
  String toString() => title;
}

const _roman = ['', 'I', 'II', 'III'];

/// Rank families in order, with how many grades each has.
const List<(String, int)> rankFamilies = [
  ('Crumb', 1),
  ('Sprinkle', 2),
  ('Glazed', 3),
  ('Frosted', 3),
  ('Jelly', 3),
  ('Cruller', 3),
  ('Fritter', 3),
  ('Long John', 3),
  ('Old Fashioned', 3),
  ('Boston Cream', 3),
  ('Beignet', 3),
  ('Baker', 3),
  ('Head Baker', 3),
  ('Pastry Chef', 3),
  ('Dozen', 2),
  ('Baker\'s Dozen', 2),
  ('Legend', 2),
  ('Mythic', 1),
  ('Inheritor', 1),
];

/// XP from one rank to the next grows the further up you are.
int _step(int index) => 250 + 60 * index;

final List<Rank> ranks = () {
  final list = <Rank>[];
  var xp = 0;
  var family = 0;
  for (final (name, grades) in rankFamilies) {
    for (var grade = 1; grade <= grades; grade++) {
      final index = list.length;
      if (index > 0) xp += _step(index - 1);
      list.add(Rank(index: index, family: family, name: name, grade: grades == 1 ? 0 : grade, xp: xp));
    }
    family++;
  }
  return list;
}();

Rank get maxRank => ranks.last;

/// The rank held with [xp] total XP.
Rank rankFor(int xp) {
  var held = ranks.first;
  for (final rank in ranks) {
    if (xp >= rank.xp) held = rank;
  }
  return held;
}

/// The rank after the one held with [xp], or null at the top.
Rank? nextRankFor(int xp) {
  final held = rankFor(xp);
  return held.index + 1 < ranks.length ? ranks[held.index + 1] : null;
}

/// 0..1 of the way from the held rank to the next; 1 at the top.
double rankProgress(int xp) {
  final held = rankFor(xp);
  final next = nextRankFor(xp);
  if (next == null) return 1;
  return ((xp - held.xp) / (next.xp - held.xp)).clamp(0.0, 1.0);
}

/// What reaching a rank pays, banked automatically on rank-up.
class RankReward {
  const RankReward({this.crumbs = 0, this.glaze = 0, this.item});

  final int crumbs;
  final int glaze;

  /// Catalog id, if the rank gives an item.
  final String? item;
}

/// Catalog items unlocked by reaching [rank]: shop items go on sale,
/// rank-only ones are handed over.
List<ShopItem> itemsUnlockedAt(Rank rank) => catalog.where((item) => item.rank == rank.index).toList();

/// The rank that unlocks [item].
Rank unlockRank(ShopItem item) => ranks[item.rank];

/// Crumbs on every rank, growing with the ladder; Glaze too, doubled when a
/// new family starts, with a big payout at the very top.
RankReward rankReward(Rank rank) {
  if (rank.index == 0) return const RankReward();
  final newFamily = rank.family != ranks[rank.index - 1].family;
  final glaze = switch (rank) {
    _ when rank == maxRank => 10,
    _ when rank.index == ranks.length - 2 => 5,
    _ => newFamily ? 2 : 1,
  };
  final item = itemsUnlockedAt(rank).where((item) => item.rankOnly).firstOrNull;
  return RankReward(crumbs: 100 + 10 * rank.index, glaze: glaze, item: item?.id);
}
