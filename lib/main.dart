import 'package:donut_game/data/settings.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/splash/splash_screen.dart';
import 'package:donut_game/ui/widget/title_bar.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.instance.load();

  if (isDesktop) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      title: 'Donut',
      size: Size(1280, 820),
      minimumSize: Size(960, 680),
      center: true,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const DonutApp());
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
        theme: buildTheme(preset),
        home: const SplashScreen(),
      ),
    );
  }
}
