// Represents a position on the fretboard to highlight for chord diagrams
class ChordPosition {
  /// 0 = low E (6th) ... 5 = high E (1st)
  final int stringIndex;
  /// Absolute fret number. 0 = open string
  final int fret;
  /// The note at this position (e.g., 'C', 'F#')
  final String note;

  const ChordPosition({
    required this.stringIndex,
    required this.fret,
    required this.note,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChordPosition &&
          runtimeType == other.runtimeType &&
          stringIndex == other.stringIndex &&
          fret == other.fret;

  @override
  int get hashCode => Object.hash(stringIndex, fret);
}
