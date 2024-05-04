import 'package:donut_game/res/resources.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:flutter/material.dart';

class PlayingCardWidget extends StatelessWidget {
  PlayingCardWidget({Key? key, required this.card, this.back, this.size, this.label, this.trump}) : super(key: key);

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
          overflow: TextOverflow.clip,
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
              fontFamily: 'FluentIcons',
              fontSize: size,
              color: Theme.of(context).primaryColor,
            ),
          )
        : Text(
            stringToCard[card.toString()] ?? '🃌',
            style: TextStyle(
              textBaseline: TextBaseline.ideographic,
              height: height,
              fontFamily: 'FluentIcons',
              fontSize: size,
              color: card.toString().contains('hearts') || card.toString().contains('diamonds')
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
