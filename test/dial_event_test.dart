import 'dart:convert';

import 'package:test/test.dart';
import 'package:wizlight/wizlight.dart';

void main() {
  group('DialEvent', () {
    test('parses rotation counter-clockwise event', () {
      final json = {
        'method': 'syncAccEvt',
        'env': 'pro',
        'params': {
          'mac': '9877d583fec5',
          'frame': 'gcAAAAAgCAFgArKqzQ==', // Type 0x08
          'rad': 1,
        },
      };

      final event = DialEvent.fromJson(json);

      expect(event, isNotNull);
      expect(event!.mac, '9877d583fec5');
      expect(event.type, DialEventType.rotationCounterClockwise);
      expect(event.rawType, 0x08);
      expect(event.sequence, 0x81c0);
      expect(event.action, 0x01);
      expect(event.state, 0x60);
    });

    test('parses rotation clockwise event', () {
      final json = {
        'method': 'syncAccEvt',
        'env': 'pro',
        'params': {
          'mac': '9877d583fec5',
          'frame': 'gb4AAAAgCQFgqyXB2g==', // Type 0x09
          'rad': 1,
        },
      };

      final event = DialEvent.fromJson(json);

      expect(event, isNotNull);
      expect(event!.type, DialEventType.rotationClockwise);
      expect(event.rawType, 0x09);
      expect(event.sequence, 0x81be);
    });

    test('parses dial short press event', () {
      final json = {
        'method': 'syncAccEvt',
        'env': 'pro',
        'params': {
          'mac': '9877d583fec5',
          'frame': 'kbQAAAAgAQFi9BvGrA==', // Type 0x01
          'rad': 1,
        },
      };

      final event = DialEvent.fromJson(json);

      expect(event, isNotNull);
      expect(event!.type, DialEventType.dialShortPress);
      expect(event.rawType, 0x01);
    });

    test('parses dial long press event', () {
      final json = {
        'method': 'syncAccEvt',
        'env': 'pro',
        'params': {
          'mac': '9877d583fec5',
          'frame': 'gckAAAAgAgFg0zQULQ==', // Type 0x02
          'rad': 1,
        },
      };

      final event = DialEvent.fromJson(json);

      expect(event, isNotNull);
      expect(event!.type, DialEventType.dialLongPress);
      expect(event.rawType, 0x02);
      expect(event.sequence, 0x81c9);
    });

    test('parses scene 1 short press event', () {
      final json = {
        'method': 'syncAccEvt',
        'env': 'pro',
        'params': {
          'mac': '9877d583fec5',
          'frame': 'gc4AAAAgEAFgZUibkQ==', // Type 0x10
          'rad': 1,
        },
      };

      final event = DialEvent.fromJson(json);

      expect(event, isNotNull);
      expect(event!.type, DialEventType.scene1ShortPress);
      expect(event.rawType, 0x10);
      expect(event.sequence, 0x81ce);
    });

    test('parses scene 1 long press event', () {
      final json = {
        'method': 'syncAccEvt',
        'env': 'pro',
        'params': {
          'mac': '9877d583fec5',
          'frame': 'gcoAAAAgEgFfMjoXPQ==', // Type 0x12
          'rad': 1,
        },
      };

      final event = DialEvent.fromJson(json);

      expect(event, isNotNull);
      expect(event!.type, DialEventType.scene1LongPress);
      expect(event.rawType, 0x12);
      expect(event.sequence, 0x81ca);
      expect(event.state, 0x5f); // Different state byte for this event
    });

    test('parses scene 2 short press event', () {
      final json = {
        'method': 'syncAccEvt',
        'env': 'pro',
        'params': {
          'mac': '9877d583fec5',
          'frame': 'gc8AAAAgEQFgadiVeg==', // Type 0x11
          'rad': 1,
        },
      };

      final event = DialEvent.fromJson(json);

      expect(event, isNotNull);
      expect(event!.type, DialEventType.scene2ShortPress);
      expect(event.rawType, 0x11);
      expect(event.sequence, 0x81cf);
    });

    test('parses scene 2 long press event', () {
      final json = {
        'method': 'syncAccEvt',
        'env': 'pro',
        'params': {
          'mac': '9877d583fec5',
          'frame': 'gcsAAAAgEwFgYB8m2A==', // Type 0x13
          'rad': 1,
        },
      };

      final event = DialEvent.fromJson(json);

      expect(event, isNotNull);
      expect(event!.type, DialEventType.scene2LongPress);
      expect(event.rawType, 0x13);
      expect(event.sequence, 0x81cb);
    });

    test('returns null for invalid method', () {
      final json = {
        'method': 'syncPilot', // Wrong method
        'env': 'pro',
        'params': {
          'mac': '9877d583fec5',
          'frame': 'gb4AAAAgCQFgqyXB2g==',
        },
      };

      final event = DialEvent.fromJson(json);
      expect(event, isNull);
    });

    test('returns null for missing params', () {
      final json = {
        'method': 'syncAccEvt',
        'env': 'pro',
      };

      final event = DialEvent.fromJson(json);
      expect(event, isNull);
    });

    test('returns null for invalid frame length', () {
      // Create a frame with wrong length (10 bytes instead of 13)
      final shortFrame = base64.encode([0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);

      final json = {
        'method': 'syncAccEvt',
        'env': 'pro',
        'params': {
          'mac': '9877d583fec5',
          'frame': shortFrame,
        },
      };

      final event = DialEvent.fromJson(json);
      expect(event, isNull);
    });

    test('handles unknown event type', () {
      // Create a frame with unknown type 0xFF
      final frame = base64.encode([
        0x81,
        0xc0,
        0x00,
        0x00,
        0x00,
        0x20,
        0xFF, // Unknown type
        0x01,
        0x60,
        0x00,
        0x00,
        0x00,
        0x00,
      ]);

      final json = {
        'method': 'syncAccEvt',
        'env': 'pro',
        'params': {
          'mac': '9877d583fec5',
          'frame': frame,
        },
      };

      final event = DialEvent.fromJson(json);

      expect(event, isNotNull);
      expect(event!.type, DialEventType.unknown);
      expect(event.rawType, 0xFF);
    });

    test('equality works correctly', () {
      final json = {
        'method': 'syncAccEvt',
        'env': 'pro',
        'params': {
          'mac': '9877d583fec5',
          'frame': 'gb4AAAAgCQFgqyXB2g==',
        },
      };

      final event1 = DialEvent.fromJson(json)!;
      final event2 = DialEvent.fromJson(json)!;

      // Same data should be equal (ignoring timestamp)
      expect(event1.mac, event2.mac);
      expect(event1.type, event2.type);
      expect(event1.sequence, event2.sequence);
    });

    test('toString includes useful information', () {
      final json = {
        'method': 'syncAccEvt',
        'env': 'pro',
        'params': {
          'mac': '9877d583fec5',
          'frame': 'gb4AAAAgCQFgqyXB2g==', // Type 0x09 = clockwise
        },
      };

      final event = DialEvent.fromJson(json)!;
      final str = event.toString();

      expect(str, contains('9877d583fec5'));
      expect(str, contains('rotationClockwise')); // Fixed: 0x09 is CW
      expect(str, contains('0x09'));
    });
  });
}
