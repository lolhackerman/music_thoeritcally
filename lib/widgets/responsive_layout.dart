// A widget that builds a responsive layout based on the screen size and orientation.
import 'package:flutter/widgets.dart';

/// Handy enum so we don’t leak Flutter’s [Orientation] type here.
enum ScreenOrientation { portrait, landscape }

/// Signature passes separate width/height factors (wF, hF).
typedef ResponsiveLayoutBuilder = Widget Function(
  BuildContext context,
  ScreenOrientation orientation,
  double wF,
  double hF,
);

/// Base design dimensions for scale calculations.
class RatioUtils {
  /// Width of your landscape mock‑up.
  static const double baseWidth = 1440;

  /// Height of your landscape mock‑up (becomes the *portrait* width baseline).
  static const double baseHeight = 900;
}

class ResponsiveLayout extends StatelessWidget {
  final ResponsiveLayoutBuilder builder;

  const ResponsiveLayout({
    required this.builder,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;

    // Determine orientation.
    final orientation = size.width > size.height
        ? ScreenOrientation.landscape
        : ScreenOrientation.portrait;

    // --- Scale factors ------------------------------------------------------
    final wF = orientation == ScreenOrientation.portrait
        ? size.width / RatioUtils.baseHeight
        : size.width / RatioUtils.baseWidth;

    final hF = orientation == ScreenOrientation.portrait
        ? size.height / RatioUtils.baseWidth
        : size.height / RatioUtils.baseHeight;

    return builder(context, orientation, wF, hF);
  }
}
