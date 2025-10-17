import 'package:flutter/material.dart';
import 'package:music_theoretically/widgets/fretboard/fretboard_styles.dart' as styles;
import 'chord_formulas.dart';

class ControlsBar extends StatelessWidget {
  final List<String> chromatic;
  final String root;
  final String quality;
  final ValueChanged<String> onRootChanged;
  final ValueChanged<String> onQualityChanged;

  const ControlsBar({
    super.key,
    required this.chromatic,
    required this.root,
    required this.quality,
    required this.onRootChanged,
    required this.onQualityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    Widget dropdown<T>({
      required T value,
      required List<DropdownMenuItem<T>> items,
      required ValueChanged<T?> onChanged,
    }) {
      // No box/underline look, compact by default
      return DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isDense: true,
        ),
      );
    }

    final noteDropdown = dropdown<String>(
      value: root,
      onChanged: (v) => onRootChanged(v ?? root),
      items: chromatic
          .map((n) => DropdownMenuItem(value: n, child: Text(n)))
          .toList(),
    );

    final qualityDropdown = dropdown<String>(
      value: quality,
      onChanged: (v) => onQualityChanged(v ?? quality),
      items: chordFormulas.keys
          .map((q) => DropdownMenuItem(value: q, child: Text(q)))
          .toList(),
    );

    Widget labeled(String label, Widget child) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: textStyle),
          const SizedBox(width: 8),
          child,
        ],
      );
    }

    // Keep it small/clean; tweak spacing here without touching the tab.
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        labeled('Root', noteDropdown),
        labeled('Quality', qualityDropdown),
      ],
    );
  }
}
