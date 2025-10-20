import 'package:flutter/material.dart';

/// Wrapper widget that fades its [child] in on mount and optionally
/// replays the fade when a parent [TabController] selects [tabIndex].
class FadeOnMount extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final TabController? tabController;
  final int? tabIndex;
  final bool animateOnMount;

  const FadeOnMount({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeInOut,
    this.tabController,
    this.tabIndex,
    this.animateOnMount = true,
  }) : super(key: key);

  @override
  State<FadeOnMount> createState() => _FadeOnMountState();
}

class _FadeOnMountState extends State<FadeOnMount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    if (widget.animateOnMount) _controller.forward();
    widget.tabController?.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (widget.tabIndex != null && widget.tabController?.index == widget.tabIndex) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    widget.tabController?.removeListener(_handleTabChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _animation, child: widget.child);
}
