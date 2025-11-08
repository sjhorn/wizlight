// Example: Listen for real-time push updates from WiZ bulbs
// See LICENSE file for licensing details.

import 'package:logging/logging.dart';
import 'package:wizlight/wizlight.dart';

void main() async {
  // Enable logging to see what's happening
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.time} [${record.level.name}] ${record.loggerName}: ${record.message}');
  });

  print('=== WiZ Push Updates Demo ===\n');

  // Discover bulbs on the network
  print('Discovering bulbs...');
  final discovered = await discoverBulbs(
    broadcastAddress: '192.168.1.255',
    waitTime: Duration(seconds: 5),
  );

  if (discovered.isEmpty) {
    print('No bulbs found. Make sure they are powered on and on the same network.');
    return;
  }

  print('Found ${discovered.length} bulb(s):');
  for (var i = 0; i < discovered.length; i++) {
    print('  [$i] IP: ${discovered[i].ip}, MAC: ${discovered[i].mac}');
  }
  print('');

  // Create bulb controllers for all discovered bulbs
  final bulbs = <Bulb>[];
  for (final disc in discovered) {
    final bulb = Bulb();
    bulb.setDeviceIP(disc.ip);
    bulbs.add(bulb);
  }

  // Start push updates for all bulbs
  print('Starting push updates for all bulbs...');
  for (var i = 0; i < bulbs.length; i++) {
    final bulb = bulbs[i];
    final ip = discovered[i].ip;
    
    final success = await bulb.startPush((state, sourceIp) {
      print('\n>>> State change detected on bulb $ip:');
      print('    On: ${state.state}');
      print('    Brightness: ${state.brightness}');
      print('    Color Temp: ${state.colorTemp}K');
      print('    RGB: ${state.rgb}');
      print('    Source: ${state.source}');
      print('    Scene: ${state.sceneId}');
    });
    
    if (success) {
      print('  ✓ Push updates enabled for $ip');
    } else {
      print('  ✗ Failed to enable push updates for $ip');
    }
  }

  print('\n=== Now listening for state changes ===');
  print('Try the following:');
  print('  1. Use the physical wall switch to turn lights on/off');
  print('  2. Use the WiZ app to change brightness or color');
  print('  3. Watch for real-time updates below!\n');
  print('Waiting 10 seconds to demonstrate push updates...\n');

  // Wait a bit to see push updates from manual changes
  await Future.delayed(Duration(seconds: 10));

  // Now programmatically trigger some changes
  if (bulbs.isNotEmpty) {
    print('\n=== Testing programmatic changes ===\n');
    
    final testBulb = bulbs[0];
    final testIp = discovered[0].ip;
    
    print('Test 1: Turning ON bulb at $testIp...');
    await testBulb.turnOn();
    await Future.delayed(Duration(seconds: 2));
    
    print('\nTest 2: Setting brightness to 50%...');
    var builder = PilotBuilder()..brightness = 128;
    await testBulb.turnOn(builder);
    await Future.delayed(Duration(seconds: 2));
    
    print('\nTest 3: Setting to warm white (2700K)...');
    builder = PilotBuilder()
      ..brightness = 128
      ..colorTemp = 2700;
    await testBulb.turnOn(builder);
    await Future.delayed(Duration(seconds: 2));
    
    print('\nTest 4: Setting to RGB red...');
    builder = PilotBuilder()..setRgb(255, 0, 0);
    await testBulb.turnOn(builder);
    await Future.delayed(Duration(seconds: 2));
    
    print('\nTest 5: Setting to RGB blue...');
    builder = PilotBuilder()..setRgb(0, 0, 255);
    await testBulb.turnOn(builder);
    await Future.delayed(Duration(seconds: 2));
    
    print('\nTest 6: Turning OFF bulb...');
    await testBulb.turnOff();
    await Future.delayed(Duration(seconds: 2));
  }

  // Keep listening for a bit more
  print('\nWaiting 5 more seconds for any manual changes...');
  print('(Try using the wall switch or WiZ app now!)\n');
  await Future.delayed(Duration(seconds: 5));

  // Cleanup
  print('\nStopping push updates...');
  for (final bulb in bulbs) {
    await bulb.stopPush();
  }
  
  print('\nDone! Push updates test complete.');
}
