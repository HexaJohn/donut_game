import 'package:donut_game/res/resources.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/ui/widget/playing_card.dart';
import 'package:flutter/material.dart';

class PlayingCardStackWidget extends StatelessWidget {
  PlayingCardStackWidget({required this.cards, Key? key}) : super(key: key);

  List<GameCard> cards;
  late PlayingCardWidget? bottomCard;
  List<Widget> _children = [];

  @override
  Widget build(BuildContext context) {
    Material _label = Material(
        color: Colors.black,
        elevation: 5.0,
        borderRadius: BorderRadius.circular(25),
        child: SizedBox(
            width: 50,
            height: 50,
            child: Center(
                child: Text(
              cards.length.toString(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ))));
    try {
      bottomCard = PlayingCardWidget(
        card: cards.last,
        size: 100,
        label: 'Discard',
        back: cards.last.state == CardState.folded,
      );
      _children.add(bottomCard!);
    } catch (e) {
      // TODO
    }

    _children.add(_label);

    return Stack(
      alignment: AlignmentDirectional.center,
      children: _children,
    );
  }
}
