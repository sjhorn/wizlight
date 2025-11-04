# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
