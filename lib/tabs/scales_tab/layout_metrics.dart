// widgets/scales_tab/layout_metrics.dart
import 'package:flutter/material.dart';

class GeometryCache {
  double? stackH, boardTopY, boardBottomY, tabBarTopY;

  bool update({
    required double newStackH,
    required double newBoardTopY,
    required double newBoardBottomY,
    required double newTabBarTopY,
  }) {
    const eps = 0.5;
    bool diff(double? a, double b) => a == null || (a - b).abs() > eps;
    final changed = diff(stackH, newStackH)
        || diff(boardTopY, newBoardTopY)
        || diff(boardBottomY, newBoardBottomY)
        || diff(tabBarTopY, newTabBarTopY);
    if (changed) {
      stackH = newStackH;
      boardTopY = newBoardTopY;
      boardBottomY = newBoardBottomY;
      tabBarTopY = newTabBarTopY;
    }
    return changed;
  }
}

/// Output for where/size to place overlays (selector + IntervalFinder)
class FinderLayout {
  final double alignTopY;       // -1..1 for selector row
  final double alignBottomY;    // -1..1 for finder row
  final double maxWFrac;        // IntervalFinder width fraction cap
  final double maxHFrac;        // IntervalFinder height fraction cap
  const FinderLayout(this.alignTopY, this.alignBottomY, this.maxWFrac, this.maxHFrac);
}

/// Strategy interface so portrait/landscape live in separate classes.
abstract class ScalesLayoutDelegate {
  FinderLayout compute({
    required BuildContext context,
    required double stackH,
    required double boardTopY,
    required double boardBottomY,
    required double tabBarTopY,
  });
}

/// PORTRAIT rules — tweak these numbers freely without touching any other file.
class PortraitLayoutDelegate implements ScalesLayoutDelegate {
  @override
  FinderLayout compute({
    required BuildContext context,
    required double stackH,
    required double boardTopY,
    required double boardBottomY,
    required double tabBarTopY,
  }) {
    // Tunable knobs for portrait
    const downNudgePortrait = 10.0;   // selector: push slightly DOWN
    const upNudgePortrait   = 12.0;   // finder:   pull slightly UP
    const phoneWFrac        = 0.78;   // finder width on phones
    const phoneHFrac        = 0.50;   // finder height on phones
    const tabletWFrac       = 0.85;   // finder width on tablets
    const tabletHFrac       = 0.60;   // finder height on tablets

    return _computeCommon(
      context: context,
      stackH: stackH,
      boardTopY: boardTopY,
      boardBottomY: boardBottomY,
      tabBarTopY: tabBarTopY,
      portrait: true,
      downNudgePortrait: downNudgePortrait,
      upNudgePortrait: upNudgePortrait,
      phoneWFracPortrait: phoneWFrac,
      phoneHFracPortrait: phoneHFrac,
      tabletWFracPortrait: tabletWFrac,
      tabletHFracPortrait: tabletHFrac,
      landscapeWFrac: 0.66, // unused in portrait
      landscapeHFrac: 0.42, // unused in portrait
    );
  }
}

/// LANDSCAPE rules — frozen to your current behavior.
class LandscapeLayoutDelegate implements ScalesLayoutDelegate {
  @override
  FinderLayout compute({
    required BuildContext context,
    required double stackH,
    required double boardTopY,
    required double boardBottomY,
    required double tabBarTopY,
  }) {
    // These match your existing landscape feel
    return _computeCommon(
      context: context,
      stackH: stackH,
      boardTopY: boardTopY,
      boardBottomY: boardBottomY,
      tabBarTopY: tabBarTopY,
      portrait: false,
      downNudgePortrait: 0, // ignored in landscape
      upNudgePortrait: 0,   // ignored in landscape
      phoneWFracPortrait: 0, // ignored
      phoneHFracPortrait: 0, // ignored
      tabletWFracPortrait: 0, // ignored
      tabletHFracPortrait: 0, // ignored
      landscapeWFrac: 0.66,
      landscapeHFrac: 0.42,
    );
  }
}

// ---- Shared math (parameterized) ----

FinderLayout _computeCommon({
  required BuildContext context,
  required double stackH,
  required double boardTopY,
  required double boardBottomY,
  required double tabBarTopY,
  required bool portrait,
  required double downNudgePortrait,
  required double upNudgePortrait,
  required double phoneWFracPortrait,
  required double phoneHFracPortrait,
  required double tabletWFracPortrait,
  required double tabletHFracPortrait,
  required double landscapeWFrac,
  required double landscapeHFrac,
}) {
  double _yToAlign(double y, double totalH) => (y / totalH) * 2.0 - 1.0;

  final mq = MediaQuery.of(context);
  final viewPad = mq.viewPadding;
  final shortest = mq.size.shortestSide;
  final isPhone = shortest < 600;
  final isSmallPhone = shortest < 380;

  final topBoundY = viewPad.top;
  final midTopY = ((topBoundY + boardTopY) * 0.5).clamp(0.0, stackH);
  final midBottomY = ((boardBottomY + tabBarTopY) * 0.5).clamp(0.0, stackH);

  double alignTopY = _yToAlign(midTopY, stackH);
  double alignBottomY = _yToAlign(midBottomY, stackH);

  // Visual centering nudges
  double downNudge, upNudge;
  if (portrait) {
    downNudge = isPhone ? (isSmallPhone ? downNudgePortrait + 2 : downNudgePortrait) : downNudgePortrait - 4;
    upNudge   = isPhone ? (isSmallPhone ? upNudgePortrait + 2 : upNudgePortrait)     : upNudgePortrait - 4;
  } else {
    // your prior landscape tuning
    downNudge = 6.0;
    upNudge   = 8.0;
  }

  alignTopY = (alignTopY + (downNudge / stackH) * 2.0).clamp(-1.0, 1.0);
  alignBottomY = (alignBottomY - (upNudge / stackH) * 2.0).clamp(-1.0, 1.0);

  // Finder size fractions
  double wFrac, hFrac;
  if (portrait) {
    if (isPhone) {
      wFrac = isSmallPhone ? 0.72 : phoneWFracPortrait;
      hFrac = isSmallPhone ? 0.45 : phoneHFracPortrait;
    } else {
      wFrac = tabletWFracPortrait;
      hFrac = tabletHFracPortrait;
    }
  } else {
    wFrac = landscapeWFrac;
    hFrac = landscapeHFrac;
  }

  return FinderLayout(alignTopY, alignBottomY, wFrac, hFrac);
}
