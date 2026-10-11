import 'dart:math';

import 'package:donut_game/progression/battle_pass.dart';
import 'package:donut_game/progression/catalog.dart';
import 'package:donut_game/progression/emblem.dart';
import 'package:donut_game/progression/environments.dart';
import 'package:donut_game/progression/profile.dart';
import 'package:donut_game/progression/ranks.dart';
import 'package:donut_game/progression/rewards.dart';
import 'package:donut_game/progression/slot_machine.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/career/career_screen.dart';
import 'package:donut_game/ui/career/match_rewards.dart';
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

  group('battle pass', () {
    test('tiers unlock with xp', () {
      expect(passTierFor(0), 0);
      expect(passTierFor(passTiers.first.xp), 1);
      expect(passTierFor(passTiers.last.xp), passTierCount);
      expect(passProgress(passTiers.last.xp), 1);
    });

    test('pass-only items each sit on a tier', () {
      for (final item in catalog.where((i) => i.passOnly)) {
        expect(passTiers.any((t) => t.item == item.id), isTrue, reason: '${item.id} has no tier');
      }
      for (final tier in passTiers.where((t) => t.item != null)) {
        expect(itemById(tier.item!), isNotNull, reason: 'tier ${tier.tier} gives unknown ${tier.item}');
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
      final bonus = profile.grant(xp: ranks[1].xp);
      expect(profile.rank, ranks[1]);
      expect(bonus, greaterThan(0));
      expect(profile.glaze, bonus);
    });

    test('buys and equips, refuses what it cannot afford', () {
      final profile = PlayerProfile();
      final dots = itemById('pattern.dots')!;
      expect(profile.buy(dots), isFalse);
      profile.grant(crumbs: dots.price);
      expect(profile.buy(dots), isTrue);
      expect(profile.crumbs, 0);
      expect(profile.cardPattern, 'pattern.dots');
      expect(profile.buy(dots), isFalse);
      expect(profile.equip('pattern.classic'), isTrue);
      expect(profile.cardPattern, 'pattern.classic');
      expect(profile.equip('pattern.waves'), isFalse);
    });

    test('pass-only items cannot be bought but can be claimed', () {
      final profile = PlayerProfile();
      final seal = itemById('pattern.bakers_seal')!;
      profile.grant(crumbs: 1 << 20);
      expect(profile.buy(seal), isFalse);
      expect(profile.claimTier(10), isFalse);
      profile.grant(xp: passTiers[9].xp);
      expect(profile.unclaimedTiers.length, 10);
      expect(profile.claimTier(10), isTrue);
      expect(profile.owns(seal.id), isTrue);
      expect(profile.claimTier(10), isFalse);
      expect(profile.claimAll(), 9);
      expect(profile.unclaimedTiers, isEmpty);
    });

    test('round-trips through json', () {
      final profile = PlayerProfile();
      profile.grant(xp: 1234, crumbs: 500, glaze: 3);
      profile.buy(itemById('env.blue')!);
      profile.setEmblem(const Emblem(shape: EmblemShape.star, icon: 'bolt', background: Color(0xFF123456)));
      profile.claimTier(1);
      final copy = PlayerProfile()..restore(profile.toJson());
      expect(copy.xp, profile.xp);
      expect(copy.crumbs, profile.crumbs);
      expect(copy.glaze, profile.glaze);
      expect(copy.environment, 'env.blue');
      expect(copy.emblem, profile.emblem);
      expect(copy.isClaimed(1), isTrue);
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
      expect(profile.crumbs, outcome.rewards.crumbs + outcome.slot.crumbs);
      expect(profile.stats.matches, 1);
      expect(profile.stats.wins, 1);
      expect(profile.stats.slotPulls, 1);
      expect(profile.firstWinTodayAvailable, isFalse);
    });
  });

  group('career screen', () {
    setUp(() {
      final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
      view.physicalSize = const Size(1280, 800);
      view.devicePixelRatio = 1;
    });

    testWidgets('shows every tab', (tester) async {
      PlayerProfile.instance.reset();
      await tester.pumpWidget(MaterialApp(theme: buildTheme(ThemePreset.donutLight), home: const CareerScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Crumb'), findsWidgets);
      await tester.tap(find.text('Battle pass'));
      await tester.pumpAndSettle();
      expect(find.text(passName), findsOneWidget);
      await tester.tap(find.text('Shop'));
      await tester.pumpAndSettle();
      expect(find.text('Polka'), findsOneWidget);
      await tester.tap(find.text('Emblem'));
      await tester.pumpAndSettle();
      expect(find.text('Surprise me'), findsOneWidget);
    });
  });
}
