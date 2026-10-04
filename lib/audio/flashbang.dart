import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:donut_game/audio/audio_available.dart';
import 'package:donut_game/audio/sfx.dart';
import 'package:donut_game/data/settings.dart';
import 'package:flutter/foundation.dart';

/// 0..1 multiplier on all music and normal sound effects. A flashbang pulls
/// it to zero ("deafened") and lets it back up as the ringing fades.
final ValueNotifier<double> audioDuck = ValueNotifier(1);

/// The sound side of a flashbang: bang, everything else drops out, the
/// ringing swells, then the ringing fades as the game audio comes back.
class FlashbangAudio {
  FlashbangAudio._();
  static final FlashbangAudio instance = FlashbangAudio._();

  // Timeline, in seconds from the bang
  static const _duckOutEnd = 0.15;
  static const _ringStart = 0.25;
  static const _ringFullAt = 1.0;
  static const _recoverStart = 2.0;
  static const _recoverEnd = 5.0;

  late final AudioPlayer _ring = AudioPlayer(playerId: 'ringing');
  bool _loaded = false;
  Timer? _envelope;

  /// Total time until audio is back to normal.
  static const Duration length = Duration(milliseconds: 5000);

  Future<void> preload() async {
    if (!audioAvailable || _loaded) return;
    try {
      await _ring.setReleaseMode(ReleaseMode.loop);
      await _ring.setSource(AssetSource('sounds/ringing.mp3'));
      _loaded = true;
    } catch (e) {
      debugPrint('Flashbang: $e');
    }
  }

  void detonate() {
    // The bang itself cuts through: it's the last thing anyone hears clearly
    SoundEffects.instance.play(Sfx.flashBang, ignoreDuck: true);
    if (!audioAvailable) return;
    _envelope?.cancel();
    final start = DateTime.now();
    var ringing = false;
    _envelope = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      final t = DateTime.now().difference(start).inMilliseconds / 1000;

      // Game audio: out fast, back slowly
      audioDuck.value = t < _duckOutEnd
          ? 1 - t / _duckOutEnd
          : t < _recoverStart
              ? 0
              : min(1, (t - _recoverStart) / (_recoverEnd - _recoverStart));

      // Ringing: swell, hold, then fade under the returning game audio
      final ring = t < _ringStart
          ? 0.0
          : t < _ringFullAt
              ? (t - _ringStart) / (_ringFullAt - _ringStart)
              : t < _recoverStart
                  ? 1.0
                  : max(0.0, 1 - (t - _recoverStart) / (_recoverEnd - _recoverStart));
      if (t >= _ringStart && !ringing && _loaded) {
        ringing = true;
        _quietly(() async {
          await _ring.setVolume(0);
          await _ring.seek(Duration.zero);
          await _ring.resume();
        });
      }
      if (ringing) _quietly(() => _ring.setVolume(ring * Settings.instance.effectiveSfxVolume));

      if (t >= _recoverEnd) {
        timer.cancel();
        audioDuck.value = 1;
        _quietly(_ring.stop);
      }
    });
  }

  Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      // Losing the ringing is better than losing the game
    }
  }
}
