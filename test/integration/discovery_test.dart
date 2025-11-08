// Integration tests for discovery functionality
// Tests network discovery of WiZ bulbs
// See LICENSE file for licensing details.

import 'dart:convert';
import 'package:test/test.dart';
import 'package:wizlight/src/bulb.dart';
import '../helpers/fake_bulb.dart';

void main() {
  group('Discovery Integration Tests', () {
    test('discover single bulb on network', () async {
      // Start fake bulb
      final (fakeBulb, port) = await startupBulb();

      // Create bulb instance
      final bulb = Bulb();
      bulb.setPort(port);

      // Discover bulb using localhost/loopback
      final result = await bulb.discover('127.0.0.1');

      // Parse the result
      expect(result, isNotEmpty);
      final json = jsonDecode(result);
      final bulbResponse = json['bulb_response'] as Map<String, dynamic>;

      expect(bulbResponse, contains('mac'));
      expect(bulbResponse['mac'], equals('a8bb5006033d'));
      expect(bulbResponse, contains('moduleName'));
      expect(bulbResponse['moduleName'], equals('ESP01_SHRGB_03'));

      fakeBulb.stop();
    });

    test('discover returns IP address in result', () async {
      final (fakeBulb, port) = await startupBulb();

      final bulb = Bulb();
      bulb.setPort(port);

      final result = await bulb.discover('127.0.0.1');

      expect(result, isNotEmpty);
      final json = jsonDecode(result);
      final bulbResponse = json['bulb_response'] as Map<String, dynamic>;

      // IP should be included in the response
      expect(bulbResponse, contains('ip'));
      expect(bulbResponse['ip'], equals('127.0.0.1'));

      fakeBulb.stop();
    });

    test('discover different bulb types', () async {
      // Test RGB bulb
      var (fakeBulb, port) = await startupBulb(config: BulbConfigs.rgbBulb);
      var bulb = Bulb();
      bulb.setPort(port);

      var result = await bulb.discover('127.0.0.1');
      var json = jsonDecode(result);
      var bulbResponse = json['bulb_response'] as Map<String, dynamic>;
      expect(bulbResponse['moduleName'], equals('ESP01_SHRGB_03'));

      fakeBulb.stop();

      // Test socket
      (fakeBulb, port) = await startupBulb(config: BulbConfigs.socket);
      bulb = Bulb();
      bulb.setPort(port);

      result = await bulb.discover('127.0.0.1');
      json = jsonDecode(result);
      bulbResponse = json['bulb_response'] as Map<String, dynamic>;
      expect(bulbResponse['moduleName'], equals('ESP10_SOCKET_06'));

      fakeBulb.stop();

      // Test tunable white
      (fakeBulb, port) = await startupBulb(config: BulbConfigs.tunableWhite);
      bulb = Bulb();
      bulb.setPort(port);

      result = await bulb.discover('127.0.0.1');
      json = jsonDecode(result);
      bulbResponse = json['bulb_response'] as Map<String, dynamic>;
      expect(bulbResponse['moduleName'], equals('ESP01_SHTW_01'));

      fakeBulb.stop();
    });

    test('discover includes firmware version', () async {
      final (fakeBulb, port) = await startupBulb();

      final bulb = Bulb();
      bulb.setPort(port);

      final result = await bulb.discover('127.0.0.1');
      final json = jsonDecode(result);
      final bulbResponse = json['bulb_response'] as Map<String, dynamic>;

      expect(bulbResponse, contains('fwVersion'));
      expect(bulbResponse['fwVersion'], equals('1.25.0'));

      fakeBulb.stop();
    });

    test('discover includes device IDs', () async {
      final (fakeBulb, port) = await startupBulb();

      final bulb = Bulb();
      bulb.setPort(port);

      final result = await bulb.discover('127.0.0.1');
      final json = jsonDecode(result);
      final bulbResponse = json['bulb_response'] as Map<String, dynamic>;

      expect(bulbResponse, contains('homeId'));
      expect(bulbResponse, contains('roomId'));
      expect(bulbResponse, contains('typeId'));

      fakeBulb.stop();
    });
  });

  group('Discovery Integration Tests - Multiple Bulbs', () {
    test('discover handles multiple responses', () async {
      // Start multiple fake bulbs
      final (bulb1, port1) = await startupBulb(config: BulbConfigs.rgbBulb);
      final (bulb2, port2) = await startupBulb(config: BulbConfigs.socket);
      final (bulb3, port3) =
          await startupBulb(config: BulbConfigs.tunableWhite);

      // Create bulb instances and discover each
      final discoveries = <Map<String, dynamic>>[];

      // Discover bulb 1
      var finder = Bulb();
      finder.setPort(port1);
      var result = await finder.discover('127.0.0.1');
      var json = jsonDecode(result);
      discoveries.add(json['bulb_response'] as Map<String, dynamic>);

      // Discover bulb 2
      finder = Bulb();
      finder.setPort(port2);
      result = await finder.discover('127.0.0.1');
      json = jsonDecode(result);
      discoveries.add(json['bulb_response'] as Map<String, dynamic>);

      // Discover bulb 3
      finder = Bulb();
      finder.setPort(port3);
      result = await finder.discover('127.0.0.1');
      json = jsonDecode(result);
      discoveries.add(json['bulb_response'] as Map<String, dynamic>);

      // Verify we found all three
      expect(discoveries.length, equals(3));
      expect(discoveries[0]['moduleName'], equals('ESP01_SHRGB_03'));
      expect(discoveries[1]['moduleName'], equals('ESP10_SOCKET_06'));
      expect(discoveries[2]['moduleName'], equals('ESP01_SHTW_01'));

      bulb1.stop();
      bulb2.stop();
      bulb3.stop();
    });
  });

  group('Discovery Integration Tests - getDeviceInfo', () {
    test('getDeviceInfo returns device information', () async {
      final (fakeBulb, port) = await startupBulb();

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      final result = await bulb.getDeviceInfo();

      expect(result, isNotEmpty);
      final json = jsonDecode(result);
      final bulbResponse = json['bulb_response'] as Map<String, dynamic>;

      expect(bulbResponse, contains('mac'));
      expect(bulbResponse, contains('moduleName'));
      expect(bulbResponse, contains('fwVersion'));

      fakeBulb.stop();
    });
  });
}
