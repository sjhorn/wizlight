// Unit tests for PilotParser class functionality.
// See LICENSE file for licensing details.

import 'package:test/test.dart';
import 'package:wizlight/src/pilot_parser.dart';

void main() {
  group('PilotParser - Basic State', () {
    test('state - on/off parsing', () {
      var parser = PilotParser({'state': true});
      expect(parser.state, equals(true));

      parser = PilotParser({'state': false});
      expect(parser.state, equals(false));

      parser = PilotParser({});
      expect(parser.state, isNull);
    });

    test('brightness - dimming percentage to 0-255', () {
      var parser = PilotParser({'dimming': 10});
      expect(parser.brightness, equals(26));

      parser = PilotParser({'dimming': 50});
      expect(parser.brightness, equals(128));

      parser = PilotParser({'dimming': 100});
      expect(parser.brightness, equals(255));

      parser = PilotParser({});
      expect(parser.brightness, isNull);
    });

    test('colorTemp - kelvin value', () {
      final parser = PilotParser({'temp': 2700});
      expect(parser.colorTemp, equals(2700));

      final parser2 = PilotParser({});
      expect(parser2.colorTemp, isNull);
    });
  });

  group('PilotParser - RGB Color', () {
    test('rgb - tuple extraction', () {
      final parser = PilotParser({'r': 255, 'g': 128, 'b': 64});
      expect(parser.rgb, isNotNull);
      expect(parser.rgb!.$1, equals(255));
      expect(parser.rgb!.$2, equals(128));
      expect(parser.rgb!.$3, equals(64));
    });

    test('rgb - missing values', () {
      var parser = PilotParser({'r': 255, 'g': 128});
      expect(parser.rgb, isNull);

      parser = PilotParser({'r': 255});
      expect(parser.rgb, isNull);

      parser = PilotParser({});
      expect(parser.rgb, isNull);
    });
  });

  group('PilotParser - RGBW Color', () {
    test('rgbw - tuple extraction', () {
      final parser = PilotParser({'r': 255, 'g': 128, 'b': 64, 'w': 32});
      expect(parser.rgbw, isNotNull);
      expect(parser.rgbw!.$1, equals(255));
      expect(parser.rgbw!.$2, equals(128));
      expect(parser.rgbw!.$3, equals(64));
      expect(parser.rgbw!.$4, equals(32));
    });

    test('rgbw - missing values', () {
      final parser = PilotParser({'r': 255, 'g': 128, 'b': 64});
      expect(parser.rgbw, isNull);
    });
  });

  group('PilotParser - RGBWW Color', () {
    test('rgbww - tuple extraction', () {
      final parser =
          PilotParser({'r': 255, 'g': 128, 'b': 64, 'c': 32, 'w': 16});
      expect(parser.rgbww, isNotNull);
      expect(parser.rgbww!.$1, equals(255));
      expect(parser.rgbww!.$2, equals(128));
      expect(parser.rgbww!.$3, equals(64));
      expect(parser.rgbww!.$4, equals(32));
      expect(parser.rgbww!.$5, equals(16));
    });

    test('rgbww - missing values', () {
      final parser = PilotParser({'r': 255, 'g': 128, 'b': 64, 'c': 32});
      expect(parser.rgbww, isNull);
    });
  });

  group('PilotParser - Individual White LEDs', () {
    test('warmWhite - extraction', () {
      final parser = PilotParser({'w': 200});
      expect(parser.warmWhite, equals(200));

      final parser2 = PilotParser({});
      expect(parser2.warmWhite, isNull);
    });

    test('coldWhite - extraction', () {
      final parser = PilotParser({'c': 150});
      expect(parser.coldWhite, equals(150));

      final parser2 = PilotParser({});
      expect(parser2.coldWhite, isNull);
    });
  });

  group('PilotParser - Scene', () {
    test('sceneId - extraction', () {
      final parser = PilotParser({'sceneId': 1});
      expect(parser.sceneId, equals(1));

      final parser2 = PilotParser({});
      expect(parser2.sceneId, isNull);
    });

    test('scene - name from ID', () {
      final parser = PilotParser({'sceneId': 1});
      expect(parser.scene, equals('Ocean'));

      final parser2 = PilotParser({'sceneId': 35});
      expect(parser2.scene, equals('Alarm'));

      final parser3 = PilotParser({'sceneId': 1000});
      expect(parser3.scene, equals('Rhythm'));
    });

    test('scene - Rhythm special case', () {
      final parser = PilotParser({'schdPsetId': 1});
      expect(parser.scene, equals('Rhythm'));
    });

    test('scene - unknown ID', () {
      final parser = PilotParser({'sceneId': 9999});
      expect(parser.scene, isNull);
    });
  });

  group('PilotParser - Speed', () {
    test('speed - extraction', () {
      final parser = PilotParser({'speed': 75});
      expect(parser.speed, equals(75));

      final parser2 = PilotParser({});
      expect(parser2.speed, isNull);
    });
  });

  group('PilotParser - Ratio', () {
    test('ratio - extraction', () {
      final parser = PilotParser({'ratio': 50});
      expect(parser.ratio, equals(50));

      final parser2 = PilotParser({});
      expect(parser2.ratio, isNull);
    });
  });

  group('PilotParser - Source', () {
    test('source - extraction', () {
      var parser = PilotParser({'src': 'udp'});
      expect(parser.source, equals('udp'));

      parser = PilotParser({'src': 'pir'});
      expect(parser.source, equals('pir'));

      parser = PilotParser({'src': 'wfa1'});
      expect(parser.source, equals('wfa1'));

      final parser2 = PilotParser({});
      expect(parser2.source, isNull);
    });
  });

  group('PilotParser - Network Info', () {
    test('mac - extraction', () {
      final parser = PilotParser({'mac': 'a8bb5006033d'});
      expect(parser.mac, equals('a8bb5006033d'));

      final parser2 = PilotParser({});
      expect(parser2.mac, isNull);
    });

    test('rssi - signal strength', () {
      final parser = PilotParser({'rssi': -50});
      expect(parser.rssi, equals(-50));

      final parser2 = PilotParser({});
      expect(parser2.rssi, isNull);
    });
  });

  group('PilotParser - Power', () {
    test('power - milliwatts to watts conversion', () {
      final parser = PilotParser({'wh': 1065385});
      expect(parser.power, closeTo(1065.385, 0.001));

      final parser2 = PilotParser({});
      expect(parser2.power, isNull);
    });
  });

  group('PilotParser - White Ranges', () {
    test('whiteRange - extraction', () {
      final parser = PilotParser({
        'whiteRange': [2200, 6500]
      });
      expect(parser.whiteRange, isNotNull);
      expect(parser.whiteRange!.length, equals(2));
      expect(parser.whiteRange![0], equals(2200.0));
      expect(parser.whiteRange![1], equals(6500.0));
    });

    test('extendedWhiteRange - extraction', () {
      final parser = PilotParser({
        'extRange': [2200, 2700, 6500]
      });
      expect(parser.extendedWhiteRange, isNotNull);
      expect(parser.extendedWhiteRange!.length, equals(3));
    });
  });

  group('PilotParser - Fan Parameters', () {
    test('fanState - extraction', () {
      var parser = PilotParser({'fs': 0});
      expect(parser.fanState, equals(0));

      parser = PilotParser({'fs': 1});
      expect(parser.fanState, equals(1));

      final parser2 = PilotParser({});
      expect(parser2.fanState, isNull);
    });

    test('fanMode - extraction', () {
      var parser = PilotParser({'fm': 1});
      expect(parser.fanMode, equals(1));

      parser = PilotParser({'fm': 2});
      expect(parser.fanMode, equals(2));

      final parser2 = PilotParser({});
      expect(parser2.fanMode, isNull);
    });

    test('fanSpeed - extraction', () {
      final parser = PilotParser({'fv': 5});
      expect(parser.fanSpeed, equals(5));

      final parser2 = PilotParser({});
      expect(parser2.fanSpeed, isNull);
    });

    test('fanReverse - extraction', () {
      var parser = PilotParser({'fr': 0});
      expect(parser.fanReverse, equals(0));

      parser = PilotParser({'fr': 1});
      expect(parser.fanReverse, equals(1));

      final parser2 = PilotParser({});
      expect(parser2.fanReverse, isNull);
    });

    test('fanSpeedRange - extraction', () {
      final parser = PilotParser({'fanSpd': 6});
      expect(parser.fanSpeedRange, equals(6));

      final parser2 = PilotParser({});
      expect(parser2.fanSpeedRange, isNull);
    });
  });

  group('PilotParser - Complex State', () {
    test('RGB bulb with all parameters', () {
      final parser = PilotParser({
        'state': true,
        'dimming': 75,
        'r': 255,
        'g': 0,
        'b': 128,
        'sceneId': 1,
        'speed': 100,
        'src': 'udp',
        'mac': 'a8bb5006033d',
        'rssi': -45,
      });

      expect(parser.state, equals(true));
      expect(parser.brightness, equals(191));
      expect(parser.rgb, isNotNull);
      expect(parser.rgb!.$1, equals(255));
      expect(parser.sceneId, equals(1));
      expect(parser.scene, equals('Ocean'));
      expect(parser.speed, equals(100));
      expect(parser.source, equals('udp'));
      expect(parser.mac, equals('a8bb5006033d'));
      expect(parser.rssi, equals(-45));
    });

    test('Smart plug with power monitoring', () {
      final parser = PilotParser({
        'state': true,
        'wh': 1500000, // 1500 watts
        'mac': 'a8bb5006033d',
      });

      expect(parser.state, equals(true));
      expect(parser.power, closeTo(1500.0, 0.001));
      expect(parser.mac, equals('a8bb5006033d'));
    });

    test('Ceiling fan with all controls', () {
      final parser = PilotParser({
        'state': true,
        'dimming': 50,
        'fs': 1,
        'fm': 2,
        'fv': 5,
        'fr': 0,
        'fanSpd': 6,
      });

      expect(parser.state, equals(true));
      expect(parser.brightness, equals(128));
      expect(parser.fanState, equals(1));
      expect(parser.fanMode, equals(2));
      expect(parser.fanSpeed, equals(5));
      expect(parser.fanReverse, equals(0));
      expect(parser.fanSpeedRange, equals(6));
    });

    test('Tunable white bulb', () {
      final parser = PilotParser({
        'state': true,
        'dimming': 80,
        'temp': 4000,
        'whiteRange': [2700, 6500],
      });

      expect(parser.state, equals(true));
      expect(parser.brightness, equals(204));
      expect(parser.colorTemp, equals(4000));
      expect(parser.whiteRange, isNotNull);
      expect(parser.whiteRange!.length, equals(2));
    });
  });

  group('PilotParser - Edge Cases', () {
    test('empty pilot result', () {
      final parser = PilotParser({});

      expect(parser.state, isNull);
      expect(parser.brightness, isNull);
      expect(parser.colorTemp, isNull);
      expect(parser.rgb, isNull);
      expect(parser.scene, isNull);
    });

    test('malformed data gracefully handled', () {
      final parser = PilotParser({
        'dimming': 'invalid',
        'temp': 'not a number',
      });

      expect(parser.brightness, isNull);
      expect(parser.colorTemp, isNull);
    });
  });
}
