// ignore_for_file: public_member_api_docs, always_specify_types, avoid_positional_boolean_parameters, avoid_classes_with_only_static_members
import "dart:ffi";
import "package:ffi/ffi.dart";
import "../dl.dart";
import "../typedefs.dart";

final class ISteamMatchmakingServerFriendsResponse extends Opaque {}

final _addFriendToList = dl.lookupFunction<
    Void Function(
      Pointer<ISteamMatchmakingServerFriendsResponse>,
      UnsignedLongLong,
      Pointer<Utf8>,
      Bool,
    ),
    void Function(
      Pointer<ISteamMatchmakingServerFriendsResponse>,
      CSteamId,
      Pointer<Utf8>,
      bool,
    )>("SteamAPI_ISteamMatchmakingServerFriendsResponse_AddFriendToList");

final _friendsFailedToRespond = dl.lookupFunction<
        Void Function(
          Pointer<ISteamMatchmakingServerFriendsResponse>,
        ),
        void Function(
          Pointer<ISteamMatchmakingServerFriendsResponse>,
        )>(
    "SteamAPI_ISteamMatchmakingServerFriendsResponse_FriendsFailedToRespond");

final _friendsRefreshComplete = dl.lookupFunction<
        Void Function(
          Pointer<ISteamMatchmakingServerFriendsResponse>,
        ),
        void Function(
          Pointer<ISteamMatchmakingServerFriendsResponse>,
        )>(
    "SteamAPI_ISteamMatchmakingServerFriendsResponse_FriendsRefreshComplete");

extension ISteamMatchmakingServerFriendsResponseExtensions
    on Pointer<ISteamMatchmakingServerFriendsResponse> {
  void addFriendToList(
    CSteamId steamId,
    Pointer<Utf8> name,
    bool currentlyConnected,
  ) =>
      _addFriendToList.call(
        this,
        steamId,
        name,
        currentlyConnected,
      );

  void friendsFailedToRespond() => _friendsFailedToRespond.call(
        this,
      );

  void friendsRefreshComplete() => _friendsRefreshComplete.call(
        this,
      );
}
