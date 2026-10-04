import 'package:flutter/material.dart';

/// Fable, the AI agent seat (Claude, playing through the MCP harness).
const String fableName = 'Fable';

/// Fable's avatar: Anthropic's "A\" mark, set in type, black on cream.
/// Anthropic's trademark: fine for a private game, check Anthropic's brand
/// guidelines before shipping it anywhere public.
class FableMark extends StatelessWidget {
  const FableMark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: Color(0xFFF0EEE6), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        'A\\',
        style: TextStyle(
          color: const Color(0xFF141413),
          fontSize: size * 0.42,
          fontWeight: FontWeight.w900,
          letterSpacing: -size * 0.02,
          height: 1,
        ),
      ),
    );
  }
}
