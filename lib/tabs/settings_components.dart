import 'package:flutter/material.dart';

class NoteColorTile extends StatelessWidget {
  final String note;
  final Color color;
  final VoidCallback onTap;
  final double scale;

  const NoteColorTile({
    super.key,
    required this.note,
    required this.color,
    required this.onTap,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lighterThanBg = scheme.surfaceContainerHighest;

    final radius = 12.0 * scale;
    final hPad = 12.0 * scale;
    final vPad = 12.0 * scale;
    final dot = 24.0 * scale;
    final icon = 18.0 * scale;
    final fontSize = 16.0 * scale;  // Increased for consistency

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

class HighlightColorTile extends StatelessWidget {
  final String label;
  final Color color;
  final double scale;
  final VoidCallback onTap;

  const HighlightColorTile({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lighterThanBg = scheme.surfaceContainerHighest;

    final radius = 12.0 * scale;
    final hPad = 12.0 * scale;
    final vPad = 12.0 * scale;
    final dotW = 24.0 * scale;
    final icon = 18.0 * scale;
    final fontSize = 16.0 * scale;  // Using consistent font size across all buttons
    final stroke = (dotW * 0.18).clamp(2.0, 4.0);

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
                width: dotW,
                height: dotW,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(dotW * 0.28),
                  border: Border.all(color: color, width: stroke),
                ),
              ),
              SizedBox(width: 10.0 * scale),
              Expanded(
                child: Text(
                  label,
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
class ColorPickerDialog extends StatefulWidget {
  final Color initial;
  final String title;

  const ColorPickerDialog({super.key, required this.initial, required this.title});

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _selected;

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
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : const Color.fromARGB(66, 248, 0, 0),
          ),
        ),
      ),
    );
  }
}

class HintCard extends StatelessWidget {
  const HintCard({super.key});

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
        'Any widget that renders notes should read colors via AppSettingsScope. '
        'Highlight colors control the ring for root and in-scale notes.',
        style: TextStyle(fontSize: 16.0),
      ),
    );
  }
}
