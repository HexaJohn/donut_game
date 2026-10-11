import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

/// Clips decoded once into memory, played through Web Audio.
class WebAudio {
  WebAudio._();
  static final WebAudio instance = WebAudio._();

  web.AudioContext? _context;
  final Map<String, web.AudioBuffer> _buffers = {};

  bool get supported => _contextOrNull != null;

  web.AudioContext? get _contextOrNull {
    if (_context != null) return _context;
    _beAmbient();
    try {
      return _context = web.AudioContext();
    } catch (e) {
      return null;
    }
  }

  /// Safari (16.4+) lets a page say its sound is a game's, not media:
  /// "ambient" mixes with other audio and stays out of Now Playing.
  /// Other browsers don't have this and need nothing.
  static void _beAmbient() {
    try {
      final session = (web.window.navigator as JSObject).getProperty<JSObject?>('audioSession'.toJS);
      session?.setProperty('type'.toJS, 'ambient'.toJS);
    } catch (_) {}
  }

  /// Decodes assets/[asset] (e.g. "sounds/click-1.mp3") ready to play.
  Future<void> load(String asset) async {
    final context = _contextOrNull;
    if (context == null || _buffers.containsKey(asset)) return;
    try {
      final data = await rootBundle.load('assets/$asset');
      // A copy, so the browser gets exactly this file's bytes
      final bytes = Uint8List.fromList(Uint8List.sublistView(data));
      _buffers[asset] = await context.decodeAudioData(bytes.buffer.toJS).toDart;
    } catch (e) {
      debugPrint('WebAudio: $asset: $e');
    }
  }

  /// Plays [asset] once at [level] (0..1).
  void play(String asset, double level) {
    final source = _source(asset, level);
    source?.$1.start();
  }

  /// Starts [asset] looping, silent until its level is raised.
  WebLoop? loop(String asset) {
    final source = _source(asset, 0);
    if (source == null) return null;
    source.$1
      ..loop = true
      ..start();
    return _Loop(source.$1, source.$2);
  }

  (web.AudioBufferSourceNode, web.GainNode)? _source(String asset, double level) {
    final context = _context;
    final buffer = _buffers[asset];
    if (context == null || buffer == null) return null;
    final source = context.createBufferSource()..buffer = buffer;
    final gain = context.createGain();
    gain.gain.value = level.clamp(0.0, 1.0);
    source.connect(gain);
    gain.connect(context.destination);
    return (source, gain);
  }

  /// Browsers keep audio off until the page is clicked or tapped; call this
  /// from that first press.
  void unlock() {
    final context = _contextOrNull;
    if (context != null && context.state != 'running') context.resume();
    if (!_musicPaused && _musicContext != null && _musicContext!.state != 'running') _musicContext!.resume();
  }

  // --- Music ------------------------------------------------------------------

  /// Music has its own context at a lower sample rate: a track is held fully
  /// decoded, and 24 kHz halves that (about 45 MB for four minutes) with
  /// little to hear under a card game.
  web.AudioContext? _musicContext;
  bool _musicPaused = false;

  web.AudioContext? get _music {
    if (_musicContext != null) return _musicContext;
    _beAmbient();
    try {
      return _musicContext = web.AudioContext(web.AudioContextOptions(sampleRate: 24000));
    } catch (_) {
      try {
        return _musicContext = web.AudioContext();
      } catch (_) {
        return null;
      }
    }
  }

  /// Decodes assets/[asset] and starts it silent; raise its level to hear
  /// it. [onEnded] runs when a track that doesn't [loop] finishes.
  Future<WebTrack?> track(String asset, {required bool loop, void Function()? onEnded}) async {
    final context = _music;
    if (context == null) return null;
    try {
      final data = await rootBundle.load('assets/$asset');
      final bytes = Uint8List.fromList(Uint8List.sublistView(data));
      final buffer = await context.decodeAudioData(bytes.buffer.toJS).toDart;
      final source = context.createBufferSource()
        ..buffer = buffer
        ..loop = loop;
      final gain = context.createGain()..gain.value = 0;
      source.connect(gain);
      gain.connect(context.destination);
      final track = _Track(source, gain);
      source.onended = ((web.Event _) {
        // Stopping it on purpose isn't the track finishing
        if (!track.stopped) onEnded?.call();
      }).toJS;
      source.start();
      return track;
    } catch (e) {
      debugPrint('WebAudio music: $asset: $e');
      return null;
    }
  }

  /// Silences music while the page is out of sight, keeping its place.
  void pauseMusic() {
    _musicPaused = true;
    _musicContext?.suspend();
  }

  void resumeMusic() {
    _musicPaused = false;
    _musicContext?.resume();
  }
}

/// A music track playing; its level can be changed as it plays.
abstract class WebTrack {
  set level(double value);
  void stop();
}

class _Track implements WebTrack {
  _Track(this._source, this._gain);

  final web.AudioBufferSourceNode _source;
  final web.GainNode _gain;
  bool stopped = false;

  @override
  set level(double value) => _gain.gain.value = value.clamp(0.0, 1.0);

  @override
  void stop() {
    stopped = true;
    try {
      _source.stop();
      _source.disconnect();
    } catch (_) {}
  }
}

/// A looping sound whose level can be changed while it plays.
abstract class WebLoop {
  set level(double value);
  void stop();
}

class _Loop implements WebLoop {
  _Loop(this._source, this._gain);

  final web.AudioBufferSourceNode _source;
  final web.GainNode _gain;

  @override
  set level(double value) => _gain.gain.value = value.clamp(0.0, 1.0);

  @override
  void stop() {
    try {
      _source.stop();
    } catch (_) {}
  }
}
