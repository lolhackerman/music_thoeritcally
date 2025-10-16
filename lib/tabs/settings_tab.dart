import 'package:flutter/material.dart';
import '../state/app_settings.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final naturalColors = settings.naturalColors;

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Slight size dial-down in landscape
    final scale = isLandscape ? 0.88 : 1.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      // Keep everything inside safe areas to avoid notches/gesture edges
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Note Colors (Naturals)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: settings.resetToDefaults,
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Grid of 7 naturals
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: kNaturalNotes.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // layout: 3 columns, 3-3-1 visually
                // Make each tile a bit more compact in landscape
                childAspectRatio: isLandscape ? 2.1 : 1.9,
                mainAxisSpacing: isLandscape ? 10 : 12,
                crossAxisSpacing: isLandscape ? 10 : 12,
              ),
              itemBuilder: (context, i) {
                final note = kNaturalNotes[i];
                final color = naturalColors[note]!;
                return _NoteColorTile(
                  note: note,
                  color: color,
                  onTap: () async {
                    final picked = await showDialog<Color>(
                      context: context,
                      builder: (_) => _ColorPickerDialog(
                        initial: color,
                        title: 'Pick color for $note',
                      ),
                    );
                    if (picked != null) {
                      settings.setNaturalColor(note, picked);
                    }
                  },
                  // Pass sizing + theme cues
                  scale: scale,
                );
              },
            ),
            const SizedBox(height: 24),
            const _HintCard(),
          ],
        ),
      ),
    );
  }
}

class _NoteColorTile extends StatelessWidget {
  final String note;
  final Color color;
  final VoidCallback onTap;
  final double scale;

  const _NoteColorTile({
    required this.note,
    required this.color,
    required this.onTap,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Use a surface tone that is intentionally lighter than the main surface.
    // In M3 dark themes, surfaceContainer* tones are lighter than surface.
    final lighterThanBg = scheme.surfaceContainerHighest;

    final radius = 16.0 * scale;
    final hPad = 12.0 * scale;
    final vPad = 10.0 * scale;
    final dot = 22.0 * scale;
    final icon = 18.0 * scale;
    final fontSize = 16.0 * scale;

    return Material(
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(radius),
      elevation: 1,
      color: lighterThanBg,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          child: Row(
            children: [
              Container(
                width: dot,
                height: dot,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(color: Colors.black12),
                ),
              ),
              SizedBox(width: 10.0 * scale),
              Expanded(
                child: Text(
                  note,
                  style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.edit, size: icon),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal, dependency-free color picker using a curated palette + shades.
class _ColorPickerDialog extends StatefulWidget {
  final Color initial;
  final String title;

  const _ColorPickerDialog({required this.initial, required this.title});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selected;

  // A pleasant, musical palette (material primaries + greys).
  static final List<MaterialColor> _primaries = Colors.primaries;
  static const List<Color> _neutrals = [
    Color(0xFF000000),
    Color(0xFF424242),
    Color(0xFF9E9E9E),
    Color(0xFFE0E0E0),
    Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final shadeLevels = [200, 400, 600, 800];

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Neutral row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _neutrals
                    .map((c) => _ColorSwatchDot(
                          color: c,
                          selected: _selected.value == c.value,
                          onTap: () => setState(() => _selected = c),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              // Primary grids with a few shades each
              Column(
                children: _primaries.map((mc) {
                  final dots = shadeLevels.map((lvl) {
                    final c = mc[lvl]!;
                    return _ColorSwatchDot(
                      color: c,
                      selected: _selected.value == c.value,
                      onTap: () => setState(() => _selected = c),
                    );
                  }).toList();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(spacing: 8, runSpacing: 8, children: dots),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _selected), child: const Text('Save')),
      ],
    );
  }
}

class _ColorSwatchDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatchDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: selected ? 28 : 24,
        height: selected ? 28 : 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            width: selected ? 2 : 1,
            color: selected ? Theme.of(context).colorScheme.onSurface : Colors.black26,
          ),
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: const Text(
        'Sharps/flats derive from neighboring naturals (e.g., C# uses C→D). '
        'Any widget that renders notes should read colors via AppSettingsScope.',
      ),
    );
  }
}
