import 'line.dart';

// In-game announcements: codes N1, N2, ... Never reuse or renumber a code: the
// text file refers to them. Add new ones at the end.

// The table's refusals and system chat lines.
const announceSeatTaken = Line('N1', 'That seat belongs to someone else.');
const announceBack = Line('N2', '{name} is back.');
const announceMissingSecret = Line('N3', 'Missing secret.');
const announceAlreadyStarted = Line('N4', 'That game has already started.');
const announceThatTableFull = Line('N5', 'That table is full.');
const announcePickName = Line('N6', 'Pick a name first.');
const announcePlayerName = Line('N7', 'Player');
const announceJoinedGame = Line('N8', '{name} joined the game.');
const announceLeftTable = Line('N9', '{name} left the table.');
const announceLostConnection = Line('N10', "{name} lost connection. A bot plays for them until they're back.");
const announceNotAtTable = Line('N11', 'Not at this table.');
const announceHandInPlay = Line('N12', 'A hand is in play.');
const announceMatchOver = Line('N13', 'The match is over. The host can start another.');
const announceNoSuchCard = Line('N14', 'No such card.');
const announceNoSwapsLeft = Line('N15', 'No swaps left.');
const announceCantFold = Line('N16', "You can't fold this hand.");
const announceNotYourTurnToPlay = Line('N17', 'Not your turn to play.');
const announceMustFollow = Line('N18', 'You must follow the lead suit.');
const announceNothingToSay = Line('N19', 'Nothing to say.');
const announceSlowDown = Line('N20', 'Slow down.');
const announceThrowSomewhere = Line('N21', 'Throw it somewhere.');
const announceFlashbangCooling = Line('N22', 'Flashbang cooling down.');
const announceThrewFlashbang = Line('N23', '{name} threw a flashbang!');
const announceOnlyHostNewMatch = Line('N24', 'Only the host can start a new match.');
const announceOnlyHostSettings = Line('N25', 'Only the host can change the table.');
const announceSettingsBetweenMatches = Line('N26', 'The table can change between matches.');
const announceBotsNow = Line('N27', 'Bots are now {skill}.');
const announceEveryoneStartsOn = Line('N28', 'Everyone starts on {n}.');
const announceOnlyHostAddBots = Line('N29', 'Only the host can add bots.');
const announceBotsJoinBetween = Line('N30', 'Bots can join between matches.');
const announceTableFull = Line('N31', 'The table is full.');
const announceOnlyHostRemoveBots = Line('N32', 'Only the host can remove bots.');
const announceBotsLeaveBetween = Line('N33', 'Bots can leave between matches.');
const announceNoBots = Line('N34', 'No bots.');
const announceUnknownMove = Line('N35', 'Unknown move {action}.');
const announceNotYourTurnToSwap = Line('N36', 'Not your turn to swap.');
const announceReportedNotHere = Line('N37', "That player isn't at this table.");
const announceReportSelf = Line('N38', "You can't report yourself.");
const announceReportsLimit = Line('N39', "You've sent a few reports already. Thanks, they're being looked at.");
const announceHandDeals = Line('N40', 'Hand {n}: {name} deals.');
const announceSuddenDeathHand = Line('N41', 'Sudden death hand: {names}.');
const announceTrump = Line('N42', 'Trump is {suit}.');
const announceFolds = Line('N43', '{name} folds.');
const announceKeepsHand = Line('N44', '{name} keeps their hand.');
const announceSwapsOne = Line('N45', '{name} swaps 1 card.');
const announceSwapsMany = Line('N46', '{name} swaps {n} cards.');
const announceOnlyOneLeft = Line('N47', '{name} is the only one left in and takes all {n} tricks.');
const announceTakesTrick = Line('N48', '{name} takes the trick.');
const announceDonut = Line('N49', '{name} got a donut! +{n}');
const announceWinsMatch = Line('N50', '{name} wins the match!');
const announceTieSuddenDeath = Line('N51', 'Tie! Sudden death between {names}.');
const announceNewMatch = Line('N52', 'New match! Everyone starts on {n}.');
const announceBotNumbered = Line('N53', 'Bot {n}');
const announceJoinedTable = Line('N54', '{name} joined the table.');
const announceNobodyByName = Line('N55', 'Nobody by that name.');
const announceShotOwnPlacard = Line('N56', '{name} shot their own placard.');
const announceShotPlacard = Line('N57', "{name} shot {target}'s placard!");
const announceShootSomething = Line('N58', 'Shoot something.');
const announceDrawSomething = Line('N59', 'Draw something.');

// Bot names.
const announceBotGlazedGary = Line('N60', 'Glazed Gary');
const announceBotSprinkles = Line('N61', 'Sprinkles');
const announceBotBostonCreme = Line('N62', 'Boston Creme');
const announceBotCruller = Line('N63', 'Cruller');
const announceBotMapleBar = Line('N64', 'Maple Bar');
const announceBotJellyJo = Line('N65', 'Jelly Jo');
const announceBotOldFashioned = Line('N66', 'Old Fashioned');
const announceBotBearClaw = Line('N67', 'Bear Claw');
const announceBotCinnamonSue = Line('N68', 'Cinnamon Sue');
const announceBotPowderedPete = Line('N69', 'Powdered Pete');

// Bot skill levels: names and blurbs.
const announceSkillRookie = Line('N70', 'Rookie');
const announceSkillRegular = Line('N71', 'Regular');
const announceSkillAmateur = Line('N72', 'Amateur');
const announceSkillPro = Line('N73', 'Pro');
const announceSkillShark = Line('N74', 'Shark');
const announceSkillRookieBlurb = Line('N75', 'Still learning. Lets you win tricks.');
const announceSkillRegularBlurb = Line('N76', 'Plays whatever comes to hand.');
const announceSkillAmateurBlurb = Line('N77', 'Knows the basics, still slips up.');
const announceSkillProBlurb = Line('N78', 'Plays the odds and folds bad hands.');
const announceSkillSharkBlurb = Line('N79', 'Counts every card. Never blinks.');

// What bots say when they take a trick, or get a donut.
const announceQuipMine = Line('N80', 'Mine!');
const announceQuipThankYou = Line('N81', 'Thank you very much.');
const announceQuipTooEasy = Line('N82', 'Too easy.');
const announceQuipYoink = Line('N83', 'Yoink.');
const announceQuipCalledIt = Line('N84', 'Called it.');
const announceQuipNom = Line('N85', 'Nom.');
const announceQuipOuch = Line('N86', 'Ouch.');
const announceQuipNotAgain = Line('N87', 'Not again...');
const announceQuipSavingThose = Line('N88', 'I was saving those cards.');
const announceQuipRigged = Line('N89', 'Rigged deck.');
const announceQuipHmph = Line('N90', 'Hmph.');

/// The bots' names, in order.
const List<Line> announceBotNames = [
  announceBotGlazedGary,
  announceBotSprinkles,
  announceBotBostonCreme,
  announceBotCruller,
  announceBotMapleBar,
  announceBotJellyJo,
  announceBotOldFashioned,
  announceBotBearClaw,
  announceBotCinnamonSue,
  announceBotPowderedPete,
];

/// What a bot may say on taking a trick.
const List<Line> announceBotTrickQuips = [
  announceQuipMine,
  announceQuipThankYou,
  announceQuipTooEasy,
  announceQuipYoink,
  announceQuipCalledIt,
  announceQuipNom,
];

/// What a bot may say on getting a donut.
const List<Line> announceBotDonutQuips = [
  announceQuipOuch,
  announceQuipNotAgain,
  announceQuipSavingThose,
  announceQuipRigged,
  announceQuipHmph,
];

const List<Line> announcementsLines = [
  announceSeatTaken,
  announceBack,
  announceMissingSecret,
  announceAlreadyStarted,
  announceThatTableFull,
  announcePickName,
  announcePlayerName,
  announceJoinedGame,
  announceLeftTable,
  announceLostConnection,
  announceNotAtTable,
  announceHandInPlay,
  announceMatchOver,
  announceNoSuchCard,
  announceNoSwapsLeft,
  announceCantFold,
  announceNotYourTurnToPlay,
  announceMustFollow,
  announceNothingToSay,
  announceSlowDown,
  announceThrowSomewhere,
  announceFlashbangCooling,
  announceThrewFlashbang,
  announceOnlyHostNewMatch,
  announceOnlyHostSettings,
  announceSettingsBetweenMatches,
  announceBotsNow,
  announceEveryoneStartsOn,
  announceOnlyHostAddBots,
  announceBotsJoinBetween,
  announceTableFull,
  announceOnlyHostRemoveBots,
  announceBotsLeaveBetween,
  announceNoBots,
  announceUnknownMove,
  announceNotYourTurnToSwap,
  announceReportedNotHere,
  announceReportSelf,
  announceReportsLimit,
  announceHandDeals,
  announceSuddenDeathHand,
  announceTrump,
  announceFolds,
  announceKeepsHand,
  announceSwapsOne,
  announceSwapsMany,
  announceOnlyOneLeft,
  announceTakesTrick,
  announceDonut,
  announceWinsMatch,
  announceTieSuddenDeath,
  announceNewMatch,
  announceBotNumbered,
  announceJoinedTable,
  announceNobodyByName,
  announceShotOwnPlacard,
  announceShotPlacard,
  announceShootSomething,
  announceDrawSomething,
  ...announceBotNames,
  announceSkillRookie,
  announceSkillRegular,
  announceSkillAmateur,
  announceSkillPro,
  announceSkillShark,
  announceSkillRookieBlurb,
  announceSkillRegularBlurb,
  announceSkillAmateurBlurb,
  announceSkillProBlurb,
  announceSkillSharkBlurb,
  ...announceBotTrickQuips,
  ...announceBotDonutQuips,
];
