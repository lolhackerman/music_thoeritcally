import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;

// ⬅️ Rely ONLY on AppSettings for colors
import 'package:music_theoretically/state/app_settings.dart';

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

/// Convenience widget to render a note with crisp outline + fill.
class OutlinedNoteText extends StatelessWidget {
  final String text;
  final double tileHeight;
  final double sizeFactor;
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

/// ─────────────────────────────────────────────────────────────────────────────
/// NOTE COLORS — single source of truth = AppSettings
/// ─────────────────────────────────────────────────────────────────────────────

/// Use this everywhere in UI to fetch a note's color.
/// This will assert if AppSettingsScope is not in the tree — by design,
/// since we now rely ONLY on AppSettings.
Color noteColor(BuildContext context, String note) {
  return AppSettingsScope.of(context).colorFor(note);
}

/// Helper for sharps: returns the base and next-natural colors from AppSettings.
/// Example: 'C#' → (C, D); 'F#' → (F, G); Naturals return (nat, nextNat).
AccidentalPair sharpGradientColors(BuildContext context, String note) {
  final settings = AppSettingsScope.of(context);
  final isSharp = note.contains('#') || note.contains('b'); // treat flats too
  final baseNat = isSharp ? note[0] : note;                  // e.g., C from C#
  final nextNat = nextNoteLetter(baseNat);                   // e.g., D after C
  return AccidentalPair(
    settings.colorFor(baseNat),
    settings.colorFor(nextNat),
  );
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

  // NEW: customizable color from AppSettings
  final Color dotColor;

  const InlayDotPainter({
    required this.tileTotalWidths,
    required this.rowHeight,
    required this.strings,
    required this.dotColor, // ← new required param
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor; // ← use injected color
    const singleFrets = [3, 5, 7, 9, 15, 17, 19, 21];
    const doubleFret = 12;
    double cumX = tileTotalWidths[0];

    for (var i = 1; i < tileTotalWidths.length; i++) {
      final w = tileTotalWidths[i];
      final centerX = (cumX + w / 2).roundToDouble();
      final fretIndex = i - 1;
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
      dotColor != old.dotColor || // ← repaint when color changes
      !listEquals(old.tileTotalWidths, tileTotalWidths) ||
      !listEquals(old.strings, strings);
}


/// Diagonal gradient for sharps (paint with two colors from AppSettings).
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
