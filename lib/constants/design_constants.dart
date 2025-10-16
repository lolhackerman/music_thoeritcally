// File: lib/constants/design_constants.dart
// Centralized design tokens for easy theming and style updates

import 'package:flutter/material.dart';

class AppColors {
  // Dropdown border color (was Colors.grey.shade400)
  static const Color dropdownBorder = Color(0xFFBDBDBD);
  // Label and outline highlight (was Color.fromARGB(255, 255, 234, 184))
  static const Color labelHighlight = Color.fromARGB(255, 255, 234, 184);
  // Root note outline (was Color.fromARGB(255, 255, 191, 0))
  static const Color rootOutline = Color.fromARGB(255, 255, 191, 0);
  // In-scale note outline uses same as label highlight
  static const Color inScaleOutline = labelHighlight;
  // Stroke color for note text outline
  static const Color noteStroke = Colors.black;
  // Fill color for note text
  static const Color noteFill = Colors.white;
  // Inlay dot color (was Color.fromARGB(255, 35, 34, 34))
  static const Color inlayDot = Color.fromARGB(255, 35, 34, 34);
}

class AppTextStyles {
  // Text style for labels (fret numerals, dropdown items)
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.labelHighlight,
  );

  // Stroke-only text style for note outlines
  static TextStyle noteStroke({
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.normal,
    double strokeWidth = 2,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = AppColors.noteStroke,
    );
  }

  // Fill-only text style for note text
  static const TextStyle noteFill = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.noteFill,
  );
}

class AppBorders {
  // Corner radius for note tiles
  static const BorderRadius tileRadius = BorderRadius.all(Radius.circular(6));
  // Radius for dropdown containers
  static const double dropdownRadius = 12.0;
}

class AppDimensions {
  // Standard tile size for fretboard
  static const double tileSize = 40.0;
  // Margin between tiles
  static const double tileMargin = 2.0;
}


//////////////////////////////////////////////////////////////////////////////
