import 'dart:math';

import 'package:donut_copy/donut_copy.dart';

/// The post-match slot machine: three reels, one pull, a bonus on top of
/// whatever the match paid.
enum SlotSymbol { crumb, cherry, sprinkle, bar, seven, glaze, donut }

extension SlotSymbolInfo on SlotSymbol {
  String get label => switch (this) {
        SlotSymbol.crumb => shopSymbolCrumb(),
        SlotSymbol.cherry => shopSymbolCherry(),
        SlotSymbol.sprinkle => shopSymbolSprinkle(),
        SlotSymbol.bar => shopSymbolBar(),
        SlotSymbol.seven => shopSymbolSeven(),
        SlotSymbol.glaze => shopSymbolGlaze(),
        SlotSymbol.donut => shopSymbolDonut(),
      };
}

/// How often each symbol comes up on a reel; the rarer the richer.
const Map<SlotSymbol, int> slotWeights = {
  SlotSymbol.crumb: 30,
  SlotSymbol.cherry: 22,
  SlotSymbol.sprinkle: 18,
  SlotSymbol.bar: 14,
  SlotSymbol.seven: 8,
  SlotSymbol.glaze: 5,
  SlotSymbol.donut: 3,
};

class SlotResult {
  const SlotResult({required this.reels, required this.label, this.crumbs = 0, this.glaze = 0, this.xp = 0});

  final List<SlotSymbol> reels;
  final String label;
  final int crumbs;
  final int glaze;
  final int xp;

  bool get jackpot => reels.every((s) => s == SlotSymbol.donut);
  bool get triple => reels.toSet().length == 1;
}

SlotSymbol _spinReel(Random random) {
  final total = slotWeights.values.reduce((a, b) => a + b);
  var roll = random.nextInt(total);
  for (final entry in slotWeights.entries) {
    roll -= entry.value;
    if (roll < 0) return entry.key;
  }
  return SlotSymbol.crumb;
}

/// Pulls the lever. [random] decides the reels; the payout follows from them.
SlotResult rollSlots(Random random) => payout([_spinReel(random), _spinReel(random), _spinReel(random)]);

/// What [reels] are worth.
SlotResult payout(List<SlotSymbol> reels) {
  final counts = <SlotSymbol, int>{};
  for (final symbol in reels) {
    counts[symbol] = (counts[symbol] ?? 0) + 1;
  }
  if (counts.length == 1) {
    return switch (reels.first) {
      SlotSymbol.donut => SlotResult(reels: reels, label: shopSlotJackpot(), crumbs: 1000, glaze: 5, xp: 300),
      SlotSymbol.glaze => SlotResult(reels: reels, label: shopSlotTripleGlaze(), crumbs: 300, glaze: 3),
      SlotSymbol.seven => SlotResult(reels: reels, label: shopSlotLuckySevens(), crumbs: 777),
      SlotSymbol.bar => SlotResult(reels: reels, label: shopSlotTripleBar(), crumbs: 400),
      SlotSymbol.sprinkle => SlotResult(reels: reels, label: shopSlotTripleSprinkle(), crumbs: 250),
      SlotSymbol.cherry => SlotResult(reels: reels, label: shopSlotTripleCherry(), crumbs: 150),
      SlotSymbol.crumb => SlotResult(reels: reels, label: shopSlotTripleCrumb(), crumbs: 75),
    };
  }
  if (counts[SlotSymbol.donut] == 2) return SlotResult(reels: reels, label: shopSlotTwoDonuts(), crumbs: 150);
  if (counts[SlotSymbol.glaze] == 2) return SlotResult(reels: reels, label: shopSlotTwoGlaze(), crumbs: 100, glaze: 1);
  if (counts.length == 2) return SlotResult(reels: reels, label: shopSlotAPair(), crumbs: 40);
  return SlotResult(reels: reels, label: shopSlotCrumbs(), crumbs: 10);
}
