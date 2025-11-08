// Mock dial event broadcaster for testing dial operations without a real dial
// See LICENSE file for licensing details.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Helper class to simulate a WiZ Smart Dial Switch for testing
///
/// The FakeDial broadcasts UDP messages on port 38899 with the same
/// format as a real Smart Dial device, allowing tests to verify event
/// handling without physical hardware.
///
/// Example:
/// ```dart
/// final dial = FakeDial(mac: 'aabbccddeeff');
/// await dial.start();
///
/// // Simulate dial rotation
/// await dial.sendRotationClockwise();
/// await dial.sendDialShortPress();
///
/// await dial.stop();
/// ```
class FakeDial {
  /// MAC address of this simulated dial
  final String mac;

  /// Port to broadcast on (default: 38899)
  final int port;

  RawDatagramSocket? _socket;
  int _sequenceNumber = 0x8000; // Start at typical sequence number

  FakeDial({
    required this.mac,
    this.port = 38899,
  });

  /// Start the fake dial (opens UDP socket for broadcasting)
  Future<void> start() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _socket!.broadcastEnabled = true;
  }

  /// Stop the fake dial and close the socket
  Future<void> stop() async {
    _socket?.close();
    _socket = null;
  }

  /// Send a custom event with the given type byte
  Future<void> sendEvent(int eventType, {int state = 0x60}) async {
    if (_socket == null) {
      throw StateError('FakeDial not started');
    }

    // Build the 13-byte frame
    final frame = <int>[
      (_sequenceNumber >> 8) & 0xFF, // Sequence high byte
      _sequenceNumber & 0xFF, // Sequence low byte
      0x00,
      0x00,
      0x00,
      0x20, // Fixed header
      eventType, // Event type
      0x01, // Action (always 0x01)
      state, // State byte
      0x00,
      0x00,
      0x00,
      0x00, // Checksum/timestamp (unused)
    ];

    _sequenceNumber++;

    // Convert frame to base64
    final frameB64 = base64.encode(frame);

    // Build JSON message
    final message = jsonEncode({
      'method': 'syncAccEvt',
      'env': 'pro',
      'params': {
        'mac': mac,
        'frame': frameB64,
        'rad': 1,
      },
    });

    // Broadcast the message
    final data = utf8.encode(message);
    _socket!.send(
      data,
      InternetAddress('255.255.255.255'),
      port,
    );

    // Small delay to allow message to be processed
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  // Convenience methods for each event type

  Future<void> sendRotationCounterClockwise() => sendEvent(0x08); // 0x08 is CCW
  Future<void> sendRotationClockwise() => sendEvent(0x09); // 0x09 is CW
  Future<void> sendDialShortPress() => sendEvent(0x01);
  Future<void> sendDialLongPress() => sendEvent(0x02);
  Future<void> sendScene1ShortPress() => sendEvent(0x10);
  Future<void> sendScene1LongPress() => sendEvent(0x12);
  Future<void> sendScene2ShortPress() => sendEvent(0x11);
  Future<void> sendScene2LongPress() => sendEvent(0x13);

  /// Simulate a rotation by sending multiple clockwise events
  Future<void> simulateRotation(int clicks, {bool clockwise = true}) async {
    for (var i = 0; i < clicks; i++) {
      if (clockwise) {
        await sendRotationClockwise();
      } else {
        await sendRotationCounterClockwise();
      }
      // Small delay between clicks to simulate real rotation
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }
}
