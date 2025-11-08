// Unit tests for Scenes functionality.
// See LICENSE file for licensing details.

import 'package:test/test.dart';
import 'package:wizlight/src/scenes.dart';

void main() {
  group('Scenes - ID to Name Mapping', () {
    test('getSceneName - valid scene IDs', () {
      expect(getSceneName(1), equals('Ocean'));
      expect(getSceneName(2), equals('Romance'));
      expect(getSceneName(10), equals('Bedtime'));
      expect(getSceneName(35), equals('Alarm'));
      expect(getSceneName(1000), equals('Rhythm'));
    });

    test('getSceneName - invalid scene ID returns null', () {
      expect(getSceneName(0), isNull);
      expect(getSceneName(37), isNull);
      expect(getSceneName(9999), isNull);
      expect(getSceneName(-1), isNull);
    });

    test('getSceneName - all defined scenes', () {
      // Test all 46 scenes are accessible
      expect(getSceneName(1), equals('Ocean'));
      expect(getSceneName(2), equals('Romance'));
      expect(getSceneName(3), equals('Sunset'));
      expect(getSceneName(4), equals('Party'));
      expect(getSceneName(5), equals('Fireplace'));
      expect(getSceneName(6), equals('Cozy'));
      expect(getSceneName(7), equals('Forest'));
      expect(getSceneName(8), equals('Pastel colors'));
      expect(getSceneName(9), equals('Wake-up'));
      expect(getSceneName(10), equals('Bedtime'));
      expect(getSceneName(11), equals('Warm white'));
      expect(getSceneName(12), equals('Daylight'));
      expect(getSceneName(13), equals('Cool white'));
      expect(getSceneName(14), equals('Night light'));
      expect(getSceneName(15), equals('Focus'));
      expect(getSceneName(16), equals('Relax'));
      expect(getSceneName(17), equals('True colors'));
      expect(getSceneName(18), equals('TV time'));
      expect(getSceneName(19), equals('Plantgrowth'));
      expect(getSceneName(20), equals('Spring'));
      expect(getSceneName(21), equals('Summer'));
      expect(getSceneName(22), equals('Fall'));
      expect(getSceneName(23), equals('Deep dive'));
      expect(getSceneName(24), equals('Jungle'));
      expect(getSceneName(25), equals('Mojito'));
      expect(getSceneName(26), equals('Club'));
      expect(getSceneName(27), equals('Christmas'));
      expect(getSceneName(28), equals('Halloween'));
      expect(getSceneName(29), equals('Candlelight'));
      expect(getSceneName(30), equals('Golden white'));
      expect(getSceneName(31), equals('Pulse'));
      expect(getSceneName(32), equals('Steampunk'));
      expect(getSceneName(33), equals('Diwali'));
      expect(getSceneName(34), equals('White'));
      expect(getSceneName(35), equals('Alarm'));
      expect(getSceneName(36), equals('Snowy sky'));
      expect(getSceneName(1000), equals('Rhythm'));
    });
  });

  group('Scenes - Name to ID Mapping', () {
    test('getSceneId - valid scene names', () {
      expect(getSceneId('Ocean'), equals(1));
      expect(getSceneId('Romance'), equals(2));
      expect(getSceneId('Bedtime'), equals(10));
      expect(getSceneId('Alarm'), equals(35));
      expect(getSceneId('Rhythm'), equals(1000));
    });

    test('getSceneId - invalid scene name throws', () {
      expect(() => getSceneId('NonExistent'), throwsA(isA<ArgumentError>()));
      expect(() => getSceneId(''), throwsA(isA<ArgumentError>()));
      expect(() => getSceneId('ocean'), throwsA(isA<ArgumentError>())); // Case sensitive
    });

    test('getSceneId - case sensitivity', () {
      expect(getSceneId('Ocean'), equals(1));
      expect(() => getSceneId('OCEAN'), throwsA(isA<ArgumentError>()));
      expect(() => getSceneId('ocean'), throwsA(isA<ArgumentError>()));
    });
  });

  group('Scenes - Scene Validation', () {
    test('isValidSceneId - valid IDs', () {
      expect(isValidSceneId(1), isTrue);
      expect(isValidSceneId(35), isTrue);
      expect(isValidSceneId(1000), isTrue);
    });

    test('isValidSceneId - invalid IDs', () {
      expect(isValidSceneId(0), isFalse);
      expect(isValidSceneId(37), isFalse);
      expect(isValidSceneId(9999), isFalse);
      expect(isValidSceneId(-1), isFalse);
    });

    test('isValidSceneName - valid names', () {
      expect(isValidSceneName('Ocean'), isTrue);
      expect(isValidSceneName('Alarm'), isTrue);
      expect(isValidSceneName('Rhythm'), isTrue);
    });

    test('isValidSceneName - invalid names', () {
      expect(isValidSceneName('NonExistent'), isFalse);
      expect(isValidSceneName(''), isFalse);
      expect(isValidSceneName('ocean'), isFalse); // Case sensitive
    });
  });

  group('Scenes - Bulb Type Specific Scenes', () {
    test('RGB scenes - includes all scenes', () {
      expect(rgbScenes.length, equals(37));
      expect(rgbScenes, contains(1)); // Ocean
      expect(rgbScenes, contains(35)); // Alarm
      expect(rgbScenes, contains(1000)); // Rhythm
    });

    test('TW scenes - limited set', () {
      expect(twScenes.length, equals(16));
      expect(twScenes, contains(6)); // Cozy
      expect(twScenes, contains(11)); // Warm white
      expect(twScenes, contains(12)); // Daylight
      expect(twScenes, isNot(contains(1))); // No Ocean (RGB only)
      expect(twScenes, isNot(contains(4))); // No Party (RGB only)
    });

    test('DW scenes - minimal set', () {
      expect(dwScenes.length, equals(8));
      expect(dwScenes, contains(9)); // Wake-up
      expect(dwScenes, contains(10)); // Bedtime
      expect(dwScenes, contains(14)); // Night light
      expect(dwScenes, isNot(contains(1))); // No Ocean (requires color)
      expect(dwScenes, isNot(contains(11))); // No Warm white (TW only)
    });

    test('TW scenes are subset of RGB scenes', () {
      for (final sceneId in twScenes) {
        expect(rgbScenes, contains(sceneId));
      }
    });

    test('DW scenes are subset of TW scenes', () {
      for (final sceneId in dwScenes) {
        expect(rgbScenes, contains(sceneId));
      }
    });
  });

  group('Scenes - Constants', () {
    test('scenes map contains all 37 scenes', () {
      expect(scenes.length, equals(37));
      expect(scenes.keys.toSet(), equals(rgbScenes.toSet()));
    });

    test('sceneIdToName map equals scenes map', () {
      expect(sceneIdToName, equals(scenes));
    });

    test('sceneNameToId is inverse of sceneIdToName', () {
      for (final entry in sceneIdToName.entries) {
        expect(sceneNameToId[entry.value], equals(entry.key));
      }
    });

    test('all RGB scene IDs are valid', () {
      for (final sceneId in rgbScenes) {
        expect(scenes.containsKey(sceneId), isTrue);
      }
    });

    test('all TW scene IDs are valid', () {
      for (final sceneId in twScenes) {
        expect(scenes.containsKey(sceneId), isTrue);
      }
    });

    test('all DW scene IDs are valid', () {
      for (final sceneId in dwScenes) {
        expect(scenes.containsKey(sceneId), isTrue);
      }
    });
  });

  group('Scenes - Specific Scene Tests', () {
    test('seasonal scenes exist', () {
      expect(getSceneId('Spring'), equals(20));
      expect(getSceneId('Summer'), equals(21));
      expect(getSceneId('Fall'), equals(22));
    });

    test('holiday scenes exist', () {
      expect(getSceneId('Christmas'), equals(27));
      expect(getSceneId('Halloween'), equals(28));
      expect(getSceneId('Diwali'), equals(33));
    });

    test('utility scenes exist', () {
      expect(getSceneId('Wake-up'), equals(9));
      expect(getSceneId('Bedtime'), equals(10));
      expect(getSceneId('Focus'), equals(15));
      expect(getSceneId('Relax'), equals(16));
      expect(getSceneId('TV time'), equals(18));
    });

    test('white scenes exist', () {
      expect(getSceneId('Warm white'), equals(11));
      expect(getSceneId('Daylight'), equals(12));
      expect(getSceneId('Cool white'), equals(13));
      expect(getSceneId('Night light'), equals(14));
      expect(getSceneId('White'), equals(34));
      expect(getSceneId('Golden white'), equals(30));
    });

    test('special Rhythm scene', () {
      expect(getSceneId('Rhythm'), equals(1000));
      expect(getSceneName(1000), equals('Rhythm'));
      expect(rgbScenes, contains(1000));
      expect(twScenes, isNot(contains(1000)));
      expect(dwScenes, isNot(contains(1000)));
    });
  });

  group('Scenes - Round Trip Conversion', () {
    test('ID to name to ID preserves value', () {
      for (final sceneId in scenes.keys) {
        final name = getSceneName(sceneId);
        if (name != null) {
          final backToId = getSceneId(name);
          expect(backToId, equals(sceneId));
        }
      }
    });

    test('name to ID to name preserves value', () {
      for (final sceneName in sceneNameToId.keys) {
        final id = getSceneId(sceneName);
        final backToName = getSceneName(id);
        expect(backToName, equals(sceneName));
      }
    });
  });
}
