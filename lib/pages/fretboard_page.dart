//THIS IS NOT BEING USED

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class FretboardWidget extends StatelessWidget {
  final String rootNote;
  final List<String> scaleNotes;

  // Configurable sizes
  static const double tileSize = 40.0;
  static const double margin = 2.0;

  const FretboardWidget({
    super.key,
    required this.rootNote,
    required this.scaleNotes,
  });

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
        : const Color.fromARGB(255, 221, 216, 216);
  }

  String nextNoteLetter(String baseNote) {
    const order = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    final idx = order.indexOf(baseNote.toUpperCase());
    return idx != -1 ? order[(idx + 1) % order.length] : 'C';
  }

  Color _dimColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.5).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        foregroundPainter: _InlayDotPainter(
          fretRatios: fretRatios,
          stringCount: openStrings.length,
          tileSize: tileSize,
          margin: margin,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: openStrings
              .map((openNote) {
                final startIdx = chromatic.indexOf(openNote);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTile(openNote, isNut: true),
                    ...List.generate(
                      fretRatios.length,
                      (i) {
                        final note = chromatic[(startIdx + i + 1) % 12];
                        return Flexible(
                          flex: (fretRatios[i] * 1000).toInt(),
                          child: _buildTile(note),
                        );
                      },
                    ),
                  ],
                );
              })
              .toList()
              .reversed
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTile(String note, {bool isNut = false}) {
    final isSharp = note.contains('#');
    final base = note[0];
    final next = nextNoteLetter(base);

    final isRoot  = note == rootNote;
    final inScale = scaleNotes.contains(note);
    final doHighlight = scaleNotes.length > 1;

    Color baseColor = getNoteColor(isSharp ? base : note);
    Color nextColor = isSharp ? getNoteColor(next) : baseColor;

    if (doHighlight && !isRoot && !inScale) {
      baseColor = _dimColor(baseColor);
      nextColor = _dimColor(nextColor);
    }

    Border? outline;
    if (doHighlight) {
      if (isRoot) {
        outline = Border.all(color: const Color.fromARGB(255, 28, 255, 7), width: 4);
      } else if (inScale) {
        outline = Border.all(color: const Color.fromARGB(255, 238, 255, 0), width: 2);
      }
    }

    final textColor = getNoteTextColor(note);

    return Container(
      width: isNut ? tileSize : null,
      height: tileSize,
      margin: const EdgeInsets.all(margin),
      decoration: BoxDecoration(
        color: isSharp ? null : baseColor,
        borderRadius: BorderRadius.circular(6),
        border: outline,
      ),
      child: isSharp
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CustomPaint(
                painter: GradientSharpNotePainter(
                  baseColor: baseColor,
                  nextColor: nextColor,
                ),
                child: Center(
                  child: Text(
                    note,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                note,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
    );
  }
}

class GradientSharpNotePainter extends CustomPainter {
  final Color baseColor;
  final Color nextColor;

  const GradientSharpNotePainter({
    required this.baseColor,
    required this.nextColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [baseColor, nextColor],
      );
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant GradientSharpNotePainter old) {
    return baseColor != old.baseColor || nextColor != old.nextColor;
  }
}

class _InlayDotPainter extends CustomPainter {
  final List<double> fretRatios;
  final int stringCount;
  final double tileSize;
  final double margin;

  const _InlayDotPainter({
    required this.fretRatios,
    required this.stringCount,
    required this.tileSize,
    required this.margin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 139, 136, 136)
      ..style = PaintingStyle.fill;

    final rowHeight = tileSize + margin * 2;
    final totalMarginWidth = (fretRatios.length + 1) * margin * 2;
    final flexWidth = size.width - tileSize - totalMarginWidth;
    final totalRatio = fretRatios.reduce((a, b) => a + b);
    final widths = fretRatios.map((r) => r / totalRatio * flexWidth).toList();

    double barX = tileSize + margin * 2;
    const singleFrets = [3, 5, 7, 9, 15, 17, 19, 21];
    const doubleFret = 12;

    for (var i = 0; i < widths.length; i++) {
      final fret = i + 1;
      final radius = (rowHeight * 0.2).clamp(4.0, 12.0);

      final singleY = rowHeight * 2.5;
      final topY = rowHeight * 1.5;
      final botY = rowHeight * 3.5;

      if (singleFrets.contains(fret)) {
        canvas.drawCircle(Offset(barX, singleY), radius, paint);
      }
      if (fret == doubleFret) {
        canvas.drawCircle(Offset(barX, topY), radius, paint);
        canvas.drawCircle(Offset(barX, botY), radius, paint);
      }

      barX += widths[i] + margin * 2;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
