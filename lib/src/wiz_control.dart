/***************************************************************************
 *  Project                WIZLIGHT
 *
 * Copyright (C) 2025 , Dart port
 * Original C++ code Copyright (C) 2022, Sri Balaji S.
 *
 * This software is licensed as described in the file LICENSE, which
 * you should have received as part of this distribution.
 *
 * You may opt to use, copy, modify, merge, publish, distribute and/or sell
 * copies of the Software, and permit persons to whom the Software is
 * furnished to do so, under the terms of the LICENSE file.
 *
 * This software is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY
 * KIND, either express or implied.
 *
 * @file wiz_control.dart
 *
 ***************************************************************************/

import 'dart:io';
import 'bulb.dart';

/// Supported WiZ commands
enum WizCmd {
  discover,
  on,
  off,
  status,
  reboot,
  getdeviceinfo,
  getwificonfig,
  getuserconfig,
  getsystemconfig,
  setbrightness,
  setrgbcolor,
  setspeed,
  setcolortemp,
  setscene,
}

/// Main controller for WiZ bulb operations
///
/// Singleton class that handles command parsing, validation, and execution
/// for WiZ smart bulb control. Supports both interactive and CLI modes.
class WizControl {
  static WizControl? _instance;

  final Bulb _bulb = Bulb();
  final Map<String, WizCmd> _cmdMap = {
    'discover': WizCmd.discover,
    'on': WizCmd.on,
    'off': WizCmd.off,
    'status': WizCmd.status,
    'reboot': WizCmd.reboot,
    'getdeviceinfo': WizCmd.getdeviceinfo,
    'getwificonfig': WizCmd.getwificonfig,
    'getuserconfig': WizCmd.getuserconfig,
    'getsystemconfig': WizCmd.getsystemconfig,
    'setbrightness': WizCmd.setbrightness,
    'setrgbcolor': WizCmd.setrgbcolor,
    'setspeed': WizCmd.setspeed,
    'setcolortemp': WizCmd.setcolortemp,
    'setscene': WizCmd.setscene,
  };

  WizControl._();

  /// Gets the singleton instance
  static WizControl getInstance() {
    _instance ??= WizControl._();
    return _instance!;
  }

  /// Checks if a command is supported
  bool isCmdSupported(String cmd) {
    return _cmdMap.containsKey(cmd);
  }

  /// Prints general usage information
  static void printUsage() {
    print('''

Usage: wizlight {Options} [Commands] {Args}
Options:
  --help\t\t\tShow the usage menu of this app
  --verbose\t\t\tEnable verbose logs

Commands:
  discover\t\t\tDiscover the Wiz bulb on the network
  off\t\t\t\tTurn Off Wiz bulb
  on\t\t\t\tTurn On Wiz bulb
  status\t\t\tGet the current status of Wiz bulb
  reboot\t\t\tReboot Wiz bulb
  getdeviceinfo\t\t\tGet the bulb information
  getwificonfig\t\t\tGet the Wifi Configuration
  getuserconfig\t\t\tGet the User Configuration
  getsystemconfig\t\tGet the System Configuration
  setbrightness\t\t\tSets the brightness on the bulb in percent
  setrgbcolor\t\t\tSets the R G B color on the bulb
  setspeed\t\t\tSets the color changing speed in percent
  setcolortemp\t\t\tSets the color temperature in kelvins
  setscene\t\t\tSets the scene mode on the bulb
''');
  }

  /// Gets the list of available scenes
  static String getSceneList() {
    return '''
Available Scene modes:
  1\tOcean
  2\tRomance
  3\tSunset
  4\tParty
  5\tFireplace
  6\tCozy
  7\tForest
  8\tPastel Colors
  9\tWake up
  10\tBedtime
  11\tWarm White
  12\tDaylight
  13\tCool white
  14\tNight light
  15\tFocus
  16\tRelax
  17\tTrue colors
  18\tTV time
  19\tPlantgrowth
  20\tSpring
  21\tSummer
  22\tFall
  23\tDeepdive
  24\tJungle
  25\tMojito
  26\tClub
  27\tChristmas
  28\tHalloween
  29\tCandlelight
  30\tGolden white
  31\tPulse
  32\tSteampunk
''';
  }

  /// Checks for an argument option and returns its value
  bool _checkArgOptions(
    List<String> args,
    String cmd,
    String option,
    void Function(String) setter,
  ) {
    final idx = args.indexOf(option);
    if (idx != -1 && idx + 1 < args.length) {
      setter(args[idx + 1]);
      return true;
    } else if (idx != -1) {
      stderr.writeln('Error: Missing required parameter for $option option');
      return false;
    } else {
      stderr.writeln('''
Unknown Option

Usage: wizlight $cmd {OPTIONS}
Try 'wizlight $cmd --help' for help.
''');
      return false;
    }
  }

  /// Validates command-line arguments and executes the command
  Future<bool> validateArgsUsage(List<String> args) async {
    if (args.isEmpty || !_cmdMap.containsKey(args[0])) {
      printUsage();
      return false;
    }

    var showArgUsage = false;
    String? ipAddr;
    String ret = '';
    final cmd = args[0];
    final argUsageList = <String>[];
    final eCmd = _cmdMap[cmd]!;

    if (args.length > 1 && args[1] == '--help') {
      showArgUsage = true;
      if (eCmd != WizCmd.discover) {
        argUsageList.add('--ip\t\t\tIP address of the bulb.\n');
      }
      argUsageList.add('--help\t\t\tShow this message and exit.\n');
    } else {
      if (eCmd != WizCmd.discover) {
        if (!_checkArgOptions(args, cmd, '--ip', (val) => ipAddr = val)) {
          return false;
        }
        _bulb.setDeviceIP(ipAddr!);
      }
    }

    switch (eCmd) {
      case WizCmd.discover:
        if (showArgUsage) {
          argUsageList
              .add('--bcast\t\t\tBroadcast IP Address [eg: 192.168.1.255].\n');
        } else {
          String? bCastIp;
          if (_checkArgOptions(args, cmd, '--bcast', (val) => bCastIp = val)) {
            ret = await _bulb.discover(bCastIp!);
          }
        }
        break;

      case WizCmd.on:
      case WizCmd.off:
      case WizCmd.status:
      case WizCmd.reboot:
      case WizCmd.getdeviceinfo:
      case WizCmd.getwificonfig:
      case WizCmd.getuserconfig:
      case WizCmd.getsystemconfig:
        if (!showArgUsage) {
          ret = await performWizRequest(cmd);
        }
        break;

      case WizCmd.setbrightness:
        if (showArgUsage) {
          argUsageList
              .add('--dim\t\t\tBrightness level in percent [0 to 100].\n');
        } else {
          String? dimStr;
          if (_checkArgOptions(args, cmd, '--dim', (val) => dimStr = val)) {
            final dimlevel = int.tryParse(dimStr!);
            if (dimlevel != null) {
              ret = await _bulb.setBrightness(dimlevel);
            }
          }
        }
        break;

      case WizCmd.setrgbcolor:
        if (showArgUsage) {
          argUsageList.add('--r\t\t\tRed color range [0 to 255].\n');
          argUsageList.add('--g\t\t\tGreen color range [0 to 255].\n');
          argUsageList.add('--b\t\t\tBlue color range [0 to 255].\n');
        } else {
          String? rStr, gStr, bStr;
          if (_checkArgOptions(args, cmd, '--r', (val) => rStr = val) &&
              _checkArgOptions(args, cmd, '--g', (val) => gStr = val) &&
              _checkArgOptions(args, cmd, '--b', (val) => bStr = val)) {
            final r = int.tryParse(rStr!);
            final g = int.tryParse(gStr!);
            final b = int.tryParse(bStr!);
            if (r != null && g != null && b != null) {
              ret = await _bulb.setRGBColor(r, g, b);
            }
          }
        }
        break;

      case WizCmd.setspeed:
        if (showArgUsage) {
          argUsageList.add(
              '--speed\t\t\tColor changing speed in percent [0 to 100].\n');
        } else {
          String? speedStr;
          if (_checkArgOptions(args, cmd, '--speed', (val) => speedStr = val)) {
            final speed = int.tryParse(speedStr!);
            if (speed != null) {
              ret = await _bulb.setSpeed(speed);
            }
          }
        }
        break;

      case WizCmd.setcolortemp:
        if (showArgUsage) {
          argUsageList.add(
              '--temp\t\t\tColor temperature in kelvins [1000 to 8000].\n');
        } else {
          String? tempStr;
          if (_checkArgOptions(args, cmd, '--temp', (val) => tempStr = val)) {
            final temp = int.tryParse(tempStr!);
            if (temp != null) {
              ret = await _bulb.setColorTemp(temp);
            }
          }
        }
        break;

      case WizCmd.setscene:
        if (showArgUsage) {
          argUsageList.add('--scene\t\t\tScene mode [1 to 32].\n');
          argUsageList.add(getSceneList());
        } else {
          String? sceneStr;
          if (_checkArgOptions(args, cmd, '--scene', (val) => sceneStr = val)) {
            final scene = int.tryParse(sceneStr!);
            if (scene != null) {
              ret = await _bulb.setScene(scene);
            }
          }
        }
        break;
    }

    if (showArgUsage) {
      print('Usage: wizlight $cmd {OPTIONS}\n\nOptions:');
      for (final usage in argUsageList) {
        stdout.write(usage);
      }
      return false;
    } else if (ret.isNotEmpty) {
      print(ret);
    }
    return true;
  }

  /// Performs a WiZ request in interactive mode
  ///
  /// Prompts the user for required parameters and executes the command.
  Future<String> performWizRequest(String cmd) async {
    String ret = '';
    if (!_cmdMap.containsKey(cmd)) {
      printUsage();
      return ret;
    }

    final eCmd = _cmdMap[cmd]!;

    // Get IP address if not set and not discovery command
    if (eCmd != WizCmd.discover && _bulb.getDeviceIp().isEmpty) {
      String? ip;
      while (ip == null || ip.isEmpty) {
        stdout.write('Enter the bulb IP address: ');
        ip = stdin.readLineSync();
      }
      _bulb.setDeviceIP(ip);
    }

    switch (eCmd) {
      case WizCmd.discover:
        stdout.write('Enter the broadcast IP Address: ');
        final bcastIp = stdin.readLineSync() ?? '';
        ret = await _bulb.discover(bcastIp);
        break;

      case WizCmd.on:
        ret = await _bulb.toggleLight(true);
        break;

      case WizCmd.off:
        ret = await _bulb.toggleLight(false);
        break;

      case WizCmd.status:
        ret = await _bulb.getStatus();
        break;

      case WizCmd.reboot:
        ret = await _bulb.reboot();
        break;

      case WizCmd.getdeviceinfo:
        ret = await _bulb.getDeviceInfo();
        break;

      case WizCmd.getuserconfig:
        ret = await _bulb.getUserConfig();
        break;

      case WizCmd.getwificonfig:
        ret = await _bulb.getWifiConfig();
        break;

      case WizCmd.getsystemconfig:
        ret = await _bulb.getSystemConfig();
        break;

      case WizCmd.setbrightness:
        stdout.write('Enter the brightness level [0 to 100]: ');
        final levelStr = stdin.readLineSync() ?? '';
        final level = int.tryParse(levelStr);
        if (level != null) {
          ret = await _bulb.setBrightness(level);
        }
        break;

      case WizCmd.setrgbcolor:
        stdout.write('Enter the Red color range [0 to 255]: ');
        final rStr = stdin.readLineSync() ?? '';
        stdout.write('Enter the Green color range [0 to 255]: ');
        final gStr = stdin.readLineSync() ?? '';
        stdout.write('Enter the Blue color range [0 to 255]: ');
        final bStr = stdin.readLineSync() ?? '';
        final r = int.tryParse(rStr);
        final g = int.tryParse(gStr);
        final b = int.tryParse(bStr);
        if (r != null && g != null && b != null) {
          ret = await _bulb.setRGBColor(r, g, b);
        }
        break;

      case WizCmd.setspeed:
        stdout.write('Enter the color changing speed in percent [0 to 100]: ');
        final speedStr = stdin.readLineSync() ?? '';
        final speed = int.tryParse(speedStr);
        if (speed != null) {
          ret = await _bulb.setSpeed(speed);
        }
        break;

      case WizCmd.setcolortemp:
        stdout.write('Enter the color temperature in kelvins [1000 to 8000]: ');
        final colorStr = stdin.readLineSync() ?? '';
        final color = int.tryParse(colorStr);
        if (color != null) {
          ret = await _bulb.setColorTemp(color);
        }
        break;

      case WizCmd.setscene:
        print(getSceneList());
        stdout.write('Enter the scene mode [1 to 32]: ');
        final sceneStr = stdin.readLineSync() ?? '';
        final scene = int.tryParse(sceneStr);
        if (scene != null) {
          ret = await _bulb.setScene(scene);
        }
        break;
    }

    return ret;
  }

  /// Closes resources
  void close() {
    _bulb.close();
  }
}
