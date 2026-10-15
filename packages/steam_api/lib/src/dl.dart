// ignore_for_file: public_member_api_docs
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
