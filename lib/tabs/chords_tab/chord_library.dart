// ============================
// lib/tabs/chords_tab/chord_library.dart
// ============================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show BuildContext, Color; // BuildContext for AppSettingsScope
import 'package:music_theoretically/state/app_settings.dart';

/// Note names used across the app. Keep enharmonics simple for v1.
const List<String> kChromatic = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
];

/// Standard tuning low→high (6→1). Index 0 = low E, 5 = high E.
const List<String> kStandardTuning = ['E', 'A', 'D', 'G', 'B', 'E'];

int _noteIndex(String note) => kChromatic.indexOf(note);

String _pcAt(String openNote, int absFret) {
  final base = _noteIndex(openNote);
  if (base < 0) return openNote; // fallback if unknown
  return kChromatic[(base + absFret) % 12];
}

/// Calculates the pitch classes in a chord given a root note and interval list
Set<String> getChordNotes(String root, List<int> intervals) {
  final rootIndex = _noteIndex(root);
  if (rootIndex < 0) return {};
  return intervals.map((i) => kChromatic[(rootIndex + (i % 12)) % 12]).toSet();
}

/// Chord qualities we’ll support initially. Extend as needed.
enum ChordQuality {
  maj, // major
  min, // minor
  dim, // diminished (triad)
  aug, // augmented (triad)
  sus2,
  sus4,
  six, // major 6th
  m6, // minor 6th
  seven, // dominant 7th
  m7, // minor 7th
  maj7, // major 7th
  m7b5, // half diminished
  dim7, // diminished 7th
  add9,
  mAdd9,
}

/// Interval formulas (in semitones from root) for supported qualities.
const Map<ChordQuality, List<int>> kChordFormulas = {
  ChordQuality.maj: [0, 4, 7],
  ChordQuality.min: [0, 3, 7],
  ChordQuality.dim: [0, 3, 6],
  ChordQuality.aug: [0, 4, 8],
  ChordQuality.sus2: [0, 2, 7],
  ChordQuality.sus4: [0, 5, 7],
  ChordQuality.six: [0, 4, 7, 9],
  ChordQuality.m6: [0, 3, 7, 9],
  ChordQuality.seven: [0, 4, 7, 10], // dominant 7th
  ChordQuality.m7: [0, 3, 7, 10],
  ChordQuality.maj7: [0, 4, 7, 11],
  ChordQuality.m7b5: [0, 3, 6, 10],
  ChordQuality.dim7: [0, 3, 6, 9],
  ChordQuality.add9: [0, 4, 7, 14],
  ChordQuality.mAdd9: [0, 3, 7, 14],
};

@immutable
class Position {
  /// 0 = low E (6th string) … 5 = high E (1st string)
  final int stringIndex;

  /// Fret relative to the 5-fret window. 0 = open, >=1 = within window.
  /// If [muted] is true, this may be ignored.
  final int fretRelative;

  /// Optional finger number 1..4
  final int? finger;

  /// If true, string is not played ("x").
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

  /// Renamed from `toString` to avoid clashing with Object.toString.
  final int toStringIndex;

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
  /// The 5-fret diagram’s base fret (1 = includes nut / open area).
  final int baseFret;

  /// Positions across strings. Prefer to list all 6 strings for clarity.
  final List<Position> positions;

  final List<Barre> barres;

  /// Optional label, e.g. "E-shape @ 3rd" or "Open".
  final String? label;

  /// Optional index (0..5) of the string containing the chord root.
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

// -----------------------
// Voicing generator (fallback for missing entries)
// -----------------------

/// Generate simple voicings for a given root and interval set.
/// This is a best-effort generator used when the seed library doesn't
/// include explicit shapes (used for diminished triads).
List<ChordVoicing> _generateVoicingsFor(String root, List<int> intervals,
  {int maxVoicings = 6, int maxBaseFret = 8}) {
  final result = <ChordVoicing>[];
  final targetPcs = getChordNotes(root, intervals);

  // Try a few base frets and search for compact 5-fret-window shapes.
  for (var base = 1; base <= maxBaseFret && result.length < maxVoicings; base++) {
    // Backtracking across 6 strings. Options per string: muted, open(0), 1..5
    void backtrack(int si, List<Position> acc, int playedCount, int? minRel, int? maxRel) {
      if (result.length >= maxVoicings) return;
      if (si == 6) {
        if (playedCount < 3) return;

        final voicing = ChordVoicing(baseFret: base, positions: List.unmodifiable(acc));
        final pcs = pitchClassesForVoicing(voicing).whereType<String>().toSet();
        // require that the voicing includes all chord pitch classes
        if (!targetPcs.every((p) => pcs.contains(p))) return;

        // prefer voicings that contain the root pitch class
        final rootPresent = pcs.contains(root);
        if (!rootPresent) return;

        // ensure uniqueness by pitch-class layout
    if (result.any((r) =>
      pitchClassesForVoicing(r).whereType<String>().toSet().join(',') == pcs.join(','))) return;

        result.add(voicing);
        return;
      }

      // Try muted
      acc.add(Position(stringIndex: si, fretRelative: 0, muted: true));
      backtrack(si + 1, acc, playedCount, minRel, maxRel);
      acc.removeLast();

      // Try open string (0)
      acc.add(Position(stringIndex: si, fretRelative: 0));
      final abs0 = _pcAt(kStandardTuning[si], 0);
      if (targetPcs.contains(abs0)) {
        backtrack(si + 1, acc, playedCount + 1, minRel, maxRel);
      }
      acc.removeLast();

      // Try fretted positions relative 1..5
      for (var r = 1; r <= 5; r++) {
        // prune windows larger than 5 frets (relative positions)
        final newMin = (minRel == null) ? r : (r < minRel ? r : minRel);
        final newMax = (maxRel == null) ? r : (r > maxRel ? r : maxRel);
        if (newMax - newMin > 4) continue;

        final abs = relativeToAbsoluteFret(baseFret: base, fretRelative: r);
        final pc = _pcAt(kStandardTuning[si], abs);
        if (!targetPcs.contains(pc)) continue;

        acc.add(Position(stringIndex: si, fretRelative: r));
        backtrack(si + 1, acc, playedCount + 1, newMin, newMax);
        acc.removeLast();
      }
    }

    backtrack(0, <Position>[], 0, null, null);
  }

  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// Colors — rely ONLY on AppSettings
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Seed Library — Root → Quality → Definition (with multiple voicings)
// Keep the starter set sane; expand over time.
// String indices: 0=lowE, 1=A, 2=D, 3=G, 4=B, 5=highE
// ─────────────────────────────────────────────────────────────────────────────

final Map<String, Map<ChordQuality, ChordDefinition>> chordLibrary = {
  // ===================== C CHORDS =====================
  'C': {
    // C major
    ChordQuality.maj: ChordDefinition(
      root: 'C',
      quality: ChordQuality.maj,
      voicings: [
        // Open C: x 3 2 0 1 0
        ChordVoicing(
          baseFret: 1,
          label: 'Open',
          rootStringIndex: 1, // A-string C
          positions: const [
            Position(stringIndex: 0, fretRelative: 0, muted: true), // x
            Position(stringIndex: 1, fretRelative: 3, finger: 3),
            Position(stringIndex: 2, fretRelative: 2, finger: 2),
            Position(stringIndex: 3, fretRelative: 0),
            Position(stringIndex: 4, fretRelative: 1, finger: 1),
            Position(stringIndex: 5, fretRelative: 0),
          ],
        ),
        // A-shape barre @ 3rd: x 3 5 5 5 3
        ChordVoicing(
          baseFret: 3,
          label: 'A-shape @ 3rd',
          barres: const [Barre(fromString: 1, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: const [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 1, finger: 1),
            Position(stringIndex: 2, fretRelative: 3, finger: 3),
            Position(stringIndex: 3, fretRelative: 3, finger: 4),
            Position(stringIndex: 4, fretRelative: 3, finger: 2),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
        // E-shape barre @ 8th: 8 10 10 9 8 8
        ChordVoicing(
          baseFret: 8,
          label: 'E-shape @ 8th',
          barres: const [Barre(fromString: 0, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: const [
            Position(stringIndex: 0, fretRelative: 1, finger: 1),
            Position(stringIndex: 1, fretRelative: 3, finger: 3),
            Position(stringIndex: 2, fretRelative: 3, finger: 4),
            Position(stringIndex: 3, fretRelative: 2, finger: 2),
            Position(stringIndex: 4, fretRelative: 1, finger: 1),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
      ],
    ),

    // C minor (barre shapes)
    ChordQuality.min: ChordDefinition(
      root: 'C',
      quality: ChordQuality.min,
      voicings: const [
        // A-shape min @ 3rd: x 3 5 5 4 3
        ChordVoicing(
          baseFret: 3,
          label: 'Am-shape @ 3rd',
          barres: [Barre(fromString: 1, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 1, finger: 1),
            Position(stringIndex: 2, fretRelative: 3, finger: 3),
            Position(stringIndex: 3, fretRelative: 3, finger: 4),
            Position(stringIndex: 4, fretRelative: 2, finger: 2),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
        // Em-shape @ 8th: 8 10 10 8 8 8
        ChordVoicing(
          baseFret: 8,
          label: 'Em-shape @ 8th',
          barres: [Barre(fromString: 0, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: [
            Position(stringIndex: 0, fretRelative: 1, finger: 1),
            Position(stringIndex: 1, fretRelative: 3, finger: 3),
            Position(stringIndex: 2, fretRelative: 3, finger: 4),
            Position(stringIndex: 3, fretRelative: 1, finger: 1),
            Position(stringIndex: 4, fretRelative: 1, finger: 1),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
      ],
    ),

    // C7 (dominant) — x 3 2 3 1 0
    ChordQuality.seven: ChordDefinition(
      root: 'C',
      quality: ChordQuality.seven,
      voicings: const [
        ChordVoicing(
          baseFret: 1,
          label: 'Open 7',
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 3, finger: 3),
            Position(stringIndex: 2, fretRelative: 2, finger: 2),
            Position(stringIndex: 3, fretRelative: 3, finger: 4),
            Position(stringIndex: 4, fretRelative: 1, finger: 1),
            Position(stringIndex: 5, fretRelative: 0),
          ],
        ),
      ],
    ),
    // C diminished (curated)
    ChordQuality.dim: ChordDefinition(
      root: 'C',
      quality: ChordQuality.dim,
      voicings: const [
        // compact open-ish shape
        ChordVoicing(
          baseFret: 1,
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 0, muted: true),
            Position(stringIndex: 2, fretRelative: 0, muted: true),
            Position(stringIndex: 3, fretRelative: 5, finger: 3),
            Position(stringIndex: 4, fretRelative: 4, finger: 2),
            Position(stringIndex: 5, fretRelative: 2, finger: 1),
          ],
        ),
        // triad with partial mutes
        ChordVoicing(
          baseFret: 1,
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 0, muted: true),
            Position(stringIndex: 2, fretRelative: 1, finger: 1),
            Position(stringIndex: 3, fretRelative: 0, muted: true),
            Position(stringIndex: 4, fretRelative: 1, finger: 1),
            Position(stringIndex: 5, fretRelative: 2, finger: 2),
          ],
        ),
        // barre-like upper voicing
        ChordVoicing(
          baseFret: 1,
          positions: [
            Position(stringIndex: 0, fretRelative: 2, finger: 1),
            Position(stringIndex: 1, fretRelative: 0, muted: true),
            Position(stringIndex: 2, fretRelative: 1, finger: 2),
            Position(stringIndex: 3, fretRelative: 0, muted: true),
            Position(stringIndex: 4, fretRelative: 1, finger: 1),
            Position(stringIndex: 5, fretRelative: 0, muted: true),
          ],
        ),
      ],
    ),
  },
  // ===================== D# CHORDS =====================
  'D#': {
    ChordQuality.maj: ChordDefinition(
      root: 'D#',
      quality: ChordQuality.maj,
      voicings: const [
        // A-shape barre @ 6th: x 6 8 8 8 6
        ChordVoicing(
          baseFret: 6,
          label: 'A-shape @ 6th',
          barres: [Barre(fromString: 1, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 1, finger: 1),
            Position(stringIndex: 2, fretRelative: 3, finger: 3),
            Position(stringIndex: 3, fretRelative: 3, finger: 4),
            Position(stringIndex: 4, fretRelative: 3, finger: 2),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
      ],
    ),
    ChordQuality.min: ChordDefinition(
      root: 'D#',
      quality: ChordQuality.min,
      voicings: const [
        // Am-shape minor @ 6th: x 6 8 8 7 6
        ChordVoicing(
          baseFret: 6,
          label: 'Am-shape @ 6th',
          barres: [Barre(fromString: 1, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 1, finger: 1),
            Position(stringIndex: 2, fretRelative: 3, finger: 3),
            Position(stringIndex: 3, fretRelative: 3, finger: 4),
            Position(stringIndex: 4, fretRelative: 2, finger: 2),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
      ],
    ),
  },

  // ===================== F# CHORDS =====================
  'F#': {
    ChordQuality.maj: ChordDefinition(
      root: 'F#',
      quality: ChordQuality.maj,
      voicings: const [
        // E-shape barre @ 2nd: 2 4 4 3 2 2 (F#)
        ChordVoicing(
          baseFret: 2,
          label: 'E-shape @ 2nd',
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
    ),
    ChordQuality.min: ChordDefinition(
      root: 'F#',
      quality: ChordQuality.min,
      voicings: const [
        // Em-shape minor @ 2nd: 2 4 4 2 2 2
        ChordVoicing(
          baseFret: 2,
          label: 'Em-shape @ 2nd',
          barres: [Barre(fromString: 0, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: [
            Position(stringIndex: 0, fretRelative: 1, finger: 1),
            Position(stringIndex: 1, fretRelative: 3, finger: 3),
            Position(stringIndex: 2, fretRelative: 3, finger: 4),
            Position(stringIndex: 3, fretRelative: 1, finger: 1),
            Position(stringIndex: 4, fretRelative: 1, finger: 1),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
      ],
    ),
  },

  // ===================== G# CHORDS =====================
  'G#': {
    ChordQuality.maj: ChordDefinition(
      root: 'G#',
      quality: ChordQuality.maj,
      voicings: const [
        // A-shape barre @ 1st (x 1 3 3 3 1) moved up: x 1 3 3 3 1 -> baseFret 1 is G# (enharmonic to Ab)
        ChordVoicing(
          baseFret: 1,
          label: 'A-shape @ 1st',
          barres: [Barre(fromString: 1, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 1, finger: 1),
            Position(stringIndex: 2, fretRelative: 3, finger: 3),
            Position(stringIndex: 3, fretRelative: 3, finger: 4),
            Position(stringIndex: 4, fretRelative: 3, finger: 2),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
      ],
    ),
    ChordQuality.min: ChordDefinition(
      root: 'G#',
      quality: ChordQuality.min,
      voicings: const [
        // Am-shape minor @ 1st: x 1 3 3 2 1
        ChordVoicing(
          baseFret: 1,
          label: 'Am-shape @ 1st',
          barres: [Barre(fromString: 1, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 1, finger: 1),
            Position(stringIndex: 2, fretRelative: 3, finger: 3),
            Position(stringIndex: 3, fretRelative: 3, finger: 4),
            Position(stringIndex: 4, fretRelative: 2, finger: 2),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
      ],
    ),
  },

  // ===================== A# CHORDS =====================
  'A#': {
    ChordQuality.maj: ChordDefinition(
      root: 'A#',
      quality: ChordQuality.maj,
      voicings: const [
        // A-shape barre @ 3rd: x 3 5 5 5 3 (A# / Bb)
        ChordVoicing(
          baseFret: 3,
          label: 'A-shape @ 3rd',
          barres: [Barre(fromString: 1, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 1, finger: 1),
            Position(stringIndex: 2, fretRelative: 3, finger: 3),
            Position(stringIndex: 3, fretRelative: 3, finger: 4),
            Position(stringIndex: 4, fretRelative: 3, finger: 2),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
      ],
    ),
    ChordQuality.min: ChordDefinition(
      root: 'A#',
      quality: ChordQuality.min,
      voicings: const [
        // Am-shape minor @ 3rd: x 3 5 5 4 3
        ChordVoicing(
          baseFret: 3,
          label: 'Am-shape @ 3rd',
          barres: [Barre(fromString: 1, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 1, finger: 1),
            Position(stringIndex: 2, fretRelative: 3, finger: 3),
            Position(stringIndex: 3, fretRelative: 3, finger: 4),
            Position(stringIndex: 4, fretRelative: 2, finger: 2),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
      ],
    ),
  },

  // ===================== C# CHORDS =====================
  'C#': {
    // C# major (curated voicings)
    ChordQuality.maj: ChordDefinition(
      root: 'C#',
      quality: ChordQuality.maj,
      voicings: const [
        // A-shape barre @ 4th: x 4 6 6 6 4
        ChordVoicing(
          baseFret: 4,
          label: 'A-shape @ 4th',
          barres: [Barre(fromString: 1, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 1, finger: 1),
            Position(stringIndex: 2, fretRelative: 3, finger: 3),
            Position(stringIndex: 3, fretRelative: 3, finger: 4),
            Position(stringIndex: 4, fretRelative: 3, finger: 2),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),

        // E-shape barre @ 9th: 9 11 11 10 9 9
        ChordVoicing(
          baseFret: 9,
          label: 'E-shape @ 9th',
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
    ),
  },

  // ===================== D CHORDS =====================
  'D': {
    // D major: x x 0 2 3 2
    ChordQuality.maj: ChordDefinition(
      root: 'D',
      quality: ChordQuality.maj,
      voicings: const [
        ChordVoicing(
          baseFret: 1,
          label: 'Open',
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 0, muted: true),
            Position(stringIndex: 2, fretRelative: 0),
            Position(stringIndex: 3, fretRelative: 2, finger: 1),
            Position(stringIndex: 4, fretRelative: 3, finger: 3),
            Position(stringIndex: 5, fretRelative: 2, finger: 2),
          ],
        ),
        // A-shape @ 5th: x 5 7 7 7 5
        ChordVoicing(
          baseFret: 5,
          label: 'A-shape @ 5th',
          barres: [Barre(fromString: 1, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 1, finger: 1),
            Position(stringIndex: 2, fretRelative: 3, finger: 3),
            Position(stringIndex: 3, fretRelative: 3, finger: 4),
            Position(stringIndex: 4, fretRelative: 3, finger: 2),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
        // E-shape @ 10th: 10 12 12 11 10 10
        ChordVoicing(
          baseFret: 10,
          label: 'E-shape @ 10th',
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
    ),

    // D minor: x x 0 2 3 1
    ChordQuality.min: ChordDefinition(
      root: 'D',
      quality: ChordQuality.min,
      voicings: const [
        ChordVoicing(
          baseFret: 1,
          label: 'Open',
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 0, muted: true),
            Position(stringIndex: 2, fretRelative: 0),
            Position(stringIndex: 3, fretRelative: 2, finger: 2),
            Position(stringIndex: 4, fretRelative: 3, finger: 3),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
        // Am-shape @ 5th: x 5 7 7 6 5
        ChordVoicing(
          baseFret: 5,
          label: 'Am-shape @ 5th',
          barres: [Barre(fromString: 1, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 1, finger: 1),
            Position(stringIndex: 2, fretRelative: 3, finger: 3),
            Position(stringIndex: 3, fretRelative: 3, finger: 4),
            Position(stringIndex: 4, fretRelative: 2, finger: 2),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
      ],
    ),

    // D7: x x 0 2 1 2
    ChordQuality.seven: ChordDefinition(
      root: 'D',
      quality: ChordQuality.seven,
      voicings: const [
        ChordVoicing(
          baseFret: 1,
          label: 'Open 7',
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 0, muted: true),
            Position(stringIndex: 2, fretRelative: 0),
            Position(stringIndex: 3, fretRelative: 2, finger: 2),
            Position(stringIndex: 4, fretRelative: 1, finger: 1),
            Position(stringIndex: 5, fretRelative: 2, finger: 3),
          ],
        ),
      ],
    ),
    // D diminished (curated)
    ChordQuality.dim: ChordDefinition(
      root: 'D',
      quality: ChordQuality.dim,
      voicings: const [
        ChordVoicing(
          baseFret: 1,
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 0, muted: true),
            Position(stringIndex: 2, fretRelative: 0, muted: true),
            Position(stringIndex: 3, fretRelative: 1, finger: 1),
            Position(stringIndex: 4, fretRelative: 3, finger: 3),
            Position(stringIndex: 5, fretRelative: 1, finger: 2),
          ],
        ),
        ChordVoicing(
          baseFret: 1,
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 0, muted: true),
            Position(stringIndex: 2, fretRelative: 0),
            Position(stringIndex: 3, fretRelative: 1, finger: 1),
            Position(stringIndex: 4, fretRelative: 0, muted: true),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
        ChordVoicing(
          baseFret: 1,
          positions: [
            Position(stringIndex: 0, fretRelative: 4, finger: 3),
            Position(stringIndex: 1, fretRelative: 0, muted: true),
            Position(stringIndex: 2, fretRelative: 3, finger: 2),
            Position(stringIndex: 3, fretRelative: 0, muted: true),
            Position(stringIndex: 4, fretRelative: 3, finger: 4),
            Position(stringIndex: 5, fretRelative: 0, muted: true),
          ],
        ),
      ],
    ),
  },

  // ===================== E CHORDS =====================
  'E': {
    // E major: 0 2 2 1 0 0
    ChordQuality.maj: ChordDefinition(
      root: 'E',
      quality: ChordQuality.maj,
      voicings: const [
        ChordVoicing(
          baseFret: 1,
          label: 'Open',
          positions: [
            Position(stringIndex: 0, fretRelative: 0),
            Position(stringIndex: 1, fretRelative: 2, finger: 2),
            Position(stringIndex: 2, fretRelative: 2, finger: 3),
            Position(stringIndex: 3, fretRelative: 1, finger: 1),
            Position(stringIndex: 4, fretRelative: 0),
            Position(stringIndex: 5, fretRelative: 0),
          ],
        ),
        // A-shape @ 7th: x 7 9 9 9 7
        ChordVoicing(
          baseFret: 7,
          label: 'A-shape @ 7th',
          barres: [Barre(fromString: 1, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 1, finger: 1),
            Position(stringIndex: 2, fretRelative: 3, finger: 3),
            Position(stringIndex: 3, fretRelative: 3, finger: 4),
            Position(stringIndex: 4, fretRelative: 3, finger: 2),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
      ],
    ),

    // E minor: 0 2 2 0 0 0
    ChordQuality.min: ChordDefinition(
      root: 'E',
      quality: ChordQuality.min,
      voicings: const [
        ChordVoicing(
          baseFret: 1,
          label: 'Open',
          positions: [
            Position(stringIndex: 0, fretRelative: 0),
            Position(stringIndex: 1, fretRelative: 2, finger: 2),
            Position(stringIndex: 2, fretRelative: 2, finger: 3),
            Position(stringIndex: 3, fretRelative: 0),
            Position(stringIndex: 4, fretRelative: 0),
            Position(stringIndex: 5, fretRelative: 0),
          ],
        ),
      ],
    ),

    // E7: 0 2 0 1 0 0
    ChordQuality.seven: ChordDefinition(
      root: 'E',
      quality: ChordQuality.seven,
      voicings: const [
        ChordVoicing(
          baseFret: 1,
          label: 'Open 7',
          positions: [
            Position(stringIndex: 0, fretRelative: 0),
            Position(stringIndex: 1, fretRelative: 2, finger: 2),
            Position(stringIndex: 2, fretRelative: 0),
            Position(stringIndex: 3, fretRelative: 1, finger: 1),
            Position(stringIndex: 4, fretRelative: 0),
            Position(stringIndex: 5, fretRelative: 0),
          ],
        ),
      ],
    ),
    // E diminished (curated)
    ChordQuality.dim: ChordDefinition(
      root: 'E',
      quality: ChordQuality.dim,
      voicings: const [
        ChordVoicing(
          baseFret: 1,
          positions: [
            Position(stringIndex: 0, fretRelative: 0),
            Position(stringIndex: 1, fretRelative: 0, muted: true),
            Position(stringIndex: 2, fretRelative: 5, finger: 3),
            Position(stringIndex: 3, fretRelative: 3, finger: 2),
            Position(stringIndex: 4, fretRelative: 5, finger: 4),
            Position(stringIndex: 5, fretRelative: 3, finger: 1),
          ],
        ),
        ChordVoicing(
          baseFret: 1,
          positions: [
            Position(stringIndex: 0, fretRelative: 0),
            Position(stringIndex: 1, fretRelative: 0, muted: true),
            Position(stringIndex: 2, fretRelative: 2, finger: 2),
            Position(stringIndex: 3, fretRelative: 3, finger: 3),
            Position(stringIndex: 4, fretRelative: 0, muted: true),
            Position(stringIndex: 5, fretRelative: 3, finger: 1),
          ],
        ),
        ChordVoicing(
          baseFret: 1,
          positions: [
            Position(stringIndex: 0, fretRelative: 3, finger: 2),
            Position(stringIndex: 1, fretRelative: 0, muted: true),
            Position(stringIndex: 2, fretRelative: 2, finger: 1),
            Position(stringIndex: 3, fretRelative: 3, finger: 3),
            Position(stringIndex: 4, fretRelative: 0, muted: true),
            Position(stringIndex: 5, fretRelative: 0, muted: true),
          ],
        ),
      ],
    ),
  },

  // ===================== F CHORDS =====================
  'F': {
    // F major (barre): 1 3 3 2 1 1
    ChordQuality.maj: ChordDefinition(
      root: 'F',
      quality: ChordQuality.maj,
      voicings: const [
        ChordVoicing(
          baseFret: 1,
          label: 'E-shape @ 1st',
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
        // A-shape @ 8th: x 8 10 10 10 8
        ChordVoicing(
          baseFret: 8,
          label: 'A-shape @ 8th',
          barres: [Barre(fromString: 1, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 1, finger: 1),
            Position(stringIndex: 2, fretRelative: 3, finger: 3),
            Position(stringIndex: 3, fretRelative: 3, finger: 4),
            Position(stringIndex: 4, fretRelative: 3, finger: 2),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
      ],
    ),

    // F minor (barre): 1 3 3 1 1 1
    ChordQuality.min: ChordDefinition(
      root: 'F',
      quality: ChordQuality.min,
      voicings: const [
        ChordVoicing(
          baseFret: 1,
          label: 'Em-shape @ 1st',
          barres: [Barre(fromString: 0, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: [
            Position(stringIndex: 0, fretRelative: 1, finger: 1),
            Position(stringIndex: 1, fretRelative: 3, finger: 3),
            Position(stringIndex: 2, fretRelative: 3, finger: 4),
            Position(stringIndex: 3, fretRelative: 1, finger: 1),
            Position(stringIndex: 4, fretRelative: 1, finger: 1),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
      ],
    ),
    // F diminished (curated)
    ChordQuality.dim: ChordDefinition(
      root: 'F',
      quality: ChordQuality.dim,
      voicings: const [
        ChordVoicing(
          baseFret: 1,
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 0, muted: true),
            Position(stringIndex: 2, fretRelative: 0, muted: true),
            Position(stringIndex: 3, fretRelative: 1, finger: 1),
            Position(stringIndex: 4, fretRelative: 0, finger: 1),
            Position(stringIndex: 5, fretRelative: 1, finger: 2),
          ],
        ),
        ChordVoicing(
          baseFret: 1,
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 0, muted: true),
            Position(stringIndex: 2, fretRelative: 3, finger: 3),
            Position(stringIndex: 3, fretRelative: 1, finger: 1),
            Position(stringIndex: 4, fretRelative: 0, muted: true),
            Position(stringIndex: 5, fretRelative: 4, finger: 4),
          ],
        ),
        ChordVoicing(
          baseFret: 1,
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 2, finger: 2),
            Position(stringIndex: 2, fretRelative: 3, finger: 3),
            Position(stringIndex: 3, fretRelative: 0, muted: true),
            Position(stringIndex: 4, fretRelative: 0, muted: true),
            Position(stringIndex: 5, fretRelative: 4, finger: 4),
          ],
        ),
      ],
    ),
  },

  // ===================== G CHORDS =====================
  'G': {
    // G major: 3 2 0 0 0 3
    ChordQuality.maj: ChordDefinition(
      root: 'G',
      quality: ChordQuality.maj,
      voicings: const [
        ChordVoicing(
          baseFret: 1,
          label: 'Open',
          positions: [
            Position(stringIndex: 0, fretRelative: 3, finger: 3),
            Position(stringIndex: 1, fretRelative: 2, finger: 2),
            Position(stringIndex: 2, fretRelative: 0),
            Position(stringIndex: 3, fretRelative: 0),
            Position(stringIndex: 4, fretRelative: 0),
            Position(stringIndex: 5, fretRelative: 3, finger: 4),
          ],
        ),
        // E-shape @ 3rd: 3 5 5 4 3 3
        ChordVoicing(
          baseFret: 3,
          label: 'E-shape @ 3rd',
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
        // A-shape @ 10th: x 10 12 12 12 10
        ChordVoicing(
          baseFret: 10,
          label: 'A-shape @ 10th',
          barres: [Barre(fromString: 1, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 1, finger: 1),
            Position(stringIndex: 2, fretRelative: 3, finger: 3),
            Position(stringIndex: 3, fretRelative: 3, finger: 4),
            Position(stringIndex: 4, fretRelative: 3, finger: 2),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
      ],
    ),

    // G minor (barre only common)
    ChordQuality.min: ChordDefinition(
      root: 'G',
      quality: ChordQuality.min,
      voicings: const [
        // Em-shape @ 3rd: 3 5 5 3 3 3
        ChordVoicing(
          baseFret: 3,
          label: 'Em-shape @ 3rd',
          barres: [Barre(fromString: 0, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: [
            Position(stringIndex: 0, fretRelative: 1, finger: 1),
            Position(stringIndex: 1, fretRelative: 3, finger: 3),
            Position(stringIndex: 2, fretRelative: 3, finger: 4),
            Position(stringIndex: 3, fretRelative: 1, finger: 1),
            Position(stringIndex: 4, fretRelative: 1, finger: 1),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
        // Am-shape @ 10th: x 10 12 12 11 10
        ChordVoicing(
          baseFret: 10,
          label: 'Am-shape @ 10th',
          barres: [Barre(fromString: 1, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 1, finger: 1),
            Position(stringIndex: 2, fretRelative: 3, finger: 3),
            Position(stringIndex: 3, fretRelative: 3, finger: 4),
            Position(stringIndex: 4, fretRelative: 2, finger: 2),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
      ],
    ),

    // G7: 3 2 0 0 0 1
    ChordQuality.seven: ChordDefinition(
      root: 'G',
      quality: ChordQuality.seven,
      voicings: const [
        ChordVoicing(
          baseFret: 1,
          label: 'Open 7',
          positions: [
            Position(stringIndex: 0, fretRelative: 3, finger: 3),
            Position(stringIndex: 1, fretRelative: 2, finger: 2),
            Position(stringIndex: 2, fretRelative: 0),
            Position(stringIndex: 3, fretRelative: 0),
            Position(stringIndex: 4, fretRelative: 0),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
      ],
    ),
    // G diminished (curated)
    ChordQuality.dim: ChordDefinition(
      root: 'G',
      quality: ChordQuality.dim,
      voicings: const [
        ChordVoicing(
          baseFret: 1,
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 0, muted: true),
            Position(stringIndex: 2, fretRelative: 0, muted: true),
            Position(stringIndex: 3, fretRelative: 3, finger: 3),
            Position(stringIndex: 4, fretRelative: 2, finger: 2),
            Position(stringIndex: 5, fretRelative: 3, finger: 4),
          ],
        ),
        ChordVoicing(
          baseFret: 1,
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 0, muted: true),
            Position(stringIndex: 2, fretRelative: 5, finger: 4),
            Position(stringIndex: 3, fretRelative: 3, finger: 2),
            Position(stringIndex: 4, fretRelative: 2, finger: 1),
            Position(stringIndex: 5, fretRelative: 0, muted: true),
          ],
        ),
        ChordVoicing(
          baseFret: 1,
          positions: [
            Position(stringIndex: 0, fretRelative: 3, finger: 3),
            Position(stringIndex: 1, fretRelative: 4, finger: 4),
            Position(stringIndex: 2, fretRelative: 0, muted: true),
            Position(stringIndex: 3, fretRelative: 3, finger: 2),
            Position(stringIndex: 4, fretRelative: 0, muted: true),
            Position(stringIndex: 5, fretRelative: 0, muted: true),
          ],
        ),
      ],
    ),
  },

  // ===================== A CHORDS =====================
  'A': {
    // A major: x 0 2 2 2 0
    ChordQuality.maj: ChordDefinition(
      root: 'A',
      quality: ChordQuality.maj,
      voicings: const [
        ChordVoicing(
          baseFret: 1,
          label: 'Open',
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 0),
            Position(stringIndex: 2, fretRelative: 2, finger: 1),
            Position(stringIndex: 3, fretRelative: 2, finger: 2),
            Position(stringIndex: 4, fretRelative: 2, finger: 3),
            Position(stringIndex: 5, fretRelative: 0),
          ],
        ),
        // E-shape @ 5th: 5 7 7 6 5 5
        ChordVoicing(
          baseFret: 5,
          label: 'E-shape @ 5th',
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
    ),

    // A minor: x 0 2 2 1 0
    ChordQuality.min: ChordDefinition(
      root: 'A',
      quality: ChordQuality.min,
      voicings: const [
        ChordVoicing(
          baseFret: 1,
          label: 'Open',
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 0),
            Position(stringIndex: 2, fretRelative: 2, finger: 2),
            Position(stringIndex: 3, fretRelative: 2, finger: 3),
            Position(stringIndex: 4, fretRelative: 1, finger: 1),
            Position(stringIndex: 5, fretRelative: 0),
          ],
        ),
      ],
    ),

    // A7: x 0 2 0 2 0
    ChordQuality.seven: ChordDefinition(
      root: 'A',
      quality: ChordQuality.seven,
      voicings: const [
        ChordVoicing(
          baseFret: 1,
          label: 'Open 7',
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 0),
            Position(stringIndex: 2, fretRelative: 2, finger: 2),
            Position(stringIndex: 3, fretRelative: 0),
            Position(stringIndex: 4, fretRelative: 2, finger: 3),
            Position(stringIndex: 5, fretRelative: 0),
          ],
        ),
      ],
    ),
    // A diminished (curated)
    ChordQuality.dim: ChordDefinition(
      root: 'A',
      quality: ChordQuality.dim,
      voicings: const [
        ChordVoicing(
          baseFret: 1,
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 0, muted: true),
            Position(stringIndex: 2, fretRelative: 0, muted: true),
            Position(stringIndex: 3, fretRelative: 5, finger: 3),
            Position(stringIndex: 4, fretRelative: 4, finger: 2),
            Position(stringIndex: 5, fretRelative: 5, finger: 4),
          ],
        ),
        ChordVoicing(
          baseFret: 1,
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 0, muted: true),
            Position(stringIndex: 2, fretRelative: 1, finger: 1),
            Position(stringIndex: 3, fretRelative: 0, muted: true),
            Position(stringIndex: 4, fretRelative: 1, finger: 1),
            Position(stringIndex: 5, fretRelative: 5, finger: 4),
          ],
        ),
        ChordVoicing(
          baseFret: 1,
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 3, finger: 3),
            Position(stringIndex: 2, fretRelative: 0, muted: true),
            Position(stringIndex: 3, fretRelative: 2, finger: 2),
            Position(stringIndex: 4, fretRelative: 4, finger: 4),
            Position(stringIndex: 5, fretRelative: 0, muted: true),
          ],
        ),
      ],
    ),
  },

  // ===================== B CHORDS (minimal starter) =====================
  'B': {
    // B major (A-shape @ 2nd): x 2 4 4 4 2
    ChordQuality.maj: ChordDefinition(
      root: 'B',
      quality: ChordQuality.maj,
      voicings: const [
        ChordVoicing(
          baseFret: 2,
          label: 'A-shape @ 2nd',
          barres: [Barre(fromString: 1, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 1, finger: 1),
            Position(stringIndex: 2, fretRelative: 3, finger: 3),
            Position(stringIndex: 3, fretRelative: 3, finger: 4),
            Position(stringIndex: 4, fretRelative: 3, finger: 2),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
      ],
    ),

    // B minor (Am-shape @ 2nd): x 2 4 4 3 2
    ChordQuality.min: ChordDefinition(
      root: 'B',
      quality: ChordQuality.min,
      voicings: const [
        ChordVoicing(
          baseFret: 2,
          label: 'Am-shape @ 2nd',
          barres: [Barre(fromString: 1, toStringIndex: 5, fretRelative: 1, finger: 1)],
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 1, finger: 1),
            Position(stringIndex: 2, fretRelative: 3, finger: 3),
            Position(stringIndex: 3, fretRelative: 3, finger: 4),
            Position(stringIndex: 4, fretRelative: 2, finger: 2),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
      ],
    ),
    // B diminished (curated)
    ChordQuality.dim: ChordDefinition(
      root: 'B',
      quality: ChordQuality.dim,
      voicings: const [
        ChordVoicing(
          baseFret: 1,
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 0, muted: true),
            Position(stringIndex: 2, fretRelative: 0, muted: true),
            Position(stringIndex: 3, fretRelative: 4, finger: 3),
            Position(stringIndex: 4, fretRelative: 3, finger: 2),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
        ChordVoicing(
          baseFret: 1,
          positions: [
            Position(stringIndex: 0, fretRelative: 0, muted: true),
            Position(stringIndex: 1, fretRelative: 0, muted: true),
            Position(stringIndex: 2, fretRelative: 0),
            Position(stringIndex: 3, fretRelative: 0, muted: true),
            Position(stringIndex: 4, fretRelative: 0, muted: true),
            Position(stringIndex: 5, fretRelative: 1, finger: 1),
          ],
        ),
        ChordVoicing(
          baseFret: 1,
          positions: [
            Position(stringIndex: 0, fretRelative: 1, finger: 1),
            Position(stringIndex: 1, fretRelative: 0, muted: true),
            Position(stringIndex: 2, fretRelative: 0, muted: true),
            Position(stringIndex: 3, fretRelative: 0, muted: true),
            Position(stringIndex: 4, fretRelative: 0, muted: true),
            Position(stringIndex: 5, fretRelative: 0, muted: true),
          ],
        ),
      ],
    ),
  },
};

// ─────────────────────────────────────────────────────────────────────────────
// Helpers for consumers
// ─────────────────────────────────────────────────────────────────────────────

ChordDefinition? chordDefinition(String root, ChordQuality q) {
  final existing = chordLibrary[root]?[q];
  if (existing != null) return existing;

  // Fallback for diminished triads: synthesize simple voicings when missing.
  if (q == ChordQuality.dim) {
    final formula = kChordFormulas[q] ?? [0, 3, 6];
    final notes = getChordNotes(root, formula);
    if (notes.isEmpty) return null;
    final generated = _generateVoicingsFor(root, formula);
    if (generated.isEmpty) return null;
    return ChordDefinition(root: root, quality: q, voicings: generated);
  }

  return null;
}

List<ChordVoicing> getVoicings(String root, ChordQuality q) =>
    chordDefinition(root, q)?.voicings ?? const [];

bool hasVoicings(String root, ChordQuality q) =>
    (chordLibrary[root]?[q]?.voicings.isNotEmpty ?? false);
