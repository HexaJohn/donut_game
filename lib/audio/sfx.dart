import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:donut_game/audio/audio_available.dart';
import 'package:donut_game/audio/flashbang.dart';
import 'package:donut_game/data/settings.dart';
import 'package:flutter/foundation.dart';

enum Sfx {
  /// Start of every deal.
  shuffle,

  /// A card leaving the deck, a trick being cleared, swapped cards tossed.
  slide,

  /// A card landing on the table.
  place,

  /// Someone sent a chat message.
  cough,

  /// Your move: swap cards or fold. Once per hand.
  yourMove,

  /// Your turn to play a card. Up to five times a hand, so it's the short one.
  yourTurn,

  /// Buttons and other controls being pressed.
  click,

  /// The revolver going off.
  gunshot,

  /// Picking the revolver up.
  revolverLoaded,

  /// A flashbang going off.
  flashBang,
}

/// One sound file, with the level and start trim that make it sit with the
/// others. Files are assets/sounds/<name>.mp3.
class _Clip {
  const _Clip(this.name, {this.gain = 1, this.start = Duration.zero, this.voices = 3});

  final String name;

  /// 0..1. Players can only turn sounds down, so the loudest clip of a slot is
  /// trimmed to match the quietest.
  final double gain;

  /// Skips silence at the head of the file.
  final Duration start;

  /// How many copies can overlap.
  final int voices;
}

// Gains come from measuring each file's loudness (RMS while audible):
// slide-1 0.021, slide-2 0.014, slide-3 0.061,
// placed-1 0.012, placed-2 0.062, placed-3 0.024, coughs 0.16-0.19,
// alerts ~0.045, clicks 0.028-0.083, revolver shots 0.092-0.212,
// revolver loaded 0.036.
// Start trims skip the silence before each sound begins.
const Map<Sfx, List<_Clip>> _bank = {
  Sfx.shuffle: [_Clip('card-shuffle-1', voices: 2)],
  Sfx.slide: [
    _Clip('card-slide-1', gain: 0.67, voices: 4),
    _Clip('card-slide-2', gain: 1.0, voices: 4),
    _Clip('card-slide-3', gain: 0.23, start: Duration(milliseconds: 140), voices: 4),
  ],
  Sfx.place: [
    _Clip('card-placed-1', gain: 1.0, start: Duration(milliseconds: 60), voices: 4),
    _Clip('card-placed-2', gain: 0.39, start: Duration(milliseconds: 85), voices: 4),
    _Clip('card-placed-3', gain: 1.0, start: Duration(milliseconds: 15), voices: 4),
  ],
  Sfx.cough: [
    _Clip('cough-1', gain: 0.5, voices: 2),
    _Clip('cough-2', gain: 0.45, voices: 2),
    _Clip('cough-3', gain: 0.45, voices: 2),
    _Clip('cough-4', gain: 0.42, voices: 2),
  ],
  Sfx.yourMove: [_Clip('alert-2', voices: 1)],
  Sfx.yourTurn: [_Clip('alert-1', voices: 1)],
  // Four shots, levelled to the quietest (fired-4, RMS 0.092)
  Sfx.gunshot: [
    _Clip('revolver-fired-1', gain: 0.54, voices: 2),
    _Clip('revolver-fired-2', gain: 0.43, voices: 2),
    _Clip('revolver-fired-3', gain: 0.92, voices: 2),
    _Clip('revolver-fired-4', gain: 1.0, voices: 2),
  ],
  Sfx.revolverLoaded: [_Clip('revolver-loaded-1', start: Duration(milliseconds: 180), voices: 1)],
  Sfx.flashBang: [_Clip('flash-bang', voices: 1)],
  // Five different ticks, levelled to the quietest (click-3)
  Sfx.click: [
    _Clip('click-1', gain: 0.8, voices: 2),
    _Clip('click-2', gain: 0.34, voices: 2),
    _Clip('click-3', gain: 1.0, voices: 2),
    _Clip('click-4', gain: 0.54, voices: 2),
    _Clip('click-5', gain: 0.64, voices: 2),
  ],
};

/// Plays game sound effects at the Effects volume from [Settings].
///
/// Each clip gets a few preloaded players used round-robin, so rapid sounds
/// (30 cards dealt in under two seconds) overlap instead of cutting off.
class SoundEffects {
  SoundEffects._();
  static final SoundEffects instance = SoundEffects._();

  final Map<_Clip, List<AudioPlayer>> _voices = {};
  final Map<_Clip, int> _next = {};
  final Map<Sfx, int> _last = {};
  final _random = Random();
  Future<void>? _loading;

  /// Loads every clip. Safe to call more than once.
  Future<void> preload() async {
    if (audioAvailable) await (_loading ??= _preload());
  }

  Future<void> _preload() async {
    for (final clip in _bank.values.expand((clips) => clips)) {
      final players = <AudioPlayer>[];
      for (var i = 0; i < clip.voices; i++) {
        final player = AudioPlayer();
        try {
          await player.setReleaseMode(ReleaseMode.stop);
          await player.setSource(AssetSource('sounds/${clip.name}.mp3'));
          players.add(player);
        } catch (e) {
          debugPrint('Sfx: ${clip.name}: $e');
          await player.dispose();
          break;
        }
      }
      _voices[clip] = players;
    }
  }

  /// Plays a random variation of [sfx]. [volume] scales it further, e.g. to
  /// make other players' cards quieter than your own.
  ///
  /// Everything is muffled by a flashbang ([audioDuck]) unless [ignoreDuck].
  void play(Sfx sfx, {double volume = 1, bool ignoreDuck = false}) {
    if (!audioAvailable) return;
    final level = Settings.instance.effectiveSfxVolume * volume * (ignoreDuck ? 1 : audioDuck.value);
    if (level <= 0) return;
    final clips = _bank[sfx]!;
    // Pick a different variation from last time where there's a choice
    var index = _random.nextInt(clips.length);
    if (clips.length > 1 && index == _last[sfx]) index = (index + 1) % clips.length;
    _last[sfx] = index;
    final clip = clips[index];
    final players = _voices[clip];
    if (players == null || players.isEmpty) return;
    final voice = _next[clip] ?? 0;
    _next[clip] = (voice + 1) % players.length;
    _start(players[voice], clip, level);
  }

  Future<void> _start(AudioPlayer player, _Clip clip, double level) async {
    try {
      await player.setVolume((clip.gain * level).clamp(0.0, 1.0));
      await player.seek(clip.start);
      await player.resume();
    } catch (e) {
      // A missed sound effect isn't worth interrupting the game for
    }
  }
}
