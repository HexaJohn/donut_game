import 'package:donut_game/ai/acrotron.dart';
import 'package:donut_game/data/model/chat_message.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_player.dart/game_player.dart';
import 'package:donut_game/data/settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('who a message is aimed at', () {
    const players = ['John', 'Mia', 'Glazed Gary', 'Bear Claw', acrotronName];
    // The conversation that a small model got wrong when asked directly
    final conversation = <(String, String, ChatTarget?)>[
      ('John', 'Acrotron, how many circuits does it take to lose a hand of cards?', ChatTarget.acrotron),
      (acrotronName, "Don't ask a broken bot questions.", null),
      ('John', 'Mia, want to grab pizza after this?', ChatTarget.someoneElse),
      ('Mia', 'yeah sure, pepperoni?', ChatTarget.someoneElse),
      ('John', 'shut up, toaster', ChatTarget.acrotron),
      ('Mia', 'who here thinks Bear Claw is cheating?', ChatTarget.table),
      ('John', 'lol Mia you are so bad at this', ChatTarget.someoneElse),
      ('Mia', 'whatever, at least I am not a talking microwave', ChatTarget.acrotron),
      ('John', 'this hand is garbage', ChatTarget.nobody),
      ('Mia', 'acro do you even know the rules', ChatTarget.acrotron),
      ('John', 'hahaha', ChatTarget.nobody),
      ('Mia', 'what are we playing next round?', ChatTarget.table),
      (acrotronName, 'Something you can actually win, for once.', null),
      ('John', 'wow rude', ChatTarget.acrotron),
    ];
    final history = <ChatMessage>[];
    var time = DateTime(2026);
    for (final (author, text, expected) in conversation) {
      time = time.add(const Duration(seconds: 5));
      final message = ChatMessage(author, text, time: time);
      history.add(message);
      if (expected == null) continue;
      final seen = List.of(history);
      test('$author: $text', () => expect(Acrotron.classify(seen, message, players), expected));
    }

    test('after Acrotron answers someone else, others are not talking to it', () {
      final t = DateTime(2026);
      final mia = ChatMessage('Mia', 'at least I am not a talking microwave', time: t);
      final reply =
          ChatMessage(acrotronName, 'Useless as a chocolate teapot.', time: t.add(const Duration(seconds: 3)));
      final grumble = ChatMessage('John', 'this hand is garbage', time: t.add(const Duration(seconds: 8)));
      final laugh = ChatMessage('John', 'hahaha', time: t.add(const Duration(seconds: 8)));
      final miaBack = ChatMessage('Mia', 'cry about it', time: t.add(const Duration(seconds: 8)));
      expect(Acrotron.classify([mia, reply, grumble], grumble, players), ChatTarget.nobody);
      expect(Acrotron.classify([mia, reply, laugh], laugh, players), ChatTarget.nobody);
      expect(Acrotron.classify([mia, reply, miaBack], miaBack, players), ChatTarget.acrotron);
      final jab = ChatMessage('John', 'cry about it, bolt brain', time: t.add(const Duration(seconds: 20)));
      expect(Acrotron.classify([mia, reply, laugh, jab], jab, players), ChatTarget.acrotron);
      final rusty = ChatMessage('John', 'nobody asked you, rusty', time: t.add(const Duration(seconds: 20)));
      expect(Acrotron.classify([rusty], rusty, players), ChatTarget.acrotron);
    });

    test('an old Acrotron line no longer counts as the conversation', () {
      final said = ChatMessage(acrotronName, 'Losers.', time: DateTime(2026));
      final later = ChatMessage('John', 'this deck is cursed', time: DateTime(2026).add(const Duration(minutes: 5)));
      expect(Acrotron.classify([said, later], later, players), ChatTarget.nobody);
    });
  });

  group('replying', () {
    late Game table;
    late List<String> prompts;
    var thinking = Duration.zero;

    setUp(() {
      Settings.instance.acrotronChattiness = 0; // only speaks when addressed
      table = Game();
      table.setupOffline(GamePlayer('John', 0, true)..id = 'local', 3, acrotron: true);
      table.playerDB['mia'] = GamePlayer('Mia', table.players.length, true);
      prompts = [];
      thinking = Duration.zero;
      Acrotron.instance.modelOverride = (messages, schema) async {
        prompts.add(messages.last['content']!);
        await Future.delayed(thinking);
        return 'Bite me, ${prompts.length}';
      };
    });

    tearDown(() => Acrotron.instance.modelOverride = null);

    Iterable<String> lines() => table.chat.value.where((m) => m.author == acrotronName).map((m) => m.text);

    testWidgets('answers when spoken to, and knows it', (tester) async {
      table.say('John', 'oi toaster, deal faster');
      await tester.pump(const Duration(milliseconds: 50));
      expect(prompts.single, contains('John is talking to you'));
      expect(lines(), ['Bite me, 1']);
    });

    testWidgets('stays out of other people\'s conversations', (tester) async {
      table.say('John', 'Mia, want to grab pizza after this?');
      table.say('Mia', 'yeah sure, pepperoni?');
      await tester.pump(const Duration(milliseconds: 50));
      expect(prompts, isEmpty, reason: 'no model call when it isn\'t replying');
      expect(lines(), isEmpty);
    });

    testWidgets('messages sent while it thinks are queued, not dropped', (tester) async {
      thinking = const Duration(seconds: 2);
      table.say('John', 'hey acrotron');
      await tester.pump(const Duration(milliseconds: 100));
      table.say('Mia', 'you still there, tin can?');
      table.say('John', 'helloooo bot');
      await tester.pump(const Duration(seconds: 5));
      expect(prompts.length, 2, reason: 'the two late messages are answered together');
      expect(prompts.last, contains('you still there, tin can?'));
      expect(prompts.last, contains('helloooo bot'));
      expect(lines().length, 2);
    });
  });
}
