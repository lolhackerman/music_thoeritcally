import 'package:flutter/material.dart';
import 'package:music_theoretically/widgets/note_tile.dart';
import 'package:music_theoretically/widgets/fretboard/fretboard_styles.dart';

const _intervalNames = {
  0: 'Perfect Unison',
  1: 'Minor 2nd',
  2: 'Major 2nd',
  3: 'Minor 3rd',
  4: 'Major 3rd',
  5: 'Perfect 4th',
  6: 'Tritone',
  7: 'Perfect 5th',
  8: 'Minor 6th',
  9: 'Major 6th',
  10: 'Minor 7th',
  11: 'Major 7th',
  12: 'Octave',
};

/// If your parent rotates the WHOLE lane by +90° in portrait,
/// counter-rotate the TEXT by 3 quarter turns (-90°).
/// If your parent does NOT rotate in portrait, set this to 0.
const _kCounterPortraitQuarterTurns = 3;

class IntervalFinder extends StatelessWidget {
  final String? firstNote;   // e.g. "A4"
  final String? secondNote;  // e.g. "E5"

  const IntervalFinder({
    super.key,
    this.firstNote,
    this.secondNote,
  });

  int _toSemitone(String note) {
    final m = RegExp(r'^([A-G]#?)(\d)$').firstMatch(note);
    if (m == null) return 0;
    final pitch = m.group(1)!;
    final octave = int.parse(m.group(2)!);
    final idx = chromatic.indexOf(pitch);
    return octave * 12 + idx;
  }

  String _formatSteps(int semis) {
    final wholes = semis ~/ 2;
    final halves = semis % 2;
    return halves == 0 ? '$wholes steps' : '$wholes½ steps';
  }

  Widget _upright(Orientation deviceOrientation, Widget child) {
    final turns = deviceOrientation == Orientation.portrait
        ? _kCounterPortraitQuarterTurns
        : 0;
    return RotatedBox(quarterTurns: turns, child: child);
  }

  @override
  Widget build(BuildContext context) {
    const tile = AppDimensions.tileSize;
    const margin = AppDimensions.tileMargin;

    final semis = (firstNote != null && secondNote != null)
        ? (_toSemitone(secondNote!) - _toSemitone(firstNote!)).abs()
        : null;
    final name = semis != null ? (_intervalNames[semis] ?? '') : '';

    TextStyle getLabelStyle({required bool placeholder, bool bold = false}) =>
        TextStyle(
          fontSize: placeholder ? 12 : 14,
          color: placeholder ? Colors.grey.shade600 : null,
          fontWeight: bold
              ? FontWeight.w600
              : (placeholder ? FontWeight.w500 : FontWeight.w600),
        );

    // NOTE BOX (NoteTile when set, two-line placeholder when null)
    Widget buildNoteBox(
      String? fullNote,
      String placeholderBottomNumber, // "1" or "2"
      Orientation deviceOrientation,
    ) {
      final child = (fullNote != null)
          ? NoteTile(
              note: fullNote.replaceAll(RegExp(r'\d'), ''),
              width: tile,
              height: tile,
              rootNote: fullNote.replaceAll(RegExp(r'\d'), ''),
              scaleNotes: [fullNote.replaceAll(RegExp(r'\d'), '')],
              onTap: () {},
              orientation: deviceOrientation,
            )
          : _upright(
              deviceOrientation,
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('note',
                      textAlign: TextAlign.center,
                      style: getLabelStyle(placeholder: true)),
                  Text(placeholderBottomNumber,
                      textAlign: TextAlign.center,
                      style: getLabelStyle(placeholder: true, bold: true)),
                ],
              ),
            );

      return Container(
        width: tile,
        height: tile,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: AppBorders.tileRadius,
        ),
        child: child,
      );
    }

    // GENERIC labeled box (value or placeholder)
    Widget buildLabel(
      String text,
      double width,
      Orientation deviceOrientation, {
      required bool placeholder,
    }) {
      return Container(
        width: width,
        height: tile,
        margin: EdgeInsets.all(margin),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: AppBorders.tileRadius,
        ),
        child: _upright(
          deviceOrientation,
          Text(text,
              style: getLabelStyle(placeholder: placeholder),
              textAlign: TextAlign.center),
        ),
      );
    }

    // Fixed widths large enough for longest text
    final semisBoxWidth = tile;      // e.g., "12"
    final stepsBoxWidth = tile * 2;  // e.g., "6 steps" / "3½ steps"
    final nameBoxWidth  = tile * 4;  // e.g., "Perfect Unison"

    return OrientationBuilder(
      builder: (context, deviceOrientation) {
        final hasBoth = semis != null && name.isNotEmpty;

        final semisText = semis != null ? semis.toString() : 'semi toness';
        final stepsText = semis != null ? _formatSteps(semis) : 'steps';
        final nameText  = hasBoth ? name : 'interval';

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // safety on small screens
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildNoteBox(firstNote, '1', deviceOrientation),
                  SizedBox(width: margin),
                  buildNoteBox(secondNote, '2', deviceOrientation),
                  SizedBox(width: margin),
                  buildLabel(
                    semisText,
                    semisBoxWidth,
                    deviceOrientation,
                    placeholder: semis == null,
                  ),
                  SizedBox(width: margin),
                  buildLabel(
                    stepsText,
                    stepsBoxWidth,
                    deviceOrientation,
                    placeholder: semis == null,
                  ),
                  SizedBox(width: margin),
                  buildLabel(
                    nameText,
                    nameBoxWidth,
                    deviceOrientation,
                    placeholder: !hasBoth,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
