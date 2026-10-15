import 'package:donut_game/ai/bot_brain.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/progression/rewards.dart';
import 'package:donut_copy/donut_copy.dart';

/// The campaign: a tour of venues, each a few stages against preset
/// opponents and ending in a boss, played on that venue's table in front of
/// its backdrop.

/// A named rival with a fixed skill, deck and things to say.
class Opponent {
  const Opponent({
    required Line name,
    required this.skill,
    required this.back,
    required this.face,
    OpponentLines lines = const OpponentLines(),
  })  : nameLine = name,
        quips = lines;

  final Line nameLine;
  final BotSkill skill;

  /// Catalog ids of their deck.
  final String back;
  final String face;
  final OpponentLines quips;

  String get name => nameLine();
  BotLines get lines => quips.text;

  /// A fresh seat for this opponent, playing at their skill moved by
  /// [difficulty].
  GamePlayer seat(Difficulty difficulty) => GamePlayer(name, 0, false)
    ..skill = skill.shifted(difficulty.skillShift)
    ..cardBack = back
    ..cardFace = face
    ..lines = lines
    ..character = true;
}

/// What an [Opponent] says, as lines of text from donut_copy.
class OpponentLines {
  const OpponentLines({this.greet = const [], this.trick = const [], this.donut = const [], this.win = const []});

  final List<Line> greet;
  final List<Line> trick;
  final List<Line> donut;
  final List<Line> win;

  /// The text to say, as the table wants it.
  BotLines get text => BotLines(
        greet: [for (final line in greet) line()],
        trick: [for (final line in trick) line()],
        donut: [for (final line in donut) line()],
        win: [for (final line in win) line()],
      );
}

/// Chosen before each stage; it moves every opponent's skill and scales the
/// first-clear rewards.
enum Difficulty { casual, standard, brutal }

extension DifficultyInfo on Difficulty {
  String get label => switch (this) {
        Difficulty.casual => campaignCasualLabel(),
        Difficulty.standard => campaignStandardLabel(),
        Difficulty.brutal => campaignBrutalLabel(),
      };

  String get blurb => switch (this) {
        Difficulty.casual => campaignCasualBlurb(),
        Difficulty.standard => campaignStandardBlurb(),
        Difficulty.brutal => campaignBrutalBlurb(),
      };

  int get skillShift => index - 1;

  /// Stars for clearing on this difficulty.
  int get stars => index + 1;

  double get rewardScale => switch (this) {
        Difficulty.casual => 0.6,
        Difficulty.standard => 1.0,
        Difficulty.brutal => 1.6,
      };
}

class Stage {
  const Stage({required this.id, required Line name, required this.opponents, this.target = 20, this.boss = false})
      : nameLine = name;

  /// Stored in the profile; never rename.
  final String id;
  final Line nameLine;
  String get name => nameLine();
  final List<Opponent> opponents;

  /// The score everyone starts on.
  final int target;
  final bool boss;
}

class Venue {
  const Venue({
    required this.id,
    required Line name,
    required Line blurb,
    required this.backdrop,
    required this.environment,
    required this.stages,
  })  : nameLine = name,
        blurbLine = blurb;

  final String id;
  final Line nameLine;
  final Line blurbLine;
  String get name => nameLine();
  String get blurb => blurbLine();

  /// Backdrop painted behind the table, from backdrops.dart.
  final String backdrop;

  /// Table environment id from the catalog.
  final String environment;
  final List<Stage> stages;
}

// The cast, roughly in the order you meet them

const _gary = Opponent(
  name: campaignGaryName,
  skill: BotSkill.rookie,
  back: 'pattern.classic',
  face: 'face.classic',
  lines: OpponentLines(
    greet: [campaignGaryGreet1],
    trick: [campaignGaryTrick1, campaignGaryTrick2],
    donut: [campaignGaryDonut1],
  ),
);
const _sprinkles = Opponent(
  name: campaignSprinklesName,
  skill: BotSkill.rookie,
  back: 'pattern.sprinkles',
  face: 'face.sprinkle',
  lines: OpponentLines(
    greet: [campaignSprinklesGreet1],
    trick: [campaignSprinklesTrick1, campaignSprinklesTrick2],
    donut: [campaignSprinklesDonut1],
  ),
);
const _maple = Opponent(
  name: campaignMapleName,
  skill: BotSkill.rookie,
  back: 'pattern.waves',
  face: 'face.classic',
  lines: OpponentLines(trick: [campaignMapleTrick1], donut: [campaignMapleDonut1]),
);
const _bea = Opponent(
  name: campaignBeaName,
  skill: BotSkill.amateur,
  back: 'pattern.bakers_seal',
  face: 'face.parlour',
  lines: OpponentLines(
    greet: [campaignBeaGreet1],
    trick: [campaignBeaTrick1, campaignBeaTrick2],
    donut: [campaignBeaDonut1],
    win: [campaignBeaWin1],
  ),
);
const _jojo = Opponent(
  name: campaignJojoName,
  skill: BotSkill.regular,
  back: 'pattern.dots',
  face: 'face.four_colour',
  lines: OpponentLines(trick: [campaignJojoTrick1, campaignJojoTrick2], donut: [campaignJojoDonut1]),
);
const _lantern = Opponent(
  name: campaignLanternName,
  skill: BotSkill.regular,
  back: 'pattern.stars',
  face: 'face.classic',
  lines: OpponentLines(
    greet: [campaignLanternGreet1],
    trick: [campaignLanternTrick1, campaignLanternTrick2],
    donut: [campaignLanternDonut1],
  ),
);
const _churro = Opponent(
  name: campaignChurroName,
  skill: BotSkill.amateur,
  back: 'pattern.chevrons',
  face: 'face.jumbo',
  lines: OpponentLines(trick: [campaignChurroTrick1, campaignChurroTrick2], donut: [campaignChurroDonut1]),
);
const _mochi = Opponent(
  name: campaignMochiName,
  skill: BotSkill.pro,
  back: 'pattern.hexes',
  face: 'face.four_colour',
  lines: OpponentLines(
    greet: [campaignMochiGreet1],
    trick: [campaignMochiTrick1, campaignMochiTrick2],
    donut: [campaignMochiDonut1],
    win: [campaignMochiWin1],
  ),
);
const _flo = Opponent(
  name: campaignFloName,
  skill: BotSkill.amateur,
  back: 'pattern.plaid',
  face: 'face.jumbo',
  lines: OpponentLines(
    greet: [campaignFloGreet1],
    trick: [campaignFloTrick1, campaignFloTrick2],
    donut: [campaignFloDonut1],
  ),
);
const _hash = Opponent(
  name: campaignHashName,
  skill: BotSkill.pro,
  back: 'pattern.argyle',
  face: 'face.terminal',
  lines: OpponentLines(trick: [campaignHashTrick1, campaignHashTrick2], donut: [campaignHashDonut1]),
);
const _duke = Opponent(
  name: campaignDukeName,
  skill: BotSkill.pro,
  back: 'pattern.circuit',
  face: 'face.terminal',
  lines: OpponentLines(
    greet: [campaignDukeGreet1],
    trick: [campaignDukeTrick1, campaignDukeTrick2],
    donut: [campaignDukeDonut1],
    win: [campaignDukeWin1],
  ),
);
const _beignet = Opponent(
  name: campaignBeignetName,
  skill: BotSkill.pro,
  back: 'pattern.filigree',
  face: 'face.parlour',
  lines: OpponentLines(
    greet: [campaignBeignetGreet1],
    trick: [campaignBeignetTrick1, campaignBeignetTrick2],
    donut: [campaignBeignetDonut1],
  ),
);
const _croque = Opponent(
  name: campaignCroqueName,
  skill: BotSkill.pro,
  back: 'pattern.argyle',
  face: 'face.neon',
  lines: OpponentLines(trick: [campaignCroqueTrick1, campaignCroqueTrick2], donut: [campaignCroqueDonut1]),
);
const _paddlewheel = Opponent(
  name: campaignPaddlewheelName,
  skill: BotSkill.shark,
  back: 'pattern.midnight_glaze',
  face: 'face.gilded',
  lines: OpponentLines(
    greet: [campaignPaddlewheelGreet1],
    trick: [campaignPaddlewheelTrick1, campaignPaddlewheelTrick2],
    donut: [campaignPaddlewheelDonut1],
    win: [campaignPaddlewheelWin1],
  ),
);
const _nova = Opponent(
  name: campaignNovaName,
  skill: BotSkill.pro,
  back: 'pattern.galaxy',
  face: 'face.neon',
  lines: OpponentLines(
    greet: [campaignNovaGreet1],
    trick: [campaignNovaTrick1, campaignNovaTrick2],
    donut: [campaignNovaDonut1],
  ),
);
const _zero = Opponent(
  name: campaignZeppoleName,
  skill: BotSkill.shark,
  back: 'pattern.stars',
  face: 'face.terminal',
  lines: OpponentLines(trick: [campaignZeppoleTrick1, campaignZeppoleTrick2], donut: [campaignZeppoleDonut1]),
);
const _station = Opponent(
  name: campaignKouignName,
  skill: BotSkill.shark,
  back: 'pattern.galaxy',
  face: 'face.gilded',
  lines: OpponentLines(
    greet: [campaignKouignGreet1],
    trick: [campaignKouignTrick1, campaignKouignTrick2],
    donut: [campaignKouignDonut1],
    win: [campaignKouignWin1],
  ),
);
const _mille = Opponent(
  name: campaignMilleName,
  skill: BotSkill.shark,
  back: 'pattern.midnight_glaze',
  face: 'face.gilded',
  lines: OpponentLines(
    greet: [campaignMilleGreet1],
    trick: [campaignMilleTrick1, campaignMilleTrick2],
    donut: [campaignMilleDonut1],
    win: [campaignMilleWin1],
  ),
);
const _eclair = Opponent(
  name: campaignEclairName,
  skill: BotSkill.shark,
  back: 'pattern.filigree',
  face: 'face.parlour',
  lines: OpponentLines(trick: [campaignEclairTrick1, campaignEclairTrick2], donut: [campaignEclairDonut1]),
);
const _croissant = Opponent(
  name: campaignCroissantName,
  skill: BotSkill.pro,
  back: 'pattern.argyle',
  face: 'face.gilded',
  lines: OpponentLines(trick: [campaignCroissantTrick1, campaignCroissantTrick2], donut: [campaignCroissantDonut1]),
);

final List<Venue> campaign = [
  const Venue(
    id: 'bakery',
    name: campaignBakeryName,
    blurb: campaignBakeryBlurb,
    backdrop: 'backdrop.bakery',
    environment: 'env.oak',
    stages: [
      Stage(id: 'bakery.1', name: campaignBakeryStage1, opponents: [_gary, _sprinkles], target: 10),
      Stage(id: 'bakery.2', name: campaignBakeryStage2, opponents: [_gary, _sprinkles, _maple], target: 12),
      Stage(id: 'bakery.boss', name: campaignBakeryStageBoss, opponents: [_bea, _gary, _maple], target: 15, boss: true),
    ],
  ),
  const Venue(
    id: 'market',
    name: campaignMarketName,
    blurb: campaignMarketBlurb,
    backdrop: 'backdrop.market',
    environment: 'env.red',
    stages: [
      Stage(id: 'market.1', name: campaignMarketStage1, opponents: [_lantern, _jojo], target: 15),
      Stage(id: 'market.2', name: campaignMarketStage2, opponents: [_lantern, _jojo, _churro], target: 15),
      Stage(id: 'market.boss', name: campaignMarketStageBoss, opponents: [_mochi, _churro, _lantern], boss: true),
    ],
  ),
  const Venue(
    id: 'diner',
    name: campaignDinerName,
    blurb: campaignDinerBlurb,
    backdrop: 'backdrop.diner',
    environment: 'env.denim',
    stages: [
      Stage(id: 'diner.1', name: campaignDinerStage1, opponents: [_flo, _churro, _jojo]),
      Stage(id: 'diner.2', name: campaignDinerStage2, opponents: [_flo, _hash, _churro]),
      Stage(id: 'diner.boss', name: campaignDinerStageBoss, opponents: [_duke, _hash, _flo], boss: true),
    ],
  ),
  const Venue(
    id: 'riverboat',
    name: campaignRiverboatName,
    blurb: campaignRiverboatBlurb,
    backdrop: 'backdrop.riverboat',
    environment: 'env.purple',
    stages: [
      Stage(id: 'riverboat.1', name: campaignRiverboatStage1, opponents: [_beignet, _hash, _flo]),
      Stage(id: 'riverboat.2', name: campaignRiverboatStage2, opponents: [_beignet, _croque, _duke, _hash]),
      Stage(
          id: 'riverboat.boss',
          name: campaignRiverboatStageBoss,
          opponents: [_paddlewheel, _beignet, _croque],
          boss: true),
    ],
  ),
  const Venue(
    id: 'orbital',
    name: campaignOrbitalName,
    blurb: campaignOrbitalBlurb,
    backdrop: 'backdrop.orbital',
    environment: 'env.galaxy',
    stages: [
      Stage(id: 'orbital.1', name: campaignOrbitalStage1, opponents: [_nova, _croque, _beignet]),
      Stage(id: 'orbital.2', name: campaignOrbitalStage2, opponents: [_nova, _zero, _croque, _duke]),
      Stage(id: 'orbital.boss', name: campaignOrbitalStageBoss, opponents: [_station, _zero, _nova], boss: true),
    ],
  ),
  const Venue(
    id: 'grand',
    name: campaignGrandName,
    blurb: campaignGrandBlurb,
    backdrop: 'backdrop.grand',
    environment: 'env.marble',
    stages: [
      Stage(id: 'grand.1', name: campaignGrandStage1, opponents: [_croissant, _eclair, _nova, _zero]),
      Stage(id: 'grand.2', name: campaignGrandStage2, opponents: [_eclair, _station, _croissant, _paddlewheel]),
      Stage(
          id: 'grand.boss',
          name: campaignGrandStageBoss,
          opponents: [_mille, _eclair, _station, _paddlewheel],
          boss: true),
    ],
  ),
];

/// Every stage in order, venue by venue.
List<Stage> get allStages => [for (final venue in campaign) ...venue.stages];

Venue venueOf(Stage stage) => campaign.firstWhere((venue) => venue.stages.contains(stage));

Stage? stageById(String id) => allStages.where((stage) => stage.id == id).firstOrNull;

/// The stage after [stage], or null at the end of the tour.
Stage? nextStage(Stage stage) {
  final stages = allStages;
  final i = stages.indexOf(stage);
  return i + 1 < stages.length ? stages[i + 1] : null;
}

/// Base pay for clearing [stage] on Standard, before scaling.
({int xp, int crumbs, int glaze}) stageReward(Stage stage) {
  final i = allStages.indexOf(stage);
  final venue = campaign.indexOf(venueOf(stage));
  return (xp: 200 + 50 * i, crumbs: 150 + 40 * i, glaze: stage.boss ? 3 + venue : 0);
}

/// What clearing [stage] on [difficulty] pays when the best clear so far was
/// [best] (null if never). Beating a stage on a harder difficulty later pays
/// the difference; replaying at or below the best pays nothing extra.
List<RewardLine> stageClearRewards(Stage stage, Difficulty difficulty, Difficulty? best) {
  final earned = difficulty.rewardScale - (best?.rewardScale ?? 0);
  if (earned <= 0) return const [];
  final base = stageReward(stage);
  final label = best == null
      ? (stage.boss ? campaignBossDefeated.of('stage', stage.name) : campaignStageCleared.of('stage', stage.name))
      : campaignDifficultyClear({'difficulty': difficulty.label, 'stage': stage.name});
  return [
    RewardLine(label,
        xp: (base.xp * earned).round(), crumbs: (base.crumbs * earned).round(), glaze: (base.glaze * earned).round()),
  ];
}
