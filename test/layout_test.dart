import 'dart:io';
import 'dart:ui' as ui;

import 'package:donut_game/campaign/campaign.dart';
import 'package:donut_game/campaign/campaign_controller.dart';
import 'package:donut_game/data/model/game/game.dart';
import 'package:donut_game/progression/profile.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/campaign/campaign_screen.dart';
import 'package:donut_game/ui/career/career_screen.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:donut_game/ui/game/game_screen.dart';
import 'package:donut_game/ui/home/home_screen.dart';
import 'package:donut_game/ui/widget/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every main screen at phone sizes, failing on any layout overflow. Set
/// LAYOUT_SHOTS to a folder to also save a PNG of each, rendered with real
/// fonts so wrapping and overflow look as they would on a device.

const sizes = {
  'portrait': Size(360, 740),
  'landscape': Size(740, 360),
};

final String? shotsDir = Platform.environment['LAYOUT_SHOTS'];

Future<void> loadRealFonts() async {
  final root = '${Platform.environment['FLUTTER_ROOT'] ?? _flutterRoot()}/bin/cache/artifacts/material_fonts';
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      final path = '$root/$file';
      if (File(path).existsSync()) loader.addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
    }
    await loader.load();
  }

  await load('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf', 'Roboto-Black.ttf']);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
  final symbols = File('assets/fonts/seguisym.ttf');
  if (symbols.existsSync()) {
    await (FontLoader('FluentIcons')..addFont(Future.value(ByteData.sublistView(symbols.readAsBytesSync())))).load();
  }
}

/// The Flutter SDK running this test, from the Dart executable's path.
String _flutterRoot() {
  final dart = Platform.resolvedExecutable;
  final i = dart.indexOf('/bin/cache/');
  return i < 0 ? '' : dart.substring(0, i);
}

Future<void> pumpFor(WidgetTester tester, Duration total) async {
  for (var t = Duration.zero; t < total; t += const Duration(milliseconds: 100)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class Screen {
  const Screen(this.name, this.build, {this.setUp});

  final String name;
  final Widget Function() build;

  /// Taps and waits to get the screen into the state worth looking at.
  final Future<void> Function(WidgetTester tester)? setUp;
}

/// Opens a dialog over a blank screen once it's on screen.
class _DialogHost extends StatefulWidget {
  const _DialogHost(this.open);

  final Future<void> Function(BuildContext context) open;

  @override
  State<_DialogHost> createState() => _DialogHostState();
}

class _DialogHostState extends State<_DialogHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.open(context));
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}

final screens = <Screen>[
  Screen('dialog_theme', () => _DialogHost(showThemePicker)),
  Screen('dialog_sound', () => _DialogHost(showSoundSettings)),
  Screen('dialog_rules', () => _DialogHost(showRulesDialog)),
  Screen('home', () => const HomeScreen()),
  Screen('home_online', () => const HomeScreen(), setUp: (tester) async {
    await tester.tap(find.text('Online'));
    await tester.pump(const Duration(milliseconds: 600));
    // Down to the party controls
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 600));
  }),
  Screen('career_rank', () => const CareerScreen()),
  Screen('career_shop', () => const CareerScreen(initialTab: 1)),
  Screen('career_emblem', () => const CareerScreen(initialTab: 2)),
  Screen('campaign', () => const CampaignScreen()),
  Screen('game_lobby', () => GameScreen(controller: OfflineGameController(nickname: 'You', bots: 3))),
  // How a party's lobby shows its code
  Screen('game_party_lobby',
      () => GameScreen(controller: OfflineGameController(nickname: 'You', bots: 3)..party.value = 'ABC234')),
  Screen(
    'game_swap',
    () => GameScreen(controller: OfflineGameController(nickname: 'You', bots: 5)),
    setUp: (tester) async {
      await tester.tap(find.text('Deal'));
      await pumpFor(tester, const Duration(seconds: 12));
    },
  ),
  Screen(
    'game_campaign',
    () => GameScreen(controller: CampaignGameController(stage: allStages[2], difficulty: Difficulty.standard)),
    setUp: (tester) async {
      await tester.tap(find.text('Deal'));
      await pumpFor(tester, const Duration(seconds: 10));
    },
  ),
  Screen(
    'game_over',
    () => GameScreen(controller: OfflineGameController(nickname: 'You', bots: 3)),
    setUp: (tester) async {
      final game = Game();
      game.champion.value = game.players.first;
      game.state.value = GameState.gameOver;
      await pumpFor(tester, const Duration(seconds: 1));
    },
  ),
];

void main() {
  setUpAll(loadRealFonts);

  for (final MapEntry(key: orientation, value: size) in sizes.entries) {
    for (final screen in screens) {
      testWidgets('${screen.name} fits a phone in $orientation', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        PlayerProfile.instance.reset();

        final problems = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          // The message, and the widget in lib/ that caused it
          final where = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(details.toString())?.group(0);
          problems.add('${details.exceptionAsString().split('\n').first} ${where ?? ''}'.trim());
        };
        addTearDown(() => FlutterError.onError = previous);

        final key = GlobalKey();
        await tester.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTheme(ThemePreset.midnightCasino).copyWith(platform: TargetPlatform.android),
          // Around the navigator, so dialogs above the page are in the shot
          builder: (context, child) => RepaintBoundary(key: key, child: child),
          home: screen.build(),
        ));
        await tester.pump(const Duration(milliseconds: 600));
        await screen.setUp?.call(tester);
        await tester.pump(const Duration(milliseconds: 600));
        if (screen.name.startsWith('dialog_')) expect(find.byType(Dialog), findsOneWidget, reason: 'never opened');

        if (shotsDir != null) {
          await tester.runAsync(() async {
            final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            Directory(shotsDir!).createSync(recursive: true);
            File('$shotsDir/${screen.name}_$orientation.png').writeAsBytesSync(bytes!.buffer.asUint8List());
          });
        }

        // Leave, and let any game loop wind down
        await tester.pumpWidget(const SizedBox());
        await pumpFor(tester, const Duration(seconds: 3));
        FlutterError.onError = previous;
        expect(problems.toSet().toList(), isEmpty, reason: '${screen.name} at ${size.width}x${size.height}');
      });
    }
  }
}
