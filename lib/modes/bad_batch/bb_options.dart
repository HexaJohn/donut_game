import 'package:donut_game/data/settings.dart';
import 'package:donut_game/modes/bad_batch/bb_builtin_deck.dart';
import 'package:donut_game/modes/bad_batch/bb_cards.dart';
import 'package:donut_game/modes/bad_batch/deck_library.dart';
import 'package:flutter/material.dart';

/// Bad Batch setup: which decks to use (built-in and CrCast imports), points
/// to win and blank cards. Shared by the menu and the server window.
class BadBatchOptions extends StatefulWidget {
  const BadBatchOptions({super.key});

  @override
  State<BadBatchOptions> createState() => _BadBatchOptionsState();
}

class _BadBatchOptionsState extends State<BadBatchOptions> {
  final settings = Settings.instance;
  final library = DeckLibrary.instance;
  final _code = TextEditingController();
  bool _adding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    library.load();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    setState(() {
      _adding = true;
      _error = null;
    });
    try {
      final deck = await library.add(_code.text);
      _code.clear();
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text('Added "${deck.name}"')));
      }
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _adding = false);
  }

  String _counts(Deck deck) => '${deck.prompts.length} prompts · ${deck.responses.length} answers';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder(
      valueListenable: library.imported,
      builder: (context, Map<String, Deck> imported, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Decks', style: theme.textTheme.labelLarge),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: settings.bbBuiltinDeck,
            onChanged: (value) => setState(() {
              settings.bbBuiltinDeck = value;
              settings.saveBadBatch();
            }),
            title: Text(builtinDeck.name),
            subtitle: Text(_counts(builtinDeck)),
          ),
          for (final deck in imported.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.style_rounded),
              title: Text(deck.name),
              subtitle: Text('${_counts(deck)} · ${deck.code}'),
              trailing: IconButton(
                tooltip: 'Remove deck',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => library.remove(deck.code),
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _code,
                  decoration: const InputDecoration(
                    hintText: 'CrCast deck code or link',
                    isDense: true,
                    prefixIcon: Icon(Icons.add_link_rounded),
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _adding ? null : _add,
                child: _adding
                    ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Add'),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ),
          if (!settings.bbBuiltinDeck && imported.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Turn on the built-in deck or add one to play.',
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Points to win', style: theme.textTheme.labelLarge),
              const Spacer(),
              Text('${settings.bbPointsToWin}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          Slider(
            value: settings.bbPointsToWin.toDouble(),
            min: 3,
            max: 15,
            divisions: 12,
            label: '${settings.bbPointsToWin}',
            onChanged: (value) => setState(() => settings.bbPointsToWin = value.round()),
            onChangeEnd: (_) => settings.saveBadBatch(),
          ),
          Row(
            children: [
              Text('Blank cards', style: theme.textTheme.labelLarge),
              const Spacer(),
              Text('${settings.bbBlankCards}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          Slider(
            value: settings.bbBlankCards.toDouble(),
            min: 0,
            max: 20,
            divisions: 20,
            label: '${settings.bbBlankCards}',
            onChanged: (value) => setState(() => settings.bbBlankCards = value.round()),
            onChangeEnd: (_) => settings.saveBadBatch(),
          ),
        ],
      ),
    );
  }
}
