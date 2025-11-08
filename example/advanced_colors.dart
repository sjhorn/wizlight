// Example demonstrating advanced color control
// Shows RGB, RGBW, RGBWW, and individual white LED control

import 'package:wizlight/wizlight.dart';

void main() async {
  print('=== WizLight Advanced Color Control Example ===\n');

  final bulb = Bulb();
  bulb.setDeviceIP('192.168.1.100'); // Replace with your bulb's IP

  print('This example demonstrates all color control modes.\n');

  try {
    // Check bulb capabilities first
    print('Detecting bulb capabilities...');
    final bulbType = await bulb.getBulbType();
    if (bulbType != null) {
      print('Bulb Type: ${bulbType.bulbType}');
      print('Supports Color: ${bulbType.features.color}');
      print('Supports Color Temp: ${bulbType.features.colorTemp}\n');

      if (!bulbType.features.color) {
        print('⚠️  This bulb doesn\'t support color.');
        print('   Some examples will be skipped.\n');
      }
    }

    // 1. RGB (3 CHANNELS) - Standard RGB control
    print('1. RGB (3 channels) - Standard color control');
    print('   Red (255, 0, 0)');
    await bulb.setRGBColor(255, 0, 0);
    await Future.delayed(Duration(seconds: 2));

    print('   Green (0, 255, 0)');
    await bulb.setRGBColor(0, 255, 0);
    await Future.delayed(Duration(seconds: 2));

    print('   Blue (0, 0, 255)');
    await bulb.setRGBColor(0, 0, 255);
    await Future.delayed(Duration(seconds: 2));

    print('   Purple (128, 0, 128)');
    await bulb.setRGBColor(128, 0, 128);
    await Future.delayed(Duration(seconds: 2));
    print('');

    // 2. RGBW (4 CHANNELS) - RGB + Warm White
    if (bulbType?.features.color == true) {
      print('2. RGBW (4 channels) - RGB + Warm White');
      print('   This adds a warm white LED to create richer colors\n');

      print('   Red with warm white accent');
      await bulb.setRgbw(255, 0, 0, 100);
      await Future.delayed(Duration(seconds: 2));

      print('   Orange with warm white (sunset effect)');
      await bulb.setRgbw(255, 100, 0, 150);
      await Future.delayed(Duration(seconds: 2));

      print('   Purple with soft warm glow');
      await bulb.setRgbw(128, 0, 128, 80);
      await Future.delayed(Duration(seconds: 2));

      print('   Pure warm white (RGB off)');
      await bulb.setRgbw(0, 0, 0, 255);
      await Future.delayed(Duration(seconds: 2));
      print('');
    }

    // 3. RGBWW (5 CHANNELS) - RGB + Cold White + Warm White
    if (bulbType?.features.color == true) {
      print('3. RGBWW (5 channels) - RGB + Cold White + Warm White');
      print('   This gives maximum flexibility with both white LEDs\n');

      print('   Red with balanced whites');
      await bulb.setRgbww(255, 0, 0, 100, 100);
      await Future.delayed(Duration(seconds: 2));

      print('   Blue with cool white accent');
      await bulb.setRgbww(0, 0, 255, 150, 50);
      await Future.delayed(Duration(seconds: 2));

      print('   Green with warm white accent');
      await bulb.setRgbww(0, 255, 0, 50, 150);
      await Future.delayed(Duration(seconds: 2));

      print('   Balanced daylight (all LEDs)');
      await bulb.setRgbww(200, 200, 200, 150, 150);
      await Future.delayed(Duration(seconds: 2));
      print('');
    }

    // 4. INDIVIDUAL WHITE CONTROL
    print('4. Individual White LED Control');
    print('   For precise white balance\n');

    print('   Warm white only (2700K feeling)');
    await bulb.setWarmWhite(255);
    await Future.delayed(Duration(seconds: 2));

    print('   Medium warm white');
    await bulb.setWarmWhite(150);
    await Future.delayed(Duration(seconds: 2));

    print('   Cold white only (6500K feeling)');
    await bulb.setColdWhite(255);
    await Future.delayed(Duration(seconds: 2));

    print('   Medium cold white');
    await bulb.setColdWhite(150);
    await Future.delayed(Duration(seconds: 2));
    print('');

    // 5. COLOR TEMPERATURE (TRADITIONAL METHOD)
    if (bulbType?.features.colorTemp == true) {
      print('5. Color Temperature (traditional white control)');
      print('   Uses kelvin values for natural white light\n');

      final kelvinRange = bulbType?.kelvinRange;
      if (kelvinRange != null) {
        print('   Bulb kelvin range: ${kelvinRange.min}K - ${kelvinRange.max}K\n');

        print('   Warm white (${kelvinRange.min}K)');
        final warmBuilder = PilotBuilder()
          ..colorTemp = kelvinRange.min
          ..brightness = 200;
        await bulb.turnOn(warmBuilder);
        await Future.delayed(Duration(seconds: 2));

        print('   Neutral white (4000K)');
        final neutralBuilder = PilotBuilder()
          ..colorTemp = 4000
          ..brightness = 200;
        await bulb.turnOn(neutralBuilder);
        await Future.delayed(Duration(seconds: 2));

        print('   Cool white (${kelvinRange.max}K)');
        final coolBuilder = PilotBuilder()
          ..colorTemp = kelvinRange.max
          ..brightness = 200;
        await bulb.turnOn(coolBuilder);
        await Future.delayed(Duration(seconds: 2));
      }
      print('');
    }

    // 6. USING PILOTBUILDER FOR COMPLEX COMBINATIONS
    print('6. Using PilotBuilder for complex color combinations\n');

    print('   Dim purple at 2700K with slow animation');
    final complexBuilder = PilotBuilder()
      ..setRgb(128, 0, 128)
      ..brightness = 100
      ..speed = 50;
    await bulb.turnOn(complexBuilder);
    await Future.delayed(Duration(seconds: 3));
    print('');

    // 7. READING CURRENT COLOR STATE
    print('7. Reading current color state with PilotParser\n');
    final state = await bulb.updateState();
    if (state != null) {
      if (state.rgb != null) {
        final rgb = state.rgb!;
        print('   RGB: (${rgb.$1}, ${rgb.$2}, ${rgb.$3})');
      }
      if (state.rgbw != null) {
        final rgbw = state.rgbw!;
        print('   RGBW: (${rgbw.$1}, ${rgbw.$2}, ${rgbw.$3}, ${rgbw.$4})');
      }
      if (state.rgbww != null) {
        final rgbww = state.rgbww!;
        print(
            '   RGBWW: (${rgbww.$1}, ${rgbww.$2}, ${rgbww.$3}, ${rgbww.$4}, ${rgbww.$5})');
      }
      if (state.warmWhite != null) {
        print('   Warm White: ${state.warmWhite}');
      }
      if (state.coldWhite != null) {
        print('   Cold White: ${state.coldWhite}');
      }
      if (state.colorTemp != null) {
        print('   Color Temperature: ${state.colorTemp}K');
      }
    }
    print('');

    // Turn off
    print('Turning off...');
    await bulb.turnOff();

    print('\n=== Example Complete ===');
    print('\nTips:');
    print('  - Not all bulbs support all color modes');
    print('  - Use getBulbType() to check capabilities first');
    print('  - RGBW/RGBWW work best on newer RGB bulbs');
    print('  - TW bulbs only support color temperature');
    print('  - DW bulbs only support brightness');
  } catch (e) {
    print('Error: $e');
    print('Make sure the bulb IP address is correct and the bulb is reachable.');
  }
}
