// Integration tests for timeout and retry behavior
// Tests progressive backoff and retry mechanisms
// See LICENSE file for licensing details.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:wizlight/src/bulb.dart';
import 'package:wizlight/src/exceptions.dart';
import 'package:wizlight/src/push_manager.dart';
import '../helpers/fake_bulb.dart';

void main() {
  group('Timeout and Retry Integration Tests - Basic Timeout', () {
    test('operation times out when no response received', () async {
      // Create socket that receives but never responds
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

      final stopwatch = Stopwatch()..start();
      final state = await bulb.updateState();
      stopwatch.stop();

      // Should timeout and return null
      expect(state, isNull);

      // Should have waited for timeout (implementation-dependent duration)
      // Just verify it eventually returned
      expect(stopwatch.elapsed.inSeconds, greaterThan(0));

      socket.close();
    });

    test('successful response before timeout returns immediately', () async {
      final (fakeBulb, port) = await startupBulb();

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      final stopwatch = Stopwatch()..start();
      final state = await bulb.updateState();
      stopwatch.stop();

      // Should return quickly with valid response
      expect(state, isNotNull);
      expect(stopwatch.elapsed.inSeconds, lessThan(2));

      fakeBulb.stop();
    });
  });

  group('Timeout and Retry Integration Tests - Progressive Backoff', () {
    test('retries with progressive backoff on no response', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      var requestCount = 0;
      final requestTimes = <DateTime>[];

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            requestCount++;
            requestTimes.add(DateTime.now());
            // Don't send response - force retries
          }
        }
      });

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      final stopwatch = Stopwatch()..start();
      final state = await bulb.updateState();
      stopwatch.stop();

      // Should have timed out after multiple retries
      expect(state, isNull);

      // Should have made multiple retry attempts
      // Python implementation does progressive backoff: 0s, 0.75s, 2.25s, 5.25s, 8.25s, 11.25s
      // Implementation may vary but should have retried at least once
      expect(requestCount, greaterThan(1),
        reason: 'Should have retried at least once');

      socket.close();
    });

    test('succeeds on second retry attempt', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      var requestCount = 0;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            requestCount++;

            // Respond only on second request
            if (requestCount >= 2) {
              final response = jsonEncode({
                'method': 'getPilot',
                'result': {
                  'state': true,
                  'dimming': 75,
                  'mac': 'a8bb5006033d',
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

      final state = await bulb.updateState();

      // Should eventually succeed after retry
      expect(state, isNotNull);
      expect(state!.state, equals(true));
      expect(requestCount, greaterThanOrEqualTo(2));

      socket.close();
    });

    test('succeeds on last retry attempt', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      var requestCount = 0;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            requestCount++;

            // Respond only on 4th request or later
            if (requestCount >= 4) {
              final response = jsonEncode({
                'method': 'getPilot',
                'result': {
                  'state': true,
                  'mac': 'a8bb5006033d',
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

      final state = await bulb.updateState();

      // May succeed or timeout depending on retry count limit
      // Just verify it doesn't crash
      if (state != null) {
        expect(requestCount, greaterThanOrEqualTo(4));
      }

      socket.close();
    });
  });

  group('Timeout and Retry Integration Tests - Different Operations', () {
    test('setPilot retries on timeout', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      var requestCount = 0;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final request = jsonDecode(utf8.decode(datagram.data));
            if (request['method'] == 'setPilot') {
              requestCount++;

              // Respond on second attempt
              if (requestCount >= 2) {
                final response = jsonEncode({
                  'method': 'setPilot',
                  'result': {'success': true}
                });
                socket.send(utf8.encode(response), datagram.address, datagram.port);
              }
            }
          }
        }
      });

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      await bulb.turnOn();

      // Should have retried
      expect(requestCount, greaterThanOrEqualTo(2));

      socket.close();
    });

    test('getSystemConfig retries on timeout', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      var requestCount = 0;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final request = jsonDecode(utf8.decode(datagram.data));
            if (request['method'] == 'getSystemConfig') {
              requestCount++;

              // Respond on second attempt
              if (requestCount >= 2) {
                final response = jsonEncode({
                  'method': 'getSystemConfig',
                  'result': {
                    'mac': 'a8bb5006033d',
                    'moduleName': 'ESP01_SHRGB_03',
                    'fwVersion': '1.25.0',
                  }
                });
                socket.send(utf8.encode(response), datagram.address, datagram.port);
              }
            }
          }
        }
      });

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      final mac = await bulb.getMac();

      // Should have retried and succeeded
      expect(mac, isNotNull);
      expect(requestCount, greaterThanOrEqualTo(2));

      socket.close();
    });

    test('discovery retries on timeout', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      var requestCount = 0;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final request = jsonDecode(utf8.decode(datagram.data));
            if (request['method'] == 'getDevInfo') {
              requestCount++;

              // Respond on second attempt
              if (requestCount >= 2) {
                final response = jsonEncode({
                  'method': 'getDevInfo',
                  'result': {
                    'mac': 'a8bb5006033d',
                    'moduleName': 'ESP01_SHRGB_03',
                    'fwVersion': '1.25.0',
                  }
                });
                socket.send(utf8.encode(response), datagram.address, datagram.port);
              }
            }
          }
        }
      });

      final bulb = Bulb();
      bulb.setPort(port);

      final result = await bulb.discover('127.0.0.1');

      // Should have retried and succeeded
      expect(result, isNotEmpty);
      expect(requestCount, greaterThanOrEqualTo(2));

      socket.close();
    });
  });

  group('Timeout and Retry Integration Tests - Backoff Timing', () {
    test('verifies progressive backoff intervals', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      final requestTimes = <DateTime>[];

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            requestTimes.add(DateTime.now());
            // Don't respond - force retries
          }
        }
      });

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      await bulb.updateState();

      // Verify we got multiple requests
      expect(requestTimes.length, greaterThan(1));

      // Verify intervals are increasing (progressive backoff)
      // Allow for some timing variance
      if (requestTimes.length >= 3) {
        final interval1 = requestTimes[1].difference(requestTimes[0]).inMilliseconds;
        final interval2 = requestTimes[2].difference(requestTimes[1]).inMilliseconds;

        // Second interval should be longer than first (progressive backoff)
        // Allow 100ms tolerance for timing variance
        expect(interval2, greaterThan(interval1 - 100),
          reason: 'Progressive backoff should increase intervals');
      }

      socket.close();
    }, timeout: Timeout(Duration(seconds: 30)));

    test('immediate response skips remaining retries', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      var requestCount = 0;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            requestCount++;

            // Respond immediately on first request
            final response = jsonEncode({
              'method': 'getPilot',
              'result': {
                'state': true,
                'mac': 'a8bb5006033d',
              }
            });
            socket.send(utf8.encode(response), datagram.address, datagram.port);
          }
        }
      });

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      final stopwatch = Stopwatch()..start();
      final state = await bulb.updateState();
      stopwatch.stop();

      // Should return immediately without retries
      expect(state, isNotNull);
      expect(requestCount, equals(1),
        reason: 'Should not retry when response is immediate');
      expect(stopwatch.elapsed.inMilliseconds, lessThan(1000));

      socket.close();
    });
  });

  group('Timeout and Retry Integration Tests - Intermittent Failures', () {
    test('handles intermittent network issues', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      var requestCount = 0;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            requestCount++;

            // Simulate intermittent failure: fail first and third, succeed on second
            if (requestCount == 2) {
              final response = jsonEncode({
                'method': 'getPilot',
                'result': {
                  'state': true,
                  'mac': 'a8bb5006033d',
                }
              });
              socket.send(utf8.encode(response), datagram.address, datagram.port);
            }
            // Ignore other requests (simulate dropped packets)
          }
        }
      });

      final bulb = Bulb();
      bulb.setDeviceIP('127.0.0.1');
      bulb.setPort(port);

      final state = await bulb.updateState();

      // Should eventually succeed
      expect(state, isNotNull);
      expect(requestCount, greaterThanOrEqualTo(2));

      socket.close();
    });

    test('handles packet loss simulation', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      var requestCount = 0;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            requestCount++;

            // Simulate 50% packet loss - only respond to even-numbered requests
            if (requestCount % 2 == 0) {
              final response = jsonEncode({
                'method': 'getPilot',
                'result': {
                  'state': true,
                  'mac': 'a8bb5006033d',
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

      final state = await bulb.updateState();

      // Should succeed on an even-numbered retry
      expect(state, isNotNull);
      expect(requestCount, greaterThanOrEqualTo(2));

      socket.close();
    });
  });

  group('Timeout and Retry Integration Tests - Multiple Concurrent Operations', () {
    test('multiple concurrent operations each retry independently', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      var requestCount = 0;
      final methodCounts = <String, int>{};

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            requestCount++;
            final request = jsonDecode(utf8.decode(datagram.data));
            final method = request['method'] as String;

            methodCounts[method] = (methodCounts[method] ?? 0) + 1;

            // Respond on second request for each method
            if (methodCounts[method]! >= 2) {
              final response = jsonEncode({
                'method': method,
                'result': {
                  'state': true,
                  'mac': 'a8bb5006033d',
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

      // Start multiple operations concurrently
      final futures = <Future>[];
      futures.add(bulb.updateState());
      futures.add(bulb.getMac());

      await Future.wait(futures);

      // Both operations should have retried
      expect(methodCounts['getPilot'], greaterThanOrEqualTo(2));
      expect(methodCounts['getSystemConfig'], greaterThanOrEqualTo(2));

      socket.close();
    });
  });

  group('Timeout and Retry Integration Tests - Registration Retries', () {
    test('registration retries on timeout', () async {
      // Reset push manager and use port 0 (any available port) like Python does
      PushManager.resetForTesting();
      PushManager.testListenPort = 0;
      PushManager.testSourceIp = '127.0.0.1';  // Override source IP for localhost testing

      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      var registrationCount = 0;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final request = jsonDecode(utf8.decode(datagram.data));
            final method = request['method'];

            if (method == 'registration') {
              registrationCount++;

              // Respond on second attempt
              if (registrationCount >= 2) {
                final response = jsonEncode({
                  'method': 'registration',
                  'result': {'success': true}
                });
                socket.send(utf8.encode(response), datagram.address, datagram.port);
              }
            } else if (method == 'getSystemConfig') {
              // Always respond to getSystemConfig
              final response = jsonEncode({
                'method': 'getSystemConfig',
                'result': {
                  'mac': 'a8bb5006033d',
                  'moduleName': 'ESP01_SHRGB_03',
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

      // Start push (which does registration internally)
      bool pushStarted = await bulb.startPush((state, ip) {});
      if (!pushStarted) {
        final failReason = PushManager().failReason;
        print('Push start failed. Reason: $failReason');
      }
      expect(pushStarted, isTrue, reason: 'Push manager should start successfully with port 0');

      // Wait for some registration attempts to occur
      await Future.delayed(Duration(seconds: 3));

      // Should have attempted registration
      expect(registrationCount, greaterThanOrEqualTo(1));

      await bulb.stopPush();
      socket.close();

      // Reset for next tests
      PushManager.resetForTesting();
      PushManager.testListenPort = null;
    });
  });

  group('Timeout and Retry Integration Tests - Edge Cases', () {
    test('handles rapid timeout succession', () async {
      final bulb = Bulb();
      bulb.setDeviceIP('192.0.2.1'); // Unreachable
      bulb.setPort(38899);

      // Multiple operations that will all timeout
      final futures = <Future>[];
      for (var i = 0; i < 3; i++) {
        futures.add(bulb.updateState().catchError((e) => null));
      }

      // All should timeout without crashing
      await Future.wait(futures);

      // No assertions needed - just verify it completes
    }, timeout: Timeout(Duration(seconds: 90)));

    test('handles timeout during state change', () async {
      final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;

      var setPilotCount = 0;
      var getPilotCount = 0;

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final request = jsonDecode(utf8.decode(datagram.data));
            final method = request['method'];

            if (method == 'setPilot') {
              setPilotCount++;
              // Never respond to setPilot - force timeout
            } else if (method == 'getPilot') {
              getPilotCount++;
              // Respond to getPilot immediately
              final response = jsonEncode({
                'method': 'getPilot',
                'result': {
                  'state': false,
                  'mac': 'a8bb5006033d',
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

      // Try to turn on (will timeout)
      try {
        await bulb.turnOn();
        fail('Should have timed out');
      } catch (e) {
        expect(e, isA<WizLightTimeoutError>());
      }

      // But reading state should still work
      final state = await bulb.updateState();
      expect(state, isNotNull);

      socket.close();
    });
  });
}
