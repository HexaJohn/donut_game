import 'dart:convert';

import 'package:donut_engine/donut_engine.dart' show BotSkill, startingScore, startingScoreChoices;
import 'package:donut_game/res/theme/donut_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String appVersion = '2.2.0';
const int defaultPort = 27960;

/// User preferences that survive restarts.
class Settings {
  Settings._();
  static final Settings instance = Settings._();

  SharedPreferences? _prefs;

  final ValueNotifier<ThemePreset> theme = ValueNotifier(ThemePreset.donutLight);

  /// Play campaign matches in each venue's scene and on its table. Off, they
  /// use the theme's background and the player's equipped table.
  final ValueNotifier<bool> venueScenery = ValueNotifier(true);
  String nickname = '';
  String serverHost = '127.0.0.1';
  int serverPort = defaultPort;
  int bots = 3;

  /// The bots' skill and everyone's starting points, for quick games and
  /// parties this player hosts.
  BotSkill botSkill = BotSkill.regular;
  int startingPoints = startingScore;

  /// Send anonymous gameplay counts (see Usage). On unless turned off.
  final ValueNotifier<bool> shareUsage = ValueNotifier(true);

  void setShareUsage(bool on) {
    shareUsage.value = on;
    _prefs?.setBool('shareUsage', on);
  }

  /// Players this player blocked, by install id, with the name they had:
  /// their chat is hidden and matchmaking keeps them apart.
  final ValueNotifier<Map<String, String>> blocked = ValueNotifier(const {});

  void block(String id, String name) {
    blocked.value = {...blocked.value, id: name};
    _prefs?.setString('blockedPlayers', jsonEncode(blocked.value));
  }

  void unblock(String id) {
    blocked.value = Map.of(blocked.value)..remove(id);
    _prefs?.setString('blockedPlayers', jsonEncode(blocked.value));
  }

  /// Volumes run 0.0 to 1.0. Muting keeps the level for when it's unmuted.
  final ValueNotifier<double> musicVolume = ValueNotifier(0.4);
  final ValueNotifier<bool> musicMuted = ValueNotifier(false);
  final ValueNotifier<double> sfxVolume = ValueNotifier(0.8);
  final ValueNotifier<bool> sfxMuted = ValueNotifier(false);

  double get effectiveMusicVolume => musicMuted.value ? 0 : musicVolume.value;
  double get effectiveSfxVolume => sfxMuted.value ? 0 : sfxVolume.value;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      // Storage unavailable: run with defaults
      return;
    }
    final prefs = _prefs!;
    final themeName = prefs.getString('theme');
    theme.value = ThemePreset.values.firstWhere(
      (element) => element.name == themeName,
      orElse: () => ThemePreset.donutLight,
    );
    venueScenery.value = prefs.getBool('venueScenery') ?? true;
    nickname = prefs.getString('nickname') ?? '';
    _forgetRemovedModes(prefs);
    serverHost = prefs.getString('serverHost') ?? serverHost;
    serverPort = prefs.getInt('serverPort') ?? serverPort;
    bots = prefs.getInt('bots') ?? bots;
    botSkill = BotSkill.values.where((skill) => skill.name == prefs.getString('botSkill')).firstOrNull ?? botSkill;
    final points = prefs.getInt('startingPoints');
    if (startingScoreChoices.contains(points)) startingPoints = points!;
    musicVolume.value = prefs.getDouble('musicVolume') ?? musicVolume.value;
    musicMuted.value = prefs.getBool('musicMuted') ?? false;
    sfxVolume.value = prefs.getDouble('sfxVolume') ?? sfxVolume.value;
    sfxMuted.value = prefs.getBool('sfxMuted') ?? false;
    shareUsage.value = prefs.getBool('shareUsage') ?? true;
    try {
      blocked.value = Map<String, String>.from(jsonDecode(prefs.getString('blockedPlayers') ?? '{}') as Map);
    } catch (_) {}
  }

  void saveAudio() {
    _prefs
      ?..setDouble('musicVolume', musicVolume.value)
      ..setBool('musicMuted', musicMuted.value)
      ..setDouble('sfxVolume', sfxVolume.value)
      ..setBool('sfxMuted', sfxMuted.value);
  }

  void setTheme(ThemePreset preset) {
    theme.value = preset;
    _prefs?.setString('theme', preset.name);
  }

  void setVenueScenery(bool on) {
    venueScenery.value = on;
    _prefs?.setBool('venueScenery', on);
  }

  void save() {
    _prefs
      ?..setString('nickname', nickname)
      ..setString('serverHost', serverHost)
      ..setInt('serverPort', serverPort)
      ..setInt('bots', bots)
      ..setString('botSkill', botSkill.name)
      ..setInt('startingPoints', startingPoints);
  }

  /// Bad Batch, Acrotron and their downloaded decks are gone from the game;
  /// clear anything they left on this device.
  void _forgetRemovedModes(SharedPreferences prefs) {
    const keys = [
      'bbDeckCodes', 'bbBuiltinDeck', 'bbXDeck', 'bbPointsToWin', 'bbBlankCards', 'adultConfirmed', //
      'serverMode', 'ollamaUrl', 'ollamaModel', 'acrotronPersonality', 'acrotronChattiness', 'seatAcrotronOffline',
    ];
    for (final key in [...keys, ...prefs.getKeys().where((key) => key.startsWith('deck.'))]) {
      prefs.remove(key);
    }
  }
}
