import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:donut_game/steam/steam.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:steam_api/steam_api.dart';

/// Whether a release build launched outside Steam should relaunch through
/// it. Only the builds uploaded to Steam turn this on.
const bool _restartThroughSteam = bool.fromEnvironment('STEAM_RESTART');

SteamService startPlatformSteam() {
  if (!Platform.isWindows && !Platform.isMacOS) return SteamService(problem: 'No Steam on this platform');
  try {
    // A debug run isn't started by Steam, so tell Steam which game this is
    if (!kReleaseMode && Platform.isMacOS) _setEnvironment('SteamAppId', '$steamAppId');
    if (_restartThroughSteam && SteamApi.restartAppIfNecessary(steamAppId)) exit(0);
    final error = calloc<Uint8>(1024).cast<Utf8>();
    final result = SteamApi.initFlat(error);
    final message = error.toDartString();
    calloc.free(error);
    if (result != ESteamApiInitResult.ok) return SteamService(problem: '${result.name}: $message');
    Dispatch.init();
    return Steamworks._()..note('Connected as ${ISteamFriends.userInstance.getPersonaName().toDartString()}');
  } on ArgumentError catch (e) {
    // The library isn't shipped with this build
    return SteamService(problem: 'Not a Steam build (${e.message})');
  } catch (e) {
    return SteamService(problem: 'Steam failed to start: $e');
  }
}

void _setEnvironment(String name, String value) {
  final setenv = DynamicLibrary.process()
      .lookupFunction<Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Int32), int Function(Pointer<Utf8>, Pointer<Utf8>, int)>(
          'setenv');
  final n = name.toNativeUtf8(), v = value.toNativeUtf8();
  setenv(n, v, 1);
  calloc
    ..free(n)
    ..free(v);
}

/// The real thing: Valve's library, pumped for its messages a few times a
/// second (manual dispatch, so nothing runs on Steam's threads).
class Steamworks extends SteamService {
  Steamworks._() : _pipe = SteamApi.getHSteamPipe() {
    _pump = Timer.periodic(const Duration(milliseconds: 100), (_) => _runFrame());
  }

  final int _pipe;
  late final Timer _pump;

  // Room for Steam's message envelope, which is bigger on Windows (24 bytes)
  // than the bindings' (20, from the macOS layout)
  final Pointer<CallbackMsg> _message = calloc<Uint8>(64).cast<CallbackMsg>();
  final Pointer<Bool> _failed = calloc<Bool>();

  /// Handlers for Steam's broadcast callbacks, by callback id.
  final Map<int, void Function(Uint8List data)> _handlers = {};

  /// Calls waiting for their result, by call handle.
  final Map<int, (int, Completer<Uint8List?>)> _pending = {};

  @override
  bool get running => true;

  @override
  int get appId => ISteamUtils.userInstance.getAppId();

  @override
  String get personaName => ISteamFriends.userInstance.getPersonaName().toDartString();

  @override
  int get steamId => ISteamUser.userInstance.getSteamId();

  /// Calls [handler] with the bytes of every [callbackId] Steam sends.
  void on(int callbackId, void Function(Uint8List data) handler) => _handlers[callbackId] = handler;

  /// The bytes of call [handle]'s result, a [callbackId] struct; null if it
  /// failed.
  Future<Uint8List?> result(int handle, int callbackId) {
    final done = Completer<Uint8List?>();
    _pending[handle] = (callbackId, done);
    return done.future.timeout(const Duration(seconds: 20), onTimeout: () {
      _pending.remove(handle);
      note('No answer to call $handle');
      return null;
    });
  }

  void _runFrame() {
    try {
      Dispatch.runFrame(_pipe);
      while (Dispatch.getNextCallback(_pipe, _message)) {
        final id = _message.ref.callback;
        final size = _message.ref.paramSize;
        final data = Uint8List.fromList(_message.ref.paramPtr.cast<Uint8>().asTypedList(size));
        if (id == SteamApiCallCompleted.callbackId) {
          _completeCall(data);
        } else {
          _handlers[id]?.call(data);
        }
        Dispatch.freeLastCallback(_pipe);
      }
    } catch (e) {
      note('Callback error: $e');
    }
  }

  void _completeCall(Uint8List completed) {
    // SteamAPICallCompleted_t: uint64 handle, int callback, uint32 size; the
    // same on every platform
    final view = ByteData.sublistView(completed);
    final handle = view.getUint64(0, Endian.little);
    final size = view.getUint32(12, Endian.little);
    final waiting = _pending.remove(handle);
    if (waiting == null) return;
    final (callbackId, done) = waiting;
    final buffer = calloc<Uint8>(size);
    final ok = Dispatch.getApiCallResult(_pipe, handle, buffer.cast(), size, callbackId, _failed);
    done.complete(ok && !_failed.value ? Uint8List.fromList(buffer.asTypedList(size)) : null);
    calloc.free(buffer);
  }

  @override
  void shutdown() {
    _pump.cancel();
    SteamApi.shutdown();
  }
}

/// Reads Steam's structs from their bytes. Valve packs them to 8 bytes on
/// Windows and 4 elsewhere, which moves any 64-bit field that follows a
/// 32-bit one.
class SteamBytes {
  SteamBytes(Uint8List data) : _view = ByteData.sublistView(data);

  final ByteData _view;

  static final bool _packedTo8 = Platform.isWindows;

  /// Where a 64-bit field following [offset]'s 32-bit field starts.
  static int after32(int offset) => _packedTo8 ? (offset + 4 + 7) & ~7 : offset + 4;

  int int32(int offset) => _view.getInt32(offset, Endian.little);
  int uint32(int offset) => _view.getUint32(offset, Endian.little);
  int uint64(int offset) => _view.getUint64(offset, Endian.little);
  bool boolean(int offset) => _view.getUint8(offset) != 0;
}
