// Example: Discover a WiZ light, monitor updates, and cycle through RGB colors
// See LICENSE file for licensing details.

import 'package:logging/logging.dart';
import 'package:wizlight/wizlight.dart';

void main() async {
  // Enable logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('[${record.level.name}] ${record.message}');
  });

  print('=== WiZ Light Color Demo ===\n');

  // Step 1: Discover WiZ lights on the network
  print('Step 1: Discovering WiZ lights...');
  final discovered = await discoverBulbs(
    broadcastAddress: '192.168.1.255',
    waitTime: const Duration(seconds: 5),
  );

  if (discovered.isEmpty) {
    print('❌ No WiZ lights found on the network.');
    print('Make sure your lights are powered on and connected.');
    return;
  }

  print('✓ Found ${discovered.length} light(s):');
  for (var i = 0; i < discovered.length; i++) {
    print('  [$i] IP: ${discovered[i].ip}, MAC: ${discovered[i].mac}');
  }
  print('');

  // Use the first discovered light
  final targetLight = discovered[0];
  print('Using light at ${targetLight.ip}\n');

  // Create bulb controller
  final bulb = Bulb();
  bulb.setDeviceIP(targetLight.ip);

  // Step 2: Start listening for push updates
  print('Step 2: Starting push updates to monitor state changes...');
  final pushSuccess = await bulb.startPush((state, sourceIp) {
    print('  🔔 State change detected:');
    print('     Power: ${state.state == true ? "ON" : "OFF"}');
    if (state.brightness != null) {
      print('     Brightness: ${state.brightness}');
    }
    if (state.rgb != null) {
      print('     RGB: ${state.rgb}');
    }
    if (state.colorTemp != null) {
      print('     Color Temp: ${state.colorTemp}K');
    }
    if (state.source != null) {
      print('     Source: ${state.source}');
    }
  });

  if (pushSuccess) {
    print('✓ Push updates enabled - monitoring for changes\n');
  } else {
    print('⚠ Could not enable push updates (will continue without monitoring)\n');
  }

  // Give push updates a moment to register
  await Future.delayed(const Duration(seconds: 2));

  // Step 3: Cycle through RGB colors
  print('Step 3: Cycling through RGB colors...\n');

  // Red
  print('Setting color to RED...');
  var builder = PilotBuilder()..setRgb(255, 0, 0);
  await bulb.turnOn(builder);
  print('✓ Light is now RED');
  await Future.delayed(const Duration(seconds: 3));

  // Green
  print('\nSetting color to GREEN...');
  builder = PilotBuilder()..setRgb(0, 255, 0);
  await bulb.turnOn(builder);
  print('✓ Light is now GREEN');
  await Future.delayed(const Duration(seconds: 3));

  // Blue
  print('\nSetting color to BLUE...');
  builder = PilotBuilder()..setRgb(0, 0, 255);
  await bulb.turnOn(builder);
  print('✓ Light is now BLUE');
  await Future.delayed(const Duration(seconds: 3));

  // Bonus: Cycle through more colors
  print('\nBonus: Cycling through more colors...\n');
  
  final colors = [
    {'name': 'Yellow', 'rgb': [255, 255, 0]},
    {'name': 'Cyan', 'rgb': [0, 255, 255]},
    {'name': 'Magenta', 'rgb': [255, 0, 255]},
    {'name': 'White', 'rgb': [255, 255, 255]},
  ];

  for (final color in colors) {
    final rgb = color['rgb'] as List<int>;
    print('Setting color to ${color['name']}...');
    builder = PilotBuilder()..setRgb(rgb[0], rgb[1], rgb[2]);
    await bulb.turnOn(builder);
    print('✓ Light is now ${color['name']}');
    await Future.delayed(const Duration(seconds: 2));
  }

  // Return to warm white
  print('\nReturning to warm white...');
  builder = PilotBuilder()
    ..brightness = 200
    ..colorTemp = 2700;
  await bulb.turnOn(builder);
  print('✓ Light returned to warm white (2700K)');

  // Wait a moment to see the final state
  await Future.delayed(const Duration(seconds: 2));

  // Cleanup
  print('\nCleaning up...');
  if (pushSuccess) {
    await bulb.stopPush();
    print('✓ Push updates stopped');
  }

  print('\n=== Demo Complete! ===');
}
