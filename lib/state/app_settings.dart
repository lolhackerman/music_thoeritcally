import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Public types
/// ─────────────────────────────────────────────────────────────────────────────

class AccidentalPair {
  final Color base;
  final Color next;
  const AccidentalPair(this.base, this.next);
}

/// Notes and defaults
const List<String> kNaturalNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];

final Map<String, Color> kDefaultNaturalColors = {
  'C': Colors.orange.shade800,
  'D': Colors.red.shade800,
  'E': Colors.purple.shade800,
  'F': Colors.blue.shade800,
  'G': Colors.green.shade900,
  'A': Colors.lightGreen.shade800,
  'B': Colors.yellow.shade800,
};

/// Default highlight colors (match your current visuals)
const Color kDefaultHighlightRootColor     = Color.fromARGB(255, 255, 191, 0);
const Color kDefaultHighlightInScaleColor  = Color.fromARGB(255, 255, 234, 184);

/// NEW: default inlay dot color (matches your previous AppColors.inlayDot)
const Color kDefaultInlayDotColor = Color.fromARGB(255, 35, 34, 34);

/// Default marker colors
const Color kDefaultMarkerRomanColor = Color.fromARGB(255, 131, 131, 131);
const Color kDefaultMarkerNumericColor = Color.fromARGB(255, 131, 131, 131);

/// ─────────────────────────────────────────────────────────────────────────────
/// Global Settings (ChangeNotifier + InheritedNotifier scope)
/// ─────────────────────────────────────────────────────────────────────────────

class AppSettings extends ChangeNotifier {
  AppSettings({
    Map<String, Color>? initial,
    Color highlightRootColor    = kDefaultHighlightRootColor,
    Color highlightInScaleColor = kDefaultHighlightInScaleColor,
    Color inlayDotColor         = kDefaultInlayDotColor,
    Color markerRomanColor      = kDefaultMarkerRomanColor,
    Color markerNumericColor    = kDefaultMarkerNumericColor,
  })  : _naturalColors = Map<String, Color>.from(initial ?? kDefaultNaturalColors),
        _highlightRootColor = highlightRootColor,
        _highlightInScaleColor = highlightInScaleColor,
        _inlayDotColor = inlayDotColor,
        _markerRomanColor = markerRomanColor,
        _markerNumericColor = markerNumericColor;

  // Note palette
  Map<String, Color> _naturalColors;

  // Highlight colors
  Color _highlightRootColor;
  Color _highlightInScaleColor;

  // Inlay dot color
  Color _inlayDotColor;

  // Marker colors
  Color _markerRomanColor;
  Color _markerNumericColor;

  /// Read-only colors for Settings UI.
  Map<String, Color> get naturalColors => Map.unmodifiable(_naturalColors);

  /// Public color accessor for ANY note string.
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

  /// Reset only the natural note palette to defaults.
  void resetToDefaults() {
    _naturalColors = Map<String, Color>.from(kDefaultNaturalColors);
    notifyListeners();
  }

  /// ── Highlight colors API ───────────────────────────────────────────────────
  Color get highlightRootColor => _highlightRootColor;
  Color get highlightInScaleColor => _highlightInScaleColor;

  void setHighlightRootColor(Color c) {
    if (c == _highlightRootColor) return;
    _highlightRootColor = c;
    notifyListeners();
  }

  void setHighlightInScaleColor(Color c) {
    if (c == _highlightInScaleColor) return;
    _highlightInScaleColor = c;
    notifyListeners();
  }

  void resetHighlightColors() {
    _highlightRootColor = kDefaultHighlightRootColor;
    _highlightInScaleColor = kDefaultHighlightInScaleColor;
    notifyListeners();
  }

  /// ── NEW: Inlay dot color API ──────────────────────────────────────────────
  Color get inlayDotColor => _inlayDotColor;

  void setInlayDotColor(Color c) {
    if (c == _inlayDotColor) return;
    _inlayDotColor = c;
    notifyListeners();
  }

  void resetInlayDotColor() {
    _inlayDotColor = kDefaultInlayDotColor;
    notifyListeners();
  }

  /// ── Marker colors API ──────────────────────────────────────────────────────
  Color get markerRomanColor => _markerRomanColor;
  Color get markerNumericColor => _markerNumericColor;

  void setMarkerRomanColor(Color c) {
    if (c == _markerRomanColor) return;
    _markerRomanColor = c;
    notifyListeners();
  }

  void setMarkerNumericColor(Color c) {
    if (c == _markerNumericColor) return;
    _markerNumericColor = c;
    notifyListeners();
  }

  void resetMarkerColors() {
    _markerRomanColor = kDefaultMarkerRomanColor;
    _markerNumericColor = kDefaultMarkerNumericColor;
    notifyListeners();
  }

  /// Convenience: reset everything
  void resetEverythingToDefaults() {
    _naturalColors = Map<String, Color>.from(kDefaultNaturalColors);
    _highlightRootColor = kDefaultHighlightRootColor;
    _highlightInScaleColor = kDefaultHighlightInScaleColor;
    _inlayDotColor = kDefaultInlayDotColor;
    _markerRomanColor = kDefaultMarkerRomanColor;
    _markerNumericColor = kDefaultMarkerNumericColor;
    notifyListeners();
  }

  /// For sharp/flat tiles: return (base, next) natural colors.
  AccidentalPair gradientPairForAccidental(String note) {
    final baseNat = _baseNaturalForAccidental(note);
    final nextNat = _nextNatural(baseNat);
    return AccidentalPair(colorFor(baseNat), colorFor(nextNat));
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Internals
  // ───────────────────────────────────────────────────────────────────────────

  String _asNaturalOrBase(String note) {
    final t = note.trim().toUpperCase();
    if (kNaturalNotes.contains(t)) return t;
    if (t.endsWith('#') && t.length >= 2) {
      final base = t.substring(0, t.length - 1);
      return _normalizeNatural(base);
    }
    if (t.endsWith('B') && t.length >= 2) {
      final root = t.substring(0, t.length - 1);
      return _prevNatural(_normalizeNatural(root));
    }
    return _normalizeNatural(t);
  }

  String _baseNaturalForAccidental(String note) => _asNaturalOrBase(note);

  String _normalizeNatural(String s) {
    final up = s.toUpperCase();
    return kNaturalNotes.contains(up) ? up : 'C';
  }

  String _nextNatural(String nat) {
    const order = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    final i = order.indexOf(nat);
    return i < 0 ? 'D' : (order[(i + 1) % order.length]);
  }

  String _prevNatural(String nat) {
    const order = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    final i = order.indexOf(nat);
    return i < 0 ? 'B' : (order[(i + order.length - 1) % order.length]);
  }
}

/// Lightweight global provider.
class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    super.key,
    required AppSettings notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static AppSettings of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope not found in the widget tree.');
    return scope!.notifier!;
  }

  static AppSettings? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>()
        ?.notifier;
  }
}
