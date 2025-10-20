import 'package:flutter/material.dart';
import 'package:music_theoretically/widgets/fretboard/fretboard_widget.dart';
import 'package:music_theoretically/widgets/fretboard/fretboard_styles.dart' as styles;
import 'package:music_theoretically/widgets/fretboard/fretboard_viewport.dart' as fbv;
import 'package:music_theoretically/widgets/fretboard/fret_spot.dart';
import 'package:music_theoretically/widgets/responsive_layout.dart';
import 'package:music_theoretically/widgets/fade_on_mount.dart';

import 'chord_library.dart';
import 'chord_diagram.dart';
import 'chord_formulas.dart';

class ChordsTab extends StatefulWidget {
  final GlobalKey? bottomBarKey;
  final TabController? tabController;
  final int? tabIndex;
  const ChordsTab({super.key, this.bottomBarKey, this.tabController, this.tabIndex});

  @override
  State<ChordsTab> createState() => _ChordsTabState();
}

class _ChordsTabState extends State<ChordsTab>
  with AutomaticKeepAliveClientMixin<ChordsTab> {
  @override
  bool get wantKeepAlive => true;

  final _stackKey = GlobalKey();
  final List<String> _chromatic = styles.chromatic;
  String _root = 'C';
  String _quality = 'maj';

  ChordDefinition? _currentChord;
  int _selectedVoicingIndex = 0;
  double? _fretboardContentHeight;

  // fade handled by FadeOnMount wrapper

  List<FretSpot>? _getSelectedSpots() {
    if (_currentChord == null || _selectedVoicingIndex >= _currentChord!.voicings.length) {
      return null;
    }
    
    final voicing = _currentChord!.voicings[_selectedVoicingIndex];
    final spots = <FretSpot>[];
    
    // Get the root note pitch class for comparison
    final rootPitchClass = _root;
    
    for (final pos in voicing.positions) {
      if (pos.muted) {
        continue;
      }
      
      // Convert relative fret to absolute fret position
      final absoluteFret = relativeToAbsoluteFret(
        baseFret: voicing.baseFret,
        fretRelative: pos.fretRelative,
      );

      // Calculate the note at this position using the tuning
      final openNote = kStandardTuning[pos.stringIndex];
      final noteAtPosition = _pcAt(openNote, absoluteFret);
      
      // Check if this note is the root note
      final isRoot = noteAtPosition == rootPitchClass;      // Add the spot, marking root notes appropriately
      spots.add(FretSpot(
        string: pos.stringIndex,
        fret: absoluteFret,
        isRoot: isRoot,
      ));
    }
    
    return spots;
  }

  String _pcAt(String openNote, int absFret) {
    final base = kChromatic.indexOf(openNote);
    if (base < 0) return openNote;  // fallback if unknown
    return kChromatic[(base + absFret) % 12];
  }

  ChordDefinition? _chordDefFor(String root, String quality) {
    // Convert quality string to enum (e.g., 'maj' -> ChordQuality.maj)
    ChordQuality? qualityEnum;
    try {
      qualityEnum = ChordQuality.values.firstWhere(
        (q) => q.toString().split('.').last == quality,
      );
    } catch (_) {
      print('Unknown chord quality: $quality');
      return null;
    }
    
    // Look up in the chord library
    return chordLibrary[root]?[qualityEnum];
  }

  void _applyChordSelection() {
    _currentChord = _chordDefFor(_root, _quality);
    _selectedVoicingIndex = 0;
  }

  @override
  void initState() {
    super.initState();
    _applyChordSelection();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FadeOnMount(
      tabController: widget.tabController,
      tabIndex: widget.tabIndex,
      child: ResponsiveLayout(builder: (ctx, ori, wF, hF) {
      const baseHPad = 72.0;
      final hPad = wF * baseHPad;

      return LayoutBuilder(
        builder: (context, constraints) {
          final media = MediaQuery.of(context);
          final viewPad = media.viewPadding;

          // Optional: measured tab bar height if parent passed a key
          final bottomBarBox =
              widget.bottomBarKey?.currentContext?.findRenderObject() as RenderBox?;
          final measuredBarH = bottomBarBox?.size.height ?? kTextTabBarHeight;

          // Strip sizing knobs (easy to tweak here or move to a Theme later)
          const kStripMax = 110.0;
          const kStripVPad = 8.0;

          // Compute the free space under the fretboard content inside this Stack
          final stackH = constraints.maxHeight;
          final contentH = _fretboardContentHeight;
          final freeSpace = (contentH == null)
              ? kStripMax
              : (stackH - contentH - viewPad.bottom - measuredBarH - kStripVPad * 2)
                  .clamp(0.0, kStripMax);

          // Give the top band a small floor so selectors never disappear
          final stripHeight = freeSpace.clamp(56.0, kStripMax);

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
                        key: ValueKey('$_root-$_quality-$_selectedVoicingIndex'),
                        rootNote: _root,
                        scaleNotes: [], // Don't pass any scale notes - we'll use selectedSpots
                        selectedSpots: _getSelectedSpots(),
                        onComputedHeight: (h) {
                          if (_fretboardContentHeight != h) {
                            setState(() => _fretboardContentHeight = h);
                          }
                        },
                      ),
                    ),
                  ),
                ),

                // ===== TOP: selectors (left) + chord diagrams (right) =====
                Positioned(
                  left: viewPad.left,
                  right: hPad + viewPad.right,
                  top: viewPad.top + kStripVPad,
                  height: stripHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT COLUMN: Root (top) + Quality (bottom)
                      SizedBox(
                        width: 100, // adjust as needed
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _BareDropdown<String>(
                              value: _root,
                              items: _chromatic
                                  .map((n) => DropdownMenuItem(
                                        value: n,
                                        child: Text(
                                          n,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() {
                                  _root = v;
                                  _applyChordSelection();
                                });
                              },
                              height: 44,
                              hint: 'Root',
                            ),
                            const SizedBox(height: 8),
                            _BareDropdown<String>(
                              value: _quality,
                              items: chordFormulas.keys
                                  .map((q) => DropdownMenuItem(
                                        value: q,
                                        child: Text(
                                          q,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() {
                                  _quality = v;
                                  _applyChordSelection();
                                });
                              },
                              height: 44,
                              hint: 'Quality',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 1),

                      // RIGHT: horizontal list of chord mini-diagrams OR empty state
                      Expanded(
                        child: Builder(builder: (context) {
                          final hasVoicings = _currentChord != null &&
                              _currentChord!.voicings.isNotEmpty;

                          // Fill the band height; keep diagrams proportional
                          final diagramH = stripHeight;
                          final diagramW = diagramH * 0.8;

                          if (!hasVoicings) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'No voicings for $_root $_quality',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _currentChord!.voicings.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, i) {
                              final v = _currentChord!.voicings[i];
                              return Center(
                                child: ChordDiagram(
                                  voicing: v,
                                  width: diagramW,
                                  height: diagramH,
                                  selected: i == _selectedVoicingIndex,
                                  onTap: () {
                                    setState(() {
                                      _selectedVoicingIndex = i;
                                      // This triggers fretboard update through rebuild
                                    });
                                  },
                                ),
                              );
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
                ),
              );
        },
      );
    }),
    );
  }
}

/// A minimal, no-box, no-underline dropdown so selectors visually float.
class _BareDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final double height;
  final String? hint;

  const _BareDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.height = 44,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            isDense: true,
            isExpanded: false,
            menuMaxHeight: 360,
            hint: hint == null ? null : Text(hint!),
            style: const TextStyle(fontSize: 16, color: Colors.white),
            dropdownColor: const Color(0xFF1C1C1E),
          ),
        ),
      ),
    );
  }
}
