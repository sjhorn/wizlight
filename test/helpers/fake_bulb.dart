// Mock UDP server for testing bulb operations without a real bulb
// Based on pywizlight's fake_bulb.py
// See LICENSE file for licensing details.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Configuration data for different bulb types
class BulbConfig {
  final String moduleName;
  final String fwVersion;
  final Map<String, dynamic> systemConfig;
  final Map<String, dynamic> modelConfig;
  final Map<String, dynamic> userConfig;
  final Map<String, dynamic>? powerResponse;

  const BulbConfig({
    required this.moduleName,
    required this.fwVersion,
    required this.systemConfig,
    required this.modelConfig,
    required this.userConfig,
    this.powerResponse,
  });
}

/// Predefined bulb configurations for testing
class BulbConfigs {
  /// ESP01_SHRGB_03 - Standard RGB bulb (v1.25.0)
  static const rgbBulb = BulbConfig(
    moduleName: 'ESP01_SHRGB_03',
    fwVersion: '1.25.0',
    systemConfig: {
      'method': 'getSystemConfig',
      'env': 'pro',
      'result': {
        'mac': 'a8bb5006033d',
        'homeId': 5385975,
        'roomId': 5385975,
        'homeLock': false,
        'pairingLock': false,
        'typeId': 0,
        'moduleName': 'ESP01_SHRGB_03',
        'fwVersion': '1.25.0',
        'groupId': 0,
        'drvConf': [20, 1],
      },
    },
    modelConfig: {
      'method': 'getModelConfig',
      'env': 'pro',
      'result': {
        'ps': 1,
        'pwmFreq': 1000,
        'pwmRange': [3, 100],
        'wcr': 30,
        'nowc': 1,
        'cctRange': [2200, 2700, 4800, 6500],
        'extRange': [2200, 2700, 6500], // Extended range (3 values)
        'renderFactor': [171, 255, 75, 255, 43, 85, 0, 0, 0, 0],
      },
    },
    userConfig: {
      'method': 'getUserConfig',
      'env': 'pro',
      'result': {
        'fadeIn': 0,
        'fadeOut': 0,
        'dftDim': 10,
        'pwmRange': [0, 100],
        'whiteRange': [2200, 6500],
        'extRange': [2200, 2700, 6500],
        'po': false,
      },
    },
  );

  /// ESP01_SHRGB1C_31 - RGBWW bulb with 2 white channels (v1.17.1)
  static const rgbwwBulb = BulbConfig(
    moduleName: 'ESP01_SHRGB1C_31',
    fwVersion: '1.17.1',
    systemConfig: {
      'method': 'getSystemConfig',
      'env': 'pro',
      'result': {
        'mac': 'a8bb5006033d',
        'homeId': 5385975,
        'roomId': 5385975,
        'homeLock': false,
        'pairingLock': false,
        'typeId': 0,
        'moduleName': 'ESP01_SHRGB1C_31',
        'fwVersion': '1.17.1',
        'groupId': 0,
        'drvConf': [20, 2],
      },
    },
    modelConfig: {
      'method': 'getModelConfig',
      'env': 'pro',
      'result': {
        'ps': 1,
        'pwmFreq': 1000,
        'pwmRange': [3, 100],
        'wcr': 20,
        'nowc': 2,
        'cctRange': [2700, 2700, 6500, 6500],
        'renderFactor': [255, 0, 255, 255, 0, 0, 0, 0, 0, 0],
      },
    },
    userConfig: {
      'method': 'getUserConfig',
      'env': 'pro',
      'result': {
        'fadeIn': 0,
        'fadeOut': 0,
        'dftDim': 10,
        'pwmRange': [0, 100],
        'whiteRange': [2700, 6500],
        'extRange': [2700, 6500],
        'po': false,
      },
    },
  );

  /// ESP10_SOCKET_06 - Smart socket with power monitoring (v1.25.0)
  static const socket = BulbConfig(
    moduleName: 'ESP10_SOCKET_06',
    fwVersion: '1.25.0',
    systemConfig: {
      'method': 'getSystemConfig',
      'env': 'pro',
      'result': {
        'mac': 'a8bb5006033d',
        'homeId': 5385975,
        'roomId': 5385975,
        'homeLock': false,
        'pairingLock': false,
        'typeId': 0,
        'moduleName': 'ESP10_SOCKET_06',
        'fwVersion': '1.25.0',
        'groupId': 0,
        'drvConf': [20, 1],
      },
    },
    modelConfig: {
      'method': 'getModelConfig',
      'env': 'pro',
      'result': {
        'ps': 1,
        'pwmFreq': 200,
        'pwmRange': [1, 100],
        'wcr': 20,
        'nowc': 2,
        'cctRange': [2700, 2700, 2700, 2700],
        'renderFactor': [255, 0, 255, 255, 0, 0, 0, 0, 0, 0],
      },
    },
    userConfig: {
      'method': 'getUserConfig',
      'env': 'pro',
      'result': {
        'fadeIn': 0,
        'fadeOut': 0,
        'dftDim': 10,
        'pwmRange': [0, 100],
        'po': false,
      },
    },
    powerResponse: {
      'method': 'getPower',
      'env': 'pro',
      'result': {
        'wh': 1065385, // 1065.385 watts in milliwatts
      },
    },
  );

  /// ESP01_SHTW_01 - Tunable white bulb (v1.18.0)
  static const tunableWhite = BulbConfig(
    moduleName: 'ESP01_SHTW_01',
    fwVersion: '1.18.0',
    systemConfig: {
      'method': 'getSystemConfig',
      'env': 'pro',
      'result': {
        'mac': 'a8bb5006033d',
        'homeId': 5385975,
        'roomId': 5385975,
        'homeLock': false,
        'pairingLock': false,
        'typeId': 2,
        'moduleName': 'ESP01_SHTW_01',
        'fwVersion': '1.18.0',
        'groupId': 0,
        'drvConf': [20, 1],
      },
    },
    modelConfig: {
      'method': 'getModelConfig',
      'env': 'pro',
      'result': {
        'ps': 2,
        'pwmFreq': 5000,
        'pwmRange': [1, 100],
        'wcr': 20,
        'nowc': 1,
        'cctRange': [2700, 2700, 6500, 6500],
        'renderFactor': [255, 0, 255, 255, 0, 0, 0, 0, 0, 0],
        'drvIface': 0,
      },
    },
    userConfig: {
      'method': 'getUserConfig',
      'env': 'pro',
      'result': {
        'fadeIn': 0,
        'fadeOut': 0,
        'dftDim': 10,
        'pwmRange': [0, 100],
        'whiteRange': [2700, 6500],
        'extRange': [2700, 6500],
        'po': false,
      },
    },
  );

  /// ESP01_SHDW_01 - Dimmable white bulb (v1.8.0)
  static const dimmableWhite = BulbConfig(
    moduleName: 'ESP01_SHDW_01',
    fwVersion: '1.8.0',
    systemConfig: {
      'method': 'getSystemConfig',
      'env': 'pro',
      'result': {
        'mac': 'a8bb5006033d',
        'homeId': 5385975,
        'roomId': 5385975,
        'homeLock': false,
        'pairingLock': false,
        'typeId': 3,
        'moduleName': 'ESP01_SHDW_01',
        'fwVersion': '1.8.0',
        'groupId': 0,
        'drvConf': [20, 1],
      },
    },
    modelConfig: {
      'method': 'getModelConfig',
      'env': 'pro',
      'result': {
        'ps': 1,
        'pwmFreq': 1000,
        'pwmRange': [5, 100],
        'wcr': 20,
        'nowc': 1,
        'cctRange': [2700, 2700, 2700, 2700],
        'renderFactor': [255, 0, 255, 255, 0, 0, 0, 0, 0, 0],
      },
    },
    userConfig: {
      'method': 'getUserConfig',
      'env': 'pro',
      'result': {
        'fadeIn': 0,
        'fadeOut': 0,
        'dftDim': 10,
        'pwmRange': [0, 100],
        'whiteRange': [2700],
        'po': false,
      },
    },
  );

  /// ESP03_FANDIMS_31 - Ceiling fan with light (v1.31.32)
  static const ceilingFan = BulbConfig(
    moduleName: 'ESP03_FANDIMS_31',
    fwVersion: '1.31.32',
    systemConfig: {
      'method': 'getSystemConfig',
      'env': 'pro',
      'result': {
        'mac': 'a8bb5006033d',
        'homeId': 5385975,
        'roomId': 5385975,
        'homeLock': false,
        'pairingLock': false,
        'typeId': 0,
        'moduleName': 'ESP03_FANDIMS_31',
        'fwVersion': '1.31.32',
        'groupId': 0,
        'drvConf': [20, 1],
      },
    },
    modelConfig: {
      'method': 'getModelConfig',
      'env': 'pro',
      'result': {
        'ps': 1,
        'pwmFreq': 200,
        'pwmRange': [0, 100],
        'wcr': 20,
        'nowc': 1,
        'cctRange': [2700, 2700, 2700, 2700],
        'renderFactor': [255, 0, 255, 255, 0, 0, 0, 0, 0, 0],
        'fanSpeed': 6,
        'wizc1': {
          'mode': [0, 0, 0, 0, 0, 0, 0]
        },
        'wizc2': {
          'mode': [0, 0, 0, 0, 0, 0, 0]
        },
      },
    },
    userConfig: {
      'method': 'getUserConfig',
      'env': 'pro',
      'result': {
        'fadeIn': 0,
        'fadeOut': 0,
        'dftDim': 10,
        'pwmRange': [0, 100],
        'whiteRange': [2700],
        'po': false,
      },
    },
  );
}

/// Fake bulb UDP server for integration testing
class FakeBulb {
  final BulbConfig config;
  late RawDatagramSocket _socket;
  late int _port;
  bool _running = false;

  // Current pilot state (getPilot response)
  final Map<String, dynamic> _pilotState = {
    'method': 'getPilot',
    'env': 'pro',
    'result': {
      'mac': 'a8bb5006033d',
      'rssi': -50,
      'state': false,
      'sceneId': 0,
      'temp': 3000,
      'dimming': 10,
    },
  };

  FakeBulb(this.config);

  /// Start the fake bulb server
  Future<int> start() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    _port = _socket.port;
    _running = true;

    _socket.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _socket.receive();
        if (datagram != null) {
          _handleRequest(datagram.data, datagram.address, datagram.port);
        }
      }
    });

    return _port;
  }

  /// Stop the fake bulb server
  void stop() {
    _running = false;
    _socket.close();
  }

  /// Get the port the server is listening on
  int get port => _port;

  /// Handle incoming UDP request
  void _handleRequest(List<int> data, InternetAddress address, int port) {
    try {
      final json = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      final method = json['method'] as String?;

      if (method == null) {
        _sendResponse({'error': {'code': -32600, 'message': 'Invalid Request'}},
            address, port);
        return;
      }

      switch (method) {
        case 'setPilot':
        case 'setState': // setState is functionally equivalent to setPilot
          _handleSetPilot(json, address, port);
          break;
        case 'getPilot':
          _handleGetPilot(address, port);
          break;
        case 'getSystemConfig':
          _handleGetSystemConfig(address, port);
          break;
        case 'getModelConfig':
          _handleGetModelConfig(address, port);
          break;
        case 'getUserConfig':
          _handleGetUserConfig(address, port);
          break;
        case 'getPower':
          _handleGetPower(address, port);
          break;
        case 'registration':
          _handleRegistration(address, port);
          break;
        case 'getDevInfo':
          _handleGetDevInfo(address, port);
          break;
        default:
          print('Unknown method: $method');
      }
    } on FormatException catch (e) {
      // Malformed JSON
      print('JSON decode error: $e');
      _sendResponse(
          {'error': {'code': -32700, 'message': 'Parse error'}}, address, port);
    } catch (e) {
      print('Error handling request: $e');
    }
  }

  /// Handle setPilot command
  void _handleSetPilot(
      Map<String, dynamic> json, InternetAddress address, int port) {
    final params = json['params'] as Map<String, dynamic>?;
    if (params != null) {
      // Update pilot state with new parameters
      final result = _pilotState['result'] as Map<String, dynamic>;
      params.forEach((key, value) {
        result[key] = value;
      });
    }

    _sendResponse({
      'method': 'setPilot',
      'env': 'pro',
      'result': {'success': true}
    }, address, port);
  }

  /// Handle getPilot command
  void _handleGetPilot(InternetAddress address, int port) {
    _sendResponse(_pilotState, address, port);
  }

  /// Handle getSystemConfig command
  void _handleGetSystemConfig(InternetAddress address, int port) {
    _sendResponse(config.systemConfig, address, port);
    // Simulate duplicate late response (like real bulbs sometimes do)
    Future.delayed(Duration(milliseconds: 50), () {
      if (_running) {
        _sendResponse(config.systemConfig, address, port);
      }
    });
  }

  /// Handle getModelConfig command
  void _handleGetModelConfig(InternetAddress address, int port) {
    _sendResponse(config.modelConfig, address, port);
  }

  /// Handle getUserConfig command
  void _handleGetUserConfig(InternetAddress address, int port) {
    _sendResponse(config.userConfig, address, port);
  }

  /// Handle getPower command (for sockets)
  void _handleGetPower(InternetAddress address, int port) {
    if (config.powerResponse != null) {
      _sendResponse(config.powerResponse!, address, port);
    } else {
      _sendResponse({
        'error': {'code': -32601, 'message': 'Method not found'}
      }, address, port);
    }
  }

  /// Handle registration command (for push updates)
  void _handleRegistration(InternetAddress address, int port) {
    _sendResponse({
      'method': 'registration',
      'env': 'pro',
      'result': {'mac': 'a8bb5006033d', 'success': true}
    }, address, port);
  }

  /// Handle getDevInfo command (for discovery)
  void _handleGetDevInfo(InternetAddress address, int port) {
    final result = Map<String, dynamic>.from(
        config.systemConfig['result'] as Map<String, dynamic>);
    _sendResponse({'method': 'getDevInfo', 'env': 'pro', 'result': result},
        address, port);
  }

  /// Send response to client
  void _sendResponse(
      Map<String, dynamic> response, InternetAddress address, int port) {
    final data = utf8.encode(jsonEncode(response));
    _socket.send(data, address, port);
  }

  /// Get current pilot state (for testing assertions)
  Map<String, dynamic> get currentState =>
      Map<String, dynamic>.from(_pilotState['result'] as Map<String, dynamic>);

  /// Reset pilot state to initial values
  void resetState() {
    final result = _pilotState['result'] as Map<String, dynamic>;
    result.clear();
    result.addAll({
      'mac': 'a8bb5006033d',
      'rssi': -50,
      'state': false,
      'sceneId': 0,
      'temp': 3000,
      'dimming': 10,
    });
  }
}

/// Helper function to start a fake bulb for testing
/// Returns the bulb instance and its port
Future<(FakeBulb, int)> startupBulb({
  BulbConfig config = BulbConfigs.rgbBulb,
}) async {
  final bulb = FakeBulb(config);
  final port = await bulb.start();
  return (bulb, port);
}
