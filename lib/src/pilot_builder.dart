// Dart port of pywizlight PilotBuilder
// See LICENSE file for licensing details.

import 'scenes.dart';

/// Builder for constructing bulb control commands
///
/// PilotBuilder provides a fluent API for building setPilot and setState
/// command messages with proper validation. It supports all color modes,
/// scenes, brightness, speed, and other bulb parameters.
///
/// Example usage:
/// ```dart
/// // Turn on with warm white at 50% brightness
/// final builder = PilotBuilder()
///   ..brightness = 127
///   ..colorTemp = 2700;
/// final command = builder.setPilotMessage(state: true);
///
/// // Set RGB color
/// final rgbBuilder = PilotBuilder()
///   ..setRgb(255, 0, 0); // Red
/// ```
class PilotBuilder {
  /// The pilot parameters that will be sent to the bulb
  final Map<String, dynamic> pilotParams = {};

  /// Sets RGB color (3 channels: red, green, blue)
  ///
  /// Values must be in range 0-255.
  /// This will set RGB mode and clear any other color settings.
  void setRgb(int r, int g, int b) {
    _validateRgbRange(r, g, b);
    pilotParams['r'] = r;
    pilotParams['g'] = g;
    pilotParams['b'] = b;
  }

  /// Sets RGBW color (4 channels: red, green, blue, warm white)
  ///
  /// Values must be in range 0-255.
  /// This will set RGBW mode and clear any other color settings.
  void setRgbw(int r, int g, int b, int w) {
    _validateRgbRange(r, g, b);
    _validateWhiteRange(w);
    pilotParams['r'] = r;
    pilotParams['g'] = g;
    pilotParams['b'] = b;
    pilotParams['w'] = w;
  }

  /// Sets RGBWW color (5 channels: red, green, blue, cold white, warm white)
  ///
  /// Values must be in range 0-255.
  /// This will set RGBWW mode and clear any other color settings.
  void setRgbww(int r, int g, int b, int c, int w) {
    _validateRgbRange(r, g, b);
    _validateWhiteRange(c);
    _validateWhiteRange(w);
    pilotParams['r'] = r;
    pilotParams['g'] = g;
    pilotParams['b'] = b;
    pilotParams['c'] = c;
    pilotParams['w'] = w;
  }

  /// Sets the warm white LED value
  ///
  /// Value must be in range 0-255.
  set warmWhite(int value) {
    _validateWhiteRange(value);
    pilotParams['w'] = value;
  }

  /// Sets the cold white LED value
  ///
  /// Value must be in range 0-255.
  set coldWhite(int value) {
    _validateWhiteRange(value);
    pilotParams['c'] = value;
  }

  /// Sets the brightness level
  ///
  /// Value must be in range 0-255 (0-100% brightness).
  /// Note: WiZ bulbs have a hardware minimum of 10% brightness.
  set brightness(int value) {
    if (value < 0 || value > 255) {
      throw ArgumentError('Brightness must be between 0 and 255, got $value');
    }
    final percent = _hexToPercent(value);
    // Hardware limitation - values less than 10% are not supported
    pilotParams['dimming'] = percent > 10 ? percent : 10;
  }

  /// Sets the color temperature in Kelvin
  ///
  /// Valid range is typically 1000-10000K. Most bulbs support 2200-6500K.
  /// Values outside this range will be clamped.
  set colorTemp(int kelvin) {
    // Normalize kelvin values - clamp to reasonable range
    pilotParams['temp'] = kelvin.clamp(1000, 10000);
  }

  /// Sets the scene by ID
  ///
  /// Scene IDs range from 1-36, plus 1000 for rhythm mode.
  /// Throws [ArgumentError] if scene ID is not valid.
  set scene(int sceneId) {
    if (!isValidSceneId(sceneId) && sceneId != 1000) {
      throw ArgumentError(
          'Scene ID must be 1-36 or 1000 (rhythm), got $sceneId');
    }
    pilotParams['sceneId'] = sceneId;
  }

  /// Sets the scene by name
  ///
  /// Throws [ArgumentError] if scene name is not recognized.
  set sceneName(String name) {
    final sceneId = getSceneId(name);
    if (sceneId == null) {
      throw ArgumentError('Unknown scene name: $name');
    }
    pilotParams['sceneId'] = sceneId;
  }

  /// Sets the effect/animation speed
  ///
  /// Value must be in range 10-200.
  /// This applies to changing effects and scenes.
  set speed(int value) {
    if (value < 10 || value > 200) {
      throw ArgumentError('Speed must be between 10 and 200, got $value');
    }
    pilotParams['speed'] = value;
  }

  /// Sets the ratio between up and down light
  ///
  /// Value must be in range 0-100.
  /// Used for lights with dual-direction capability.
  set ratio(int value) {
    if (value < 0 || value > 100) {
      throw ArgumentError('Ratio must be between 0 and 100, got $value');
    }
    pilotParams['ratio'] = value;
  }

  /// Sets the on/off state
  ///
  /// This can be used to explicitly include state in the pilot params.
  set state(bool value) {
    pilotParams['state'] = value;
  }

  // ========== Fan Control Parameters ==========

  /// Sets the fan state (for ceiling fan controllers)
  ///
  /// Value must be 0 (off) or 1 (on).
  set fanState(int value) {
    if (value < 0 || value > 1) {
      throw ArgumentError('Fan state must be 0 or 1, got $value');
    }
    pilotParams['fs'] = value;
  }

  /// Sets the fan mode (for ceiling fan controllers)
  ///
  /// Value must be 1 (normal) or 2 (breeze).
  set fanMode(int value) {
    if (value < 1 || value > 2) {
      throw ArgumentError('Fan mode must be 1 or 2, got $value');
    }
    pilotParams['fm'] = value;
  }

  /// Sets the fan speed (for ceiling fan controllers)
  ///
  /// Value must be between 1 and 6.
  set fanSpeed(int value) {
    if (value < 1 || value > 6) {
      throw ArgumentError('Fan speed must be 1-6, got $value');
    }
    pilotParams['fv'] = value;
  }

  /// Sets the fan reverse/rotation direction (for ceiling fan controllers)
  ///
  /// Value must be 0 (normal/summer) or 1 (reverse/winter).
  set fanReverse(int value) {
    if (value < 0 || value > 1) {
      throw ArgumentError('Fan reverse must be 0 or 1, got $value');
    }
    pilotParams['fr'] = value;
  }


  /// Generates a setPilot command message
  ///
  /// This is the standard method for controlling bulb state.
  /// If [state] is provided, it will be included in the command.
  ///
  /// Returns a Map ready to be JSON-encoded and sent to the bulb.
  Map<String, dynamic> setPilotMessage({bool? state}) {
    final params = Map<String, dynamic>.from(pilotParams);
    if (state != null) {
      params['state'] = state;
    }
    return {
      'method': 'setPilot',
      'params': params,
    };
  }

  /// Generates a setState command message
  ///
  /// This is an alternative method for setting bulb state.
  /// If [state] is provided, it will be included in the command.
  ///
  /// Returns a Map ready to be JSON-encoded and sent to the bulb.
  Map<String, dynamic> setStateMessage({bool? state}) {
    final params = Map<String, dynamic>.from(pilotParams);
    if (state != null) {
      params['state'] = state;
    }
    return {
      'method': 'setState',
      'params': params,
    };
  }

  /// Checks if any parameters have been set
  bool get isEmpty => pilotParams.isEmpty;

  /// Checks if any parameters have been set
  bool get isNotEmpty => pilotParams.isNotEmpty;

  // Validation helper methods

  void _validateRgbRange(int r, int g, int b) {
    if (r < 0 || r > 255) {
      throw ArgumentError('Red must be between 0 and 255, got $r');
    }
    if (g < 0 || g > 255) {
      throw ArgumentError('Green must be between 0 and 255, got $g');
    }
    if (b < 0 || b > 255) {
      throw ArgumentError('Blue must be between 0 and 255, got $b');
    }
  }

  void _validateWhiteRange(int value) {
    if (value < 0 || value > 255) {
      throw ArgumentError('White value must be between 0 and 255, got $value');
    }
  }

  /// Converts hex value (0-255) to percentage (0-100)
  int _hexToPercent(int hex) {
    return (hex * 100 / 255).round();
  }

  @override
  String toString() {
    return 'PilotBuilder{params: $pilotParams}';
  }
}
