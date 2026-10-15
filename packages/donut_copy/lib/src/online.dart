import 'line.dart';

// Online play: codes O1, O2, ... Never reuse or renumber a code: the
// text file refers to them. Add new ones at the end.

const onlineReportFailed = Line('O1', "The report didn't go through. Try again.");
const onlinePublicGame = Line('O2', 'Public game');
const onlineParty = Line('O3', 'Party');
const onlinePartyCode = Line('O4', 'Party {code}');
const onlineReconnecting = Line('O5', 'Connection lost. Reconnecting...');
const onlinePartyRefused = Line('O6', 'The party server refused.');
const onlineGameCenter = Line('O7', 'Game Center');
const onlineLostHost = Line('O8', 'Lost touch with the host.');
const onlineHostLeft = Line('O9', 'The host left, so this game is over.');
const onlineGameCenterUnavailable = Line('O10', "Game Center isn't available right now.");
const onlineGameCenterNoDevice = Line('O11', "Game Center isn't available on this device.");

// A Game Center host's refusals and table lines.
const onlineMissingSecret = Line('O12', 'Missing secret');
const onlinePickName = Line('O13', 'Pick a name');
const onlineNameTaken = Line('O14', 'Someone at the table already has that name.');
const onlineNotAtTable = Line('O15', 'Not at this table');
const onlineNotYourSeat = Line('O16', 'Not your seat');
const onlineSlowDown = Line('O17', 'Slow down');
const onlineFlashbangCooling = Line('O18', 'Flashbang cooling down');
const onlineOnlyHostRestart = Line('O19', 'Only the host can restart');
const onlineUnknownAction = Line('O20', 'Unknown action {action}');
const onlineNotYourTurnToPlay = Line('O21', 'Not your turn to play');
const onlineMustFollow = Line('O22', 'You must follow the lead suit');
const onlineBotTakesSeat = Line('O23', '{name} left. A bot takes their seat.');

const List<Line> onlineLines = [
  onlineReportFailed,
  onlinePublicGame,
  onlineParty,
  onlinePartyCode,
  onlineReconnecting,
  onlinePartyRefused,
  onlineGameCenter,
  onlineLostHost,
  onlineHostLeft,
  onlineGameCenterUnavailable,
  onlineGameCenterNoDevice,
  onlineMissingSecret,
  onlinePickName,
  onlineNameTaken,
  onlineNotAtTable,
  onlineNotYourSeat,
  onlineSlowDown,
  onlineFlashbangCooling,
  onlineOnlyHostRestart,
  onlineUnknownAction,
  onlineNotYourTurnToPlay,
  onlineMustFollow,
  onlineBotTakesSeat,
];
