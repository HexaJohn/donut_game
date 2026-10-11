import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// False under `flutter test`, which has no audio backend: creating players
/// there throws MissingPluginException from inside the audio plugin.
final bool audioAvailable = kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST');

/// An audio player that doesn't track its playback position. Left on, the
/// plugin asks the platform for the position on every frame while a sound
/// plays and keeps the screen redrawing; Android's low-latency players never
/// report finishing, so for sound effects that polling never stopped and
/// piled up with every sound until the game crawled. Nothing here needs the
/// position.
AudioPlayer newAudioPlayer({String? playerId}) => AudioPlayer(playerId: playerId)..positionUpdater = null;
