// ============================
// lib/widgets/chords_tab/chord_gallery.dart
// ============================

import 'package:flutter/material.dart';
import 'chord_library.dart';
import 'chord_diagram.dart';

class ChordGallery extends StatelessWidget {
  final List<ChordVoicing> voicings;
  final int selectedIndex;
  final ValueChanged<int> onSelectIndex;

  const ChordGallery({
    super.key,
    required this.voicings,
    required this.selectedIndex,
    required this.onSelectIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: voicings.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChordDiagram(
                voicing: voicings[i],
                selected: i == selectedIndex,
                onTap: () => onSelectIndex(i),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 96,
                child: Text(
                  voicings[i].label ?? 'Voicing ${i + 1}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
