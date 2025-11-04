// Example demonstrating the WizLight package usage.
// See LICENSE file for licensing details.

import 'package:wizlight/wizlight.dart';

/// Example showing how to use the WizLight package to control WiZ smart bulbs
void main() async {
  // Create a bulb instance
  final bulb = Bulb();

  // Set the IP address of your WiZ bulb
  // You can discover the IP using the discover method
  bulb.setDeviceIP('192.168.1.100');

  print('=== WizLight Package Example ===\n');

  // Example 1: Turn the light on
  print('1. Turning light ON...');
  await bulb.toggleLight(true);
  await Future.delayed(Duration(seconds: 2));

  // Example 2: Set brightness to 50%
  print('2. Setting brightness to 50%...');
  await bulb.setBrightness(50);
  await Future.delayed(Duration(seconds: 2));

  // Example 3: Set brightness to 100%
  print('3. Setting brightness to 100%...');
  await bulb.setBrightness(100);
  await Future.delayed(Duration(seconds: 2));

  // Example 4: Set RGB color to red
  print('4. Setting color to RED...');
  await bulb.setRGBColor(255, 0, 0);
  await Future.delayed(Duration(seconds: 2));

  // Example 5: Set RGB color to green
  print('5. Setting color to GREEN...');
  await bulb.setRGBColor(0, 255, 0);
  await Future.delayed(Duration(seconds: 2));

  // Example 6: Set RGB color to blue
  print('6. Setting color to BLUE...');
  await bulb.setRGBColor(0, 0, 255);
  await Future.delayed(Duration(seconds: 2));

  // Example 7: Set color temperature (warm white)
  print('7. Setting color temperature to 2700K (warm white)...');
  await bulb.setColorTemp(2700);
  await Future.delayed(Duration(seconds: 2));

  // Example 8: Set color temperature (cool white)
  print('8. Setting color temperature to 6500K (cool white)...');
  await bulb.setColorTemp(6500);
  await Future.delayed(Duration(seconds: 2));

  // Example 9: Set a scene (Ocean = scene 1)
  print('9. Setting scene to Ocean (scene 1)...');
  await bulb.setScene(1);
  await Future.delayed(Duration(seconds: 3));

  // Example 10: Set animation speed
  print('10. Setting animation speed to 50%...');
  await bulb.setSpeed(50);
  await Future.delayed(Duration(seconds: 2));

  // Example 11: Get current status
  print('11. Getting current bulb status...');
  final status = await bulb.getStatus();
  if (status.isNotEmpty) {
    print('Current status:');
    print(status);
  }

  // Example 12: Get device information
  print('\n12. Getting device information...');
  final deviceInfo = await bulb.getDeviceInfo();
  if (deviceInfo.isNotEmpty) {
    print('Device info:');
    print(deviceInfo);
  }

  // Example 13: Turn the light off
  print('\n13. Turning light OFF...');
  await bulb.toggleLight(false);

  // Clean up
  bulb.close();

  print('\n=== Example completed ===');
}

/// Example showing how to discover bulbs on the network
void discoverExample() async {
  final bulb = Bulb();

  print('=== Discovering WiZ Bulbs ===\n');

  // Use your network's broadcast address
  // For 192.168.1.x network, use 192.168.1.255
  final broadcastIp = '192.168.1.255';

  print('Sending discovery request to $broadcastIp...');
  final result = await bulb.discover(broadcastIp);

  if (result.isNotEmpty) {
    print('Bulb discovered:');
    print(result);
  } else {
    print('No bulb responded to discovery request.');
  }

  bulb.close();
}

/// Example showing all available scenes
void scenesExample() async {
  final bulb = Bulb();
  bulb.setDeviceIP('192.168.1.100');

  print('=== Testing All Scenes ===\n');
  print(WizControl.getSceneList());

  // Cycle through first few scenes
  for (var sceneId = 1; sceneId <= 5; sceneId++) {
    print('Setting scene $sceneId...');
    await bulb.setScene(sceneId);
    await Future.delayed(Duration(seconds: 3));
  }

  bulb.close();
}

/// Example showing input validation
void validationExample() async {
  final bulb = Bulb();
  bulb.setDeviceIP('192.168.1.100');

  print('=== Testing Input Validation ===\n');

  // Test invalid brightness
  print('1. Testing invalid brightness (150)...');
  var result = await bulb.setBrightness(150);
  print('Result: $result'); // Should print "Invalid_Request"

  // Test invalid RGB values
  print('\n2. Testing invalid RGB color (300, 0, 0)...');
  result = await bulb.setRGBColor(300, 0, 0);
  print('Result: $result'); // Should print "Invalid_Request"

  // Test invalid color temperature
  print('\n3. Testing invalid color temperature (10000K)...');
  result = await bulb.setColorTemp(10000);
  print('Result: $result'); // Should print "Invalid_Request"

  // Test invalid scene
  print('\n4. Testing invalid scene (99)...');
  result = await bulb.setScene(99);
  print('Result: $result'); // Should print "Invalid_Request"

  bulb.close();
}
