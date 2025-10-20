// widgets/scales_tab/scales_tab.dart
import 'package:flutter/material.dart';
import 'package:music_theoretically/widgets/responsive_layout.dart';
import 'package:music_theoretically/widgets/fade_on_mount.dart';

import 'scales_state.dart';
import 'fretboard_area.dart';
import 'scale_selector_panel.dart';
import 'centered_scalable_finder.dart';
import 'layout_metrics.dart';
import 'scales_composer.dart';

class ScalesTab extends StatefulWidget {
  final GlobalKey? bottomBarKey;
  final TabController? tabController;
  final int? tabIndex;
  const ScalesTab({super.key, this.bottomBarKey, this.tabController, this.tabIndex});
  @override
  State<ScalesTab> createState() => _ScalesTabState();
}

class _ScalesTabState extends State<ScalesTab>
  with AutomaticKeepAliveClientMixin<ScalesTab> {
  @override
  bool get wantKeepAlive => true;

  // Keys / geometry
  final _stackKey = GlobalKey();
  final _fretboardKey = GlobalKey();
  final _geo = GeometryCache();

  late final ScalesState _state;
  // fade handled by FadeOnMount

  @override
  void initState() {
    super.initState();
    _state = ScalesState();
  // handled by FadeOnMount
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state.attachPersistence(context);
    _state.tryRestore(context);
  }

  @override
  void dispose() {
  _state.dispose();
  // handled by FadeOnMount
  super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // for AutomaticKeepAliveClientMixin
    return FadeOnMount(
      tabController: widget.tabController,
      tabIndex: widget.tabIndex,
      child: ResponsiveLayout(builder: (ctx, ori, wF, hF) {
      const baseHPad = 72.0;
      final hPad = wF * baseHPad;

  return LayoutBuilder(builder: (context, constraints) {
        // --- Measurements for overlay alignment ---
        final stackCtx = _stackKey.currentContext;
        final boardCtx = _fretboardKey.currentContext;
        final stackBox = stackCtx?.findRenderObject() as RenderBox?;
        final boardBox = boardCtx?.findRenderObject() as RenderBox?;
        final bottomBarBox = widget.bottomBarKey?.currentContext?.findRenderObject() as RenderBox?;

        final size = MediaQuery.of(context).size;
        final viewPad = MediaQuery.of(context).viewPadding;
        final stackH = stackBox?.size.height ?? size.height;

        Offset boardTopLeftInStack = Offset.zero;
        if (boardBox != null && stackBox != null) {
          boardTopLeftInStack =
              boardBox.localToGlobal(Offset.zero, ancestor: stackBox);
        }
        final boardTopY =
            boardBox != null ? boardTopLeftInStack.dy : stackH * 0.40;
        final boardBottomY = boardBox != null
            ? boardTopLeftInStack.dy + boardBox.size.height
            : stackH * 0.60;

        final measuredBarH = bottomBarBox?.size.height ?? kTextTabBarHeight;
        final bottomPad = (bottomBarBox != null)
            ? (measuredBarH + viewPad.bottom)
            : (measuredBarH + viewPad.bottom + 8.0);
        final tabBarTopY = stackH - bottomPad;

        final needsRebuild = (stackBox == null) ||
            (boardBox == null) ||
            (widget.bottomBarKey != null && bottomBarBox == null) ||
            _geo.update(
              newStackH: stackH,
              newBoardTopY: boardTopY,
              newBoardBottomY: boardBottomY,
              newTabBarTopY: tabBarTopY,
            );
        if (needsRebuild) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
        }

        // --- Pick the numeric policy (portrait vs landscape), but render with the same overlay composer ---
        final isPortrait =
            MediaQuery.of(context).orientation == Orientation.portrait;

    final ScalesLayoutDelegate delegate =
      isPortrait ? PortraitLayoutDelegate() : LandscapeLayoutDelegate();

        final layout = delegate.compute(
          context: context,
          stackH: stackH,
          boardTopY: boardTopY,
          boardBottomY: boardBottomY,
          tabBarTopY: tabBarTopY,
        );

        // Build stable children once using the delegate's size caps for BOTH modes
        final children = ScalesChildren(
          fretboard: FretboardArea(boardKey: _fretboardKey, state: _state),
          selector: ScaleSelectorPanel(state: _state),
          intervalFinder: CenteredScalableFinder(
            designSize: const Size(640, 140),
            maxWidthFraction: layout.maxWFrac,
            maxHeightFraction: layout.maxHFrac,
            firstNote: _state.firstNoteVN.value,
            secondNote: _state.secondNoteVN.value,
            firstNoteVN: _state.firstNoteVN,
            secondNoteVN: _state.secondNoteVN,
          ),
          horizontalPad: EdgeInsets.symmetric(horizontal: hPad),
        );

        // Choose composer: use a new right-overlay composer for portrait so
        // the selector sits in a right-side overlay while the fretboard keeps
        // its pixel-identical bounds. Landscape continues to use the
        // existing overlay composer.
        final ScalesComposer composer = isPortrait
            ? PortraitOverlayRightSidebar()
            : LandscapeComposer(
                alignTopY: layout.alignTopY,
                alignBottomY: layout.alignBottomY,
              );

        // Outer Stack holds the key used for geometry; composer provides the body.
        return Stack(
          key: _stackKey,
          children: [
            composer.build(context, children),
          ],
        );
        });
      }),
    );
  }
}
