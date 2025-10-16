import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Public types
/// ─────────────────────────────────────────────────────────────────────────────

/// Simple pair type for sharp/flat gradients (no Dart records needed).
class AccidentalPair {
  final Color base;
  final Color next;
  const AccidentalPair(this.base, this.next);
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Notes and defaults (match fretboard_styles.getNoteColor)
/// ─────────────────────────────────────────────────────────────────────────────

/// Only the seven naturals are user-selectable in Settings.
const List<String> kNaturalNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
final Map<String, Color> kDefaultNaturalColors = {
  'C': Colors.orange.shade800, // orange.800 equivalent in dark scheme
  'D': Colors.red.shade800,
  'E': Colors.purple.shade800,
  'F': Colors.blue.shade800,
  'G': Colors.green.shade900, // already dark in your mapping
  'A': Colors.lightGreen.shade800,
  'B': Colors.yellow.shade800,
};

/// ─────────────────────────────────────────────────────────────────────────────
/// Global Settings (ChangeNotifier + InheritedNotifier scope)
/// ─────────────────────────────────────────────────────────────────────────────

class AppSettings extends ChangeNotifier {
  AppSettings({Map<String, Color>? initial})
      : _naturalColors = Map<String, Color>.from(
          initial ?? kDefaultNaturalColors,
        );

  Map<String, Color> _naturalColors;

  /// Read-only colors for Settings UI.
  Map<String, Color> get naturalColors => Map.unmodifiable(_naturalColors);

  /// Public color accessor for ANY note string.
  /// Naturals -> direct color; Accidentals -> base natural’s color.
  Color colorFor(String note) {
    final nat = _asNaturalOrBase(note);
    return _naturalColors[nat] ??
        kDefaultNaturalColors[nat] ??
        Colors.grey.shade700;
  }

  /// Update color for a natural note (C, D, E, F, G, A, B).
  void setNaturalColor(String natural, Color color) {
    final n = _normalizeNatural(natural);
    if (!_naturalColors.containsKey(n)) return;
    if (_naturalColors[n] == color) return;
    _naturalColors = {..._naturalColors, n: color};
    notifyListeners();
  }

  /// Reset all naturals to defaults.
  void resetToDefaults() {
    _naturalColors = Map<String, Color>.from(kDefaultNaturalColors);
    notifyListeners();
  }

  /// For sharp/flat tiles: return (base, next) natural colors.
  /// Examples:
  ///  - 'C#' or 'Db' -> (C, D)
  ///  - 'F#' or 'Gb' -> (F, G)
  ///  - 'Bb'         -> (A, B)
  /// If a natural is passed, returns (natural, nextNatural).
  AccidentalPair gradientPairForAccidental(String note) {
    final baseNat = _baseNaturalForAccidental(note);
    final nextNat = _nextNatural(baseNat);
    return AccidentalPair(colorFor(baseNat), colorFor(nextNat));
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Internals
  // ───────────────────────────────────────────────────────────────────────────

  /// Map any input to a natural:
  ///  - Naturals -> itself
  ///  - Sharps   -> natural before '#': C# -> C
  ///  - Flats    -> previous natural:   Db -> C
  String _asNaturalOrBase(String note) {
    final t = note.trim().toUpperCase();
    if (kNaturalNotes.contains(t)) return t;

    // Sharp: X# -> base X (e.g., C# -> C)
    if (t.endsWith('#') && t.length >= 2) {
      final base = t.substring(0, t.length - 1);
      return _normalizeNatural(base);
    }

    // Flat: Xb -> previous natural (e.g., Db -> C)
    if (t.endsWith('B') && t.length >= 2) {
      final root = t.substring(0, t.length - 1);
      return _prevNatural(_normalizeNatural(root));
    }

    // Fallback: best-effort normalize to a natural
    return _normalizeNatural(t);
  }

  /// For an accidental like 'C#'/'Db', returns the base natural ('C' here).
  /// If a natural is given, just returns that natural.
  String _baseNaturalForAccidental(String note) => _asNaturalOrBase(note);

  String _normalizeNatural(String s) {
    final up = s.toUpperCase();
    return kNaturalNotes.contains(up) ? up : 'C';
  }

  String _nextNatural(String nat) {
    const order = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    final i = order.indexOf(nat);
    return i < 0 ? 'D' : order[(i + 1) % order.length];
  }

  String _prevNatural(String nat) {
    const order = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    final i = order.indexOf(nat);
    return i < 0 ? 'B' : order[(i + order.length - 1) % order.length];
  }
}

/// Lightweight global provider.
/// Wrap your app (or at least any screen that renders the fretboard) in this.
class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    super.key,
    required AppSettings notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  /// Strict accessor: asserts the scope exists.
  static AppSettings of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope not found in the widget tree.');
    return scope!.notifier!;
  }

  /// Safe accessor: returns null if the scope is not mounted.
  static AppSettings? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>()
        ?.notifier;
  }
}
