/// WizLight - A complete Dart library for controlling WiZ smart devices
///
/// This library provides a comprehensive interface for controlling WiZ smart devices
/// over UDP using the WiZ protocol. It's a feature-complete port of the popular
/// [pywizlight](https://github.com/sbidy/pywizlight) Python library to Dart.
///
/// ## Supported Devices
///
/// - **RGB Bulbs** - Full color control with tunable white
/// - **Tunable White Bulbs** - Adjustable color temperature
/// - **Dimmable White Bulbs** - Brightness control only
/// - **Smart Plugs** - On/off control with power monitoring
/// - **Ceiling Fans** - Light and fan control
/// - **Wall Switches** - Basic on/off control
///
/// ## Core Features
///
/// ### Device Discovery
/// - Broadcast discovery of WiZ devices on your network
/// - Automatic device type detection with capability flags
///
/// ### Modern Control API
/// - **Turn On/Off**: `turnOn()`, `turnOff()`, `lightSwitch()`
/// - **Brightness**: 0-255 with hardware minimum of 10%
/// - **RGB Colors**: 3-channel (RGB), 4-channel (RGBW), 5-channel (RGBWW)
/// - **Color Temperature**: 1000-10000K (device-dependent range)
/// - **White LEDs**: Individual warm/cold white control
/// - **Scenes**: 46 preset scenes with device-specific support
/// - **Effects**: Speed control for animated scenes
/// - **Dual-Direction**: Ratio control for up/down lights
///
/// ### Advanced Features
/// - **Push Updates**: Real-time state change notifications (no polling!)
/// - **State Management**: Cached state with typed parsing via `PilotParser`
/// - **Command Building**: Fluent API via `PilotBuilder`
/// - **Bulb Capabilities**: Feature detection with `BulbType`
/// - **Power Monitoring**: Get wattage from smart plugs
/// - **Fan Control**: Full ceiling fan control (speed, mode, reverse)
///
/// ### Robust Communication
/// - Progressive backoff retry logic (6 attempts over 13 seconds)
/// - Request serialization to prevent race conditions
/// - Typed exceptions for proper error handling
/// - Configurable timeout and retry parameters
///
/// ## Quick Start
///
/// ### Basic Control
/// ```dart
/// import 'package:wizlight/wizlight.dart';
///
/// void main() async {
///   final bulb = Bulb();
///   bulb.setDeviceIP('192.168.1.100');
///
///   // Modern API with PilotBuilder
///   final builder = PilotBuilder()
///     ..brightness = 200
///     ..colorTemp = 2700;
///   await bulb.turnOn(builder);
///
///   // Get typed state
///   final state = await bulb.updateState();
///   print('Brightness: ${state?.brightness}');
///   print('Color temp: ${state?.colorTemp}K');
///
///   // Toggle based on current state
///   await bulb.lightSwitch();
/// }
/// ```
///
/// ### Device Capabilities
/// ```dart
/// // Detect bulb type and capabilities
/// final bulbType = await bulb.getBulbType();
/// print('Type: ${bulbType?.bulbType}');
/// print('Supports color: ${bulbType?.features.color}');
/// print('Kelvin range: ${bulbType?.kelvinRange}');
///
/// // Get supported scenes
/// final scenes = await bulb.getSupportedScenes();
/// print('Available scenes: $scenes');
/// ```
///
/// ### Push Updates (Real-time)
/// ```dart
/// // Enable push updates for instant notifications
/// await bulb.startPush((state, ip) {
///   print('State changed!');
///   print('  On: ${state.state}');
///   print('  Brightness: ${state.brightness}');
///   print('  Source: ${state.source}'); // 'udp', 'pir', 'wfa1', etc.
/// });
///
/// // Changes from wall switch, app, or motion sensor
/// // will now trigger the callback automatically!
/// ```
///
/// ### Extended Colors
/// ```dart
/// // RGB (3 channels)
/// await bulb.setRGBColor(255, 0, 0);
///
/// // RGBW (4 channels: RGB + warm white)
/// await bulb.setRgbw(255, 100, 0, 150);
///
/// // RGBWW (5 channels: RGB + cold white + warm white)
/// await bulb.setRgbww(255, 0, 0, 100, 200);
///
/// // Individual white control
/// await bulb.setWarmWhite(200);
/// await bulb.setColdWhite(150);
/// ```
///
/// ### Smart Plug Power Monitoring
/// ```dart
/// // Get power consumption in watts
/// final watts = await bulb.getPower();
/// if (watts != null) {
///   print('Current power: ${watts.toStringAsFixed(2)}W');
/// }
/// ```
///
/// ### Ceiling Fan Control
/// ```dart
/// // Turn fan on with specific settings
/// await bulb.fanTurnOn(mode: 1, speed: 3);
///
/// // Full control
/// await bulb.fanSetState(
///   state: 1,      // on
///   mode: 2,       // breeze mode
///   speed: 6,      // max speed
///   reverse: 0,    // summer mode
/// );
///
/// // Toggle fan
/// await bulb.fanSwitch();
/// ```
///
/// ## Legacy API
///
/// The library maintains backward compatibility with the original API:
/// ```dart
/// // Legacy methods (still supported but deprecated)
/// await bulb.toggleLight(true);  // Use turnOn() instead
/// await bulb.setBrightness(75);
/// await bulb.setRGBColor(255, 0, 0);
/// await bulb.setScene(1);
/// ```
///
/// ## More Information
///
/// - For CLI usage, see the `bin/wizlight.dart` command-line tool
/// - For complete API documentation, see individual class documentation
/// - Migration guide: See pywizlight_port.md for porting notes
library;

export 'src/bulb.dart';
export 'src/bulb_type.dart';
export 'src/color_utils.dart';
export 'src/discovery.dart';
export 'src/exceptions.dart';
export 'src/pilot_builder.dart';
export 'src/pilot_parser.dart';
export 'src/push_manager.dart';
export 'src/scenes.dart';
export 'src/udp_socket.dart';
export 'src/wiz_control.dart';
