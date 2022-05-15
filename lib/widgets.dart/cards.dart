import 'package:donut_game/constants.dart';
import 'package:donut_game/modules/cards.dart';
import 'package:donut_game/modules/game.dart';
import 'package:donut_game/modules/players.dart';
import 'package:flutter/material.dart';

class PlayingCardWidget extends StatelessWidget {
  PlayingCardWidget(
      {Key? key,
      required this.card,
      this.back,
      this.size,
      this.label,
      this.trump})
      : super(key: key);

  final GameCard card;
  bool? back;
  double? size;
  String? label;
  Suit? trump;
  bool _trump = false;

  @override
  Widget build(BuildContext context) {
    _trump = card.suit == trump;
    back ??= false;
    size ??= 50;
    double height = 1 - (0.0125 * size! / 50);

    Widget? _label;

    if (label != null) {
      _label = Padding(
        padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
        child: Text(
          label!,
          overflow: TextOverflow.fade,
          maxLines: 1,
          softWrap: false,
        ),
      );
    }

    Text _cardText = back!
        ? Text(
            stringToCard['card back'] ?? '🃌',
            style: TextStyle(
              textBaseline: TextBaseline.ideographic,
              height: height,
              fontSize: size,
              color: Theme.of(context).primaryColor,
            ),
          )
        : Text(
            stringToCard[card.toString()] ?? '🃌',
            style: TextStyle(
              textBaseline: TextBaseline.ideographic,
              height: height,
              fontSize: size,
              color: card.toString().contains('hearts') ||
                      card.toString().contains('diamonds')
                  ? Colors.red
                  : Colors.black,
            ),
          );

    List<Widget> _children = [];
    _children.add(_cardText);
    if (_label != null) {
      _children.add(_label);
    }
    return SizedBox(
      width: size! * 0.8 + 3,
      child: Card(
          color: back == false && _trump == true ? Colors.yellow : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: Column(children: _children),
          )),
    );
  }
}

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
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
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
