import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:donut_game/campaign/backdrops.dart';
import 'package:donut_game/campaign/campaign.dart';
import 'package:donut_game/campaign/campaign_controller.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/data/settings.dart';
import 'package:donut_game/progression/catalog.dart';
import 'package:donut_game/progression/environments.dart';
import 'package:donut_game/progression/profile.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/campaign/campaign_screen.dart';
import 'package:donut_game/ui/career/career_screen.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:donut_game/ui/game/game_screen.dart';
import 'package:donut_game/ui/home/home_screen.dart';
import 'package:donut_game/ui/widget/donut_logo.dart';
import 'package:donut_game/ui/widget/playing_card.dart';
import 'package:donut_game/ui/widget/table_tools.dart' show markerWidth;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'layout_test.dart' show loadRealFonts, pumpFor;

/// Renders the Steam page's art from the game's own drawing: capsules,
/// library art and 1920x1080 screenshots of real game moments.
///
///   STORE_ART=/some/folder flutter test test/store_art_test.dart
///
/// Skipped unless STORE_ART is set.
final String? outDir = Platform.environment['STORE_ART'];

const _theme = ThemePreset.midnightCasino;
const _scene = 'backdrop.grand';
const _felt = 'env.red';
const _face = 'face.gilded';
const _back = 'pattern.midnight_glaze';

void main() {
  setUpAll(() async {
    await loadRealFonts();
    await loadDeckFonts();
    // A player well into their career, with the good decks equipped
    final profile = PlayerProfile.instance..reset();
    profile.grant(xp: 250000, crumbs: 999999, glaze: 99999);
    for (final item in catalog) {
      profile.buy(item);
    }
    for (final id in [_face, _back, 'env.galaxy']) {
      profile.equip(id);
    }
    Settings.instance
      ..nickname = 'You'
      ..theme.value = _theme;
  });
  tearDownAll(() => PlayerProfile.instance.reset());

  // --- Capsules and library art -----------------------------------------------

  final art = <String, (Size, Widget)>{
    'store_header_capsule': (const Size(920, 430), const KeyArt(layout: ArtLayout.wide)),
    'store_small_capsule': (const Size(462, 174), const KeyArt(layout: ArtLayout.small)),
    'store_main_capsule': (const Size(1232, 706), const KeyArt(layout: ArtLayout.wide)),
    'store_vertical_capsule': (const Size(748, 896), const KeyArt(layout: ArtLayout.tall)),
    'store_page_background': (const Size(1438, 810), const KeyArt(layout: ArtLayout.scene, dim: 0.55)),
    'library_capsule': (const Size(600, 900), const KeyArt(layout: ArtLayout.tall)),
    'library_header': (const Size(920, 430), const KeyArt(layout: ArtLayout.wide)),
    'library_hero': (const Size(3840, 1240), const KeyArt(layout: ArtLayout.scene)),
    'library_logo': (const Size(1280, 720), const KeyArt(layout: ArtLayout.logoOnly)),
    'community_icon': (const Size(184, 184), const KeyArt(layout: ArtLayout.icon)),
  };
  for (final MapEntry(key: name, value: (size, widget)) in art.entries) {
    testWidgets(name, skip: outDir == null, (tester) async {
      await _capture(tester, name, size, widget);
    });
  }

  // --- Screenshots, 1920x1080 ---------------------------------------------------

  const shot = Size(1920, 1080);

  testWidgets('screenshot_1_campaign_trick', skip: outDir == null, (tester) async {
    final controller = CampaignGameController(stage: allStages[4], difficulty: Difficulty.standard);
    await _capture(tester, 'screenshot_1_campaign_trick', shot, GameScreen(controller: controller), setUp: () async {
      await _playUntil(tester, controller, (game) => game.table.cards.value.length >= 2 && controller.canPlayNow);
    });
  });

  testWidgets('screenshot_2_swap', skip: outDir == null, (tester) async {
    final controller = OfflineGameController(nickname: 'You', bots: 5);
    await _capture(tester, 'screenshot_2_swap', shot, GameScreen(controller: controller), setUp: () async {
      await tester.tap(find.text('Deal'));
      await pumpFor(tester, const Duration(seconds: 12));
      final local = controller.localPlayer;
      final hand = [...local.hand.cards.value]..sort((a, b) => a.value.index.compareTo(b.value.index));
      for (final card in hand.take(2)) {
        await controller.toggleSwap(card);
      }
      await pumpFor(tester, const Duration(milliseconds: 800));
    });
  });

  testWidgets('screenshot_3_campaign_map', skip: outDir == null, (tester) async {
    await _capture(tester, 'screenshot_3_campaign_map', shot, const CampaignScreen());
  });

  testWidgets('screenshot_4_shop', skip: outDir == null, (tester) async {
    await _capture(tester, 'screenshot_4_shop', shot, const CareerScreen(initialTab: 1));
  });

  testWidgets('screenshot_5_home', skip: outDir == null, (tester) async {
    await _capture(tester, 'screenshot_5_home', shot, const HomeScreen());
  });

  testWidgets('screenshot_6_victory', skip: outDir == null, (tester) async {
    final controller = OfflineGameController(nickname: 'You', bots: 3);
    await _capture(tester, 'screenshot_6_victory', shot, GameScreen(controller: controller), setUp: () async {
      final game = Game();
      final local = controller.localPlayer;
      local
        ..score.value = 0
        ..donuts.value = 0;
      // A close match: everyone else nearly there
      final rivals = game.players.where((player) => player != local).toList();
      for (final (i, score) in [3, 7, 12].indexed) {
        if (i < rivals.length) rivals[i].score.value = score;
      }
      game
        ..matchStarted = DateTime.now().subtract(const Duration(minutes: 14, seconds: 32))
        ..matchEnded = DateTime.now()
        ..handNumber = 9
        ..champion.value = local
        ..state.value = GameState.gameOver;
      await pumpFor(tester, const Duration(seconds: 3));
    });
  });

  testWidgets('screenshot_7_grand_boss', skip: outDir == null, (tester) async {
    final controller = CampaignGameController(stage: stageById('grand.boss')!, difficulty: Difficulty.brutal);
    await _capture(tester, 'screenshot_7_grand_boss', shot, GameScreen(controller: controller), setUp: () async {
      await _playUntil(tester, controller, (game) => game.table.cards.value.length >= 3 && controller.canPlayNow);
      // Deep into the match: the boss nearly out, you close behind
      final game = controller.game;
      final local = controller.localPlayer;
      local
        ..score.value = 6
        ..donuts.value = 1;
      final rivals = game.players.where((player) => player != local).toList();
      for (final (i, (score, donuts)) in [(4, 0), (9, 1), (13, 2), (11, 1)].indexed) {
        if (i < rivals.length) {
          rivals[i]
            ..score.value = score
            ..donuts.value = donuts;
        }
      }
      game.handNumber = 8;
      // The boss gets the last word, unless she sat this hand out
      final boss = rivals.first;
      game.say(boss.skip ? game.table.cards.value.first.belongsTo!.name : boss.name,
          boss.skip ? 'Filled to the brim.' : 'Layer upon layer, darling.');
      await pumpFor(tester, const Duration(milliseconds: 500));
    });
  });

  testWidgets('screenshot_8_doodles', skip: outDir == null, (tester) async {
    final controller = CampaignGameController(stage: stageById('diner.1')!, difficulty: Difficulty.standard);
    await _capture(tester, 'screenshot_8_doodles', shot, GameScreen(controller: controller), setUp: () async {
      await _playUntil(tester, controller, (game) => game.table.cards.value.length >= 2 && controller.canPlayNow);
      _doodle(controller);
      controller.game.say('Flapjack Flo', 'Who\'s been drawing on my counter?');
      await pumpFor(tester, const Duration(milliseconds: 500));
    });
  });

  testWidgets('screenshot_9_sudden_death', skip: outDir == null, (tester) async {
    final controller = CampaignGameController(stage: stageById('orbital.boss')!, difficulty: Difficulty.standard);
    await _capture(tester, 'screenshot_9_sudden_death', shot, GameScreen(controller: controller), setUp: () async {
      // You and the Commander both hit zero last hand: only you two play on
      final game = controller.game;
      final local = controller.localPlayer;
      final rivals = game.players.where((player) => player != local).toList();
      final commander = rivals.first;
      local.score.value = 0;
      commander.score.value = 0;
      for (final (i, score) in [3, 7].indexed) {
        if (i + 1 < rivals.length) rivals[i + 1].score.value = score;
      }
      game
        ..handNumber = 11
        ..matchStarted = DateTime.now().subtract(const Duration(minutes: 18))
        ..suddenDeath.addAll([local, commander]);
      await _playUntil(tester, controller, (game) => game.table.cards.value.isNotEmpty && controller.canPlayNow);
      // Let the swap banner give way to the turn prompt
      await pumpFor(tester, const Duration(seconds: 3));
      game.say(commander.name, 'You\'re a long way from the bakery, cadet.');
      await pumpFor(tester, const Duration(milliseconds: 500));
    });
  });
}

/// Covers the felt in table-marker art: a smiley, noughts and crosses, an
/// arrow at the trick, a donut stamp and a couple of bullet holes.
void _doodle(GameController controller) {
  var n = 0;
  void line(Color color, List<Offset> points, {double width = markerWidth}) =>
      controller.draw('doodle-${n++}', color: color, width: width, erase: false, points: points);
  // Points are fractions of the felt, which is about three times wider than tall
  const aspect = 3.0;
  List<Offset> arc(Offset centre, double r, double from, double to, {int steps = 40}) => [
        for (var i = 0; i <= steps; i++)
          Offset(
            centre.dx + cos(from + (to - from) * i / steps) * r,
            centre.dy + sin(from + (to - from) * i / steps) * r * aspect,
          ),
      ];

  const yellow = Color(0xFFFDD835), white = Color(0xFFFAFAFA), red = Color(0xFFE53935);
  const blue = Color(0xFF1E88E5), pink = Color(0xFFF06292), green = Color(0xFF43A047);

  // A smiley, upper left
  const face = Offset(0.2, 0.36);
  line(yellow, arc(face, 0.055, 0, 2 * pi));
  line(yellow, arc(face + const Offset(-0.02, -0.06), 0.004, 0, 2 * pi, steps: 12), width: 0.008);
  line(yellow, arc(face + const Offset(0.02, -0.06), 0.004, 0, 2 * pi, steps: 12), width: 0.008);
  line(yellow, arc(face + const Offset(0, 0.01), 0.032, 0.15 * pi, 0.85 * pi));

  // Noughts and crosses, upper right
  const left = 0.74, top = 0.14, cell = 0.04, cellH = cell * aspect;
  for (var i = 1; i <= 2; i++) {
    line(white, [Offset(left + cell * i, top), Offset(left + cell * i, top + cellH * 3)]);
    line(white, [Offset(left, top + cellH * i), Offset(left + cell * 3, top + cellH * i)]);
  }
  Offset centreOf(int col, int row) => Offset(left + cell * (col + 0.5), top + cellH * (row + 0.5));
  void cross(int col, int row) {
    final c = centreOf(col, row);
    const d = cell * 0.28;
    line(red, [c + const Offset(-d, -d * aspect), c + const Offset(d, d * aspect)]);
    line(red, [c + const Offset(d, -d * aspect), c + const Offset(-d, d * aspect)]);
  }
  void nought(int col, int row) => line(blue, arc(centreOf(col, row), cell * 0.3, 0, 2 * pi));
  cross(0, 0);
  nought(1, 1);
  cross(2, 0);
  nought(1, 0);
  cross(0, 2);

  // An arrow at the trick
  line(green, [for (var i = 0; i <= 30; i++) Offset(0.29 + 0.09 * i / 30, 0.66 - 0.16 * sin(pi * i / 60))]);
  line(green, [const Offset(0.355, 0.47), const Offset(0.38, 0.5), const Offset(0.353, 0.55)]);

  // A donut stamp, as the stamp tool draws it
  line(pink, arc(const Offset(0.19, 0.76), 0.045, 0, 2 * pi), width: 0.045 * 0.9);

  // Someone found the revolver
  controller.game
    ..shootTable('Flapjack Flo', 0.64, 0.24, seed: 7)
    ..shootTable('Flapjack Flo', 0.67, 0.33, seed: 19);
}

/// The serif and typewriter decks' fonts, and an emoji font for the donut
/// counts, from this Mac or this PC.
Future<void> loadDeckFonts() async {
  for (final (family, files) in [
    ('Georgia', ['/System/Library/Fonts/Supplemental/Georgia.ttf', '/System/Library/Fonts/Supplemental/Georgia Bold.ttf', 'C:/Windows/Fonts/georgia.ttf', 'C:/Windows/Fonts/georgiab.ttf']),
    ('Courier New', ['/System/Library/Fonts/Supplemental/Courier New.ttf', '/System/Library/Fonts/Supplemental/Courier New Bold.ttf', 'C:/Windows/Fonts/cour.ttf', 'C:/Windows/Fonts/courbd.ttf']),
    (_emojiFont, ['/System/Library/Fonts/Apple Color Emoji.ttc', 'C:/Windows/Fonts/seguiemj.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final file in files) {
      final font = File(file);
      if (font.existsSync()) loader.addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
    }
    await loader.load();
  }
}

const _emojiFont = 'Emoji';

/// [theme] with the emoji font to fall back on; tests have no system fonts to
/// find one in.
ThemeData withEmoji(ThemeData theme) => theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamilyFallback: const [_emojiFont]),
      primaryTextTheme: theme.primaryTextTheme.apply(fontFamilyFallback: const [_emojiFont]),
    );

/// Plays the local player's moves (keeping their hand, leading their first
/// legal card) until [ready] says the table looks right.
Future<void> _playUntil(WidgetTester tester, GameController controller, bool Function(Game game) ready) async {
  await tester.tap(find.text('Deal'));
  for (var i = 0; i < 600; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    final game = controller.game;
    if (ready(game)) break;
    final local = controller.localPlayer;
    if (local == null) continue;
    if (game.state.value == GameState.waitingForPlayerToSwap && controller.isLocalTurn && local.notReady) {
      await controller.confirmSwap();
    } else if (controller.canPlayNow && game.table.cards.value.isEmpty) {
      // Lead, so the bots answer and the trick fills up
      final card = local.hand.cards.value.firstWhere(controller.isLegal);
      await controller.play(card);
    } else if (game.state.value == GameState.waitingToDeal && i > 50) {
      await tester.tap(find.text('Deal'));
    }
  }
  await pumpFor(tester, const Duration(milliseconds: 1200));
}

Future<void> _capture(WidgetTester tester, String name, Size size, Widget child,
    {Future<void> Function()? setUp}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: withEmoji(buildTheme(_theme)),
    builder: (context, page) => RepaintBoundary(key: key, child: page),
    home: child is KeyArt ? Material(type: MaterialType.transparency, child: child) : child,
  ));
  await tester.pump(const Duration(milliseconds: 600));
  await setUp?.call();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(outDir!).createSync(recursive: true);
    File('$outDir/${name}_${size.width.toInt()}x${size.height.toInt()}.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
  });
  // Let any game loop wind down before the next one
  await tester.pumpWidget(const SizedBox());
  await pumpFor(tester, const Duration(seconds: 3));
}

enum ArtLayout { wide, small, tall, scene, logoOnly, icon }

/// The key art: a venue, its table, a fanned hand and the Donut mark.
class KeyArt extends StatelessWidget {
  const KeyArt({super.key, required this.layout, this.dim = 0});

  final ArtLayout layout;

  /// Darkens everything, for art that sits behind the store page.
  final double dim;

  static final _hand = [
    GameCard(Suit.hearts, Value.ace),
    GameCard(Suit.spades, Value.king),
    GameCard(Suit.diamonds, Value.queen),
    GameCard(Suit.clubs, Value.jack),
    GameCard(Suit.hearts, Value.ten),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      switch (layout) {
        case ArtLayout.logoOnly:
          // Transparent, for Steam to lay over the hero
          return Center(child: _mark(size.height * 0.62, row: true));
        case ArtLayout.icon:
          return Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(colors: [Color(0xFF3A1C2A), Color(0xFF120A14)]),
            ),
            child: Center(child: DonutLogo(size: size.shortestSide * 0.86, frosting: const Color(0xFFF06292))),
          );
        default:
          break;
      }
      final tall = layout == ArtLayout.tall;
      final small = layout == ArtLayout.small;
      final scene = layout == ArtLayout.scene;
      final h = size.height, w = size.width;

      // The hand: centred low on tall art, to the right on wide art
      final cardH = scene ? h * 0.42 : (tall ? h * 0.27 : (small ? h * 0.56 : h * 0.50));
      final handCenter = scene
          ? Offset(w * 0.5, h * 0.80)
          : tall
              ? Offset(w * 0.5, h * 0.90)
              : Offset(w * (small ? 0.83 : 0.77), h * (small ? 0.90 : 0.84));

      return Stack(fit: StackFit.expand, clipBehavior: Clip.hardEdge, children: [
        const Backdrop(id: _scene),
        // Shade towards the words so they read on any scene
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: tall ? Alignment.topCenter : Alignment.centerLeft,
              end: tall ? Alignment.bottomCenter : Alignment.centerRight,
              colors: [Colors.black.withValues(alpha: scene ? 0.15 : 0.62), Colors.black.withValues(alpha: 0.05)],
            ),
          ),
        ),
        _table(size),
        ..._fan(handCenter, cardH, spread: tall ? 1.0 : (small ? 0.8 : 1.0)),
        if (!scene)
          Positioned(
            left: tall ? w * 0.06 : w * 0.05,
            right: tall ? w * 0.06 : w * (small ? 0.36 : 0.50),
            top: tall ? h * 0.06 : 0,
            bottom: tall ? h * 0.50 : 0,
            child: Center(
              child: _mark(
                tall ? w * 0.42 : h * (small ? 0.62 : 0.42),
                row: !tall,
              ),
            ),
          ),
        if (dim > 0) ColoredBox(color: Colors.black.withValues(alpha: dim)),
      ]);
    });
  }

  /// The felt: a wide oval rising from the bottom edge.
  Widget _table(Size size) {
    final env = TableEnvironment.byId(_felt);
    final felt = env.felt ?? const Color(0xFF7A1F2B);
    final edge = env.edge ?? const Color(0xFF4F121B);
    final width = size.width * (layout == ArtLayout.tall ? 1.6 : 1.25);
    final height = size.height * (layout == ArtLayout.tall ? 0.55 : 0.75);
    return Positioned(
      left: (size.width - width) / 2,
      width: width,
      bottom: -height * 0.45,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: felt,
          border: Border.all(color: edge, width: size.shortestSide * 0.025),
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 40, spreadRadius: 8)],
        ),
        child: ClipOval(child: env.texture == null ? null : CustomPaint(painter: env.texture!(felt))),
      ),
    );
  }

  /// Five cards fanned from a point below their centre.
  List<Widget> _fan(Offset center, double cardH, {double spread = 1}) {
    final cardW = cardH * cardDesignSize.width / cardDesignSize.height;
    return [
      for (var i = 0; i < _hand.length; i++)
        Positioned(
          left: center.dx - cardW / 2,
          top: center.dy - cardH,
          width: cardW,
          height: cardH,
          child: Transform.rotate(
            angle: (i - 2) * 0.17 * spread,
            alignment: const Alignment(0, 2.2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cardW * 0.08),
                boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8))],
              ),
              child: PlayingCardWidget(card: _hand[i], face: _face, back: _back, trump: i == 0),
            ),
          ),
        ),
    ];
  }

  /// The donut and the name, side by side or stacked.
  Widget _mark(double size, {required bool row}) {
    final title = Text(
      'Donut',
      style: TextStyle(
        fontFamily: 'Roboto',
        fontWeight: FontWeight.w900,
        fontSize: size * (row ? 0.62 : 0.42),
        height: 1,
        color: const Color(0xFFFFF4E6),
        letterSpacing: -size * 0.01,
        shadows: [
          Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: size * 0.08, offset: Offset(0, size * 0.03))
        ],
      ),
    );
    final words = title;
    final logo = DonutLogo(size: size * (row ? 0.82 : 0.7), frosting: const Color(0xFFF06292));
    return FittedBox(
      child: row
          ? Row(mainAxisSize: MainAxisSize.min, children: [logo, SizedBox(width: size * 0.08), words])
          : Column(mainAxisSize: MainAxisSize.min, children: [logo, SizedBox(height: size * 0.05), words]),
    );
  }
}
