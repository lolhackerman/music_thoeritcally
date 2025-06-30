import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class FretboardWidget extends StatelessWidget {
  const FretboardWidget({super.key});

  static const List<String> chromatic = [
    'C', 'C#', 'D', 'D#', 'E',
    'F', 'F#', 'G', 'G#', 'A',
    'A#', 'B'
  ];

  static const List<String> openStrings = ['E', 'A', 'D', 'G', 'B', 'E'];

  static const List<double> fretRatios = [
    0.079872, 0.075389, 0.071158, 0.067164, 0.063393,
    0.059831, 0.056466, 0.053286, 0.050280, 0.047437,
    0.044747, 0.042201, 0.039790, 0.037504, 0.035336,
    0.033277, 0.031320, 0.029457, 0.027681, 0.025986,
    0.024364
  ];

  Color getNoteColor(String note) {
    switch (note) {
      case 'C': return Colors.orange;
      case 'D': return Colors.red;
      case 'E': return Colors.purple;
      case 'F': return Colors.blue;
      case 'G': return Colors.green.shade900;
      case 'A': return Colors.lightGreen;
      case 'B': return Colors.yellow;
      default:  return Colors.grey.shade700;
    }
  }

  Color getNoteTextColor(String note) {
    return (note == 'A' || note == 'B' || note == 'C')
        ? Colors.black
        : Colors.white;
  }

  String nextNoteLetter(String baseNote) {
    final order = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    final idx = order.indexOf(baseNote.toUpperCase());
    return idx != -1 ? order[(idx + 1) % order.length] : 'G';
  }

  @override
  Widget build(BuildContext context) {
    // Center the fretboard on screen while preserving ratios
    return Center(
      child: Column(
        // Shrink to fit content so centering works both vertically and horizontally
        mainAxisSize: MainAxisSize.min,
        children: openStrings
            .map((openNote) {
              final startIdx = chromatic.indexOf(openNote);
              return Row(
                // Shrink row width to its content for proper centering
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Open string "nut" square
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: getNoteColor(openNote),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black26),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        openNote,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: getNoteTextColor(openNote),
                        ),
                      ),
                    ),
                  ),
                  // Frets with flexible width based on ratios
                  ...List.generate(fretRatios.length, (fret) {
                    final note = chromatic[(startIdx + fret + 1) % 12];
                    final flexValue = (fretRatios[fret] * 1000).toInt();
                    final isSharp = note.contains('#');
                    final baseNote = note[0];
                    final nextNote = nextNoteLetter(baseNote);

                    return Flexible(
                      flex: flexValue,
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.all(2),
                        child: isSharp
                            ? CustomPaint(
                                painter: GradientSharpNotePainter(
                                  baseColor: getNoteColor(baseNote),
                                  nextColor: getNoteColor(nextNote),
                                ),
                                child: Center(
                                  child: Text(
                                    note,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: getNoteColor(note),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.black26),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  note,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: getNoteTextColor(note),
                                  ),
                                ),
                              ),
                      ),
                    );
                  }),
                ],
              );
            })
            .toList()
            .reversed
            .toList(),
      ),
    );
  }
}

class GradientSharpNotePainter extends CustomPainter {
  final Color baseColor;
  final Color nextColor;

  GradientSharpNotePainter({
    required this.baseColor,
    required this.nextColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const borderRadius = 6.0;

    final shader = ui.Gradient.linear(
      rect.topLeft,
      rect.bottomRight,
      [baseColor, nextColor],
      [0.0, 1.0],
      TileMode.clamp,
    );

    final paint = Paint()..shader = shader;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    canvas.drawRRect(rrect, paint);

    final borderPaint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant GradientSharpNotePainter old) {
    return baseColor != old.baseColor || nextColor != old.nextColor;
  }
}// middle
