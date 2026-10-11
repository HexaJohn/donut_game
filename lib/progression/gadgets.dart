import 'package:donut_game/progression/profile.dart';
import 'package:donut_game/ui/widget/table_tools.dart';
import 'package:flutter/material.dart';

/// Extra marker colours unlocked by gadgets.
const List<Color> neonMarkers = [
  Color(0xFFFF2BD6),
  Color(0xFF9C27FF),
  Color(0xFFFF7A00),
  Color(0xFF00F0FF),
];

const List<Color> pastelMarkers = [
  Color(0xFFA8E6CF),
  Color(0xFFC9B6FF),
  Color(0xFFFFC3A0),
  Color(0xFFA0D8FF),
];

const Color goldMarker = Color(0xFFE6B422);

/// Every marker in [profile]'s tray: the standard five plus unlocked packs.
List<Color> markerColorsFor(PlayerProfile profile) => [
      ...markerColors,
      if (profile.owns('gadget.markers_neon')) ...neonMarkers,
      if (profile.owns('gadget.markers_pastel')) ...pastelMarkers,
      if (profile.owns('gadget.marker_gold')) goldMarker,
    ];

/// Rounds the revolver holds.
int chambersFor(PlayerProfile profile) => profile.owns('gadget.speedloader') ? 12 : 6;
