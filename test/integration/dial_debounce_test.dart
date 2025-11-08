import 'dart:async';

import 'package:test/test.dart';
import 'package:wizlight/wizlight.dart';

import '../helpers/fake_dial.dart';

void main() {
  group('Dial Debouncing', () {
    late DialManager manager;
    late FakeDial fakeDial;

    setUp(() async {
      // Reset and configure for testing
      DialManager.resetForTesting();
      DialManager.testListenPort = 0; // Use any available port

      manager = DialManager();
      await manager.start();

      fakeDial = FakeDial(mac: 'aabbccddeeff', port: manager.port!);
      await fakeDial.start();
    });

    tearDown(() async {
      await fakeDial.stop();
      await manager.stop();
      DialManager.resetForTesting();
    });

    test('debounces rapid button short presses', () async {
      final events = <DialEvent>[];
      final completer = Completer<void>();

      manager.subscribe('aabbccddeeff', (event) {
        events.add(event);
        if (events.length >= 1) {
          // Wait a bit after first event to see if duplicates arrive
          Future<void>.delayed(const Duration(milliseconds: 400), () {
            completer.complete();
          });
        }
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Send 3 rapid button presses within debounce window (250ms)
      await fakeDial.sendDialShortPress();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await fakeDial.sendDialShortPress();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await fakeDial.sendDialShortPress();

      await completer.future.timeout(const Duration(seconds: 2));

      // Should only receive the first event due to debouncing
      expect(events.length, 1);
      expect(events[0].type, DialEventType.dialShortPress);
    });

    test('allows button presses after debounce window', () async {
      final events = <DialEvent>[];
      final completer = Completer<void>();

      manager.subscribe('aabbccddeeff', (event) {
        events.add(event);
        if (events.length == 2) {
          completer.complete();
        }
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Send first button press
      await fakeDial.sendDialShortPress();

      // Wait for debounce window to expire (250ms + margin)
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // Send second button press (should not be debounced)
      await fakeDial.sendDialShortPress();

      await completer.future.timeout(const Duration(seconds: 2));

      // Should receive both events
      expect(events.length, 2);
      expect(events[0].type, DialEventType.dialShortPress);
      expect(events[1].type, DialEventType.dialShortPress);
    });

    test('does not debounce rotation events', () async {
      final events = <DialEvent>[];
      final completer = Completer<void>();

      manager.subscribe('aabbccddeeff', (event) {
        events.add(event);
        if (events.length == 5) {
          completer.complete();
        }
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Send 5 rapid rotation events (should all pass through)
      for (var i = 0; i < 5; i++) {
        await fakeDial.sendRotationClockwise();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      await completer.future.timeout(const Duration(seconds: 2));

      // Should receive all 5 rotation events (no debouncing)
      expect(events.length, 5);
      for (final event in events) {
        expect(event.type, DialEventType.rotationClockwise);
      }
    });

    test('debounces scene button presses independently', () async {
      final events = <DialEvent>[];
      final completer = Completer<void>();

      manager.subscribe('aabbccddeeff', (event) {
        events.add(event);
        if (events.length >= 2) {
          // Wait a bit after events to ensure no more arrive
          Future<void>.delayed(const Duration(milliseconds: 400), () {
            completer.complete();
          });
        }
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Send rapid scene 1 presses (should debounce to 1)
      await fakeDial.sendScene1ShortPress();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await fakeDial.sendScene1ShortPress();

      // Send scene 2 press immediately (different button, should not debounce)
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await fakeDial.sendScene2ShortPress();

      await completer.future.timeout(const Duration(seconds: 2));

      // Should receive 2 events (1 scene1, 1 scene2)
      expect(events.length, 2);
      expect(events[0].type, DialEventType.scene1ShortPress);
      expect(events[1].type, DialEventType.scene2ShortPress);
    });

    test('debounces long press separately from short press', () async {
      final events = <DialEvent>[];
      final completer = Completer<void>();

      manager.subscribe('aabbccddeeff', (event) {
        events.add(event);
        if (events.length >= 2) {
          Future<void>.delayed(const Duration(milliseconds: 400), () {
            completer.complete();
          });
        }
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Send rapid short press followed by long press
      // (different event types, should not debounce each other)
      await fakeDial.sendDialShortPress();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await fakeDial.sendDialLongPress();

      await completer.future.timeout(const Duration(seconds: 2));

      // Should receive both events (different types)
      expect(events.length, 2);
      expect(events[0].type, DialEventType.dialShortPress);
      expect(events[1].type, DialEventType.dialLongPress);
    });

    test('debounces per MAC address', () async {
      // Create second dial with different MAC
      final fakeDial2 = FakeDial(mac: 'ffeeddccbbaa', port: manager.port!);
      await fakeDial2.start();

      final events = <DialEvent>[];
      final completer = Completer<void>();

      // Subscribe to both dials via global callback
      manager.setGlobalCallback((event) {
        events.add(event);
        if (events.length >= 2) {
          Future<void>.delayed(const Duration(milliseconds: 400), () {
            completer.complete();
          });
        }
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Send rapid presses from both dials (should get one from each)
      await fakeDial.sendDialShortPress();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await fakeDial2.sendDialShortPress();

      await completer.future.timeout(const Duration(seconds: 2));

      // Should receive 2 events (one from each dial)
      expect(events.length, 2);
      expect(events[0].mac, 'aabbccddeeff');
      expect(events[1].mac, 'ffeeddccbbaa');

      await fakeDial2.stop();
    });
  });
}
