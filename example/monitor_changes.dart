// Example: Monitor external state changes from WiZ bulbs
// See LICENSE file for licensing details.

import 'package:logging/logging.dart';
import 'package:wizlight/wizlight.dart';

void main() async {
  // Enable INFO level logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('[${record.level.name}] ${record.message}');
  });

  print('=== WiZ Push Updates Monitor ===\n');

  // Discover bulbs
  print('Discovering bulbs...');
  final discovered = await discoverBulbs(
    broadcastAddress: '192.168.1.255',
    waitTime: Duration(seconds: 5),
  );

  if (discovered.isEmpty) {
    print('No bulbs found.');
    return;
  }

  print('\nFound ${discovered.length} bulb(s):');
  for (var i = 0; i < discovered.length; i++) {
    print('  [$i] ${discovered[i].ip} (${discovered[i].mac})');
  }

  // Setup monitoring for all bulbs
  final bulbs = <Bulb>[];
  print('\nStarting push updates...');
  for (final disc in discovered) {
    final bulb = Bulb();
    bulb.setDeviceIP(disc.ip);
    
    await bulb.startPush((state, sourceIp) {
      print('\n🔔 State change on ${disc.ip}:');
      if (state.state != null) {
        print('   Power: ${state.state! ? "ON" : "OFF"}');
      }
      if (state.brightness != null) {
        print('   Brightness: ${state.brightness}');
      }
      if (state.colorTemp != null) {
        print('   Color Temp: ${state.colorTemp}K');
      }
      if (state.rgb != null) {
        print('   RGB: ${state.rgb}');
      }
      if (state.source != null) {
        print('   Source: ${state.source}');
      }
      if (state.sceneId != null) {
        print('   Scene: ${state.sceneId}');
      }
    });
    
    bulbs.add(bulb);
    print('✓ Monitoring ${disc.ip}');
  }

  print('\n========================================');
  print('Monitoring for state changes...');
  print('Try:');
  print('  - Flip the wall switch');
  print('  - Use the WiZ mobile app');
  print('  - Use voice assistant');
  print('========================================\n');
  print('Press Ctrl+C to exit\n');

  // Keep monitoring indefinitely
  try {
    while (true) {
      await Future.delayed(Duration(seconds: 60));
      print('Still monitoring... (${DateTime.now()})');
    }
  } catch (e) {
    print('\nExiting...');
  } finally {
    for (final bulb in bulbs) {
      await bulb.stopPush();
    }
  }
}
