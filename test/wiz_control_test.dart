/***************************************************************************
 *  Project                WIZLIGHT
 *
 * Copyright (C) 2025 , Dart port
 *
 * Unit tests for WizControl class functionality
 *
 ***************************************************************************/

import 'package:test/test.dart';
import 'package:wizlight/src/wiz_control.dart';

void main() {
  group('WizControl - Singleton', () {
    test('getInstance returns same instance', () {
      final instance1 = WizControl.getInstance();
      final instance2 = WizControl.getInstance();

      expect(identical(instance1, instance2), isTrue);
    });
  });

  group('WizControl - Command Support', () {
    late WizControl wiz;

    setUp(() {
      wiz = WizControl.getInstance();
    });

    test('isCmdSupported returns true for valid commands', () {
      expect(wiz.isCmdSupported('discover'), isTrue);
      expect(wiz.isCmdSupported('on'), isTrue);
      expect(wiz.isCmdSupported('off'), isTrue);
      expect(wiz.isCmdSupported('status'), isTrue);
      expect(wiz.isCmdSupported('reboot'), isTrue);
      expect(wiz.isCmdSupported('getdeviceinfo'), isTrue);
      expect(wiz.isCmdSupported('getwificonfig'), isTrue);
      expect(wiz.isCmdSupported('getuserconfig'), isTrue);
      expect(wiz.isCmdSupported('getsystemconfig'), isTrue);
      expect(wiz.isCmdSupported('setbrightness'), isTrue);
      expect(wiz.isCmdSupported('setrgbcolor'), isTrue);
      expect(wiz.isCmdSupported('setspeed'), isTrue);
      expect(wiz.isCmdSupported('setcolortemp'), isTrue);
      expect(wiz.isCmdSupported('setscene'), isTrue);
    });

    test('isCmdSupported returns false for invalid commands', () {
      expect(wiz.isCmdSupported('invalid'), isFalse);
      expect(wiz.isCmdSupported('random'), isFalse);
      expect(wiz.isCmdSupported(''), isFalse);
    });
  });

  group('WizControl - Scene List', () {
    test('getSceneList contains all 32 scenes', () {
      final sceneList = WizControl.getSceneList();

      // Check for presence of specific scenes
      expect(sceneList.contains('Ocean'), isTrue);
      expect(sceneList.contains('Romance'), isTrue);
      expect(sceneList.contains('Sunset'), isTrue);
      expect(sceneList.contains('Party'), isTrue);
      expect(sceneList.contains('Fireplace'), isTrue);
      expect(sceneList.contains('Cozy'), isTrue);
      expect(sceneList.contains('Forest'), isTrue);
      expect(sceneList.contains('Pastel Colors'), isTrue);
      expect(sceneList.contains('Wake up'), isTrue);
      expect(sceneList.contains('Bedtime'), isTrue);
      expect(sceneList.contains('Warm White'), isTrue);
      expect(sceneList.contains('Daylight'), isTrue);
      expect(sceneList.contains('Cool white'), isTrue);
      expect(sceneList.contains('Night light'), isTrue);
      expect(sceneList.contains('Focus'), isTrue);
      expect(sceneList.contains('Relax'), isTrue);
      expect(sceneList.contains('True colors'), isTrue);
      expect(sceneList.contains('TV time'), isTrue);
      expect(sceneList.contains('Plantgrowth'), isTrue);
      expect(sceneList.contains('Spring'), isTrue);
      expect(sceneList.contains('Summer'), isTrue);
      expect(sceneList.contains('Fall'), isTrue);
      expect(sceneList.contains('Deepdive'), isTrue);
      expect(sceneList.contains('Jungle'), isTrue);
      expect(sceneList.contains('Mojito'), isTrue);
      expect(sceneList.contains('Club'), isTrue);
      expect(sceneList.contains('Christmas'), isTrue);
      expect(sceneList.contains('Halloween'), isTrue);
      expect(sceneList.contains('Candlelight'), isTrue);
      expect(sceneList.contains('Golden white'), isTrue);
      expect(sceneList.contains('Pulse'), isTrue);
      expect(sceneList.contains('Steampunk'), isTrue);

      // Check for scene numbers
      expect(sceneList.contains('1\t'), isTrue);
      expect(sceneList.contains('32\t'), isTrue);
    });
  });

  group('WizControl - Command Enum', () {
    test('WizCmd enum has all commands', () {
      // Verify all enum values exist
      expect(WizCmd.values, contains(WizCmd.discover));
      expect(WizCmd.values, contains(WizCmd.on));
      expect(WizCmd.values, contains(WizCmd.off));
      expect(WizCmd.values, contains(WizCmd.status));
      expect(WizCmd.values, contains(WizCmd.reboot));
      expect(WizCmd.values, contains(WizCmd.getdeviceinfo));
      expect(WizCmd.values, contains(WizCmd.getwificonfig));
      expect(WizCmd.values, contains(WizCmd.getuserconfig));
      expect(WizCmd.values, contains(WizCmd.getsystemconfig));
      expect(WizCmd.values, contains(WizCmd.setbrightness));
      expect(WizCmd.values, contains(WizCmd.setrgbcolor));
      expect(WizCmd.values, contains(WizCmd.setspeed));
      expect(WizCmd.values, contains(WizCmd.setcolortemp));
      expect(WizCmd.values, contains(WizCmd.setscene));

      // Verify count
      expect(WizCmd.values.length, equals(14));
    });
  });

  group('WizControl - Usage Information', () {
    test('printUsage contains all commands', () {
      // We can't directly test print output easily, but we can verify
      // the method exists and doesn't throw
      expect(() => WizControl.printUsage(), returnsNormally);
    });
  });

  group('WizControl - Argument Validation', () {
    late WizControl wiz;

    setUp(() {
      wiz = WizControl.getInstance();
    });

    test('validateArgsUsage returns false for empty args', () async {
      expect(await wiz.validateArgsUsage([]), isFalse);
    });

    test('validateArgsUsage returns false for invalid command', () async {
      expect(await wiz.validateArgsUsage(['invalid']), isFalse);
    });

    test('validateArgsUsage handles help flag', () async {
      // Test various commands with --help
      expect(await wiz.validateArgsUsage(['on', '--help']), isFalse);
      expect(await wiz.validateArgsUsage(['discover', '--help']), isFalse);
      expect(await wiz.validateArgsUsage(['setbrightness', '--help']), isFalse);
    });
  });

  group('WizControl - Command Format Validation', () {
    test('Command names match C++ implementation', () {
      final wiz = WizControl.getInstance();

      // All command names should be lowercase and match C++ version
      expect(wiz.isCmdSupported('discover'), isTrue);
      expect(wiz.isCmdSupported('DISCOVER'), isFalse); // Case sensitive
      expect(wiz.isCmdSupported('Discover'), isFalse); // Case sensitive

      // Verify specific command mappings
      expect(wiz.isCmdSupported('getdeviceinfo'), isTrue);
      expect(wiz.isCmdSupported('getwificonfig'), isTrue);
      expect(wiz.isCmdSupported('getuserconfig'), isTrue);
      expect(wiz.isCmdSupported('getsystemconfig'), isTrue);
    });
  });
}
