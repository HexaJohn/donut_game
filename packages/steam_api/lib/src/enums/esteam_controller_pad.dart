// ignore_for_file: public_member_api_docs, always_specify_types, avoid_positional_boolean_parameters, avoid_classes_with_only_static_members, unreachable_switch_case
import "dart:ffi";
import "../unknown_enum_value_exception.dart";

typedef ESteamControllerPadAliasDart = int;
typedef ESteamControllerPadAliasC = Int32;

enum ESteamControllerPad {
  padLeft(0),
  padRight(1),
  padBoth(2),
  gripLeft(3),
  gripRight(4),
  gripBoth(5),
  ;

  final int value;

  const ESteamControllerPad(this.value);

  factory ESteamControllerPad.fromValue(int value) {
    switch (value) {
      case 0:
        return ESteamControllerPad.padLeft;
      case 1:
        return ESteamControllerPad.padRight;
      case 2:
        return ESteamControllerPad.padBoth;
      case 3:
        return ESteamControllerPad.gripLeft;
      case 4:
        return ESteamControllerPad.gripRight;
      case 5:
        return ESteamControllerPad.gripBoth;
      default:
        throw UnknownEnumValueException(
            "Unknown value for 'ESteamControllerPad'. The value was: '$value'");
    }
  }
}
