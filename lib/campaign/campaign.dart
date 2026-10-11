import 'package:donut_game/ai/bot_brain.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/progression/rewards.dart';

/// The campaign: a tour of venues, each a few stages against preset
/// opponents and ending in a boss, played on that venue's table in front of
/// its backdrop.

/// A named rival with a fixed skill, deck and things to say.
class Opponent {
  const Opponent({
    required this.name,
    required this.skill,
    required this.back,
    required this.face,
    this.lines = const BotLines(),
  });

  final String name;
  final BotSkill skill;

  /// Catalog ids of their deck.
  final String back;
  final String face;
  final BotLines lines;

  /// A fresh seat for this opponent, playing at their skill moved by
  /// [difficulty].
  GamePlayer seat(Difficulty difficulty) => GamePlayer(name, 0, false)
    ..skill = skill.shifted(difficulty.skillShift)
    ..cardBack = back
    ..cardFace = face
    ..lines = lines
    ..character = true;
}

/// Chosen before each stage; it moves every opponent's skill and scales the
/// first-clear rewards.
enum Difficulty { casual, standard, brutal }

extension DifficultyInfo on Difficulty {
  String get label => switch (this) {
        Difficulty.casual => 'Casual',
        Difficulty.standard => 'Standard',
        Difficulty.brutal => 'Brutal',
      };

  String get blurb => switch (this) {
        Difficulty.casual => 'Every opponent plays a tier worse. Smaller rewards.',
        Difficulty.standard => 'Opponents play as billed.',
        Difficulty.brutal => 'Every opponent plays a tier better. Bigger rewards.',
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
  const Stage({required this.id, required this.name, required this.opponents, this.target = 20, this.boss = false});

  /// Stored in the profile; never rename.
  final String id;
  final String name;
  final List<Opponent> opponents;

  /// The score everyone starts on.
  final int target;
  final bool boss;
}

class Venue {
  const Venue({
    required this.id,
    required this.name,
    required this.blurb,
    required this.backdrop,
    required this.environment,
    required this.stages,
  });

  final String id;
  final String name;
  final String blurb;

  /// Backdrop painted behind the table, from backdrops.dart.
  final String backdrop;

  /// Table environment id from the catalog.
  final String environment;
  final List<Stage> stages;
}

// The cast, roughly in the order you meet them

const _gary = Opponent(
  name: 'Glazed Gary',
  skill: BotSkill.rookie,
  back: 'pattern.classic',
  face: 'face.classic',
  lines: BotLines(
    greet: ['First day on the job? Me too.'],
    trick: ['Oh! Was that mine?', 'Beginner\'s luck.'],
    donut: ['That\'s fine. That\'s fine.'],
  ),
);
const _sprinkles = Opponent(
  name: 'Sprinkles',
  skill: BotSkill.rookie,
  back: 'pattern.sprinkles',
  face: 'face.sprinkle',
  lines: BotLines(
    greet: ['Hiii! Let\'s play!'],
    trick: ['Yay!', 'Sparkly!'],
    donut: ['Aww, crumbs.'],
  ),
);
const _maple = Opponent(
  name: 'Maple Bar',
  skill: BotSkill.rookie,
  back: 'pattern.waves',
  face: 'face.classic',
  lines: BotLines(trick: ['Smooth as syrup.'], donut: ['Sticky situation.']),
);
const _bea = Opponent(
  name: 'Baker Bea',
  skill: BotSkill.amateur,
  back: 'pattern.bakers_seal',
  face: 'face.parlour',
  lines: BotLines(
    greet: ['My bakery, my rules. Mostly the normal rules.'],
    trick: ['Fresh out of the oven.', 'Proper technique.'],
    donut: ['Burnt that batch.'],
    win: ['Come back when you\'ve proofed a bit longer.'],
  ),
);
const _jojo = Opponent(
  name: 'Jelly Jo',
  skill: BotSkill.regular,
  back: 'pattern.dots',
  face: 'face.four_colour',
  lines: BotLines(trick: ['Squish.', 'Filled with joy.'], donut: ['Leaking.']),
);
const _lantern = Opponent(
  name: 'Lantern Lou',
  skill: BotSkill.regular,
  back: 'pattern.stars',
  face: 'face.classic',
  lines: BotLines(
    greet: ['Mind the lanterns.'],
    trick: ['Lights out.', 'Bright idea.'],
    donut: ['Fizzled.'],
  ),
);
const _churro = Opponent(
  name: 'Churro Chen',
  skill: BotSkill.amateur,
  back: 'pattern.chevrons',
  face: 'face.jumbo',
  lines: BotLines(trick: ['Crispy.', 'Ridged for strength.'], donut: ['Soggy.']),
);
const _mochi = Opponent(
  name: 'Mochi Mae',
  skill: BotSkill.pro,
  back: 'pattern.hexes',
  face: 'face.four_colour',
  lines: BotLines(
    greet: ['The market closes when I say so.'],
    trick: ['Chewy.', 'Pounded flat.'],
    donut: ['Hm. Unexpected.'],
    win: ['Stall\'s closed. Try again tomorrow.'],
  ),
);
const _flo = Opponent(
  name: 'Flapjack Flo',
  skill: BotSkill.amateur,
  back: 'pattern.plaid',
  face: 'face.jumbo',
  lines: BotLines(
    greet: ['Coffee\'s fresh. Cards are fresher.'],
    trick: ['Order up!', 'Short stack.'],
    donut: ['Eighty-six that.'],
  ),
);
const _hash = Opponent(
  name: 'Hash Brown Hank',
  skill: BotSkill.pro,
  back: 'pattern.argyle',
  face: 'face.terminal',
  lines: BotLines(trick: ['Crispy edges.', 'Scattered, smothered.'], donut: ['Undercooked.']),
);
const _duke = Opponent(
  name: 'Duke Danish',
  skill: BotSkill.pro,
  back: 'pattern.circuit',
  face: 'face.terminal',
  lines: BotLines(
    greet: ['Nobody leaves my diner hungry. Or winning.'],
    trick: ['Bottomless.', 'On the house.'],
    donut: ['Comp that one.'],
    win: ['Tip your waitress on the way out.'],
  ),
);
const _beignet = Opponent(
  name: 'Belle Beignet',
  skill: BotSkill.pro,
  back: 'pattern.filigree',
  face: 'face.parlour',
  lines: BotLines(
    greet: ['Welcome aboard, sugar.'],
    trick: ['Powdered.', 'Laissez les bons temps rouler.'],
    donut: ['The river giveth...'],
  ),
);
const _croque = Opponent(
  name: 'Captain Croque',
  skill: BotSkill.pro,
  back: 'pattern.argyle',
  face: 'face.neon',
  lines: BotLines(trick: ['Full steam.', 'Weigh anchor.'], donut: ['Man overboard.']),
);
const _paddlewheel = Opponent(
  name: 'The Paddlewheel',
  skill: BotSkill.shark,
  back: 'pattern.midnight_glaze',
  face: 'face.gilded',
  lines: BotLines(
    greet: ['House always wins. I am the house.'],
    trick: ['House edge.', 'Collect.'],
    donut: ['A rounding error.'],
    win: ['The river keeps what it takes.'],
  ),
);
const _nova = Opponent(
  name: 'Nova Cruller',
  skill: BotSkill.pro,
  back: 'pattern.galaxy',
  face: 'face.neon',
  lines: BotLines(
    greet: ['Gravity\'s optional up here. Mercy too.'],
    trick: ['Liftoff.', 'Orbit achieved.'],
    donut: ['Houston...'],
  ),
);
const _zero = Opponent(
  name: 'Zero-G Zeppole',
  skill: BotSkill.shark,
  back: 'pattern.stars',
  face: 'face.terminal',
  lines: BotLines(trick: ['Calculated.', 'Trajectory nominal.'], donut: ['Anomaly logged.']),
);
const _station = Opponent(
  name: 'Commander Kouign',
  skill: BotSkill.shark,
  back: 'pattern.galaxy',
  face: 'face.gilded',
  lines: BotLines(
    greet: ['You\'re a long way from the bakery, cadet.'],
    trick: ['Docking complete.', 'Mission success.'],
    donut: ['Recalibrating.'],
    win: ['Request denied. Return to Earth.'],
  ),
);
const _mille = Opponent(
  name: 'Madame Mille-Feuille',
  skill: BotSkill.shark,
  back: 'pattern.midnight_glaze',
  face: 'face.gilded',
  lines: BotLines(
    greet: ['A thousand layers, darling. You\'ve seen one.'],
    trick: ['Exquisite.', 'Layer upon layer.'],
    donut: ['How... rustic.'],
    win: ['Do mind the door on your way out.'],
  ),
);
const _eclair = Opponent(
  name: 'Sir Eclair',
  skill: BotSkill.shark,
  back: 'pattern.filigree',
  face: 'face.parlour',
  lines: BotLines(trick: ['Filled to the brim.', 'Glazed and confused? No.'], donut: ['A soggy bottom.']),
);
const _croissant = Opponent(
  name: 'Count Croissant',
  skill: BotSkill.pro,
  back: 'pattern.argyle',
  face: 'face.gilded',
  lines: BotLines(trick: ['Flaky? Never.', 'Buttered.'], donut: ['Crumbled.']),
);

final List<Venue> campaign = [
  const Venue(
    id: 'bakery',
    name: 'The Corner Bakery',
    blurb: 'Where it all starts: flour in the air and nobody who knows the rules.',
    backdrop: 'backdrop.bakery',
    environment: 'env.oak',
    stages: [
      Stage(id: 'bakery.1', name: 'Opening Shift', opponents: [_gary, _sprinkles], target: 10),
      Stage(id: 'bakery.2', name: 'Morning Rush', opponents: [_gary, _sprinkles, _maple], target: 12),
      Stage(id: 'bakery.boss', name: 'The Head Baker', opponents: [_bea, _gary, _maple], target: 15, boss: true),
    ],
  ),
  const Venue(
    id: 'market',
    name: 'Night Market',
    blurb: 'Lanterns, hawkers and players who\'ve at least read the rules.',
    backdrop: 'backdrop.market',
    environment: 'env.red',
    stages: [
      Stage(id: 'market.1', name: 'Lantern Row', opponents: [_lantern, _jojo], target: 15),
      Stage(id: 'market.2', name: 'Hawker Alley', opponents: [_lantern, _jojo, _churro], target: 15),
      Stage(id: 'market.boss', name: 'Last Stall Standing', opponents: [_mochi, _churro, _lantern], boss: true),
    ],
  ),
  const Venue(
    id: 'diner',
    name: 'The All-Night Diner',
    blurb: 'Bottomless coffee, chrome stools and regulars who fold when they should.',
    backdrop: 'backdrop.diner',
    environment: 'env.denim',
    stages: [
      Stage(id: 'diner.1', name: 'Graveyard Shift', opponents: [_flo, _churro, _jojo]),
      Stage(id: 'diner.2', name: 'Blue Plate Special', opponents: [_flo, _hash, _churro]),
      Stage(id: 'diner.boss', name: 'The Owner\'s Booth', opponents: [_duke, _hash, _flo], boss: true),
    ],
  ),
  const Venue(
    id: 'riverboat',
    name: 'Riverboat Casino',
    blurb: 'Felt, brass and a dealer who never seems to lose.',
    backdrop: 'backdrop.riverboat',
    environment: 'env.purple',
    stages: [
      Stage(id: 'riverboat.1', name: 'Boarding', opponents: [_beignet, _hash, _flo]),
      Stage(id: 'riverboat.2', name: 'High Rollers', opponents: [_beignet, _croque, _duke, _hash]),
      Stage(id: 'riverboat.boss', name: 'The House', opponents: [_paddlewheel, _beignet, _croque], boss: true),
    ],
  ),
  const Venue(
    id: 'orbital',
    name: 'Orbital Lounge',
    blurb: 'Zero gravity, perfect recall. Up here they count every card.',
    backdrop: 'backdrop.orbital',
    environment: 'env.galaxy',
    stages: [
      Stage(id: 'orbital.1', name: 'Docking Bay', opponents: [_nova, _croque, _beignet]),
      Stage(id: 'orbital.2', name: 'Low Orbit', opponents: [_nova, _zero, _croque, _duke]),
      Stage(id: 'orbital.boss', name: 'Command Deck', opponents: [_station, _zero, _nova], boss: true),
    ],
  ),
  const Venue(
    id: 'grand',
    name: 'The Grand Patisserie',
    blurb: 'Chandeliers, marble and the finest players in the world. Bring your best deck.',
    backdrop: 'backdrop.grand',
    environment: 'env.marble',
    stages: [
      Stage(id: 'grand.1', name: 'The Salon', opponents: [_croissant, _eclair, _nova, _zero]),
      Stage(id: 'grand.2', name: 'The Gallery', opponents: [_eclair, _station, _croissant, _paddlewheel]),
      Stage(
          id: 'grand.boss',
          name: 'A Thousand Layers',
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
      ? (stage.boss ? 'Boss defeated: ${stage.name}' : 'Stage cleared: ${stage.name}')
      : '${difficulty.label} clear: ${stage.name}';
  return [
    RewardLine(label,
        xp: (base.xp * earned).round(), crumbs: (base.crumbs * earned).round(), glaze: (base.glaze * earned).round()),
  ];
}
