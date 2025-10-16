import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for listEquals
import 'package:music_theoretically/widgets/fretboard/fretboard_styles.dart';
import 'package:music_theoretically/state/app_settings.dart';

class NoteTile extends StatefulWidget {
  final String note;
  final double width;
  final double height;
  final String rootNote;
  final List<String> scaleNotes;
  final VoidCallback? onTap;
  final Orientation orientation;

  const NoteTile({
    Key? key,
    required this.note,
    required this.width,
    required this.height,
    required this.rootNote,
    required this.scaleNotes,
    this.onTap,
    required this.orientation,
  }) : super(key: key);

  @override
  _NoteTileState createState() => _NoteTileState();
}

class _NoteTileState extends State<NoteTile> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<Color?> _startColorAnim;
  late Animation<Color?> _endColorAnim;

  late Color _baseStart;
  late Color _baseEnd;
  late Color _brightStart;
  late Color _brightEnd;

  AppSettings? _settings; // current settings notifier we’re listening to

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _recalculateColors(); // initial (will use fallback mapping if no scope yet)
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Attach to the (possibly new) AppSettings in the tree
    final newSettings = AppSettingsScope.maybeOf(context);
    if (!identical(newSettings, _settings)) {
      _settings?.removeListener(_onSettingsChanged);
      _settings = newSettings;
      _settings?.addListener(_onSettingsChanged);
      // If we just gained settings (or they swapped), recompute colors
      _recalculateColors();
    }
  }

  @override
  void didUpdateWidget(NoteTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sameNote = oldWidget.note == widget.note;
    final sameRoot = oldWidget.rootNote == widget.rootNote;
    final sameScale = listEquals(oldWidget.scaleNotes, widget.scaleNotes);

    if (!sameNote || !sameRoot || !sameScale) {
      _recalculateColors();
      _controller.value = 1.0;
    }
  }

  void _onSettingsChanged() {
    // Global palette changed → recompute tile colors and refresh
    _recalculateColors();
    if (mounted) setState(() {}); // redraw with new colors
  }

  void _recalculateColors() {
    final note = widget.note;
    final isSharp = note.contains('#');
    final baseNat = isSharp ? note[0] : note;
    final nextNat = nextNoteLetter(baseNat);

    // Prefer global settings; fall back to the legacy fixed palette
    Color pick(String n) =>
        _settings?.colorFor(n) ?? getNoteColor(n);

    _baseStart = pick(isSharp ? baseNat : note);
    _baseEnd   = isSharp ? pick(nextNat) : _baseStart;

    // De-emphasis for out-of-scale (except root)
    if (widget.scaleNotes.length > 1 &&
        note != widget.rootNote &&
        !widget.scaleNotes.contains(note)) {
      _baseStart = dimColor(_baseStart);
      _baseEnd   = dimColor(_baseEnd);
    }

    // “Tap brighten” source colors (tween from bright -> base on tap)
    final hslStart = HSLColor.fromColor(_baseStart);
    final hslEnd   = HSLColor.fromColor(_baseEnd);
    _brightStart = hslStart.withLightness(
      (hslStart.lightness + 0.3).clamp(0.0, 1.0),
    ).toColor();
    _brightEnd = hslEnd.withLightness(
      (hslEnd.lightness + 0.3).clamp(0.0, 1.0),
    ).toColor();

    _startColorAnim = ColorTween(begin: _brightStart, end: _baseStart).animate(_controller);
    _endColorAnim   = ColorTween(begin: _brightEnd,   end: _baseEnd).animate(_controller);
  }

  void _handleTap() {
    _controller
      ..value = 0.0
      ..forward();
    widget.onTap?.call();
  }

  @override
  void dispose() {
    _settings?.removeListener(_onSettingsChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final start = _startColorAnim.value!;
          final end   = _endColorAnim.value!;
          final note = widget.note;
          final isSharp = note.contains('#');
          final isRoot = note == widget.rootNote;
          final inScale = widget.scaleNotes.contains(note);
          final doHighlight = widget.scaleNotes.length > 1;

          // Sizing heuristics
          final base = widget.height;
          final isPhone = MediaQuery.of(context).size.shortestSide < 600;
          final deviceFactor = isPhone ? 0.7 : 1.0;

          final rootTarget = base * 0.06 * deviceFactor;   // ~6%
          final inTarget  = base * 0.035 * deviceFactor;   // ~3.5%
          final ringRoot  = rootTarget.clamp(2.0, 4.5).toDouble();
          final ringIn    = inTarget.clamp(1.2, 3.0).toDouble();

          // Chosen ring thickness (fully inside the tile)
          double ringThickness = 0.0;
          Color? ringColor;
          if (doHighlight) {
            if (isRoot) {
              ringColor = AppColors.rootOutline;
              ringThickness = ringRoot;
            } else if (inScale) {
              ringColor = AppColors.inScaleOutline;
              ringThickness = ringIn;
            }
          }

          // Keep label away from the ring
          final double labelPad =
              ringThickness > 0 ? (ringThickness * 0.6).clamp(1.0, 8.0) : 0.0;

          // Height available for the glyph after padding — used to pick a crisp size
          final double contentHeight =
              (widget.height - 2 * labelPad).clamp(0.0, widget.height);

          // 0° in landscape, 270° in portrait
          final turns = widget.orientation == Orientation.portrait ? 3 : 0;

          // SOLID text (no outline). Pixel-snap the font size to avoid halos.
          final fs = (contentHeight * 0.52).floorToDouble();
          final label = RotatedBox(
            quarterTurns: turns,
            child: Text(
              widget.note,
              textAlign: TextAlign.center,
              style: AppTextStyles.noteFillStyle(
                fontSize: fs,
                weight: FontWeight.w600,
                color: AppColors.noteFill,
              ),
            ),
          );

          final BoxDecoration background = isSharp
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [start, end],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppBorders.tileRadius,
                )
              : BoxDecoration(
                  color: start,
                  borderRadius: AppBorders.tileRadius,
                );

          return ClipRRect(
            borderRadius: AppBorders.tileRadius,
            child: CustomPaint(
              foregroundPainter: (ringThickness > 0 && ringColor != null)
                  ? _InnerRingPainter(
                      color: ringColor,
                      thickness: ringThickness,
                      radius: AppBorders.tileRadius,
                    )
                  : null,
              child: Container(
                width: widget.width,
                height: widget.height,
                padding: EdgeInsets.all(labelPad),
                decoration: background,
                child: Center(child: label),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Paints an inset rounded-rectangle ring fully INSIDE the bounds.
/// This avoids any visual overlap with neighboring tiles.
class _InnerRingPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final BorderRadius radius;

  _InnerRingPainter({
    required this.color,
    required this.thickness,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (thickness <= 0) return;

    final rrect = RRect.fromRectAndCorners(
      Offset.zero & size,
      topLeft: radius.topLeft,
      topRight: radius.topRight,
      bottomLeft: radius.bottomLeft,
      bottomRight: radius.bottomRight,
    ).deflate(thickness / 2); // centers stroke within bounds

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = color
      ..isAntiAlias = true;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _InnerRingPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.thickness != thickness ||
        oldDelegate.radius != radius;
  }
}
