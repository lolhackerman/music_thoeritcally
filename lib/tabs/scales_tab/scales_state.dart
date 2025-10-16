import 'package:flutter/material.dart';
import 'package:music_theoretically/widgets/fretboard/fretboard_styles.dart' show chromatic;
import 'scales_constants.dart';

class ScalesState {
  final ValueNotifier<String?> firstNoteVN = ValueNotifier(null);
  final ValueNotifier<String?> secondNoteVN = ValueNotifier(null);
  final ValueNotifier<String>  selectedScaleVN =
      ValueNotifier(allScales.first);
  final ValueNotifier<String>  selectedRootVN =
      ValueNotifier(chromatic.first);

  // PageStorage keys
  static const _psKeyScale = 'scalesTab.scale';
  static const _psKeyRoot  = 'scalesTab.root';

  void attachPersistence(BuildContext context) {
    void persist() {
      final bucket = PageStorage.maybeOf(context);
      bucket?.writeState(context, selectedScaleVN.value, identifier: _psKeyScale);
      bucket?.writeState(context, selectedRootVN.value,  identifier: _psKeyRoot);
    }
    selectedScaleVN.addListener(persist);
    selectedRootVN.addListener(persist);

    WidgetsBinding.instance.addPostFrameCallback((_) => persist());
  }

  void tryRestore(BuildContext context) {
    final bucket = PageStorage.maybeOf(context);
    final savedScale = bucket?.readState(context, identifier: _psKeyScale) as String?;
    final savedRoot  = bucket?.readState(context, identifier: _psKeyRoot)  as String?;
    if (savedScale != null && allScales.contains(savedScale)) {
      selectedScaleVN.value = savedScale;
    }
    if (savedRoot != null && chromatic.contains(savedRoot)) {
      selectedRootVN.value = savedRoot;
    }
  }

  void dispose() {
    firstNoteVN.dispose();
    secondNoteVN.dispose();
    selectedScaleVN.dispose();
    selectedRootVN.dispose();
  }

  void handleNoteTap(String note) {
    final a = firstNoteVN.value;
    final b = secondNoteVN.value;
    if (a == null || b != null) {
      firstNoteVN.value = note;
      secondNoteVN.value = null;
    } else {
      secondNoteVN.value = note;
    }
  }

  List<String> scaleNotesFor(String root, String scaleName) {
    final intervals = scaleIntervals[scaleName]!;
    final rootIdx = chromatic.indexOf(root);
    return intervals.map((i) => chromatic[(rootIdx + i) % chromatic.length]).toList();
  }
}
