import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:donut_game/audio/audio_available.dart';
import 'package:donut_game/audio/flashbang.dart';
import 'package:donut_game/data/settings.dart';
import 'package:flutter/foundation.dart';

enum MusicMode { menu, game }

/// Background music, following the music volume and mute in [Settings]:
/// the menu theme loops on the menus, and the in-game tracks play as a
/// shuffled playlist during a game. Switching crossfades between them.
class MusicPlayer {
  MusicPlayer._();
  static final MusicPlayer instance = MusicPlayer._();

  /// Files are assets/music/<name>.mp3.
  static const menuTrack = 'menu-1';
  static const gameTracks = ['Oscuridad', 'Sombra'];

  /// The game tracks are mastered ~3.5 dB hotter than the menu loop; trim
  /// them so switching doesn't jump in volume.
  static const _trackGain = {'Oscuridad': 0.66, 'Sombra': 0.66};

  /// Names shown in the sound settings.
  static const displayNames = {'menu-1': 'Menu theme'};

  // Created on first use, so merely touching [instance] never starts the plugin
  late final AudioPlayer _player = AudioPlayer(playerId: 'music');
  final ValueNotifier<String?> nowPlaying = ValueNotifier(null);
  final ValueNotifier<MusicMode?> mode = ValueNotifier(null);
  final Settings _settings = Settings.instance;

  List<String> _queue = [];
  bool _listening = false;

  /// Bumped on every switch, so a slow fade from an earlier switch can tell
  /// it has been overtaken and stop.
  int _generation = 0;

  /// 0..1 multiplier used for fades, on top of the user's volume.
  double _fade = 0;
  double _gain = 1;
  Timer? _fadeTimer;
  Completer<void>? _fadeDone;

  /// Loops the menu theme. Does nothing if it's already playing.
  Future<void> playMenu() => _switchTo(MusicMode.menu);

  /// Starts the in-game playlist. Does nothing if it's already playing.
  Future<void> playGame() => _switchTo(MusicMode.game);

  /// In a game, fades to the next track. The menu theme has nowhere to skip to.
  Future<void> skip() async {
    if (mode.value != MusicMode.game) return;
    final generation = ++_generation;
    await _fadeTo(0, const Duration(milliseconds: 600));
    if (generation == _generation) await _playNextGameTrack(generation);
  }

  Future<void> _switchTo(MusicMode target) async {
    if (!audioAvailable || mode.value == target) return;
    _listen();
    final firstStart = mode.value == null;
    mode.value = target;
    final generation = ++_generation;
    if (!firstStart) await _fadeTo(0, const Duration(milliseconds: 900));
    if (generation != _generation) return;
    if (target == MusicMode.menu) {
      await _start(menuTrack, loop: true, generation: generation);
    } else {
      await _playNextGameTrack(generation);
    }
  }

  Future<void> _playNextGameTrack(int generation) async {
    if (_queue.isEmpty) {
      // Reshuffle, but never repeat the track that just finished
      _queue = List.of(gameTracks)..shuffle(Random());
      if (_queue.length > 1 && _queue.first == nowPlaying.value) {
        _queue.add(_queue.removeAt(0));
      }
    }
    await _start(_queue.removeAt(0), loop: false, generation: generation);
  }

  Future<void> _start(String track, {required bool loop, required int generation}) async {
    nowPlaying.value = track;
    _gain = _trackGain[track] ?? 1;
    _fade = 0;
    _applyVolume();
    await _quietly(() => _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop));
    if (generation != _generation) return;
    await _quietly(() => _player.play(AssetSource('music/$track.mp3'), volume: 0));
    if (generation != _generation) return;
    await _fadeTo(1, Duration(milliseconds: loop ? 1500 : 3000));
  }

  void _listen() {
    if (_listening) return;
    _listening = true;
    _settings.musicVolume.addListener(_applyVolume);
    _settings.musicMuted.addListener(_applyVolume);
    audioDuck.addListener(_applyVolume);
    // Only the playlist finishes; the menu theme loops
    _player.onPlayerComplete.listen((_) {
      if (mode.value == MusicMode.game) _playNextGameTrack(_generation);
    });
  }

  void _applyVolume() {
    _quietly(() => _player.setVolume(_settings.effectiveMusicVolume * _gain * _fade * audioDuck.value));
  }

  Future<void> _fadeTo(double target, Duration duration) {
    // A new fade replaces any running one; let whoever awaited that carry on
    _fadeTimer?.cancel();
    if (!(_fadeDone?.isCompleted ?? true)) _fadeDone!.complete();
    final completer = _fadeDone = Completer<void>();
    const step = Duration(milliseconds: 50);
    final start = _fade;
    final steps = max(1, duration.inMilliseconds ~/ step.inMilliseconds);
    var i = 0;
    _fadeTimer = Timer.periodic(step, (timer) {
      i++;
      _fade = start + (target - start) * (i / steps);
      _applyVolume();
      if (i >= steps) {
        timer.cancel();
        completer.complete();
      }
    });
    return completer.future;
  }

  /// Music must never take the app down: missing codecs, browser autoplay
  /// rules and the like just mean silence.
  Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Music: $e');
    }
  }
}
