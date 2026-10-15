import 'line.dart';
import 'announcements.dart';
import 'app.dart';
import 'campaign.dart';
import 'dialogs.dart';
import 'online.dart';
import 'shop.dart';
import 'table.dart';

export 'announcements.dart';
export 'app.dart';
export 'campaign.dart';
export 'dialogs.dart';
export 'online.dart';
export 'shop.dart';
export 'table.dart';

/// Every line, by area, in the text file's order.
const List<(String, List<Line>)> copyAreas = [
  ('App and home', appLines),
  ('The game table', tableLines),
  ('Online play', onlineLines),
  ('In-game announcements', announcementsLines),
  ('Campaign', campaignLines),
  ('Shop and career', shopLines),
  ('Dialogs and settings', dialogsLines),
];

/// Every line.
Iterable<Line> get allLines => copyAreas.expand((area) => area.$2);
