import 'package:donut_copy/donut_copy.dart';

/// Everything that can be bought or earned: card backs, card faces, table
/// environments and gadgets for the tool tray.
enum ItemKind { cardPattern, cardFace, environment, gadget }

extension ItemKindInfo on ItemKind {
  String get label => switch (this) {
        ItemKind.cardPattern => shopKindPatterns(),
        ItemKind.cardFace => shopKindFaces(),
        ItemKind.environment => shopKindEnvironments(),
        ItemKind.gadget => shopKindGadgets(),
      };

  String get singular => switch (this) {
        ItemKind.cardPattern => shopKindPattern(),
        ItemKind.cardFace => shopKindFace(),
        ItemKind.environment => shopKindEnvironment(),
        ItemKind.gadget => shopKindGadget(),
      };
}

/// Crumbs are earned every match; Glaze is rare and comes from rank-ups and
/// slot jackpots.
enum Currency { crumbs, glaze }

extension CurrencyInfo on Currency {
  String get label => switch (this) {
        Currency.crumbs => shopCrumbs(),
        Currency.glaze => shopGlaze(),
      };

  String get symbol => switch (this) {
        Currency.crumbs => shopCrumbsSymbol(),
        Currency.glaze => shopGlazeSymbol(),
      };
}

class ShopItem {
  const ShopItem({
    required this.id,
    required this.nameLine,
    required this.descriptionLine,
    required this.kind,
    this.price = 0,
    this.currency = Currency.crumbs,
    this.rankOnly = false,
    this.rank = 0,
    this.requires,
  });

  /// Stored in the profile; never rename.
  final String id;
  final Line nameLine;
  final Line descriptionLine;

  String get name => nameLine();
  String get description => descriptionLine();
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
      id: 'pattern.classic',
      nameLine: shopPatternClassicName,
      descriptionLine: shopPatternClassicDescription,
      kind: ItemKind.cardPattern),
  ShopItem(
      id: 'pattern.dots',
      nameLine: shopPatternDotsName,
      descriptionLine: shopPatternDotsDescription,
      kind: ItemKind.cardPattern,
      price: 300,
      rank: 1),
  ShopItem(
      id: 'pattern.chevrons',
      nameLine: shopPatternChevronsName,
      descriptionLine: shopPatternChevronsDescription,
      kind: ItemKind.cardPattern,
      price: 350,
      rank: 2),
  ShopItem(
      id: 'pattern.waves',
      nameLine: shopPatternWavesName,
      descriptionLine: shopPatternWavesDescription,
      kind: ItemKind.cardPattern,
      price: 400,
      rank: 4),
  ShopItem(
      id: 'pattern.sprinkles',
      nameLine: shopPatternSprinklesName,
      descriptionLine: shopPatternSprinklesDescription,
      kind: ItemKind.cardPattern,
      price: 500,
      rank: 6),
  ShopItem(
      id: 'pattern.hexes',
      nameLine: shopPatternHexesName,
      descriptionLine: shopPatternHexesDescription,
      kind: ItemKind.cardPattern,
      price: 550,
      rank: 8),
  ShopItem(
      id: 'pattern.stars',
      nameLine: shopPatternStarsName,
      descriptionLine: shopPatternStarsDescription,
      kind: ItemKind.cardPattern,
      price: 600,
      rank: 10),
  ShopItem(
      id: 'pattern.plaid',
      nameLine: shopPatternPlaidName,
      descriptionLine: shopPatternPlaidDescription,
      kind: ItemKind.cardPattern,
      price: 700,
      rank: 13),
  ShopItem(
      id: 'pattern.circuit',
      nameLine: shopPatternCircuitName,
      descriptionLine: shopPatternCircuitDescription,
      kind: ItemKind.cardPattern,
      price: 900,
      rank: 16),
  ShopItem(
      id: 'pattern.argyle',
      nameLine: shopPatternArgyleName,
      descriptionLine: shopPatternArgyleDescription,
      kind: ItemKind.cardPattern,
      price: 1000,
      rank: 19),
  ShopItem(
      id: 'pattern.filigree',
      nameLine: shopPatternFiligreeName,
      descriptionLine: shopPatternFiligreeDescription,
      kind: ItemKind.cardPattern,
      price: 6,
      currency: Currency.glaze,
      rank: 22),
  ShopItem(
      id: 'pattern.galaxy',
      nameLine: shopPatternGalaxyName,
      descriptionLine: shopPatternGalaxyDescription,
      kind: ItemKind.cardPattern,
      price: 8,
      currency: Currency.glaze,
      rank: 30),
  ShopItem(
      id: 'pattern.bakers_seal',
      nameLine: shopPatternBakersSealName,
      descriptionLine: shopPatternBakersSealDescription,
      kind: ItemKind.cardPattern,
      rankOnly: true,
      rank: 9),
  ShopItem(
      id: 'pattern.midnight_glaze',
      nameLine: shopPatternMidnightGlazeName,
      descriptionLine: shopPatternMidnightGlazeDescription,
      kind: ItemKind.cardPattern,
      rankOnly: true,
      rank: 27),

  // Card faces
  ShopItem(
      id: 'face.classic',
      nameLine: shopFaceClassicName,
      descriptionLine: shopFaceClassicDescription,
      kind: ItemKind.cardFace),
  ShopItem(
      id: 'face.four_colour',
      nameLine: shopFaceFourColourName,
      descriptionLine: shopFaceFourColourDescription,
      kind: ItemKind.cardFace,
      price: 300,
      rank: 2),
  ShopItem(
      id: 'face.jumbo',
      nameLine: shopFaceJumboName,
      descriptionLine: shopFaceJumboDescription,
      kind: ItemKind.cardFace,
      price: 500,
      rank: 6),
  ShopItem(
      id: 'face.parlour',
      nameLine: shopFaceParlourName,
      descriptionLine: shopFaceParlourDescription,
      kind: ItemKind.cardFace,
      price: 700,
      rank: 11),
  ShopItem(
      id: 'face.terminal',
      nameLine: shopFaceTerminalName,
      descriptionLine: shopFaceTerminalDescription,
      kind: ItemKind.cardFace,
      price: 800,
      rank: 14),
  ShopItem(
      id: 'face.sprinkle',
      nameLine: shopFaceSprinkleName,
      descriptionLine: shopFaceSprinkleDescription,
      kind: ItemKind.cardFace,
      price: 1100,
      rank: 23),
  ShopItem(
      id: 'face.neon',
      nameLine: shopFaceNeonName,
      descriptionLine: shopFaceNeonDescription,
      kind: ItemKind.cardFace,
      price: 7,
      currency: Currency.glaze,
      rank: 28),
  ShopItem(
      id: 'face.gilded',
      nameLine: shopFaceGildedName,
      descriptionLine: shopFaceGildedDescription,
      kind: ItemKind.cardFace,
      rankOnly: true,
      rank: 36),

  // Environments
  ShopItem(
      id: 'env.theme',
      nameLine: shopEnvThemeName,
      descriptionLine: shopEnvThemeDescription,
      kind: ItemKind.environment),
  ShopItem(
      id: 'env.blue',
      nameLine: shopEnvBlueName,
      descriptionLine: shopEnvBlueDescription,
      kind: ItemKind.environment,
      price: 400,
      rank: 1),
  ShopItem(
      id: 'env.red',
      nameLine: shopEnvRedName,
      descriptionLine: shopEnvRedDescription,
      kind: ItemKind.environment,
      price: 400,
      rank: 3),
  ShopItem(
      id: 'env.purple',
      nameLine: shopEnvPurpleName,
      descriptionLine: shopEnvPurpleDescription,
      kind: ItemKind.environment,
      price: 450,
      rank: 5),
  ShopItem(
      id: 'env.oak',
      nameLine: shopEnvOakName,
      descriptionLine: shopEnvOakDescription,
      kind: ItemKind.environment,
      price: 800,
      rank: 11),
  ShopItem(
      id: 'env.marble',
      nameLine: shopEnvMarbleName,
      descriptionLine: shopEnvMarbleDescription,
      kind: ItemKind.environment,
      price: 1000,
      rank: 17),
  ShopItem(
      id: 'env.slate',
      nameLine: shopEnvSlateName,
      descriptionLine: shopEnvSlateDescription,
      kind: ItemKind.environment,
      price: 900,
      rank: 14),
  ShopItem(
      id: 'env.carbon',
      nameLine: shopEnvCarbonName,
      descriptionLine: shopEnvCarbonDescription,
      kind: ItemKind.environment,
      price: 1200,
      rank: 20),
  ShopItem(
      id: 'env.denim',
      nameLine: shopEnvDenimName,
      descriptionLine: shopEnvDenimDescription,
      kind: ItemKind.environment,
      price: 700,
      rank: 7),
  ShopItem(
      id: 'env.grid',
      nameLine: shopEnvGridName,
      descriptionLine: shopEnvGridDescription,
      kind: ItemKind.environment,
      price: 1500,
      rank: 24),
  ShopItem(
      id: 'env.galaxy',
      nameLine: shopEnvGalaxyName,
      descriptionLine: shopEnvGalaxyDescription,
      kind: ItemKind.environment,
      price: 10,
      currency: Currency.glaze,
      rank: 33),
  ShopItem(
      id: 'env.gold',
      nameLine: shopEnvGoldName,
      descriptionLine: shopEnvGoldDescription,
      kind: ItemKind.environment,
      price: 12,
      currency: Currency.glaze,
      rank: 39),
  ShopItem(
      id: 'env.bakery',
      nameLine: shopEnvBakeryName,
      descriptionLine: shopEnvBakeryDescription,
      kind: ItemKind.environment,
      rankOnly: true,
      rank: 18),

  // Gadgets
  ShopItem(
      id: 'gadget.markers',
      nameLine: shopGadgetMarkersName,
      descriptionLine: shopGadgetMarkersDescription,
      kind: ItemKind.gadget,
      price: 150,
      rank: 1),
  ShopItem(
      id: 'gadget.revolver',
      nameLine: shopGadgetRevolverName,
      descriptionLine: shopGadgetRevolverDescription,
      kind: ItemKind.gadget,
      price: 400,
      rank: 4),
  ShopItem(
      id: 'gadget.flashbang',
      nameLine: shopGadgetFlashbangName,
      descriptionLine: shopGadgetFlashbangDescription,
      kind: ItemKind.gadget,
      price: 600,
      rank: 7),
  ShopItem(
      id: 'gadget.markers_neon',
      nameLine: shopGadgetMarkersNeonName,
      descriptionLine: shopGadgetMarkersNeonDescription,
      kind: ItemKind.gadget,
      price: 600,
      rank: 3,
      requires: 'gadget.markers'),
  ShopItem(
      id: 'gadget.markers_pastel',
      nameLine: shopGadgetMarkersPastelName,
      descriptionLine: shopGadgetMarkersPastelDescription,
      kind: ItemKind.gadget,
      rankOnly: true,
      rank: 12,
      requires: 'gadget.markers'),
  ShopItem(
      id: 'gadget.marker_gold',
      nameLine: shopGadgetMarkerGoldName,
      descriptionLine: shopGadgetMarkerGoldDescription,
      kind: ItemKind.gadget,
      price: 5,
      currency: Currency.glaze,
      rank: 21,
      requires: 'gadget.markers'),
  ShopItem(
      id: 'gadget.stamp',
      nameLine: shopGadgetStampName,
      descriptionLine: shopGadgetStampDescription,
      kind: ItemKind.gadget,
      price: 800,
      rank: 10),
  ShopItem(
      id: 'gadget.confetti',
      nameLine: shopGadgetConfettiName,
      descriptionLine: shopGadgetConfettiDescription,
      kind: ItemKind.gadget,
      price: 1200,
      rank: 15),
  ShopItem(
      id: 'gadget.speedloader',
      nameLine: shopGadgetSpeedloaderName,
      descriptionLine: shopGadgetSpeedloaderDescription,
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
