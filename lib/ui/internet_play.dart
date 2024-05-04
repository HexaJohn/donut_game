import 'dart:convert';
import 'dart:developer' as developer;

import 'package:donut_game/data/model/game_card/game_card_stack.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/ui/login/login.dart';
import 'package:donut_game/ui/widget/playing_card.dart';
import 'package:donut_game/ui/widget/playing_card_stack.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart';

class OnlineGamePage extends StatefulWidget {
  const OnlineGamePage({Key? key, required this.title, required this.username}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final String username;

  @override
  State<OnlineGamePage> createState() => _OnlineGamePageState();
}

class _OnlineGamePageState extends State<OnlineGamePage> {
  bool keepConnected = true;
  Game game = Game();
  GamePlayer get localPlayer {
    try {
      return game.playerDB.values.firstWhere((element) => element.name == username);
    } catch (e) {
      return GamePlayer(widget.username, game.players.length + 1, true);
    }
  }

  void connectionLoop() async {
    while (keepConnected) {
      await Future.delayed(const Duration(milliseconds: 1000));
      Uri uri = Uri(scheme: 'http', host: serverAddress, port: port, path: '/update');
      Response response;
      try {
        response = await get(uri);
        var json = response.body;
        var gameJson = jsonDecode(json);
        // print(gameJson[0]['players']);

        setState(() {
          var activeKeys = [];
          for (var element in gameJson[0]['players']) {
            activeKeys.add(element['id']);

            game.playerDB.putIfAbsent(element['id'],
                () => GamePlayer(element['username'], game.playerDB.length, element['human'] == 'true' ? true : false));

            var cards = GameCardStack.fromJson(element['cards']);
            for (var card in cards.cards.value) {
              card.belongsTo = game.playerDB[element['id']];
            }
            //Populate player data
            game.playerDB[element['id']]
              ?..voteToDeal = element['voteDeal'] == 'true'
              ..hand = cards
              ..swaps.value = element['swaps']
              ..notReady = element['notReady'] == 'true'
              ..score.value = element['score']
              ..donuts.value = element['donuts']
              ..winner.value = element['winner']
              ..folds = element['folds'];
          }
          game.state.value = stringToGameState[gameJson[0]['game']['state']]!;
          game.protectedActive = gameJson[0]['game']['active'];
          game.protectedDealer = gameJson[0]['game']['dealer'];
          try {
            game.leadingCard = GameCard.fromJson(gameJson[0]['game']['leading_card']);
          } catch (e) {
            game.leadingCard = null;
          }
          game.trumpSuit.value = stringToSuit[gameJson[0]['game']['trump']]!;
          List<GameCard> newCards = [];
          List<GameCard> discards = [];
          //Populate game table data
          for (var element in gameJson[0]['game']['table']) {
            newCards.add(GameCard.fromJson(element)!);
          }
          for (var element in gameJson[0]['game']['discard']) {
            discards.add(GameCard.fromJson(element)!);
          }
          game.table.cards.value = newCards;
          game.discard.cards.value = discards;
          Iterable active = game.playerDB.keys.where((element) => activeKeys.contains(element));

          game.playerDB.removeWhere((key, value) => !active.contains(key));
        });

        // game.playerDB.containsKey(key);
      } catch (e) {
        developer.log(e.toString());
        // TODO
      }
    }
  }

  @override
  void initState() {
    connectionLoop();

    game.state.value = GameState.waitingToDeal;

    super.initState();
  }

  void clientDeal() async {
    localPlayer.voteToDeal = true;
    game.clientDeal();
    // game.state.value = GameState.swapping;
  }

  void clientSwap(int cardIndex) async {
    // game.state.value = GameState.swapping;
    game.clientSwap(cardIndex);
  }

  void deal() async {
    await game.deal();
    // game.state.value = GameState.swapping;
  }

  Widget layoutSwapActions(int index) {
    final player = localPlayer;
    final card = localPlayer.hand.cards.value.elementAt(index);
    switch (card.state) {
      case CardState.held:
        return ElevatedButton(
            onPressed: () {
              setState(() {
                player.hand.cards.value[index].state = CardState.swap;
                player.swaps.value--;
                clientSwap(index);
              });
            },
            child: const Text('Swap',
                style: TextStyle(
                    // color: Colors.red,
                    )));
      case CardState.swap:
        return ElevatedButton(
            style: ButtonStyle(backgroundColor: MaterialStateColor.resolveWith((states) => Colors.red)),
            onPressed: () {
              setState(() {
                player.hand.cards.value[index].state = CardState.held;
                player.swaps.value++;
                clientSwap(index);
              });
            },
            child: const Text('Cancel',
                style: TextStyle(
                    // color: Colors.red,
                    )));
      default:
        return ElevatedButton(
            style: ButtonStyle(overlayColor: MaterialStateColor.resolveWith((states) => Colors.red.shade50)),
            onPressed: () {},
            child: const Text('!',
                style: TextStyle(
                    // color: Colors.red,
                    )));
    }
  }

  Widget layoutPlayActions(int index) {
    final player = localPlayer;
    final card = localPlayer.hand.cards.value.elementAt(index);
    var lead = game.leadingCard?.suit;
    bool throwoff = false;
    if (player.hand.cards.value.any((element) => element.suit == game.leadingCard?.suit)) {
      throwoff = false;
    } else {
      throwoff = true;
    }
    if (game.table.cards.value.isEmpty) {
      throwoff = false;
    }
    if (card.suit == lead || lead == null || throwoff) {
      switch (card.state) {
        case CardState.held:
          return ElevatedButton(
              onPressed: () {
                setState(() {
                  game.clientPlayCard(index);
                  player.cardToPlay = card;
                });
              },
              child: Text(
                  !throwoff
                      ? 'Play'
                      : card.suit == game.trumpSuit.value
                          ? 'Trump'
                          : 'Throw',
                  style: const TextStyle(
                      // color: Colors.red,
                      )));
        case CardState.swap:
          return ElevatedButton(
              style: ButtonStyle(overlayColor: MaterialStateColor.resolveWith((states) => Colors.red.shade50)),
              onPressed: () {
                setState(() {
                  player.hand.cards.value[index].state = CardState.held;
                  player.swaps.value++;
                });
              },
              child: const Text('Cancel',
                  style: TextStyle(
                      // color: Colors.red,
                      )));
        default:
          return ElevatedButton(
              style: ButtonStyle(overlayColor: MaterialStateColor.resolveWith((states) => Colors.red.shade50)),
              onPressed: () {},
              child: const Text('!',
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
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Text(
                'Donut: A Card Game',
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
            const ListTile(
              title: Text('Leaderboard:'),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: game.players.length,
              itemBuilder: (context, playerIndex) {
                return SizedBox(
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
            ListTile(
              title: const Text('Back to game'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Debug: toggle connection'),
              onTap: () {
                keepConnected = !keepConnected;
                if (keepConnected) {
                  connectionLoop();
                }
              },
            ),
            ListTile(
              title: const Text('Debug: reset server'),
              onTap: () {
                game.adminReset();
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        toolbarTextStyle: const TextStyle(color: Colors.black),
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(top: 16),
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: game.players.length,
              itemBuilder: (context, playerIndex) {
                return SizedBox(
                  width: 150,
                  child: ValueListenableBuilder(
                      valueListenable: game.activePlayer,
                      builder: (context, GamePlayer value, child) {
                        return Column(
                          children: [
                            Text(game.players[playerIndex].voteToDeal ? 'ready' : 'not ready'),
                            Card(
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
                                              valueListenable: game.players[playerIndex].winner,
                                              builder: (context, bool value, child) {
                                                return value
                                                    ? LinearProgressIndicator(
                                                        minHeight: 33,
                                                        color: Colors.yellow,
                                                        backgroundColor: Colors.yellow.shade100,
                                                      )
                                                    : Container();
                                              }),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2.0, left: 8.0, right: 4.0),
                                                  child: ValueListenableBuilder(
                                                      valueListenable: game.dealer,
                                                      builder: (context, GamePlayer value, child) {
                                                        return Icon(
                                                          value.name == game.players[playerIndex].name
                                                              ? Icons.star
                                                              : game.players[playerIndex].human
                                                                  ? game.players[playerIndex].name == localPlayer.name
                                                                      ? Icons.account_circle
                                                                      : Icons.account_circle_outlined
                                                                  : Icons.psychology_rounded,
                                                          size: 14,
                                                        );
                                                      }),
                                                ),
                                                //Username
                                                Expanded(
                                                  child: Text(
                                                    game.players.toList()[playerIndex].name,
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                                //Score
                                                ValueListenableBuilder(
                                                    valueListenable: game.players[playerIndex].score,
                                                    builder: (context, int value, child) {
                                                      return Text(
                                                        '$value',
                                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                                      );
                                                    }),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  //Cards in hand
                                  ValueListenableBuilder(
                                    valueListenable: game.players[playerIndex].hand.cards,
                                    builder: (context, List<GameCard> value, child) {
                                      List<Widget> children = List.generate(
                                        value.length,
                                        (index) {
                                          var child = (game.dealer.value == game.players[playerIndex] &&
                                                  index == 4 &&
                                                  (game.state.value == GameState.swapping ||
                                                      game.state.value == GameState.waitingForPlayerToSwap))
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
                                        alignment: WrapAlignment.center,
                                        children: children,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                );
              },
            ),
          ),
          ValueListenableBuilder(
              valueListenable: game.trumpSuit,
              builder: (context, Suit value, child) {
                return Text("Current Trump: ${suitToString[value] ?? 'none'}, Debug State: ${game.state.value}");
              }),
          Container(
            decoration: BoxDecoration(
                color: Colors.green.shade900,
                borderRadius: BorderRadius.circular(5),
                boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 1.0)]),
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.all(8),
            height: 145,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  //Game table cards
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
                                      value[index].belongsTo.toString(),
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
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(5),
                boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 1.0)]),
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
                                      return Row(
                                        children: [
                                          // Text(localPlayer
                                          //     .hand.cards.value[index].state
                                          //     .toString()),
                                          // Text(localPlayer.swaps.value
                                          //     .toString()),
                                          ValueListenableBuilder(
                                            builder: (context, value, child) => (value != 0 ||
                                                        localPlayer.hand.cards.value[index].state == CardState.swap) &&
                                                    game.state.value == GameState.waitingForPlayerToSwap
                                                ? layoutSwapActions(index)
                                                : Container(),
                                            valueListenable: localPlayer.swaps,
                                          ),
                                          ValueListenableBuilder(
                                            builder: (context, GameState value, child) =>
                                                (value == GameState.playing && game.activePlayerLazy == localPlayer)
                                                    ? layoutPlayActions(index)
                                                    : Container(),
                                            valueListenable: game.state,
                                          )
                                        ],
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
                    clientDeal();
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
                          game.clientFold();
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
                          await game.clientSwapFinalize();
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
