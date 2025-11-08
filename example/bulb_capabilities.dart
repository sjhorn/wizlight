// Example demonstrating bulb capability detection
// Shows how to detect device type and adapt your control logic

import 'package:wizlight/wizlight.dart';

void main() async {
  print('=== WizLight Bulb Capability Detection Example ===\n');

  final bulb = Bulb();
  bulb.setDeviceIP('192.168.1.100'); // Replace with your bulb's IP

  print('This example shows how to detect device capabilities');
  print('and adapt your control logic accordingly.\n');

  try {
    // 1. GET DEVICE INFORMATION
    print('1. Getting device information...');
    await bulb.getSystemConfig();
    print('   Raw system config retrieved');
    print('');

    // 2. GET BULB TYPE WITH FEATURES
    print('2. Detecting bulb type and features...');
    final bulbType = await bulb.getBulbType();

    if (bulbType == null) {
      print('   ⚠️  Could not detect bulb type');
      print('   This might be an older bulb or unsupported device');
      return;
    }

    // 3. DISPLAY BULB CLASSIFICATION
    print('\n╔══════════════════════════════════════════╗');
    print('║         BULB CLASSIFICATION              ║');
    print('╚══════════════════════════════════════════╝');
    print('Type: ${bulbType.bulbType.displayName}');
    print('Module: ${bulbType.name ?? "Unknown"}');
    print('Firmware: ${bulbType.fwVersion ?? "Unknown"}');
    print('');

    // 4. DISPLAY FEATURE FLAGS
    print('╔══════════════════════════════════════════╗');
    print('║           FEATURE FLAGS                  ║');
    print('╚══════════════════════════════════════════╝');
    final features = bulbType.features;
    print('✓ Brightness:       ${features.brightness ? "YES" : "NO"}');
    print('✓ Color (RGB):      ${features.color ? "YES" : "NO"}');
    print('✓ Color Temperature:${features.colorTemp ? "YES" : "NO"}');
    print('✓ Effects/Scenes:   ${features.effect ? "YES" : "NO"}');
    print('✓ Dual Head:        ${features.dualHead ? "YES" : "NO"}');
    print('✓ Fan Control:      ${features.fan ? "YES" : "NO"}');
    print('✓ Fan Breeze Mode:  ${features.fanBreezeMode ? "YES" : "NO"}');
    print('✓ Fan Reverse:      ${features.fanReverse ? "YES" : "NO"}');
    print('');

    // 5. DISPLAY COLOR TEMPERATURE RANGE
    if (bulbType.kelvinRange != null) {
      print('╔══════════════════════════════════════════╗');
      print('║      COLOR TEMPERATURE RANGE             ║');
      print('╚══════════════════════════════════════════╝');
      final range = bulbType.kelvinRange!;
      print('Minimum: ${range.min}K (warm white)');
      print('Maximum: ${range.max}K (cool white)');
      print('Range:   ${range.max - range.min}K');
      print('');
    }

    // 6. GET WHITE RANGES
    print('╔══════════════════════════════════════════╗');
    print('║          WHITE LED RANGES                ║');
    print('╚══════════════════════════════════════════╝');

    final whiteRange = await bulb.getWhiteRange();
    if (whiteRange != null) {
      print('White Range: $whiteRange');
    }

    final extWhiteRange = await bulb.getExtendedWhiteRange();
    if (extWhiteRange != null) {
      print('Extended Range: $extWhiteRange');
    }

    if (bulbType.whiteChannels != null) {
      print('White Channels: ${bulbType.whiteChannels}');
    }
    if (bulbType.whiteToColorRatio != null) {
      print('White/Color Ratio: ${bulbType.whiteToColorRatio}');
    }
    print('');

    // 7. GET SUPPORTED SCENES
    print('╔══════════════════════════════════════════╗');
    print('║         SUPPORTED SCENES                 ║');
    print('╚══════════════════════════════════════════╝');
    final supportedScenes = await bulb.getSupportedScenes();
    print('This ${bulbType.bulbType.displayName} bulb supports');
    print('${supportedScenes.length} scenes:\n');

    // Display in columns
    for (var i = 0; i < supportedScenes.length; i += 3) {
      final scene1 = supportedScenes[i];
      final scene2 =
          i + 1 < supportedScenes.length ? supportedScenes[i + 1] : '';
      final scene3 =
          i + 2 < supportedScenes.length ? supportedScenes[i + 2] : '';
      print(
          '  ${scene1.padRight(15)} ${scene2.padRight(15)} ${scene3.padRight(15)}');
    }
    print('');

    // 8. FAN SPEED RANGE (IF APPLICABLE)
    if (features.fan) {
      print('╔══════════════════════════════════════════╗');
      print('║         FAN CAPABILITIES                 ║');
      print('╚══════════════════════════════════════════╝');
      final fanSpeedRange = await bulb.getFanSpeedRange();
      if (fanSpeedRange != null) {
        print('Fan Speed Range: 1-$fanSpeedRange');
        print(
            'Breeze Mode: ${features.fanBreezeMode ? "Supported" : "Not supported"}');
        print(
            'Reverse Mode: ${features.fanReverse ? "Supported" : "Not supported"}');
      }
      print('');
    }

    // 9. POWER MONITORING (IF APPLICABLE)
    print('╔══════════════════════════════════════════╗');
    print('║       POWER MONITORING                   ║');
    print('╚══════════════════════════════════════════╝');
    final power = await bulb.getPower();
    if (power != null) {
      print('✓ Power monitoring: SUPPORTED');
      print('Current power: ${power.toStringAsFixed(2)}W');
    } else {
      print('✗ Power monitoring: NOT SUPPORTED');
      print('(Only available on smart plugs with metering)');
    }
    print('');

    // 10. GET MAC ADDRESS
    print('╔══════════════════════════════════════════╗');
    print('║        DEVICE IDENTIFIERS                ║');
    print('╚══════════════════════════════════════════╝');
    final mac = await bulb.getMac();
    print('MAC Address: $mac');
    print('IP Address: ${bulb.getDeviceIp()}');
    print('');

    // 11. ADAPTIVE CONTROL EXAMPLE
    print('╔══════════════════════════════════════════╗');
    print('║      ADAPTIVE CONTROL DEMO               ║');
    print('╚══════════════════════════════════════════╝');
    print('Demonstrating adaptive control based on capabilities...\n');

    if (features.color) {
      print('✓ Bulb supports color - setting to purple');
      await bulb.setRGBColor(128, 0, 128);
    } else if (features.colorTemp) {
      print('✓ Bulb supports color temp - setting to warm white');
      final builder = PilotBuilder()
        ..colorTemp = bulbType.kelvinRange?.min ?? 2700;
      await bulb.turnOn(builder);
    } else if (features.brightness) {
      print('✓ Bulb supports brightness - setting to 75%');
      await bulb.setBrightness(75);
    } else {
      print('✓ Basic bulb - turning on');
      await bulb.turnOn();
    }

    await Future.delayed(Duration(seconds: 2));

    if (features.effect) {
      print('✓ Bulb supports effects - setting Ocean scene');
      await bulb.setScene(1); // Ocean
      await Future.delayed(Duration(seconds: 3));
    }

    print('\nTurning off...');
    await bulb.turnOff();

    print('\n=== Example Complete ===');
    print('\nKey Takeaways:');
    print('  - Always detect capabilities before using advanced features');
    print('  - Different bulb types have different feature sets');
    print('  - Use feature flags to enable/disable UI elements');
    print('  - Adapt your control logic based on detected capabilities');
  } catch (e) {
    print('Error: $e');
    print(
        'Make sure the bulb IP address is correct and the bulb is reachable.');
  }
}
