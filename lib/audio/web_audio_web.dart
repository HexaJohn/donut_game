import 'dart:js_interop';

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
    try {
      return _context ??= web.AudioContext();
    } catch (e) {
      return null;
    }
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
  }

  /// What the phone shows for the music in its media controls.
  void nowPlaying(String title) {
    try {
      web.window.navigator.mediaSession.metadata =
          web.MediaMetadata(web.MediaMetadataInit(title: title, artist: 'Donut', album: 'Donut'));
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
