import 'package:donut_game/res/enums/card_state.dart';

Map<CardState, String> cardStateToString = {
  CardState.deck: 'deck',
  CardState.held: 'held',
  CardState.swap: 'swap',
  CardState.folded: 'folded',
  CardState.played: 'played',
  CardState.unknown: 'unknown'
};

Map<String, CardState> stringToCardState = {
  'deck': CardState.deck,
  'held': CardState.held,
  'swap': CardState.swap,
  'folded': CardState.folded,
  'played': CardState.played,
  'unknown': CardState.unknown
};
