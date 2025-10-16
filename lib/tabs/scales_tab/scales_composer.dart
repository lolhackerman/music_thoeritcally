import 'package:flutter/material.dart';

/// These are the children both composers can arrange.
/// You already have concrete widgets to pass in for each of these.
class ScalesChildren {
  final Widget fretboard;          // e.g., FretboardArea(...)
  final Widget selector;           // e.g., ScaleSelectorPanel(...)
  final Widget intervalFinder;     // e.g., CenteredScalableFinder(...)
  final EdgeInsets horizontalPad;  // usually EdgeInsets.symmetric(horizontal: wF * 72)
  const ScalesChildren({
    required this.fretboard,
    required this.selector,
    required this.intervalFinder,
    required this.horizontalPad,
  });
}

/// Strategy interface – returns the widget tree.
abstract class ScalesComposer {
  Widget build(BuildContext context, ScalesChildren c);
}

/// LANDSCAPE: thin wrapper around your existing overlay layout.
/// (This expects you to still compute alignTopY/alignBottomY in scales_tab.dart)
class LandscapeComposer implements ScalesComposer {
  final double alignTopY;
  final double alignBottomY;
  const LandscapeComposer({required this.alignTopY, required this.alignBottomY});

  @override
  Widget build(BuildContext context, ScalesChildren c) {
    return Stack(
      children: [
        Align(alignment: Alignment.center, child: c.fretboard),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: Align(
              alignment: Alignment(0, alignBottomY),
              child: Padding(padding: c.horizontalPad, child: c.intervalFinder),
            ),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment(0, alignTopY),
            child: Padding(
              padding: c.horizontalPad,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: c.selector,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// PORTRAIT: Left tools column (selector + interval finder stacked),
/// centered vertically; fretboard on the right expanding to fill.
/// Tweak leftWidthFraction/maxToolWidth/gap to taste.
class PortraitComposerLeftTools implements ScalesComposer {
  final double leftWidthFraction; // portion of width for tools column (0..1)
  final double maxToolWidth;      // cap for tool column width
  final double gap;               // vertical gap between selector and finder
  const PortraitComposerLeftTools({
    this.leftWidthFraction = 0.36,
    this.maxToolWidth = 420,
    this.gap = 12,
  });

  @override
  Widget build(BuildContext context, ScalesChildren c) {
    return Padding(
      padding: c.horizontalPad,
      child: LayoutBuilder(
        builder: (context, cons) {
          final leftW = (cons.maxWidth * leftWidthFraction).clamp(220.0, maxToolWidth);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // LEFT: tools column, vertically centered
              SizedBox(
                width: leftW,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: leftW),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 260),
                          child: c.selector,
                        ),
                        SizedBox(height: gap),
                        // Finder gets a sensible cap; it will size itself internally.
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: c.intervalFinder,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // RIGHT: fretboard takes the rest, centered
              Expanded(
                child: Center(
                  child: c.fretboard,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
