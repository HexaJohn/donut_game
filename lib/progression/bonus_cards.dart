import 'dart:math';

/// The post-match bonus: three face-down cards, each hiding a prize. Every
/// card is flipped and every prize is kept, so there's nothing to miss.
enum BonusPrize { crumbs, xp, glaze }

class BonusCard {
  const BonusCard(this.prize, this.amount, {this.rare = false});

  final BonusPrize prize;
  final int amount;

  /// Shown with a gold edge when flipped.
  final bool rare;

  @override
  bool operator ==(Object other) =>
      other is BonusCard && other.prize == prize && other.amount == amount && other.rare == rare;

  @override
  int get hashCode => Object.hash(prize, amount, rare);
}

/// Every prize a card can hide, with how often it comes up; the rarer the
/// richer. Works out to about 32 Crumbs, 13 XP and 1 Glaze in 67 draws.
const List<(BonusCard, int)> bonusTable = [
  (BonusCard(BonusPrize.crumbs, 5), 70),
  (BonusCard(BonusPrize.crumbs, 10), 50),
  (BonusCard(BonusPrize.crumbs, 20), 30),
  (BonusCard(BonusPrize.xp, 20), 30),
  (BonusCard(BonusPrize.crumbs, 40), 12),
  (BonusCard(BonusPrize.xp, 60, rare: true), 5),
  (BonusCard(BonusPrize.crumbs, 100, rare: true), 2),
  (BonusCard(BonusPrize.glaze, 1, rare: true), 1),
];

class BonusDraw {
  const BonusDraw(this.cards);

  final List<BonusCard> cards;

  int _total(BonusPrize prize) => cards.where((card) => card.prize == prize).fold(0, (sum, card) => sum + card.amount);

  int get crumbs => _total(BonusPrize.crumbs);
  int get xp => _total(BonusPrize.xp);
  int get glaze => _total(BonusPrize.glaze);
  int get rareCards => cards.where((card) => card.rare).length;
}

BonusCard _drawCard(Random random) {
  final total = bonusTable.fold(0, (sum, entry) => sum + entry.$2);
  var roll = random.nextInt(total);
  for (final (card, weight) in bonusTable) {
    roll -= weight;
    if (roll < 0) return card;
  }
  return bonusTable.first.$1;
}

/// Deals the three cards. [random] decides them before any is flipped.
BonusDraw drawBonusCards(Random random) => BonusDraw([for (var i = 0; i < 3; i++) _drawCard(random)]);
