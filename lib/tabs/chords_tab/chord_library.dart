// ============================
// lib/widgets/chords_tab/chord_library.dart
// ============================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show BuildContext, Color; // need BuildContext for AppSettingsScope
import 'package:music_theoretically/state/app_settings.dart'; // ⬅️ adjust path to your app_settings.dart

/// Note names used across the app. Keep enharmonics simple for v1.
const List<String> kChromatic = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
];

/// Standard tuning low→high (6→1). Only pitch class is needed for colors.
const List<String> kStandardTuning = ['E', 'A', 'D', 'G', 'B', 'E'];

int _noteIndex(String note) => kChromatic.indexOf(note);

String _pcAt(String openNote, int absFret) {
  final base = _noteIndex(openNote);
  if (base < 0) return openNote; // fallback if unknown
  return kChromatic[(base + absFret) % 12];
}

/// Calculates the notes in a chord given a root note and quality
Set<String> getChordNotes(String root, List<int> intervals) {
  final rootIndex = _noteIndex(root);
  if (rootIndex < 0) return {};
  return intervals
      .map((i) => kChromatic[(rootIndex + (i % 12)) % 12])
      .toSet();
}

/// Chord qualities we’ll support initially. Extend as needed.
enum ChordQuality {
  maj,
  min,
  dim,
  aug,
  sus2,
  sus4,
  six,
  m6,
  seven,
  m7,
  maj7,
}

@immutable
class Position {
  /// 0 = low E (6th) … 5 = high E (1st)
  final int stringIndex;
  /// Fret relative to the 5-fret window.
  /// 0 = open, >=1 = within window. If muted==true, this may be ignored.
  final int fretRelative;
  final int? finger; // 1..4 or null
  final bool muted;

  const Position({
    required this.stringIndex,
    required this.fretRelative,
    this.finger,
    this.muted = false,
  });
}

@immutable
class Barre {
  /// Inclusive string span (low index ≤ high index). Use 0..5.
  final int fromString;
  final int toStringIndex; // renamed from `toString` to avoid Object.toString clash
  /// Fret relative to window (>=1 typically). Finger performing the barre.
  final int fretRelative;
  final int? finger;

  const Barre({
    required this.fromString,
    required this.toStringIndex,
    required this.fretRelative,
    this.finger,
  });
}

@immutable
class ChordVoicing {
  /// The 5-fret diagram’s base fret (1 = includes nut, e.g., open positions).
  final int baseFret;
  /// Positions across strings. Prefer to list all 6 strings for clarity.
  final List<Position> positions;
  final List<Barre> barres;
  /// Optional label, e.g. "E-shape @ 5th" or "Open"
  final String? label;
  /// Optional index of the string containing the root (for accent styling)
  final int? rootStringIndex;

  const ChordVoicing({
    required this.baseFret,
    required this.positions,
    this.barres = const [],
    this.label,
    this.rootStringIndex,
  });
}

@immutable
class ChordDefinition {
  final String root; // e.g., 'C'
  final ChordQuality quality;
  final List<ChordVoicing> voicings;

  const ChordDefinition({
    required this.root,
    required this.quality,
    required this.voicings,
  });
}

/// Convert a relative fret to absolute fret number on the neck for rendering
/// or coloration. baseFret=1 means window starts at nut.
int relativeToAbsoluteFret({required int baseFret, required int fretRelative}) {
  if (fretRelative <= 0) return fretRelative; // 0=open stays 0
  return baseFret == 1 ? fretRelative : (baseFret + fretRelative - 1);
}

/// For a given voicing, compute the pitch classes per string in standard tuning.
/// Returns a list of nullable note names for strings 0..5 (low→high).
List<String?> pitchClassesForVoicing(
  ChordVoicing v, {
  List<String> tuning = kStandardTuning,
}) {
  final pc = List<String?>.filled(6, null);
  for (final p in v.positions) {
    if (p.muted) {
      pc[p.stringIndex] = null;
      continue;
    }
    final abs = relativeToAbsoluteFret(baseFret: v.baseFret, fretRelative: p.fretRelative);
    if (p.fretRelative == 0) {
      pc[p.stringIndex] = tuning[p.stringIndex];
    } else {
      pc[p.stringIndex] = _pcAt(tuning[p.stringIndex], abs);
    }
  }
  return pc;
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Colors — rely ONLY on AppSettings
/// ─────────────────────────────────────────────────────────────────────────────

/// UI-friendly resolver (when you have a BuildContext).
Color colorForNote(BuildContext context, String? note) {
  if (note == null) return const Color(0xFF999999);
  return AppSettingsScope.of(context).colorFor(note);
}

/// Non-UI resolver (when you already hold an AppSettings instance).
Color colorForNoteFromSettings(AppSettings settings, String? note) {
  if (note == null) return const Color(0xFF999999);
  return settings.colorFor(note);
}

/// Text color chosen for legibility against the note’s fill color.
Color textColorForNote(BuildContext context, String? note) {
  final bg = colorForNote(context, note);
  return bg.computeLuminance() > 0.5 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
}

/// --- Seed Data (example) -------------------------------------------------
const ChordDefinition seedCmaj = ChordDefinition(
  root: 'C',
  quality: ChordQuality.maj,
  voicings: [
    // Open C
    ChordVoicing(
      baseFret: 1,
      label: 'Open',
      rootStringIndex: 4, // A-string root in pitch terms
      positions: [
        Position(stringIndex: 0, fretRelative: 0, muted: true), // low E muted
        Position(stringIndex: 1, fretRelative: 3, finger: 3),
        Position(stringIndex: 2, fretRelative: 2, finger: 2),
        Position(stringIndex: 3, fretRelative: 0),
        Position(stringIndex: 4, fretRelative: 1, finger: 1),
        Position(stringIndex: 5, fretRelative: 0),
      ],
    ),
    // A-shape barre at 3rd (C major)
    ChordVoicing(
      baseFret: 3,
      label: 'A-shape @ 3rd',
      barres: [Barre(fromString: 1, toStringIndex: 5, fretRelative: 1, finger: 1)],
      positions: [
        Position(stringIndex: 0, fretRelative: 0, muted: true), // often muted
        Position(stringIndex: 1, fretRelative: 1, finger: 1),
        Position(stringIndex: 2, fretRelative: 3, finger: 3),
        Position(stringIndex: 3, fretRelative: 3, finger: 4),
        Position(stringIndex: 4, fretRelative: 2, finger: 2),
        Position(stringIndex: 5, fretRelative: 1, finger: 1),
      ],
    ),
    // E-shape barre at 8th (C major)
    ChordVoicing(
      baseFret: 8,
      label: 'E-shape @ 8th',
      barres: [Barre(fromString: 0, toStringIndex: 5, fretRelative: 1, finger: 1)],
      positions: [
        Position(stringIndex: 0, fretRelative: 1, finger: 1),
        Position(stringIndex: 1, fretRelative: 3, finger: 3),
        Position(stringIndex: 2, fretRelative: 3, finger: 4),
        Position(stringIndex: 3, fretRelative: 2, finger: 2),
        Position(stringIndex: 4, fretRelative: 1, finger: 1),
        Position(stringIndex: 5, fretRelative: 1, finger: 1),
      ],
    ),
  ],
);
