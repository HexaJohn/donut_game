import 'line.dart';

// Dialogs and settings: codes D1, D2, ... Never reuse or renumber a code: the
// text file refers to them. Add new ones at the end.

// How to play
const dialogsHowToPlay = Line('D1', 'How to play');
const dialogsRulesGoal = Line('D2', 'The goal');
const dialogsRulesPlayers = Line('D3', '3 or more players. Everyone starts on {points} points.');
const dialogsRulesTricks = Line('D4', 'Every trick you take knocks a point off. First to 0 wins.');
const dialogsRulesDonut = Line('D5', 'Take no tricks in a hand and you get a donut: +{points} points.');
const dialogsRulesDealing = Line('D6', 'Dealing');
const dialogsRulesDeal = Line('D7', "Everyone gets {n} cards. The dealer's last card sets the trump suit.");
const dialogsRulesSwap = Line('D8', 'On your turn, swap up to {n} cards for new ones, or fold.');
const dialogsRulesFoldLimit = Line('D9', "You can't fold if you folded the last {n} hands.");
const dialogsRulesPlaying = Line('D10', 'Playing');
const dialogsRulesLead = Line('D11', 'The player after the dealer leads any card.');
const dialogsRulesFollow = Line('D12', 'Everyone else must follow the lead suit if they can.');
const dialogsRulesTrump = Line('D13', "If you can't follow, play anything. A trump beats every other suit.");
const dialogsRulesTakeTrick =
    Line('D14', 'Highest card of the lead suit (or highest trump) takes the trick and leads next.');
const dialogsRulesSuddenDeath = Line('D15', 'Sudden death');
const dialogsRulesPlayOn = Line('D16', 'If several players reach 0 in the same hand, they play on alone.');
const dialogsRulesFewestOut = Line('D17', 'After each sudden death hand, whoever took the fewest tricks is out.');
const dialogsRulesLastStanding = Line('D18', 'Last one standing wins.');
const dialogsGotIt = Line('D19', 'Got it');

// Theme picker
const dialogsThemeTitle = Line('D20', 'Theme');
const dialogsCampaignScenery = Line('D21', 'Campaign scenery');
const dialogsCampaignSceneryInfo =
    Line('D22', 'Play each venue in its own scene and on its own table. Off, your theme and table are used.');
const dialogsDone = Line('D23', 'Done');

// Settings
const dialogsSettingsTitle = Line('D24', 'Settings');
const dialogsSound = Line('D25', 'Sound');
const dialogsMusic = Line('D26', 'Music');
const dialogsNowPlaying = Line('D27', 'Now playing: {track}');
const dialogsNextTrack = Line('D28', 'Next');
const dialogsEffects = Line('D29', 'Effects');
const dialogsPrivacy = Line('D30', 'Privacy');
const dialogsShareStats = Line('D31', 'Share anonymous gameplay stats');
const dialogsShareStatsInfo = Line('D32',
    'Counts like matches played and campaign stages cleared, to help balance the game. Never your name or chat.');
const dialogsUnmute = Line('D33', 'Unmute {sound}');
const dialogsMute = Line('D34', 'Mute {sound}');
const dialogsVolumeOff = Line('D35', 'Off');
const dialogsVolumePercent = Line('D36', '{n}%');

// Theme names and descriptions
const dialogsThemeClassic = Line('D37', 'Classic');
const dialogsThemeClassicInfo = Line('D38', 'The original v1 look');
const dialogsThemeDonutLight = Line('D39', 'Donut Light');
const dialogsThemeDonutLightInfo = Line('D40', 'Fresh out of the oven');
const dialogsThemeDonutDark = Line('D41', 'Donut Dark');
const dialogsThemeDonutDarkInfo = Line('D42', 'Late-night snack');
const dialogsThemeMidnightCasino = Line('D43', 'Midnight Casino');
const dialogsThemeMidnightCasinoInfo = Line('D44', 'High rollers only');
const dialogsThemeNeonArcade = Line('D45', 'Neon Arcade');
const dialogsThemeNeonArcadeInfo = Line('D46', 'Insert coin');
const dialogsThemeStrawberry = Line('D47', 'Strawberry Sprinkles');
const dialogsThemeStrawberryInfo = Line('D48', 'Extra frosting');
const dialogsThemeRetroTerminal = Line('D49', 'Retro Terminal');
const dialogsThemeRetroTerminalInfo = Line('D50', '> donut.exe');

// Music track names
const dialogsTrackMenu = Line('D51', 'Menu theme');
const dialogsTrackOscuridad = Line('D52', 'Oscuridad');
const dialogsTrackSombra = Line('D53', 'Sombra');

// Tutorial: a practice hand with every card face up. D55-D69 and D72 were
// a slideshow, retired; don't reuse them.
const dialogsTutorialWelcome = Line('D54', 'Welcome to Donut');
const dialogsTutorialSkip = Line('D70', 'Skip');
const dialogsTutorialFullRules = Line('D71', 'Full rules');
const dialogsTutorialInvite =
    Line('D73', 'New here? Play a practice hand against two bots, with every card face up and tips as you go.');
const dialogsTutorialStart = Line('D74', 'Play the tutorial');
const dialogsTutorialLabel = Line('D75', 'Tutorial');
const dialogsCoachDeal = Line('D76', 'A practice hand: every card is face up, so you can see what everyone holds. Press Deal.');
const dialogsCoachDealing =
    Line('D77', 'Everyone gets {n} cards. The last card dealt is turned up, and its suit is trump.');
const dialogsCoachBotSwap = Line('D78',
    'Trump is {suit} this hand: a {suit} card beats any card of another suit. {name} is swapping weak cards for new ones.');
const dialogsCoachSwap = Line('D79',
    'Your move. Tap up to {n} weak cards to swap them for new ones, then press {button}. Try {cards}: low, and not trump.');
const dialogsCoachKeep = Line('D80', 'Your move. Your hand is strong: press {button} to keep it.');
const dialogsCoachBotPlays = Line('D81', '{name} plays. Each trick, everyone plays one card, in turn round the table.');
const dialogsCoachLead = Line('D82', 'You lead: play any card. Everyone else has to follow its suit if they can.');
const dialogsCoachFollowWin = Line('D83',
    '{suit} were led and you have some, so you must play one. Your {card} beats everything played so far.');
const dialogsCoachFollowLose = Line('D84',
    "{suit} were led and you have some, so you must play one. You can't beat the {best}: play your lowest.");
const dialogsCoachTrump =
    Line('D85', "No {suit}? Then you can play anything, and a trump beats it. Try your {card}.");
const dialogsCoachDiscard = Line('D86', 'No {suit}, and nothing that wins: throw away your lowest card.');
const dialogsCoachYouTook = Line('D87', "You took the trick! One point off your score: you're on {score}.");
const dialogsCoachBotTook = Line('D88', '{name} took the trick, and a point off their score.');
const dialogsCoachFolded = Line('D89', "You folded: you sit this hand out, so you take no tricks but can't get a donut.");
const dialogsTutorialDone = Line('D90', 'Tutorial complete');
const dialogsTutorialTricks = Line('D91', 'You took {n} of the {total} tricks: {n} points off your score.');
const dialogsTutorialDonut =
    Line('D92', "You took no tricks, so that's a donut: +{points} points. Take at least one trick to avoid it.");
const dialogsTutorialBotDonut = Line('D93', '{name} took no tricks and got a donut: +{points} points.');
const dialogsTutorialNextUp =
    Line('D94', 'A real match goes on hand after hand, from {points} points, until someone gets to 0.');
const dialogsTutorialPlayBots = Line('D95', 'Play vs bots');
const dialogsTutorialMenu = Line('D96', 'Main menu');

const List<Line> dialogsLines = [
  dialogsHowToPlay,
  dialogsRulesGoal,
  dialogsRulesPlayers,
  dialogsRulesTricks,
  dialogsRulesDonut,
  dialogsRulesDealing,
  dialogsRulesDeal,
  dialogsRulesSwap,
  dialogsRulesFoldLimit,
  dialogsRulesPlaying,
  dialogsRulesLead,
  dialogsRulesFollow,
  dialogsRulesTrump,
  dialogsRulesTakeTrick,
  dialogsRulesSuddenDeath,
  dialogsRulesPlayOn,
  dialogsRulesFewestOut,
  dialogsRulesLastStanding,
  dialogsGotIt,
  dialogsThemeTitle,
  dialogsCampaignScenery,
  dialogsCampaignSceneryInfo,
  dialogsDone,
  dialogsSettingsTitle,
  dialogsSound,
  dialogsMusic,
  dialogsNowPlaying,
  dialogsNextTrack,
  dialogsEffects,
  dialogsPrivacy,
  dialogsShareStats,
  dialogsShareStatsInfo,
  dialogsUnmute,
  dialogsMute,
  dialogsVolumeOff,
  dialogsVolumePercent,
  dialogsThemeClassic,
  dialogsThemeClassicInfo,
  dialogsThemeDonutLight,
  dialogsThemeDonutLightInfo,
  dialogsThemeDonutDark,
  dialogsThemeDonutDarkInfo,
  dialogsThemeMidnightCasino,
  dialogsThemeMidnightCasinoInfo,
  dialogsThemeNeonArcade,
  dialogsThemeNeonArcadeInfo,
  dialogsThemeStrawberry,
  dialogsThemeStrawberryInfo,
  dialogsThemeRetroTerminal,
  dialogsThemeRetroTerminalInfo,
  dialogsTrackMenu,
  dialogsTrackOscuridad,
  dialogsTrackSombra,
  dialogsTutorialWelcome,
  dialogsTutorialSkip,
  dialogsTutorialFullRules,
  dialogsTutorialInvite,
  dialogsTutorialStart,
  dialogsTutorialLabel,
  dialogsCoachDeal,
  dialogsCoachDealing,
  dialogsCoachBotSwap,
  dialogsCoachSwap,
  dialogsCoachKeep,
  dialogsCoachBotPlays,
  dialogsCoachLead,
  dialogsCoachFollowWin,
  dialogsCoachFollowLose,
  dialogsCoachTrump,
  dialogsCoachDiscard,
  dialogsCoachYouTook,
  dialogsCoachBotTook,
  dialogsCoachFolded,
  dialogsTutorialDone,
  dialogsTutorialTricks,
  dialogsTutorialDonut,
  dialogsTutorialBotDonut,
  dialogsTutorialNextUp,
  dialogsTutorialPlayBots,
  dialogsTutorialMenu,
];
