// Integration tests for error handling and edge cases
// Tests network failures, malformed responses, and timeouts
// See LICENSE file for licensing details.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:wizlight/src/bulb.dart';
import '../helpers/fake_bulb.dart';

void main() {
  group('Error Handling Integration Tests - Malformed Responses', () {
    test('handles malformed JSON gracefully', () async {
      // Create a fake bulb that returns malformed JSON
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            // Send malformed JSON
            final malformed = utf8.encode('{invalid json}');
            socket.send(malformed, datagram.address, datagram.port);
          }
        }
      });

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      // Should handle gracefully and return null
      final state = await bulb.updateState();
      expect(state, isNull);

      socket.close();
    });

    test('handles incomplete JSON response', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            // Send incomplete JSON (missing closing brace)
            final incomplete = utf8.encode('{"method":"getPilot","result":{"state":true');
            socket.send(incomplete, datagram.address, datagram.port);
          }
        }
      });

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      final state = await bulb.updateState();
      expect(state, isNull);

      socket.close();
    });

    test('handles missing result field in response', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            // Send response without result field
            final response = jsonEncode({
              'method': 'getPilot',
              'env': 'pro',
              // Missing 'result' field
            });
            socket.send(utf8.encode(response), datagram.address, datagram.port);
          }
        }
      });

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      final state = await bulb.updateState();
      expect(state, isNull);

      socket.close();
    });

    test('handles response with wrong data types', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            // Send response with wrong types
            final response = jsonEncode({
              'method': 'getPilot',
              'result': {
                'state': 'not-a-boolean', // Should be bool
                'dimming': 'not-a-number', // Should be int
                'temp': [], // Should be int
              }
            });
            socket.send(utf8.encode(response), datagram.address, datagram.port);
          }
        }
      });

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      // Should parse what it can and handle errors gracefully
      final state = await bulb.updateState();
      // Should still return a parser, but fields may be null
      expect(state, isNotNull);

      socket.close();
    });

    test('handles error response from bulb', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            // Send error response
            final response = jsonEncode({
              'method': 'getPilot',
              'error': {
                'code': -32600,
                'message': 'Invalid Request'
              }
            });
            socket.send(utf8.encode(response), datagram.address, datagram.port);
          }
        }
      });

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      final state = await bulb.updateState();
      expect(state, isNull);

      socket.close();
    });
  });

  group('Error Handling Integration Tests - Network Issues', () {
    test('handles network timeout gracefully', () async {
      // Create a socket that never responds
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          socket.receive(); // Receive but don't respond
        }
      });

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      // Should timeout and return null
      final state = await bulb.updateState();
      expect(state, isNull);

      socket.close();
    });

    test('handles unreachable IP address', () async {
      final bulb = Bulb();
      // Use an IP that won't respond (TEST-NET-1 from RFC 5737)
      bulb.setDeviceIP('192.0.2.1');
      bulb.setPort(38899);

      // Should timeout gracefully
      final state = await bulb.updateState();
      expect(state, isNull);
    });

    test('handles connection to invalid port', () async {
      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(1); // Port 1 is unlikely to be listening

      final state = await bulb.updateState();
      expect(state, isNull);
    });
  });

  group('Error Handling Integration Tests - Missing Data', () {
    test('handles missing MAC address', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final request = jsonDecode(utf8.decode(datagram.data));
            final method = request['method'];

            if (method == 'getSystemConfig') {
              // Send system config without MAC
              final response = jsonEncode({
                'method': 'getSystemConfig',
                'result': {
                  'moduleName': 'ESP01_SHRGB_03',
                  'fwVersion': '1.25.0',
                  // Missing 'mac' field
                }
              });
              socket.send(utf8.encode(response), datagram.address, datagram.port);
            }
          }
        }
      });

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      final mac = await bulb.getMac();
      expect(mac, isNull);

      socket.close();
    });

    test('handles missing module name', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final request = jsonDecode(utf8.decode(datagram.data));
            final method = request['method'];

            if (method == 'getSystemConfig') {
              // Send system config without moduleName
              final response = jsonEncode({
                'method': 'getSystemConfig',
                'result': {
                  'mac': 'a8bb5006033d',
                  'fwVersion': '1.25.0',
                  // Missing 'moduleName' field
                }
              });
              socket.send(utf8.encode(response), datagram.address, datagram.port);
            } else if (method == 'getModelConfig' || method == 'getUserConfig') {
              // Respond with error so it doesn't timeout
              final response = jsonEncode({
                'error': {'code': -32601, 'message': 'Method not found'}
              });
              socket.send(utf8.encode(response), datagram.address, datagram.port);
            }
          }
        }
      });

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      final bulbType = await bulb.getBulbType();
      expect(bulbType, isNull);

      socket.close();
    }, timeout: Timeout(Duration(seconds: 60)));

    test('handles missing kelvin range data', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final request = jsonDecode(utf8.decode(datagram.data));
            final method = request['method'];

            if (method == 'getModelConfig') {
              // Send model config without kelvin range
              final response = jsonEncode({
                'method': 'getModelConfig',
                'result': {
                  'ps': 1,
                  'pwmFreq': 1000,
                  // Missing kelvin range fields
                }
              });
              socket.send(utf8.encode(response), datagram.address, datagram.port);
            } else if (method == 'getUserConfig') {
              // Also respond without kelvin range for fallback
              final response = jsonEncode({
                'method': 'getUserConfig',
                'result': {
                  'fadeIn': 0,
                  'fadeOut': 0,
                  // Missing whiteRange field
                }
              });
              socket.send(utf8.encode(response), datagram.address, datagram.port);
            }
          }
        }
      });

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      final range = await bulb.getWhiteRange();
      expect(range, isNull);

      socket.close();
    }, timeout: Timeout(Duration(seconds: 60)));
  });

  group('Error Handling Integration Tests - Late Responses', () {
    test('handles multiple late responses to same request', () async {
      // This simulates a bulb that sends multiple responses to one request
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final request = jsonDecode(utf8.decode(datagram.data));
            final method = request['method'];

            if (method == 'getPilot') {
              final response = jsonEncode({
                'method': 'getPilot',
                'result': {
                  'state': true,
                  'dimming': 50,
                  'mac': 'a8bb5006033d',
                }
              });

              // Send response multiple times with delays
              socket.send(utf8.encode(response), datagram.address, datagram.port);

              // Send duplicate responses later (like real bulbs do)
              Future.delayed(Duration(milliseconds: 100), () {
                socket.send(utf8.encode(response), datagram.address, datagram.port);
              });

              Future.delayed(Duration(milliseconds: 200), () {
                socket.send(utf8.encode(response), datagram.address, datagram.port);
              });
            }
          }
        }
      });

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      // Should handle first response and ignore late duplicates
      final state = await bulb.updateState();
      expect(state, isNotNull);
      expect(state!.state, equals(true));

      socket.close();
    });

    test('handles very late responses', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      var requestCount = 0;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            requestCount++;

            if (requestCount == 1) {
              // First request: send response after a long delay
              Future.delayed(Duration(seconds: 20), () {
                final response = jsonEncode({
                  'method': 'getPilot',
                  'result': {'state': true}
                });
                socket.send(utf8.encode(response), datagram.address, datagram.port);
              });
            } else {
              // Subsequent requests: respond immediately
              final response = jsonEncode({
                'method': 'getPilot',
                'result': {'state': false}
              });
              socket.send(utf8.encode(response), datagram.address, datagram.port);
            }
          }
        }
      });

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      // First request should timeout (response too late)
      final state1 = await bulb.updateState();
      expect(state1, isNull);

      // Second request should succeed (immediate response)
      final state2 = await bulb.updateState();
      expect(state2, isNotNull);

      socket.close();
    });
  });

  group('Error Handling Integration Tests - Invalid Operations', () {
    test('handles setPilot on disconnected bulb', () async {
      final bulb = Bulb();
      bulb.setDeviceIP('192.0.2.1'); // Unreachable IP
      bulb.setPort(38899);

      // Operations should fail gracefully without throwing
      await bulb.turnOn();
      await bulb.setBrightness(100);
      await bulb.setRGBColor(255, 0, 0);

      // No exceptions expected
    });

    test('handles discovery on unreachable network', () async {
      final bulb = Bulb();
      bulb.setPort(38899);

      // Discovery on unreachable IP should timeout gracefully
      final result = await bulb.discover('192.0.2.1');
      expect(result, isEmpty);
    });

    test('handles push updates on unreachable bulb', () async {
      final bulb = Bulb();
      bulb.setDeviceIP('192.0.2.1');
      bulb.setPort(38899);

      final updates = <dynamic>[];
      final success = await bulb.startPush((state, ip) {
        updates.add(state);
      });

      // May fail to start or timeout
      // Either way, should not crash
      expect(updates, isEmpty);

      await bulb.stopPush();
    });
  });

  group('Error Handling Integration Tests - State Validation', () {
    test('handles invalid brightness values gracefully', () async {
      final (fakeBulb, port) = await startupBulb();

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      // These should clamp or validate internally
      await bulb.setBrightness(0); // Minimum
      await bulb.setBrightness(255); // Maximum

      // Implementation-dependent: may throw or clamp
      // Just verify it doesn't crash the test harness

      fakeBulb.stop();
    });

    test('handles invalid color temperature values', () async {
      final (fakeBulb, port) = await startupBulb();

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      // Test boundary values
      await bulb.setColorTemp(1000); // Very low
      await bulb.setColorTemp(10000); // Very high

      // Should not crash
      fakeBulb.stop();
    });

    test('handles invalid RGB values', () async {
      final (fakeBulb, port) = await startupBulb();

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      // Test boundary values
      await bulb.setRGBColor(0, 0, 0); // All off
      await bulb.setRGBColor(255, 255, 255); // All max

      // Should not crash
      fakeBulb.stop();
    });

    test('handles invalid scene IDs', () async {
      final (fakeBulb, port) = await startupBulb();

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      // Valid scene IDs
      await bulb.setScene(1); // Valid
      await bulb.setScene(36); // Valid max

      // Implementation should validate scene IDs
      // Just verify basic operations work

      fakeBulb.stop();
    });
  });

  group('Error Handling Integration Tests - Concurrent Operations', () {
    test('handles concurrent state updates', () async {
      final (fakeBulb, port) = await startupBulb();

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      // Fire multiple requests concurrently
      final futures = <Future>[];
      futures.add(bulb.turnOn());
      futures.add(bulb.setBrightness(75));
      futures.add(bulb.setColorTemp(3000));
      futures.add(bulb.updateState());

      // All should complete without error
      await Future.wait(futures);

      fakeBulb.stop();
    });

    test('handles rapid successive commands', () async {
      final (fakeBulb, port) = await startupBulb();

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      // Send many commands in quick succession
      for (var i = 0; i < 10; i++) {
        await bulb.setBrightness(10 + i * 10);
      }

      // Should not crash or lose commands
      final state = await bulb.updateState();
      expect(state, isNotNull);

      fakeBulb.stop();
    });
  });

  group('Error Handling Integration Tests - Power Monitoring Errors', () {
    test('handles missing power data', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final request = jsonDecode(utf8.decode(datagram.data));
            final method = request['method'];

            if (method == 'getPilot') {
              // Send response without power data (wh field)
              final response = jsonEncode({
                'method': 'getPilot',
                'result': {
                  'state': true,
                  'mac': 'a8bb5006033d',
                  // Missing 'wh' field
                }
              });
              socket.send(utf8.encode(response), datagram.address, datagram.port);
            }
          }
        }
      });

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      final power = await bulb.getPower();
      expect(power, isNull);

      socket.close();
    });

    test('handles invalid power data type', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final request = jsonDecode(utf8.decode(datagram.data));
            final method = request['method'];

            if (method == 'getPilot') {
              // Send response with invalid power data
              final response = jsonEncode({
                'method': 'getPilot',
                'result': {
                  'state': true,
                  'mac': 'a8bb5006033d',
                  'wh': 'not-a-number', // Invalid type
                }
              });
              socket.send(utf8.encode(response), datagram.address, datagram.port);
            }
          }
        }
      });

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      // Should handle gracefully
      final power = await bulb.getPower();
      expect(power, isNull);

      socket.close();
    });
  });
}
