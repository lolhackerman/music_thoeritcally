// lib/widgets/chords_tab/chords_tab.dart
import 'package:flutter/material.dart';
import 'package:music_theoretically/widgets/fretboard/fretboard_widget.dart';
import 'package:music_theoretically/widgets/fretboard/fretboard_styles.dart' as styles;
import 'package:music_theoretically/widgets/fretboard/fretboard_viewport.dart' as fbv;
import 'package:music_theoretically/widgets/responsive_layout.dart';
import 'package:music_theoretically/tabs/chords_tab/chord_library.dart';
import 'package:music_theoretically/tabs/chords_tab/chord_diagram.dart';

const Map<String, List<int>> _chordFormulas = {
  'maj': [0, 4, 7],
  'min': [0, 3, 7],
  'dim': [0, 3, 6],
  'aug': [0, 4, 8],
  'sus2': [0, 2, 7],
  'sus4': [0, 5, 7],
  '6': [0, 4, 7, 9],
  'm6': [0, 3, 7, 9],
  '7': [0, 4, 7, 10],
  'maj7': [0, 4, 7, 11],
  'min7': [0, 3, 7, 10],
  'm7b5': [0, 3, 6, 10],
  'dim7': [0, 3, 6, 9],
  'add9': [0, 4, 7, 14],
  'm(add9)': [0, 3, 7, 14],
};

class ChordsTab extends StatefulWidget {
  final GlobalKey? bottomBarKey; // pass your TabBar/BottomNav key if you have it
  const ChordsTab({super.key, this.bottomBarKey});

  @override
  State<ChordsTab> createState() => _ChordsTabState();
}

class _ChordsTabState extends State<ChordsTab>
    with AutomaticKeepAliveClientMixin<ChordsTab> {
  @override
  bool get wantKeepAlive => true;

  final _stackKey = GlobalKey();
  final _fretboardKey = GlobalKey();

  late final List<String> _chromatic = styles.chromatic;
  String _root = 'C';
  String _quality = 'maj';

  ChordDefinition? _currentChord;
  int _selectedVoicingIndex = 0;

  // NEW: actual drawn height of the fretboard content
  double? _fretboardContentHeight;

  Set<String> get _chordNotes {
    final rootIndex = _chromatic.indexOf(_root);
    if (rootIndex < 0) return const {};
    final intervals = _chordFormulas[_quality] ?? const [0, 4, 7];
    return intervals
        .map((i) => _chromatic[(rootIndex + (i % 12)) % 12])
        .toSet();
  }

  @override
  void initState() {
    super.initState();
    _applyChordSelection();
  }

  ChordDefinition? _chordDefFor(String root, String quality) {
    if (root == 'C' && quality == 'maj') return seedCmaj;
    return null;
  }

  void _applyChordSelection() {
    _currentChord = _chordDefFor(_root, _quality);
    _selectedVoicingIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ResponsiveLayout(builder: (ctx, ori, wF, hF) {
      const baseHPad = 72.0;
      final hPad = wF * baseHPad;

      return LayoutBuilder(
        builder: (context, constraints) {
          final media = MediaQuery.of(context);
          final viewPad = media.viewPadding;

          // Optional: measured tab bar height if parent passed a key
          final bottomBarBox = widget.bottomBarKey
              ?.currentContext
              ?.findRenderObject() as RenderBox?;
          final measuredBarH = bottomBarBox?.size.height ?? kTextTabBarHeight;

          // Strip sizing parameters
          const kStripMax = 130.0;
          const kStripVPad = 8.0;

          // Compute the free space under the fretboard content inside this Stack
          final stackH = constraints.maxHeight;
          final contentH = _fretboardContentHeight;
          final freeSpace = (contentH == null)
              // Before first measurement, assume there's room for max strip height.
              ? kStripMax
              : (stackH
                  - contentH
                  - viewPad.bottom
                  - measuredBarH
                  - kStripVPad * 2)
                  .clamp(0.0, kStripMax);

          final stripHeight =
              (freeSpace is num ? freeSpace.toDouble() : kStripMax);

          return SizedBox.expand(
            child: Stack(
              key: _stackKey,
              fit: StackFit.expand,
              children: [
                // ===== Full-bleed fretboard =====
                Positioned.fill(
                  child: fbv.FretboardViewport(
                    snapToOppositeNotchEdge: true,
                    rotateChildInPortrait: false,
                    landscapeCleanEdgePreference:
                        fbv.LandscapeCleanEdgePreference.right,
                    debugGutters: false,
                    child: RepaintBoundary(
                      child: FretboardWidget(
                        key: _fretboardKey,
                        rootNote: _root,
                        scaleNotes: _chordNotes.toList(),
                        // NEW: get actual drawn height so we can size the strip perfectly
                        onComputedHeight: (h) {
                          if (_fretboardContentHeight != h) {
                            setState(() => _fretboardContentHeight = h);
                          }
                        },
                      ),
                    ),
                  ),
                ),

                // ===== Controls under the app bar =====
                Positioned(
                  top: viewPad.top + kToolbarHeight + 8,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: _ControlsBar(
                      chromatic: _chromatic,
                      root: _root,
                      quality: _quality,
                      onRootChanged: (r) => setState(() {
                        _root = r;
                        _applyChordSelection();
                      }),
                      onQualityChanged: (q) => setState(() {
                        _quality = q;
                        _applyChordSelection();
                      }),
                    ),
                  ),
                ),

                // ===== Bottom chord strip (never pushes the fretboard) =====
                if (_currentChord != null &&
                    _currentChord!.voicings.isNotEmpty &&
                    stripHeight > 0)
                  Positioned(
                    left: hPad,
                    right: hPad,
                    bottom: viewPad.bottom + measuredBarH + kStripVPad,
                    height: stripHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _currentChord!.voicings.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final v = _currentChord!.voicings[i];
                        return ChordDiagram(
                          voicing: v,
                          width: 96,
                          height: 120,
                          selected: i == _selectedVoicingIndex,
                          onTap: () {
                            setState(() {
                              _selectedVoicingIndex = i;
                              // By design, no overlay is pushed to the big fretboard
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
    });
  }
}

class _ControlsBar extends StatelessWidget {
  final List<String> chromatic;
  final String root;
  final String quality;
  final ValueChanged<String> onRootChanged;
  final ValueChanged<String> onQualityChanged;

  const _ControlsBar({
    required this.chromatic,
    required this.root,
    required this.quality,
    required this.onRootChanged,
    required this.onQualityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final noteDropdown = DropdownButton<String>(
      value: root,
      onChanged: (v) => onRootChanged(v ?? root),
      items: chromatic
          .map((n) => DropdownMenuItem(value: n, child: Text(n)))
          .toList(),
    );

    final qualityDropdown = DropdownButton<String>(
      value: quality,
      onChanged: (v) => onQualityChanged(v ?? quality),
      items: _chordFormulas.keys
          .map((q) => DropdownMenuItem(value: q, child: Text(q)))
          .toList(),
    );

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Labeled('Root', noteDropdown),
        _Labeled('Quality', qualityDropdown),
      ],
    );
  }
}

class _Labeled extends StatelessWidget {
  final String label;
  final Widget child;
  const _Labeled(this.label, this.child);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(width: 8),
      child,
    ]);
  }
}
