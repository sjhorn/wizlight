// Example: Monitor events from a WiZ Smart Dial Switch
// See LICENSE file for licensing details.

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:wizlight/wizlight.dart';

Future<void> main(List<String> args) async {
  // Setup logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('[${record.level.name}] ${record.time}: ${record.message}');
  });

  // Get MAC address from arguments or use default
  final mac = args.isNotEmpty ? args[0] : '9877d583fec5';

  print('WiZ Smart Dial Monitor');
  print('=====================');
  print('Listening for events from dial: $mac');
  print('Press Ctrl+C to exit\n');

  // Create and configure the dial
  final dial = WizDial(mac: mac, name: 'Living Room Dial');

  // Start listening for events
  final started = await dial.startListening((event) {
    final timestamp = event.timestamp.toString().substring(11, 23);

    switch (event.type) {
      case DialEventType.rotationClockwise:
        print('[$timestamp] 🔄 Rotated clockwise (seq: ${event.sequence})');
        break;

      case DialEventType.rotationCounterClockwise:
        print(
            '[$timestamp] 🔄 Rotated counter-clockwise (seq: ${event.sequence})');
        break;

      case DialEventType.dialShortPress:
        print('[$timestamp] ⏺️  Dial button pressed (short)');
        break;

      case DialEventType.dialLongPress:
        print('[$timestamp] ⏺️  Dial button pressed (LONG)');
        break;

      case DialEventType.scene1ShortPress:
        print('[$timestamp] 🎬 Scene 1 button pressed (short)');
        break;

      case DialEventType.scene1LongPress:
        print('[$timestamp] 🎬 Scene 1 button pressed (LONG)');
        break;

      case DialEventType.scene2ShortPress:
        print('[$timestamp] 🎬 Scene 2 button pressed (short)');
        break;

      case DialEventType.scene2LongPress:
        print('[$timestamp] 🎬 Scene 2 button pressed (LONG)');
        break;

      case DialEventType.unknown:
        print('[$timestamp] ❓ Unknown event type: 0x${event.rawType.toRadixString(16)}');
        break;
    }

    // Show additional debug info
    print('    Raw: type=0x${event.rawType.toRadixString(16).padLeft(2, '0')}, '
        'action=0x${event.action.toRadixString(16).padLeft(2, '0')}, '
        'state=0x${event.state.toRadixString(16).padLeft(2, '0')}');
    print('');
  });

  if (!started) {
    print('Error: Failed to start dial manager');
    exit(1);
  }

  print('Listening for dial events...\n');

  // Keep running until interrupted
  await ProcessSignal.sigint.watch().first;

  print('\nStopping...');
  dial.stopListening();
  await DialManager().stop();
  print('Stopped.');
}
