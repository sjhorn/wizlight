/// Smart Dial event types and handling for WiZ Smart Dial Switch
library;

import 'dart:convert';

/// Types of events that can be emitted by a WiZ Smart Dial
///
/// The Smart Dial has three physical controls:
/// - A rotary dial that can be turned clockwise/counter-clockwise (with tactile clicks)
/// - A dial button that can be pressed (short or long press)
/// - Two scene buttons that can be pressed (short or long press)
enum DialEventType {
  /// Dial was rotated clockwise by one click/step
  ///
  /// Each physical click of the dial sends one event. To adjust brightness,
  /// count the number of clockwise events and increment accordingly.
  rotationClockwise,

  /// Dial was rotated counter-clockwise by one click/step
  ///
  /// Each physical click of the dial sends one event. To adjust brightness,
  /// count the number of counter-clockwise events and decrement accordingly.
  rotationCounterClockwise,

  /// Dial button was short-pressed (quick tap)
  ///
  /// Useful for toggling power on/off or switching modes.
  dialShortPress,

  /// Dial button was long-pressed (held for >1-2 seconds)
  ///
  /// Useful for special actions like resetting to default or entering a mode.
  dialLongPress,

  /// Scene button 1 was short-pressed (quick tap)
  ///
  /// Typically used to activate a specific scene or preset.
  scene1ShortPress,

  /// Scene button 1 was long-pressed (held for >1-2 seconds)
  ///
  /// Can be used for alternative scene actions or scene editing.
  scene1LongPress,

  /// Scene button 2 was short-pressed (quick tap)
  ///
  /// Typically used to activate a specific scene or preset.
  scene2ShortPress,

  /// Scene button 2 was long-pressed (held for >1-2 seconds)
  ///
  /// Can be used for alternative scene actions or scene editing.
  scene2LongPress,

  /// Unknown event type (not mapped in protocol)
  unknown,
}

/// Represents a single event from a WiZ Smart Dial
///
/// Events are broadcast over UDP on port 38899 using the 'syncAccEvt' method.
/// Each event contains a sequence number, event type, and timestamp information.
class DialEvent {
  /// The MAC address of the dial that generated this event
  final String mac;

  /// The type of event (rotation, button press, etc.)
  final DialEventType type;

  /// Sequence number for this event (increments with each event)
  final int sequence;

  /// Raw event type byte from the protocol (0x01-0x13)
  final int rawType;

  /// Action byte from the protocol (typically 0x01)
  final int action;

  /// State byte from the protocol (typically 0x60, sometimes 0x5f)
  final int state;

  /// The raw base64-encoded frame data
  final String frame;

  /// Timestamp when this event was received
  final DateTime timestamp;

  const DialEvent({
    required this.mac,
    required this.type,
    required this.sequence,
    required this.rawType,
    required this.action,
    required this.state,
    required this.frame,
    required this.timestamp,
  });

  /// Parse a DialEvent from a UDP message
  ///
  /// The message should be a JSON object with the format:
  /// ```json
  /// {
  ///   "method": "syncAccEvt",
  ///   "env": "pro",
  ///   "params": {
  ///     "mac": "9877d583fec5",
  ///     "frame": "gb4AAAAgCQFgqyXB2g==",
  ///     "rad": 1
  ///   }
  /// }
  /// ```
  static DialEvent? fromJson(Map<String, dynamic> json) {
    try {
      // Validate method
      if (json['method'] != 'syncAccEvt') {
        return null;
      }

      final params = json['params'] as Map<String, dynamic>?;
      if (params == null) {
        return null;
      }

      final mac = params['mac'] as String?;
      final frameB64 = params['frame'] as String?;

      if (mac == null || frameB64 == null) {
        return null;
      }

      // Decode the base64 frame
      final frameBytes = base64.decode(frameB64);
      if (frameBytes.length != 13) {
        return null;
      }

      // Parse frame structure:
      // Offset 0-1: Sequence (16-bit big-endian)
      // Offset 2-5: Fixed header (0x00 0x00 0x00 0x20)
      // Offset 6:   Event type
      // Offset 7:   Action (always 0x01)
      // Offset 8:   State (0x60 or 0x5f)
      // Offset 9-12: Checksum/timestamp (unknown purpose)

      final sequence = (frameBytes[0] << 8) | frameBytes[1];
      final rawType = frameBytes[6];
      final action = frameBytes[7];
      final state = frameBytes[8];

      // Map raw type to DialEventType
      final type = _typeFromRawByte(rawType);

      return DialEvent(
        mac: mac,
        type: type,
        sequence: sequence,
        rawType: rawType,
        action: action,
        state: state,
        frame: frameB64,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Map protocol byte to event type
  static DialEventType _typeFromRawByte(int byte) {
    switch (byte) {
      case 0x01:
        return DialEventType.dialShortPress;
      case 0x02:
        return DialEventType.dialLongPress;
      case 0x08:
        return DialEventType.rotationCounterClockwise; // 0x08 is CCW
      case 0x09:
        return DialEventType.rotationClockwise; // 0x09 is CW
      case 0x10:
        return DialEventType.scene1ShortPress;
      case 0x11:
        return DialEventType.scene2ShortPress;
      case 0x12:
        return DialEventType.scene1LongPress;
      case 0x13:
        return DialEventType.scene2LongPress;
      default:
        return DialEventType.unknown;
    }
  }

  @override
  String toString() {
    return 'DialEvent(mac: $mac, type: $type, seq: $sequence, '
        'rawType: 0x${rawType.toRadixString(16).padLeft(2, '0')})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DialEvent &&
        other.mac == mac &&
        other.type == type &&
        other.sequence == sequence &&
        other.rawType == rawType &&
        other.action == action &&
        other.state == state &&
        other.frame == frame;
  }

  @override
  int get hashCode {
    return Object.hash(mac, type, sequence, rawType, action, state, frame);
  }
}
