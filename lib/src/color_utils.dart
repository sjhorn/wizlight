// Color utility functions for RGB and HSV conversions
// See LICENSE file for licensing details.

import 'dart:math';

/// Represents a color in RGB format
class RGBColor {
  /// Red component (0-255)
  final int red;

  /// Green component (0-255)
  final int green;

  /// Blue component (0-255)
  final int blue;

  const RGBColor(this.red, this.green, this.blue);

  @override
  String toString() => 'RGB($red, $green, $blue)';

  @override
  bool operator ==(Object other) =>
      other is RGBColor &&
      red == other.red &&
      green == other.green &&
      blue == other.blue;

  @override
  int get hashCode => Object.hash(red, green, blue);
}

/// Represents a color in HSV format
class HSVColor {
  /// Hue component (0-360 degrees)
  final double hue;

  /// Saturation component (0-100 percent)
  final double saturation;

  /// Value/brightness component (0-100 percent)
  final double value;

  const HSVColor(this.hue, this.saturation, this.value);

  @override
  String toString() =>
      'HSV(${hue.toStringAsFixed(1)}, ${saturation.toStringAsFixed(1)}, ${value.toStringAsFixed(1)})';

  @override
  bool operator ==(Object other) =>
      other is HSVColor &&
      (hue - other.hue).abs() < 0.001 &&
      (saturation - other.saturation).abs() < 0.001 &&
      (value - other.value).abs() < 0.001;

  @override
  int get hashCode => Object.hash(hue, saturation, value);
}

/// Converts RGB color to HSV color
///
/// Takes RGB values in range 0-255 and converts to HSV with:
/// - Hue: 0-360 degrees
/// - Saturation: 0-100 percent
/// - Value: 0-100 percent
HSVColor rgbToHsv(RGBColor rgb) {
  final r = rgb.red / 255.0;
  final g = rgb.green / 255.0;
  final b = rgb.blue / 255.0;

  final maxC = max(r, max(g, b));
  final minC = min(r, min(g, b));
  final delta = maxC - minC;

  // Calculate Value (brightness)
  final v = maxC * 100.0;

  // Calculate Saturation
  final s = maxC == 0 ? 0.0 : (delta / maxC) * 100.0;

  // Calculate Hue
  double h;
  if (delta == 0) {
    h = 0.0; // Achromatic (gray)
  } else if (maxC == r) {
    h = 60.0 * (((g - b) / delta) % 6);
  } else if (maxC == g) {
    h = 60.0 * (((b - r) / delta) + 2);
  } else {
    h = 60.0 * (((r - g) / delta) + 4);
  }

  // Normalize hue to 0-360 range
  if (h < 0) h += 360.0;

  return HSVColor(h, s, v);
}

/// Converts HSV color to RGB color
///
/// Takes HSV with:
/// - Hue: 0-360 degrees
/// - Saturation: 0-100 percent
/// - Value: 0-100 percent
///
/// Returns RGB with values in range 0-255
RGBColor hsvToRgb(HSVColor hsv) {
  final h = hsv.hue;
  final s = hsv.saturation / 100.0;
  final v = hsv.value / 100.0;

  final c = v * s;
  final x = c * (1 - ((h / 60.0) % 2 - 1).abs());
  final m = v - c;

  double r, g, b;

  if (h < 60) {
    r = c;
    g = x;
    b = 0;
  } else if (h < 120) {
    r = x;
    g = c;
    b = 0;
  } else if (h < 180) {
    r = 0;
    g = c;
    b = x;
  } else if (h < 240) {
    r = 0;
    g = x;
    b = c;
  } else if (h < 300) {
    r = x;
    g = 0;
    b = c;
  } else {
    r = c;
    g = 0;
    b = x;
  }

  return RGBColor(
    ((r + m) * 255).round(),
    ((g + m) * 255).round(),
    ((b + m) * 255).round(),
  );
}

/// Converts hex color value (0-255) to percent (0-100)
double hexToPercent(int hexValue) {
  return (hexValue / 255.0) * 100.0;
}

/// Converts percent value (0-100) to hex color value (0-255)
int percentToHex(double percent) {
  return ((percent / 100.0) * 255).round().clamp(0, 255);
}

/// Converts color temperature in Kelvin to approximate RGB values
///
/// Uses a simplified approximation algorithm for temperature range 1000-40000K.
/// Note: This is an approximation and may not match exact blackbody radiation.
RGBColor kelvinToRgb(int kelvin) {
  // Clamp to reasonable range
  final temp = kelvin.clamp(1000, 40000) / 100.0;

  double r, g, b;

  // Calculate Red
  if (temp <= 66) {
    r = 255;
  } else {
    r = temp - 60;
    r = 329.698727446 * pow(r, -0.1332047592);
    r = r.clamp(0, 255);
  }

  // Calculate Green
  if (temp <= 66) {
    g = temp;
    g = 99.4708025861 * log(g) - 161.1195681661;
    g = g.clamp(0, 255);
  } else {
    g = temp - 60;
    g = 288.1221695283 * pow(g, -0.0755148492);
    g = g.clamp(0, 255);
  }

  // Calculate Blue
  if (temp >= 66) {
    b = 255;
  } else if (temp <= 19) {
    b = 0;
  } else {
    b = temp - 10;
    b = 138.5177312231 * log(b) - 305.0447927307;
    b = b.clamp(0, 255);
  }

  return RGBColor(r.round(), g.round(), b.round());
}
