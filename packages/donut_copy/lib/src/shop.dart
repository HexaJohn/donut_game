import 'line.dart';

// Shop and career: codes S1, S2, ... Never reuse or renumber a code: the
// text file refers to them. Add new ones at the end.

const shopKindPatterns = Line('S1', 'Card patterns');
const shopKindFaces = Line('S2', 'Card faces');
const shopKindEnvironments = Line('S3', 'Environments');
const shopKindGadgets = Line('S4', 'Gadgets');
const shopKindPattern = Line('S5', 'Card pattern');
const shopKindFace = Line('S6', 'Card face');
const shopKindEnvironment = Line('S7', 'Environment');
const shopKindGadget = Line('S8', 'Gadget');
const shopCrumbs = Line('S9', 'Crumbs');
const shopGlaze = Line('S10', 'Glaze');
const shopCrumbsSymbol = Line('S11', 'cR');
const shopGlazeSymbol = Line('S12', 'GL');
const shopPatternClassicName = Line('S13', 'Classic');
const shopPatternClassicDescription = Line('S14', 'Lattice and a little donut.');
const shopPatternDotsName = Line('S15', 'Polka');
const shopPatternDotsDescription = Line('S16', 'Rows of neat dots.');
const shopPatternChevronsName = Line('S17', 'Chevrons');
const shopPatternChevronsDescription = Line('S18', 'Sharp zig-zags.');
const shopPatternWavesName = Line('S19', 'Waves');
const shopPatternWavesDescription = Line('S20', 'Rolling ripples.');
const shopPatternSprinklesName = Line('S21', 'Sprinkles');
const shopPatternSprinklesDescription = Line('S22', 'Scattered hundreds and thousands.');
const shopPatternHexesName = Line('S23', 'Honeycomb');
const shopPatternHexesDescription = Line('S24', 'Tiled hexagons.');
const shopPatternStarsName = Line('S25', 'Starfield');
const shopPatternStarsDescription = Line('S26', 'A sky of tiny stars.');
const shopPatternPlaidName = Line('S27', 'Plaid');
const shopPatternPlaidDescription = Line('S28', 'Picnic blanket.');
const shopPatternCircuitName = Line('S29', 'Circuit');
const shopPatternCircuitDescription = Line('S30', 'Traces and solder pads.');
const shopPatternArgyleName = Line('S31', 'Argyle');
const shopPatternArgyleDescription = Line('S32', 'Golf club chic.');
const shopPatternFiligreeName = Line('S33', 'Filigree');
const shopPatternFiligreeDescription = Line('S34', 'Ornate scrollwork, fit for a casino.');
const shopPatternGalaxyName = Line('S35', 'Galaxy');
const shopPatternGalaxyDescription = Line('S36', 'Swirling nebula.');
const shopPatternBakersSealName = Line('S37', 'Baker\'s Seal');
const shopPatternBakersSealDescription = Line('S38', 'Stamped and approved. Rank reward.');
const shopPatternMidnightGlazeName = Line('S39', 'Midnight Glaze');
const shopPatternMidnightGlazeDescription = Line('S40', 'Dripping with it. Rank reward.');
const shopFaceClassicName = Line('S41', 'Standard');
const shopFaceClassicDescription = Line('S42', 'Clean pips, big corners.');
const shopFaceFourColourName = Line('S43', 'Four Colour');
const shopFaceFourColourDescription = Line('S44', 'Green clubs, blue diamonds. No more misreads.');
const shopFaceJumboName = Line('S45', 'Jumbo Index');
const shopFaceJumboDescription = Line('S46', 'Corners you can read from across the room.');
const shopFaceParlourName = Line('S47', 'Parlour');
const shopFaceParlourDescription = Line('S48', 'Serif type on cream card stock.');
const shopFaceTerminalName = Line('S49', 'Terminal');
const shopFaceTerminalDescription = Line('S50', 'Monospaced and framed, like a printout.');
const shopFaceSprinkleName = Line('S51', 'Sprinkle Edge');
const shopFaceSprinkleDescription = Line('S52', 'Every card rolled in sprinkles.');
const shopFaceNeonName = Line('S53', 'Neon');
const shopFaceNeonDescription = Line('S54', 'Ink that glows like a diner sign.');
const shopFaceGildedName = Line('S55', 'Gilded');
const shopFaceGildedDescription = Line('S56', 'Gold-trimmed court cards on ivory. Rank reward.');
const shopEnvThemeName = Line('S57', 'House Felt');
const shopEnvThemeDescription = Line('S58', 'Whatever your theme says.');
const shopEnvBlueName = Line('S59', 'Blue Felt');
const shopEnvBlueDescription = Line('S60', 'Cool and calm.');
const shopEnvRedName = Line('S61', 'Red Felt');
const shopEnvRedDescription = Line('S62', 'Poker night.');
const shopEnvPurpleName = Line('S63', 'Royal Felt');
const shopEnvPurpleDescription = Line('S64', 'Deep purple.');
const shopEnvOakName = Line('S65', 'Oak Table');
const shopEnvOakDescription = Line('S66', 'Bare wood, no felt.');
const shopEnvMarbleName = Line('S67', 'Marble');
const shopEnvMarbleDescription = Line('S68', 'Cold, white and veined.');
const shopEnvSlateName = Line('S69', 'Slate');
const shopEnvSlateDescription = Line('S70', 'Dark stone.');
const shopEnvCarbonName = Line('S71', 'Carbon Fibre');
const shopEnvCarbonDescription = Line('S72', 'Woven and glossy.');
const shopEnvDenimName = Line('S73', 'Denim');
const shopEnvDenimDescription = Line('S74', 'Faded blue jeans.');
const shopEnvGridName = Line('S75', 'Neon Grid');
const shopEnvGridDescription = Line('S76', 'Perspective lines to the horizon.');
const shopEnvGalaxyName = Line('S77', 'Deep Space');
const shopEnvGalaxyDescription = Line('S78', 'Play among the stars.');
const shopEnvGoldName = Line('S79', 'Gold Leaf');
const shopEnvGoldDescription = Line('S80', 'Obscenely expensive looking.');
const shopEnvBakeryName = Line('S81', 'Bakery Counter');
const shopEnvBakeryDescription = Line('S82', 'Checkered tiles and flour dust. Rank reward.');
const shopGadgetMarkersName = Line('S83', 'Marker Set');
const shopGadgetMarkersDescription = Line('S84', 'Five markers and an eraser. Doodle on the felt; everyone sees it.');
const shopGadgetRevolverName = Line('S85', 'Revolver');
const shopGadgetRevolverDescription = Line('S86', 'Six rounds. Shoot the table or a rival\'s placard.');
const shopGadgetFlashbangName = Line('S87', 'Flashbang');
const shopGadgetFlashbangDescription = Line('S88', 'Lob it on the table and white out every screen. Needs a moment to recharge.');
const shopGadgetMarkersNeonName = Line('S89', 'Neon Markers');
const shopGadgetMarkersNeonDescription = Line('S90', 'Four extra markers: hot pink, violet, orange and cyan.');
const shopGadgetMarkersPastelName = Line('S91', 'Pastel Markers');
const shopGadgetMarkersPastelDescription = Line('S92', 'Four soft markers: mint, lavender, peach and sky. Rank reward.');
const shopGadgetMarkerGoldName = Line('S93', 'Gold Marker');
const shopGadgetMarkerGoldDescription = Line('S94', 'One marker. Metallic gold ink.');
const shopGadgetStampName = Line('S95', 'Donut Stamp');
const shopGadgetStampDescription = Line('S96', 'Stamps a donut on the table in your marker colour. Everyone sees it.');
const shopGadgetConfettiName = Line('S97', 'Confetti Cannon');
const shopGadgetConfettiDescription = Line('S98', 'Celebrate anything. Click the table for a burst.');
const shopGadgetSpeedloaderName = Line('S99', 'Speedloader');
const shopGadgetSpeedloaderDescription = Line('S100', 'The revolver holds twelve rounds instead of six.');
const shopRankCrumb = Line('S101', 'Crumb');
const shopRankSprinkle = Line('S102', 'Sprinkle');
const shopRankGlazed = Line('S103', 'Glazed');
const shopRankFrosted = Line('S104', 'Frosted');
const shopRankJelly = Line('S105', 'Jelly');
const shopRankCruller = Line('S106', 'Cruller');
const shopRankFritter = Line('S107', 'Fritter');
const shopRankLongJohn = Line('S108', 'Long John');
const shopRankOldFashioned = Line('S109', 'Old Fashioned');
const shopRankBostonCream = Line('S110', 'Boston Cream');
const shopRankBeignet = Line('S111', 'Beignet');
const shopRankBaker = Line('S112', 'Baker');
const shopRankHeadBaker = Line('S113', 'Head Baker');
const shopRankPastryChef = Line('S114', 'Pastry Chef');
const shopRankDozen = Line('S115', 'Dozen');
const shopRankBakersDozen = Line('S116', 'Baker\'s Dozen');
const shopRankLegend = Line('S117', 'Legend');
const shopRankMythic = Line('S118', 'Mythic');
const shopRankInheritor = Line('S119', 'Inheritor');
const shopRankGraded = Line('S120', '{rank} {grade}');
const shopSymbolCrumb = Line('S121', 'Crumb');
const shopSymbolCherry = Line('S122', 'Cherry');
const shopSymbolSprinkle = Line('S123', 'Sprinkle');
const shopSymbolBar = Line('S124', 'Bar');
const shopSymbolSeven = Line('S125', 'Seven');
const shopSymbolGlaze = Line('S126', 'Glaze');
const shopSymbolDonut = Line('S127', 'Donut');
const shopSlotJackpot = Line('S128', 'JACKPOT!');
const shopSlotTripleGlaze = Line('S129', 'Triple Glaze');
const shopSlotLuckySevens = Line('S130', 'Lucky sevens');
const shopSlotTripleBar = Line('S131', 'Triple bar');
const shopSlotTripleSprinkle = Line('S132', 'Triple sprinkle');
const shopSlotTripleCherry = Line('S133', 'Triple cherry');
const shopSlotTripleCrumb = Line('S134', 'Triple crumb');
const shopSlotTwoDonuts = Line('S135', 'Two donuts');
const shopSlotTwoGlaze = Line('S136', 'Two glaze');
const shopSlotAPair = Line('S137', 'A pair');
const shopSlotCrumbs = Line('S138', 'Crumbs');
const shopRewardMatchPlayed = Line('S139', 'Match played');
const shopRewardVictory = Line('S140', 'Victory');
const shopRewardRunnerUp = Line('S141', 'Runner-up');
const shopRewardThirdPlace = Line('S142', 'Third place');
const shopRewardTrickTaken = Line('S143', '{n} trick taken');
const shopRewardTricksTaken = Line('S144', '{n} tricks taken');
const shopRewardHandsPlayed = Line('S145', '{n} hands played');
const shopRewardCleanSheet = Line('S146', 'Clean sheet: no donuts');
const shopRewardSuddenDeathSurvivor = Line('S147', 'Sudden death survivor');
const shopRewardSuddenDeath = Line('S148', 'Sudden death');
const shopRewardFullTable = Line('S149', 'Full table');
const shopRewardFirstWin = Line('S150', 'First win of the day');
const shopShapeCircle = Line('S151', 'Circle');
const shopShapeShield = Line('S152', 'Shield');
const shopShapeHexagon = Line('S153', 'Hexagon');
const shopShapeDiamond = Line('S154', 'Diamond');
const shopShapeSquare = Line('S155', 'Square');
const shopShapeBadge = Line('S156', 'Badge');
const shopShapeStar = Line('S157', 'Star');
const shopShapeHeart = Line('S158', 'Heart');
const shopTitle = Line('S159', 'Career');
const shopTabRank = Line('S160', 'Rank');
const shopTabShop = Line('S161', 'Shop');
const shopTabEmblem = Line('S162', 'Emblem');
const shopXpTopOfLadder = Line('S163', '{xp} XP. Top of the ladder.');
const shopXpToNext = Line('S164', '{xp} / {next} XP to {rank}');
const shopRankOf = Line('S165', 'Rank {n} of {total}');
const shopStatsHeading = Line('S166', 'Career');
const shopStatMatches = Line('S167', 'Matches');
const shopStatWins = Line('S168', 'Wins');
const shopStatWinRate = Line('S169', 'Win rate');
const shopPercent = Line('S170', '{n}%');
const shopStatTricks = Line('S171', 'Tricks taken');
const shopStatDonuts = Line('S172', 'Donuts eaten');
const shopStatHands = Line('S173', 'Hands played');
const shopStatSpins = Line('S174', 'Bonus spins');
const shopStatJackpots = Line('S175', 'Jackpots');
const shopHowToEarnHeading = Line('S176', 'How to earn');
const shopHowToEarn = Line('S177', 'Every offline match pays XP and Crumbs: more for winning, taking tricks and dodging donuts. '
    'Each match ends with a bonus spin. Every rank-up pays Crumbs and Glaze, the rare stuff, unlocks more of the shop, and some ranks hand over items the shop doesn\'t sell.');
const shopLadderHeading = Line('S178', 'The ladder');
const shopResetCareer = Line('S179', 'Reset career');
const shopResetTitle = Line('S180', 'Reset your career?');
const shopResetBody = Line('S181', 'Rank, currencies, unlocks and emblem all go back to the start. There is no undo.');
const shopKeepIt = Line('S182', 'Keep it');
const shopReset = Line('S183', 'Reset');
const shopNewInShopTooltip = Line('S184', 'New in the shop: {items}');
const shopLadderXp = Line('S185', '{xp} XP');
const shopXpSymbol = Line('S186', 'XP');
const shopAmount = Line('S187', '{prefix}{amount} {unit}');
const shopEmblemYou = Line('S188', 'You');
const shopEmblemAtTable = Line('S189', 'At the table');
const shopEmblemSurprise = Line('S190', 'Surprise me');
const shopEmblemShapeHeading = Line('S191', 'Shape');
const shopEmblemIconHeading = Line('S192', 'Icon');
const shopEmblemColoursHeading = Line('S193', 'Colours');
const shopEmblemLayerShape = Line('S194', 'Shape');
const shopEmblemLayerIcon = Line('S195', 'Icon');
const shopEmblemLayerRing = Line('S196', 'Ring');
const shopEmblemRingSwitch = Line('S197', 'Ring around the edge');
const shopEmblemHue = Line('S198', 'Hue');
const shopEmblemSaturation = Line('S199', 'Saturation');
const shopEmblemLightness = Line('S200', 'Lightness');
const shopBlurbPatterns = Line('S201', 'The back of your cards. Everyone at the table sees it.');
const shopBlurbFaces = Line('S202', 'The front of your cards, as everyone sees them in play.');
const shopBlurbEnvironments = Line('S203', 'What the table is made of.');
const shopBlurbGadgets = Line('S204', 'More toys for the tool tray. Always on once you own them.');
const shopNotEnough = Line('S205', 'Not enough {currency} for {item}.');
const shopEquipped = Line('S206', 'Equipped');
const shopOwned = Line('S207', 'Owned');
const shopEquip = Line('S208', 'Equip');
const shopReach = Line('S209', 'Reach {rank}');
const shopNeeds = Line('S210', 'Needs {item}');
const shopBuy = Line('S211', 'Buy');
const shopRareTooltip = Line('S212', 'Rare: costs Glaze');
const shopCollectRewards = Line('S213', 'Collect rewards');
const shopMatchRewards = Line('S214', 'Match rewards');
const shopBonusSpin = Line('S215', 'Bonus spin');
const shopRankUpLine = Line('S216', 'Rank up: {rank}');
const shopTotal = Line('S217', 'Total');
const shopTopRank = Line('S218', 'Top rank');
const shopRankUpBadge = Line('S219', 'RANK UP');
const shopUnlockedGadget = Line('S220', '{item} unlocked. It\'s on your tool tray.');
const shopUnlockedEquip = Line('S221', '{item} unlocked. Equip it from the shop.');
const shopNewInShop = Line('S222', 'New in the shop: {items}.');
const shopSlotTitle = Line('S223', 'BONUS SPIN');
const shopSlotHint = Line('S224', 'Pull the lever');
const shopSlotBar = Line('S225', 'BAR');
const shopSlotPull = Line('S226', 'Pull');

const List<Line> shopLines = [
  shopKindPatterns,
  shopKindFaces,
  shopKindEnvironments,
  shopKindGadgets,
  shopKindPattern,
  shopKindFace,
  shopKindEnvironment,
  shopKindGadget,
  shopCrumbs,
  shopGlaze,
  shopCrumbsSymbol,
  shopGlazeSymbol,
  shopPatternClassicName,
  shopPatternClassicDescription,
  shopPatternDotsName,
  shopPatternDotsDescription,
  shopPatternChevronsName,
  shopPatternChevronsDescription,
  shopPatternWavesName,
  shopPatternWavesDescription,
  shopPatternSprinklesName,
  shopPatternSprinklesDescription,
  shopPatternHexesName,
  shopPatternHexesDescription,
  shopPatternStarsName,
  shopPatternStarsDescription,
  shopPatternPlaidName,
  shopPatternPlaidDescription,
  shopPatternCircuitName,
  shopPatternCircuitDescription,
  shopPatternArgyleName,
  shopPatternArgyleDescription,
  shopPatternFiligreeName,
  shopPatternFiligreeDescription,
  shopPatternGalaxyName,
  shopPatternGalaxyDescription,
  shopPatternBakersSealName,
  shopPatternBakersSealDescription,
  shopPatternMidnightGlazeName,
  shopPatternMidnightGlazeDescription,
  shopFaceClassicName,
  shopFaceClassicDescription,
  shopFaceFourColourName,
  shopFaceFourColourDescription,
  shopFaceJumboName,
  shopFaceJumboDescription,
  shopFaceParlourName,
  shopFaceParlourDescription,
  shopFaceTerminalName,
  shopFaceTerminalDescription,
  shopFaceSprinkleName,
  shopFaceSprinkleDescription,
  shopFaceNeonName,
  shopFaceNeonDescription,
  shopFaceGildedName,
  shopFaceGildedDescription,
  shopEnvThemeName,
  shopEnvThemeDescription,
  shopEnvBlueName,
  shopEnvBlueDescription,
  shopEnvRedName,
  shopEnvRedDescription,
  shopEnvPurpleName,
  shopEnvPurpleDescription,
  shopEnvOakName,
  shopEnvOakDescription,
  shopEnvMarbleName,
  shopEnvMarbleDescription,
  shopEnvSlateName,
  shopEnvSlateDescription,
  shopEnvCarbonName,
  shopEnvCarbonDescription,
  shopEnvDenimName,
  shopEnvDenimDescription,
  shopEnvGridName,
  shopEnvGridDescription,
  shopEnvGalaxyName,
  shopEnvGalaxyDescription,
  shopEnvGoldName,
  shopEnvGoldDescription,
  shopEnvBakeryName,
  shopEnvBakeryDescription,
  shopGadgetMarkersName,
  shopGadgetMarkersDescription,
  shopGadgetRevolverName,
  shopGadgetRevolverDescription,
  shopGadgetFlashbangName,
  shopGadgetFlashbangDescription,
  shopGadgetMarkersNeonName,
  shopGadgetMarkersNeonDescription,
  shopGadgetMarkersPastelName,
  shopGadgetMarkersPastelDescription,
  shopGadgetMarkerGoldName,
  shopGadgetMarkerGoldDescription,
  shopGadgetStampName,
  shopGadgetStampDescription,
  shopGadgetConfettiName,
  shopGadgetConfettiDescription,
  shopGadgetSpeedloaderName,
  shopGadgetSpeedloaderDescription,
  shopRankCrumb,
  shopRankSprinkle,
  shopRankGlazed,
  shopRankFrosted,
  shopRankJelly,
  shopRankCruller,
  shopRankFritter,
  shopRankLongJohn,
  shopRankOldFashioned,
  shopRankBostonCream,
  shopRankBeignet,
  shopRankBaker,
  shopRankHeadBaker,
  shopRankPastryChef,
  shopRankDozen,
  shopRankBakersDozen,
  shopRankLegend,
  shopRankMythic,
  shopRankInheritor,
  shopRankGraded,
  shopSymbolCrumb,
  shopSymbolCherry,
  shopSymbolSprinkle,
  shopSymbolBar,
  shopSymbolSeven,
  shopSymbolGlaze,
  shopSymbolDonut,
  shopSlotJackpot,
  shopSlotTripleGlaze,
  shopSlotLuckySevens,
  shopSlotTripleBar,
  shopSlotTripleSprinkle,
  shopSlotTripleCherry,
  shopSlotTripleCrumb,
  shopSlotTwoDonuts,
  shopSlotTwoGlaze,
  shopSlotAPair,
  shopSlotCrumbs,
  shopRewardMatchPlayed,
  shopRewardVictory,
  shopRewardRunnerUp,
  shopRewardThirdPlace,
  shopRewardTrickTaken,
  shopRewardTricksTaken,
  shopRewardHandsPlayed,
  shopRewardCleanSheet,
  shopRewardSuddenDeathSurvivor,
  shopRewardSuddenDeath,
  shopRewardFullTable,
  shopRewardFirstWin,
  shopShapeCircle,
  shopShapeShield,
  shopShapeHexagon,
  shopShapeDiamond,
  shopShapeSquare,
  shopShapeBadge,
  shopShapeStar,
  shopShapeHeart,
  shopTitle,
  shopTabRank,
  shopTabShop,
  shopTabEmblem,
  shopXpTopOfLadder,
  shopXpToNext,
  shopRankOf,
  shopStatsHeading,
  shopStatMatches,
  shopStatWins,
  shopStatWinRate,
  shopPercent,
  shopStatTricks,
  shopStatDonuts,
  shopStatHands,
  shopStatSpins,
  shopStatJackpots,
  shopHowToEarnHeading,
  shopHowToEarn,
  shopLadderHeading,
  shopResetCareer,
  shopResetTitle,
  shopResetBody,
  shopKeepIt,
  shopReset,
  shopNewInShopTooltip,
  shopLadderXp,
  shopXpSymbol,
  shopAmount,
  shopEmblemYou,
  shopEmblemAtTable,
  shopEmblemSurprise,
  shopEmblemShapeHeading,
  shopEmblemIconHeading,
  shopEmblemColoursHeading,
  shopEmblemLayerShape,
  shopEmblemLayerIcon,
  shopEmblemLayerRing,
  shopEmblemRingSwitch,
  shopEmblemHue,
  shopEmblemSaturation,
  shopEmblemLightness,
  shopBlurbPatterns,
  shopBlurbFaces,
  shopBlurbEnvironments,
  shopBlurbGadgets,
  shopNotEnough,
  shopEquipped,
  shopOwned,
  shopEquip,
  shopReach,
  shopNeeds,
  shopBuy,
  shopRareTooltip,
  shopCollectRewards,
  shopMatchRewards,
  shopBonusSpin,
  shopRankUpLine,
  shopTotal,
  shopTopRank,
  shopRankUpBadge,
  shopUnlockedGadget,
  shopUnlockedEquip,
  shopNewInShop,
  shopSlotTitle,
  shopSlotHint,
  shopSlotBar,
  shopSlotPull,
];
