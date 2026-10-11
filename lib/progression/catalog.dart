/// Everything that can be bought or earned: card backs, card faces, table
/// environments and gadgets for the tool tray.
enum ItemKind { cardPattern, cardFace, environment, gadget }

extension ItemKindInfo on ItemKind {
  String get label => switch (this) {
        ItemKind.cardPattern => 'Card patterns',
        ItemKind.cardFace => 'Card faces',
        ItemKind.environment => 'Environments',
        ItemKind.gadget => 'Gadgets',
      };

  String get singular => switch (this) {
        ItemKind.cardPattern => 'Card pattern',
        ItemKind.cardFace => 'Card face',
        ItemKind.environment => 'Environment',
        ItemKind.gadget => 'Gadget',
      };
}

/// Crumbs are earned every match; Glaze is rare and comes from rank-ups and
/// slot jackpots.
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
    this.rankOnly = false,
    this.rank = 0,
    this.requires,
  });

  /// Stored in the profile; never rename.
  final String id;
  final String name;
  final String description;
  final ItemKind kind;
  final int price;
  final Currency currency;

  /// Only earned by ranking up, never sold.
  final bool rankOnly;

  /// Index of the rank that unlocks it: for sale from then on, or handed
  /// over then if [rankOnly].
  final int rank;

  /// Another item that must be owned first, for upgrades to it.
  final String? requires;

  bool get rare => currency == Currency.glaze;
}

/// Items everyone has from the start.
const Set<String> starterItems = {'pattern.classic', 'face.classic', 'env.theme'};

const List<ShopItem> catalog = [
  // Card patterns
  ShopItem(
      id: 'pattern.classic', name: 'Classic', description: 'Lattice and a little donut.', kind: ItemKind.cardPattern),
  ShopItem(
      id: 'pattern.dots',
      name: 'Polka',
      description: 'Rows of neat dots.',
      kind: ItemKind.cardPattern,
      price: 300,
      rank: 1),
  ShopItem(
      id: 'pattern.chevrons',
      name: 'Chevrons',
      description: 'Sharp zig-zags.',
      kind: ItemKind.cardPattern,
      price: 350,
      rank: 2),
  ShopItem(
      id: 'pattern.waves',
      name: 'Waves',
      description: 'Rolling ripples.',
      kind: ItemKind.cardPattern,
      price: 400,
      rank: 4),
  ShopItem(
      id: 'pattern.sprinkles',
      name: 'Sprinkles',
      description: 'Scattered hundreds and thousands.',
      kind: ItemKind.cardPattern,
      price: 500,
      rank: 6),
  ShopItem(
      id: 'pattern.hexes',
      name: 'Honeycomb',
      description: 'Tiled hexagons.',
      kind: ItemKind.cardPattern,
      price: 550,
      rank: 8),
  ShopItem(
      id: 'pattern.stars',
      name: 'Starfield',
      description: 'A sky of tiny stars.',
      kind: ItemKind.cardPattern,
      price: 600,
      rank: 10),
  ShopItem(
      id: 'pattern.plaid',
      name: 'Plaid',
      description: 'Picnic blanket.',
      kind: ItemKind.cardPattern,
      price: 700,
      rank: 13),
  ShopItem(
      id: 'pattern.circuit',
      name: 'Circuit',
      description: 'Traces and solder pads.',
      kind: ItemKind.cardPattern,
      price: 900,
      rank: 16),
  ShopItem(
      id: 'pattern.argyle',
      name: 'Argyle',
      description: 'Golf club chic.',
      kind: ItemKind.cardPattern,
      price: 1000,
      rank: 19),
  ShopItem(
      id: 'pattern.filigree',
      name: 'Filigree',
      description: 'Ornate scrollwork, fit for a casino.',
      kind: ItemKind.cardPattern,
      price: 6,
      currency: Currency.glaze,
      rank: 22),
  ShopItem(
      id: 'pattern.galaxy',
      name: 'Galaxy',
      description: 'Swirling nebula.',
      kind: ItemKind.cardPattern,
      price: 8,
      currency: Currency.glaze,
      rank: 30),
  ShopItem(
      id: 'pattern.bakers_seal',
      name: 'Baker\'s Seal',
      description: 'Stamped and approved. Rank reward.',
      kind: ItemKind.cardPattern,
      rankOnly: true,
      rank: 9),
  ShopItem(
      id: 'pattern.midnight_glaze',
      name: 'Midnight Glaze',
      description: 'Dripping with it. Rank reward.',
      kind: ItemKind.cardPattern,
      rankOnly: true,
      rank: 27),

  // Card faces
  ShopItem(id: 'face.classic', name: 'Standard', description: 'Clean pips, big corners.', kind: ItemKind.cardFace),
  ShopItem(
      id: 'face.four_colour',
      name: 'Four Colour',
      description: 'Green clubs, blue diamonds. No more misreads.',
      kind: ItemKind.cardFace,
      price: 300,
      rank: 2),
  ShopItem(
      id: 'face.jumbo',
      name: 'Jumbo Index',
      description: 'Corners you can read from across the room.',
      kind: ItemKind.cardFace,
      price: 500,
      rank: 6),
  ShopItem(
      id: 'face.parlour',
      name: 'Parlour',
      description: 'Serif type on cream card stock.',
      kind: ItemKind.cardFace,
      price: 700,
      rank: 11),
  ShopItem(
      id: 'face.terminal',
      name: 'Terminal',
      description: 'Monospaced and framed, like a printout.',
      kind: ItemKind.cardFace,
      price: 800,
      rank: 14),
  ShopItem(
      id: 'face.sprinkle',
      name: 'Sprinkle Edge',
      description: 'Every card rolled in sprinkles.',
      kind: ItemKind.cardFace,
      price: 1100,
      rank: 23),
  ShopItem(
      id: 'face.neon',
      name: 'Neon',
      description: 'Ink that glows like a diner sign.',
      kind: ItemKind.cardFace,
      price: 7,
      currency: Currency.glaze,
      rank: 28),
  ShopItem(
      id: 'face.gilded',
      name: 'Gilded',
      description: 'Gold-trimmed court cards on ivory. Rank reward.',
      kind: ItemKind.cardFace,
      rankOnly: true,
      rank: 36),

  // Environments
  ShopItem(id: 'env.theme', name: 'House Felt', description: 'Whatever your theme says.', kind: ItemKind.environment),
  ShopItem(
      id: 'env.blue',
      name: 'Blue Felt',
      description: 'Cool and calm.',
      kind: ItemKind.environment,
      price: 400,
      rank: 1),
  ShopItem(
      id: 'env.red', name: 'Red Felt', description: 'Poker night.', kind: ItemKind.environment, price: 400, rank: 3),
  ShopItem(
      id: 'env.purple',
      name: 'Royal Felt',
      description: 'Deep purple.',
      kind: ItemKind.environment,
      price: 450,
      rank: 5),
  ShopItem(
      id: 'env.oak',
      name: 'Oak Table',
      description: 'Bare wood, no felt.',
      kind: ItemKind.environment,
      price: 800,
      rank: 11),
  ShopItem(
      id: 'env.marble',
      name: 'Marble',
      description: 'Cold, white and veined.',
      kind: ItemKind.environment,
      price: 1000,
      rank: 17),
  ShopItem(
      id: 'env.slate', name: 'Slate', description: 'Dark stone.', kind: ItemKind.environment, price: 900, rank: 14),
  ShopItem(
      id: 'env.carbon',
      name: 'Carbon Fibre',
      description: 'Woven and glossy.',
      kind: ItemKind.environment,
      price: 1200,
      rank: 20),
  ShopItem(
      id: 'env.denim',
      name: 'Denim',
      description: 'Faded blue jeans.',
      kind: ItemKind.environment,
      price: 700,
      rank: 7),
  ShopItem(
      id: 'env.grid',
      name: 'Neon Grid',
      description: 'Perspective lines to the horizon.',
      kind: ItemKind.environment,
      price: 1500,
      rank: 24),
  ShopItem(
      id: 'env.galaxy',
      name: 'Deep Space',
      description: 'Play among the stars.',
      kind: ItemKind.environment,
      price: 10,
      currency: Currency.glaze,
      rank: 33),
  ShopItem(
      id: 'env.gold',
      name: 'Gold Leaf',
      description: 'Obscenely expensive looking.',
      kind: ItemKind.environment,
      price: 12,
      currency: Currency.glaze,
      rank: 39),
  ShopItem(
      id: 'env.bakery',
      name: 'Bakery Counter',
      description: 'Checkered tiles and flour dust. Rank reward.',
      kind: ItemKind.environment,
      rankOnly: true,
      rank: 18),

  // Gadgets
  ShopItem(
      id: 'gadget.markers',
      name: 'Marker Set',
      description: 'Five markers and an eraser. Doodle on the felt; everyone sees it.',
      kind: ItemKind.gadget,
      price: 150,
      rank: 1),
  ShopItem(
      id: 'gadget.revolver',
      name: 'Revolver',
      description: 'Six rounds. Shoot the table or a rival\'s placard.',
      kind: ItemKind.gadget,
      price: 400,
      rank: 4),
  ShopItem(
      id: 'gadget.flashbang',
      name: 'Flashbang',
      description: 'Lob it on the table and white out every screen. Needs a moment to recharge.',
      kind: ItemKind.gadget,
      price: 600,
      rank: 7),
  ShopItem(
      id: 'gadget.markers_neon',
      name: 'Neon Markers',
      description: 'Four extra markers: hot pink, violet, orange and cyan.',
      kind: ItemKind.gadget,
      price: 600,
      rank: 3,
      requires: 'gadget.markers'),
  ShopItem(
      id: 'gadget.markers_pastel',
      name: 'Pastel Markers',
      description: 'Four soft markers: mint, lavender, peach and sky. Rank reward.',
      kind: ItemKind.gadget,
      rankOnly: true,
      rank: 12,
      requires: 'gadget.markers'),
  ShopItem(
      id: 'gadget.marker_gold',
      name: 'Gold Marker',
      description: 'One marker. Metallic gold ink.',
      kind: ItemKind.gadget,
      price: 5,
      currency: Currency.glaze,
      rank: 21,
      requires: 'gadget.markers'),
  ShopItem(
      id: 'gadget.stamp',
      name: 'Donut Stamp',
      description: 'Stamps a donut on the table in your marker colour. Everyone sees it.',
      kind: ItemKind.gadget,
      price: 800,
      rank: 10),
  ShopItem(
      id: 'gadget.confetti',
      name: 'Confetti Cannon',
      description: 'Celebrate anything. Click the table for a burst.',
      kind: ItemKind.gadget,
      price: 1200,
      rank: 15),
  ShopItem(
      id: 'gadget.speedloader',
      name: 'Speedloader',
      description: 'The revolver holds twelve rounds instead of six.',
      kind: ItemKind.gadget,
      price: 1500,
      rank: 25,
      requires: 'gadget.revolver'),
];

ShopItem? itemById(String id) {
  for (final item in catalog) {
    if (item.id == id) return item;
  }
  return null;
}

List<ShopItem> itemsOfKind(ItemKind kind) => catalog.where((item) => item.kind == kind).toList();

/// A deck for a bot, picked from the cheaper shop items so every seat's
/// cards look different. The same name always gets the same deck.
({String back, String face}) botDeck(String name) {
  List<ShopItem> pool(ItemKind kind) =>
      itemsOfKind(kind).where((item) => !item.rankOnly && item.currency == Currency.crumbs).toList();
  final backs = pool(ItemKind.cardPattern);
  final faces = pool(ItemKind.cardFace);
  // String.hashCode isn't stable across runs; this is
  final hash = name.codeUnits.fold(17, (h, c) => (h * 31 + c) & 0x3fffffff);
  return (back: backs[hash % backs.length].id, face: faces[(hash ~/ 7) % faces.length].id);
}
