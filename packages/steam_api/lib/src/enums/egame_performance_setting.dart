// ignore_for_file: public_member_api_docs, always_specify_types, avoid_positional_boolean_parameters, avoid_classes_with_only_static_members, unreachable_switch_case
import "dart:ffi";
import "../unknown_enum_value_exception.dart";

typedef EGamePerformanceSettingAliasDart = int;
typedef EGamePerformanceSettingAliasC = Int32;

enum EGamePerformanceSetting {
  notSet(0),
  low(1),
  medium(2),
  high(3),
  ultra(4),
  custom(5),
  ;

  final int value;

  const EGamePerformanceSetting(this.value);

  factory EGamePerformanceSetting.fromValue(int value) {
    switch (value) {
      case 0:
        return EGamePerformanceSetting.notSet;
      case 1:
        return EGamePerformanceSetting.low;
      case 2:
        return EGamePerformanceSetting.medium;
      case 3:
        return EGamePerformanceSetting.high;
      case 4:
        return EGamePerformanceSetting.ultra;
      case 5:
        return EGamePerformanceSetting.custom;
      default:
        throw UnknownEnumValueException(
            "Unknown value for 'EGamePerformanceSetting'. The value was: '$value'");
    }
  }
}
