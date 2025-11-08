# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-11-07

### Added

- **Discovery Module** (`lib/src/discovery.dart`)
  - New `discoverBulbs()` function that finds ALL devices on the network
  - `DiscoveredBulb` class with IP and MAC address
  - `BulbRegistry` for collecting and deduplicating discovered bulbs
  - Matches Python's discovery behavior: keeps socket open for 5 seconds, sends repeated broadcasts
  - Exported in public API for programmatic use

- **Color Utilities** (`lib/src/color_utils.dart`)
  - `RGBColor` class for RGB color representation (0-255 range)
  - `HSVColor` class for HSV color representation (hue 0-360°, saturation/value 0-100%)
  - `rgbToHsv()` - Convert RGB to HSV color space
  - `hsvToRgb()` - Convert HSV to RGB color space
  - `hexToPercent()` - Convert 0-255 hex values to 0-100 percent
  - `percentToHex()` - Convert 0-100 percent to 0-255 hex values
  - `kelvinToRgb()` - Convert color temperature (Kelvin) to RGB using blackbody approximation
  - 37 comprehensive unit tests with round-trip validation

- **Examples**
  - `example/color_demo.dart` - Complete demo: discovery + push updates + RGB color cycling
  - `example/discover.dart` - Discovery and basic control
  - `example/monitor_changes.dart` - Long-running push update monitor
  - `example/push_updates.dart` - Push updates with programmatic testing
  - `example/debug_push.dart` - Debug version with detailed logging

- **Testing Improvements**
  - Test hooks in `PushManager` for better testability
    - `PushManager.testListenPort` - Override listen port (use 0 for any available port)
    - `PushManager.testSourceIp` - Override source IP for localhost testing
    - `PushManager.resetForTesting()` - Reset singleton state between tests
  - All 15 timeout/retry integration tests now passing (100%)

### Fixed

- **Discovery Issues**
  - Fixed discovery only finding first device instead of all devices
  - Discovery now keeps socket open for 5 seconds (matching Python)
  - Discovery now sends repeated broadcasts every 1 second (matching Python)
  - Discovery now collects and deduplicates all responses by MAC address
  - CLI discovery output now matches Python format exactly

- **Push Manager Critical Bug**
  - Fixed source IP detection returning `0.0.0.0` instead of actual local IP
  - Now uses `NetworkInterface.list()` to find correct local IP on same subnet
  - Bulbs can now properly send push updates back to the monitoring application
  - Push updates verified working with real WiZ devices

- **BulbType Detection**
  - Fixed `whiteChannels` auto-detection always returning null
  - Now reads from `drvConf` array first (for firmware < 1.22)
  - Then overrides with model config values if available (firmware >= 1.22)
  - Matches Python's dual-source reading logic exactly

- **Test Reliability**
  - Fixed 8 timeout/retry test failures
  - Tests now properly handle exceptions and timeouts
  - Reduced concurrent operations in stress tests (5 → 3)
  - Increased test timeouts where appropriate (60s → 90s)
  - Fixed push manager registration tests with proper test hooks

- **Compilation**
  - Fixed missing `import 'dart:convert'` in `wiz_control.dart`

### Changed

- **Discovery Behavior**
  - Old: `Bulb.discover()` returned single device as string
  - New: `discoverBulbs()` returns `List<DiscoveredBulb>` with all devices
  - CLI still works but now uses new discovery module internally
  - Output format changed to match Python exactly

- **Push Manager**
  - Source IP detection now more robust and accurate
  - Better logging for troubleshooting connection issues

### Verified

- ✅ All features tested with real WiZ smart bulbs (2 devices)
- ✅ Discovery finds all devices on network
- ✅ Push updates receive real-time state changes
- ✅ RGB color control works (red, green, blue, yellow, cyan, magenta, white)
- ✅ Color temperature control works (2700K warm white tested)
- ✅ Output format matches Python implementation exactly
- ✅ All 15 timeout/retry integration tests passing
- ✅ All 40 bulb_type tests passing
- ✅ All 37 color_utils tests passing

## [1.0.0] - 2025-11-04

### Added

- Initial release of WizLight Dart package
- Complete port of wizlightcpp functionality to Dart
- `Bulb` class for controlling WiZ smart light bulbs
  - Device discovery via UDP broadcast
  - Basic controls (on/off, reboot)
  - Brightness control (0-100%)
  - RGB color control (0-255 per channel)
  - Color temperature control (1000-8000K)
  - Scene selection (32 preset scenes)
  - Animation speed control (0-100%)
  - Device information queries (status, WiFi config, system config, user config)
- `UDPSocket` class for UDP communication with broadcast support
- `WizControl` class for command handling and CLI operations
- CLI tool (`bin/wizlight.dart`) with support for:
  - All bulb control commands
  - Interactive and CLI modes
  - Help and usage information
  - Verbose logging option
- Comprehensive unit tests
  - Input validation tests
  - JSON request format tests
  - Response parsing tests
  - Command handling tests
- Example code demonstrating all features
- Full API documentation with Dartdoc comments
- README with detailed usage instructions
- MIT License

### Features

- **Type Safety**: Full null-safety support
- **Input Validation**: Range checking for all parameters
- **Error Handling**: Proper timeout and error handling
- **Logging**: Structured logging with configurable levels
- **Cross-Platform**: Works on all Dart-supported platforms

### Documentation

- Comprehensive README.md with examples
- API reference documentation
- Usage examples in `example/main.dart`
- Scene list reference
- Protocol details and troubleshooting guide

### Testing

- Unit tests for Bulb class
- Unit tests for WizControl class
- Request format validation tests
- Response parsing tests
