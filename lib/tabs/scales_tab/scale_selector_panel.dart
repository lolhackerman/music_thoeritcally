import 'package:flutter/material.dart';
import 'package:music_theoretically/widgets/note_tile.dart';
import 'scales_state.dart';
import 'scales_constants.dart';
import 'package:music_theoretically/widgets/fretboard/fretboard_styles.dart' show chromatic;


class ScaleSelectorPanel extends StatefulWidget {
  final ScalesState state;
  const ScaleSelectorPanel({super.key, required this.state});
  @override State<ScaleSelectorPanel> createState() => _ScaleSelectorPanelState();
}

class _ScaleSelectorPanelState extends State<ScaleSelectorPanel> {
  @override
  void initState() {
    super.initState();
    widget.state.selectedScaleVN.addListener(_onChange);
    widget.state.selectedRootVN.addListener(_onChange);
  }
  @override
  void didUpdateWidget(covariant ScaleSelectorPanel old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) {
      old.state.selectedScaleVN.removeListener(_onChange);
      old.state.selectedRootVN.removeListener(_onChange);
      widget.state.selectedScaleVN.addListener(_onChange);
      widget.state.selectedRootVN.addListener(_onChange);
    }
  }
  @override
  void dispose() {
    widget.state.selectedScaleVN.removeListener(_onChange);
    widget.state.selectedRootVN.removeListener(_onChange);
    super.dispose();
  }
  void _onChange() => setState((){});

  List<String> _rotatedNotes(String root) {
    final idx = chromatic.indexOf(root);
    return [...chromatic.sublist(idx), ...chromatic.sublist(0, idx)];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, selC) {
      final innerW = selC.maxWidth;
      final innerSpacing = innerW * 0.005;
      final innerPad     = innerW * 0.05;

      final currentScale = widget.state.selectedScaleVN.value;
      final currentRoot  = widget.state.selectedRootVN.value;

      final innerAvail   = innerW - innerPad * 2;
      final noteCount    = chromatic.length;
      final innerRawTile = (innerAvail - innerSpacing * (noteCount - 1)) / noteCount;
      final innerTile    = innerRawTile.clamp(24.0, 32.0);

      final scaleNotes = widget.state.scaleNotesFor(currentRoot, currentScale);

      return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: innerPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: currentScale,
                items: allScales.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (s) { if (s != null) widget.state.selectedScaleVN.value = s; },
              ),
              SizedBox(height: innerSpacing * 4),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: innerSpacing,
                runSpacing: innerSpacing,
                children: _rotatedNotes(currentRoot).map((n) {
                  return SizedBox(
                    width: innerTile,
                    height: innerTile,
                    child: NoteTile(
                      note: n,
                      width: innerTile,
                      height: innerTile,
                      rootNote: currentRoot,
                      scaleNotes: scaleNotes,
                      onTap: () => widget.state.selectedRootVN.value = n,
                      orientation: MediaQuery.of(context).orientation,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    });
  }
}
