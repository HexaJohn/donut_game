// ignore_for_file: public_member_api_docs, always_specify_types, avoid_positional_boolean_parameters, avoid_classes_with_only_static_members, unreachable_switch_case
import "dart:ffi";
import "../unknown_enum_value_exception.dart";

typedef ESteamHardwareTypeAliasDart = int;
typedef ESteamHardwareTypeAliasC = Int32;

enum ESteamHardwareType {
  none(0),
  steamDeck(1),
  steamMachine(2),
  steamFrame(3),
  ;

  final int value;

  const ESteamHardwareType(this.value);

  factory ESteamHardwareType.fromValue(int value) {
    switch (value) {
      case 0:
        return ESteamHardwareType.none;
      case 1:
        return ESteamHardwareType.steamDeck;
      case 2:
        return ESteamHardwareType.steamMachine;
      case 3:
        return ESteamHardwareType.steamFrame;
      default:
        throw UnknownEnumValueException(
            "Unknown value for 'ESteamHardwareType'. The value was: '$value'");
    }
  }
}
