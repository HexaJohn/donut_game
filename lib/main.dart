import 'dart:async';
import 'dart:io';

import 'package:donut_game/analytics/usage.dart';
import 'package:donut_game/audio/music_player.dart';
import 'package:donut_game/data/settings.dart';
import 'package:donut_game/progression/profile.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/splash/splash_screen.dart';
import 'package:donut_game/ui/widget/title_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:donut_game/net/game_center_lobby.dart';

/// Phone screens to try the layout at on desktop, in logical pixels, picked
/// with --dart-define=DEVICE=<name>. Layout only depends on logical size, so a
/// window this size lays out like the phone.
const Map<String, Size> devicePresets = {
  'galaxy_s8': Size(360, 740),
  'galaxy_s8_landscape': Size(740, 360),
};

/// The phone being simulated, if any.
const String simulatedDevice = String.fromEnvironment('DEVICE');

/// Phones and tablets, where the app runs fullscreen.
bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// Hides the system bars; a swipe from the edge brings them back for a moment.
void _goFullscreen() {
  if (isMobile) SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _goFullscreen();
  // Quiets the music in the background and puts fullscreen back on return,
  // since some phones drop it while away. It registers itself with the
  // binding, which keeps it alive.
  AppLifecycleListener(
    onStateChange: (state) {
      final away = state == AppLifecycleState.paused ||
          state == AppLifecycleState.hidden ||
          state == AppLifecycleState.detached;
      MusicPlayer.instance.setBackgrounded(away);
      if (state == AppLifecycleState.resumed) _goFullscreen();
    },
  );
  await Settings.instance.load();
  unawaited(Usage.instance.start());
  await PlayerProfile.instance.load();

  if (isDesktop) {
    await windowManager.ensureInitialized();
    final device = devicePresets[simulatedDevice];
    final options = device == null
        ? const WindowOptions(
            title: 'Donut',
            size: Size(1280, 820),
            minimumSize: Size(960, 680),
            center: true,
            titleBarStyle: TitleBarStyle.hidden,
          )
        // Pinned to the phone's size so it can't be resized away from it
        : WindowOptions(
            title: 'Donut ($simulatedDevice)',
            size: device,
            minimumSize: device,
            maximumSize: device,
            center: true,
            titleBarStyle: TitleBarStyle.hidden,
          );
    windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const DonutApp());
  GameCenterLobby.instance.signInQuietly();
}

class DonutApp extends StatelessWidget {
  const DonutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Settings.instance.theme,
      builder: (context, ThemePreset preset, _) => MaterialApp(
        title: 'Donut',
        debugShowCheckedModeBanner: false,
        // Lets a Game Center match open from anywhere, invites included
        navigatorKey: GameCenterLobby.instance.navigatorKey,
        scaffoldMessengerKey: GameCenterLobby.instance.messengerKey,
        theme: buildTheme(preset),
        // Clear of camera cutouts on phones that have them
        builder: (context, child) {
          final app = isMobile ? SafeArea(child: child!) : child!;
          if (!kIsWeb) return app;
          // The first click or tap lets the browser play sound
          return Listener(onPointerDown: (_) => MusicPlayer.instance.unlockAudio(), child: app);
        },
        home: const SplashScreen(),
      ),
    );
  }
}
