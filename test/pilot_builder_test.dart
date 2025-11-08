// Unit tests for PilotBuilder class functionality.
// See LICENSE file for licensing details.

import 'package:test/test.dart';
import 'package:wizlight/src/pilot_builder.dart';

void main() {
  group('PilotBuilder - Brightness', () {
    test('brightness validation - valid range', () {
      final builder = PilotBuilder();
      builder.brightness = 0;
      expect(builder.pilotParams['dimming'], equals(10));

      builder.brightness = 127;
      expect(builder.pilotParams['dimming'], equals(50));

      builder.brightness = 255;
      expect(builder.pilotParams['dimming'], equals(100));
    });

    test('brightness validation - invalid range throws', () {
      final builder = PilotBuilder();
      expect(() => builder.brightness = -1, throwsA(isA<ArgumentError>()));
      expect(() => builder.brightness = 256, throwsA(isA<ArgumentError>()));
    });
  });

  group('PilotBuilder - Color Temperature', () {
    test('colorTemp validation - valid range', () {
      final builder = PilotBuilder();
      builder.colorTemp = 2700;
      expect(builder.pilotParams['temp'], equals(2700));

      builder.colorTemp = 6500;
      expect(builder.pilotParams['temp'], equals(6500));
    });

    test('colorTemp validation - clamps out of range', () {
      final builder = PilotBuilder();
      builder.colorTemp = 500;
      expect(builder.pilotParams['temp'], equals(1000));

      builder.colorTemp = 15000;
      expect(builder.pilotParams['temp'], equals(10000));
    });
  });

  group('PilotBuilder - RGB', () {
    test('setRgb - valid values', () {
      final builder = PilotBuilder();
      builder.setRgb(255, 128, 64);
      expect(builder.pilotParams['r'], equals(255));
      expect(builder.pilotParams['g'], equals(128));
      expect(builder.pilotParams['b'], equals(64));
    });

    test('setRgb - invalid values throw', () {
      final builder = PilotBuilder();
      expect(() => builder.setRgb(256, 0, 0), throwsA(isA<ArgumentError>()));
      expect(() => builder.setRgb(0, 256, 0), throwsA(isA<ArgumentError>()));
      expect(() => builder.setRgb(0, 0, 256), throwsA(isA<ArgumentError>()));
      expect(() => builder.setRgb(-1, 0, 0), throwsA(isA<ArgumentError>()));
    });
  });

  group('PilotBuilder - RGBW', () {
    test('setRgbw - valid values', () {
      final builder = PilotBuilder();
      builder.setRgbw(255, 128, 64, 32);
      expect(builder.pilotParams['r'], equals(255));
      expect(builder.pilotParams['g'], equals(128));
      expect(builder.pilotParams['b'], equals(64));
      expect(builder.pilotParams['w'], equals(32));
    });

    test('setRgbw - invalid values throw', () {
      final builder = PilotBuilder();
      expect(() => builder.setRgbw(256, 0, 0, 0), throwsA(isA<ArgumentError>()));
      expect(() => builder.setRgbw(0, 256, 0, 0), throwsA(isA<ArgumentError>()));
      expect(() => builder.setRgbw(0, 0, 256, 0), throwsA(isA<ArgumentError>()));
      expect(() => builder.setRgbw(0, 0, 0, 256), throwsA(isA<ArgumentError>()));
    });
  });

  group('PilotBuilder - RGBWW', () {
    test('setRgbww - valid values', () {
      final builder = PilotBuilder();
      builder.setRgbww(255, 128, 64, 32, 16);
      expect(builder.pilotParams['r'], equals(255));
      expect(builder.pilotParams['g'], equals(128));
      expect(builder.pilotParams['b'], equals(64));
      expect(builder.pilotParams['c'], equals(32));
      expect(builder.pilotParams['w'], equals(16));
    });

    test('setRgbww - invalid values throw', () {
      final builder = PilotBuilder();
      expect(() => builder.setRgbww(256, 0, 0, 0, 0),
          throwsA(isA<ArgumentError>()));
      expect(() => builder.setRgbww(0, 256, 0, 0, 0),
          throwsA(isA<ArgumentError>()));
      expect(() => builder.setRgbww(0, 0, 256, 0, 0),
          throwsA(isA<ArgumentError>()));
      expect(() => builder.setRgbww(0, 0, 0, 256, 0),
          throwsA(isA<ArgumentError>()));
      expect(() => builder.setRgbww(0, 0, 0, 0, 256),
          throwsA(isA<ArgumentError>()));
    });
  });

  group('PilotBuilder - White LEDs', () {
    test('warmWhite - valid values', () {
      final builder = PilotBuilder();
      builder.warmWhite = 200;
      expect(builder.pilotParams['w'], equals(200));
    });

    test('warmWhite - invalid values throw', () {
      final builder = PilotBuilder();
      expect(() => builder.warmWhite = -1, throwsA(isA<ArgumentError>()));
      expect(() => builder.warmWhite = 256, throwsA(isA<ArgumentError>()));
    });

    test('coldWhite - valid values', () {
      final builder = PilotBuilder();
      builder.coldWhite = 150;
      expect(builder.pilotParams['c'], equals(150));
    });

    test('coldWhite - invalid values throw', () {
      final builder = PilotBuilder();
      expect(() => builder.coldWhite = -1, throwsA(isA<ArgumentError>()));
      expect(() => builder.coldWhite = 256, throwsA(isA<ArgumentError>()));
    });
  });

  group('PilotBuilder - Scene', () {
    test('scene - valid values', () {
      final builder = PilotBuilder();
      builder.scene = 1;
      expect(builder.pilotParams['sceneId'], equals(1));

      builder.scene = 35;
      expect(builder.pilotParams['sceneId'], equals(35));

      builder.scene = 1000;
      expect(builder.pilotParams['sceneId'], equals(1000));
    });

    test('scene - invalid values throw', () {
      final builder = PilotBuilder();
      expect(() => builder.scene = 0, throwsA(isA<ArgumentError>()));
      expect(() => builder.scene = 37, throwsA(isA<ArgumentError>()));
      expect(() => builder.scene = 500, throwsA(isA<ArgumentError>()));
    });

    test('sceneName - valid values', () {
      final builder = PilotBuilder();
      builder.sceneName = 'Ocean';
      expect(builder.pilotParams['sceneId'], equals(1));

      builder.sceneName = 'Alarm';
      expect(builder.pilotParams['sceneId'], equals(35));
    });

    test('sceneName - invalid values throw', () {
      final builder = PilotBuilder();
      expect(
          () => builder.sceneName = 'NonExistent', throwsA(isA<ArgumentError>()));
    });
  });

  group('PilotBuilder - Speed', () {
    test('speed - valid values', () {
      final builder = PilotBuilder();
      builder.speed = 10;
      expect(builder.pilotParams['speed'], equals(10));

      builder.speed = 100;
      expect(builder.pilotParams['speed'], equals(100));

      builder.speed = 200;
      expect(builder.pilotParams['speed'], equals(200));
    });

    test('speed - invalid values throw', () {
      final builder = PilotBuilder();
      expect(() => builder.speed = 9, throwsA(isA<ArgumentError>()));
      expect(() => builder.speed = 201, throwsA(isA<ArgumentError>()));
    });
  });

  group('PilotBuilder - Ratio', () {
    test('ratio - valid values', () {
      final builder = PilotBuilder();
      builder.ratio = 0;
      expect(builder.pilotParams['ratio'], equals(0));

      builder.ratio = 50;
      expect(builder.pilotParams['ratio'], equals(50));

      builder.ratio = 100;
      expect(builder.pilotParams['ratio'], equals(100));
    });

    test('ratio - invalid values throw', () {
      final builder = PilotBuilder();
      expect(() => builder.ratio = -1, throwsA(isA<ArgumentError>()));
      expect(() => builder.ratio = 101, throwsA(isA<ArgumentError>()));
    });
  });

  group('PilotBuilder - Fan Parameters', () {
    test('fanState - valid values', () {
      final builder = PilotBuilder();
      builder.fanState = 0;
      expect(builder.pilotParams['fs'], equals(0));

      builder.fanState = 1;
      expect(builder.pilotParams['fs'], equals(1));
    });

    test('fanState - invalid values throw', () {
      final builder = PilotBuilder();
      expect(() => builder.fanState = -1, throwsA(isA<ArgumentError>()));
      expect(() => builder.fanState = 2, throwsA(isA<ArgumentError>()));
    });

    test('fanMode - valid values', () {
      final builder = PilotBuilder();
      builder.fanMode = 1;
      expect(builder.pilotParams['fm'], equals(1));

      builder.fanMode = 2;
      expect(builder.pilotParams['fm'], equals(2));
    });

    test('fanMode - invalid values throw', () {
      final builder = PilotBuilder();
      expect(() => builder.fanMode = 0, throwsA(isA<ArgumentError>()));
      expect(() => builder.fanMode = 3, throwsA(isA<ArgumentError>()));
    });

    test('fanSpeed - valid values', () {
      final builder = PilotBuilder();
      builder.fanSpeed = 1;
      expect(builder.pilotParams['fv'], equals(1));

      builder.fanSpeed = 6;
      expect(builder.pilotParams['fv'], equals(6));
    });

    test('fanSpeed - invalid values throw', () {
      final builder = PilotBuilder();
      expect(() => builder.fanSpeed = 0, throwsA(isA<ArgumentError>()));
      expect(() => builder.fanSpeed = 7, throwsA(isA<ArgumentError>()));
    });

    test('fanReverse - valid values', () {
      final builder = PilotBuilder();
      builder.fanReverse = 0;
      expect(builder.pilotParams['fr'], equals(0));

      builder.fanReverse = 1;
      expect(builder.pilotParams['fr'], equals(1));
    });

    test('fanReverse - invalid values throw', () {
      final builder = PilotBuilder();
      expect(() => builder.fanReverse = -1, throwsA(isA<ArgumentError>()));
      expect(() => builder.fanReverse = 2, throwsA(isA<ArgumentError>()));
    });
  });

  group('PilotBuilder - Message Generation', () {
    test('setPilotMessage - basic parameters', () {
      final builder = PilotBuilder()
        ..brightness = 127
        ..colorTemp = 2700;

      final msg = builder.setPilotMessage(state: true);

      expect(msg['method'], equals('setPilot'));
      expect(msg['params']['state'], equals(true));
      expect(msg['params']['dimming'], equals(50));
      expect(msg['params']['temp'], equals(2700));
    });

    test('setPilotMessage - RGB color', () {
      final builder = PilotBuilder()..setRgb(255, 0, 128);

      final msg = builder.setPilotMessage(state: true);

      expect(msg['params']['r'], equals(255));
      expect(msg['params']['g'], equals(0));
      expect(msg['params']['b'], equals(128));
    });

    test('setPilotMessage - scene with speed', () {
      final builder = PilotBuilder()
        ..scene = 1
        ..speed = 50;

      final msg = builder.setPilotMessage();

      expect(msg['params']['sceneId'], equals(1));
      expect(msg['params']['speed'], equals(50));
    });

    test('setStateMessage - generates setState format', () {
      final builder = PilotBuilder();

      final msg = builder.setStateMessage(state: true);

      expect(msg['method'], equals('setState'));
      expect(msg['params']['state'], equals(true));
    });

    test('setPilotMessage - fan parameters', () {
      final builder = PilotBuilder()
        ..fanState = 1
        ..fanMode = 2
        ..fanSpeed = 5
        ..fanReverse = 1;

      final msg = builder.setPilotMessage();

      expect(msg['params']['fs'], equals(1));
      expect(msg['params']['fm'], equals(2));
      expect(msg['params']['fv'], equals(5));
      expect(msg['params']['fr'], equals(1));
    });
  });

  group('PilotBuilder - Complex Scenarios', () {
    test('Can set both RGB and brightness', () {
      final builder = PilotBuilder()
        ..brightness = 200
        ..setRgb(255, 0, 0);

      final msg = builder.setPilotMessage();

      expect(msg['params']['r'], equals(255));
      expect(msg['params']['dimming'], equals(78));
    });

    test('Can set both color temp and brightness', () {
      final builder = PilotBuilder()
        ..brightness = 150
        ..colorTemp = 3000;

      final msg = builder.setPilotMessage();

      expect(msg['params']['temp'], equals(3000));
      expect(msg['params']['dimming'], equals(59));
    });

    test('Scene with speed and brightness', () {
      final builder = PilotBuilder()
        ..scene = 1
        ..speed = 100
        ..brightness = 200;

      final msg = builder.setPilotMessage();

      expect(msg['params']['sceneId'], equals(1));
      expect(msg['params']['speed'], equals(100));
      expect(msg['params']['dimming'], equals(78));
    });
  });
}
