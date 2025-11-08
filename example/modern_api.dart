// Comprehensive example demonstrating the modern WizLight API
// This showcases all the new features from the pywizlight port

import 'package:wizlight/wizlight.dart';

void main() async {
  print('=== WizLight Modern API Example ===\n');

  final bulb = Bulb();
  bulb.setDeviceIP('192.168.1.100'); // Replace with your bulb's IP

  try {
    // 1. DEVICE CAPABILITY DETECTION
    print('1. Detecting bulb capabilities...');
    final bulbType = await bulb.getBulbType();
    if (bulbType != null) {
      print('   Bulb Type: ${bulbType.bulbType}');
      print('   Module: ${bulbType.name}');
      print('   Firmware: ${bulbType.fwVersion}');
      print('   Features:');
      print('     - Color: ${bulbType.features.color}');
      print('     - Color Temperature: ${bulbType.features.colorTemp}');
      print('     - Brightness: ${bulbType.features.brightness}');
      print('     - Effects: ${bulbType.features.effect}');
      if (bulbType.kelvinRange != null) {
        print(
            '   Kelvin Range: ${bulbType.kelvinRange!.min}K - ${bulbType.kelvinRange!.max}K');
      }
    }
    print('');

    // 2. GET SUPPORTED SCENES
    print('2. Getting supported scenes...');
    final supportedScenes = await bulb.getSupportedScenes();
    print('   This bulb supports ${supportedScenes.length} scenes:');
    print('   ${supportedScenes.take(5).join(", ")}...\n');

    // 3. MODERN CONTROL API WITH PILOTBUILDER
    print('3. Using PilotBuilder for advanced control...');

    // Turn on with warm white at 50% brightness
    print('   Turning on: Warm white, 2700K, 50% brightness');
    final builder1 = PilotBuilder()
      ..brightness = 127
      ..colorTemp = 2700;
    await bulb.turnOn(builder1);
    await Future.delayed(const Duration(seconds: 2));

    // Change to cool white
    print('   Changing to: Cool white, 6500K, 75% brightness');
    final builder2 = PilotBuilder()
      ..brightness = 191
      ..colorTemp = 6500;
    await bulb.turnOn(builder2);
    await Future.delayed(const Duration(seconds: 2));

    // 4. STATE-AWARE TOGGLE
    print('\n4. Demonstrating state-aware toggle...');
    final state1 = await bulb.updateState();
    print('   Current state: ${state1?.state == true ? "ON" : "OFF"}');

    print('   Toggling with lightSwitch()...');
    await bulb.lightSwitch(); // Will turn off since it's on
    await Future.delayed(const Duration(seconds: 1));

    final state2 = await bulb.updateState();
    print('   New state: ${state2?.state == true ? "ON" : "OFF"}');

    print('   Toggling again...');
    await bulb.lightSwitch(); // Will turn on since it's off
    await Future.delayed(const Duration(seconds: 1));
    print('');

    // 5. TYPED STATE ACCESS
    print('5. Reading bulb state with PilotParser...');
    final state = await bulb.updateState();
    if (state != null) {
      print('   State: ${state.state == true ? "ON" : "OFF"}');
      print(
          '   Brightness: ${state.brightness}/255 (${(state.brightness! * 100 / 255).round()}%)');
      print('   Color Temperature: ${state.colorTemp}K');
      print('   Scene: ${state.scene ?? "None"}');
      print('   Source: ${state.source ?? "Unknown"}');
      if (state.rgb != null) {
        final rgb = state.rgb!;
        print('   RGB: (${rgb.$1}, ${rgb.$2}, ${rgb.$3})');
      }
    }
    print('');

    // 6. EXTENDED COLOR MODES
    print('6. Demonstrating extended color modes...');

    // RGB (3 channels)
    print('   Setting RGB red...');
    await bulb.setRGBColor(255, 0, 0);
    await Future.delayed(const Duration(seconds: 2));

    // If bulb supports RGBW, try it
    if (bulbType?.features.color == true) {
      print('   Setting RGBW: Purple with warm white accent...');
      await bulb.setRgbw(128, 0, 128, 100);
      await Future.delayed(const Duration(seconds: 2));
    }

    // Individual white control
    print('   Setting warm white only...');
    await bulb.setWarmWhite(200);
    await Future.delayed(const Duration(seconds: 2));
    print('');

    // 7. SCENES WITH SPEED
    print('7. Demonstrating scenes with speed control...');
    print('   Setting Ocean scene with slow speed...');
    final sceneBuilder = PilotBuilder()
      ..scene = 1 // Ocean
      ..speed = 50; // Slow
    await bulb.turnOn(sceneBuilder);
    await Future.delayed(const Duration(seconds: 3));

    print('   Changing to fast speed...');
    final fastBuilder = PilotBuilder()
      ..scene = 1 // Keep Ocean
      ..speed = 200; // Fast
    await bulb.turnOn(fastBuilder);
    await Future.delayed(const Duration(seconds: 3));
    print('');

    // 8. MAC ADDRESS
    print('8. Getting MAC address...');
    final mac = await bulb.getMac();
    print('   MAC: $mac\n');

    // 9. CLEAN SHUTDOWN
    print('9. Turning off...');
    await bulb.turnOff();
    print('   Done!');

    print('\n=== Example Complete ===');
    print('Note: Push updates example is in example/push_updates.dart');
    print('Note: Fan control example would require a ceiling fan controller');
    print('Note: Power monitoring example would require a smart plug');
  } catch (e) {
    print('Error: $e');
    print(
        'Make sure the bulb IP address is correct and the bulb is reachable.');
  }
}
