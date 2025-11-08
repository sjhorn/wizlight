// Unit tests for BulbType class functionality.
// See LICENSE file for licensing details.

import 'package:test/test.dart';
import 'package:wizlight/src/bulb_type.dart';
import 'package:wizlight/src/exceptions.dart';

void main() {
  group('BulbType - RGB Bulbs', () {
    test('ESP01_SHRGB_03 - standard RGB bulb', () {
      final bulbType = BulbType.fromData(
        moduleName: 'ESP01_SHRGB_03',
        kelvinList: [2200, 2700, 6500],
        fwVersion: '1.25.0',
        whiteChannels: 1,
        whiteToColorRatio: 30,
      );

      expect(bulbType.bulbType, equals(BulbClass.rgb));
      expect(bulbType.name, equals('ESP01_SHRGB_03'));
      expect(bulbType.fwVersion, equals('1.25.0'));
      expect(bulbType.features.color, isTrue);
      expect(bulbType.features.colorTemp, isTrue);
      expect(bulbType.features.effect, isTrue);
      expect(bulbType.features.brightness, isTrue);
      expect(bulbType.kelvinRange?.min, equals(2200));
      expect(bulbType.kelvinRange?.max, equals(6500));
      expect(bulbType.whiteChannels, equals(1));
      expect(bulbType.whiteToColorRatio, equals(30));
    });

    test('ESP01_SHRGB1C_31 - RGBWW bulb with 2 white channels', () {
      final bulbType = BulbType.fromData(
        moduleName: 'ESP01_SHRGB1C_31',
        kelvinList: [2700, 6500],
        fwVersion: '1.17.1',
        whiteChannels: 2,
        whiteToColorRatio: 20,
      );

      expect(bulbType.bulbType, equals(BulbClass.rgb));
      expect(bulbType.features.color, isTrue);
      expect(bulbType.whiteChannels, equals(2));
      expect(bulbType.whiteToColorRatio, equals(20));
    });

    test('ESP56_SHTW3_01 - Hero/Strip Tunable White bulb', () {
      final bulbType = BulbType.fromData(
        moduleName: 'ESP56_SHTW3_01',
        kelvinList: [2200, 2700, 6500],
        fwVersion: '1.23.70',
      );

      expect(bulbType.bulbType, equals(BulbClass.tw));
      expect(bulbType.features.color, isFalse);
      expect(bulbType.features.colorTemp, isTrue);
    });
  });

  group('BulbType - Tunable White Bulbs', () {
    test('ESP01_SHTW_01 - standard tunable white', () {
      final bulbType = BulbType.fromData(
        moduleName: 'ESP01_SHTW_01',
        kelvinList: [2700, 6500],
        fwVersion: '1.18.0',
      );

      expect(bulbType.bulbType, equals(BulbClass.tw));
      expect(bulbType.features.color, isFalse);
      expect(bulbType.features.colorTemp, isTrue);
      expect(bulbType.features.effect, isTrue);
      expect(bulbType.features.brightness, isTrue);
      expect(bulbType.kelvinRange?.min, equals(2700));
      expect(bulbType.kelvinRange?.max, equals(6500));
    });

    test('ESP15_SHTW1_01I - tunable white variant', () {
      final bulbType = BulbType.fromData(
        moduleName: 'ESP15_SHTW1_01I',
        kelvinList: [2700, 6500],
        fwVersion: '1.10.0',
      );

      expect(bulbType.bulbType, equals(BulbClass.tw));
      expect(bulbType.features.color, isFalse);
      expect(bulbType.features.colorTemp, isTrue);
    });
  });

  group('BulbType - Dimmable White Bulbs', () {
    test('ESP01_SHDW_01 - dimmable white', () {
      final bulbType = BulbType.fromData(
        moduleName: 'ESP01_SHDW_01',
        kelvinList: [2700],
        fwVersion: '1.8.0',
      );

      expect(bulbType.bulbType, equals(BulbClass.dw));
      expect(bulbType.features.color, isFalse);
      expect(bulbType.features.colorTemp, isFalse);
      expect(bulbType.features.effect, isTrue);
      expect(bulbType.features.brightness, isTrue);
    });

    test('ESP06_SHDW9_01 - dimmable white variant', () {
      final bulbType = BulbType.fromData(
        moduleName: 'ESP06_SHDW9_01',
        kelvinList: [2700],
        fwVersion: '1.11.7',
      );

      expect(bulbType.bulbType, equals(BulbClass.dw));
      expect(bulbType.features.color, isFalse);
      expect(bulbType.features.colorTemp, isFalse);
    });
  });

  group('BulbType - Smart Plugs/Sockets', () {
    test('ESP10_SOCKET_06 - smart socket', () {
      final bulbType = BulbType.fromData(
        moduleName: 'ESP10_SOCKET_06',
        kelvinList: [],
        fwVersion: '1.25.0',
      );

      expect(bulbType.bulbType, equals(BulbClass.socket));
      expect(bulbType.features.color, isFalse);
      expect(bulbType.features.colorTemp, isFalse);
      expect(bulbType.features.effect, isFalse);
      expect(bulbType.features.brightness, isFalse);
    });

    test('ESP25_SOCKET_01 - power monitoring socket', () {
      final bulbType = BulbType.fromData(
        moduleName: 'ESP25_SOCKET_01',
        kelvinList: [],
        fwVersion: '1.26.2',
      );

      expect(bulbType.bulbType, equals(BulbClass.socket));
      expect(bulbType.features.color, isFalse);
    });
  });

  group('BulbType - Ceiling Fans', () {
    test('ESP03_FANDIMS_31 - fan with dimming (fandim)', () {
      final bulbType = BulbType.fromData(
        moduleName: 'ESP03_FANDIMS_31',
        kelvinList: [2700],
        fwVersion: '1.31.32',
      );

      expect(bulbType.bulbType, equals(BulbClass.fandim));
      expect(bulbType.features.fan, isTrue);
      expect(bulbType.features.brightness, isTrue);
    });
  });

  group('BulbType - Dual Head Bulbs', () {
    test('ESP20_DHRGB_01B - dual head RGB (Squire)', () {
      final bulbType = BulbType.fromData(
        moduleName: 'ESP20_DHRGB_01B',
        kelvinList: [2200, 2700, 6500],
        fwVersion: '1.21.40',
      );

      expect(bulbType.bulbType, equals(BulbClass.rgb));
      expect(bulbType.features.dualHead, isTrue);
      expect(bulbType.features.color, isTrue);
    });

    test('ESP03_SHRGB1W_01 - single head RGB', () {
      final bulbType = BulbType.fromData(
        moduleName: 'ESP03_SHRGB1W_01',
        kelvinList: [2200, 2700, 6500],
        fwVersion: '1.0.0',
      );

      expect(bulbType.bulbType, equals(BulbClass.rgb));
      expect(bulbType.features.dualHead, isFalse);
      expect(bulbType.features.color, isTrue);
    });
  });

  group('BulbType - Wall Switches', () {
    test('ESP_WFAL_01 - wall switch', () {
      final bulbType = BulbType.fromData(
        moduleName: 'ESP_WFAL_01',
        kelvinList: [2700],
        fwVersion: '1.16.68',
      );

      expect(bulbType.bulbType, equals(BulbClass.dw));
      expect(bulbType.features.brightness, isTrue);
    });
  });

  group('BulbType - Special Cases', () {
    test('missing module name uses type ID', () {
      final bulbType = BulbType.fromData(
        typeId: 0, // DW type - only known typeId
        kelvinList: [2700],
        fwVersion: '1.0.0',
      );

      expect(bulbType.bulbType, equals(BulbClass.dw));
      expect(bulbType.name, isNull);
    });

    test('unknown type ID defaults to DW', () {
      final bulbType = BulbType.fromData(
        typeId: 99, // Unknown type ID
        kelvinList: [2700],
        fwVersion: '1.0.0',
      );

      expect(bulbType.bulbType, equals(BulbClass.dw));
      expect(bulbType.name, isNull);
    });

    test('module name without RGB/TW/DW defaults to DW', () {
      final bulbType = BulbType.fromData(
        moduleName: 'ESP01_SHLIGHT_01',  // No RGB/TW/DW in identifier
        kelvinList: [2700],
        fwVersion: '1.0.0',
      );

      expect(bulbType.bulbType, equals(BulbClass.dw));
      expect(bulbType.name, equals('ESP01_SHLIGHT_01'));
    });

    test('missing kelvin range throws exception for RGB', () {
      expect(
        () => BulbType.fromData(
          moduleName: 'ESP01_SHRGB_03',
          fwVersion: '1.0.0',
        ),
        throwsA(isA<WizLightNotKnownBulb>()),
      );
    });

    test('missing kelvin range is allowed for DW', () {
      final bulbType = BulbType.fromData(
        moduleName: 'ESP01_SHDW_01',
        fwVersion: '1.0.0',
      );

      expect(bulbType.bulbType, equals(BulbClass.dw));
      expect(bulbType.kelvinRange, isNull);
    });

    test('single kelvin value (DW bulb)', () {
      final bulbType = BulbType.fromData(
        moduleName: 'ESP01_SHDW_01',
        kelvinList: [2700],
        fwVersion: '1.0.0',
      );

      expect(bulbType.bulbType, equals(BulbClass.dw));
      expect(bulbType.kelvinRange, isNotNull);
      expect(bulbType.kelvinRange!.min, equals(2700));
      expect(bulbType.kelvinRange!.max, equals(2700));
    });

    test('two kelvin values (TW bulb)', () {
      final bulbType = BulbType.fromData(
        moduleName: 'ESP01_SHTW_01',
        kelvinList: [2700, 6500],
        fwVersion: '1.0.0',
      );

      expect(bulbType.bulbType, equals(BulbClass.tw));
      expect(bulbType.kelvinRange?.min, equals(2700));
      expect(bulbType.kelvinRange?.max, equals(6500));
    });
  });

  group('BulbType - Features Detection', () {
    test('RGB bulb features', () {
      final bulbType = BulbType.fromData(
        moduleName: 'ESP01_SHRGB_03',
        kelvinList: [2700, 6500],
      );

      final features = bulbType.features;
      expect(features.color, isTrue);
      expect(features.colorTemp, isTrue);
      expect(features.effect, isTrue);
      expect(features.brightness, isTrue);
      expect(features.dualHead, isFalse);
      expect(features.fan, isFalse);
      expect(features.fanBreezeMode, isFalse);
      expect(features.fanReverse, isFalse);
    });

    test('Socket features', () {
      final bulbType = BulbType.fromData(
        moduleName: 'ESP10_SOCKET_06',
        kelvinList: [],
      );

      final features = bulbType.features;
      expect(features.color, isFalse);
      expect(features.colorTemp, isFalse);
      expect(features.effect, isFalse);
      expect(features.brightness, isFalse);
      expect(features.dualHead, isFalse);
      expect(features.fan, isFalse);
    });

    test('Fan features', () {
      final bulbType = BulbType.fromData(
        moduleName: 'ESP03_FANDIMS_31',
        kelvinList: [2700],
      );

      final features = bulbType.features;
      expect(features.fan, isTrue);
      expect(features.fanBreezeMode, isTrue);
      expect(features.fanReverse, isTrue);
      expect(features.brightness, isTrue);
      expect(features.color, isFalse);
    });
  });

  group('BulbType - Equality', () {
    test('equal bulb types have same properties', () {
      final bulbType1 = BulbType.fromData(
        moduleName: 'ESP01_SHRGB_03',
        kelvinList: [2200, 2700, 6500],
        fwVersion: '1.25.0',
      );

      final bulbType2 = BulbType.fromData(
        moduleName: 'ESP01_SHRGB_03',
        kelvinList: [2200, 2700, 6500],
        fwVersion: '1.25.0',
      );

      // Compare properties instead of object equality
      expect(bulbType1.bulbType, equals(bulbType2.bulbType));
      expect(bulbType1.name, equals(bulbType2.name));
      expect(bulbType1.fwVersion, equals(bulbType2.fwVersion));
    });

    test('different bulb types have different properties', () {
      final bulbType1 = BulbType.fromData(
        moduleName: 'ESP01_SHRGB_03',
        kelvinList: [2200, 2700, 6500],
        fwVersion: '1.25.0',
      );

      final bulbType2 = BulbType.fromData(
        moduleName: 'ESP01_SHTW_01',
        kelvinList: [2700, 6500],
        fwVersion: '1.18.0',
      );

      expect(bulbType1.bulbType, isNot(equals(bulbType2.bulbType)));
      expect(bulbType1.name, isNot(equals(bulbType2.name)));
    });
  });

  group('BulbClass - Display Names', () {
    test('display names are correct', () {
      expect(BulbClass.rgb.displayName, equals('RGB Tunable'));
      expect(BulbClass.tw.displayName, equals('Tunable White'));
      expect(BulbClass.dw.displayName, equals('Dimmable White'));
      expect(BulbClass.socket.displayName, equals('Socket'));
      expect(BulbClass.fandim.displayName, equals('Fan Dimmable'));
    });
  });

  group('KelvinRange', () {
    test('kelvin range creation', () {
      final range = KelvinRange(min: 2700, max: 6500);
      expect(range.min, equals(2700));
      expect(range.max, equals(6500));
    });

    test('kelvin range equality', () {
      final range1 = KelvinRange(min: 2700, max: 6500);
      final range2 = KelvinRange(min: 2700, max: 6500);
      final range3 = KelvinRange(min: 2200, max: 6500);

      // Compare properties instead of object equality
      expect(range1.min, equals(range2.min));
      expect(range1.max, equals(range2.max));
      expect(range1.min, isNot(equals(range3.min)));
    });
  });

  group('Features', () {
    test('features creation', () {
      const features = Features(
        color: true,
        colorTemp: true,
        effect: true,
        brightness: true,
        dualHead: false,
        fan: false,
        fanBreezeMode: false,
        fanReverse: false,
      );

      expect(features.color, isTrue);
      expect(features.colorTemp, isTrue);
      expect(features.effect, isTrue);
      expect(features.brightness, isTrue);
      expect(features.dualHead, isFalse);
      expect(features.fan, isFalse);
    });

    test('features equality', () {
      const features1 = Features(
        color: true,
        colorTemp: true,
        effect: true,
        brightness: true,
        dualHead: false,
        fan: false,
        fanBreezeMode: false,
        fanReverse: false,
      );

      const features2 = Features(
        color: true,
        colorTemp: true,
        effect: true,
        brightness: true,
        dualHead: false,
        fan: false,
        fanBreezeMode: false,
        fanReverse: false,
      );

      const features3 = Features(
        color: false,
        colorTemp: true,
        effect: true,
        brightness: true,
        dualHead: false,
        fan: false,
        fanBreezeMode: false,
        fanReverse: false,
      );

      // Compare properties instead of object equality
      expect(features1.color, equals(features2.color));
      expect(features1.colorTemp, equals(features2.colorTemp));
      expect(features1.color, isNot(equals(features3.color)));
    });
  });
}
