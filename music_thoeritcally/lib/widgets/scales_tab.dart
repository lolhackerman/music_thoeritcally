import 'package:flutter/material.dart';
import 'fretboard_widget.dart';

/// A tab that lets the user pick a root note, select a scale, and displays
/// the 12-note selector and the fretboard centered on screen.
class ScalesTab extends StatefulWidget {
  const ScalesTab({super.key});

  @override
  State<ScalesTab> createState() => _ScalesTabState();
}

class _ScalesTabState extends State<ScalesTab> {
  // Available scales and their semitone intervals
  static const List<String> scales = [
    'Major',
    'Minor',
    'Dorian',
    'Mixolydian',
    'Lydian',
    'Phrygian',
    'Locrian',
  ];

  static const Map<String, List<int>> scaleIntervals = {
    'Major': [0, 2, 4, 5, 7, 9, 11],
    'Minor': [0, 2, 3, 5, 7, 8, 10],
    'Dorian': [0, 2, 3, 5, 7, 9, 10],
    'Mixolydian': [0, 2, 4, 5, 7, 9, 10],
    'Lydian': [0, 2, 4, 6, 7, 9, 11],
    'Phrygian': [0, 1, 3, 5, 7, 8, 10],
    'Locrian': [0, 1, 3, 5, 6, 8, 10],
  };

  String selectedScale = scales.first;
  String selectedRoot = FretboardWidget.chromatic.first;

  /// The 12 chromatic notes, rotated so [selectedRoot, ...]
  List<String> get rotatedNotes {
    final all = FretboardWidget.chromatic;
    final idx = all.indexOf(selectedRoot);
    return [...all.sublist(idx), ...all.sublist(0, idx)];
  }

  /// Notes that belong to the currently selected scale
  List<String> get scaleNotes {
    final intervals = scaleIntervals[selectedScale]!;
    final rootIdx = FretboardWidget.chromatic.indexOf(selectedRoot);
    return intervals
        .map((i) =>
            FretboardWidget.chromatic[(rootIdx + i) % FretboardWidget.chromatic.length])
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row with dropdown scale selector on left and 12-note grid in center
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            children: [
              // Scale dropdown
              DropdownButton<String>(
                value: selectedScale,
                items: scales
                    .map((scale) => DropdownMenuItem(
                          value: scale,
                          child: Text(scale),
                        ))
                    .toList(),
                onChanged: (scale) {
                  if (scale != null) setState(() => selectedScale = scale);
                },
              ),
              const SizedBox(width: 16),
              // 12-note selector
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: rotatedNotes.map((note) {
                    final isRoot = note == selectedRoot;
                    final inScale = scaleNotes.contains(note);
                    return GestureDetector(
                      onTap: () => setState(() => selectedRoot = note),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: FretboardWidget(
                                        ).getNoteColor(note),
                          border: isRoot
                              ? Border.all(color: Colors.amber, width: 3)
                              : inScale
                                  ? Border.all(color: Colors.grey, width: 2)
                                  : null,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          note,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                FretboardWidget().getNoteTextColor(note),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        // Fretboard widget remains centered below
        Expanded(
          child: Center(
            child: FretboardWidget(
              // TODO: extend FretboardWidget to accept highlightedNotes & rootNote
              // to visualize scale and root on fretboard
            ),
          ),
        ),
      ],
    );
  }
}
