// Example: Discover WiZ bulbs on the network
// See LICENSE file for licensing details.

import 'package:wizlight/wizlight.dart';

void main() async {
  // Discover bulbs on the network
  print('Discovering bulbs...');
  final bulbs = await discoverBulbs(
    broadcastAddress: '192.168.1.255', // Change to your network
    waitTime: Duration(seconds: 5),
  );

  if (bulbs.isEmpty) {
    print('No bulbs found. Make sure they are powered on and on the same network.');
    return;
  }

  print('Found ${bulbs.length} bulb(s):');
  for (final discovered in bulbs) {
    print('  IP: ${discovered.ip}, MAC: ${discovered.mac}');
  }

  // Control the first bulb found
  final bulb = Bulb();
  bulb.setDeviceIP(bulbs.first.ip);

  print('\nTurning on bulb at ${bulbs.first.ip}...');
  await bulb.turnOn();

  print('Waiting 3 seconds...');
  await Future.delayed(Duration(seconds: 3));

  print('Turning off bulb...');
  await bulb.turnOff();

  print('Done!');
}
