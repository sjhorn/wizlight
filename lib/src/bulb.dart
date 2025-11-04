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
 * @file bulb.dart
 *
 ***************************************************************************/

import 'dart:convert';
import 'package:logging/logging.dart';
import 'udp_socket.dart';

/// Standard WiZ protocol UDP port
const int udpWizBroadcastBulbPort = 38899;

/// Error message for invalid requests
const String errorInvalidRequest = 'Invalid_Request';

/// Represents a WiZ smart light bulb
///
/// Provides methods to control and query WiZ smart bulbs over UDP/JSON protocol.
/// Supports device discovery, state control, color control, brightness, scenes,
/// and device information queries.
class Bulb {
  static final Logger _log = Logger('Bulb');

  final UDPSocket _socket = UDPSocket();
  String _deviceIp = '';
  final int _port = udpWizBroadcastBulbPort;

  /// Sets the target device IP address
  ///
  /// [ip] - The IPv4 address of the WiZ bulb
  void setDeviceIP(String ip) {
    _deviceIp = ip;
  }

  /// Gets the current device IP address
  ///
  /// Returns the currently set device IP, or empty string if not set.
  String getDeviceIp() {
    return _deviceIp;
  }

  /// Discovers WiZ bulbs on the network
  ///
  /// Sends a broadcast discovery request and returns device information
  /// along with the responding device's IP address.
  ///
  /// [ip] - The broadcast IP address (e.g., 192.168.1.255)
  ///
  /// Returns JSON string with device info and IP, or empty on error.
  Future<String> discover(String ip) async {
    final request = {'method': 'getDevInfo'};
    final msg = jsonEncode(request);
    _log.fine('Wiz discover request $msg to Wiz');

    final (response, senderIp) =
        await _socket.sendUDPCommand(msg, ip, _port, captureSenderIp: true);
    return _parseResponse(response, senderIp);
  }

  /// Gets the current status (pilot) of the bulb
  ///
  /// Returns JSON with current state including brightness, color, temperature, etc.
  /// Returns empty string on error or timeout.
  Future<String> getStatus() async {
    final request = {'method': 'getPilot'};
    final msg = jsonEncode(request);
    _log.fine('Wiz getStatus request $msg to Wiz');

    final (response, _) = await _socket.sendUDPCommand(msg, _deviceIp, _port);
    return _parseResponse(response);
  }

  /// Gets device information
  ///
  /// Returns JSON with device metadata (model, MAC address, firmware version, etc.)
  /// Returns empty string on error or timeout.
  Future<String> getDeviceInfo() async {
    final request = {'method': 'getDevInfo'};
    final msg = jsonEncode(request);
    _log.fine('Wiz getDeviceInfo request $msg to Wiz');

    final (response, _) = await _socket.sendUDPCommand(msg, _deviceIp, _port);
    return _parseResponse(response);
  }

  /// Gets WiFi configuration
  ///
  /// Returns raw JSON response with WiFi settings.
  /// Note: Response format may not follow standard structure.
  Future<String> getWifiConfig() async {
    final request = {'method': 'getWifiConfig'};
    final msg = jsonEncode(request);
    _log.fine('Wiz getWifiConfig request $msg to Wiz');

    final (response, _) = await _socket.sendUDPCommand(msg, _deviceIp, _port);
    // Return raw response - WiZ WiFi config response has non-standard format
    return response;
  }

  /// Gets system configuration
  ///
  /// Returns JSON with system settings.
  /// Returns empty string on error or timeout.
  Future<String> getSystemConfig() async {
    final request = {'method': 'getSystemConfig'};
    final msg = jsonEncode(request);
    _log.fine('Wiz getSystemConfig request $msg to Wiz');

    final (response, _) = await _socket.sendUDPCommand(msg, _deviceIp, _port);
    return _parseResponse(response);
  }

  /// Gets user configuration
  ///
  /// Returns JSON with user preferences and settings.
  /// Returns empty string on error or timeout.
  Future<String> getUserConfig() async {
    final request = {'method': 'getUserConfig'};
    final msg = jsonEncode(request);
    _log.fine('Wiz getUserConfig request $msg to Wiz');

    final (response, _) = await _socket.sendUDPCommand(msg, _deviceIp, _port);
    return _parseResponse(response);
  }

  /// Toggles the light on or off
  ///
  /// [state] - true to turn on, false to turn off
  ///
  /// Returns JSON response with result, or empty string on error.
  Future<String> toggleLight(bool state) async {
    final request = {
      'id': 1,
      'method': 'setState',
      'params': {'state': state}
    };
    final msg = jsonEncode(request);
    print('Turning light ${state ? "ON" : "OFF"}');
    _log.fine('Wiz toggleLight request $msg to Wiz');

    final (response, _) = await _socket.sendUDPCommand(msg, _deviceIp, _port);
    return _parseResponse(response);
  }

  /// Reboots the bulb
  ///
  /// Sends a reboot command to the device.
  /// Returns JSON response with result, or empty string on error.
  Future<String> reboot() async {
    final request = {'method': 'reboot'};
    final msg = jsonEncode(request);
    print('Rebooting...');
    _log.fine('Wiz reboot request $msg to Wiz');

    final (response, _) = await _socket.sendUDPCommand(msg, _deviceIp, _port);
    return _parseResponse(response);
  }

  /// Sets the brightness level
  ///
  /// [brightness] - Brightness level from 0 to 100 (percent)
  ///
  /// Returns JSON response with result, or "Invalid_Request" if out of range.
  Future<String> setBrightness(int brightness) async {
    if (brightness < 0 || brightness > 100) {
      return errorInvalidRequest;
    }

    final request = {
      'id': 1,
      'method': 'setPilot',
      'params': {'dimming': brightness}
    };
    final msg = jsonEncode(request);
    _log.fine('Wiz setBrightness request $msg to Wiz');

    final (response, _) = await _socket.sendUDPCommand(msg, _deviceIp, _port);
    return _parseResponse(response);
  }

  /// Sets RGB color
  ///
  /// [r] - Red value (0-255)
  /// [g] - Green value (0-255)
  /// [b] - Blue value (0-255)
  ///
  /// Returns JSON response with result, or "Invalid_Request" if any value out of range.
  Future<String> setRGBColor(int r, int g, int b) async {
    if (r > 255 || g > 255 || b > 255) {
      return errorInvalidRequest;
    }

    final request = {
      'id': 1,
      'method': 'setPilot',
      'params': {'r': r, 'g': g, 'b': b}
    };
    final msg = jsonEncode(request);
    _log.fine('Wiz setRGBColor request $msg to Wiz');

    final (response, _) = await _socket.sendUDPCommand(msg, _deviceIp, _port);
    return _parseResponse(response);
  }

  /// Sets animation speed
  ///
  /// [speed] - Speed value from 0 to 100 (percent)
  ///
  /// Returns JSON response with result, or "Invalid_Request" if out of range.
  Future<String> setSpeed(int speed) async {
    if (speed < 0 || speed > 100) {
      return errorInvalidRequest;
    }

    final request = {
      'id': 1,
      'method': 'setPilot',
      'params': {'speed': speed}
    };
    final msg = jsonEncode(request);
    _log.fine('Wiz setSpeed request $msg to Wiz');

    final (response, _) = await _socket.sendUDPCommand(msg, _deviceIp, _port);
    return _parseResponse(response);
  }

  /// Sets color temperature
  ///
  /// [temp] - Color temperature in Kelvin (1000-8000)
  ///
  /// Returns JSON response with result, or "Invalid_Request" if out of range.
  Future<String> setColorTemp(int temp) async {
    if (temp < 1000 || temp > 8000) {
      return errorInvalidRequest;
    }

    final request = {
      'id': 1,
      'method': 'setPilot',
      'params': {'temp': temp}
    };
    final msg = jsonEncode(request);
    _log.fine('Wiz setColorTemp request $msg to Wiz');

    final (response, _) = await _socket.sendUDPCommand(msg, _deviceIp, _port);
    return _parseResponse(response);
  }

  /// Sets a preset scene
  ///
  /// [scene] - Scene ID from 1 to 32 (see WiZ documentation for scene list)
  ///
  /// Supported scenes include: Ocean, Romance, Sunset, Party, Fireplace, Cozy,
  /// Forest, Pastel Colors, Wake up, Bedtime, and many more.
  ///
  /// Returns JSON response with result, or "Invalid_Request" if scene ID invalid.
  Future<String> setScene(int scene) async {
    if (scene < 1 || scene > 32) {
      return errorInvalidRequest;
    }

    final request = {
      'id': 1,
      'method': 'setPilot',
      'params': {'sceneId': scene}
    };
    final msg = jsonEncode(request);
    _log.fine('Wiz setScene request $msg to Wiz');

    final (response, _) = await _socket.sendUDPCommand(msg, _deviceIp, _port);
    return _parseResponse(response);
  }

  /// Parses the bulb response
  ///
  /// Extracts the "result" object from the response, removes protocol metadata,
  /// and wraps it in a "bulb_response" object for consistent output format.
  ///
  /// [jsonStr] - The raw JSON response string
  /// [additionalParams] - Optional IP address to include in response (for discovery)
  ///
  /// Returns formatted JSON string with proper indentation, or empty on error.
  String _parseResponse(String jsonStr, [String additionalParams = '']) {
    if (jsonStr.isEmpty) {
      return jsonStr;
    }

    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (!data.containsKey('result')) {
        _log.severe('JSON error. result field not found');
        return '';
      }

      final result = data['result'] as Map<String, dynamic>;

      // Create a copy and remove protocol metadata
      final cleanResult = Map<String, dynamic>.from(result);
      cleanResult.remove('method');
      cleanResult.remove('id');
      cleanResult.remove('env');

      // Add IP if provided (for discovery)
      if (additionalParams.isNotEmpty) {
        cleanResult['ip'] = additionalParams;
      }

      // Wrap in bulb_response
      final output = {'bulb_response': cleanResult};
      final formattedJson =
          const JsonEncoder.withIndent('    ').convert(output);
      _log.fine(formattedJson);
      return formattedJson;
    } catch (e) {
      _log.severe('JSON parsing error: $e');
      return '';
    }
  }

  /// Closes the UDP socket
  void close() {
    _socket.close();
  }
}
