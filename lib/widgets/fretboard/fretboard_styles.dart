import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;

/// ─────────────────────────────────────────────────────────────────────────────
/// Global design tokens and constants
/// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  static const Color dropdownBorder = Color(0xFFBDBDBD);
  static const Color labelHighlight = Color.fromARGB(255, 255, 234, 184);
  static const Color rootOutline = Color.fromARGB(255, 255, 191, 0);
  static const Color inScaleOutline = labelHighlight;
  static const Color noteStroke = Colors.black;
  static const Color noteFill = Colors.white;
  static const Color inlayDot = Color.fromARGB(255, 35, 34, 34);
}

class AppTextStyles {
  /// Small UI labels (not the note glyphs)
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.labelHighlight,
    height: 1.0,
    letterSpacing: 0.0,
  );

  /// NOTE LETTERS (stroke + fill)
  /// Use [outlinedNoteText] below to render cleanly without ghosting.
  ///
  /// We keep these builders public so you can use them directly if needed.
  static TextStyle noteStrokeStyle({
    required double fontSize,
    FontWeight weight = FontWeight.w600,
    double strokeWidth = 2.0,
    Color color = AppColors.noteStroke,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: weight,
      height: 1.0,
      letterSpacing: 0.0,
      // Draw the outline from the glyph path
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  static TextStyle noteFillStyle({
    required double fontSize,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.noteFill,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: weight,
      height: 1.0,
      letterSpacing: 0.0,
      color: color,
    );
  }

  /// Deprecated: kept for source-compatibility; don’t use this for outlines.
  @Deprecated('Use noteStrokeStyle/noteFillStyle + outlinedNoteText.')
  static TextStyle noteFill = const TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w200,
    color: AppColors.noteFill,
  );
}

/// Convenience widget to render a note (e.g., "G#", "D#", "B") with a crisp
/// outline + fill using the SAME glyph metrics, with pixel-snapped size.
/// This eliminates the faint “shadow” you were seeing when zoomed in.
class OutlinedNoteText extends StatelessWidget {
  final String text;

  /// Pass the tile height you’re using; font size scales from it.
  final double tileHeight;

  /// Fraction of tileHeight for font size (snapped to whole px).
  final double sizeFactor;

  /// Stroke width as a fraction of font size.
  final double strokeFactor;

  final FontWeight weight;
  final Color strokeColor;
  final Color fillColor;
  final TextAlign textAlign;

  const OutlinedNoteText(
    this.text, {
    super.key,
    required this.tileHeight,
    this.sizeFactor = 0.52,
    this.strokeFactor = 0.09,
    this.weight = FontWeight.w600,
    this.strokeColor = AppColors.noteStroke,
    this.fillColor = AppColors.noteFill,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    // Snap to whole pixels to avoid subpixel blur/halos.
    final fs = (tileHeight * sizeFactor).floorToDouble();
    final sw = (fs * strokeFactor).clamp(1.5, 3.0);

    final stroke = AppTextStyles.noteStrokeStyle(
      fontSize: fs,
      weight: weight,
      strokeWidth: sw,
      color: strokeColor,
    );
    final fill = AppTextStyles.noteFillStyle(
      fontSize: fs,
      weight: weight,
      color: fillColor,
    );

    // Two Text widgets with identical metrics: one stroked, one filled.
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(text, style: stroke, textAlign: textAlign),
        Text(text, style: fill, textAlign: textAlign),
      ],
    );
  }
}

class AppBorders {
  static const BorderRadius tileRadius = BorderRadius.all(Radius.circular(6));
  static const double dropdownRadius = 12.0;
}

class AppDimensions {
  static const double tileSize = 40.0;
  static const double tileMargin = 2.0;
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Musical data
/// ─────────────────────────────────────────────────────────────────────────────
const List<String> chromatic = [
  'C', 'C#', 'D', 'D#', 'E',
  'F', 'F#', 'G', 'G#', 'A',
  'A#', 'B'
];
const List<String> openStrings = ['E', 'A', 'D', 'G', 'B', 'E'];

/// Fret length ratios (relative) - up to 20th fret only
const List<double> fretRatios = [
  0.079872, 0.075389, 0.071158, 0.067164, 0.063393,
  0.059831, 0.056466, 0.053286, 0.050280, 0.047437,
  0.044747, 0.042201, 0.039790, 0.037504, 0.035336,
  0.033277, 0.031320, 0.029457, 0.027681, 0.025986
];

/// Roman numerals for frets up to XX
const List<String> romanNumerals = [
  '0','I','II','III','IV','V','VI','VII','VIII','IX',
  'X','XI','XII','XIII','XIV','XV','XVI','XVII','XVIII','XIX','XX'
];

Color getNoteColor(String note) {
  switch (note) {
    case 'C': return Colors.orange.shade800;
    case 'D': return Colors.red.shade800;
    case 'E': return Colors.purple.shade800;
    case 'F': return Colors.blue.shade800;
    case 'G': return Colors.green.shade900; // already dark, kept same
    case 'A': return Colors.lightGreen.shade800;
    case 'B': return Colors.yellow.shade800;
    default: return Colors.grey.shade700;
  }
}

const _noteOrder = ['C','D','E','F','G','A','B'];
String nextNoteLetter(String base) {
  final idx = _noteOrder.indexOf(base.toUpperCase());
  return idx < 0 ? 'C' : _noteOrder[(idx + 1) % _noteOrder.length];
}

Color dimColor(Color color) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness * 0.5).clamp(0.0, 1.0)).toColor();
}

class AppDims {
  // Fractions of tile height
  static const double rootOutlineScale    = 0.06;   // ~6% of tile height
  static const double inScaleOutlineScale = 0.035;  // ~3.5%

  // Clamps so it never gets absurdly thick/thin
  static const double rootOutlineMin = 2.0;
  static const double rootOutlineMax = 4.5;
  static const double inScaleOutlineMin = 1.2;
  static const double inScaleOutlineMax = 3.0;

  // How much of the highlight goes to outer halo vs inner edge
  static const double haloOpacity = 0.85;
  static const double haloBlur = 0.0; // keep crisp; bump to 1–2 if you want a glow
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Misc UI helpers
/// ─────────────────────────────────────────────────────────────────────────────
class LabelTile extends StatelessWidget {
  final String label;
  final double width;
  final double height;
  final Orientation orientation;
  final int textTurns;

  const LabelTile({
    super.key,
    required this.label,
    required this.width,
    required this.height,
    required this.orientation,
    required this.textTurns,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      child: RotatedBox(
        quarterTurns: textTurns,
        child: Text(
          label,
          style: AppTextStyles.label,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class InlayDotPainter extends CustomPainter {
  final List<double> tileTotalWidths;
  final double rowHeight;
  final List<String> strings;

  const InlayDotPainter({
    required this.tileTotalWidths,
    required this.rowHeight,
    required this.strings,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.inlayDot;
    const singleFrets = [3, 5, 7, 9, 15, 17, 19, 21];
    const doubleFret = 12;
    double cumX = tileTotalWidths[0];

    for (var i = 1; i < tileTotalWidths.length; i++) {
      final w = tileTotalWidths[i];
      final centerX = (cumX + w / 2).roundToDouble(); // pixel-snap center
      final fretIndex = i - 1;  // Shift to account for extra string-number column
      final radius = (rowHeight * 0.2).clamp(4.0, 12.0);

      void drawBetween(String a, String b) {
        final ia = strings.indexOf(a);
        final ib = strings.indexOf(b);
        if (ia >= 0 && ib >= 0) {
          final centerY = (((ia + ib) / 2 + 0.5) * rowHeight).roundToDouble();
          canvas.drawCircle(Offset(centerX, centerY), radius, paint);
        }
      }

      if (singleFrets.contains(fretIndex)) {
        drawBetween('G', 'D');
      }
      if (fretIndex == doubleFret) {
        drawBetween('B', 'G');
        drawBetween('D', 'A');
      }
      cumX += w;
    }
  }

  @override
  bool shouldRepaint(covariant InlayDotPainter old) =>
      old.rowHeight != rowHeight ||
      !listEquals(old.tileTotalWidths, tileTotalWidths) ||
      !listEquals(old.strings, strings);
}

/// Diagonal gradient for sharps. (Unchanged logic; just kept tidy.)
class GradientSharpNotePainter extends CustomPainter {
  final Color baseColor;
  final Color nextColor;
  const GradientSharpNotePainter({required this.baseColor, required this.nextColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        [baseColor, nextColor],
      );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant GradientSharpNotePainter old) =>
      baseColor != old.baseColor || nextColor != old.nextColor;
}
