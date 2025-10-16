import 'package:flutter/material.dart';
import 'package:music_theoretically/widgets/responsive_layout.dart';
import 'package:music_theoretically/widgets/interval_finder.dart';
import 'package:music_theoretically/widgets/fretboard/fretboard_viewport.dart' as fbv;
import 'package:music_theoretically/widgets/fretboard/fretboard_widget.dart' as fbw;

class HomeTab extends StatefulWidget {
  /// Optional: GlobalKey of the bottom nav/TabBar so we can measure its true height.
  final GlobalKey? bottomBarKey;

  const HomeTab({super.key, this.bottomBarKey});

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // Keys to compute geometry safely
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _boardKey = GlobalKey();

  // Notes live in notifiers to avoid setState on taps.
  final ValueNotifier<String?> _note1VN = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _note2VN = ValueNotifier<String?>(null);

  void _handleNoteTap(String fullNote) {
    final a = _note1VN.value;
    final b = _note2VN.value;
    if (a == null || b != null) {
      _note1VN.value = fullNote;
      _note2VN.value = null;
    } else {
      _note2VN.value = fullNote;
    }
  }

  @override
  void dispose() {
    _note1VN.dispose();
    _note2VN.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      builder: (ctx, orientation, wF, hF) {
        // Side padding for the finder (72 @ 1440 base)
        const baseHorizontalPadding = 72.0;
        final horizontalPadding = wF * baseHorizontalPadding;

        // Build the fretboard (measured by _boardKey)
        final board = fbw.FretboardWidget(
          key: _boardKey,
          rootNote: 'C',
          scaleNotes: const [],
          onNoteTap: _handleNoteTap, // <- no setState here
        );

        // --- Measurements (stack, board bottom, bottom bar height) ---
        final stackCtx = _stackKey.currentContext;
        final boardCtx = _boardKey.currentContext;

        final stackBox = stackCtx?.findRenderObject() as RenderBox?;
        final boardBox = boardCtx?.findRenderObject() as RenderBox?;
        final bottomBarBox =
            widget.bottomBarKey?.currentContext?.findRenderObject() as RenderBox?;

        final Size screenSize = MediaQuery.sizeOf(ctx);
        final EdgeInsets viewPad = MediaQuery.of(ctx).viewPadding;
        final double stackH = stackBox?.size.height ?? screenSize.height;

        // Fallback for first frame before layout is ready
        Offset boardTopLeftInStack = Offset.zero;
        if (boardBox != null && stackBox != null) {
          boardTopLeftInStack =
              boardBox.localToGlobal(Offset.zero, ancestor: stackBox);
        }
        final double boardBottomY = (boardBox != null)
            ? boardTopLeftInStack.dy + boardBox.size.height
            : stackH * 0.60; // guess on first frame

        final double measuredBarH =
            bottomBarBox?.size.height ?? kTextTabBarHeight;

        // If measured, no fudge; if not, add a tiny cushion for safety.
        final double bottomPad = (bottomBarBox != null)
            ? (measuredBarH + viewPad.bottom)
            : (measuredBarH + viewPad.bottom + 8.0);

        final double tabBarTopY = stackH - bottomPad;

        // Midpoint between fretboard bottom and tab bar top:
        final double midY = ((boardBottomY + tabBarTopY) * 0.5).clamp(0.0, stackH);

        // Map Y in [0, H] -> Align.y in [-1, +1]
        double yToAlign(double y, double totalH) => (y / totalH) * 2.0 - 1.0;
        double alignY = yToAlign(midY, stackH);

        // --- Device/orientation info ---
        final mq = MediaQuery.of(ctx);
        final shortest = mq.size.shortestSide;
        final bool isPortrait = orientation == Orientation.portrait;
        final bool isPhone = shortest < 600;       // rough tablet breakpoint
        final bool isSmallPhone = shortest < 380;  // small phones

        // --- Small pixel nudge UP so the visual center hits the true midline ---
        // Positive value = move UP by that many pixels.
        double upNudgePx = 0.0;
        if (isPhone && isPortrait) {
          upNudgePx = isSmallPhone ? 12.0 : 10.0;
        } else if (isPhone && !isPortrait) {
          upNudgePx = 8.0;
        } else {
          // tablets/desktop: tiny correction
          upNudgePx = 6.0;
        }
        // Convert pixel nudge to Align units and apply.
        alignY = (alignY - (upNudgePx / stackH) * 2.0).clamp(-1.0, 1.0);

        // After first layout pass, trigger one more build so measured sizes apply.
        final bool needsPostLayoutRebuild =
            (stackBox == null) || (boardBox == null) ||
            (widget.bottomBarKey != null && bottomBarBox == null);
        if (needsPostLayoutRebuild) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
        }

        // ---- Device-aware scaling: make the IntervalFinder smaller on phones ----
        // Baseline fractions (desktop/tablet)
        double widthFrac = 0.95;
        double heightFrac = 0.90;

        if (isPhone && isPortrait) {
          // Portrait phones: tighten so it feels proportional.
          widthFrac = isSmallPhone ? 0.72 : 0.78;
          heightFrac = isSmallPhone ? 0.45 : 0.50;
        }
        if (isPhone && !isPortrait) {
          // Landscape phones: still smaller, but you have more horizontal room.
          widthFrac = 0.66;
          heightFrac = 0.42;
        }

        return Stack(
          key: _stackKey,
          children: [
            // Base layer: keeps fretboard centered exactly like your original
            fbv.FretboardViewport(
              snapToOppositeNotchEdge: true,
              rotateChildInPortrait: false, // board handles portrait
              landscapeCleanEdgePreference:
                  fbv.LandscapeCleanEdgePreference.right,
              debugGutters: false,
              child: RepaintBoundary(child: board), // isolate paints
            ),

            // Overlay: place IntervalFinder so its CENTER lands on the true midline
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true, // let taps pass through to the fretboard
                child: Align(
                  alignment: Alignment(0, alignY),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: ValueListenableBuilder<String?>(
                      valueListenable: _note1VN,
                      builder: (_, n1, __) {
                        return ValueListenableBuilder<String?>(
                          valueListenable: _note2VN,
                          builder: (_, n2, __) {
                            return _CenteredScalableFinder(
                              designSize: const Size(640, 140),
                              maxWidthFraction: widthFrac,
                              maxHeightFraction: heightFrac,
                              firstNote: n1,
                              secondNote: n2,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Centers and uniformly scales IntervalFinder to fit whatever height it gets.
class _CenteredScalableFinder extends StatelessWidget {
  final Size designSize;
  final double maxWidthFraction;
  final double maxHeightFraction;

  final String? firstNote;
  final String? secondNote;

  const _CenteredScalableFinder({
    super.key,
    required this.designSize,
    required this.maxWidthFraction,
    required this.maxHeightFraction,
    required this.firstNote,
    required this.secondNote,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth * maxWidthFraction;
        final maxH = constraints.maxHeight * maxHeightFraction;

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: designSize.width,
              height: designSize.height,
              child: IntervalFinder(
                firstNote: firstNote,
                secondNote: secondNote,
              ),
            ),
          ),
        );
      },
    );
  }
}
