import 'dart:developer';
import 'dart:io';
import 'dart:math';

import 'package:donut_game/constants.dart';
import 'package:donut_game/modules/cards.dart';
import 'package:donut_game/modules/game.dart';
import 'package:donut_game/modules/players.dart';
import 'package:donut_game/widgets.dart/cards.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OfflineGamePage extends StatefulWidget {
  const OfflineGamePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<OfflineGamePage> createState() => _OfflineGamePageState();
}

class _OfflineGamePageState extends State<OfflineGamePage> {
  int _counter = 0;
  Game game = Game();
  late final GamePlayer localPlayer =
      GamePlayer('username', game.players.length + 1, true);

  @override
  void initState() {
    game.addBot();
    game.addLocalPlayer(localPlayer);
    game.addBot();
    game.addBot();
    game.addBot();
    game.state.value = GameState.waitingToDeal;

    super.initState();
  }

  void deal() async {
    await game.deal();
    // game.state.value = GameState.swapping;
  }

  Widget layoutSwapActions(int index) {
    final player = localPlayer;
    final _card = localPlayer.hand.cards.value.elementAt(index);
    switch (_card.state) {
      case CardState.held:
        return ElevatedButton(
            onPressed: () {
              setState(() {
                player.hand.cards.value[index].state = CardState.swap;
                player.swaps.value--;
              });
            },
            child: Text('Swap',
                style: TextStyle(
                    // color: Colors.red,
                    )));
      case CardState.swap:
        return ElevatedButton(
            style: ButtonStyle(
                backgroundColor:
                    MaterialStateColor.resolveWith((states) => Colors.red)),
            onPressed: () {
              setState(() {
                player.hand.cards.value[index].state = CardState.held;
                player.swaps.value++;
              });
            },
            child: Text('Cancel',
                style: TextStyle(
                    // color: Colors.red,
                    )));
      default:
        return ElevatedButton(
            style: ButtonStyle(
                overlayColor: MaterialStateColor.resolveWith(
                    (states) => Colors.red.shade50)),
            onPressed: () {},
            child: Text('!',
                style: TextStyle(
                    // color: Colors.red,
                    )));
    }
  }

  Widget layoutPlayActions(int index) {
    final player = localPlayer;
    final _card = localPlayer.hand.cards.value.elementAt(index);
    var _lead = game.leadingCard?.suit;
    bool throwoff = false;
    if (player.hand.cards.value
        .any((element) => element.suit == game.leadingCard?.suit)) {
      throwoff = false;
    } else {
      throwoff = true;
    }
    if (game.table.cards.value.isEmpty) {
      throwoff = false;
    }
    if (_card.suit == _lead || _lead == null || throwoff) {
      switch (_card.state) {
        case CardState.held:
          return ElevatedButton(
              onPressed: () {
                setState(() {
                  player.cardToPlay = _card;
                });
              },
              child: Text(
                  !throwoff
                      ? 'Play'
                      : _card.suit == game.trumpSuit.value
                          ? 'Trump'
                          : 'Throw',
                  style: TextStyle(
                      // color: Colors.red,
                      )));
        case CardState.swap:
          return ElevatedButton(
              style: ButtonStyle(
                  overlayColor: MaterialStateColor.resolveWith(
                      (states) => Colors.red.shade50)),
              onPressed: () {
                setState(() {
                  player.hand.cards.value[index].state = CardState.held;
                  player.swaps.value++;
                });
              },
              child: Text('Cancel',
                  style: TextStyle(
                      // color: Colors.red,
                      )));
        default:
          return ElevatedButton(
              style: ButtonStyle(
                  overlayColor: MaterialStateColor.resolveWith(
                      (states) => Colors.red.shade50)),
              onPressed: () {},
              child: Text('!',
                  style: TextStyle(
                      // color: Colors.red,
                      )));
      }
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // shrinkWrap: true,
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Text(
                'Donut: A Card Game',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
            ListTile(
              title: const Text('Leaderboard:'),
              // onTap: () {
              //   // Update the state of the app
              //   // ...
              //   // Then close the drawer
              //   Navigator.pop(context);
              // },
            ),
            Container(
              // margin: EdgeInsets.only(top: 16),
              // height: 165,
              child: ListView.builder(
                // scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemCount: game.players.length,
                itemBuilder: (context, playerIndex) {
                  return Container(
                      width: 150,
                      child: ListTile(
                        visualDensity: VisualDensity.comfortable,
                        // contentPadding: EdgeInsets.all(0),
                        dense: true,
                        leading: Icon(
                          game.players[playerIndex].human
                              ? game.players[playerIndex] == localPlayer
                                  ? Icons.account_circle
                                  : Icons.account_circle_outlined
                              : Icons.psychology_rounded,
                        ),
                        title: Text(game.players[playerIndex].name),
                        subtitle: Text(
                            'Score: ${game.players[playerIndex].score.value} | Donuts: ${game.players[playerIndex].donuts.value}'),
                      ));
                },
              ),
            ),
            // Expanded(child: Container()),
            ListTile(
              title: const Text('Back to game'),
              onTap: () {
                // Update the state of the app
                // ...
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(
          widget.title,
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        toolbarTextStyle: TextStyle(color: Colors.black),
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),

        // TextStyle(color: Theme.of(context).colorScheme.onBackground),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          // TextButton(
          //   onPressed: () {
          //     var _gameState;
          //     debugger();
          //     _gameState = game;
          //   },
          //   child: Text(
          //     'debugger',
          //     style: TextStyle(),
          //   ),
          // ),
          Container(
            margin: EdgeInsets.only(top: 16),
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: game.players.length,
              itemBuilder: (context, playerIndex) {
                return Container(
                  width: 150,
                  child: ValueListenableBuilder(
                      valueListenable: game.activePlayer,
                      builder: (context, GamePlayer value, child) {
                        return Card(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Card(
                                  color: value == game.players[playerIndex]
                                      ? Colors.lightGreenAccent.shade100
                                      : Colors.white,
                                  child: Stack(
                                    children: [
                                      ValueListenableBuilder(
                                          valueListenable:
                                              game.players[playerIndex].winner,
                                          builder:
                                              (context, bool value, child) {
                                            return value
                                                ? LinearProgressIndicator(
                                                    minHeight: 33,
                                                    color: Colors.yellow,
                                                    backgroundColor:
                                                        Colors.yellow.shade100,
                                                  )
                                                : Container();
                                          }),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 2.0,
                                                  left: 8.0,
                                                  right: 4.0),
                                              child: ValueListenableBuilder(
                                                  valueListenable: game.dealer,
                                                  builder:
                                                      (context, value, child) {
                                                    return Icon(
                                                      value ==
                                                              game.players[
                                                                  playerIndex]
                                                          ? Icons.star
                                                          : game
                                                                  .players[
                                                                      playerIndex]
                                                                  .human
                                                              ? game.players[
                                                                          playerIndex] ==
                                                                      localPlayer
                                                                  ? Icons
                                                                      .account_circle
                                                                  : Icons
                                                                      .account_circle_outlined
                                                              : Icons
                                                                  .psychology_rounded,
                                                      size: 14,
                                                    );
                                                  }),
                                            ),
                                            Text(
                                              game.players
                                                  .toList()[playerIndex]
                                                  .name,
                                            ),
                                            Expanded(child: Container()),
                                            ValueListenableBuilder(
                                                valueListenable: game
                                                    .players[playerIndex].score,
                                                builder: (context, int value,
                                                    child) {
                                                  return Text(
                                                    '$value',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  );
                                                }),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ValueListenableBuilder(
                                valueListenable:
                                    game.players[playerIndex].hand.cards,
                                builder:
                                    (context, List<GameCard> value, child) {
                                  List<Widget> children = List.generate(
                                    value.length,
                                    (index) {
                                      var child = (game.dealer.value ==
                                                  game.players[playerIndex] &&
                                              index == 4 &&
                                              (game.state.value ==
                                                      GameState.swapping ||
                                                  game.state.value ==
                                                      GameState
                                                          .waitingForPlayerToSwap))
                                          ? PlayingCardWidget(
                                              card: value[index],
                                              back: false,
                                              trump: game.trumpSuit.value,
                                            )
                                          : PlayingCardWidget(
                                              card: value[index],
                                              back: true,
                                            );
                                      return child;
                                    },
                                  );
                                  return Wrap(
                                    children: children,
                                    alignment: WrapAlignment.center,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                );
              },
            ),
          ),
          Container(
            child: ValueListenableBuilder(
                valueListenable: game.trumpSuit,
                builder: (context, Suit value, child) {
                  return Text(
                      "Current Trump: ${suitToString[value] ?? 'none'}");
                }),
          ),
          Container(
            decoration: BoxDecoration(
                color: Colors.green.shade900,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 1),
                      blurRadius: 1.0)
                ]),
            padding: EdgeInsets.all(8),
            margin: EdgeInsets.all(8),
            height: 145,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: game.table.cards,
                    builder: (context, List<GameCard> value, child) {
                      return ListView.builder(
                          reverse: false,
                          // shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: value.length,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                PlayingCardWidget(
                                  card: value[index],
                                  size: index == 0 ? 100 : 75,
                                  trump: game.trumpSuit.value,
                                  label:
                                      // "${value[index].belongsTo.toString()}: ${scoreThis(value[index], game)}",
                                      "${value[index].belongsTo.toString()}",
                                ),
                              ],
                            );
                          });
                    },
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: game.discard.cards,
                  builder: (context, List<GameCard> value, child) {
                    return PlayingCardStackWidget(
                      cards: value,
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 1),
                      blurRadius: 1.0)
                ]),
            height: 175,
            child: ValueListenableBuilder(
                valueListenable: game.trumpSuit,
                builder: (useless, unnusedValue, nope) {
                  return ValueListenableBuilder(
                      valueListenable: localPlayer.hand.cards,
                      builder: (context, snapshot, child) {
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          // shrinkWrap: true,
                          itemCount: localPlayer.hand.cards.value.length,
                          itemBuilder: (context, index) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                PlayingCardWidget(
                                  card: localPlayer.hand.cards.value[index],
                                  size: 100,
                                  trump: game.trumpSuit.value,
                                ),
                                ValueListenableBuilder(
                                    valueListenable: game.state,
                                    builder: (context, value, child) {
                                      return Container(
                                        color: Colors.amber
                                            .withAlpha(Random().nextInt(255)),
                                        child: Row(
                                          // alignment: MainAxisAlignment.center,
                                          children: [
                                            ValueListenableBuilder(
                                              builder: (context, value,
                                                      child) =>
                                                  (value != 0 ||
                                                              localPlayer
                                                                      .hand
                                                                      .cards
                                                                      .value[
                                                                          index]
                                                                      .state ==
                                                                  CardState
                                                                      .swap) &&
                                                          game.state.value ==
                                                              GameState
                                                                  .waitingForPlayerToSwap
                                                      ? layoutSwapActions(index)
                                                      : Container(),
                                              valueListenable:
                                                  localPlayer.swaps,
                                            ),
                                            ValueListenableBuilder(
                                              builder: (context,
                                                      GameState value, child) =>
                                                  (value == GameState.playing &&
                                                          game.activePlayerLazy ==
                                                              localPlayer)
                                                      ? layoutPlayActions(index)
                                                      : Container(),
                                              valueListenable: game.state,
                                            )
                                          ],
                                        ),
                                      );
                                    })
                              ],
                            );
                          },
                        );
                      });
                }),
          ),
        ],
      ),
      floatingActionButton: ValueListenableBuilder(
          valueListenable: game.state,
          builder: (context, GameState value, child) {
            switch (value) {
              case GameState.waitingToDeal:
                return FloatingActionButton(
                  onPressed: () => setState(() {
                    deal();
                  }),
                  tooltip: 'Deal',
                  child: const Icon(Icons.style_sharp),
                );
              case GameState.dealing:
                return Container();

              case GameState.waitingForPlayerToSwap:
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FloatingActionButton(
                        onPressed: () async {
                          localPlayer.skip = true;
                          localPlayer.notReady = false;
                          localPlayer.donut = false;
                        },
                        tooltip: 'Fold',
                        child: const Icon(Icons.close),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FloatingActionButton(
                        onPressed: () async {
                          localPlayer.notReady = false;
                        },
                        tooltip: 'Swap',
                        child: const Icon(Icons.view_carousel_sharp),
                      ),
                    ),
                  ],
                );
              default:
                return Container();
            }
          }), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
