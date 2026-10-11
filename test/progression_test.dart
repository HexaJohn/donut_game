import 'dart:math';

import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/progression/card_faces.dart';
import 'package:donut_game/progression/catalog.dart';
import 'package:donut_game/progression/emblem.dart';
import 'package:donut_game/progression/environments.dart';
import 'package:donut_game/progression/gadgets.dart';
import 'package:donut_game/progression/profile.dart';
import 'package:donut_game/progression/ranks.dart';
import 'package:donut_game/progression/rewards.dart';
import 'package:donut_game/progression/slot_machine.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/career/career_screen.dart';
import 'package:donut_game/ui/career/match_rewards.dart';
import 'package:donut_game/ui/widget/playing_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ranks', () {
    test('ladder climbs monotonically from zero', () {
      expect(ranks.first.xp, 0);
      for (var i = 1; i < ranks.length; i++) {
        expect(ranks[i].xp, greaterThan(ranks[i - 1].xp));
      }
      expect(ranks.first.title, 'Crumb');
      expect(ranks.last.title, 'Inheritor');
    });

    test('rankFor picks the highest rank reached', () {
      expect(rankFor(0), ranks.first);
      expect(rankFor(ranks[3].xp), ranks[3]);
      expect(rankFor(ranks[3].xp + 1), ranks[3]);
      expect(rankFor(ranks[4].xp - 1), ranks[3]);
      expect(rankFor(1 << 30), ranks.last);
      expect(nextRankFor(1 << 30), isNull);
    });

    test('progress runs 0..1 between ranks', () {
      final a = ranks[5];
      final b = ranks[6];
      expect(rankProgress(a.xp), 0);
      expect(rankProgress((a.xp + b.xp) ~/ 2), closeTo(0.5, 0.01));
      expect(rankProgress(ranks.last.xp), 1);
    });
  });

  group('rewards', () {
    test('a win pays more than a loss', () {
      const base = DonutMatchSummary(
          placement: 4, players: 4, tricks: 3, donuts: 2, hands: 5, suddenDeath: false, duration: Duration(minutes: 8));
      final loss = donutMatchRewards(base);
      final win = donutMatchRewards(const DonutMatchSummary(
          placement: 1, players: 4, tricks: 3, donuts: 2, hands: 5, suddenDeath: false, duration: Duration(minutes: 8)));
      expect(win.xp, greaterThan(loss.xp));
      expect(win.crumbs, greaterThan(loss.crumbs));
      expect(loss.xp, greaterThan(0));
      expect(loss.lines.any((l) => l.label == 'Victory'), isFalse);
      expect(win.lines.any((l) => l.label == 'Victory'), isTrue);
    });

    test('clean sheet and daily bonus apply', () {
      final rewards = donutMatchRewards(const DonutMatchSummary(
        placement: 1,
        players: 6,
        tricks: 10,
        donuts: 0,
        hands: 6,
        suddenDeath: true,
        duration: Duration(minutes: 10),
        firstWinToday: true,
      ));
      final labels = rewards.lines.map((l) => l.label).toList();
      expect(labels, contains('Clean sheet: no donuts'));
      expect(labels, contains('First win of the day'));
      expect(labels, contains('Full table'));
      expect(labels, contains('Sudden death survivor'));
    });

    test('bad batch pays for rounds', () {
      final rewards = badBatchRewards(const BadBatchSummary(won: true, roundsWon: 7, players: 4));
      expect(rewards.xp, 60 + 150 + 70);
      expect(rewards.crumbs, 40 + 100 + 35);
    });
  });

  group('slot machine', () {
    test('payouts match the table', () {
      expect(payout([SlotSymbol.donut, SlotSymbol.donut, SlotSymbol.donut]).jackpot, isTrue);
      expect(payout([SlotSymbol.seven, SlotSymbol.seven, SlotSymbol.seven]).crumbs, 777);
      expect(payout([SlotSymbol.glaze, SlotSymbol.glaze, SlotSymbol.crumb]).glaze, 1);
      expect(payout([SlotSymbol.bar, SlotSymbol.bar, SlotSymbol.crumb]).crumbs, 40);
      expect(payout([SlotSymbol.bar, SlotSymbol.cherry, SlotSymbol.crumb]).crumbs, 10);
    });

    test('rolls are reproducible and always pay something', () {
      final a = rollSlots(Random(1));
      final b = rollSlots(Random(1));
      expect(a.reels, b.reels);
      for (var seed = 0; seed < 200; seed++) {
        expect(rollSlots(Random(seed)).crumbs, greaterThan(0));
      }
    });

    test('jackpots are rare', () {
      var jackpots = 0;
      final random = Random(99);
      for (var i = 0; i < 20000; i++) {
        if (rollSlots(random).jackpot) jackpots++;
      }
      // (3/100)^3 = 2.7e-5 per pull
      expect(jackpots, lessThan(10));
    });
  });

  group('rank rewards', () {
    test('every rank past the first pays crumbs and glaze', () {
      expect(rankReward(ranks.first).crumbs, 0);
      for (final rank in ranks.skip(1)) {
        expect(rankReward(rank).crumbs, greaterThan(0), reason: rank.title);
        expect(rankReward(rank).glaze, greaterThan(0), reason: rank.title);
      }
    });

    test('every item unlocks at a real rank, starters at the first', () {
      for (final item in catalog) {
        expect(item.rank, inInclusiveRange(0, ranks.length - 1), reason: item.id);
        if (starterItems.contains(item.id)) expect(item.rank, 0, reason: item.id);
        if (!starterItems.contains(item.id)) expect(item.rank, greaterThan(0), reason: item.id);
      }
    });

    test('rank-only items are each handed over by their rank', () {
      for (final item in catalog.where((i) => i.rankOnly)) {
        expect(rankReward(unlockRank(item)).item, item.id, reason: item.id);
      }
      for (final rank in ranks) {
        expect(itemsUnlockedAt(rank).where((i) => i.rankOnly).length, lessThanOrEqualTo(1), reason: rank.title);
      }
    });
  });

  group('catalog', () {
    test('ids are unique and environments exist', () {
      final ids = catalog.map((i) => i.id).toSet();
      expect(ids.length, catalog.length);
      for (final item in itemsOfKind(ItemKind.environment)) {
        expect(environments.any((e) => e.id == item.id), isTrue, reason: item.id);
      }
    });
  });

  group('profile', () {
    test('grants xp and pays glaze on rank-up', () {
      final profile = PlayerProfile();
      expect(profile.rank, ranks.first);
      final reached = profile.grant(xp: ranks[1].xp);
      expect(profile.rank, ranks[1]);
      expect(reached, [ranks[1]]);
      expect(profile.glaze, rankReward(ranks[1]).glaze);
      expect(profile.crumbs, rankReward(ranks[1]).crumbs);
    });

    test('buys and equips, refuses what it cannot afford', () {
      final profile = PlayerProfile();
      final dots = itemById('pattern.dots')!;
      profile.grant(xp: unlockRank(dots).xp);
      expect(profile.crumbs, lessThan(dots.price));
      expect(profile.buy(dots), isFalse);
      profile.grant(crumbs: dots.price - profile.crumbs);
      expect(profile.buy(dots), isTrue);
      expect(profile.crumbs, 0);
      expect(profile.buy(dots), isFalse);
    });

    test('shop items stay locked until their rank', () {
      final profile = PlayerProfile();
      final dots = itemById('pattern.dots')!;
      profile.grant(crumbs: 1 << 20);
      expect(profile.hasUnlocked(dots), isFalse);
      expect(profile.buy(dots), isFalse);
      profile.grant(xp: unlockRank(dots).xp);
      expect(profile.hasUnlocked(dots), isTrue);
      expect(profile.buy(dots), isTrue);
    });

    test('equips what it owns', () {
      final profile = PlayerProfile();
      final dots = itemById('pattern.dots')!;
      profile.grant(xp: unlockRank(dots).xp, crumbs: 1 << 20);
      expect(profile.buy(dots), isTrue);
      expect(profile.cardPattern, 'pattern.dots');
      expect(profile.equip('pattern.classic'), isTrue);
      expect(profile.cardPattern, 'pattern.classic');
      expect(profile.equip('pattern.waves'), isFalse);
    });

    test('rank-only items cannot be bought but unlock on rank-up', () {
      final profile = PlayerProfile();
      final seal = itemById('pattern.bakers_seal')!;
      final sealRank = unlockRank(seal);
      profile.grant(crumbs: 1 << 20);
      expect(profile.buy(seal), isFalse);
      profile.grant(xp: sealRank.xp - 1);
      expect(profile.owns(seal.id), isFalse);
      final crumbs = profile.crumbs;
      expect(profile.grant(xp: 1), [sealRank]);
      expect(profile.owns(seal.id), isTrue);
      expect(profile.crumbs, crumbs + rankReward(sealRank).crumbs);
    });

    test('table tools are bought, and upgrades need what they upgrade', () {
      final profile = PlayerProfile();
      expect(markerColorsFor(profile), isEmpty);
      expect(profile.owns('gadget.revolver'), isFalse);
      expect(profile.owns('gadget.flashbang'), isFalse);
      profile.grant(xp: ranks[30].xp, crumbs: 1 << 20, glaze: 1 << 10);
      final speedloader = itemById('gadget.speedloader')!;
      expect(profile.hasRequirement(speedloader), isFalse);
      expect(profile.buy(speedloader), isFalse);
      expect(profile.buy(itemById('gadget.revolver')!), isTrue);
      expect(profile.buy(speedloader), isTrue);
      expect(chambersFor(profile), 12);
      expect(profile.buy(itemById('gadget.markers_neon')!), isFalse);
      expect(profile.buy(itemById('gadget.markers')!), isTrue);
      expect(profile.buy(itemById('gadget.markers_neon')!), isTrue);
      // Pastel markers came free with the rank, and show now there's a set
      expect(markerColorsFor(profile).length, 5 + 4 + 4);
      for (final item in catalog.where((i) => i.requires != null)) {
        expect(itemById(item.requires!), isNotNull, reason: item.id);
        expect(itemById(item.requires!)!.rank, lessThanOrEqualTo(item.rank), reason: item.id);
      }
    });

    test('old saves get the items of ranks already held', () {
      final profile = PlayerProfile()..restore({'xp': ranks[12].xp, 'claimed': [1, 2]});
      expect(profile.owns('pattern.bakers_seal'), isTrue);
      expect(profile.owns('gadget.markers_pastel'), isTrue);
      expect(profile.owns('env.bakery'), isFalse);
    });

    test('round-trips through json', () {
      final profile = PlayerProfile();
      profile.grant(xp: 1234, crumbs: 500, glaze: 3);
      profile.grant(xp: ranks[1].xp);
      expect(profile.buy(itemById('env.blue')!), isTrue);
      profile.setEmblem(const Emblem(shape: EmblemShape.star, icon: 'bolt', background: Color(0xFF123456)));
      final copy = PlayerProfile()..restore(profile.toJson());
      expect(copy.xp, profile.xp);
      expect(copy.crumbs, profile.crumbs);
      expect(copy.glaze, profile.glaze);
      expect(copy.environment, 'env.blue');
      expect(copy.emblem, profile.emblem);
    });

    test('match outcome banks rewards and slots once', () {
      final profile = PlayerProfile();
      final outcome = MatchOutcome.awardDonut(
        profile,
        const DonutMatchSummary(
            placement: 1, players: 4, tricks: 8, donuts: 0, hands: 5, suddenDeath: false, duration: Duration(minutes: 7)),
        random: Random(4),
      );
      expect(outcome.xpBefore, 0);
      expect(profile.xp, outcome.rewards.xp + outcome.slot.xp);
      final rankUpCrumbs =
          [...outcome.rankUps, ...outcome.slotRankUps].fold(0, (sum, rank) => sum + rankReward(rank).crumbs);
      expect(outcome.rankUps, isNotEmpty);
      expect(profile.crumbs, outcome.rewards.crumbs + outcome.slot.crumbs + rankUpCrumbs);
      expect(profile.stats.matches, 1);
      expect(profile.stats.wins, 1);
      expect(profile.stats.slotPulls, 1);
      expect(profile.firstWinTodayAvailable, isFalse);
    });
  });

  group('decks', () {
    test('every face style in the catalog has its own look', () {
      expect(identical(cardFaceStyle('face.classic'), const CardFaceStyle()), isTrue);
      for (final item in itemsOfKind(ItemKind.cardFace).where((i) => i.id != 'face.classic')) {
        expect(identical(cardFaceStyle(item.id), const CardFaceStyle()), isFalse, reason: item.id);
      }
    });

    test('bots get a stable deck of real, purchasable items', () {
      for (final name in ['Sprinkles', 'Cruller', 'Bot 42', '']) {
        final deck = botDeck(name);
        expect(botDeck(name), deck);
        expect(itemById(deck.back)?.kind, ItemKind.cardPattern);
        expect(itemById(deck.face)?.kind, ItemKind.cardFace);
      }
      final bot = GamePlayer('Sprinkles', 1, false);
      expect(bot.cardBack, botDeck('Sprinkles').back);
      final human = GamePlayer('Sam', 0, true);
      expect(human.cardBack, 'pattern.classic');
      expect(human.cardFace, 'face.classic');
    });

    test('equips a face and keeps it through a save', () {
      final profile = PlayerProfile();
      expect(profile.cardFace, 'face.classic');
      final four = itemById('face.four_colour')!;
      profile.grant(xp: unlockRank(four).xp, crumbs: four.price);
      expect(profile.buy(four), isTrue);
      expect(profile.cardFace, four.id);
      expect(profile.isEquipped(four.id), isTrue);
      final copy = PlayerProfile()..restore(profile.toJson());
      expect(copy.cardFace, four.id);
      // A face that isn't owned falls back to the standard one
      expect((PlayerProfile()..restore({'cardFace': 'face.neon'})).cardFace, 'face.classic');
    });

    testWidgets('every face style draws every kind of card cleanly', (tester) async {
      final cards = [
        GameCard(Suit.spades, Value.ace),
        GameCard(Suit.hearts, Value.ten),
        GameCard(Suit.clubs, Value.king),
        GameCard(Suit.diamonds, Value.two),
      ];
      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(ThemePreset.donutLight),
        home: Wrap(children: [
          for (final item in itemsOfKind(ItemKind.cardFace))
            for (final card in cards)
              SizedBox(width: 50, height: 70, child: PlayingCardWidget(card: card, face: item.id, trump: true)),
        ]),
      ));
      expect(tester.takeException(), isNull);
      expect(find.byType(CardFace), findsNWidgets(itemsOfKind(ItemKind.cardFace).length * cards.length));
    });
  });

  group('career screen', () {
    setUp(() {
      final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view.physicalSize = const Size(1280, 800);
      view.devicePixelRatio = 1;
    });

    testWidgets('rewards panel fits a rank-up with every currency', (tester) async {
      final profile = PlayerProfile();
      final outcome = MatchOutcome.awardDonut(
        profile,
        const DonutMatchSummary(
            placement: 2, players: 4, tricks: 12, donuts: 0, hands: 8, suddenDeath: false, duration: Duration(minutes: 9)),
        random: Random(4),
        extra: const [RewardLine('Boss defeated: The Head Baker', xp: 300, crumbs: 230, glaze: 3)],
      );
      expect(outcome.rankUps, isNotEmpty);
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: buildTheme(ThemePreset.donutDark),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 364,
              child: MatchOverFlow(header: const SizedBox(), standings: const SizedBox(), actions: const SizedBox(), outcome: outcome),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Collect rewards'));
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(tester.takeException(), isNull);
      expect(find.text('Rank up: ${outcome.rankUps.last.title}'), findsOneWidget);
      // Total Glaze counts the match's own Glaze as well as the rank-ups'
      expect(find.text('+${3 + outcome.rankUpGlaze} GL'), findsOneWidget);

      // Then the bonus spin, through to the payout
      await tester.tap(find.text('Bonus spin'));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.tap(find.byTooltip('Pull'));
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(tester.takeException(), isNull);
      expect(find.text(outcome.slot.label), findsOneWidget);
    });

    testWidgets('shows every tab', (tester) async {
      PlayerProfile.instance.reset();
      await tester.pumpWidget(MaterialApp(theme: buildTheme(ThemePreset.donutLight), home: const CareerScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Crumb'), findsWidgets);
      await tester.tap(find.text('Shop'));
      await tester.pumpAndSettle();
      expect(find.text('Polka'), findsOneWidget);
      await tester.tap(find.text('Emblem'));
      await tester.pumpAndSettle();
      expect(find.text('Surprise me'), findsOneWidget);
    });
  });
}
