import 'package:donut_game/res/resources.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/server.dart';

class GameCard {
  GameCard(this.suit, this.value);

  Suit suit;
  Value value;
  CardState state = CardState.unknown;
  GamePlayer? belongsTo;

  int get points => valueToScore[value] ?? 0;

  @override
  String toString() {
    return "${valueToString[value]} of ${suitToString[suit]}";
  }

  Map<String, String> toJson() {
    return {
      "suit": suitToString[suit]!,
      "value": valueToString[value]!,
      "state": cardStateToString[state]!,
      "belongsTo": belongsTo?.name ?? 'nobody',
    };
  }

  static GameCard? fromJson(Map<String, dynamic> element) {
    try {
      print("table card belongs to ${element['belongsTo']}");
      return GameCard(stringToSuit[element['suit']]!, stringToValue[element['value']]!)
        ..state = stringToCardState[element['state']]!
        ..belongsTo = serverGame.playerDB.values.firstWhere((db) => db.name == element['belongsTo']);
    } catch (e, s) {
      print('invalid card');
      print(s);
      return null;
    }
  }

  static List<Map<String, String>> jsonArray(List<GameCard> value) {
    List<Map<String, String>> output = [];
    value.forEach((element) {
      output.add(element.toJson());
    });
    return output;
  }

  @override
  bool operator ==(other) => other is GameCard && toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;
}
