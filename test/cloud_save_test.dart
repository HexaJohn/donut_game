import 'dart:convert';
import 'dart:typed_data';

import 'package:donut_game/steam/cloud_save.dart';
import 'package:donut_game/steam/steam.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Steam with an in-memory cloud.
class _FakeSteam extends SteamService {
  final Map<String, Uint8List> cloud = {};

  @override
  bool get running => true;

  @override
  bool get cloudEnabled => true;

  @override
  Uint8List? readCloudFile(String name) => cloud[name];

  @override
  bool writeCloudFile(String name, Uint8List data) {
    cloud[name] = data;
    return true;
  }

  Map<String, dynamic> get saved => jsonDecode(utf8.decode(cloud[CloudSave.file]!)) as Map<String, dynamic>;

  void put(int savedAt, Map<String, Object> values) =>
      cloud[CloudSave.file] = Uint8List.fromList(utf8.encode(jsonEncode({'savedAt': savedAt, 'values': values})));
}

void main() {
  late _FakeSteam steam;
  setUp(() {
    steam = _FakeSteam();
    SteamService.instance = steam;
    CloudSave.resetForTest();
  });
  tearDown(() => SteamService.instance = SteamService(problem: 'test over'));

  test('a newer cloud save replaces this computer\'s, but not its own identity', () async {
    SharedPreferences.setMockInitialValues({
      'profile': '{"xp":10}',
      'deviceId': 'this-computer',
      'cloud.savedAt': 1000,
    });
    steam.put(2000, {'profile': '{"xp":500}', 'musicVolume': 0.2, 'deviceId': 'other-computer', 'blocked': ['a', 'b']});
    await CloudSave.restore();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('profile'), '{"xp":500}');
    expect(prefs.getDouble('musicVolume'), 0.2);
    expect(prefs.getStringList('blocked'), ['a', 'b']);
    expect(prefs.getString('deviceId'), 'this-computer', reason: 'each install keeps its own seat identity');
    expect(prefs.getInt('cloud.savedAt'), 2000);
  });

  test('an older cloud save is left alone', () async {
    SharedPreferences.setMockInitialValues({'profile': '{"xp":900}', 'cloud.savedAt': 5000});
    steam.put(2000, {'profile': '{"xp":1}'});
    await CloudSave.restore();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('profile'), '{"xp":900}');
  });

  test('a new computer never uploads before checking the cloud', () async {
    SharedPreferences.setMockInitialValues({});
    steam.put(2000, {'profile': '{"xp":777}'});
    // The app leaving the foreground during start-up asks for an upload
    await CloudSave.upload();
    expect(steam.saved['values'], {'profile': '{"xp":777}'}, reason: 'the real save survived');
    await CloudSave.restore();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('profile'), '{"xp":777}');
  });

  test('changes are uploaded once, without the per-install values', () async {
    SharedPreferences.setMockInitialValues({'profile': '{"xp":3}', 'deviceSecret': 'secret', 'usagePending': '{}'});
    await CloudSave.restore();
    await CloudSave.upload();
    expect(steam.saved['values'], {'profile': '{"xp":3}'});
    final firstStamp = steam.saved['savedAt'];

    await CloudSave.upload();
    expect(steam.saved['savedAt'], firstStamp, reason: 'nothing changed, nothing sent');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile', '{"xp":4}');
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await CloudSave.upload();
    expect(steam.saved['values'], {'profile': '{"xp":4}'});
    expect(prefs.getInt('cloud.savedAt'), steam.saved['savedAt']);
  });
}
