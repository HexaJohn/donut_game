import 'dart:io';
import 'dart:ui' as ui;

import 'package:donut_engine/donut_engine.dart' show Suit, Value;
import 'package:donut_game/campaign/backdrops.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/progression/card_faces.dart';
import 'package:donut_game/progression/catalog.dart';
import 'package:donut_game/progression/emblem.dart';
import 'package:donut_game/progression/environments.dart';
import 'package:donut_game/progression/ranks.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/career/rank_insignia.dart';
import 'package:donut_game/ui/widget/confetti.dart';
import 'package:donut_game/ui/widget/donut_logo.dart';
import 'package:donut_game/ui/widget/playing_card.dart';
import 'package:donut_game/ui/widget/revolver.dart';
import 'package:donut_game/ui/widget/suit_icon.dart';
import 'package:donut_game/ui/widget/table_tools.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'layout_test.dart' show loadRealFonts;
import 'store_art_test.dart' show loadDeckFonts, withEmoji;

/// Renders every piece of code-drawn (AI-made) art to a PNG, so each can be
/// redrawn by hand. Transparent where the art is; scaled up so it's sharp.
///
///   ART_EXPORT=/some/folder flutter test test/art_export_test.dart
///
/// Skipped unless ART_EXPORT is set.
final String? outDir = Platform.environment['ART_EXPORT'];

const _theme = ThemePreset.midnightCasino;
const _scene = Size(1920, 1080);
const _card = Size(250, 350);

String _slug(String id) => id.replaceFirst(RegExp(r'^\w+\.'), '');

void main() {
  setUpAll(() async {
    await loadRealFonts();
    await loadDeckFonts();
  });

  void art(String path, Size size, Widget child, {double scale = 1, Duration settle = Duration.zero}) {
    testWidgets(path, skip: outDir == null, (tester) => _capture(tester, path, size, child, scale, settle));
  }

  // Campaign venues, behind the table
  for (final id in ['backdrop.bakery', 'backdrop.market', 'backdrop.diner', 'backdrop.riverboat', 'backdrop.orbital', 'backdrop.grand']) {
    art('backdrops/${_slug(id)}', _scene, CustomPaint(size: _scene, painter: backdropPainter(id)));
  }

  // Table surfaces with a drawn texture (the plain felts are just colours)
  for (final env in environments.where((env) => env.texture != null)) {
    art('tables/${_slug(env.id)}', _scene,
        Container(color: env.felt, child: CustomPaint(size: _scene, painter: env.texture!(env.felt!))));
  }

  // Card backs, in the default theme's colours
  for (final id in catalog.map((item) => item.id).where((id) => id.startsWith('pattern.'))) {
    art('card_backs/${_slug(id)}', _card, CardBack(pattern: id), scale: 4);
  }

  // Every deck's faces: all 52 cards
  final faces = {'face.classic', ...catalog.map((item) => item.id).where((id) => id.startsWith('face.'))};
  for (final style in faces) {
    for (final suit in Suit.values) {
      for (final value in Value.values) {
        art('card_faces/${_slug(style)}/${suit.name}_${value.name}', _card,
            CardFace(card: GameCard(suit, value), style: style),
            scale: 4);
      }
    }
  }
  art('card_faces/sprinkle_edge', _card, const CustomPaint(size: _card, painter: SprinkleEdgePainter()), scale: 4);

  for (final suit in Suit.values) {
    final red = suit == Suit.hearts || suit == Suit.diamonds;
    art('suits/${suit.name}', const Size.square(64),
        SuitIcon(suit, size: 64, color: red ? const Color(0xFFD32F2F) : const Color(0xFF212121)),
        scale: 8);
  }

  for (final shape in EmblemShape.values) {
    art('emblems/${shape.name}', const Size.square(128), EmblemWidget(emblem: Emblem(shape: shape), size: 128), scale: 4);
  }

  for (final rank in ranks) {
    final name = rank.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    art('ranks/${rank.index.toString().padLeft(2, '0')}_$name${rank.grade > 0 ? '_${rank.grade}' : ''}',
        const Size.square(128), RankInsignia(rank: rank, size: 128, color: const Color(0xFFFFD54F)),
        scale: 4);
  }

  art('logo/donut', const Size.square(256), const DonutLogo(size: 256), scale: 4);

  art('table_tools/revolver', revolverSize, const Revolver(), scale: 8);
  art('table_tools/revolver_firing', revolverSize, const Revolver(flash: true), scale: 8);
  for (final seed in [1, 2, 3, 4]) {
    art('table_tools/bullet_hole_$seed', const Size.square(64),
        BulletHoleMark(seed: seed, size: 64, surface: const Color(0xFF7A1F2B)),
        scale: 8);
  }
  for (final (i, color) in markerColors.indexed) {
    art('table_tools/marker_${i + 1}', markerSize, MarkerPen(color: color), scale: 8);
  }
  art('table_tools/eraser', eraserSize, const EraserBlock(), scale: 8);
  art('table_tools/flashbang', flashbangSize, const FlashbangGrenade(), scale: 8);
  art('table_tools/flashbang_lit', flashbangSize, const FlashbangGrenade(lit: true), scale: 8);

  // One moment of the burst
  art('effects/confetti', const Size.square(400),
      const ConfettiBurst(size: 400, life: Duration(seconds: 2), seed: 3),
      scale: 2, settle: const Duration(milliseconds: 500));
}

Future<void> _capture(WidgetTester tester, String path, Size size, Widget child, double scale, Duration settle) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: withEmoji(buildTheme(_theme)),
    home: Material(
      type: MaterialType.transparency,
      child: Center(
        child: RepaintBoundary(key: key, child: SizedBox.fromSize(size: size, child: child)),
      ),
    ),
  ));
  await tester.pump(settle);
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: scale);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$outDir/$path.png')..parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}
