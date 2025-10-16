import 'package:flutter/material.dart';
import 'package:music_theoretically/widgets/fretboard/fretboard_widget.dart';
import 'package:music_theoretically/widgets/fretboard/fretboard_viewport.dart' as fbv;
import 'scales_state.dart';

class FretboardArea extends StatefulWidget {
  final GlobalKey boardKey;
  final ScalesState state;
  const FretboardArea({super.key, required this.boardKey, required this.state});

  @override State<FretboardArea> createState() => _FretboardAreaState();
}

class _FretboardAreaState extends State<FretboardArea> {
  @override
  void initState() {
    super.initState();
    widget.state.selectedRootVN.addListener(_onChange);
    widget.state.selectedScaleVN.addListener(_onChange);
  }
  @override
  void didUpdateWidget(covariant FretboardArea old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) {
      old.state.selectedRootVN.removeListener(_onChange);
      old.state.selectedScaleVN.removeListener(_onChange);
      widget.state.selectedRootVN.addListener(_onChange);
      widget.state.selectedScaleVN.addListener(_onChange);
    }
  }
  @override
  void dispose() {
    widget.state.selectedRootVN.removeListener(_onChange);
    widget.state.selectedScaleVN.removeListener(_onChange);
    super.dispose();
  }
  void _onChange() => setState((){});

  @override
  Widget build(BuildContext context) {
    final root = widget.state.selectedRootVN.value;
    final scale = widget.state.selectedScaleVN.value;
    final scaleNotes = widget.state.scaleNotesFor(root, scale);

    return fbv.FretboardViewport(
      snapToOppositeNotchEdge: true,
      rotateChildInPortrait: false,
      landscapeCleanEdgePreference: fbv.LandscapeCleanEdgePreference.right,
      debugGutters: false,
      child: RepaintBoundary(
        child: FretboardWidget(
          key: widget.boardKey,
          rootNote: root,
          scaleNotes: scaleNotes,
          onNoteTap: widget.state.handleNoteTap,
        ),
      ),
    );
  }
}
