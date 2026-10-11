import 'dart:io';
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
    // The serif and typewriter decks' fonts, from this Mac
    for (final (family, files) in [
      ('Georgia', ['Georgia.ttf', 'Georgia Bold.ttf']),
      ('Courier New', ['Courier New.ttf', 'Courier New Bold.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final file in files) {
        final font = File('/System/Library/Fonts/Supplemental/$file');
        if (font.existsSync()) loader.addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
      }
      await loader.load();
    }
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
}

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
    theme: buildTheme(_theme),
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
