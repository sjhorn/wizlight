/// WizLight - A Dart library for controlling WiZ smart light bulbs
///
/// This library provides a complete interface for controlling WiZ smart bulbs
/// over UDP using the WiZ protocol. It supports device discovery, state control,
/// color control, brightness adjustment, scenes, and device information queries.
///
/// ## Features
///
/// - **Device Discovery**: Find WiZ bulbs on your network via broadcast
/// - **Basic Controls**: Turn lights on/off
/// - **Brightness Control**: Adjust dimming from 0-100%
/// - **Color Control**: Set RGB colors or color temperature (1000-8000K)
/// - **Animation Control**: Set animation speed and preset scenes (32 scenes)
/// - **Device Information**: Query device, WiFi, system, and user configuration
/// - **Device Management**: Reboot devices
///
/// ## Usage
///
/// ```dart
/// import 'package:wizlight/wizlight.dart';
///
/// void main() async {
///   final bulb = Bulb();
///   bulb.setDeviceIP('192.168.1.100');
///
///   // Turn the light on
///   await bulb.toggleLight(true);
///
///   // Set brightness to 75%
///   await bulb.setBrightness(75);
///
///   // Set RGB color to red
///   await bulb.setRGBColor(255, 0, 0);
///
///   // Set a scene (e.g., Ocean)
///   await bulb.setScene(1);
///
///   bulb.close();
/// }
/// ```
///
/// For CLI usage, see the `bin/wizlight.dart` command-line tool.
library;

export 'src/bulb.dart';
export 'src/udp_socket.dart';
export 'src/wiz_control.dart';
