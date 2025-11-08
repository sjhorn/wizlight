// Example: Control a WiZ bulb using a Smart Dial Switch
// See LICENSE file for licensing details.

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:wizlight/wizlight.dart';

Future<void> main(List<String> args) async {
  // Setup logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('[${record.level.name}] ${record.message}');
  });

  if (args.length < 2) {
    print('Usage: dart dial_controlled_bulb.dart <dial_mac> <bulb_ip>');
    print('Example: dart dial_controlled_bulb.dart 9877d583fec5 192.168.1.100');
    exit(1);
  }

  final dialMac = args[0];
  final bulbIp = args[1];

  print('WiZ Smart Dial + Bulb Controller');
  print('=================================');
  print('Dial MAC: $dialMac');
  print('Bulb IP:  $bulbIp');
  print('Press Ctrl+C to exit\n');

  // Setup bulb
  final bulb = Bulb();
  bulb.setDeviceIP(bulbIp);

  // Get initial state
  print('Getting bulb state...');
  final initialState = await bulb.updateState();
  if (initialState == null) {
    print('Error: Could not connect to bulb at $bulbIp');
    exit(1);
  }

  var currentBrightness = initialState.brightness ?? 128;
  var isOn = initialState.state ?? false;

  print('Bulb is ${isOn ? 'ON' : 'OFF'}, brightness: ${(currentBrightness * 100 / 255).round()}%');
  print('');

  // Setup dial
  final dial = WizDial(mac: dialMac, name: 'Controller');

  await dial.startListening((event) async {
    print('Event: ${event.type}');

    switch (event.type) {
      case DialEventType.rotationClockwise:
        // Increase brightness by 5%
        if (isOn) {
          currentBrightness = (currentBrightness + 13).clamp(10, 255);
          final percent = (currentBrightness * 100 / 255).round();
          await bulb.setBrightness(percent);
          print('  → Brightness increased to $percent%');
        }
        break;

      case DialEventType.rotationCounterClockwise:
        // Decrease brightness by 5%
        if (isOn) {
          currentBrightness = (currentBrightness - 13).clamp(10, 255);
          final percent = (currentBrightness * 100 / 255).round();
          await bulb.setBrightness(percent);
          print('  → Brightness decreased to $percent%');
        }
        break;

      case DialEventType.dialShortPress:
        // Toggle power
        if (isOn) {
          await bulb.turnOff();
          isOn = false;
          print('  → Bulb turned OFF');
        } else {
          await bulb.turnOn();
          isOn = true;
          print('  → Bulb turned ON');
        }
        break;

      case DialEventType.dialLongPress:
        // Set to 100% brightness
        if (!isOn) {
          await bulb.turnOn();
          isOn = true;
        }
        currentBrightness = 255;
        await bulb.setBrightness(100);
        print('  → Bulb set to 100%');
        break;

      case DialEventType.scene1ShortPress:
        // Set to warm white (2700K)
        await bulb.setColorTemp(2700);
        print('  → Set to warm white (2700K)');
        break;

      case DialEventType.scene1LongPress:
        // Set to scene 1 (Ocean)
        await bulb.setScene(1);
        print('  → Set to scene 1 (Ocean)');
        break;

      case DialEventType.scene2ShortPress:
        // Set to cool white (6500K)
        await bulb.setColorTemp(6500);
        print('  → Set to cool white (6500K)');
        break;

      case DialEventType.scene2LongPress:
        // Set to scene 2 (Romance)
        await bulb.setScene(2);
        print('  → Set to scene 2 (Romance)');
        break;

      case DialEventType.unknown:
        print('  → Unknown event: 0x${event.rawType.toRadixString(16)}');
        break;
    }
  });

  print('Controller active! Use the dial to control the bulb:');
  print('  • Rotate: Adjust brightness');
  print('  • Press dial (short): Toggle power');
  print('  • Press dial (long): Set to 100%');
  print('  • Scene 1 (short): Warm white');
  print('  • Scene 1 (long): Ocean scene');
  print('  • Scene 2 (short): Cool white');
  print('  • Scene 2 (long): Romance scene');
  print('');

  // Keep running until interrupted
  await ProcessSignal.sigint.watch().first;

  print('\nStopping...');
  dial.stopListening();
  await DialManager().stop();
  print('Stopped.');
}
