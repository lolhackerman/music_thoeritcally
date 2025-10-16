// import 'package:flutter/foundation.dart';
// import 'chord_library.dart';

// @immutable
// class FretDot {
//   final int stringIndex; // 0 = low E … 5 = high E
//   final int absFret;     // 0 = open, >=1 = fretted
//   final String? note;    // pitch class like 'C', 'D#'
//   final int? finger;     // 1..4 (optional)
//   final bool muted;      // true => render X at nut for this string

//   const FretDot({
//     required this.stringIndex,
//     required this.absFret,
//     required this.note,
//     this.finger,
//     this.muted = false,
//   });
// }

// @immutable
// class BarreOverlay {
//   final int fromStringIndex; // inclusive
//   final int toStringIndex;   // inclusive
//   final int absFret;         // absolute fret where the barre lies
//   final int? finger;         // 1..4 (optional)

//   const BarreOverlay({
//     required this.fromStringIndex,
//     required this.toStringIndex,
//     required this.absFret,
//     this.finger,
//   });
// }

// @immutable
// class ChordOverlay {
//   final List<FretDot> dots;
//   final List<BarreOverlay> barres;

//   const ChordOverlay({required this.dots, required this.barres});
// }

// /// Convert a ChordVoicing into a render-ready overlay.
// ChordOverlay voicingToOverlay(
//   ChordVoicing v, {
//   List<String> tuning = kStandardTuning,
// }) {
//   final pcs = pitchClassesForVoicing(v, tuning: tuning);

//   final dots = <FretDot>[];
//   for (final p in v.positions) {
//     final abs = relativeToAbsoluteFret(baseFret: v.baseFret, fretRelative: p.fretRelative);
//     dots.add(FretDot(
//       stringIndex: p.stringIndex,
//       absFret: abs,
//       note: pcs[p.stringIndex],
//       finger: p.finger,
//       muted: p.muted,
//     ));
//   }

//   final barres = <BarreOverlay>[
//     for (final b in v.barres)
//       BarreOverlay(
//         fromStringIndex: b.fromString,
//         toStringIndex: b.toStringIndex,
//         absFret: relativeToAbsoluteFret(baseFret: v.baseFret, fretRelative: b.fretRelative),
//         finger: b.finger,
//       ),
//   ];

//   return ChordOverlay(dots: dots, barres: barres);
// }
