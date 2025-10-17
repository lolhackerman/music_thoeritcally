import 'package:flutter/foundation.dart';

@immutable
class FretSpot {
  /// 0 = low E (6th string), 5 = high E (1st string)
  final int string;
  /// 0 = open, 1..22 = fret
  final int fret;
  /// Whether this spot is a root note
  final bool isRoot;

  const FretSpot({
    required this.string,
    required this.fret,
    this.isRoot = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FretSpot &&
          string == other.string &&
          fret == other.fret;

  @override
  int get hashCode => Object.hash(string, fret);
}
