import 'package:flutter/material.dart';
import 'package:music_theoretically/tabs/chords_tab/chord_diagram.dart';
import 'package:music_theoretically/tabs/chords_tab/chord_library.dart';

class ChordStrip extends StatelessWidget {
  final List<ChordVoicing> voicings;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final double itemWidth;
  final double itemHeight;
  final double spacing;

  const ChordStrip({
    super.key,
    required this.voicings,
    required this.selectedIndex,
    required this.onSelect,
    this.itemWidth = 96,
    this.itemHeight = 120,
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: voicings.length,
      separatorBuilder: (_, __) => SizedBox(width: spacing),
      itemBuilder: (context, i) {
        final v = voicings[i];
        return ChordDiagram(
          voicing: v,
          width: itemWidth,
          height: itemHeight,
          selected: i == selectedIndex,
          onTap: () => onSelect(i),
        );
      },
    );
  }
}
