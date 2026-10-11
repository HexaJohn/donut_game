/// Everything that can be bought or earned: card patterns, table
/// environments and gadgets for the tool tray.
enum ItemKind { cardPattern, environment, gadget }

extension ItemKindInfo on ItemKind {
  String get label => switch (this) {
        ItemKind.cardPattern => 'Card patterns',
        ItemKind.environment => 'Environments',
        ItemKind.gadget => 'Gadgets',
      };

  String get singular => switch (this) {
        ItemKind.cardPattern => 'Card pattern',
        ItemKind.environment => 'Environment',
        ItemKind.gadget => 'Gadget',
      };
}

/// Crumbs are earned every match; Glaze is rare and comes from the battle
/// pass, rank-ups and slot jackpots.
enum Currency { crumbs, glaze }

extension CurrencyInfo on Currency {
  String get label => switch (this) {
        Currency.crumbs => 'Crumbs',
        Currency.glaze => 'Glaze',
      };

  String get symbol => switch (this) {
        Currency.crumbs => 'cR',
        Currency.glaze => 'GL',
      };
}

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    this.price = 0,
    this.currency = Currency.crumbs,
    this.passOnly = false,
  });

  /// Stored in the profile; never rename.
  final String id;
  final String name;
  final String description;
  final ItemKind kind;
  final int price;
  final Currency currency;

  /// Only earned from the battle pass, never sold.
  final bool passOnly;

  bool get rare => currency == Currency.glaze;
}

/// Items everyone has from the start.
const Set<String> starterItems = {'pattern.classic', 'env.theme'};

const List<ShopItem> catalog = [
  // Card patterns
  ShopItem(
      id: 'pattern.classic',
      name: 'Classic',
      description: 'Lattice and a little donut.',
      kind: ItemKind.cardPattern),
  ShopItem(
      id: 'pattern.dots',
      name: 'Polka',
      description: 'Rows of neat dots.',
      kind: ItemKind.cardPattern,
      price: 300),
  ShopItem(
      id: 'pattern.chevrons', name: 'Chevrons', description: 'Sharp zig-zags.', kind: ItemKind.cardPattern, price: 350),
  ShopItem(
      id: 'pattern.waves', name: 'Waves', description: 'Rolling ripples.', kind: ItemKind.cardPattern, price: 400),
  ShopItem(
      id: 'pattern.sprinkles',
      name: 'Sprinkles',
      description: 'Scattered hundreds and thousands.',
      kind: ItemKind.cardPattern,
      price: 500),
  ShopItem(
      id: 'pattern.hexes', name: 'Honeycomb', description: 'Tiled hexagons.', kind: ItemKind.cardPattern, price: 550),
  ShopItem(
      id: 'pattern.stars', name: 'Starfield', description: 'A sky of tiny stars.', kind: ItemKind.cardPattern, price: 600),
  ShopItem(
      id: 'pattern.plaid', name: 'Plaid', description: 'Picnic blanket.', kind: ItemKind.cardPattern, price: 700),
  ShopItem(
      id: 'pattern.circuit',
      name: 'Circuit',
      description: 'Traces and solder pads.',
      kind: ItemKind.cardPattern,
      price: 900),
  ShopItem(
      id: 'pattern.argyle', name: 'Argyle', description: 'Golf club chic.', kind: ItemKind.cardPattern, price: 1000),
  ShopItem(
      id: 'pattern.filigree',
      name: 'Filigree',
      description: 'Ornate scrollwork, fit for a casino.',
      kind: ItemKind.cardPattern,
      price: 6,
      currency: Currency.glaze),
  ShopItem(
      id: 'pattern.galaxy',
      name: 'Galaxy',
      description: 'Swirling nebula.',
      kind: ItemKind.cardPattern,
      price: 8,
      currency: Currency.glaze),
  ShopItem(
      id: 'pattern.bakers_seal',
      name: 'Baker\'s Seal',
      description: 'Stamped and approved. Battle pass reward.',
      kind: ItemKind.cardPattern,
      passOnly: true),
  ShopItem(
      id: 'pattern.midnight_glaze',
      name: 'Midnight Glaze',
      description: 'Dripping with it. Battle pass reward.',
      kind: ItemKind.cardPattern,
      passOnly: true),

  // Environments
  ShopItem(
      id: 'env.theme',
      name: 'House Felt',
      description: 'Whatever your theme says.',
      kind: ItemKind.environment),
  ShopItem(
      id: 'env.blue', name: 'Blue Felt', description: 'Cool and calm.', kind: ItemKind.environment, price: 400),
  ShopItem(
      id: 'env.red', name: 'Red Felt', description: 'Poker night.', kind: ItemKind.environment, price: 400),
  ShopItem(
      id: 'env.purple', name: 'Royal Felt', description: 'Deep purple.', kind: ItemKind.environment, price: 450),
  ShopItem(
      id: 'env.oak', name: 'Oak Table', description: 'Bare wood, no felt.', kind: ItemKind.environment, price: 800),
  ShopItem(
      id: 'env.marble',
      name: 'Marble',
      description: 'Cold, white and veined.',
      kind: ItemKind.environment,
      price: 1000),
  ShopItem(
      id: 'env.slate', name: 'Slate', description: 'Dark stone.', kind: ItemKind.environment, price: 900),
  ShopItem(
      id: 'env.carbon', name: 'Carbon Fibre', description: 'Woven and glossy.', kind: ItemKind.environment, price: 1200),
  ShopItem(
      id: 'env.denim', name: 'Denim', description: 'Faded blue jeans.', kind: ItemKind.environment, price: 700),
  ShopItem(
      id: 'env.grid',
      name: 'Neon Grid',
      description: 'Perspective lines to the horizon.',
      kind: ItemKind.environment,
      price: 1500),
  ShopItem(
      id: 'env.galaxy',
      name: 'Deep Space',
      description: 'Play among the stars.',
      kind: ItemKind.environment,
      price: 10,
      currency: Currency.glaze),
  ShopItem(
      id: 'env.gold',
      name: 'Gold Leaf',
      description: 'Obscenely expensive looking.',
      kind: ItemKind.environment,
      price: 12,
      currency: Currency.glaze),
  ShopItem(
      id: 'env.bakery',
      name: 'Bakery Counter',
      description: 'Checkered tiles and flour dust. Battle pass reward.',
      kind: ItemKind.environment,
      passOnly: true),

  // Gadgets
  ShopItem(
      id: 'gadget.markers_neon',
      name: 'Neon Markers',
      description: 'Four extra markers: hot pink, violet, orange and cyan.',
      kind: ItemKind.gadget,
      price: 600),
  ShopItem(
      id: 'gadget.markers_pastel',
      name: 'Pastel Markers',
      description: 'Four soft markers: mint, lavender, peach and sky. Battle pass reward.',
      kind: ItemKind.gadget,
      passOnly: true),
  ShopItem(
      id: 'gadget.marker_gold',
      name: 'Gold Marker',
      description: 'One marker. Metallic gold ink.',
      kind: ItemKind.gadget,
      price: 5,
      currency: Currency.glaze),
  ShopItem(
      id: 'gadget.stamp',
      name: 'Donut Stamp',
      description: 'Stamps a donut on the table in your marker colour. Everyone sees it.',
      kind: ItemKind.gadget,
      price: 800),
  ShopItem(
      id: 'gadget.confetti',
      name: 'Confetti Cannon',
      description: 'Celebrate anything. Click the table for a burst.',
      kind: ItemKind.gadget,
      price: 1200),
  ShopItem(
      id: 'gadget.speedloader',
      name: 'Speedloader',
      description: 'The revolver holds twelve rounds instead of six.',
      kind: ItemKind.gadget,
      price: 1500),
];

ShopItem? itemById(String id) {
  for (final item in catalog) {
    if (item.id == id) return item;
  }
  return null;
}

List<ShopItem> itemsOfKind(ItemKind kind) => catalog.where((item) => item.kind == kind).toList();
