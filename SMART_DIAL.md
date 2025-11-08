# WiZ Smart Dial Switch - Protocol & Implementation

Complete documentation for WiZ Smart Dial Switch (model 9290037923) support in the wizlight package.

## Hardware Overview

**Device**: WiZ Smart Dial Switch (model 9290037923)

**Physical Controls**:
- **Rotary Dial**: Clockwise/counter-clockwise rotation with tactile clicks (stepped, not continuous)
- **Dial Button**: Can be short-pressed or long-pressed (>1-2 seconds)
- **Scene Button 1**: Can be short-pressed or long-pressed
- **Scene Button 2**: Can be short-pressed or long-pressed

## Protocol Reverse Engineering

### Discovery Process

The protocol was fully reverse-engineered using network traffic analysis:

1. **Initial Capture**: Used `tcpdump -X -n -i en0 udp port 38899` to capture UDP broadcasts
2. **Systematic Testing**: Captured events in specific order:
   - Clockwise rotation (multiple clicks)
   - Counter-clockwise rotation (multiple clicks)
   - Dial button long press
   - Scene button 1 long press
   - Scene button 2 long press
   - Scene button 1 short press
   - Scene button 2 short press
3. **Frame Analysis**: Decoded base64 payloads to identify 13-byte binary structure
4. **Pattern Matching**: Correlated physical actions with event type bytes

### Communication Protocol

**Network**:
- **Protocol**: UDP broadcast
- **Port**: 38899 (same as bulb respond port)
- **Method**: `syncAccEvt` (different from bulbs' `syncPilot`)
- **Direction**: Unidirectional broadcast (no registration required)

**Message Format**:
```json
{
  "method": "syncAccEvt",
  "env": "pro",
  "params": {
    "mac": "9877d583fec5",
    "frame": "gb4AAAAgCQFgqyXB2g==",
    "rad": 1
  }
}
```

### Frame Structure

The `frame` field contains a base64-encoded 13-byte binary payload:

```
Offset  Size  Field           Description
------  ----  -----           -----------
0-1     2     Sequence        16-bit big-endian counter (increments with each event)
2-5     4     Fixed Header    Always 0x00 0x00 0x00 0x20
6       1     Event Type      See event mapping below
7       1     Action          Always 0x01 in all captured samples
8       1     State           Usually 0x60, occasionally 0x5f (meaning unknown)
9-12    4     Checksum/Time   Purpose unknown, varies per event
```

### Event Type Mapping

**IMPORTANT**: Based on real hardware testing, the correct mapping is:

| Type Byte | Event Description | Confirmed |
|-----------|------------------|-----------|
| **0x01** | Dial button short press | ✓ |
| **0x02** | Dial button long press | ✓ |
| **0x08** | Rotation **counter-clockwise** (per click) | ✓ |
| **0x09** | Rotation **clockwise** (per click) | ✓ |
| **0x10** | Scene button 1 short press | ✓ |
| **0x11** | Scene button 2 short press | ✓ |
| **0x12** | Scene button 1 long press | ✓ |
| **0x13** | Scene button 2 long press | ✓ |

**Note**: Initial analysis had 0x08 and 0x09 reversed. This was corrected after testing with real hardware.

### Key Findings

1. **Stepped Rotation**: Each "click" of the dial sends exactly one event. The rotation is discrete, not continuous degrees. This makes it ideal for incremental brightness/volume control.

2. **No Registration Required**: Unlike bulbs (which require periodic `syncPilot` registration), the dial broadcasts events freely. Just listen on port 38899.

3. **Sequence Numbers**: The sequence number increments with each event, allowing detection of missed events or duplicate packets.

4. **State Byte Mystery**: The state byte (offset 8) is usually 0x60, but was observed as 0x5f for one scene button long press event. The meaning is unclear but doesn't affect event detection.

5. **Long Press Timing**: Long press appears to trigger after ~1-2 seconds of holding the button/scene button.

## Implementation

### Core Classes

**lib/src/dial_event.dart**:
- `DialEventType` enum with 8 event types + unknown
- `DialEvent` class representing a single event
- `DialEvent.fromJson()` parser for UDP messages

**lib/src/dial_manager.dart**:
- Singleton manager listening on UDP port 38899
- Per-dial subscriptions by MAC address
- Optional global event callback
- **Automatic debouncing** for button press events (250ms window)
  - Prevents duplicate events from hardware bouncing
  - Applies only to button presses (dial button, scene buttons)
  - Rotation events are NOT debounced for fast responsiveness
  - Debouncing is per-MAC and per-event-type
- Test hooks for integration testing

**lib/src/wiz_dial.dart**:
- High-level `WizDial` class
- Simple API: `dial.startListening((event) => ...)`
- Automatic manager initialization

### Usage Example

```dart
import 'package:wizlight/wizlight.dart';

// Create dial and bulb instances
final dial = WizDial(mac: '9877d583fec5');
final bulb = Bulb()..setDeviceIP('192.168.1.100');

// Listen for dial events
await dial.startListening((event) async {
  switch (event.type) {
    case DialEventType.rotationClockwise:
      // Each click increases brightness by 5%
      final state = await bulb.updateState();
      final brightness = ((state?.brightness ?? 128) * 100 / 255).round();
      await bulb.setBrightness((brightness + 5).clamp(0, 100));
      break;

    case DialEventType.rotationCounterClockwise:
      // Each click decreases brightness by 5%
      final state = await bulb.updateState();
      final brightness = ((state?.brightness ?? 128) * 100 / 255).round();
      await bulb.setBrightness((brightness - 5).clamp(0, 100));
      break;

    case DialEventType.dialShortPress:
      // Toggle power
      await bulb.lightSwitch();
      break;

    case DialEventType.dialLongPress:
      // Set to 100% brightness
      await bulb.turnOn();
      await bulb.setBrightness(100);
      break;

    case DialEventType.scene1ShortPress:
      // Warm white
      await bulb.setColorTemp(2700);
      break;

    case DialEventType.scene2ShortPress:
      // Cool white
      await bulb.setColorTemp(6500);
      break;

    // ... handle other events
  }
});
```

### Sample Decoded Events

**Clockwise Rotation** (Type 0x09):
```
Frame: gb4AAAAgCQFgqyXB2g==
Hex:   81 be 00 00 00 20 09 01 60 ab 25 c1 da
Seq:   0x81be (33214)
Type:  0x09 (clockwise)
```

**Counter-Clockwise Rotation** (Type 0x08):
```
Frame: gcAAAAAgCAFgArKqzQ==
Hex:   81 c0 00 00 00 20 08 01 60 02 b2 aa cd
Seq:   0x81c0 (33216)
Type:  0x08 (counter-clockwise)
```

**Dial Long Press** (Type 0x02):
```
Frame: gckAAAAgAgFg0zQULQ==
Hex:   81 c9 00 00 00 20 02 01 60 d3 34 14 2d
Seq:   0x81c9 (33225)
Type:  0x02 (long press)
```

**Scene 1 Short Press** (Type 0x10):
```
Frame: gc4AAAAgEAFgZUibkQ==
Hex:   81 ce 00 00 00 20 10 01 60 65 48 9b 91
Seq:   0x81ce (33230)
Type:  0x10 (scene 1 short)
```

**Scene 1 Long Press** (Type 0x12, Different State):
```
Frame: gcoAAAAgEgFfMjoXPQ==
Hex:   81 ca 00 00 00 20 12 01 5f 32 3a 17 3d
Seq:   0x81ca (33226)
Type:  0x12 (scene 1 long)
State: 0x5f (unusual, typically 0x60)
```

## Testing

### Test Infrastructure

**test/helpers/fake_dial.dart**:
- `FakeDial` class simulates dial events for testing
- Sends properly formatted UDP broadcasts
- Convenience methods for each event type

**test/dial_event_test.dart**:
- 14 unit tests covering all event types
- Tests for invalid input handling
- Frame parsing validation

**test/integration/dial_integration_test.dart**:
- 8 integration tests with real UDP communication
- Tests manager subscriptions and callbacks
- Verifies event reception and handling

### Running Tests

```bash
# Unit tests
dart test test/dial_event_test.dart

# Integration tests
dart test test/integration/dial_integration_test.dart

# All tests
dart test
```

## Implementation Notes

### Design Decisions

1. **Singleton Manager**: Follows the same pattern as `PushManager` for consistency
2. **Event-Driven API**: Callback-based to match bulb push updates
3. **No State Tracking**: Dial has no state to query, only events to receive
4. **MAC-Based Subscription**: Allows multiple dials on the same network
5. **Automatic Debouncing**: Button presses are debounced (250ms) to prevent duplicate events from hardware bouncing

### Event Debouncing

The `DialManager` automatically debounces button press events to provide a better user experience:

- **What's debounced**: Dial button (short/long press) and scene buttons (short/long press)
- **What's NOT debounced**: Rotation events (clockwise/counter-clockwise) - preserved for fast rotation
- **Duration**: 250ms window - events of the same type within this window are filtered
- **Scope**: Per-MAC address and per-event-type (dial1's button is independent of dial2's button)
- **Benefit**: Eliminates duplicate events from hardware bouncing observed on real devices

### Port Sharing

The dial uses UDP port 38899, which is the same port bulbs use for responding to commands. This means:
- You can run both `Bulb` and `WizDial` in the same application
- The `DialManager` and `Bulb` responses don't interfere (different methods: `syncAccEvt` vs `getPilot`/`setPilot`)
- No port conflicts will occur

### Performance Considerations

- **Broadcast Nature**: All dials broadcast to all listeners. Use MAC filtering to ignore unwanted events.
- **No Polling**: Events arrive immediately when dial is used (no polling required)
- **Low Overhead**: Typical event rate is <10 events/second even with rapid rotation

## Troubleshooting

### Not Receiving Events

1. **Check Network**: Ensure device is on same subnet as dial
2. **Check Port**: Verify port 38899 is not blocked by firewall
3. **Check MAC**: Verify correct MAC address in subscription
4. **Check Manager**: Ensure `DialManager` is started before sending events

### Wrong Direction

If rotation direction is reversed:
- Verify you have the latest version with the corrected mapping
- Type 0x09 = clockwise, Type 0x08 = counter-clockwise

### Missed Events

- Check sequence numbers for gaps
- Reduce network latency if possible
- Events are UDP broadcasts (no delivery guarantee)

## Version History

- **2.1.0** (2025-11-08): Initial Smart Dial support
  - Complete protocol reverse engineering
  - Event parsing and handling
  - Test infrastructure
  - Examples and documentation
  - **Fix**: Corrected clockwise/counter-clockwise mapping based on real hardware testing

## References

- Original Python library: [pywizlight](https://github.com/sbidy/pywizlight)
- WiZ official documentation: Limited/unavailable for accessory devices
- Protocol: Fully reverse-engineered from network captures
