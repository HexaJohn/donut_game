import 'dart:math';

import 'package:donut_game/ai/bot_brain.dart';
import 'package:donut_game/campaign/backdrops.dart';
import 'package:donut_game/campaign/campaign.dart';
import 'package:donut_game/campaign/campaign_controller.dart';
import 'package:donut_game/data/settings.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/data/model/game_card/game_card_deck.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/progression/catalog.dart';
import 'package:donut_game/progression/environments.dart';
import 'package:donut_game/progression/profile.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/campaign/campaign_screen.dart';
import 'package:donut_game/ui/game/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Plays [hands] hands between bots of [skills] on the shared game, without
/// the game loop's delays. Returns each seat's total score change: -1 per
/// trick, +donutPenalty per donut.
/// Seat [human], if given, counts as a human at the table (rookies play to
/// help it) though a brain still plays for it.
List<int> simulate(List<BotSkill> skills, {int hands = 300, int seed = 1, int? human}) {
  final random = Random(seed);
  final game = Game();
  game.abort();
  game.playerDB.clear();
  final players = [
    for (var i = 0; i < skills.length; i++) GamePlayer('Seat $i', i, i == human)..skill = skills[i],
  ];
  for (final player in players) {
    game.playerDB[player.name] = player;
  }
  final brains = [for (var i = 0; i < skills.length; i++) BotBrain(skills[i], random: Random(seed * 31 + i))];
  final totals = List.filled(players.length, 0);

  for (var hand = 0; hand < hands; hand++) {
    final deck = GameCardDeck.fresh().contents..shuffle(random);
    game.discard.dump();
    game.table.dump();
    game.trumpSuit.value = Suit.values[random.nextInt(4)];
    for (final player in players) {
      player.hand.dump();
      player.skip = false;
      player.tricks = 0;
      player.swaps.value = maxSwaps;
      for (var i = 0; i < cardsPerHand; i++) {
        player.hand.add(deck.removeLast()..belongsTo = player);
      }
    }
    for (var i = 0; i < players.length; i++) {
      final player = players[i];
      if (brains[i].shouldFold(player, game)) {
        player.skip = true;
        player.folds++;
        continue;
      }
      player.folds = 0;
      final out = brains[i].chooseSwaps(player.hand.cards.value, game.trumpSuit.value, maxSwaps);
      for (final card in out) {
        player.hand.remove(card);
        game.discard.add(card);
        player.hand.add(deck.removeLast()..belongsTo = player);
      }
    }
    final seated = [
      for (var i = 0; i < players.length; i++)
        if (!players[i].skip) i
    ];
    var lead = seated.isEmpty ? 0 : seated.first;
    for (var trick = 0; trick < cardsPerHand && seated.isNotEmpty; trick++) {
      game.table.dump();
      game.leadingCard = null;
      final order = [for (var k = 0; k < seated.length; k++) seated[(seated.indexOf(lead) + k) % seated.length]];
      for (final i in order) {
        final card = brains[i].chooseCard(players[i], game);
        expect(BotBrain.legal(players[i].hand.cards.value, game), contains(card),
            reason: '${skills[i]} played illegally');
        players[i].hand.remove(card);
        game.leadingCard ??= card;
        game.table.add(card);
      }
      final winner = game.evaluateTableForWinner();
      winner.tricks++;
      lead = players.indexOf(winner);
      for (final card in game.table.cards.value) {
        game.discard.add(card);
      }
    }
    for (var i = 0; i < players.length; i++) {
      if (players[i].skip) continue;
      totals[i] += players[i].tricks == 0 ? donutPenalty : -players[i].tricks;
    }
  }
  game.playerDB.clear();
  return totals;
}

void main() {
  group('bot brain', () {
    test('every skill only ever plays legal cards', () {
      simulate(BotSkill.values, hands: 200, seed: 3);
    });

    test('regulars swap like the old bots did', () {
      final brain = BotBrain(BotSkill.regular);
      final hand = [
        GameCard(Suit.hearts, Value.two),
        GameCard(Suit.spades, Value.ace),
        GameCard(Suit.hearts, Value.king),
        GameCard(Suit.clubs, Value.three),
        GameCard(Suit.diamonds, Value.four),
      ];
      expect(brain.chooseSwaps(hand, Suit.hearts, 3), [hand[1], hand[3], hand[4]]);
      expect(BotBrain(BotSkill.pro).chooseSwaps(hand, Suit.hearts, 3), [hand[3], hand[4]]);
    });

    test('better skills score better over many hands', () {
      // Lower is better: scores count down to zero
      // Rookies hand tricks around, so rank the rest at a table without them
      final skills = BotSkill.values.skip(1).toList();
      for (final seed in [7, 11, 19]) {
        final totals = simulate(skills, hands: 800, seed: seed);
        for (var i = 1; i < totals.length; i++) {
          expect(totals[i], lessThan(totals[i - 1]), reason: '${skills[i]} vs ${skills[i - 1]}, seed $seed: $totals');
        }
      }
      final mixed = simulate(BotSkill.values, hands: 600, seed: 7);
      expect(mixed.first, greaterThan(mixed.skip(1).reduce(max)), reason: 'rookies come last: $mixed');
    });

    test('rookies throw the game for the human at the table', () {
      // The same player, a regular at heart, at a table of rookies or regulars
      final withRookies = simulate([BotSkill.regular, ...List.filled(3, BotSkill.rookie)], hands: 600, human: 0);
      final withRegulars = simulate(List.filled(4, BotSkill.regular), hands: 600, human: 0);
      expect(withRookies[0], lessThan(withRegulars[0] - 300), reason: 'rookies $withRookies, regulars $withRegulars');
      // And it still beats every rookie
      for (final rookie in withRookies.skip(1)) {
        expect(withRookies[0], lessThan(rookie));
      }
    });

    test('a rookie stops a bot beating a human who has already played', () {
      final game = Game();
      game.playerDB.clear();
      final human = GamePlayer('Human', 0, true);
      final bot = GamePlayer('Bot', 1, false);
      final rookie = GamePlayer('Rookie', 2, false)..skill = BotSkill.rookie;
      for (final p in [human, bot, rookie]) {
        game.playerDB[p.name] = p;
      }
      game.trumpSuit.value = Suit.spades;
      game.table.dump();
      final lead = GameCard(Suit.hearts, Value.five)..belongsTo = human;
      game.leadingCard = lead;
      game.table.add(lead);
      game.table.add(GameCard(Suit.hearts, Value.nine)..belongsTo = bot);
      rookie.hand.dump();
      rookie.hand.add(GameCard(Suit.hearts, Value.king));
      rookie.hand.add(GameCard(Suit.hearts, Value.two));
      // Every time it's in the mood to throw; otherwise it plays like a regular
      var kings = 0;
      for (var seed = 0; seed < 40; seed++) {
        if (BotBrain(BotSkill.rookie, random: Random(seed)).chooseCard(rookie, game).value == Value.king) kings++;
      }
      expect(kings, greaterThan(28));
      game.playerDB.clear();
    });

    test('difficulty shifts skill within bounds', () {
      expect(BotSkill.rookie.shifted(Difficulty.casual.skillShift), BotSkill.rookie);
      expect(BotSkill.pro.shifted(Difficulty.brutal.skillShift), BotSkill.shark);
      expect(BotSkill.shark.shifted(Difficulty.brutal.skillShift), BotSkill.shark);
      expect(BotSkill.amateur.shifted(Difficulty.standard.skillShift), BotSkill.amateur);
    });
  });

  group('campaign', () {
    test('stage ids are unique and stages are playable', () {
      final ids = allStages.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final venue in campaign) {
        expect(venue.stages.last.boss, isTrue, reason: venue.id);
        expect(environments.any((e) => e.id == venue.environment), isTrue, reason: venue.environment);
        for (final stage in venue.stages) {
          final names = stage.opponents.map((o) => o.name).toList();
          expect(names.toSet().length, names.length, reason: '${stage.id} seats someone twice');
          expect(stage.opponents.length, inInclusiveRange(2, Game.maxPlayers - 1), reason: stage.id);
          for (final opponent in stage.opponents) {
            expect(itemById(opponent.back)?.kind, ItemKind.cardPattern, reason: opponent.name);
            expect(itemById(opponent.face)?.kind, ItemKind.cardFace, reason: opponent.name);
          }
        }
      }
    });

    test('stages open one at a time and clears keep the best', () {
      final profile = PlayerProfile();
      final first = allStages[0], second = allStages[1];
      expect(profile.isStageUnlocked(first), isTrue);
      expect(profile.isStageUnlocked(second), isFalse);
      profile.recordStageClear(first, Difficulty.standard);
      expect(profile.isStageUnlocked(second), isTrue);
      profile.recordStageClear(first, Difficulty.casual);
      expect(profile.bestClear(first), Difficulty.standard);
      expect(profile.campaignStars, 2);
      profile.campaignDifficulty = Difficulty.brutal;
      final copy = PlayerProfile()..restore(profile.toJson());
      expect(copy.bestClear(first), Difficulty.standard);
      expect(copy.campaignDifficulty, Difficulty.brutal);
    });

    test('first clears pay, harder clears pay the difference, replays pay nothing', () {
      final boss = campaign.first.stages.last;
      final first = stageClearRewards(boss, Difficulty.standard, null).single;
      expect(first.xp, stageReward(boss).xp);
      expect(first.glaze, greaterThan(0));
      expect(stageClearRewards(boss, Difficulty.standard, Difficulty.standard), isEmpty);
      expect(stageClearRewards(boss, Difficulty.casual, Difficulty.standard), isEmpty);
      final upgrade = stageClearRewards(boss, Difficulty.brutal, Difficulty.standard).single;
      expect(upgrade.xp, (stageReward(boss).xp * 0.6).round());
    });

    test('opponents sit at their skill moved by difficulty', () {
      final boss = campaign.last.stages.last.opponents.first;
      expect(boss.seat(Difficulty.casual).skill, boss.skill.shifted(-1));
      final seat = boss.seat(Difficulty.standard);
      expect(seat.cardBack, boss.back);
      expect(seat.character, isTrue);
      expect(seat.human, isFalse);
    });

    test('scenery can be turned off for the theme and your own table', () {
      final controller = CampaignGameController(stage: allStages.first, difficulty: Difficulty.standard);
      addTearDown(controller.dispose);
      expect(controller.backdrop, campaign.first.backdrop);
      Settings.instance.setVenueScenery(false);
      addTearDown(() => Settings.instance.setVenueScenery(true));
      expect(controller.backdrop, isNull);
      expect(controller.environment, isNull);
    });

    testWidgets('switching scenery mid-match redraws the table at once', (tester) async {
      tester.view.physicalSize = const Size(1280, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      addTearDown(() => Settings.instance.setVenueScenery(true));
      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(ThemePreset.donutDark),
        home: GameScreen(controller: CampaignGameController(stage: allStages.first, difficulty: Difficulty.standard)),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Backdrop), findsOneWidget);

      // Nothing else happens in the game meanwhile
      Settings.instance.setVenueScenery(false);
      await tester.pump();
      expect(find.byType(Backdrop), findsNothing);
      Settings.instance.setVenueScenery(true);
      await tester.pump();
      expect(find.byType(Backdrop), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    });

    testWidgets('every backdrop paints and the campaign screen shows', (tester) async {
      final view = tester.view;
      view.physicalSize = const Size(1280, 900);
      view.devicePixelRatio = 1;
      addTearDown(view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(ThemePreset.donutLight),
        home: Column(children: [
          for (final venue in campaign) Expanded(child: Backdrop(id: venue.backdrop)),
        ]),
      ));
      expect(tester.takeException(), isNull);

      PlayerProfile.instance.reset();
      await tester.pumpWidget(MaterialApp(theme: buildTheme(ThemePreset.donutLight), home: const CampaignScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('The Corner Bakery'), findsOneWidget);
      expect(find.text('Opening Shift'), findsOneWidget);
    });
  });
}
