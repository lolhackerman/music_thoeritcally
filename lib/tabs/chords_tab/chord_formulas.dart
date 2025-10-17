// Small, single-purpose file to edit/extend chord qualities.
const Map<String, List<int>> chordFormulas = {
  'maj': [0, 4, 7],
  'min': [0, 3, 7],
  'dim': [0, 3, 6],
  'aug': [0, 4, 8],
  'sus2': [0, 2, 7],
  'sus4': [0, 5, 7],
  '6': [0, 4, 7, 9],
  'm6': [0, 3, 7, 9],
  '7': [0, 4, 7, 10],
  'maj7': [0, 4, 7, 11],
  'min7': [0, 3, 7, 10],
  'm7b5': [0, 3, 6, 10],
  'dim7': [0, 3, 6, 9],
  'add9': [0, 4, 7, 14],
  'm(add9)': [0, 3, 7, 14],
};
