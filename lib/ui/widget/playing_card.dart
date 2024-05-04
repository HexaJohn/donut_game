import 'package:donut_game/res/resources.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:flutter/material.dart';

class PlayingCardWidget extends StatelessWidget {
  PlayingCardWidget({Key? key, required this.card, this.back = false, this.size = 50, this.label, this.trump})
      : super(key: key);

  final GameCard card;
  final bool? back;
  final double? size;
  final String? label;
  final Suit? trump;
  late final double height = 1 - (0.0125 * size! / 50);
  late final bool _trump = card.suit == trump;

  @override
  Widget build(BuildContext context) {
    Widget? labelWidget;

    if (label != null) {
      labelWidget = Column(
        children: [
          Spacer(),
          Card(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2, left: 2, right: 2),
              child: Text(
                label!,
                overflow: TextOverflow.clip,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ),
        ],
      );
    }

    Text cardText = back!
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

    List<Widget> children = [];
    children.add(cardText);
    if (labelWidget != null) {
      children.add(labelWidget);
    }
    return SizedBox(
      width: size! * 0.8 + 3,
      height: size! * 1.2 + 0,
      child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0.0),
          ),
          color: back == false && _trump == true ? Colors.yellow : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: Stack(alignment: AlignmentDirectional.topCenter, children: children),
          )),
    );
  }
}
