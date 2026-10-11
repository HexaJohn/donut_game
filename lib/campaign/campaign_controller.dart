import 'dart:math';

import 'package:donut_game/campaign/campaign.dart';
import 'package:donut_game/data/settings.dart';
import 'package:donut_game/ui/game/game_controller.dart';

/// An offline match on one campaign stage: its opponents, target score,
/// table and backdrop.
class CampaignGameController extends OfflineGameController {
  CampaignGameController({required this.stage, required this.difficulty})
      : super(
          nickname: Settings.instance.nickname,
          bots: stage.opponents.length,
          opponents: [for (final opponent in stage.opponents) opponent.seat(difficulty)],
          target: stage.target,
        ) {
    _greet();
  }

  final Stage stage;
  final Difficulty difficulty;

  Venue get venue => venueOf(stage);

  @override
  String get label => '${venue.name} · ${stage.name}';

  /// The venue's scene and table, unless scenery is turned off in the theme
  /// picker; then the theme and the player's own table show instead.
  @override
  String? get backdrop => Settings.instance.venueScenery.value ? venue.backdrop : null;

  @override
  String? get environment => Settings.instance.venueScenery.value ? venue.environment : null;

  /// Replaying keeps the same table; say hello again.
  @override
  Future<void> newMatch() async {
    await super.newMatch();
    _greet();
  }

  void _greet() {
    game.say('', '${stage.boss ? 'Boss stage' : 'Stage'}: ${stage.name}. First to zero from ${stage.target} wins.',
        system: true);
    final random = Random();
    for (final player in game.players) {
      final lines = player.lines?.greet ?? const [];
      if (lines.isNotEmpty) game.say(player.name, lines[random.nextInt(lines.length)]);
    }
  }

  /// A rival's parting shot after beating you, if they have one.
  void gloat(String winner) {
    final player = game.players.where((p) => p.name == winner).firstOrNull;
    final lines = player?.lines?.win ?? const [];
    if (lines.isNotEmpty) game.say(player!.name, lines[Random().nextInt(lines.length)]);
  }
}
