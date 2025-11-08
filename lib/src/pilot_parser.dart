// Dart port of pywizlight PilotParser
// See LICENSE file for licensing details.

import 'scenes.dart';

/// RGB color tuple
typedef RgbColor = (int r, int g, int b);

/// RGBW color tuple (RGB + warm white)
typedef RgbwColor = (int r, int g, int b, int w);

/// RGBWW color tuple (RGB + cold white + warm white)
typedef RgbwwColor = (int r, int g, int b, int c, int w);

/// Parses pilot responses from WiZ bulbs
///
/// The PilotParser interprets JSON responses from getPilot and syncPilot
/// messages, providing typed getters for all state properties.
///
/// Example usage:
/// ```dart
/// final parser = PilotParser({'state': true, 'dimming': 50, 'temp': 2700});
/// print(parser.state); // true
/// print(parser.brightness); // 127 (50% of 255)
/// print(parser.colorTemp); // 2700
/// ```
class PilotParser {
  /// The raw pilot result from the bulb
  final Map<String, dynamic> pilotResult;

  /// Creates a parser for the given pilot result
  PilotParser(this.pilotResult);

  /// Gets the on/off state of the bulb
  ///
  /// Returns true if the bulb is on, false if off, null if not present.
  bool? get state => _extractBool('state');

  /// Gets the source of the state change
  ///
  /// Possible values include:
  /// - 'udp' - Changed via UDP command
  /// - 'pir' - Changed by PIR motion sensor
  /// - 'wfa1', 'wfa2', etc. - Changed by WizMote button press
  String? get source => _extractString('src');

  /// Gets the MAC address of the bulb
  String? get mac => _extractString('mac');

  /// Gets the power consumption in watts
  ///
  /// Available on smart plugs with power monitoring.
  /// Returns null if power monitoring is not supported or data not available.
  double? get power {
    final milliWatts = _extractInt('pc');
    return milliWatts != null ? milliWatts / 1000.0 : null;
  }

  /// Gets the warm white LED value (0-255)
  int? get warmWhite => _extractInt('w');

  /// Gets the cold white LED value (0-255)
  int? get coldWhite => _extractInt('c');

  /// Gets the white range values
  ///
  /// Returns a list of floats representing the white temperature range.
  List<double>? get whiteRange {
    if (pilotResult.containsKey('whiteRange')) {
      final range = pilotResult['whiteRange'];
      if (range is List) {
        return range.map((e) => (e as num).toDouble()).toList();
      }
    }
    return null;
  }

  /// Gets the extended white range values
  ///
  /// This includes extended color temperature ranges on newer firmware.
  /// Checks both 'extRange' (older) and 'cctRange' (FW >= 1.22).
  List<double>? get extendedWhiteRange {
    if (pilotResult.containsKey('extRange')) {
      final range = pilotResult['extRange'];
      if (range is List) {
        return range.map((e) => (e as num).toDouble()).toList();
      }
    }
    // New after v1.22 FW - "cctRange":[2200,2700,6500,6500]
    if (pilotResult.containsKey('cctRange')) {
      final range = pilotResult['cctRange'];
      if (range is List) {
        return range.map((e) => (e as num).toDouble()).toList();
      }
    }
    return null;
  }

  /// Gets the effect/animation speed (10-200)
  int? get speed => _extractInt('speed');

  /// Gets the ratio between up and down light (0-100)
  ///
  /// Used for lights with dual-direction capability.
  int? get ratio => _extractInt('ratio');

  /// Gets the current scene ID
  ///
  /// Returns 1000 for rhythm mode (schdPsetId present),
  /// otherwise returns the sceneId value.
  int? get sceneId {
    if (pilotResult.containsKey('schdPsetId')) {
      return 1000; // Rhythm mode
    }
    return pilotResult['sceneId'] as int?;
  }

  /// Gets the current scene name
  ///
  /// Returns the human-readable name of the current scene,
  /// or null if no scene is active or the scene ID is unknown.
  String? get scene {
    final id = sceneId;
    return id != null ? getSceneName(id) : null;
  }

  /// Gets the RGB color values
  ///
  /// Returns a tuple of (red, green, blue) values from 0-255,
  /// or null if RGB values are not present.
  RgbColor? get rgb {
    if (pilotResult.containsKey('r') &&
        pilotResult.containsKey('g') &&
        pilotResult.containsKey('b')) {
      return (
        pilotResult['r'] as int,
        pilotResult['g'] as int,
        pilotResult['b'] as int,
      );
    }
    return null;
  }

  /// Gets the RGBW color values (RGB + warm white)
  ///
  /// Returns a tuple of (red, green, blue, warmWhite) values from 0-255,
  /// or null if RGBW values are not all present.
  RgbwColor? get rgbw {
    if (pilotResult.containsKey('r') &&
        pilotResult.containsKey('g') &&
        pilotResult.containsKey('b') &&
        pilotResult.containsKey('w')) {
      return (
        pilotResult['r'] as int,
        pilotResult['g'] as int,
        pilotResult['b'] as int,
        pilotResult['w'] as int,
      );
    }
    return null;
  }

  /// Gets the RGBWW color values (RGB + cold white + warm white)
  ///
  /// Returns a tuple of (red, green, blue, coldWhite, warmWhite) from 0-255,
  /// or null if RGBWW values are not all present.
  RgbwwColor? get rgbww {
    if (pilotResult.containsKey('r') &&
        pilotResult.containsKey('g') &&
        pilotResult.containsKey('b') &&
        pilotResult.containsKey('c') &&
        pilotResult.containsKey('w')) {
      return (
        pilotResult['r'] as int,
        pilotResult['g'] as int,
        pilotResult['b'] as int,
        pilotResult['c'] as int,
        pilotResult['w'] as int,
      );
    }
    return null;
  }

  /// Gets the brightness value (0-255)
  ///
  /// Converts the 'dimming' percentage (10-100) to brightness (0-255).
  /// Note: WiZ bulbs have a hardware minimum of 10% dimming.
  int? get brightness {
    final dimming = _extractInt('dimming');
    return dimming != null ? _percentToHex(dimming) : null;
  }

  /// Gets the color temperature in Kelvin
  ///
  /// Typical range is 1000-10000K, with most bulbs supporting 2200-6500K.
  int? get colorTemp => _extractInt('temp');

  /// Gets the RSSI (signal strength) value
  ///
  /// Returns the WiFi signal strength in dBm (typically -30 to -90).
  int? get rssi => _extractInt('rssi');

  // Fan-related getters (for ceiling fan controllers)

  /// Gets the fan state (0=off, 1=on)
  int? get fanState => _extractInt('fs');

  /// Gets the fan mode (1=normal, 2=breeze)
  int? get fanMode => _extractInt('fm');

  /// Gets the fan speed (1 to fanSpeedRange)
  int? get fanSpeed => _extractInt('fv');

  /// Gets the fan rotation direction (0=normal/summer, 1=reverse/winter)
  int? get fanReverse => _extractInt('fr');

  /// Gets the fan speed range (maximum fan speed setting)
  int? get fanSpeedRange => _extractInt('fanSpd');

  // Helper methods for extracting values with proper null handling

  bool? _extractBool(String key) {
    final value = pilotResult[key];
    return value != null ? value as bool : null;
  }

  String? _extractString(String key) {
    final value = pilotResult[key];
    return value != null ? value.toString() : null;
  }

  int? _extractInt(String key) {
    final value = pilotResult[key];
    if (value == null) return null;
    try {
      return value as int;
    } catch (_) {
      return null;
    }
  }

  /// Converts percentage (0-100) to hex value (0-255)
  int _percentToHex(int percent) {
    return (percent * 255 / 100).round();
  }

  @override
  String toString() {
    return 'PilotParser{state: $state, brightness: $brightness, '
        'colorTemp: $colorTemp, scene: $scene, rgb: $rgb}';
  }
}
