import 'dart:io';
import 'dart:math';

import 'package:donut_game/audit/ai_audit.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:donut_game/audio/web_audio.dart';
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

/// One sound file, with the level that makes it sit with the others. Files
/// are assets/sounds/<name>.<ext>; each starts on its first sound, since
/// low-latency playback can't skip ahead.
class _Clip {
  const _Clip(this.name, {this.gain = 1, this.voices = 3, this.ext = 'mp3'});

  final String name;

  /// 0..1. Players can only turn sounds down, so the loudest clip of a slot is
  /// trimmed to match the quietest.
  final double gain;

  /// The few clips that had silence cut from the head are WAV, which trims to
  /// the sample; re-encoding to MP3 would pad the start again.
  final String ext;

  /// How many copies can overlap.
  final int voices;
}

// Gains come from measuring each file's loudness (RMS while audible):
// slide-1 0.021, slide-2 0.014, slide-3 0.061,
// placed-1 0.012, placed-2 0.062, placed-3 0.024, coughs 0.16-0.19,
// alerts ~0.045, clicks 0.028-0.083, revolver shots 0.092-0.212,
// revolver loaded 0.036.
// The silence before each sound began was cut from the files: card-slide-3
// 140 ms, card-placed-1 60 ms, card-placed-2 85 ms, card-placed-3 15 ms,
// revolver-loaded-1 180 ms.
const Map<Sfx, List<_Clip>> _bank = {
  Sfx.shuffle: [_Clip('card-shuffle-1', voices: 2)],
  Sfx.slide: [
    _Clip('card-slide-1', gain: 0.67, voices: 4),
    _Clip('card-slide-2', gain: 1.0, voices: 4),
    _Clip('card-slide-3', gain: 0.23, voices: 4, ext: 'wav'),
  ],
  Sfx.place: [
    _Clip('card-placed-1', gain: 1.0, voices: 4, ext: 'wav'),
    _Clip('card-placed-2', gain: 0.39, voices: 4, ext: 'wav'),
    _Clip('card-placed-3', gain: 1.0, voices: 4, ext: 'wav'),
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
  Sfx.revolverLoaded: [_Clip('revolver-loaded-1', voices: 1, ext: 'wav')],
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

  /// Android plays through SoundPool, which holds clips decoded in memory and
  /// starts them at once; the default MediaPlayer is built for music and can
  /// lag a sound by a few hundred milliseconds.
  static bool get _lowLatency => !kIsWeb && Platform.isAndroid;

  /// Effects play over the music instead of asking for audio focus, which
  /// takes time on every sound and would pause the music.
  static final AudioContext _mixed = AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build();

  /// In a browser, effects go through Web Audio (see [WebAudio]).
  static bool get _webAudio => kIsWeb && WebAudio.instance.supported;

  static String _asset(_Clip clip) => 'sounds/${clip.name}.${clip.ext}';

  Future<void> _preload() async {
    if (_webAudio) {
      await Future.wait(
          [for (final clip in _bank.values.expand((clips) => clips)) WebAudio.instance.load(_asset(clip))]);
      return;
    }
    for (final clip in _bank.values.expand((clips) => clips)) {
      final players = <AudioPlayer>[];
      for (var i = 0; i < clip.voices; i++) {
        final player = newAudioPlayer();
        try {
          if (_lowLatency) {
            await player.setPlayerMode(PlayerMode.lowLatency);
            await player.setAudioContext(_mixed);
          }
          await player.setReleaseMode(ReleaseMode.stop);
          await player.setSource(AssetSource('sounds/${clip.name}.${clip.ext}'));
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
    AiAudit.instance.sound(clip.name);
    if (_webAudio) {
      WebAudio.instance.play(_asset(clip), (clip.gain * level).clamp(0.0, 1.0));
      return;
    }
    final players = _voices[clip];
    if (players == null || players.isEmpty) return;
    final voice = _next[clip] ?? 0;
    _next[clip] = (voice + 1) % players.length;
    _start(players[voice], clip, level);
  }

  /// Stops the voice (rewinding it, and on Android letting it play again),
  /// sets its level and plays it. The calls reach the platform in order, so
  /// none waits on the last one's reply: a busy frame can't hold a sound back.
  void _start(AudioPlayer player, _Clip clip, double level) {
    // A missed sound effect isn't worth interrupting the game for
    void quietly(Future<void> call) => call.catchError((_) {});
    quietly(player.stop());
    quietly(player.setVolume((clip.gain * level).clamp(0.0, 1.0)));
    quietly(player.resume());
  }
}
