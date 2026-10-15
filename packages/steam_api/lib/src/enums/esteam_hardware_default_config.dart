// ignore_for_file: public_member_api_docs, always_specify_types, avoid_positional_boolean_parameters, avoid_classes_with_only_static_members, unreachable_switch_case
import "dart:ffi";
import "../unknown_enum_value_exception.dart";

typedef ESteamHardwareDefaultConfigAliasDart = int;
typedef ESteamHardwareDefaultConfigAliasC = Int32;

enum ESteamHardwareDefaultConfig {
  none(0),
  low(1),
  medium(2),
  high(3),
  max(4),
  steamDeck(5),
  steamMachine(6),
  steamFrame(7),
  ;

  final int value;

  const ESteamHardwareDefaultConfig(this.value);

  factory ESteamHardwareDefaultConfig.fromValue(int value) {
    switch (value) {
      case 0:
        return ESteamHardwareDefaultConfig.none;
      case 1:
        return ESteamHardwareDefaultConfig.low;
      case 2:
        return ESteamHardwareDefaultConfig.medium;
      case 3:
        return ESteamHardwareDefaultConfig.high;
      case 4:
        return ESteamHardwareDefaultConfig.max;
      case 5:
        return ESteamHardwareDefaultConfig.steamDeck;
      case 6:
        return ESteamHardwareDefaultConfig.steamMachine;
      case 7:
        return ESteamHardwareDefaultConfig.steamFrame;
      default:
        throw UnknownEnumValueException(
            "Unknown value for 'ESteamHardwareDefaultConfig'. The value was: '$value'");
    }
  }
}
