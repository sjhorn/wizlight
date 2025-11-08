// Dart port of pywizlight scenes
// See LICENSE file for licensing details.

/// Scene ID to name mappings for WiZ bulbs
///
/// WiZ bulbs support various preset scenes/effects. Scene IDs range from 1-36,
/// plus a special scene 1000 for "Rhythm" mode.
const Map<int, String> scenes = {
  35: 'Alarm',
  10: 'Bedtime',
  29: 'Candlelight',
  27: 'Christmas',
  6: 'Cozy',
  13: 'Cool white',
  26: 'Club',
  12: 'Daylight',
  33: 'Diwali',
  23: 'Deep dive',
  22: 'Fall',
  5: 'Fireplace',
  7: 'Forest',
  15: 'Focus',
  30: 'Golden white',
  28: 'Halloween',
  24: 'Jungle',
  25: 'Mojito',
  14: 'Night light',
  1: 'Ocean',
  4: 'Party',
  31: 'Pulse',
  8: 'Pastel colors',
  19: 'Plantgrowth',
  2: 'Romance',
  16: 'Relax',
  36: 'Snowy sky',
  3: 'Sunset',
  20: 'Spring',
  21: 'Summer',
  32: 'Steampunk',
  17: 'True colors',
  18: 'TV time',
  34: 'White',
  9: 'Wake-up',
  11: 'Warm white',
  1000: 'Rhythm',
};

/// Scene name to ID mappings
///
/// Reverse lookup map for finding scene IDs by name.
final Map<String, int> sceneNameToId = {
  for (var entry in scenes.entries) entry.value: entry.key
};

/// Scene ID to name mappings (same as scenes, provided for compatibility)
const Map<int, String> sceneIdToName = scenes;

/// Scene IDs supported by RGB bulbs (all scenes)
///
/// RGB bulbs support all available scenes.
final List<int> rgbScenes = scenes.keys.toList();

/// Scene IDs supported by Tunable White (TW) bulbs
///
/// TW bulbs support a subset of all available scenes.
const List<int> twScenes = [
  6,
  9,
  10,
  11,
  12,
  13,
  14,
  15,
  16,
  18,
  29,
  30,
  31,
  32,
  33,
  35
];

/// Scene IDs supported by Dimmable White (DW) bulbs
///
/// DW bulbs support a smaller subset of scenes compared to TW and RGB bulbs.
const List<int> dwScenes = [9, 10, 14, 29, 31, 32, 34, 35];

/// Gets the scene name for a given scene ID
///
/// Returns null if the scene ID is not recognized.
String? getSceneName(int sceneId) {
  return scenes[sceneId];
}

/// Gets the scene ID for a given scene name
///
/// Throws [ArgumentError] if the scene name is not recognized.
/// Scene names are case-sensitive.
int getSceneId(String sceneName) {
  final id = sceneNameToId[sceneName];
  if (id == null) {
    throw ArgumentError('Unknown scene name: $sceneName');
  }
  return id;
}

/// Validates if a scene ID is valid
///
/// Returns true if the scene ID exists in the scene database.
bool isValidSceneId(int sceneId) {
  return scenes.containsKey(sceneId);
}

/// Validates if a scene name is valid
///
/// Returns true if the scene name exists in the scene database.
/// Scene names are case-sensitive.
bool isValidSceneName(String sceneName) {
  return sceneNameToId.containsKey(sceneName);
}
