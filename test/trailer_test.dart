import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:donut_game/audio/sfx.dart';
import 'package:donut_game/campaign/campaign.dart';
import 'package:donut_game/campaign/campaign_controller.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/data/model/game_card/game_card.dart';
import 'package:donut_game/data/settings.dart';
import 'package:donut_game/progression/catalog.dart';
import 'package:donut_game/progression/profile.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/campaign/campaign_screen.dart';
import 'package:donut_game/ui/career/career_screen.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:donut_game/ui/game/game_screen.dart';
import 'package:donut_game/ui/home/home_screen.dart';
import 'package:donut_game/ui/widget/donut_logo.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'layout_test.dart' show loadRealFonts, pumpFor;
import 'store_art_test.dart' show ArtLayout, KeyArt, loadDeckFonts, withEmoji;

/// Records the Steam trailer from the game itself: every frame is the real
/// game drawn at 1920x1080, driven by a script, with the trailer's captions
/// drawn over it. Frames go straight into ffmpeg; the sounds the game asked
/// for are written alongside, for tool/trailer_audio.py to mix with the music.
///
///   TRAILER=/some/folder flutter test test/trailer_test.dart
///
/// Writes video.mp4 (no audio) and sounds.csv. Skipped unless TRAILER is set.
final String? outDir = Platform.environment['TRAILER'];

const int fps = 30;
const Size frameSize = Size(1920, 1080);
const _theme = ThemePreset.midnightCasino;

/// The pitch, in the game's own words.
const _cta = 'WISHLIST NOW';
const _tagline = 'Get to zero. Avoid the donut.';

const _pink = Color(0xFFF06292);
const _gold = Color(0xFFFFC857);
const _cream = Color(0xFFFFF4E6);
const _plum = Color(0xFF2A0F1E);

void main() {
  setUpAll(() async {
    await loadRealFonts();
    await loadDeckFonts();
    final profile = PlayerProfile.instance..reset();
    profile.grant(xp: 250000, crumbs: 999999, glaze: 99999);
    for (final item in catalog) {
      profile.buy(item);
    }
    for (final id in ['face.gilded', 'pattern.midnight_glaze']) {
      profile.equip(id);
    }
    Settings.instance
      ..nickname = 'You'
      ..theme.value = _theme;
  });
  tearDownAll(() {
    SoundEffects.debugOnPlay = null;
    PlayerProfile.instance.reset();
  });

  testWidgets('trailer', skip: outDir == null, timeout: const Timeout(Duration(minutes: 40)), (tester) async {
    final rec = Recorder(tester);
    await rec.start();

    // --- 1. Straight into a hand: deal, swap, play --------------------------------
    GameController controller = CampaignGameController(stage: stageById('market.2')!, difficulty: Difficulty.standard);
    await rec.show(GameScreen(controller: controller));
    await tester.tap(find.text('Deal').first);
    rec.cut();
    rec.caption('GET TO ZERO.', kicker: 'A TRICK-TAKING CARD GAME', length: 2.6, at: 0.15);
    // Deal and trump, until it's your move
    await rec.record(5, until: () => _yourSwap(controller));
    await rec.record(0.3);
    rec.caption('SWAP UP TO 3.', kicker: 'BAD HAND?', length: 2.4);
    final local = controller.localPlayer!;
    final trump = controller.game.trumpSuit.value;
    final junk = [...local.hand.cards.value.where((card) => card.suit != trump)]
      ..sort((a, b) => a.value.index.compareTo(b.value.index));
    for (final card in junk.take(2)) {
      await rec.record(0.35);
      await controller.toggleSwap(card);
    }
    await rec.record(0.6);
    await controller.confirmSwap();
    // First trick: play it out and watch it get taken
    var tricks = controller.game.trickSerial;
    var captioned = false;
    await rec.record(9, until: () => controller.game.trickSerial >= tricks + 1, each: () async {
      if (!captioned && controller.game.table.cards.value.isNotEmpty) {
        captioned = true;
        rec.caption('TAKE TRICKS.', kicker: 'TRUMP BEATS EVERYTHING', length: 2.6);
      }
      await rec.autoPlay(controller, best: true);
    });
    rec.caption('EVERY TRICK: −1', kicker: 'FIRST TO ZERO WINS', length: 2.2);
    await rec.record(1.9);

    // --- 2. A donut ----------------------------------------------------------------
    await rec.skip(until: () => _lastTrickWithADonut(controller), each: () => rec.autoPlay(controller));
    rec.cut();
    final before = {for (final player in controller.game.players) player: player.donuts.value};
    rec.caption('NO TRICKS YET?', kicker: 'LAST TRICK OF THE HAND', length: 2.6, at: 0.1);
    await rec.record(9,
        until: () => controller.game.state.value == GameState.waitingToDeal, each: () => rec.autoPlay(controller));
    final donuts = [
      for (final player in controller.game.players)
        if (player.donuts.value > before[player]!) player == controller.localPlayer ? 'YOU' : player.name.toUpperCase()
    ];
    rec.caption('THAT\'S A DONUT. +5', kicker: donuts.join(' & '), length: 2.2);
    await rec.record(2.2);

    // --- 3. Table toys -------------------------------------------------------------
    await rec.skip(seconds: 2);
    rec.cut();
    await rec.toys(controller);

    // --- 4. The campaign ------------------------------------------------------------
    controller.game.abort();
    final rivals = {for (final stage in allStages) ...stage.opponents.map((opponent) => opponent.name)}.length;
    await rec.show(const CampaignScreen());
    rec.cut();
    rec.zoom = (t) => 1 + 0.03 * t;
    rec.caption('${campaign.length} VENUES. $rivals RIVALS.', kicker: 'SINGLE-PLAYER CAMPAIGN', length: 2.3, at: 0.1);
    await rec.record(2.3);
    rec.zoom = null;

    for (final (id, line) in [
      ('bakery.boss', null),
      ('diner.2', null),
      ('riverboat.boss', null),
      ('orbital.2', null),
      ('grand.boss', 'BEAT THE BOSSES.'),
    ]) {
      controller.game.abort();
      final stage = stageById(id)!;
      controller = CampaignGameController(stage: stage, difficulty: Difficulty.standard);
      await rec.show(GameScreen(controller: controller));
      await tester.tap(find.text('Deal').first);
      await rec.skip(
        until: () => controller.game.table.cards.value.length >= 2 && controller.canPlayNow,
        each: () => rec.autoPlay(controller),
      );
      rec.cut();
      final venue = venueOf(stage);
      final length = line == null ? 1.5 : 2.6;
      rec.caption(line ?? venue.name.toUpperCase(),
          kicker: line == null ? stage.name.toUpperCase() : venue.name.toUpperCase(), length: length, at: 0.05, small: line == null);
      await rec.record(0.45);
      await rec.autoPlay(controller, best: true, now: true);
      await rec.record(length - 0.45);
    }

    // --- 5. Career and online -----------------------------------------------------------
    controller.game.abort();
    await rec.show(const CareerScreen(initialTab: 1));
    rec.cut();
    rec.zoom = (t) => 1.04 - 0.04 * t / 2.4;
    rec.caption('UNLOCK DECKS & TABLES.', kicker: 'RANK UP', length: 2.4, at: 0.1);
    await rec.record(2.4);
    rec.zoom = null;

    await rec.show(const HomeScreen());
    rec.cut();
    rec.caption('PLAY FRIENDS ONLINE.', kicker: 'OR TAKE ON THE BOTS', length: 2.4, at: 0.1, right: true);
    await rec.record(0.7);
    await tester.tap(find.text('Online').first);
    await rec.record(1.7);

    // --- 6. A win, then the end card ---------------------------------------------------
    controller = OfflineGameController(nickname: 'You', bots: 3);
    await rec.show(GameScreen(controller: controller));
    final game = controller.game;
    final you = controller.localPlayer!;
    you.score.value = 0;
    final others = game.players.where((player) => player != you).toList();
    for (final (i, score) in [2, 6, 11].indexed) {
      if (i < others.length) others[i].score.value = score;
    }
    game
      ..matchStarted = DateTime.now().subtract(const Duration(minutes: 12, seconds: 48))
      ..matchEnded = DateTime.now()
      ..handNumber = 8
      ..champion.value = you
      ..state.value = GameState.gameOver;
    rec.cut();
    await rec.record(2.2);

    controller.game.abort();
    await rec.show(const _EndCard());
    rec.cut(flash: false);
    rec.fadeOutFrom = rec.t + 4.0;
    await rec.record(4.6);

    await rec.finish();
  });
}

bool _yourSwap(GameController controller) {
  final game = controller.game;
  return game.state.value == GameState.waitingForPlayerToSwap &&
      controller.isLocalTurn &&
      controller.localPlayer!.notReady;
}

/// The start of a hand's last trick, with someone still on no tricks.
bool _lastTrickWithADonut(GameController controller) {
  final game = controller.game;
  if (game.state.value != GameState.playing && game.state.value != GameState.waitingForPlayer) return false;
  if (game.table.cards.value.isNotEmpty) return false;
  final seated = game.players.where((player) => !player.skip).toList();
  if (seated.any((player) => player.hand.cards.value.length != 1)) return false;
  return seated.any((player) => player.tricks == 0);
}

/// One line of trailer text: a kicker over a slab-backed headline.
class Caption {
  Caption(this.start, this.end, this.headline, {this.kicker, this.small = false, this.right = false});

  final double start, end;
  final String headline;
  final String? kicker;
  final bool small;
  final bool right;
}

class Recorder {
  Recorder(this.tester);

  final WidgetTester tester;
  Process? _ffmpeg;
  int frames = 0;
  final clock = ValueNotifier<double>(0);
  final _screen = ValueNotifier<Widget>(const SizedBox());
  final _key = GlobalKey();
  final captions = <Caption>[];
  final cuts = <(double, bool)>[];
  final sounds = <(double, Sfx, double)>[];
  double Function(double sinceCut)? zoom;
  double? fadeOutFrom;

  /// Where a pretend mouse pointer is drawn, when it isn't holding a tool.
  Offset? cursor;
  /// Off while skipping, so only sounds that make the cut are kept.
  bool _recording = true;

  double get t => frames / fps;

  Future<void> start() async {
    tester.view.physicalSize = frameSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SoundEffects.debugOnPlay = (sfx, volume) {
      if (_recording) sounds.add((t, sfx, volume));
    };
    Directory(outDir!).createSync(recursive: true);
    await tester.runAsync(() async {
      _ffmpeg = await Process.start('ffmpeg', [
        '-y', '-loglevel', 'error',
        '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', '${frameSize.width.toInt()}x${frameSize.height.toInt()}',
        '-r', '$fps', '-i', '-',
        // Near-lossless; the final encode with sound happens afterwards
        '-c:v', 'libx264', '-preset', 'veryfast', '-crf', '8', '-pix_fmt', 'yuv444p',
        '$outDir/video.mp4',
      ]);
      _ffmpeg!.stdout.drain<void>();
      _ffmpeg!.stderr.listen(stderr.add);
    });
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: withEmoji(buildTheme(_theme)),
      builder: (context, page) => RepaintBoundary(key: _key, child: _TrailerFrame(rec: this, page: page!)),
      home: ValueListenableBuilder(valueListenable: _screen, builder: (context, screen, _) => screen),
    ));
  }

  /// Swaps the screen, giving the new one a moment to settle off the record.
  Future<void> show(Widget screen) async {
    _screen.value = const SizedBox();
    await tester.pump(const Duration(milliseconds: 50));
    _screen.value = KeyedSubtree(key: UniqueKey(), child: screen);
    await pumpFor(tester, const Duration(milliseconds: 700));
  }

  void cut({bool flash = true}) => cuts.add((t, flash));

  void caption(String headline, {String? kicker, required double length, double at = 0, bool small = false, bool right = false}) {
    final start = t + at;
    // One caption at a time: whatever's up makes way
    for (final (i, other) in captions.indexed.toList()) {
      if (other.end > start && other.start < start) {
        captions[i] = Caption(other.start, start, other.headline, kicker: other.kicker, small: other.small, right: other.right);
      }
    }
    captions.add(Caption(start, start + length, headline, kicker: kicker, small: small, right: right));
  }

  /// Records [seconds] of frames, or until [until] says stop. [each] runs
  /// before every frame.
  Future<void> record(double seconds, {bool Function()? until, Future<void> Function()? each}) async {
    final end = frames + (seconds * fps).round();
    while (frames < end) {
      if (until != null && until()) return;
      await each?.call();
      await frame();
    }
  }

  Future<void> frame() async {
    clock.value = t;
    await tester.pump(const Duration(microseconds: 1000000 ~/ fps));
    await tester.runAsync(() async {
      final boundary = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      _ffmpeg!.stdin.add(bytes!.buffer.asUint8List());
      await _ffmpeg!.stdin.flush();
    });
    frames++;
  }

  /// Runs the game on without recording.
  Future<void> skip({double? seconds, bool Function()? until, Future<void> Function()? each}) async {
    _recording = false;
    final limit = seconds == null ? 6000 : (seconds * 10).round();
    for (var i = 0; i < limit; i++) {
      if (until != null && until()) {
        _recording = true;
        return;
      }
      await each?.call();
      await tester.pump(const Duration(milliseconds: 100));
      final game = Game();
      if (game.state.value == GameState.waitingToDeal && find.text('Deal').evaluate().isNotEmpty) {
        await tester.tap(find.text('Deal').first);
      }
    }
    _recording = true;
    if (until != null && !until()) fail('Gave up waiting while skipping');
  }

  DateTime? _turnSeen;
  int _turnFrames = 0;

  /// Plays for you: keeps your hand at the swap, and plays a legal card a
  /// moment after it becomes your turn (your best one if [best]).
  Future<void> autoPlay(GameController controller, {bool best = false, bool now = false}) async {
    final local = controller.localPlayer!;
    if (_yourSwap(controller)) {
      await controller.confirmSwap();
      return;
    }
    if (!controller.canPlayNow) {
      _turnSeen = null;
      return;
    }
    if (_turnSeen == null) {
      _turnSeen = DateTime.now();
      _turnFrames = 0;
    }
    if (!now && _turnFrames++ < 12) return;
    final legal = local.hand.cards.value.where(controller.isLegal).toList();
    if (legal.isEmpty) return;
    final trump = controller.game.trumpSuit.value;
    int rank(GameCard card) => card.value.index + (card.suit == trump ? 100 : 0);
    legal.sort((a, b) => rank(a).compareTo(rank(b)));
    _turnSeen = null;
    await controller.play(best ? legal.last : legal[Random().nextInt(legal.length)]);
  }

  /// The toys: a doodle, the donut stamp, the revolver and a flashbang.
  Future<void> toys(GameController controller) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    var at = const Offset(1500, 950);
    await mouse.addPointer(location: at);
    cursor = at;

    Future<void> glide(Offset to, double seconds, {bool down = false}) async {
      final from = at;
      final n = max(1, (seconds * fps).round());
      for (var i = 1; i <= n; i++) {
        final p = Offset.lerp(from, to, Curves.easeInOut.transform(i / n))!;
        await mouse.moveTo(p);
        at = p;
        if (cursor != null) cursor = p;
        await frame();
      }
    }

    Future<void> click() async {
      await mouse.down(at);
      await frame();
      await mouse.up();
      await frame();
    }

    Future<void> pickUp(String tool, {int index = 0}) async {
      final where = tester.getCenter(find.byTooltip(tool).at(index));
      await glide(where, 0.45);
      await click();
      cursor = null;
    }

    Future<void> putDown() async {
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      cursor = at;
      await frame();
    }

    final felt = tester.getRect(find.byKey(const ValueKey('felt')).first);
    Offset onFelt(double x, double y) => Offset(felt.left + felt.width * x, felt.top + felt.height * y);

    // A smiley in yellow marker
    caption('DRAW ON THE FELT.', kicker: 'WAITING ON YOUR TURN?', length: 3.4, at: 0.2);
    await pickUp('Marker', index: 3);
    final face = onFelt(0.62, 0.42);
    const r = 105.0;
    await glide(face + const Offset(r, 0), 0.3);
    await mouse.down(at);
    for (var i = 1; i <= 24; i++) {
      final a = 2 * pi * i / 24;
      await mouse.moveTo(face + Offset(cos(a) * r, sin(a) * r));
      at = face + Offset(cos(a) * r, sin(a) * r);
      await frame();
    }
    await mouse.up();
    for (final eye in [const Offset(-36, -28), const Offset(36, -28)]) {
      await glide(face + eye, 0.15);
      await mouse.down(at);
      await mouse.moveTo(at + const Offset(1, 9));
      await frame();
      await mouse.up();
    }
    await glide(face + Offset(cos(0.2 * pi) * 62, sin(0.2 * pi) * 62), 0.15);
    await mouse.down(at);
    for (var i = 1; i <= 10; i++) {
      final a = (0.2 + 0.6 * i / 10) * pi;
      await mouse.moveTo(face + Offset(cos(a) * 62, sin(a) * 62));
      await frame();
    }
    at = face + Offset(cos(0.8 * pi) * 62, sin(0.8 * pi) * 62);
    await mouse.up();
    await frame();
    await putDown();

    // Stamp a couple of donuts
    await pickUp('Donut stamp');
    for (final spot in [onFelt(0.80, 0.30), onFelt(0.86, 0.55)]) {
      await glide(spot, 0.25);
      await click();
    }
    await putDown();

    // The revolver: a placard, then the felt
    caption('OR SHOOT IT.', kicker: 'TABLE TOYS', length: 2.6, at: 0.3);
    await pickUp('Revolver');
    final seat = tester.getCenter(find.text(controller.game.players.where((p) => p != controller.localPlayer).first.name).first);
    await glide(seat, 0.4);
    await click();
    await glide(onFelt(0.30, 0.30), 0.25);
    await click();
    await glide(onFelt(0.36, 0.40), 0.12);
    await click();
    await glide(onFelt(0.33, 0.55), 0.12);
    await click();
    await frame();
    await putDown();

    // And a flashbang
    await pickUp('Flashbang');
    await glide(onFelt(0.5, 0.5), 0.35);
    caption('FLASHBANGS.', kicker: 'OBVIOUSLY', length: 2.0, at: 0.5);
    await click();
    for (var i = 0; i < (2.4 * fps).round(); i++) {
      await frame();
    }
    await mouse.removePointer();
    cursor = null;
  }

  Future<void> finish() async {
    await tester.runAsync(() async {
      await _ffmpeg!.stdin.close();
      final code = await _ffmpeg!.exitCode;
      if (code != 0) throw StateError('ffmpeg exited with $code');
    });
    File('$outDir/sounds.csv').writeAsStringSync([
      'time,sound,volume',
      for (final (time, sfx, volume) in sounds) '${time.toStringAsFixed(4)},${sfx.name},$volume',
    ].join('\n'));
    File('$outDir/edit.txt').writeAsStringSync([
      'frames $frames (${t.toStringAsFixed(2)} s at $fps fps)',
      for (final (time, flash) in cuts) 'cut ${time.toStringAsFixed(2)}${flash ? ' flash' : ''}',
      for (final c in captions) 'caption ${c.start.toStringAsFixed(2)}-${c.end.toStringAsFixed(2)} ${c.kicker ?? ''} / ${c.headline}',
    ].join('\n'));
    await tester.pumpWidget(const SizedBox());
    await pumpFor(tester, const Duration(seconds: 3));
  }
}

/// The game, punched in at each cut, with captions, a pointer and fades on top.
class _TrailerFrame extends StatelessWidget {
  const _TrailerFrame({required this.rec, required this.page});

  final Recorder rec;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: rec.clock,
      builder: (context, t, _) {
        final lastCut = rec.cuts.lastWhere((cut) => cut.$1 <= t, orElse: () => (-10.0, false));
        final since = t - lastCut.$1;
        // A quick punch-in on every cut, settling over a quarter second
        final punch = lastCut.$2 ? 0.045 * (1 - Curves.easeOutCubic.transform((since / 0.28).clamp(0.0, 1.0))) : 0.0;
        final scale = (rec.zoom?.call(since) ?? 1) + punch;
        final flash = lastCut.$2 ? (0.55 * (1 - since / 0.16)).clamp(0.0, 1.0) : 0.0;
        final fade = rec.fadeOutFrom == null ? 0.0 : ((t - rec.fadeOutFrom!) / 0.5).clamp(0.0, 1.0);
        final intro = lastCut.$2 ? 0.0 : (1 - since / 0.25).clamp(0.0, 1.0);
        return Stack(fit: StackFit.expand, children: [
          ClipRect(child: Transform.scale(scale: scale, child: page)),
          for (final caption in rec.captions)
            if (t >= caption.start && t < caption.end) _CaptionView(caption: caption, t: t - caption.start),
          if (rec.cursor != null)
            Positioned(
              left: rec.cursor!.dx - 3,
              top: rec.cursor!.dy - 2,
              child: const IgnorePointer(child: CustomPaint(size: Size(30, 44), painter: _PointerPainter())),
            ),
          if (flash > 0) IgnorePointer(child: ColoredBox(color: Colors.white.withValues(alpha: flash))),
          if (intro > 0) IgnorePointer(child: ColoredBox(color: Colors.black.withValues(alpha: intro))),
          if (fade > 0) IgnorePointer(child: ColoredBox(color: Colors.black.withValues(alpha: fade))),
        ]);
      },
    );
  }
}

/// A gold kicker tag over a skewed pink slab; the slab wipes in, the words
/// pop up one by one, and the lot slides off to the left.
class _CaptionView extends StatelessWidget {
  const _CaptionView({required this.caption, required this.t});

  final Caption caption;
  final double t;

  @override
  Widget build(BuildContext context) {
    final length = caption.end - caption.start;
    double phase(double from, double over) => ((t - from) / over).clamp(0.0, 1.0);
    final slab = Curves.easeOutCubic.transform(phase(0, 0.3));
    final out = Curves.easeInCubic.transform(phase(length - 0.3, 0.3));
    final size = caption.small ? 60.0 : 92.0;
    final words = caption.headline.split(' ');

    final headline = Stack(children: [
      Positioned.fill(
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: slab,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _pink,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 30, offset: const Offset(0, 12))],
            ),
          ),
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: size * 0.32, vertical: size * 0.1),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final (i, word) in words.indexed)
            Builder(builder: (context) {
              final p = phase(0.1 + i * 0.07, 0.32);
              final rise = Curves.easeOutBack.transform(p);
              return Opacity(
                opacity: p,
                child: Transform.translate(
                  offset: Offset(0, (1 - rise) * size * 0.7),
                  child: Text(
                    i == words.length - 1 ? word : '$word ',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w900,
                      fontSize: size,
                      height: 1.08,
                      letterSpacing: -size * 0.01,
                      color: _plum,
                    ),
                  ),
                ),
              );
            }),
        ]),
      ),
    ]);

    final kicker = caption.kicker == null
        ? null
        : Opacity(
            opacity: phase(0.05, 0.25),
            child: Transform.translate(
              offset: Offset(-40 * (1 - Curves.easeOutCubic.transform(phase(0.05, 0.35))), 0),
              child: Container(
                margin: EdgeInsets.only(left: size * 0.18, bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                color: _plum.withValues(alpha: 0.92),
                child: Text(
                  caption.kicker!,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w900,
                    fontSize: caption.small ? 22 : 28,
                    letterSpacing: 5,
                    color: _gold,
                  ),
                ),
              ),
            ),
          );

    return Positioned(
      left: caption.right ? null : 190,
      right: caption.right ? 190 : null,
      top: caption.small ? 250 : 270,
      child: IgnorePointer(
        child: Opacity(
          opacity: 1 - out,
          child: Transform.translate(
            offset: Offset(-160 * out, 0),
            child: Transform(
              transform: Matrix4.skewX(-0.14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [if (kicker != null) kicker, headline],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A plain arrow pointer, for the moments the mouse isn't holding a tool.
class _PointerPainter extends CustomPainter {
  const _PointerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, 34)
      ..lineTo(8, 26)
      ..lineTo(14, 40)
      ..lineTo(20, 37)
      ..lineTo(14, 24)
      ..lineTo(25, 24)
      ..close();
    canvas.drawShadow(path, Colors.black, 4, false);
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The last shot: the key art, slowly pushing in, with the tagline and a
/// call to wishlist.
class _EndCard extends StatelessWidget {
  const _EndCard();

  @override
  Widget build(BuildContext context) {
    final rec = context.findAncestorWidgetOfExactType<_TrailerFrame>()!.rec;
    return ValueListenableBuilder(
      valueListenable: rec.clock,
      builder: (context, t, _) {
        final since = t - rec.cuts.last.$1;
        double phase(double from, double over) => ((since - from) / over).clamp(0.0, 1.0);
        final pulse = 1 + 0.035 * sin(max(0.0, since - 1.2) * 2 * pi / 1.1);
        return Stack(fit: StackFit.expand, children: [
          Transform.scale(scale: 1.08 - 0.06 * Curves.easeOut.transform(phase(0, 4.5)), child: const KeyArt(layout: ArtLayout.wide)),
          Positioned(
            left: 1920 * 0.05,
            width: 1920 * 0.45,
            top: 760,
            child: Column(children: [
              Opacity(
                opacity: phase(0.6, 0.4),
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - Curves.easeOutCubic.transform(phase(0.6, 0.5)))),
                  child: const Text(
                    _tagline,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 44,
                      color: _cream,
                      shadows: [Shadow(color: Colors.black, blurRadius: 16, offset: Offset(0, 3))],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Opacity(
                opacity: phase(1.0, 0.3),
                child: Transform.scale(
                  scale: Curves.easeOutBack.transform(phase(1.0, 0.45)) * pulse,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                    decoration: BoxDecoration(
                      color: _pink,
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [BoxShadow(color: _pink.withValues(alpha: 0.5), blurRadius: 40)],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const DonutLogo(size: 46, frosting: _cream, shadow: false),
                      const SizedBox(width: 16),
                      const Text(
                        '$_cta ON STEAM',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w900,
                          fontSize: 40,
                          letterSpacing: 2,
                          color: _plum,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ]);
      },
    );
  }
}
