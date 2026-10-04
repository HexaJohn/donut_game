import 'dart:math';

import 'package:donut_game/audio/music_player.dart';
import 'package:donut_game/audio/sfx.dart';
import 'package:donut_game/data/remote/connectivity.dart';
import 'package:donut_game/data/settings.dart';
import 'package:donut_game/res/resources.dart';
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:donut_game/ui/game/game_controller.dart';
import 'package:donut_game/ui/game/game_screen.dart';
import 'package:donut_game/ui/home/routes.dart';
import 'package:donut_game/modes/bad_batch/bb_controller.dart';
import 'package:donut_game/modes/bad_batch/bb_options.dart';
import 'package:donut_game/modes/bad_batch/bb_screen.dart';
import 'package:donut_game/modes/game_mode.dart';
import 'package:donut_game/ui/widget/dialogs.dart';
import 'package:donut_game/ui/widget/donut_logo.dart';
import 'package:donut_game/ui/widget/suit_icon.dart';
import 'package:donut_game/ui/widget/title_bar.dart';
import 'package:flutter/material.dart';

enum _Mode { offline, online }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.network = const NetworkStatus()});

  final NetworkStatus network;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final settings = Settings.instance;
  late final _nickname = TextEditingController(text: settings.nickname);
  late final _host = TextEditingController(text: settings.serverHost);
  late final _port = TextEditingController(text: '${settings.serverPort}');
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 24))
    ..repeat();

  late _Mode _mode = widget.network.serverReachable ? _Mode.online : _Mode.offline;
  late bool? _serverReachable = widget.network.serverReachable;
  bool _checking = false;
  bool _joining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    MusicPlayer.instance.playMenu();
    SoundEffects.instance.preload();
  }

  @override
  void dispose() {
    _nickname.dispose();
    _host.dispose();
    _port.dispose();
    _spin.dispose();
    super.dispose();
  }

  void _save() {
    settings
      ..nickname = _nickname.text.trim()
      ..serverHost = _host.text.trim()
      ..serverPort = int.tryParse(_port.text.trim()) ?? defaultPort
      ..save();
  }

  Future<void> _checkServer() async {
    _save();
    setState(() {
      _checking = true;
      _serverReachable = null;
    });
    final reachable = await checkServer(settings.serverHost, settings.serverPort);
    if (mounted) {
      setState(() {
        _checking = false;
        _serverReachable = reachable;
      });
    }
  }

  GameMode _offlineMode = GameMode.donut;

  Future<void> _playOffline() async {
    _save();
    if (_offlineMode == GameMode.badBatch) {
      if (!await confirmAdultContent(context) || !mounted) return;
      Navigator.of(context).push(gameRoute(
        BbScreen(controller: OfflineBbController(nickname: settings.nickname, bots: settings.bots)),
      ));
      return;
    }
    Navigator.of(context).push(gameRoute(
      GameScreen(controller: OfflineGameController(nickname: settings.nickname, bots: settings.bots)),
    ));
  }

  Future<void> _joinOnline() async {
    _save();
    if (settings.nickname.isEmpty) {
      setState(() => _error = 'Pick a nickname first.');
      return;
    }
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      await OnlineGameController.join(settings.serverHost, settings.serverPort, settings.nickname);
      // Open whichever game the server is running
      final mode = await fetchServerMode(settings.serverHost, settings.serverPort);
      if (!mounted) return;
      setState(() => _joining = false);
      if (mode.adult && !await confirmAdultContent(context)) return;
      if (!mounted) return;
      await Navigator.of(context).push(onlineRoute(
        mode,
        host: settings.serverHost,
        port: settings.serverPort,
        username: settings.nickname,
      ));
    } catch (e) {
      if (mounted) {
        setState(() {
          _joining = false;
          _error = '$e';
          _serverReachable = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = DonutColors.of(context);
    // The backdrop runs under the whole window; title bar and footer sit on it
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _Backdrop(colors: colors, background: theme.scaffoldBackgroundColor)),
          Column(
            children: [
              const DonutTitleBar(solid: false),
              Expanded(
                child: LayoutBuilder(builder: (context, constraints) {
                  final wide = constraints.maxWidth > 860;
                  final hero = _hero(theme, colors, wide);
                  final panel = _panel(theme, colors);
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: wide
                            ? Row(
                                children: [
                                  Expanded(child: hero),
                                  const SizedBox(width: 48),
                                  SizedBox(width: 420, child: panel),
                                ],
                              )
                            : Column(children: [hero, const SizedBox(height: 32), panel]),
                      ),
                    ),
                  );
                }),
              ),
              _footer(theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hero(ThemeData theme, DonutColors colors, bool wide) {
    final align = wide ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    return Column(
      crossAxisAlignment: align,
      children: [
        RotationTransition(
          turns: _spin,
          child: DonutLogo(size: wide ? 168 : 120, frosting: colors.accent),
        ),
        const SizedBox(height: 20),
        Text('Donut', style: theme.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.5)),
        const SizedBox(height: 8),
        Text(
          'A trick-taking card game.\nGet to zero. Avoid the donut.',
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: wide ? WrapAlignment.start : WrapAlignment.center,
          children: [
            ActionChip(
              avatar: const Icon(Icons.menu_book_rounded, size: 18),
              label: const Text('How to play'),
              onPressed: () => showRulesDialog(context),
            ),
            ActionChip(
              avatar: const Icon(Icons.palette_outlined, size: 18),
              label: Text(settings.theme.value.label),
              onPressed: () => showThemePicker(context),
            ),
            ActionChip(
              avatar: const Icon(Icons.volume_up_rounded, size: 18),
              label: const Text('Sound'),
              onPressed: () => showSoundSettings(context),
            ),
            _NetworkChip(internet: widget.network.internet),
          ],
        ),
      ],
    );
  }

  Widget _panel(ThemeData theme, DonutColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 10))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Your name', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _nickname,
              maxLength: 16,
              decoration: const InputDecoration(
                hintText: 'Nickname',
                prefixIcon: Icon(Icons.person_rounded),
                counterText: '',
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 20),
            SegmentedButton<_Mode>(
              segments: const [
                ButtonSegment(value: _Mode.offline, icon: Icon(Icons.smart_toy_rounded), label: Text('Vs bots')),
                ButtonSegment(value: _Mode.online, icon: Icon(Icons.public_rounded), label: Text('Online')),
              ],
              selected: {_mode},
              onSelectionChanged: (value) => setState(() {
                _mode = value.first;
                _error = null;
              }),
            ),
            const SizedBox(height: 20),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _mode == _Mode.offline ? _offlineOptions(theme) : _onlineOptions(theme, colors),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _offlineOptions(ThemeData theme) {
    return Column(
      key: const ValueKey('offline'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Game', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<GameMode>(
          segments: [
            for (final mode in GameMode.values)
              ButtonSegment(
                value: mode,
                label: Text(mode.adult ? '${mode.label} 18+' : mode.label),
                icon: Icon(mode == GameMode.donut ? Icons.donut_large_rounded : Icons.style_rounded),
              ),
          ],
          selected: {_offlineMode},
          onSelectionChanged: (value) => setState(() => _offlineMode = value.first),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 14),
          child: Text(_offlineMode.tagline,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
        ),
        if (_offlineMode == GameMode.badBatch) ...[
          const BadBatchOptions(),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Text('Opponents', style: theme.textTheme.labelLarge),
            const Spacer(),
            for (var i = 0; i < settings.bots; i++)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.smart_toy_rounded, size: 18, color: theme.colorScheme.primary),
              ),
          ],
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: settings.seatAcrotronOffline,
          onChanged: (value) => setState(() {
            settings
              ..seatAcrotronOffline = value
              ..saveAcrotron();
          }),
          secondary: IconButton(
            tooltip: 'Acrotron settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => showAcrotronSettings(context),
          ),
          title: const Text('Seat Acrotron'),
          subtitle: const Text('AI player on your local Ollama. Takes one bot seat.'),
        ),
        Slider(
          value: settings.bots.toDouble(),
          min: 2,
          max: 6,
          divisions: 4,
          label: '${settings.bots} bots',
          onChanged: (value) => setState(() => settings.bots = value.round()),
          onChangeEnd: (_) => _save(),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: _playOffline,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start game', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _onlineOptions(ThemeData theme, DonutColors colors) {
    final (statusText, statusColor) = switch (_serverReachable) {
      null => ('Checking...', theme.colorScheme.onSurface.withValues(alpha: 0.5)),
      true => ('Server is up', Colors.green),
      false => ('No server answering', theme.colorScheme.error),
    };
    return Column(
      key: const ValueKey('online'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Server', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _host,
                decoration: const InputDecoration(hintText: 'Address', prefixIcon: Icon(Icons.dns_rounded)),
                onSubmitted: (_) => _checkServer(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 96,
              child: TextField(
                controller: _port,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Port'),
                onSubmitted: (_) => _checkServer(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(statusText, style: theme.textTheme.bodySmall?.copyWith(color: statusColor)),
            const Spacer(),
            TextButton.icon(
              onPressed: _checking ? null : _checkServer,
              icon: _checking
                  ? const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Check'),
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: _joining ? null : _joinOnline,
          icon: _joining
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.login_rounded),
          label: Text(_joining ? 'Joining...' : 'Join game',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _footer(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Text('v$appVersion',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
          const Spacer(),
          Text('Acro Visuals',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                letterSpacing: 2,
              )),
        ],
      ),
    );
  }
}

class _NetworkChip extends StatelessWidget {
  const _NetworkChip({required this.internet});

  final bool? internet;

  @override
  Widget build(BuildContext context) {
    if (internet == null) return const SizedBox.shrink();
    return Chip(
      avatar: Icon(internet! ? Icons.wifi_rounded : Icons.wifi_off_rounded,
          size: 18, color: internet! ? Colors.green : Theme.of(context).colorScheme.error),
      label: Text(internet! ? 'Online' : 'No internet'),
    );
  }
}

/// Soft background with a few big suit symbols drifting about.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.colors, required this.background});

  final DonutColors colors;
  final Color background;

  /// Fixed scatter of suit symbols as fractions of the screen, worked out once
  /// so resizing only scales them rather than reshuffling them.
  static final List<({double x, double y, double angle, double size})> _scatter = () {
    final random = Random(3);
    return [
      for (var i = 0; i < 10; i++)
        (
          x: random.nextDouble(),
          y: random.nextDouble(),
          angle: random.nextDouble() * pi,
          size: 60 + random.nextDouble() * 80,
        ),
    ];
  }();

  @override
  Widget build(BuildContext context) {
    const suits = [Suit.spades, Suit.hearts, Suit.clubs, Suit.diamonds];
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.6, -0.2),
                  radius: 1.2,
                  colors: [Color.lerp(background, colors.accent, 0.08)!, background],
                ),
              ),
            ),
          ),
          for (var i = 0; i < _scatter.length; i++)
            Positioned(
              left: _scatter[i].x * constraints.maxWidth,
              top: _scatter[i].y * constraints.maxHeight,
              child: Transform.rotate(
                angle: _scatter[i].angle,
                child: SuitIcon(
                  suits[i % suits.length],
                  size: _scatter[i].size * 0.8,
                  color: colors.accent.withValues(alpha: 0.05),
                ),
              ),
            ),
        ],
      );
    });
  }
}
