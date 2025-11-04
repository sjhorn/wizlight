# WizLight - Dart Package

A comprehensive Dart package for controlling WiZ smart light bulbs over UDP using the WiZ protocol. This is a port of the [wizlightcpp](https://github.com/srisham/wizlightcpp) C++ implementation.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- **Device Discovery**: Find WiZ bulbs on your network via broadcast
- **Basic Controls**: Turn lights on/off
- **Brightness Control**: Adjust dimming from 0-100%
- **Color Control**: Set RGB colors (0-255 per channel) or color temperature (1000-8000K)
- **Animation Control**: Set animation speed (0-100%) and preset scenes (32 scenes available)
- **Device Information**: Query device metadata, WiFi, system, and user configuration
- **Device Management**: Reboot devices remotely
- **CLI Tool**: Command-line interface for easy bulb control
- **Type Safe**: Full type safety with null-safety support

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  wizlight: ^1.0.0
```

Then run:

```bash
dart pub get
```

## Quick Start

### Library Usage

```dart
import 'package:wizlight/wizlight.dart';

void main() async {
  // Create a bulb instance
  final bulb = Bulb();
  bulb.setDeviceIP('192.168.1.100');

  // Turn the light on
  await bulb.toggleLight(true);

  // Set brightness to 75%
  await bulb.setBrightness(75);

  // Set RGB color to purple
  await bulb.setRGBColor(128, 0, 255);

  // Set a scene (Ocean = 1)
  await bulb.setScene(1);

  // Get current status
  final status = await bulb.getStatus();
  print(status);

  // Clean up
  bulb.close();
}
```

### CLI Usage

The package includes a command-line tool for controlling WiZ bulbs:

```bash
# Discover bulbs on the network
dart run wizlight discover --bcast 192.168.1.255

# Turn a bulb on
dart run wizlight on --ip 192.168.1.100

# Turn a bulb off
dart run wizlight off --ip 192.168.1.100

# Set brightness to 50%
dart run wizlight setbrightness --ip 192.168.1.100 --dim 50

# Set RGB color
dart run wizlight setrgbcolor --ip 192.168.1.100 --r 255 --g 128 --b 0

# Set color temperature (warm white)
dart run wizlight setcolortemp --ip 192.168.1.100 --temp 2700

# Set a scene
dart run wizlight setscene --ip 192.168.1.100 --scene 1

# Get help
dart run wizlight --help
dart run wizlight setscene --help
```

#### Interactive Mode

You can also run commands in interactive mode by providing only the command name:

```bash
dart run wizlight on
# Will prompt: Enter the bulb IP address:
```

## API Reference

### Bulb Class

The main class for controlling WiZ bulbs.

#### Device Management

```dart
void setDeviceIP(String ip)
String getDeviceIp()
void close()
```

#### Discovery

```dart
Future<String> discover(String broadcastIp)
```

Discovers WiZ bulbs on the network. Returns JSON with device info and IP address.

**Example:**
```dart
final result = await bulb.discover('192.168.1.255');
```

#### Status & Information

```dart
Future<String> getStatus()
Future<String> getDeviceInfo()
Future<String> getWifiConfig()
Future<String> getSystemConfig()
Future<String> getUserConfig()
```

Query bulb status and configuration information.

#### Basic Control

```dart
Future<String> toggleLight(bool state)
Future<String> reboot()
```

Turn lights on/off or reboot the device.

#### Brightness & Color

```dart
Future<String> setBrightness(int brightness)  // 0-100
Future<String> setRGBColor(int r, int g, int b)  // 0-255 each
Future<String> setColorTemp(int temp)  // 1000-8000 Kelvin
```

Control brightness and color.

**Examples:**
```dart
await bulb.setBrightness(75);  // 75% brightness
await bulb.setRGBColor(255, 0, 0);  // Red
await bulb.setColorTemp(3000);  // Warm white
```

#### Scenes & Animation

```dart
Future<String> setScene(int scene)  // 1-32
Future<String> setSpeed(int speed)  // 0-100
```

Set preset scenes and animation speed.

### Available Scenes

The package supports 32 preset scenes:

| ID | Scene | ID | Scene | ID | Scene |
|----|-------|----|-------|----|-------|
| 1 | Ocean | 12 | Daylight | 23 | Deepdive |
| 2 | Romance | 13 | Cool white | 24 | Jungle |
| 3 | Sunset | 14 | Night light | 25 | Mojito |
| 4 | Party | 15 | Focus | 26 | Club |
| 5 | Fireplace | 16 | Relax | 27 | Christmas |
| 6 | Cozy | 17 | True colors | 28 | Halloween |
| 7 | Forest | 18 | TV time | 29 | Candlelight |
| 8 | Pastel Colors | 19 | Plantgrowth | 30 | Golden white |
| 9 | Wake up | 20 | Spring | 31 | Pulse |
| 10 | Bedtime | 21 | Summer | 32 | Steampunk |
| 11 | Warm White | 22 | Fall | | |

### WizControl Class

Singleton class for command handling and CLI operations.

```dart
WizControl getInstance()
bool isCmdSupported(String cmd)
Future<bool> validateArgsUsage(List<String> args)
Future<String> performWizRequest(String cmd)
static void printUsage()
static String getSceneList()
```

## Protocol Details

### Communication

- **Protocol**: UDP
- **Port**: 38899
- **Format**: JSON
- **Timeout**: 2 seconds

### Request Format

```json
{
  "id": 1,
  "method": "setPilot",
  "params": {
    "state": true,
    "dimming": 75
  }
}
```

### Response Format

```json
{
  "bulb_response": {
    "mac": "123456789ABC",
    "rssi": -50,
    "state": true,
    "sceneId": 0,
    "temp": 3000,
    "dimming": 75
  }
}
```

## Examples

### Discover Bulbs

```dart
import 'package:wizlight/wizlight.dart';

void main() async {
  final bulb = Bulb();

  // Use your network's broadcast address
  final result = await bulb.discover('192.168.1.255');

  if (result.isNotEmpty) {
    print('Bulb discovered:');
    print(result);
  }

  bulb.close();
}
```

### Create a Light Show

```dart
import 'package:wizlight/wizlight.dart';

void main() async {
  final bulb = Bulb();
  bulb.setDeviceIP('192.168.1.100');

  // Turn on
  await bulb.toggleLight(true);

  // Cycle through colors
  final colors = [
    [255, 0, 0],    // Red
    [255, 165, 0],  // Orange
    [255, 255, 0],  // Yellow
    [0, 255, 0],    // Green
    [0, 0, 255],    // Blue
    [128, 0, 255],  // Purple
  ];

  for (final color in colors) {
    await bulb.setRGBColor(color[0], color[1], color[2]);
    await Future.delayed(Duration(seconds: 2));
  }

  bulb.close();
}
```

### Input Validation

All methods validate input ranges and return `"Invalid_Request"` for out-of-range values:

```dart
// These will return "Invalid_Request"
await bulb.setBrightness(150);  // Valid: 0-100
await bulb.setRGBColor(300, 0, 0);  // Valid: 0-255
await bulb.setColorTemp(10000);  // Valid: 1000-8000
await bulb.setScene(99);  // Valid: 1-32
```

## Testing

Run the test suite:

```bash
dart test
```

The package includes comprehensive unit tests for:
- Input validation
- JSON request format
- Response parsing
- Command handling
- Protocol constants

## Development

### Project Structure

```
wizlight/
├── bin/
│   └── wizlight.dart       # CLI entry point
├── lib/
│   ├── wizlight.dart       # Main library export
│   └── src/
│       ├── bulb.dart       # Bulb control class
│       ├── udp_socket.dart # UDP communication
│       └── wiz_control.dart # Command handling
├── test/
│   ├── bulb_test.dart      # Bulb class tests
│   └── wiz_control_test.dart # WizControl tests
├── example/
│   └── main.dart           # Usage examples
└── pubspec.yaml
```

### Code Style

This project follows the [Dart style guide](https://dart.dev/guides/language/effective-dart/style):

- Two spaces for indentation
- Prefer `final` and `const`
- Use Dartdoc comments (`///`) for public APIs
- Null-safety enforced

### Format and Analyze

```bash
dart format .
dart analyze
```

## Platform Support

- **Dart SDK**: >=3.0.0 <4.0.0
- **Platforms**: All platforms supporting Dart (Linux, macOS, Windows)
- **Dependencies**:
  - `args` - Command-line argument parsing
  - `logging` - Structured logging

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Original C++ implementation Copyright (c) 2022 Sri Balaji S.
Dart port Copyright (c) 2025.

## Credits

- Original C++ implementation: [wizlightcpp](https://github.com/srisham/wizlightcpp) by Sri Balaji S.
- WiZ protocol documentation and community contributions

## Troubleshooting

### Bulb not responding

1. Ensure the bulb is on the same network
2. Check firewall settings (UDP port 38899)
3. Verify the IP address is correct
4. Try discovery mode to find the bulb's IP

### Discovery not working

1. Use the correct broadcast address for your network
2. Check network configuration (subnet mask)
3. Ensure broadcast is enabled on your network interface

### Timeout errors

- Default timeout is 2 seconds
- Check network latency
- Ensure bulb is powered on and connected to WiFi

## Related Projects

- [wizlightcpp](https://github.com/srisham/wizlightcpp) - Original C++ implementation
- [pywizlight](https://github.com/sbidy/pywizlight) - Python implementation

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
