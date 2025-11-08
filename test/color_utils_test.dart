// Unit tests for color utility functions
// See LICENSE file for licensing details.

import 'package:test/test.dart';
import 'package:wizlight/src/color_utils.dart';

void main() {
  group('RGBColor', () {
    test('constructor and getters', () {
      final color = RGBColor(255, 128, 0);
      expect(color.red, equals(255));
      expect(color.green, equals(128));
      expect(color.blue, equals(0));
    });

    test('toString', () {
      final color = RGBColor(255, 128, 0);
      expect(color.toString(), equals('RGB(255, 128, 0)'));
    });

    test('equality', () {
      final color1 = RGBColor(255, 128, 0);
      final color2 = RGBColor(255, 128, 0);
      final color3 = RGBColor(255, 128, 1);

      expect(color1, equals(color2));
      expect(color1, isNot(equals(color3)));
    });
  });

  group('HSVColor', () {
    test('constructor and getters', () {
      final color = HSVColor(180.0, 50.0, 75.0);
      expect(color.hue, equals(180.0));
      expect(color.saturation, equals(50.0));
      expect(color.value, equals(75.0));
    });

    test('toString', () {
      final color = HSVColor(180.5, 50.3, 75.7);
      expect(color.toString(), equals('HSV(180.5, 50.3, 75.7)'));
    });

    test('equality with tolerance', () {
      final color1 = HSVColor(180.0, 50.0, 75.0);
      final color2 = HSVColor(180.0001, 50.0001, 75.0001);
      final color3 = HSVColor(180.1, 50.0, 75.0);

      expect(color1, equals(color2)); // Within tolerance
      expect(color1, isNot(equals(color3))); // Outside tolerance
    });
  });

  group('RGB to HSV Conversion', () {
    test('pure red', () {
      final rgb = RGBColor(255, 0, 0);
      final hsv = rgbToHsv(rgb);

      expect(hsv.hue, closeTo(0.0, 0.1));
      expect(hsv.saturation, closeTo(100.0, 0.1));
      expect(hsv.value, closeTo(100.0, 0.1));
    });

    test('pure green', () {
      final rgb = RGBColor(0, 255, 0);
      final hsv = rgbToHsv(rgb);

      expect(hsv.hue, closeTo(120.0, 0.1));
      expect(hsv.saturation, closeTo(100.0, 0.1));
      expect(hsv.value, closeTo(100.0, 0.1));
    });

    test('pure blue', () {
      final rgb = RGBColor(0, 0, 255);
      final hsv = rgbToHsv(rgb);

      expect(hsv.hue, closeTo(240.0, 0.1));
      expect(hsv.saturation, closeTo(100.0, 0.1));
      expect(hsv.value, closeTo(100.0, 0.1));
    });

    test('black', () {
      final rgb = RGBColor(0, 0, 0);
      final hsv = rgbToHsv(rgb);

      expect(hsv.hue, closeTo(0.0, 0.1));
      expect(hsv.saturation, closeTo(0.0, 0.1));
      expect(hsv.value, closeTo(0.0, 0.1));
    });

    test('white', () {
      final rgb = RGBColor(255, 255, 255);
      final hsv = rgbToHsv(rgb);

      expect(hsv.hue, closeTo(0.0, 0.1));
      expect(hsv.saturation, closeTo(0.0, 0.1));
      expect(hsv.value, closeTo(100.0, 0.1));
    });

    test('gray (50%)', () {
      final rgb = RGBColor(128, 128, 128);
      final hsv = rgbToHsv(rgb);

      expect(hsv.saturation, closeTo(0.0, 0.1));
      expect(hsv.value, closeTo(50.2, 0.5)); // 128/255 * 100 ≈ 50.2
    });

    test('cyan', () {
      final rgb = RGBColor(0, 255, 255);
      final hsv = rgbToHsv(rgb);

      expect(hsv.hue, closeTo(180.0, 0.1));
      expect(hsv.saturation, closeTo(100.0, 0.1));
      expect(hsv.value, closeTo(100.0, 0.1));
    });

    test('magenta', () {
      final rgb = RGBColor(255, 0, 255);
      final hsv = rgbToHsv(rgb);

      expect(hsv.hue, closeTo(300.0, 0.1));
      expect(hsv.saturation, closeTo(100.0, 0.1));
      expect(hsv.value, closeTo(100.0, 0.1));
    });

    test('yellow', () {
      final rgb = RGBColor(255, 255, 0);
      final hsv = rgbToHsv(rgb);

      expect(hsv.hue, closeTo(60.0, 0.1));
      expect(hsv.saturation, closeTo(100.0, 0.1));
      expect(hsv.value, closeTo(100.0, 0.1));
    });

    test('orange', () {
      final rgb = RGBColor(255, 128, 0);
      final hsv = rgbToHsv(rgb);

      expect(hsv.hue, closeTo(30.12, 0.5));
      expect(hsv.saturation, closeTo(100.0, 0.1));
      expect(hsv.value, closeTo(100.0, 0.1));
    });
  });

  group('HSV to RGB Conversion', () {
    test('pure red (hue 0)', () {
      final hsv = HSVColor(0.0, 100.0, 100.0);
      final rgb = hsvToRgb(hsv);

      expect(rgb.red, equals(255));
      expect(rgb.green, equals(0));
      expect(rgb.blue, equals(0));
    });

    test('pure green (hue 120)', () {
      final hsv = HSVColor(120.0, 100.0, 100.0);
      final rgb = hsvToRgb(hsv);

      expect(rgb.red, equals(0));
      expect(rgb.green, equals(255));
      expect(rgb.blue, equals(0));
    });

    test('pure blue (hue 240)', () {
      final hsv = HSVColor(240.0, 100.0, 100.0);
      final rgb = hsvToRgb(hsv);

      expect(rgb.red, equals(0));
      expect(rgb.green, equals(0));
      expect(rgb.blue, equals(255));
    });

    test('black (value 0)', () {
      final hsv = HSVColor(0.0, 100.0, 0.0);
      final rgb = hsvToRgb(hsv);

      expect(rgb.red, equals(0));
      expect(rgb.green, equals(0));
      expect(rgb.blue, equals(0));
    });

    test('white (saturation 0, value 100)', () {
      final hsv = HSVColor(0.0, 0.0, 100.0);
      final rgb = hsvToRgb(hsv);

      expect(rgb.red, equals(255));
      expect(rgb.green, equals(255));
      expect(rgb.blue, equals(255));
    });

    test('gray (saturation 0, value 50)', () {
      final hsv = HSVColor(0.0, 0.0, 50.0);
      final rgb = hsvToRgb(hsv);

      expect(rgb.red, equals(128));
      expect(rgb.green, equals(128));
      expect(rgb.blue, equals(128));
    });

    test('cyan (hue 180)', () {
      final hsv = HSVColor(180.0, 100.0, 100.0);
      final rgb = hsvToRgb(hsv);

      expect(rgb.red, equals(0));
      expect(rgb.green, equals(255));
      expect(rgb.blue, equals(255));
    });

    test('magenta (hue 300)', () {
      final hsv = HSVColor(300.0, 100.0, 100.0);
      final rgb = hsvToRgb(hsv);

      expect(rgb.red, equals(255));
      expect(rgb.green, equals(0));
      expect(rgb.blue, equals(255));
    });

    test('yellow (hue 60)', () {
      final hsv = HSVColor(60.0, 100.0, 100.0);
      final rgb = hsvToRgb(hsv);

      expect(rgb.red, equals(255));
      expect(rgb.green, equals(255));
      expect(rgb.blue, equals(0));
    });

    test('desaturated red', () {
      final hsv = HSVColor(0.0, 50.0, 100.0);
      final rgb = hsvToRgb(hsv);

      expect(rgb.red, equals(255));
      expect(rgb.green, equals(128));
      expect(rgb.blue, equals(128));
    });
  });

  group('RGB ↔ HSV Round-trip Conversion', () {
    test('round trip preserves color', () {
      final originalRgb = RGBColor(200, 100, 50);
      final hsv = rgbToHsv(originalRgb);
      final roundTripRgb = hsvToRgb(hsv);

      expect(roundTripRgb.red, closeTo(originalRgb.red, 1));
      expect(roundTripRgb.green, closeTo(originalRgb.green, 1));
      expect(roundTripRgb.blue, closeTo(originalRgb.blue, 1));
    });

    test('round trip multiple colors', () {
      final testColors = [
        RGBColor(255, 0, 0),
        RGBColor(0, 255, 0),
        RGBColor(0, 0, 255),
        RGBColor(255, 255, 0),
        RGBColor(255, 0, 255),
        RGBColor(0, 255, 255),
        RGBColor(128, 64, 192),
        RGBColor(200, 150, 100),
      ];

      for (final original in testColors) {
        final hsv = rgbToHsv(original);
        final roundTrip = hsvToRgb(hsv);

        expect(roundTrip.red, closeTo(original.red, 1),
            reason: 'Red mismatch for $original');
        expect(roundTrip.green, closeTo(original.green, 1),
            reason: 'Green mismatch for $original');
        expect(roundTrip.blue, closeTo(original.blue, 1),
            reason: 'Blue mismatch for $original');
      }
    });
  });

  group('Percent/Hex Conversion', () {
    test('hexToPercent', () {
      expect(hexToPercent(0), closeTo(0.0, 0.1));
      expect(hexToPercent(128), closeTo(50.2, 0.5));
      expect(hexToPercent(255), closeTo(100.0, 0.1));
    });

    test('percentToHex', () {
      expect(percentToHex(0.0), equals(0));
      expect(percentToHex(50.0), equals(128));
      expect(percentToHex(100.0), equals(255));
    });

    test('percent/hex round trip', () {
      for (int hex = 0; hex <= 255; hex += 10) {
        final percent = hexToPercent(hex);
        final roundTrip = percentToHex(percent);
        expect(roundTrip, closeTo(hex, 1));
      }
    });
  });

  group('Kelvin to RGB Conversion', () {
    test('warm white (2700K) - yellowish', () {
      final rgb = kelvinToRgb(2700);

      expect(rgb.red, greaterThan(250)); // Should be very high
      expect(rgb.green, greaterThan(100)); // Medium-high
      expect(rgb.green, lessThan(200));
      expect(rgb.blue, lessThan(100)); // Should be low
    });

    test('neutral white (5000K)', () {
      final rgb = kelvinToRgb(5000);

      // Should be relatively balanced, slightly warm
      expect(rgb.red, greaterThan(200));
      expect(rgb.green, greaterThan(200));
      expect(rgb.blue, greaterThan(200));
    });

    test('cool white (6500K) - slightly bluish', () {
      final rgb = kelvinToRgb(6500);

      expect(rgb.red, greaterThan(200));
      expect(rgb.green, greaterThan(200));
      expect(rgb.blue, greaterThan(240)); // Blue should be high (near max)
    });

    test('very cool (10000K)', () {
      final rgb = kelvinToRgb(10000);

      expect(rgb.blue, equals(255)); // Blue maxed out
      expect(rgb.red, lessThan(rgb.blue));
    });

    test('clamps minimum temperature', () {
      final rgb = kelvinToRgb(500); // Below minimum
      expect(rgb.red, isPositive);
      expect(rgb.green, isPositive);
      expect(rgb.blue, isA<int>());
    });

    test('clamps maximum temperature', () {
      final rgb = kelvinToRgb(50000); // Above maximum
      expect(rgb.red, isPositive);
      expect(rgb.green, isPositive);
      expect(rgb.blue, isPositive);
    });
  });
}
