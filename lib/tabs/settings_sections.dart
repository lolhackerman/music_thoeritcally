import 'package:flutter/material.dart';
import '../state/app_settings.dart';
import 'settings_components.dart';
import 'package:music_theoretically/widgets/fretboard/fretboard_styles.dart' show kNaturalNotes;

class NaturalsPaletteSection extends StatelessWidget {
  final VoidCallback onReset;
  final double scale;
  const NaturalsPaletteSection({
    super.key,
    required this.onReset,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final naturalColors = settings.naturalColors;

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Note Colors (Naturals)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(onPressed: onReset, child: const Text('Reset')),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kNaturalNotes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // layout: 3 columns, 3-3-1 visually
            childAspectRatio: isLandscape ? 4.0 : 2.8, // Base ratio for portrait mode
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, i) {
            final note = kNaturalNotes[i];
            final color = naturalColors[note]!;
            return NoteColorTile(
              note: note,
              color: color,
              scale: scale,
              onTap: () async {
                final picked = await showDialog<Color>(
                  context: context,
                  builder: (_) => ColorPickerDialog(
                    initial: color,
                    title: 'Pick color for $note',
                  ),
                );
                if (picked != null) {
                  settings.setNaturalColor(note, picked);
                }
              },
            );
          },
        ),
      ],
    );
  }
}

class HighlightColorsSection extends StatelessWidget {
  final VoidCallback onReset;
  final double scale;
  const HighlightColorsSection({
    super.key,
    required this.onReset,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Highlight Colors',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(onPressed: onReset, child: const Text('Reset')),
          ],
        ),
        const SizedBox(height: 8),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isLandscape ? 2 : 1,
            childAspectRatio: isLandscape ? 6.0 : 6.0, // Higher ratio in landscape for shorter buttons
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          children: [
            HighlightColorTile(
              label: 'Root note highlight',
              color: settings.highlightRootColor,
              scale: scale,
              onTap: () async {
                final picked = await showDialog<Color>(
                  context: context,
                  builder: (_) => ColorPickerDialog(
                    initial: settings.highlightRootColor,
                    title: 'Pick root highlight color',
                  ),
                );
                if (picked != null) {
                  settings.setHighlightRootColor(picked);
                }
              },
            ),
            HighlightColorTile(
              label: 'In-scale highlight',
              color: settings.highlightInScaleColor,
              scale: scale,
              onTap: () async {
                final picked = await showDialog<Color>(
                  context: context,
                  builder: (_) => ColorPickerDialog(
                    initial: settings.highlightInScaleColor,
                    title: 'Pick in-scale highlight color',
                  ),
                );
                if (picked != null) {
                  settings.setHighlightInScaleColor(picked);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class FretboardMarkersSection extends StatelessWidget {
  final VoidCallback onReset;
  final double scale;
  const FretboardMarkersSection({
    super.key,
    required this.onReset,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Fretboard Markers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(onPressed: onReset, child: const Text('Reset')),
          ],
        ),
        const SizedBox(height: 8),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            childAspectRatio: isLandscape ? 12.0 : 6.0, // Double the landscape ratio since we're using single column
            mainAxisSpacing: 8,
          ),
          children: [
            NoteColorTile(
              note: 'Roman numerals',
              color: settings.markerRomanColor,
              scale: scale,
              onTap: () async {
                final picked = await showDialog<Color>(
                  context: context,
                  builder: (_) => ColorPickerDialog(
                    initial: settings.markerRomanColor,
                    title: 'Pick Roman numeral color',
                  ),
                );
                if (picked != null) {
                  settings.setMarkerRomanColor(picked);
                }
              },
            ),
            NoteColorTile(
              note: 'Numeric frets',
              color: settings.markerNumericColor,
              scale: scale,
              onTap: () async {
                final picked = await showDialog<Color>(
                  context: context,
                  builder: (_) => ColorPickerDialog(
                    initial: settings.markerNumericColor,
                    title: 'Pick numeric fret color',
                  ),
                );
                if (picked != null) {
                  settings.setMarkerNumericColor(picked);
                }
              },
            ),
            NoteColorTile(
              note: 'Inlay dot color',
              color: settings.inlayDotColor,
              scale: scale,
              onTap: () async {
                final picked = await showDialog<Color>(
                  context: context,
                  builder: (_) => ColorPickerDialog(
                    initial: settings.inlayDotColor,
                    title: 'Pick inlay dot color',
                  ),
                );
                if (picked != null) {
                  settings.setInlayDotColor(picked);
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
