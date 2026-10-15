"""Fixes steamworks_gen's output for this SDK and how the game ships Steam.

steamworks_gen (0.4.5) was made for Steam API 1.63. Three functions added
since pass enums straight through FFI, which Dart rejects; they get the
integer form the rest of the bindings use. And the library is opened from
where the game ships it rather than by bare name.

Usage: python3 patch_bindings.py <generated folder>
"""
import pathlib
import sys

root = pathlib.Path(sys.argv[1])


def patch(path, old, new):
    file = root / path
    text = file.read_text()
    if new in text:
        return
    if old not in text:
        sys.exit(f'{path}: expected code not found; the generator output changed, check by hand')
    file.write_text(text.replace(old, new, 1))


for enum, fn in [('ESteamHardwareType', 'isRunningOnSteamHardware'),
                 ('ESteamHardwareDefaultConfig', 'getSteamHardwareDefaultConfig')]:
    patch('interfaces/isteam_utils.dart',
          f'final _{fn} = dl.lookupFunction<\n    {enum} Function(\n      Pointer<ISteamUtils>,\n    ),\n    {enum} Function(',
          f'final _{fn} = dl.lookupFunction<\n    {enum}AliasC Function(\n      Pointer<ISteamUtils>,\n    ),\n    {enum}AliasDart Function(')
    patch('interfaces/isteam_utils.dart',
          f'  {enum} {fn}() =>\n      _{fn}.call(\n        this,\n      );',
          f'  {enum} {fn}() => {enum}.fromValue(\n        _{fn}.call(\n          this,\n        ),\n      );')

patch('interfaces/isteam_apps.dart',
      '      Pointer<ISteamApps>,\n      EGamePerformanceSetting,\n    ),\n    void Function(\n      Pointer<ISteamApps>,\n      EGamePerformanceSetting,\n    )>',
      '      Pointer<ISteamApps>,\n      EGamePerformanceSettingAliasC,\n    ),\n    void Function(\n      Pointer<ISteamApps>,\n      EGamePerformanceSettingAliasDart,\n    )>')
patch('interfaces/isteam_apps.dart',
      '      _setGamePerformanceSetting.call(\n        this,\n        setting,\n      );',
      '      _setGamePerformanceSetting.call(\n        this,\n        setting.value,\n      );')

(root / 'dl.dart').write_text('''// ignore_for_file: public_member_api_docs
import "dart:ffi";
import "dart:io";

/// Valve's steam_api library, shipped with the game: beside the .exe on
/// Windows, in the app's Frameworks folder on macOS. Opening it throws where
/// it isn't shipped, which is how the game knows it isn't a Steam build.
final DynamicLibrary dl = _open();

DynamicLibrary _open() {
  if (Platform.isWindows) return DynamicLibrary.open("steam_api64.dll");
  if (Platform.isMacOS) {
    // <app>/Contents/MacOS/<executable> -> <app>/Contents/Frameworks
    final contents = File(Platform.resolvedExecutable).parent.parent;
    final bundled = File("${contents.path}/Frameworks/libsteam_api.dylib");
    return DynamicLibrary.open(bundled.existsSync() ? bundled.path : "libsteam_api.dylib");
  }
  if (Platform.isLinux) return DynamicLibrary.open("libsteam_api.so");
  throw UnsupportedError("Steam isn't available on this platform");
}
''')
print('patched')
