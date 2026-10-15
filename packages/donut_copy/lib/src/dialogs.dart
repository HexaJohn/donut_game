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
];
