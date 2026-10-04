import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// False under `flutter test`, which has no audio backend: creating players
/// there throws MissingPluginException from inside the audio plugin.
final bool audioAvailable = kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST');
