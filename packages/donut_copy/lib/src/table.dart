import 'line.dart';

// The game table: codes G1, G2, ... Never reuse or renumber a code: the
// text file refers to them. Add new ones at the end.

const tableSpectating = Line('G1', 'Spectating');
const tableHideChat = Line('G2', 'Hide chat');
const tableChat = Line('G3', 'Chat');
const tableMenu = Line('G4', 'Menu');
const tableHowToPlay = Line('G5', 'How to play');
const tableTheme = Line('G6', 'Theme');
const tableSettings = Line('G7', 'Settings');
const tableTableSettings = Line('G8', 'Table settings');
const tableAddBot = Line('G9', 'Add a bot');
const tableRemoveBot = Line('G10', 'Remove a bot');
const tableRestartServerGame = Line('G11', 'Restart server game');
const tableRestartMatch = Line('G12', 'Restart match');
const tableLeaveGame = Line('G13', 'Leave game');
const tableRestartServerTitle = Line('G14', 'Restart the server game?');
const tableRestartMatchTitle = Line('G15', 'Restart the match?');
const tableRestartServerBody = Line('G16', 'Everyone at the table goes back to the lobby and scores are wiped.');
const tableRestartMatchBody = Line('G17', 'Scores go back to {target} and a new match starts.');
const tableCancel = Line('G18', 'Cancel');
const tableRestart = Line('G19', 'Restart');
const tableWaitingToJoin = Line('G20', 'Waiting for players to join');
const tableReadyWhenYouAre = Line('G21', 'Ready when you are');
const tableNextHandIn = Line('G22', 'Next hand in {seconds}s. Ready ({ready}/{total})');
const tableTapReady = Line('G23', "Tap I'm ready for the next hand ({ready}/{total} ready)");
const tableWaitingForReady = Line('G24', 'Waiting for players to be ready ({ready}/{total})');
const tableDealing = Line('G25', 'Dealing');
const tableYouFolded = Line('G26', 'You folded this hand');
const tableYourSwapMove = Line('G27', 'Your move: pick up to {max} cards to swap ({picked} picked)');
const tableChoosingSwaps = Line('G28', '{name} is choosing swaps');
const tableChoosingSwapsYouSwapped = Line('G29', "{name} is choosing swaps. You've swapped.");
const tableChoosingSwapsYouNext = Line('G30', "{name} is choosing swaps. You're next.");
const tableChoosingSwapsMoreBefore = Line('G31', '{name} is choosing swaps. {n} more before you.');
const tableYourLead = Line('G32', 'Your lead: play any card');
const tableYourTurnFollow = Line('G33', 'Your turn: follow suit if you can');
const tableNextTrickComingUp = Line('G34', 'Next trick coming up');
const tableWaitingFor = Line('G35', 'Waiting for {name}');
const tableNextTrick = Line('G36', 'Next trick');
const tableMatchOver = Line('G37', 'Match over');
const tableWonTheMatch = Line('G38', '{name} won the match');
const tableDeal = Line('G39', 'Deal');
const tableWait = Line('G40', 'Wait');
const tableReady = Line('G41', 'Ready');
const tableImReady = Line('G42', "I'm ready");
const tableNoFoldingSuddenDeath = Line('G43', 'No folding in sudden death');
const tableFoldedLastHands = Line('G44', 'You folded the last {n} hands');
const tableFoldHint = Line('G45', 'Sit this hand out. No tricks, but no donut either.');
const tableFold = Line('G46', 'Fold');
const tableKeepHand = Line('G47', 'Keep hand');
const tableSwapCount = Line('G48', 'Swap {n}');
const tableNewMatch = Line('G49', 'New match');
const tableMarker = Line('G50', 'Marker');
const tableEraser = Line('G51', 'Eraser');
const tableFlashbang = Line('G52', 'Flashbang');
const tableFlashbangCooling = Line('G53', 'Flashbang (cooling down)');
const tableDonutStamp = Line('G54', 'Donut stamp');
const tableConfettiCannon = Line('G55', 'Confetti cannon');
const tableRevolver = Line('G56', 'Revolver');
const tableDeckCount = Line('G57', 'Deck · {n}');
const tableDiscardCount = Line('G58', 'Discard · {n}');
const tableYou = Line('G59', 'You');
const tableHintShoot = Line('G60', 'Click to shoot');
const tableHintDraw = Line('G61', 'Drag to draw on the table');
const tableHintErase = Line('G62', 'Drag to rub out ink');
const tableHintFlashbang = Line('G63', 'Click the table to throw it');
const tableHintStamp = Line('G64', 'Click the table to stamp a donut');
const tableHintConfetti = Line('G65', 'Click the table to fire');
const tableWhySwapped = Line('G66', "You've swapped this hand. Waiting for {name}.");
const tableWhyYouNext = Line('G67', "Not your turn to swap yet. {name} is choosing, and you're next.");
const tableWhyMoreBefore = Line('G68', 'Not your turn to swap yet. {name} is choosing, then {n} more before you.');
const tableWhyPlaying = Line('G69', 'Wait for your turn. {name} is playing.');
const tableSwapTag = Line('G70', 'SWAP');
const tableSeatChampion = Line('G71', 'Champion!');
const tableSeatSittingOut = Line('G72', 'Sitting out');
const tableSeatFolded = Line('G73', 'Folded');
const tableSeatChoosingSwaps = Line('G74', 'Choosing swaps');
const tableSeatThinking = Line('G75', 'Thinking');
const tableSeatSwapped = Line('G76', 'Swapped');
const tableSeatUpNext = Line('G77', 'Up next');
const tableSeatWaitingToSwap = Line('G78', 'Waiting to swap');
const tableSeatReady = Line('G79', 'Ready');
const tableDealer = Line('G80', 'Dealer');
const tableDealerBadge = Line('G81', 'D');
const tablePointsLeft = Line('G82', 'Points left');
const tableTricksOne = Line('G83', '{n} trick this hand');
const tableTricksMany = Line('G84', '{n} tricks this hand');
const tableDonutsOne = Line('G85', '{n} donut this match');
const tableDonutsMany = Line('G86', '{n} donuts this match');
const tableWins = Line('G87', 'WINS');
const tableLead = Line('G88', 'LEAD');
const tableTrumpChip = Line('G89', 'TRUMP');
const tableToolEmpty = Line('G90', 'Empty! Right-click or Esc to put it down and reload');
const tableToolHint = Line('G91', '{action} · Right-click or Esc to put it down');
const tableSuddenDeath = Line('G92', 'Sudden death');
const tableHandNumber = Line('G93', 'Hand {n}');
const tableYouDeal = Line('G94', 'You deal');
const tableDeals = Line('G95', '{name} deals');
const tableTrumpIs = Line('G96', 'Trump is {suit}');
const tableTrumpBeats = Line('G97', 'Beats every other suit this hand');
const tableHandOver = Line('G98', 'Hand over');
const tableNoDonuts = Line('G99', 'No donuts this hand');
const tableGotADonut = Line('G100', '\u{1F369} {names} got a donut');
const tableSuddenDeathBang = Line('G101', 'Sudden death!');
const tableSuddenDeathSubtitle = Line('G102', '{players}. Fewest tricks is out.');
const tableVersus = Line('G103', 'vs');
const tableYouTakeTrick = Line('G104', 'You take the trick!');
const tableTakesIt = Line('G105', '{name} takes it');
const tableYourMove = Line('G106', 'Your move');
const tableYourMoveSubtitle = Line('G107', 'Tap up to {max} cards to swap, or fold');
const tableYourTurn = Line('G108', 'Your turn');
const tableLeadAny = Line('G109', 'Lead with any card');
const tableFollowSuit = Line('G110', 'Follow {suit} if you can');
const tableLeaveTitle = Line('G111', 'Leave the game?');
const tableLeaveOnline = Line('G112', 'You can rejoin with the same nickname.');
const tableLeaveOffline = Line('G113', 'This match will be lost.');
const tableStay = Line('G114', 'Stay');
const tableLeave = Line('G115', 'Leave');
const tableYouWin = Line('G116', 'You win!');
const tablePlayerWins = Line('G117', '{name} wins!');
const tableMatchTime = Line('G118', 'Match time {time}');
const tablePlace = Line('G119', '{n}.');
const tableMainMenu = Line('G120', 'Main menu');
const tablePlayAgain = Line('G121', 'Play again');
const tableBossDefeated = Line('G122', 'Boss defeated on {difficulty}');
const tableStageCleared = Line('G123', 'Stage cleared on {difficulty}');
const tableStageOn = Line('G124', '{stage} on {difficulty}');
const tableCampaign = Line('G125', 'Campaign');
const tableRetry = Line('G126', 'Retry');
const tableNextStage = Line('G127', 'Next stage');
const tablePublicGame = Line('G128', 'Public game');
const tablePartyCode = Line('G129', 'Party code');
const tableCodeCopied = Line('G130', 'Copied. Send it to your friends.');
const tableCopy = Line('G131', 'Copy');
const tableUnmuteChat = Line('G132', 'Unmute chat');
const tableMuteChat = Line('G133', 'Mute chat');
const tableThisGameOnly = Line('G134', 'For this game only');
const tableUnblock = Line('G135', 'Unblock');
const tableBlock = Line('G136', 'Block');
const tableUnblockHint = Line('G137', "You'll see their chat again");
const tableBlockHint = Line('G138', "Hides their chat, and Find a game won't seat you with them");
const tableReport = Line('G139', 'Report');
const tableReportHint = Line('G140', 'Sends their recent chat to be reviewed');
const tableReasonHarassment = Line('G141', 'Harassment or bullying');
const tableReasonHate = Line('G142', 'Hate speech');
const tableReasonSexual = Line('G143', 'Sexual content');
const tableReasonName = Line('G144', 'Offensive name');
const tableReasonCheating = Line('G145', 'Cheating');
const tableReasonSpam = Line('G146', 'Spam');
const tableReasonOther = Line('G147', 'Something else');
const tableReportTitle = Line('G148', 'Report {name}');
const tableReportNoteHint = Line('G149', 'Anything to add? (optional)');
const tableReportSent = Line('G150', 'Thanks. Your report was sent.');
const tableSendReport = Line('G151', 'Send report');
const tableBlockedPlayers = Line('G152', 'Blocked players');
const tableNobodyBlocked = Line('G153', 'Nobody. Tap a player at an online table to block them.');
const tableDone = Line('G154', 'Done');
const tableQuickGg = Line('G155', 'GG');
const tableQuickNiceOne = Line('G156', 'Nice one!');
const tableTableTalk = Line('G157', 'Table talk');
const tableClose = Line('G158', 'Close');
const tableSaySomething = Line('G159', 'Say something...');
const tableReportingUnavailable = Line('G160', "Reporting isn't available here.");
const tableOfflineLabel = Line('G161', 'Offline vs bots');
const tableOnlineAtLabel = Line('G162', 'Online at {host}:{port}');
const tableServerNoAnswer = Line('G163', 'The server at {host}:{port} did not answer.');
const tableCouldNotReachHost = Line('G164', 'Could not reach {host}:{port}.');
const tableServerRefused = Line('G165', 'The server refused to let you in ({status}).');
const tableConnectionLost = Line('G166', 'Connection lost. Reconnecting...');
const tableCouldNotReachServer = Line('G167', 'Could not reach the server.');
const tableTrump = Line('G168', 'Trump');

const List<Line> tableLines = [
  tableSpectating,
  tableHideChat,
  tableChat,
  tableMenu,
  tableHowToPlay,
  tableTheme,
  tableSettings,
  tableTableSettings,
  tableAddBot,
  tableRemoveBot,
  tableRestartServerGame,
  tableRestartMatch,
  tableLeaveGame,
  tableRestartServerTitle,
  tableRestartMatchTitle,
  tableRestartServerBody,
  tableRestartMatchBody,
  tableCancel,
  tableRestart,
  tableWaitingToJoin,
  tableReadyWhenYouAre,
  tableNextHandIn,
  tableTapReady,
  tableWaitingForReady,
  tableDealing,
  tableYouFolded,
  tableYourSwapMove,
  tableChoosingSwaps,
  tableChoosingSwapsYouSwapped,
  tableChoosingSwapsYouNext,
  tableChoosingSwapsMoreBefore,
  tableYourLead,
  tableYourTurnFollow,
  tableNextTrickComingUp,
  tableWaitingFor,
  tableNextTrick,
  tableMatchOver,
  tableWonTheMatch,
  tableDeal,
  tableWait,
  tableReady,
  tableImReady,
  tableNoFoldingSuddenDeath,
  tableFoldedLastHands,
  tableFoldHint,
  tableFold,
  tableKeepHand,
  tableSwapCount,
  tableNewMatch,
  tableMarker,
  tableEraser,
  tableFlashbang,
  tableFlashbangCooling,
  tableDonutStamp,
  tableConfettiCannon,
  tableRevolver,
  tableDeckCount,
  tableDiscardCount,
  tableYou,
  tableHintShoot,
  tableHintDraw,
  tableHintErase,
  tableHintFlashbang,
  tableHintStamp,
  tableHintConfetti,
  tableWhySwapped,
  tableWhyYouNext,
  tableWhyMoreBefore,
  tableWhyPlaying,
  tableSwapTag,
  tableSeatChampion,
  tableSeatSittingOut,
  tableSeatFolded,
  tableSeatChoosingSwaps,
  tableSeatThinking,
  tableSeatSwapped,
  tableSeatUpNext,
  tableSeatWaitingToSwap,
  tableSeatReady,
  tableDealer,
  tableDealerBadge,
  tablePointsLeft,
  tableTricksOne,
  tableTricksMany,
  tableDonutsOne,
  tableDonutsMany,
  tableWins,
  tableLead,
  tableTrumpChip,
  tableToolEmpty,
  tableToolHint,
  tableSuddenDeath,
  tableHandNumber,
  tableYouDeal,
  tableDeals,
  tableTrumpIs,
  tableTrumpBeats,
  tableHandOver,
  tableNoDonuts,
  tableGotADonut,
  tableSuddenDeathBang,
  tableSuddenDeathSubtitle,
  tableVersus,
  tableYouTakeTrick,
  tableTakesIt,
  tableYourMove,
  tableYourMoveSubtitle,
  tableYourTurn,
  tableLeadAny,
  tableFollowSuit,
  tableLeaveTitle,
  tableLeaveOnline,
  tableLeaveOffline,
  tableStay,
  tableLeave,
  tableYouWin,
  tablePlayerWins,
  tableMatchTime,
  tablePlace,
  tableMainMenu,
  tablePlayAgain,
  tableBossDefeated,
  tableStageCleared,
  tableStageOn,
  tableCampaign,
  tableRetry,
  tableNextStage,
  tablePublicGame,
  tablePartyCode,
  tableCodeCopied,
  tableCopy,
  tableUnmuteChat,
  tableMuteChat,
  tableThisGameOnly,
  tableUnblock,
  tableBlock,
  tableUnblockHint,
  tableBlockHint,
  tableReport,
  tableReportHint,
  tableReasonHarassment,
  tableReasonHate,
  tableReasonSexual,
  tableReasonName,
  tableReasonCheating,
  tableReasonSpam,
  tableReasonOther,
  tableReportTitle,
  tableReportNoteHint,
  tableReportSent,
  tableSendReport,
  tableBlockedPlayers,
  tableNobodyBlocked,
  tableDone,
  tableQuickGg,
  tableQuickNiceOne,
  tableTableTalk,
  tableClose,
  tableSaySomething,
  tableReportingUnavailable,
  tableOfflineLabel,
  tableOnlineAtLabel,
  tableServerNoAnswer,
  tableCouldNotReachHost,
  tableServerRefused,
  tableConnectionLost,
  tableCouldNotReachServer,
  tableTrump,
];
