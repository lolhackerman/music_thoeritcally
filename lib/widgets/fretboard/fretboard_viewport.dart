import 'package:flutter/material.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

enum LandscapeCleanEdgePreference { auto, left, right }
enum _NotchSide { none, left, right }
enum _StableNativeLandscape { none, left, right }

class FretboardViewport extends StatefulWidget {
  final Widget child;
  final bool snapToOppositeNotchEdge;
  final bool rotateChildInPortrait;
  final int portraitQuarterTurns;
  final LandscapeCleanEdgePreference landscapeCleanEdgePreference;
  final bool debugGutters;

  const FretboardViewport({
    super.key,
    required this.child,
    this.snapToOppositeNotchEdge = true,
    this.rotateChildInPortrait = false,
    this.portraitQuarterTurns = 1,
    this.landscapeCleanEdgePreference = LandscapeCleanEdgePreference.auto,
    this.debugGutters = false,
  });

  @override
  State<FretboardViewport> createState() => _FretboardViewportState();
}

class _ComputedViewport {
  final bool isPortrait;
  final _NotchSide notchSide;
  final double addLeft, addRight, addTop;
  final Alignment align;
  const _ComputedViewport({
    required this.isPortrait,
    required this.notchSide,
    required this.addLeft,
    required this.addRight,
    required this.addTop,
    required this.align,
  });
}

class _FretboardViewportState extends State<FretboardViewport> {
  _ComputedViewport? _cached;
  Orientation? _lastFlutterOrientation;
  _StableNativeLandscape? _lastStableLandscape;

  // Guarded-freeze cache of the outer box. We only cache when the
  // constraints look stable and non-trivially sized. Post-orientation,
  // we allow the cache to grow but not shrink (until next orientation change)
  // to avoid latching onto transient undersized first-frame constraints.
  double? _cachedBoxW;
  double? _cachedBoxH;

  double _snap(double v, double dpr) => (v * dpr).round() / dpr;

  @override
  Widget build(BuildContext context) {
    return NativeDeviceOrientationReader(
      builder: (ctx) {
        final sys = MediaQueryData.fromView(View.of(ctx));
        final flutterOrientation = sys.orientation;
        final native = NativeDeviceOrientationReader.orientation(ctx);
        final stableLandscape = _asStableLandscape(native);

        final needsRecompute =
            _cached == null ||
            _lastFlutterOrientation != flutterOrientation ||
            _lastStableLandscape != stableLandscape;

        if (needsRecompute) {
          _cached = _computeViewport(sys, native);
          _lastFlutterOrientation = flutterOrientation;
          _lastStableLandscape = stableLandscape;

          // On real orientation change, reset the frozen outer size.
          _cachedBoxW = null;
          _cachedBoxH = null;
        }

        final c = _cached!;
        final pad = sys.viewPadding;
        final gest = sys.systemGestureInsets;

        return LayoutBuilder(
          builder: (context, constraints) {
            final dpr = sys.devicePixelRatio;

            // Snap paddings to physical pixels for crisp edges.
            final addLeft  = _snap(c.addLeft,  dpr);
            final addRight = _snap(c.addRight, dpr);
            final addTop   = _snap(c.addTop,   dpr);

            // Incoming measured box from parent constraints.
            final incomingW = _snap(constraints.maxWidth,  dpr);
            final incomingH = _snap(constraints.maxHeight, dpr);

            // Determine if these constraints look "plausibly stable".
            final screen = sys.size; // logical size in current orientation
            final looksPlausible = _isPlausibleOuterBox(
              incomingW: incomingW,
              incomingH: incomingH,
              screen: screen,
            );

            // Guarded-freeze policy:
            // 1) On first pass after orientation change, only cache if plausible.
            // 2) Thereafter, allow the cache to grow (accept larger numbers),
            //    but ignore transient shrinkage to avoid latching half-size.
            if (_cachedBoxW == null || _cachedBoxH == null) {
              if (looksPlausible) {
                _cachedBoxW = incomingW;
                _cachedBoxH = incomingH;
              }
            } else {
              if (incomingW > _cachedBoxW!) _cachedBoxW = incomingW;
              if (incomingH > _cachedBoxH!) _cachedBoxH = incomingH;
              // Note: we intentionally do NOT accept smaller values here.
              // True viewport shrink (e.g., multi-window resize) will be handled
              // by the next orientation change or can be extended later with
              // a timed stability check if needed.
            }

            // Effective box for *this* frame: if the cache isn't set yet,
            // render with the incoming size, but do not freeze it unless plausible.
            final effW = (_cachedBoxW ?? incomingW);
            final effH = (_cachedBoxH ?? incomingH);

            final maxW = (effW - addLeft - addRight).clamp(0.0, double.infinity);
            final maxH = (effH - addTop).clamp(0.0, double.infinity);

            Widget content = widget.child;
            if (c.isPortrait && widget.rotateChildInPortrait) {
              content = RotatedBox(
                quarterTurns: widget.portraitQuarterTurns % 4,
                child: content,
              );
            }

            content = RepaintBoundary(child: content);

            Widget body = MediaQuery.removePadding(
              context: ctx,
              removeLeft: true,
              removeRight: true,
              removeTop: true,
              removeBottom: false,
              child: ClipRect(
                clipBehavior: Clip.hardEdge,
                child: Padding(
                  padding: EdgeInsets.only(left: addLeft, right: addRight, top: addTop),
                  child: Align(
                    alignment: c.align,
                    child: SizedBox(
                      width: maxW,
                      height: maxH,
                      child: ClipRect(child: content),
                    ),
                  ),
                ),
              ),
            );

            if (!widget.debugGutters) return body;

            return Stack(
              children: [
                Positioned.fill(child: Container(color: const Color(0x08000000))),
                if (c.isPortrait && pad.top > 0)
                  Positioned(top: 0, left: 0, right: 0, height: pad.top,
                      child: Container(color: const Color(0x22FF0000))),
                if (!c.isPortrait && pad.left > 0)
                  Positioned(top: 0, bottom: 0, left: 0, width: pad.left,
                      child: Container(color: const Color(0x22FF0000))),
                if (!c.isPortrait && pad.right > 0)
                  Positioned(top: 0, bottom: 0, right: 0, width: pad.right,
                      child: Container(color: const Color(0x22FF0000))),
                if (!c.isPortrait && gest.left > 0)
                  Positioned(top: 0, bottom: 0, left: pad.left, width: gest.left,
                      child: Container(color: const Color(0x222277FF))),
                if (!c.isPortrait && gest.right > 0)
                  Positioned(top: 0, bottom: 0, right: pad.right, width: gest.right,
                      child: Container(color: const Color(0x222277FF))),
                if (addTop > 0)
                  Positioned(top: 0, left: 0, right: 0, height: addTop,
                      child: Container(color: const Color(0x2200FF00))),
                if (addLeft > 0)
                  Positioned(top: 0, bottom: 0, left: 0, width: addLeft,
                      child: Container(color: const Color(0x2200FF00))),
                if (addRight > 0)
                  Positioned(top: 0, bottom: 0, right: 0, width: addRight,
                      child: Container(color: const Color(0x2200FF00))),
                ClipRect(child: body),
              ],
            );
          },
        );
      },
    );
  }

  bool _isPlausibleOuterBox({
    required double incomingW,
    required double incomingH,
    required Size screen,
  }) {
    // Reject obviously bogus/placeholder sizes (zero or extremely small).
    if (incomingW <= 0 || incomingH <= 0) return false;

    // Heuristic: accept if at least ~45% of the current screen in each axis.
    // This filters out the transient half-height/half-width we see on first
    // layout in certain tab-switch+rotation sequences, while still allowing
    // small devices and insets.
    final minW = screen.width * 0.45;
    final minH = screen.height * 0.45;
    return incomingW >= minW && incomingH >= minH;
  }

  _StableNativeLandscape _asStableLandscape(NativeDeviceOrientation native) {
    switch (native) {
      case NativeDeviceOrientation.landscapeLeft:
        return _StableNativeLandscape.left;
      case NativeDeviceOrientation.landscapeRight:
        return _StableNativeLandscape.right;
      default:
        return _StableNativeLandscape.none;
    }
  }

  _ComputedViewport _computeViewport(
    MediaQueryData sys,
    NativeDeviceOrientation native,
  ) {
    final pad = sys.viewPadding;
    final gest = sys.systemGestureInsets;
    final isPortrait = sys.orientation == Orientation.portrait;

    final notchSide = isPortrait
        ? _NotchSide.none
        : _detectNotchSideLandscape(
            pad: pad,
            gest: gest,
            native: native,
            pref: widget.landscapeCleanEdgePreference,
          );

    double addLeft = 0, addRight = 0, addTop = 0;
    if (isPortrait) {
      addTop = pad.top;
    } else {
      if (notchSide == _NotchSide.left)  addLeft  = pad.left;
      if (notchSide == _NotchSide.right) addRight = pad.right;
    }

    Alignment align = Alignment.center;
    if (widget.snapToOppositeNotchEdge) {
      if (isPortrait) {
        align = Alignment.bottomCenter;
      } else {
        switch (notchSide) {
          case _NotchSide.left:  align = Alignment.centerRight; break;
          case _NotchSide.right: align = Alignment.centerLeft;  break;
          case _NotchSide.none:  align = Alignment.center;      break;
        }
      }
    }

    return _ComputedViewport(
      isPortrait: isPortrait,
      notchSide: notchSide,
      addLeft: addLeft,
      addRight: addRight,
      addTop: addTop,
      align: align,
    );
  }

  _NotchSide _detectNotchSideLandscape({
    required EdgeInsets pad,
    required EdgeInsets gest,
    required NativeDeviceOrientation native,
    required LandscapeCleanEdgePreference pref,
  }) {
    const eps = 0.5;
    final leftScore  = pad.left  + gest.left;
    final rightScore = pad.right + gest.right;

    if ((leftScore - rightScore) > eps) return _NotchSide.left;
    if ((rightScore - leftScore) > eps) return _NotchSide.right;

    if (native == NativeDeviceOrientation.landscapeLeft)  return _NotchSide.left;
    if (native == NativeDeviceOrientation.landscapeRight) return _NotchSide.right;

    switch (pref) {
      case LandscapeCleanEdgePreference.left:
        return _NotchSide.left;
      case LandscapeCleanEdgePreference.right:
        return _NotchSide.right;
      case LandscapeCleanEdgePreference.auto:
        return _NotchSide.none;
    }
  }
}
