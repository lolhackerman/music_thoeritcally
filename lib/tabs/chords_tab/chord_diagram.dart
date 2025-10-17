// ============================
// lib/widgets/chords_tab/chord_diagram.dart
// ============================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'chord_library.dart';
import 'package:music_theoretically/state/app_settings.dart'; // ⬅️ adjust path if needed

class ChordDiagram extends StatelessWidget {
  final ChordVoicing voicing;
  final double width;
  final double height;
  final bool selected;
  final VoidCallback? onTap;
  final bool showFretNumbers;

  const ChordDiagram({
    super.key,
    required this.voicing,
    this.width = 92,    // Slightly narrower to prevent touching fret number
    this.height = 108,  // Shorter now that fret number is beside
    this.selected = false,
    this.onTap,
    this.showFretNumbers = true,
  });

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context); // ⬅️ grab once here

    final shortest = math.min(width, height);
    final pad = (shortest * 0.05).clamp(2.0, 8.0);
    final radius = (shortest * 0.16).clamp(8.0, 16.0);
    final borderW = selected ? 1.6 : 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: EdgeInsets.all(pad),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            width: borderW,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
        child: CustomPaint(
          painter: _ChordDiagramPainter(
            voicing: voicing,
            showFretNumbers: showFretNumbers,
            settings: settings, // ⬅️ pass settings to painter
          ),
        ),
      ),
    );
  }
}

class _ChordDiagramPainter extends CustomPainter {
  final ChordVoicing voicing;
  final bool showFretNumbers;
  final AppSettings settings; // ⬅️ use settings inside paint

  _ChordDiagramPainter({
    required this.voicing,
    required this.showFretNumbers,
    required this.settings,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final g = _Geom(size);

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = g.gridStrokeW
      ..color = const Color(0xFF6B7280);

    // Strings (6 vertical lines)
    for (int s = 0; s < 6; s++) {
      final x = g.strX(s);
      canvas.drawLine(Offset(x, g.top), Offset(x, g.bottom), grid);
    }

    // Frets (5 horizontal lines)
    for (int f = 0; f <= 5; f++) {
      final y = g.fretY(f);
      canvas.drawLine(Offset(g.left, y), Offset(g.right, y), grid);
    }

    // Nut (thicker) when baseFret == 1
    if (voicing.baseFret == 1) {
      final nut = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = g.nutStrokeW
        ..color = Colors.white;
      canvas.drawLine(Offset(g.left, g.top), Offset(g.right, g.top), nut);
    }

    // Fret number - positioned to the right of first fret
    if (showFretNumbers && voicing.baseFret > 1) {
      final tp = TextPainter(
        text: TextSpan(
          text: '${voicing.baseFret}fr',
          style: TextStyle(
            fontSize: g.fretNumFont, 
            color: Colors.white70,
            height: 1.0,  // Tighter line height
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
      )..layout();
      // Position at the right of the diagram, vertically centered with first fret
      final textY = g.fretY(0) + ((g.fretY(1) - g.fretY(0)) / 2) - (tp.height / 2);
      tp.paint(canvas, Offset(g.right + g.fretNumPadding, textY));
    }

    // Compute pitch classes per string for color mapping
    final pcs = pitchClassesForVoicing(voicing);

    // Mutes/Open markers above the nut line
    for (final p in voicing.positions) {
      final cx = g.strX(p.stringIndex);
      final isOpen = p.fretRelative == 0 && !p.muted;
      if (p.muted) {
        final note = pcs[p.stringIndex];
        final col = _colorForNoteFromSettings(note);
        _drawX(canvas, Offset(cx, g.openY), g.markerR, col, g.markerStrokeW);
      } else if (isOpen) {
        final note = pcs[p.stringIndex];
        final col = _colorForNoteFromSettings(note);
        _drawOpenO(canvas, Offset(cx, g.openY), g.markerR, col, g.markerStrokeW);
      }
    }

    // Barres first (behind dots)
    for (final b in voicing.barres) {
      final y = g.dotCenterY(b.fretRelative);
      final x1 = g.strX(b.fromString) - g.stringSpacing * 0.30;
      final x2 = g.strX(b.toStringIndex) + g.stringSpacing * 0.30;
      final rrect = RRect.fromLTRBR(
        x1,
        y - g.dotR * 0.7,
        x2,
        y + g.dotR * 0.7,
        Radius.circular(g.barreRadius),
      );
      final col = const Color(0xFFCBD5E1);
      canvas.drawRRect(rrect, Paint()..color = col.withOpacity(0.22));
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = g.barreStrokeW
          ..color = col.withOpacity(0.9),
      );

      if (b.finger != null) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${b.finger}',
            style: TextStyle(
              fontSize: g.fingerFont,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset((x1 + x2) / 2 - tp.width / 2, y - tp.height / 2));
      }
    }

    // Fretted dots
    for (final p in voicing.positions) {
      if (p.muted || p.fretRelative <= 0) continue; // open & mute handled above
      final c = Offset(g.strX(p.stringIndex), g.dotCenterY(p.fretRelative));
      final note = pcs[p.stringIndex];
      final fill = _colorForNoteFromSettings(note);
      final textCol = _legibleTextOn(fill);
      canvas.drawCircle(c, g.dotR, Paint()..color = fill);

      if (p.finger != null) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${p.finger}',
            style: TextStyle(
              fontSize: g.dotR * 1.4,  // Larger numbers to fill the bigger dots
              color: textCol,
              fontWeight: FontWeight.w700,  // Slightly bolder for better readability
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
      }
    }
  }

  // --- Helpers that use AppSettings -----------------------------------------

  Color _colorForNoteFromSettings(String? note) {
    return colorForNoteFromSettings(settings, note);
  }

  Color _legibleTextOn(Color bg) =>
      bg.computeLuminance() > 0.5 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);

  @override
  bool shouldRepaint(covariant _ChordDiagramPainter old) {
    return old.voicing != voicing ||
        old.showFretNumbers != showFretNumbers ||
        old.settings != settings; // repaint when palette changes
  }

  void _drawX(Canvas canvas, Offset c, double r, Color color, double strokeW) {
    final p = Paint()
      ..color = color
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(c.dx - r, c.dy - r), Offset(c.dx + r, c.dy + r), p);
    canvas.drawLine(Offset(c.dx + r, c.dy - r), Offset(c.dx - r, c.dy + r), p);
  }

  void _drawOpenO(Canvas canvas, Offset c, double r, Color color, double strokeW) {
    final p = Paint()
      ..color = color
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(c, r, p);
  }
}

class _Geom {
  final Size size;
  _Geom(this.size);

  double get shortest => math.min(size.width, size.height);

  // Scaled paddings
  double get hPad => (size.width * 0.11).clamp(4.0, 12.0);  // Slightly more horizontal padding
  double get vPadTop => (size.height * 0.12).clamp(8.0, 14.0);  // Less top padding
  double get vPadBot => (size.height * 0.12).clamp(8.0, 14.0);  // Less bottom padding

  // Strokes
  double get gridStrokeW => (shortest * 0.007).clamp(0.8, 1.2);
  double get nutStrokeW  => (shortest * 0.012).clamp(1.2, 2.0);
  double get markerStrokeW => (shortest * 0.011).clamp(1.2, 2.0);  // Slightly thicker for readability
  double get barreStrokeW  => (shortest * 0.010).clamp(1.0, 1.6);

  // Marker sizes (reduced further)
  double get markerR => (shortest * 0.05).clamp(2.0, 4.5);  // Smaller markers

  // Fonts and text layout
  double get fretNumFont  => (size.height * 0.09).clamp(8.0, 11.0);
  double get fingerFont   => (size.height * 0.10).clamp(9.0, 12.0);
  double get fretNumPadding => (shortest * 0.08).clamp(6.0, 10.0);  // Increased space between diagram and fret number

  // Geometry bounds
  double get left   => hPad;
  double get right  => size.width - hPad;
  double get top    => vPadTop;
  double get bottom => size.height - vPadBot;

  double get stringSpacing => (right - left) / 5.0; // 6 strings → 5 gaps
  double get fretSpacing   => (bottom - top) / 5.0; // 5 frets

  double strX(int s) => left + s * stringSpacing;
  double fretY(int f) => top + f * fretSpacing;

  double dotCenterY(int fretRelative) => fretY(fretRelative) - fretSpacing / 2;
  // Maximum dot size that won't cause adjacent dots to touch (with small safety margin)
  double get dotR => stringSpacing * 0.45;  // 45% of string spacing (90% of gap between strings)

  double get openY => top - (markerR * 1.8);  // More spacing between markers and nut

  // Barre capsule corner radius
  double get barreRadius => (shortest * 0.12).clamp(6.0, 10.0);
}
