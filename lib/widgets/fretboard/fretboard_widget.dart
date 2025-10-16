import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:music_theoretically/widgets/fretboard/fretboard_styles.dart';
import 'package:music_theoretically/widgets/fretboard/note_audio_player.dart';
import 'package:music_theoretically/widgets/fretboard/fretboard_grid.dart';
import 'package:music_theoretically/widgets/responsive_layout.dart';

/// FretboardWidget.dart (pure: no SafeArea / notch logic)
class FretboardWidget extends StatefulWidget {
  final String rootNote;
  final List<String> scaleNotes;
  final ValueChanged<String>? onNoteTap;

  /// NEW: notifies the parent of the actual drawn content height (in logical px)
  final ValueChanged<double>? onComputedHeight;

  const FretboardWidget({
    Key? key,
    required this.rootNote,
    required this.scaleNotes,
    this.onNoteTap,
    this.onComputedHeight, // NEW
  }) : super(key: key);

  @override
  State<FretboardWidget> createState() => _FretboardWidgetState();
}

class _FretboardWidgetState extends State<FretboardWidget> {
  late final NoteAudioPlayer _notePlayer;

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    _notePlayer = NoteAudioPlayer();
  }

  @override
  void dispose() {
    _notePlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      builder: (ctx, _ignored, wF, hF) {
        final mq = MediaQuery.of(ctx);
        final isPortraitMobile = _isMobile && mq.orientation == Orientation.portrait;
        final isLandscapeMobile = _isMobile && mq.orientation == Orientation.landscape;

        // Uniform scale to preserve original aspect ratio from your design factors.
        final scale = math.min(wF, hF);

        return LayoutBuilder(
          builder: (ctx, constraints) {
            // 1) Scaled geometry
            final tileSize = AppDimensions.tileSize * scale;
            final margin = AppDimensions.tileMargin * scale;
            final rowHeight = tileSize + margin * 2;
            const bottomRows = 1; // roman/arabic label row
            final totalRows = openStrings.length + bottomRows + 1; // +1 for top labels
            final totalHeight = rowHeight * totalRows;

            // NEW: report the drawn content height to parent after this frame
            if (widget.onComputedHeight != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                widget.onComputedHeight!(totalHeight);
              });
            }

            // 2) Available span (parent handles all safe-area; we use raw constraints)
            final availableSpan = isPortraitMobile
                ? constraints.maxHeight // rotated case
                : constraints.maxWidth;

            // 3) Column widths
            final totalRatio = fretRatios.fold<double>(0, (sum, r) => sum + r);
            final totalMargin = margin * 2 * (fretRatios.length + 2);
            final stringNutWidth = tileSize; // left-most column for string labels
            final nutWidth = tileSize;       // nut column
            final flexSpan = availableSpan - totalMargin - stringNutWidth - nutWidth;

            final fretWidths = fretRatios.map((r) => flexSpan * r / totalRatio).toList();
            final widths = <double>[stringNutWidth, nutWidth, ...fretWidths];
            final tileTotalWidths = widths.map((w) => w + margin * 2).toList();

            // 4) Strings/colors/octaves (UI order high→low)
            final uiStrings = openStrings.reversed.toList();
            final borderColors = uiStrings.map(getNoteColor).toList();
            const openStringOctaves = [2, 2, 3, 3, 3, 4];
            final uiStringOctaves = openStringOctaves.reversed.toList();

            // 5) Labels
            final arabicLabels = List<String>.generate(
              widths.length,
              (i) => i == 0 ? '' : (i - 1).toString(),
            );
            final romanLabels = List<String>.generate(
              widths.length,
              (i) => i == 0 ? '' : romanNumerals[i - 1],
            );

            // 6) Core grid
            final grid = FretboardGrid(
              tileSize: tileSize,
              margin: margin,
              orientation: isPortraitMobile ? Orientation.portrait : Orientation.landscape,
              widths: widths,
              tileTotalWidths: tileTotalWidths,
              uiStrings: uiStrings,
              borderColors: borderColors,
              uiStringOctaves: uiStringOctaves,
              rootNote: widget.rootNote,
              scaleNotes: widget.scaleNotes,
              onNoteTap: (note) {
                widget.onNoteTap?.call(note);
                _notePlayer.playNote(note);
              },
              arabicLabels: arabicLabels,
              romanLabels: romanLabels,
            );

            // 7) Inlays
            Widget inlayLayer({
              required double width,
              required double height,
              required List<String> strings,
              required double top,
            }) {
              return Positioned(
                top: top,
                left: 0,
                right: 0,
                height: height,
                child: IgnorePointer(
                  child: CustomPaint(
                    size: Size(width, height),
                    painter: InlayDotPainter(
                      tileTotalWidths: tileTotalWidths,
                      rowHeight: rowHeight,
                      strings: strings,
                    ),
                  ),
                ),
              );
            }

            final interStringInlays = inlayLayer(
              width: availableSpan,
              height: rowHeight * openStrings.length,
              strings: uiStrings,
              top: rowHeight,
            );

            final bottomInlays = inlayLayer(
              width: availableSpan,
              height: rowHeight * bottomRows,
              strings: const ['I', 'II', 'III', 'IV', 'V', 'VI'],
              top: rowHeight * (openStrings.length + 1),
            );

            Widget buildUnrotated(double width) {
              return Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: width,
                  height: totalHeight,
                  child: Stack(
                    children: [grid, interStringInlays, bottomInlays],
                  ),
                ),
              );
            }

            // 8) Rotate for portrait on mobile (long axis horizontal)
            if (isPortraitMobile) {
              return Align(
                alignment: Alignment.center,
                child: RotatedBox(
                  quarterTurns: 1,
                  child: buildUnrotated(availableSpan),
                ),
              );
            }

            // 9) Landscape & desktop/web
            return Align(
              alignment: Alignment.center,
              child: buildUnrotated(constraints.maxWidth),
            );
          },
        );
      },
    );
  }
}
