const List<String> allScales = [
  'Major','Minor','Major Pentatonic','Minor Pentatonic',
  'Dorian','Mixolydian','Lydian','Phrygian','Locrian',
];

const Map<String, List<int>> scaleIntervals = {
  'Major':[0,2,4,5,7,9,11],
  'Minor':[0,2,3,5,7,8,10],
  'Major Pentatonic':[0,2,4,7,9],
  'Minor Pentatonic':[0,3,5,7,10],
  'Dorian':[0,2,3,5,7,9,10],
  'Mixolydian':[0,2,4,5,7,9,10],
  'Lydian':[0,2,4,6,7,9,11],
  'Phrygian':[0,1,3,5,7,8,10],
  'Locrian':[0,1,3,5,6,8,10],
};
