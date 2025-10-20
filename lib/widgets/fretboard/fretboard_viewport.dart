import 'package:flutter/material.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

enum LandscapeCleanEdgePreference { auto, left, right }
enum _NotchSide { none, left, right }
enum _StableNativeLandscape { none, left, right }

/// Viewport that handles device notch positioning and rotation
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

/// Internal computed viewport state
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
  int _frameCount = 0;
  double? _cachedBoxW;
  double? _cachedBoxH;
  bool _isFirstFrame = true;
  _NotchSide? _lastNotchSide;

  double _snap(double v, double dpr) => (v * dpr).round() / dpr;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isFirstFrame = false;
    });
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

  _ComputedViewport _computeViewportWithNotchSide(
    MediaQueryData sys,
    NativeDeviceOrientation native,
    _NotchSide forcedNotchSide,
  ) {
    final isPortrait = sys.orientation == Orientation.portrait;
    final pad = sys.viewPadding;
    
    // Reuse known notch side but recalculate padding
    double addLeft = 0, addRight = 0, addTop = pad.top;
    
    switch (forcedNotchSide) {
      case _NotchSide.left:
        addLeft = pad.left;
        break;
      case _NotchSide.right:
        addRight = pad.right;
        break;
      case _NotchSide.none:
        break;
    }

    return _ComputedViewport(
      isPortrait: isPortrait,
      notchSide: forcedNotchSide,
      addLeft: addLeft,
      addRight: addRight,
      addTop: addTop,
      align: Alignment.center,
    );
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
      if (notchSide == _NotchSide.left) addLeft = pad.left;
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
    final leftScore = pad.left + gest.left;
    final rightScore = pad.right + gest.right;

    if ((leftScore - rightScore) > eps) return _NotchSide.left;
    if ((rightScore - leftScore) > eps) return _NotchSide.right;

    if (native == NativeDeviceOrientation.landscapeLeft) return _NotchSide.left;
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

  @override
  Widget build(BuildContext context) {
    return NativeDeviceOrientationReader(
      builder: (ctx) {
        final sys = MediaQueryData.fromView(View.of(ctx));
        final flutterOrientation = sys.orientation;
        final native = NativeDeviceOrientationReader.orientation(ctx);
        final stableLandscape = _asStableLandscape(native);

        if (_frameCount < 2) {
          debugPrint('\n[Frame ${_frameCount + 1}] FretboardViewport:'
              '\n  viewPadding: ${sys.viewPadding}'
              '\n  systemGestureInsets: ${sys.systemGestureInsets}'
              '\n  orientation: $flutterOrientation'
              '\n  nativeOrientation: $native'
              '\n  constraints: ${(context.findRenderObject() as RenderBox?)?.constraints}');
          _frameCount++;
        }

        final needsRecompute =
            _cached == null ||
            _lastFlutterOrientation != flutterOrientation ||
            _lastStableLandscape != stableLandscape;

        if (needsRecompute) {
          if (_isFirstFrame && _lastNotchSide != null) {
            _cached = _computeViewportWithNotchSide(sys, native, _lastNotchSide!);
          } else {
            _cached = _computeViewport(sys, native);
            if (!_isFirstFrame) {
              _lastNotchSide = _cached!.notchSide;
            }
          }
          
          _lastFlutterOrientation = flutterOrientation;
          _lastStableLandscape = stableLandscape;

          if (!_isFirstFrame) {
            _cachedBoxW = null;
            _cachedBoxH = null;
          }
        }

        final c = _cached!;
        return LayoutBuilder(
          builder: (context, constraints) {
            final dpr = sys.devicePixelRatio;
            final addLeft = _snap(c.addLeft, dpr);
            final addRight = _snap(c.addRight, dpr);
            final addTop = _snap(c.addTop, dpr);
            final incomingW = _snap(constraints.maxWidth, dpr);
            final incomingH = _snap(constraints.maxHeight, dpr);

            final looksPlausible = _isPlausibleOuterBox(
              incomingW: incomingW,
              incomingH: incomingH,
              screen: sys.size,
            );

            if (_cachedBoxW == null || _cachedBoxH == null) {
              if (looksPlausible) {
                _cachedBoxW = incomingW;
                _cachedBoxH = incomingH;
              }
            } else {
              if (incomingW > _cachedBoxW!) _cachedBoxW = incomingW;
              if (incomingH > _cachedBoxH!) _cachedBoxH = incomingH;
            }

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
                  padding: EdgeInsets.only(
                    left: addLeft,
                    right: addRight,
                    top: addTop,
                  ),
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
                if (c.isPortrait && sys.viewPadding.top > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: sys.viewPadding.top,
                    child: Container(color: const Color(0x22FF0000)),
                  ),
                if (!c.isPortrait && sys.viewPadding.left > 0)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: sys.viewPadding.left,
                    child: Container(color: const Color(0x22FF0000)),
                  ),
                if (!c.isPortrait && sys.viewPadding.right > 0)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: sys.viewPadding.right,
                    child: Container(color: const Color(0x22FF0000)),
                  ),
                if (!c.isPortrait && sys.systemGestureInsets.left > 0)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: sys.viewPadding.left,
                    width: sys.systemGestureInsets.left,
                    child: Container(color: const Color(0x222277FF)),
                  ),
                if (!c.isPortrait && sys.systemGestureInsets.right > 0)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: sys.viewPadding.right,
                    width: sys.systemGestureInsets.right,
                    child: Container(color: const Color(0x222277FF)),
                  ),
                if (addTop > 0)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: addTop,
                    child: Container(color: const Color(0x2200FF00)),
                  ),
                if (addLeft > 0)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: addLeft,
                    child: Container(color: const Color(0x2200FF00)),
                  ),
                if (addRight > 0)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: addRight,
                    child: Container(color: const Color(0x2200FF00)),
                  ),
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
    if (incomingW <= 0 || incomingH <= 0) return false;
    final minW = screen.width * 0.45;
    final minH = screen.height * 0.45;
    return incomingW >= minW && incomingH >= minH;
  }
}
