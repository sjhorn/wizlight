import 'dart:async';

import 'package:test/test.dart';
import 'package:wizlight/wizlight.dart';

import '../helpers/fake_dial.dart';

void main() {
  group('Dial Integration', () {
    late DialManager manager;
    late FakeDial fakeDial;

    setUp(() async {
      // Reset and configure for testing
      DialManager.resetForTesting();
      DialManager.testListenPort = 0; // Use any available port

      manager = DialManager();
      await manager.start(); // Start manager first to get the port

      fakeDial = FakeDial(mac: 'aabbccddeeff', port: manager.port!);
      await fakeDial.start();
    });

    tearDown(() async {
      await fakeDial.stop();
      await manager.stop();
      DialManager.resetForTesting();
    });

    test('receives rotation clockwise events', () async {
      final completer = Completer<DialEvent>();

      manager.subscribe('aabbccddeeff', (event) {
        if (!completer.isCompleted) {
          completer.complete(event);
        }
      });

      // Wait for manager to be ready
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Send event
      await fakeDial.sendRotationClockwise();

      final event =
          await completer.future.timeout(const Duration(seconds: 2));

      expect(event.type, DialEventType.rotationClockwise);
      expect(event.mac, 'aabbccddeeff');
      expect(event.rawType, 0x09); // Fixed: CW is 0x09
    });

    test('receives rotation counter-clockwise events', () async {
      final completer = Completer<DialEvent>();

      manager.subscribe('aabbccddeeff', (event) {
        if (!completer.isCompleted) {
          completer.complete(event);
        }
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));
      await fakeDial.sendRotationCounterClockwise();

      final event =
          await completer.future.timeout(const Duration(seconds: 2));

      expect(event.type, DialEventType.rotationCounterClockwise);
      expect(event.rawType, 0x08); // Fixed: CCW is 0x08
    });

    test('receives dial button events', () async {
      final events = <DialEvent>[];
      final completer = Completer<void>();

      manager.subscribe('aabbccddeeff', (event) {
        events.add(event);
        if (events.length == 2) {
          completer.complete();
        }
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));
      await fakeDial.sendDialShortPress();
      await fakeDial.sendDialLongPress();

      await completer.future.timeout(const Duration(seconds: 2));

      expect(events, hasLength(2));
      expect(events[0].type, DialEventType.dialShortPress);
      expect(events[1].type, DialEventType.dialLongPress);
    });

    test('receives scene button events', () async {
      final events = <DialEvent>[];
      final completer = Completer<void>();

      manager.subscribe('aabbccddeeff', (event) {
        events.add(event);
        if (events.length == 4) {
          completer.complete();
        }
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));
      await fakeDial.sendScene1ShortPress();
      await fakeDial.sendScene1LongPress();
      await fakeDial.sendScene2ShortPress();
      await fakeDial.sendScene2LongPress();

      await completer.future.timeout(const Duration(seconds: 2));

      expect(events, hasLength(4));
      expect(events[0].type, DialEventType.scene1ShortPress);
      expect(events[1].type, DialEventType.scene1LongPress);
      expect(events[2].type, DialEventType.scene2ShortPress);
      expect(events[3].type, DialEventType.scene2LongPress);
    });

    test('receives multiple rotation events', () async {
      final events = <DialEvent>[];
      final completer = Completer<void>();

      manager.subscribe('aabbccddeeff', (event) {
        events.add(event);
        if (events.length == 5) {
          completer.complete();
        }
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));
      await fakeDial.simulateRotation(5, clockwise: true);

      await completer.future.timeout(const Duration(seconds: 3));

      expect(events, hasLength(5));
      for (final event in events) {
        expect(event.type, DialEventType.rotationClockwise);
      }
    });

    test('global callback receives all events', () async {
      final events = <DialEvent>[];
      final completer = Completer<void>();

      manager.setGlobalCallback((event) {
        events.add(event);
        if (events.length == 3) {
          completer.complete();
        }
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));
      await fakeDial.sendRotationClockwise();
      await fakeDial.sendDialShortPress();
      await fakeDial.sendScene1ShortPress();

      await completer.future.timeout(const Duration(seconds: 2));

      expect(events, hasLength(3));
      expect(events[0].type, DialEventType.rotationClockwise);
      expect(events[1].type, DialEventType.dialShortPress);
      expect(events[2].type, DialEventType.scene1ShortPress);
    });

    test('can unsubscribe from dial', () async {
      var eventCount = 0;

      manager.subscribe('aabbccddeeff', (event) {
        eventCount++;
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));
      await fakeDial.sendRotationClockwise();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(eventCount, 1);

      // Unsubscribe
      manager.unsubscribe('aabbccddeeff');

      // Send another event (should not be received)
      await fakeDial.sendRotationClockwise();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(eventCount, 1); // Still 1, not incremented
    });

    test('WizDial convenience class works', () async {
      final dial = WizDial(mac: 'aabbccddeeff', name: 'Test Dial');
      final completer = Completer<DialEvent>();

      await dial.startListening((event) {
        if (!completer.isCompleted) {
          completer.complete(event);
        }
      });

      await Future<void>.delayed(const Duration(milliseconds: 100));
      await fakeDial.sendRotationClockwise();

      final event =
          await completer.future.timeout(const Duration(seconds: 2));

      expect(event.type, DialEventType.rotationClockwise);
      expect(dial.lastEvent, isNotNull);
      expect(dial.lastEvent!.type, DialEventType.rotationClockwise);
      expect(dial.isListening, isTrue);
      expect(dial.name, 'Test Dial');

      dial.stopListening();
      expect(dial.isListening, isFalse);

      await manager.stop();
    });
  });
}
