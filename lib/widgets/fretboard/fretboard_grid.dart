// lib/widgets/fretboard/fretboard_grid.dart

import 'package:flutter/material.dart';
import 'package:music_theoretically/widgets/fretboard/fretboard_styles.dart';
import 'package:music_theoretically/widgets/note_tile.dart';

class FretboardGrid extends StatelessWidget {
  final double tileSize;
  final double margin;
  final Orientation orientation;
  final List<double> widths;
  final List<double> tileTotalWidths;
  final List<String> uiStrings;
  final List<Color> borderColors;
  final List<int> uiStringOctaves;
  final String rootNote;
  final List<String> scaleNotes;
  final void Function(String note)? onNoteTap;
  final List<String> arabicLabels;
  final List<String> romanLabels;

  const FretboardGrid({
    Key? key,
    required this.tileSize,
    required this.margin,
    required this.orientation,
    required this.widths,
    required this.tileTotalWidths,
    required this.uiStrings,
    required this.borderColors,
    required this.uiStringOctaves,
    required this.rootNote,
    required this.scaleNotes,
    required this.onNoteTap,
    required this.arabicLabels,
    required this.romanLabels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Arabic numerals
        Row(
          mainAxisSize: MainAxisSize.min,
          children: arabicLabels.asMap().entries.map((entry) {
            final i = entry.key;
            return Padding(
              padding: EdgeInsets.all(margin),
              child: LabelTile(
                label: entry.value,
                width: widths[i],
                height: tileSize,
                orientation: orientation,
                textTurns: orientation == Orientation.portrait ? 3 : 0,
              ),
            );
          }).toList(),
        ),

        // Fretboard rows
        ...uiStrings.asMap().entries.map((entry) {
          final rowIndex = entry.key;
          final open = entry.value;
          final openOctave = uiStringOctaves[rowIndex];
          final start = chromatic.indexOf(open);

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widths.length, (i) {
              if (i == 0 && rowIndex < uiStrings.length) {
                // Lerp factor for string gradient [0=highest string…1=lowest string]
                final t = uiStrings.length > 1
                    ? rowIndex / (uiStrings.length - 1)
                    : 0.0;
                // Silver → bronze
                final textColor = Color.lerp(
                  const Color(0xFFC0C0C0),
                  const Color(0xFF8C6239),
                  t,
                )!;
                // Light → heavy
                final fontWeight = FontWeight.lerp(
                  FontWeight.w100,
                  FontWeight.w900,
                  t,
                )!;
                // Thin → thick border
                final borderColor = borderColors[rowIndex];
                const borderWidth = 1.0;


                return Padding(
                  padding: EdgeInsets.all(margin),
                  child: Container(
                    width: widths[i],
                    height: tileSize,
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: borderWidth),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: orientation == Orientation.portrait
                          ? RotatedBox(
                              quarterTurns: 3, // 90° clockwise
                              child: Text(
                                (rowIndex + 1).toString(),
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: fontWeight,
                                  fontSize: tileSize * 0.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Text(
                              (rowIndex + 1).toString(),
                              style: TextStyle(
                                color: textColor,
                                fontWeight: fontWeight,
                                fontSize: tileSize * 0.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ),

                  ),
                );
              }


              final fretIndex = i - 1;
              final semitoneIndex = start + fretIndex;
              final noteName = chromatic[semitoneIndex % chromatic.length];
              final octaveOffset = semitoneIndex ~/ chromatic.length;
              final fullNote = '$noteName${openOctave + octaveOffset}';

              return Padding(
                padding: EdgeInsets.all(margin),
                child: NoteTile(
                  note: noteName,
                  width: widths[i],
                  height: tileSize,
                  rootNote: rootNote,
                  scaleNotes: scaleNotes,
                  orientation: orientation,
                  onTap: () => onNoteTap?.call(fullNote),
                ),
              );
            }),
          );
        }).toList(),

        // Bottom Roman numerals
        Row(
          mainAxisSize: MainAxisSize.min,
          children: romanLabels.asMap().entries.map((entry) {
            final i = entry.key;
            return Padding(
              padding: EdgeInsets.all(margin),
              child: LabelTile(
                label: entry.value,
                width: widths[i],
                height: tileSize,
                orientation: orientation,
                textTurns: orientation == Orientation.portrait ? 3 : 0,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}