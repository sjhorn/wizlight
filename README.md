# WizLight - Dart Package

A dart package for controlling WiZ smart devices over UDP. This is a port of the popular [pywizlight](https://github.com/sbidy/pywizlight) Python library, originally based on [wizlightcpp](https://github.com/srisham/wizlightcpp).

[![pub package](https://img.shields.io/pub/v/wizlight.svg)](https://pub.dev/packages/wizlight)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🌟 New Features

This is a **rewrite** with features from pywizlight:
- ✨ **API** with `PilotBuilder` and `PilotParser`
- 🔔 **Push Updates** - Real-time state change notifications
- 🎛️ **Smart Dial Support** - WiZ Smart Dial Switch event handling (NEW in 2.1.0!)
- 🎨 **Extended Colors** - RGBW, RGBWW, individual white LED control
- 🔍 **Capability Detection** - Automatic bulb type and feature detection
- ⚡ **Robust Communication** - Progressive backoff retry (6 attempts over 13s)
- 🔌 **Extended Device Support** - Smart plugs, ceiling fans, all bulb types
- 📊 **Power Monitoring** - Wattage tracking for smart plugs
- 🌀 **Fan Control** - Full ceiling fan controller support

## Supported Devices

| Device Type | Features |
|------------|----------|
| **RGB Bulbs** | Full color, tunable white, scenes, push updates |
| **Tunable White** | Color temperature, brightness, scenes |
| **Dimmable White** | Brightness only, basic scenes |
| **Smart Plugs** | On/off, **power monitoring** |
| **Ceiling Fans** | Light control + **fan control** |
| **Wall Switches** | On/off control |
| **Smart Dial** | Rotation, button events, scene buttons (NEW!) |

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  wizlight: ^2.0.0
```

Then run:

```bash
dart pub get
```

## Quick Start

### Modern API (Recommended)

```dart
import 'package:wizlight/wizlight.dart';

void main() async {
  final bulb = Bulb();
  bulb.setDeviceIP('192.168.1.100');

  // Turn on with PilotBuilder
  final builder = PilotBuilder()
    ..brightness = 200
    ..colorTemp = 2700;
  await bulb.turnOn(builder);

  // Get typed state
  final state = await bulb.updateState();
  print('Brightness: ${state?.brightness}');
  print('Temp: ${state?.colorTemp}K');

  // State-aware toggle
  await bulb.lightSwitch();
}
```

### Legacy API (Still Supported)

```dart
import 'package:wizlight/wizlight.dart';

void main() async {
  final bulb = Bulb();
  bulb.setDeviceIP('192.168.1.100');

  await bulb.toggleLight(true);
  await bulb.setBrightness(75);
  await bulb.setRGBColor(128, 0, 255);
  await bulb.setScene(1);
}
```

## Core Features

### 1. Device Capability Detection

```dart
// Detect what your bulb can do
final bulbType = await bulb.getBulbType();
print('Type: ${bulbType?.bulbType}');
print('Supports color: ${bulbType?.features.color}');
print('Kelvin range: ${bulbType?.kelvinRange}');

// Get supported scenes
final scenes = await bulb.getSupportedScenes();
print('Available: $scenes');
```

### 2. Push Updates (Real-time State Changes)

```dart
// Get instant notifications without polling!
await bulb.startPush((state, ip) {
  print('State changed!');
  print('  On: ${state.state}');
  print('  Brightness: ${state.brightness}');
  print('  Source: ${state.source}'); // 'udp', 'pir', 'wfa1', etc.
});

// Changes from wall switch, app, or motion sensor
// will trigger the callback automatically!
```

### 3. Extended Color Control

```dart
// RGB (3 channels)
await bulb.setRGBColor(255, 0, 0);

// RGBW (4 channels: RGB + warm white)
await bulb.setRgbw(255, 100, 0, 150);

// RGBWW (5 channels: RGB + cold white + warm white)
await bulb.setRgbww(255, 0, 0, 100, 200);

// Individual white LED control
await bulb.setWarmWhite(200);
await bulb.setColdWhite(150);
```

### 4. Smart Plug Power Monitoring

```dart
// Get current power consumption
final watts = await bulb.getPower();
if (watts != null) {
  print('Power: ${watts.toStringAsFixed(2)}W');
}
```

### 5. Ceiling Fan Control

```dart
// Turn fan on with settings
await bulb.fanTurnOn(mode: 1, speed: 3);

// Full control
await bulb.fanSetState(
  state: 1,      // on
  mode: 2,       // breeze mode
  speed: 6,      // max speed
  reverse: 0,    // summer mode
);

// Toggle fan
await bulb.fanSwitch();
```

### WiZ Smart Dial Switch (NEW in 2.1.0!)

Listen for events from WiZ Smart Dial Switch (model 9290037923):

```dart
import 'package:wizlight/wizlight.dart';

// Create a dial instance
final dial = WizDial(mac: '9877d583fec5', name: 'Living Room');

// Start listening for events
await dial.startListening((event) {
  switch (event.type) {
    case DialEventType.rotationClockwise:
      print('Turned right');
      break;
    case DialEventType.rotationCounterClockwise:
      print('Turned left');
      break;
    case DialEventType.dialShortPress:
      print('Button pressed');
      break;
    case DialEventType.dialLongPress:
      print('Button held');
      break;
    case DialEventType.scene1ShortPress:
      print('Scene 1 pressed');
      break;
    case DialEventType.scene2ShortPress:
      print('Scene 2 pressed');
      break;
    // ... and more
  }
});

// Example: Control bulb brightness with dial
final bulb = Bulb();
bulb.setDeviceIP('192.168.1.100');

dial.startListening((event) async {
  if (event.type == DialEventType.rotationClockwise) {
    // Increase brightness
    final state = await bulb.updateState();
    final brightness = ((state?.brightness ?? 128) * 100 / 255).round();
    await bulb.setBrightness((brightness + 5).clamp(0, 100));
  }
});
```

See `example/dial_controlled_bulb.dart` for a complete example.

## API Reference

### Modern Control Methods

```dart
// Core control
Future<void> turnOn([PilotBuilder? pilot])
Future<void> turnOff()
Future<void> lightSwitch()  // State-aware toggle
Future<void> setState(PilotBuilder pilot)

// State management
Future<PilotParser?> updateState()
PilotParser? get state  // Cached state

// Device info
Future<String?> getMac()
Future<Map<String, dynamic>?> getModelConfig()
Future<void> reset()
Future<BulbType?> getBulbType()
Future<List<double>?> getWhiteRange()
Future<List<double>?> getExtendedWhiteRange()
Future<List<String>> getSupportedScenes()

// Extended color
Future<void> setRgbw(int r, int g, int b, int w)
Future<void> setRgbww(int r, int g, int b, int c, int w)
Future<void> setWarmWhite(int value)
Future<void> setColdWhite(int value)
Future<void> setRatio(int ratio)  // Up/down light ratio

// Power monitoring
Future<double?> getPower()

// Fan control
Future<void> fanTurnOn({int? mode, int? speed})
Future<void> fanTurnOff()
Future<void> fanSetState({int? state, int? mode, int? speed, int? reverse})
Future<void> fanSwitch()
Future<int?> getFanSpeedRange()

// Push updates
Future<bool> startPush(PushCallback callback)
Future<void> stopPush()
void setDiscoveryCallback(DiscoveryCallback callback)
```

### PilotBuilder

Fluent API for building bulb commands:

```dart
final builder = PilotBuilder()
  ..brightness = 200           // 0-255
  ..colorTemp = 2700           // 1000-10000K
  ..setRgb(255, 0, 0)          // RGB color
  ..setRgbw(255, 0, 0, 150)    // RGBW color
  ..setRgbww(255, 0, 0, 100, 200)  // RGBWW color
  ..warmWhite = 200            // Warm white LED
  ..coldWhite = 150            // Cold white LED
  ..scene = 1                  // Scene ID
  ..sceneName = 'Ocean'        // Scene name
  ..speed = 100                // Animation speed (10-200)
  ..ratio = 50                 // Up/down ratio (0-100)
  ..state = true;              // On/off state

// Use with turn on
await bulb.turnOn(builder);

// Or get raw message
final msg = builder.setPilotMessage(state: true);
```

### PilotParser

Typed access to bulb state:

```dart
final state = await bulb.updateState();

// Basic state
state?.state            // bool - on/off
state?.brightness       // int - 0-255
state?.colorTemp        // int - kelvin
state?.scene            // String - scene name
state?.sceneId          // int - scene ID
state?.source           // String - change source
state?.mac              // String - MAC address

// Colors
state?.rgb              // (int, int, int) - RGB tuple
state?.rgbw             // (int, int, int, int) - RGBW tuple
state?.rgbww            // (int, int, int, int, int) - RGBWW tuple
state?.warmWhite        // int - warm white LED
state?.coldWhite        // int - cold white LED

// Extended
state?.speed            // int - animation speed
state?.ratio            // int - up/down ratio
state?.power            // double - watts
state?.rssi             // int - WiFi signal
state?.whiteRange       // List<double> - kelvin range
state?.extendedWhiteRange  // List<double> - extended range

// Fan (ceiling fans)
state?.fanState         // int - 0=off, 1=on
state?.fanMode          // int - 1=normal, 2=breeze
state?.fanSpeed         // int - speed level
state?.fanReverse       // int - 0=normal, 1=reverse
state?.fanSpeedRange    // int - max speed
```

### BulbType

Device capability detection:

```dart
final bulbType = await bulb.getBulbType();

// Classification
bulbType?.bulbType      // BulbClass enum (rgb, tw, dw, socket, fandim)
bulbType?.name          // String - module name
bulbType?.fwVersion     // String - firmware version

// Feature flags
bulbType?.features.color        // bool - supports RGB
bulbType?.features.colorTemp    // bool - supports kelvin
bulbType?.features.brightness   // bool - supports dimming
bulbType?.features.effect       // bool - supports scenes
bulbType?.features.dualHead     // bool - dual direction
bulbType?.features.fan          // bool - has fan
bulbType?.features.fanBreezeMode  // bool - breeze mode
bulbType?.features.fanReverse    // bool - reverse rotation

// Ranges
bulbType?.kelvinRange?.min      // int - min kelvin
bulbType?.kelvinRange?.max      // int - max kelvin
bulbType?.whiteChannels         // int - number of white LEDs
bulbType?.whiteToColorRatio     // int - white/color ratio
bulbType?.fanSpeedRange         // int - max fan speed
```

## Available Scenes

46 scenes supported (bulb-dependent):

| ID | Scene | ID | Scene | ID | Scene |
|----|-------|----|-------|----|-------|
| 1 | Ocean | 16 | Relax | 31 | Pulse |
| 2 | Romance | 17 | True colors | 32 | Steampunk |
| 3 | Sunset | 18 | TV time | 33 | Diwali |
| 4 | Party | 19 | Plantgrowth | 34 | White |
| 5 | Fireplace | 20 | Spring | 35 | Alarm |
| 6 | Cozy | 21 | Summer | 36 | Snowy sky |
| 7 | Forest | 22 | Fall | 1000 | Rhythm |
| 8 | Pastel colors | 23 | Deep dive | | |
| 9 | Wake-up | 24 | Jungle | | |
| 10 | Bedtime | 25 | Mojito | | |
| 11 | Warm white | 26 | Club | | |
| 12 | Daylight | 27 | Christmas | | |
| 13 | Cool white | 28 | Halloween | | |
| 14 | Night light | 29 | Candlelight | | |
| 15 | Focus | 30 | Golden white | | |

## Examples

See the `example/` directory for comprehensive examples:

- **`modern_api.dart`** - Demonstrates all new features
- **`push_updates.dart`** - Real-time state change notifications
- **`advanced_colors.dart`** - RGB, RGBW, RGBWW color control
- **`bulb_capabilities.dart`** - Capability detection and adaptive control
- **`main.dart`** - Legacy API examples

### Run Examples

```bash
dart run example/modern_api.dart
dart run example/push_updates.dart
dart run example/advanced_colors.dart
dart run example/bulb_capabilities.dart
```

## CLI Usage

Command-line interface for quick bulb control:

```bash
# Discover bulbs
dart run wizlight discover --bcast 192.168.1.255

# Control bulb
dart run wizlight on --ip 192.168.1.100
dart run wizlight off --ip 192.168.1.100
dart run wizlight setbrightness --ip 192.168.1.100 --dim 50

# RGB color
dart run wizlight setrgbcolor --ip 192.168.1.100 --r 255 --g 0 --b 0

# Color temperature
dart run wizlight setcolortemp --ip 192.168.1.100 --temp 2700

# Scenes
dart run wizlight setscene --ip 192.168.1.100 --scene 1

# Help
dart run wizlight --help
```

## Protocol Details

### Communication

- **Protocol**: UDP
- **Port**: 38899 (control), 38900 (push updates)
- **Format**: JSON
- **Timeout**: 13 seconds with progressive backoff
- **Retries**: 6 attempts (0s, 0.75s, 2.25s, 5.25s, 8.25s, 11.25s)

### Progressive Backoff

Unlike the original implementation, this port includes robust retry logic:
- Sends multiple datagrams with increasing delays
- Much better reliability for distant bulbs
- Configurable timeout and retry parameters

### Request Serialization

All requests are serialized to prevent race conditions and response mismatches.

## Testing

```bash
dart test
```

35 tests covering:
- Input validation
- JSON request format
- Response parsing
- Protocol constants
- All control methods

## Migration Guide

### From v1.x to v2.x

**Old API** (still works):
```dart
await bulb.toggleLight(true);
final status = await bulb.getStatus();  // Returns JSON string
```

**New API** (recommended):
```dart
await bulb.turnOn();
final state = await bulb.updateState();  // Returns PilotParser
print(state?.brightness);
```

**Benefits of new API:**
- Typed state access
- Better error handling with exceptions
- Push updates support
- Feature detection
- Extended color modes

## Troubleshooting

### Bulb Not Responding

1. Check IP address is correct
2. Ensure bulb is on same network
3. Check firewall (UDP ports 38899, 38900)
4. Try discovery mode to find bulb IP

### Push Updates Not Working

1. Port 38900 must be available
2. Check firewall allows UDP incoming
3. Ensure no other apps using port 38900
4. Falls back to polling if push fails

### Timeout Errors

- Default timeout is 13 seconds with 6 retries
- Check network latency
- Ensure bulb is powered and connected

### Extended Features Not Available

- Check bulb capabilities with `getBulbType()`
- Not all features work on all bulb types
- Older firmware may not support newer methods

## Platform Support

- **Dart SDK**: >=3.0.0 <4.0.0
- **Platforms**: All platforms (Linux, macOS, Windows, mobile)
- **Dependencies**:
  - `args` - CLI parsing
  - `logging` - Structured logging

## Contributing

Contributions welcome! Please submit Pull Requests.

1. Fork the repository
2. Create feature branch
3. Add tests for new features
4. Ensure all tests pass
5. Submit Pull Request

## License

MIT License - see [LICENSE](LICENSE) file.

Original C++ implementation © 2022 Sri Balaji S.
Python pywizlight © Stephan Traub
Dart port © 2025

## Credits

- **pywizlight**: [sbidy/pywizlight](https://github.com/sbidy/pywizlight) - Primary reference
- **wizlightcpp**: [srisham/wizlightcpp](https://github.com/srisham/wizlightcpp) - Original port base
- WiZ protocol documentation and community

## Related Projects

- [pywizlight](https://github.com/sbidy/pywizlight) - Python (reference implementation)
- [wizlightcpp](https://github.com/srisham/wizlightcpp) - C++
- [Home Assistant WiZ Integration](https://www.home-assistant.io/integrations/wiz/) - Uses pywizlight

## Changelog

### v2.0.0 - pywizlight Port

**Major Features:**
- ✨ Modern API with `PilotBuilder` and `PilotParser`
- 🔔 Push updates for real-time state notifications
- 🎨 Extended color modes (RGBW, RGBWW, individual white LEDs)
- 🔍 Automatic bulb type and capability detection
- ⚡ Progressive backoff retry (6 attempts over 13s)
- 📊 Power monitoring for smart plugs
- 🌀 Full ceiling fan controller support
- 🏗️ Request serialization with async locks
- 🎯 Typed exceptions for proper error handling
- 📚 Comprehensive documentation and examples

**New Classes:**
- `PilotBuilder` - Command builder with fluent API
- `PilotParser` - Typed state parsing
- `BulbType` - Capability detection
- `PushManager` - Push update manager
- Exception hierarchy

**New Methods:**
- 40+ new methods in `Bulb` class
- Push updates: `startPush()`, `stopPush()`
- Modern control: `turnOn()`, `turnOff()`, `lightSwitch()`
- State: `updateState()`, `state` getter
- Extended colors: `setRgbw()`, `setRgbww()`, `setWarmWhite()`, `setColdWhite()`
- Capabilities: `getBulbType()`, `getSupportedScenes()`
- Fan control: `fanTurnOn()`, `fanTurnOff()`, `fanSetState()`, `fanSwitch()`
- Power: `getPower()`

**Backward Compatibility:**
- All v1.x methods still supported
- No breaking changes to existing code

See [pywizlight_port.md](pywizlight_port.md) for complete implementation plan.

### v1.0.0 - Initial Release

- Basic bulb control
- Discovery
- RGB colors and color temperature
- Scenes and brightness
- CLI tool
