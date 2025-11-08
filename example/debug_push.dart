// Debug push updates with detailed logging
import 'package:logging/logging.dart';
import 'package:wizlight/wizlight.dart';

void main() async {
  // Enable FINE level logging to see registration messages
  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((record) {
    print('[${record.level.name}] ${record.loggerName}: ${record.message}');
  });

  print('=== Push Debug Test ===\n');

  final bulb = Bulb();
  bulb.setDeviceIP('192.168.1.147');

  print('Starting push updates with detailed logging...\n');
  
  await bulb.startPush((state, sourceIp) {
    print('\n🔔 🔔 🔔 PUSH UPDATE RECEIVED! 🔔 🔔 🔔');
    print('From IP: $sourceIp');
    print('State: ${state.state}');
    print('Brightness: ${state.brightness}');
    print('Source: ${state.source}');
    print('');
  });

  print('\n========================================');
  print('Monitoring for 45 seconds...');
  print('Use Python CLI or WiZ app to change state');
  print('========================================\n');

  await Future.delayed(Duration(seconds: 45));

  print('\nStopping...');
  await bulb.stopPush();
}
