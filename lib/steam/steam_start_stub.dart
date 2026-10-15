import 'package:donut_game/steam/steam.dart';

/// No Steam on the web.
SteamService startPlatformSteam() => SteamService(problem: 'Not a desktop build');
