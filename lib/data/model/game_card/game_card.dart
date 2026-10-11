import 'dart:math';

import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_engine/donut_engine.dart' show PlayingCard;
import 'package:donut_game/ws_server.dart';

class GameCard implements PlayingCard {
  GameCard(this.suit, this.value);

  /// A card whose face this player isn't allowed to see: someone else's
  /// hand, the deck or the discard pile. Only its tracking id is known.
  GameCard.hidden(String tid)
      : suit = Suit.values.first,
        value = Value.values.first,
        hidden = true {
    this.tid = tid;
  }

  Suit suit;
  Value value;
  CardState state = CardState.unknown;
  GamePlayer? belongsTo;

  /// Whether the face is unknown here.
  bool hidden = false;

  /// Follows the card on screen as it moves, without saying what it is.
  /// Drawn afresh whenever the card goes back into the deck, so nobody can
  /// follow a card they saw face up into someone's next hand.
  String? _tid;

  // Drawn only when something reads it, so shuffling in simulations (which
  // never look) costs nothing
  String get tid => _tid ??= newTid();
  set tid(String value) => _tid = value;

  /// What the board keys this card's widget by.
  String get key => tid;

  /// Forgets the tracking id; the next read draws a new one.
  void retag() => _tid = null;

  static final Random _random = Random.secure();
  static const _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

  static String newTid() =>
      String.fromCharCodes(List.generate(10, (_) => _alphabet.codeUnitAt(_random.nextInt(_alphabet.length))));

  int get points => valueToScore[value] ?? 0;

  @override
  String toString() {
    return hidden ? 'hidden card $tid' : "${valueToString[value]} of ${suitToString[suit]}";
  }

  /// [hide] leaves out the face: just the tracking id and whose it is.
  Map<String, String> toJson({bool hide = false}) {
    if (hide) return {"tid": tid, "belongsTo": belongsTo?.name ?? 'nobody'};
    return {
      "tid": tid,
      "suit": suitToString[suit]!,
      "value": valueToString[value]!,
      "state": cardStateToString[state]!,
      "belongsTo": belongsTo?.name ?? 'nobody',
    };
  }

  static GameCard? fromJson(Map<String, dynamic> element) {
    try {
      final owners = serverGame.playerDB.values.where((db) => db.name == element['belongsTo']);
      final card = element['suit'] == null
          ? (GameCard.hidden('${element['tid']}')..state = CardState.held)
          : (GameCard(stringToSuit[element['suit']]!, stringToValue[element['value']]!)
            ..state = stringToCardState[element['state']]!);
      if (element['tid'] is String) card.tid = element['tid'];
      return card..belongsTo = owners.isEmpty ? null : owners.first;
    } catch (e) {
      return null;
    }
  }

  static List<Map<String, String>> jsonArray(List<GameCard> value, {bool hide = false}) =>
      [for (final card in value) card.toJson(hide: hide)];

  @override
  bool operator ==(other) => other is GameCard && toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;
}
