/// The free battle pass: a ladder of tiers unlocked with XP, each with a
/// reward to claim.
class PassTier {
  const PassTier({required this.tier, required this.xp, this.crumbs = 0, this.glaze = 0, this.item});

  /// 1-based.
  final int tier;

  /// Total XP needed to unlock.
  final int xp;
  final int crumbs;
  final int glaze;

  /// Catalog id, if the tier gives an item.
  final String? item;
}

const String passName = 'Season 1: Fresh Batch';
const int passTierCount = 30;

/// XP to reach [tier]: gentle at first, steeper later.
int passXpFor(int tier) => 300 * tier + 20 * tier * tier;

final List<PassTier> passTiers = [
  for (var tier = 1; tier <= passTierCount; tier++) _tier(tier),
];

PassTier _tier(int tier) {
  final xp = passXpFor(tier);
  // Items on the milestones; Glaze every fifth tier; Crumbs on the rest
  return switch (tier) {
    5 => PassTier(tier: tier, xp: xp, glaze: 2, crumbs: 200),
    10 => PassTier(tier: tier, xp: xp, item: 'pattern.bakers_seal', glaze: 1),
    15 => PassTier(tier: tier, xp: xp, item: 'gadget.markers_pastel', glaze: 2),
    20 => PassTier(tier: tier, xp: xp, item: 'env.bakery', glaze: 2),
    25 => PassTier(tier: tier, xp: xp, glaze: 5, crumbs: 500),
    30 => PassTier(tier: tier, xp: xp, item: 'pattern.midnight_glaze', glaze: 8, crumbs: 1000),
    _ => tier % 5 == 0
        ? PassTier(tier: tier, xp: xp, glaze: 2)
        : PassTier(tier: tier, xp: xp, crumbs: 150 + 25 * tier),
  };
}

/// Tiers unlocked with [xp] total XP.
int passTierFor(int xp) {
  var unlocked = 0;
  for (final tier in passTiers) {
    if (xp >= tier.xp) unlocked = tier.tier;
  }
  return unlocked;
}

/// 0..1 of the way to the next tier; 1 when the pass is complete.
double passProgress(int xp) {
  final current = passTierFor(xp);
  if (current >= passTierCount) return 1;
  final from = current == 0 ? 0 : passTiers[current - 1].xp;
  final to = passTiers[current].xp;
  return ((xp - from) / (to - from)).clamp(0.0, 1.0);
}
