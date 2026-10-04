import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:donut_game/data/remote/connectivity.dart';
import 'package:donut_game/data/settings.dart';
import 'package:donut_game/ui/home/home_screen.dart';
import 'package:donut_game/ui/splash/acro_logo.dart';
import 'package:donut_game/ui/widget/donut_logo.dart';
import 'package:donut_game/ui/widget/title_bar.dart';
import 'package:flutter/material.dart';

enum _Stage { acro, donut, leaving }

/// Startup: the Acro Visuals card, then the Donut card with a loading bar
/// while network checks run. Background follows the system light/dark mode.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  _Stage _stage = _Stage.acro;
  bool _visible = false;
  double _progress = 0;
  String _step = 'Starting up';
  NetworkStatus _network = const NetworkStatus();

  static const _fade = Duration(milliseconds: 650);

  /// The Acro "braam". It swells to its peak about 1.4 s in, which lands as
  /// the bars finish and the words come out, then rings for several seconds.
  final _sound = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _sound.dispose();
    super.dispose();
  }

  /// Sound is a nice-to-have: never let a missing codec or a browser's
  /// autoplay block hold up the splash.
  Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      // Carry on silently
    }
  }

  /// Ramps the volume down so the tail doesn't ring into the Donut splash.
  Future<void> _fadeOutSound(Duration duration) async {
    const steps = 20;
    for (var i = steps - 1; i >= 0; i--) {
      await _wait(duration.inMilliseconds ~/ steps);
      if (!mounted) return;
      await _quietly(() => _sound.setVolume(i / steps));
    }
    await _quietly(_sound.stop);
  }

  Future<void> _wait(int ms) => Future.delayed(Duration(milliseconds: ms));

  void _set(VoidCallback change) {
    if (mounted) setState(change);
  }

  Future<void> _run() async {
    // Acro Visuals: load the logo layers first so the animation starts whole
    // and the sound is ready to start on the same frame
    await Future.wait([
      precacheAcroLogo().catchError((_) {}),
      _quietly(() async {
        await _sound.setReleaseMode(ReleaseMode.stop);
        await _sound.setSource(AssetSource('sounds/acro-braam.mp3'));
        await _sound.setVolume(0.4);
      }).timeout(const Duration(seconds: 2), onTimeout: () {}),
      _wait(250),
    ]);
    _set(() => _visible = true);
    _quietly(_sound.resume);
    await _wait(acroLogoDuration.inMilliseconds + 700);
    _set(() => _visible = false);
    _fadeOutSound(const Duration(milliseconds: 1400));
    await _wait(_fade.inMilliseconds);

    // Donut + loader
    _set(() {
      _stage = _Stage.donut;
      _visible = true;
    });
    await _wait(_fade.inMilliseconds);

    final settings = Settings.instance;
    _set(() {
      _step = 'Checking network';
      _progress = 0.2;
    });
    final internet = checkInternet();
    final server = checkServer(settings.serverHost, settings.serverPort);
    final hasInternet = await internet;
    _set(() {
      _step = hasInternet == false ? 'No internet, offline play only' : 'Looking for a game server';
      _progress = 0.6;
    });
    final hasServer = await server;
    await _wait(350);
    _network = NetworkStatus(internet: hasInternet, serverReachable: hasServer);
    _set(() {
      _step = hasServer ? 'Server found at ${settings.serverHost}' : 'Ready';
      _progress = 1;
    });
    await _wait(700);

    _set(() {
      _visible = false;
      _stage = _Stage.leaving;
    });
    await _wait(_fade.inMilliseconds);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, __, ___) => HomeScreen(network: _network),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final background = dark ? Colors.black : Colors.white;
    final foreground = dark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: background,
      body: Column(
        children: [
          DonutTitleBar(transparent: true, foreground: foreground),
          Expanded(
            child: Center(
              child: AnimatedOpacity(
                opacity: _visible ? 1 : 0,
                duration: _fade,
                curve: Curves.easeInOut,
                child: _stage == _Stage.acro
                    ? (_visible
                        ? AcroLogoAnimation(
                            color: foreground,
                            width: (MediaQuery.sizeOf(context).width * 0.5).clamp(260.0, 560.0),
                          )
                        : const SizedBox())
                    : _DonutMark(color: foreground, progress: _progress, step: _step),
              ),
            ),
          ),
          const SizedBox(height: titleBarHeight),
        ],
      ),
    );
  }
}

class _DonutMark extends StatelessWidget {
  const _DonutMark({required this.color, required this.progress, required this.step});

  final Color color;
  final double progress;
  final String step;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutBack,
          builder: (context, t, child) => Transform.rotate(
            angle: (1 - t) * -0.8,
            child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
          ),
          child: const DonutLogo(size: 128),
        ),
        const SizedBox(height: 18),
        Text('Donut', style: TextStyle(color: color, fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: 28),
        SizedBox(
          width: 220,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 5,
                color: const Color(0xFFF06292),
                backgroundColor: color.withValues(alpha: 0.12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(step, key: ValueKey(step), style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 13)),
        ),
      ],
    );
  }
}
