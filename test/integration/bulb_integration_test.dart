// Integration tests for Bulb class with real network communication
// Uses fake_bulb.dart to simulate a real WiZ bulb
// See LICENSE file for licensing details.

import 'package:test/test.dart';
import 'package:wizlight/src/bulb.dart';
import 'package:wizlight/src/pilot_builder.dart';
import 'package:wizlight/src/pilot_parser.dart';
import '../helpers/fake_bulb.dart';

void main() {
  group('Bulb Integration Tests - Basic Operations', () {
    late FakeBulb fakeBulb;
    late Bulb bulb;

    setUp(() async {
      final (server, port) = await startupBulb();
      fakeBulb = server;
      bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);
    });

    tearDown(() {
      fakeBulb.stop();
    });

    test('turn on bulb', () async {
      await bulb.turnOn();
      await Future.delayed(Duration(milliseconds: 100));

      final state = fakeBulb.currentState;
      expect(state['state'], equals(true));
    });

    test('turn off bulb', () async {
      // First turn on
      await bulb.turnOn();
      await Future.delayed(Duration(milliseconds: 100));

      // Then turn off
      await bulb.turnOff();
      await Future.delayed(Duration(milliseconds: 100));

      final state = fakeBulb.currentState;
      expect(state['state'], equals(false));
    });

    test('set brightness', () async {
      await bulb.setBrightness(75);
      await Future.delayed(Duration(milliseconds: 100));

      final state = fakeBulb.currentState;
      expect(state['dimming'], equals(75));
    });

    test('set RGB color', () async {
      await bulb.setRGBColor(255, 128, 64);
      await Future.delayed(Duration(milliseconds: 100));

      final state = fakeBulb.currentState;
      expect(state['r'], equals(255));
      expect(state['g'], equals(128));
      expect(state['b'], equals(64));
    });

    test('set color temperature', () async {
      await bulb.setColorTemp(4000);
      await Future.delayed(Duration(milliseconds: 100));

      final state = fakeBulb.currentState;
      expect(state['temp'], equals(4000));
    });

    test('set scene', () async {
      await bulb.setScene(1); // Ocean
      await Future.delayed(Duration(milliseconds: 100));

      final state = fakeBulb.currentState;
      expect(state['sceneId'], equals(1));
    });

    test('updateState returns current state', () async {
      // Set some state first
      await bulb.setBrightness(50);
      await bulb.setColorTemp(3000);
      await Future.delayed(Duration(milliseconds: 100));

      // Now read it back
      final parser = await bulb.updateState();

      expect(parser, isNotNull);
      expect(parser!.brightness, equals(128)); // 50% = 128/255
      expect(parser.colorTemp, equals(3000));
    });

    test('lightSwitch toggles state', () async {
      // Initial state should be off
      final state1 = await bulb.updateState();
      expect(state1?.state, equals(false));

      // Toggle on
      await bulb.lightSwitch();
      await Future.delayed(Duration(milliseconds: 100));

      final state2 = await bulb.updateState();
      expect(state2?.state, equals(true));

      // Toggle off
      await bulb.lightSwitch();
      await Future.delayed(Duration(milliseconds: 100));

      final state3 = await bulb.updateState();
      expect(state3?.state, equals(false));
    });
  });

  group('Bulb Integration Tests - Extended Colors', () {
    late FakeBulb fakeBulb;
    late Bulb bulb;

    setUp(() async {
      final (server, port) = await startupBulb(config: BulbConfigs.rgbwwBulb);
      fakeBulb = server;
      bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);
    });

    tearDown(() {
      fakeBulb.stop();
    });

    test('set RGBW color', () async {
      await bulb.setRgbw(255, 128, 64, 32);
      await Future.delayed(Duration(milliseconds: 100));

      final state = fakeBulb.currentState;
      expect(state['r'], equals(255));
      expect(state['g'], equals(128));
      expect(state['b'], equals(64));
      expect(state['w'], equals(32));
    });

    test('set RGBWW color', () async {
      await bulb.setRgbww(255, 128, 64, 32, 16);
      await Future.delayed(Duration(milliseconds: 100));

      final state = fakeBulb.currentState;
      expect(state['r'], equals(255));
      expect(state['g'], equals(128));
      expect(state['b'], equals(64));
      expect(state['c'], equals(32));
      expect(state['w'], equals(16));
    });

    test('set warm white', () async {
      await bulb.setWarmWhite(200);
      await Future.delayed(Duration(milliseconds: 100));

      final state = fakeBulb.currentState;
      expect(state['w'], equals(200));
    });

    test('set cold white', () async {
      await bulb.setColdWhite(150);
      await Future.delayed(Duration(milliseconds: 100));

      final state = fakeBulb.currentState;
      expect(state['c'], equals(150));
    });
  });

  group('Bulb Integration Tests - PilotBuilder', () {
    late FakeBulb fakeBulb;
    late Bulb bulb;

    setUp(() async {
      final (server, port) = await startupBulb();
      fakeBulb = server;
      bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);
    });

    tearDown(() {
      fakeBulb.stop();
    });

    test('turnOn with PilotBuilder', () async {
      final builder = PilotBuilder()
        ..brightness = 200
        ..colorTemp = 2700;

      await bulb.turnOn(builder);
      await Future.delayed(Duration(milliseconds: 100));

      final state = fakeBulb.currentState;
      expect(state['state'], equals(true));
      expect(state['dimming'], equals(78)); // 200/255 * 100 ≈ 78%
      expect(state['temp'], equals(2700));
    });

    test('turnOn with scene and speed', () async {
      final builder = PilotBuilder()
        ..scene = 1 // Ocean
        ..speed = 100;

      await bulb.turnOn(builder);
      await Future.delayed(Duration(milliseconds: 100));

      final state = fakeBulb.currentState;
      expect(state['sceneId'], equals(1));
      expect(state['speed'], equals(100));
    });

    test('setState with PilotBuilder', () async {
      final builder = PilotBuilder()
        ..brightness = 150
        ..setRgb(128, 0, 255);

      await bulb.setState(builder);
      await Future.delayed(Duration(milliseconds: 100));

      final state = fakeBulb.currentState;
      expect(state['dimming'], equals(59)); // 150/255 * 100 ≈ 59%
      expect(state['r'], equals(128));
      expect(state['g'], equals(0));
      expect(state['b'], equals(255));
    });
  });

  group('Bulb Integration Tests - Device Info', () {
    late FakeBulb fakeBulb;
    late Bulb bulb;

    setUp(() async {
      final (server, port) = await startupBulb();
      fakeBulb = server;
      bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);
    });

    tearDown(() {
      fakeBulb.stop();
    });

    test('getMac returns MAC address', () async {
      final mac = await bulb.getMac();
      expect(mac, equals('a8bb5006033d'));
    });

    test('getBulbType detects RGB bulb', () async {
      final bulbType = await bulb.getBulbType();

      expect(bulbType, isNotNull);
      expect(bulbType!.name, equals('ESP01_SHRGB_03'));
      expect(bulbType.fwVersion, equals('1.25.0'));
      expect(bulbType.features.color, isTrue);
      expect(bulbType.features.colorTemp, isTrue);
      expect(bulbType.features.brightness, isTrue);
    });

    test('getSystemConfig returns system configuration', () async {
      final config = await bulb.getSystemConfig();

      expect(config, isNotNull);
      expect(config!['mac'], equals('a8bb5006033d'));
      expect(config['moduleName'], equals('ESP01_SHRGB_03'));
      expect(config['fwVersion'], equals('1.25.0'));
    });

    test('getModelConfig returns model configuration', () async {
      final config = await bulb.getModelConfig();

      expect(config, isNotNull);
      expect(config!['ps'], equals(1));
      expect(config['pwmFreq'], equals(1000));
    });

    test('getWhiteRange returns kelvin range', () async {
      final range = await bulb.getWhiteRange();

      expect(range, isNotNull);
      expect(range!.length, equals(2));
      expect(range[0], equals(2200.0));
      expect(range[1], equals(6500.0));
    });

    test('getExtendedWhiteRange returns extended range', () async {
      final range = await bulb.getExtendedWhiteRange();

      expect(range, isNotNull);
      expect(range!.length, equals(3));
      expect(range[0], equals(2200.0));
      expect(range[1], equals(2700.0));
      expect(range[2], equals(6500.0));
    });
  });

  group('Bulb Integration Tests - Power Monitoring', () {
    late FakeBulb fakeBulb;
    late Bulb bulb;

    setUp(() async {
      final (server, port) = await startupBulb(config: BulbConfigs.socket);
      fakeBulb = server;
      bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);
    });

    tearDown() {
      fakeBulb.stop();
    };

    test('getPower returns power consumption', () async {
      final power = await bulb.getPower();

      expect(power, isNotNull);
      expect(power, closeTo(1065.385, 0.001));
    });

    test('getBulbType detects socket', () async {
      final bulbType = await bulb.getBulbType();

      expect(bulbType, isNotNull);
      expect(bulbType!.name, equals('ESP10_SOCKET_06'));
      expect(bulbType.features.color, isFalse);
      expect(bulbType.features.brightness, isFalse);
    });
  });

  group('Bulb Integration Tests - Different Bulb Types', () {
    test('tunable white bulb', () async {
      final (fakeBulb, port) =
          await startupBulb(config: BulbConfigs.tunableWhite);

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      final bulbType = await bulb.getBulbType();

      expect(bulbType, isNotNull);
      expect(bulbType!.name, equals('ESP01_SHTW_01'));
      expect(bulbType.features.color, isFalse);
      expect(bulbType.features.colorTemp, isTrue);
      expect(bulbType.features.brightness, isTrue);

      fakeBulb.stop();
    });

    test('dimmable white bulb', () async {
      final (fakeBulb, port) =
          await startupBulb(config: BulbConfigs.dimmableWhite);

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      final bulbType = await bulb.getBulbType();

      expect(bulbType, isNotNull);
      expect(bulbType!.name, equals('ESP01_SHDW_01'));
      expect(bulbType.features.color, isFalse);
      expect(bulbType.features.colorTemp, isFalse);
      expect(bulbType.features.brightness, isTrue);

      fakeBulb.stop();
    });

    test('ceiling fan', () async {
      final (fakeBulb, port) =
          await startupBulb(config: BulbConfigs.ceilingFan);

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      final bulbType = await bulb.getBulbType();

      expect(bulbType, isNotNull);
      expect(bulbType!.name, equals('ESP03_FANDIMS_31'));

      // Check fan speed range
      final fanSpeedRange = await bulb.getFanSpeedRange();
      expect(fanSpeedRange, equals(6));

      fakeBulb.stop();
    });
  });

  group('Bulb Integration Tests - Legacy API', () {
    late FakeBulb fakeBulb;
    late Bulb bulb;

    setUp(() async {
      final (server, port) = await startupBulb();
      fakeBulb = server;
      bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);
    });

    tearDown() {
      fakeBulb.stop();
    };

    test('toggleLight turns on/off', () async {
      await bulb.toggleLight(true);
      await Future.delayed(Duration(milliseconds: 100));

      var state = fakeBulb.currentState;
      expect(state['state'], equals(true));

      await bulb.toggleLight(false);
      await Future.delayed(Duration(milliseconds: 100));

      state = fakeBulb.currentState;
      expect(state['state'], equals(false));
    });

    test('getStatus returns JSON state', () async {
      final status = await bulb.getStatus();

      expect(status, isNotEmpty);
      expect(status, contains('mac'));
      expect(status, contains('a8bb5006033d'));
    });
  });
}
