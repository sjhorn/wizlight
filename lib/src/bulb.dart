// Dart port of wizlightcpp - https://github.com/srisham/wizlightcpp
// See LICENSE file for licensing details.

import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart';
import 'async_lock.dart';
import 'bulb_type.dart';
import 'exceptions.dart';
import 'pilot_builder.dart';
import 'pilot_parser.dart';
import 'push_manager.dart';
import 'scenes.dart';
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
  final AsyncLock _lock = AsyncLock();
  String _deviceIp = '';
  int _port = udpWizBroadcastBulbPort;

  // Cached state and configuration
  PilotParser? _state;
  String? _mac;
  BulbType? _bulbType;
  List<double>? _whiteRange;
  List<double>? _extendedWhiteRange;

  // Push update support
  PushCallback? _pushCallback;
  void Function()? _pushCancel;
  Timer? _registrationTimer;
  bool _pushRunning = false;

  // Power monitoring support
  bool? _powerMonitoring;

  // Fan control support
  int? _fanSpeedRange;

  /// Sets the target device IP address
  ///
  /// [ip] - The IPv4 address of the WiZ bulb
  void setDeviceIP(String ip) {
    _deviceIp = ip;
  }

  /// Sets the target device UDP port
  ///
  /// [port] - The UDP port number (default: 38899)
  void setPort(int port) {
    _port = port;
  }

  /// Gets the current device IP address
  ///
  /// Returns the currently set device IP, or empty string if not set.
  String getDeviceIp() {
    return _deviceIp;
  }

  /// Sends a UDP command with request serialization
  ///
  /// This wraps the UDP socket call with an async lock to ensure that
  /// requests are sent sequentially, preventing response mismatches.
  Future<(String, String)> _sendCommand(
    String msg,
    String targetIp,
    int port, {
    bool captureSenderIp = false,
  }) async {
    return await _lock.synchronized(() async {
      return await _socket.sendUDPCommand(
        msg,
        targetIp,
        port,
        captureSenderIp: captureSenderIp,
      );
    });
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
        await _sendCommand(msg, ip, _port, captureSenderIp: true);
    return _parseResponse(response, senderIp);
  }

  /// Gets the current status (pilot) of the bulb as JSON
  ///
  /// Returns JSON string with current state including brightness, color, temperature, etc.
  /// Returns empty string on error or timeout.
  ///
  /// **Tip**: Consider using `updateState()` instead for typed access to state properties
  /// via `PilotParser`.
  Future<String> getStatus() async {
    final request = {'method': 'getPilot'};
    final msg = jsonEncode(request);
    _log.fine('Wiz getStatus request $msg to Wiz');

    final (response, _) = await _sendCommand(msg, _deviceIp, _port);
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

    final (response, _) = await _sendCommand(msg, _deviceIp, _port);
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

    final (response, _) = await _sendCommand(msg, _deviceIp, _port);
    // Return raw response - WiZ WiFi config response has non-standard format
    return response;
  }

  /// Gets system configuration
  ///
  /// Returns map with system settings including MAC, module name, firmware version.
  /// Returns null on error or timeout.
  Future<Map<String, dynamic>?> getSystemConfig() async {
    try {
      final request = {'method': 'getSystemConfig'};
      final msg = jsonEncode(request);
      _log.fine('Wiz getSystemConfig request $msg to Wiz');

      final (response, _) = await _sendCommand(msg, _deviceIp, _port);
      if (response.isEmpty) return null;

      final data = jsonDecode(response) as Map<String, dynamic>;
      if (data.containsKey('error')) {
        _log.warning('getSystemConfig returned error: ${data['error']}');
        return null;
      }

      return data['result'] as Map<String, dynamic>?;
    } catch (e) {
      _log.warning('getSystemConfig failed: $e');
      return null;
    }
  }

  /// Gets user configuration
  ///
  /// Returns JSON with user preferences and settings.
  /// Returns empty string on error or timeout.
  Future<String> getUserConfig() async {
    final request = {'method': 'getUserConfig'};
    final msg = jsonEncode(request);
    _log.fine('Wiz getUserConfig request $msg to Wiz');

    final (response, _) = await _sendCommand(msg, _deviceIp, _port);
    return _parseResponse(response);
  }

  /// Sets the light on or off state
  ///
  /// **Note**: Despite the name, this method sets the state rather than toggling it.
  /// Consider using the modern API instead:
  /// - For turning on: `turnOn([PilotBuilder])`
  /// - For turning off: `turnOff()`
  /// - For state-aware toggling: `lightSwitch()`
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

    final (response, _) = await _sendCommand(msg, _deviceIp, _port);
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

    final (response, _) = await _sendCommand(msg, _deviceIp, _port);
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

    final (response, _) = await _sendCommand(msg, _deviceIp, _port);
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

    final (response, _) = await _sendCommand(msg, _deviceIp, _port);
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

    final (response, _) = await _sendCommand(msg, _deviceIp, _port);
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

    final (response, _) = await _sendCommand(msg, _deviceIp, _port);
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

    final (response, _) = await _sendCommand(msg, _deviceIp, _port);
    return _parseResponse(response);
  }

  // ========== Enhanced Control Methods (pywizlight-compatible API) ==========

  /// Turns the light on with optional parameters
  ///
  /// Uses setPilot method (preferred over setState for pywizlight compatibility).
  /// Accepts an optional [PilotBuilder] to set color, brightness, scene, etc.
  ///
  /// Example:
  /// ```dart
  /// // Turn on with default settings
  /// await bulb.turnOn();
  ///
  /// // Turn on with specific brightness and color
  /// final builder = PilotBuilder()
  ///   ..brightness = 200
  ///   ..colorTemp = 2700;
  /// await bulb.turnOn(builder);
  /// ```
  Future<void> turnOn([PilotBuilder? pilot]) async {
    final builder = pilot ?? PilotBuilder();
    final msg = jsonEncode(builder.setPilotMessage(state: true));
    _log.fine('turnOn request: $msg');

    final (response, _) = await _sendCommand(msg, _deviceIp, _port);
    _updateStateFromResponse(response);
  }

  /// Turns the light off
  ///
  /// Uses setPilot method with state=false.
  Future<void> turnOff() async {
    final msg = jsonEncode({
      'method': 'setPilot',
      'params': {'state': false}
    });
    _log.fine('turnOff request: $msg');

    final (response, _) = await _sendCommand(msg, _deviceIp, _port);
    _updateStateFromResponse(response);
  }

  /// Toggles the light on or off based on current state
  ///
  /// First queries the current state, then toggles it.
  /// This is more reliable than blind toggle as it checks actual bulb state.
  Future<void> lightSwitch() async {
    await updateState();
    if (_state?.state == true) {
      await turnOff();
    } else {
      await turnOn();
    }
  }

  /// Sets the bulb state without forcing it on or off
  ///
  /// This allows changing color, brightness, etc. without affecting the on/off state.
  /// Uses setState method which preserves the current power state.
  Future<void> setState(PilotBuilder pilot) async {
    final currentState = _state?.state;
    final msg = jsonEncode(pilot.setStateMessage(state: currentState));
    _log.fine('setState request: $msg');

    final (response, _) = await _sendCommand(msg, _deviceIp, _port);
    _updateStateFromResponse(response);
  }

  /// Updates and returns the current bulb state
  ///
  /// Queries the bulb with getPilot and returns a [PilotParser] with
  /// the current state. The state is also cached internally.
  ///
  /// Returns null if the request fails or times out.
  Future<PilotParser?> updateState() async {
    try {
      final msg = jsonEncode({'method': 'getPilot', 'params': {}});
      _log.fine('updateState request: $msg');

      final (response, _) = await _sendCommand(msg, _deviceIp, _port);
      final data = jsonDecode(response) as Map<String, dynamic>;

      if (data.containsKey('result')) {
        _state = PilotParser(data['result'] as Map<String, dynamic>);
        return _state;
      }
    } catch (e) {
      _log.warning('updateState failed: $e');
    }
    return null;
  }

  /// Gets the current cached state
  ///
  /// Returns the last known state from [updateState] or control commands.
  /// Returns null if state has never been queried.
  PilotParser? get state => _state;

  /// Gets the MAC address of the bulb
  ///
  /// Queries system config if not already cached.
  /// Returns null if unable to retrieve MAC address.
  Future<String?> getMac() async {
    if (_mac != null) return _mac;

    try {
      final data = await getSystemConfig();
      if (data != null) {
        _mac = data['mac'] as String?;
      }
    } catch (e) {
      _log.warning('getMac failed: $e');
    }
    return _mac;
  }

  /// Gets the model configuration (FW >= 1.22)
  ///
  /// Returns model capabilities and configuration for newer firmware.
  /// Throws [WizLightMethodNotFound] if not supported by this bulb/firmware.
  Future<Map<String, dynamic>?> getModelConfig() async {
    try {
      final msg = jsonEncode({'method': 'getModelConfig', 'params': {}});
      _log.fine('getModelConfig request: $msg');

      final (response, _) = await _sendCommand(msg, _deviceIp, _port);
      final data = jsonDecode(response) as Map<String, dynamic>;

      if (data.containsKey('error')) {
        final error = data['error'] as Map<String, dynamic>;
        if (error['code'] == -32601) {
          throw const WizLightMethodNotFound(
              'getModelConfig not supported (older firmware)');
        }
      }

      if (data.containsKey('result')) {
        return data['result'] as Map<String, dynamic>;
      }
    } catch (e) {
      _log.warning('getModelConfig failed: $e');
      rethrow;
    }
    return null;
  }

  /// Resets the bulb to factory defaults
  ///
  /// WARNING: This will erase all settings and require re-pairing the bulb.
  Future<void> reset() async {
    final msg = jsonEncode({'method': 'reset', 'params': {}});
    _log.fine('reset request: $msg');
    await _sendCommand(msg, _deviceIp, _port);
  }

  /// Gets the bulb type with feature detection
  ///
  /// Queries system and user configuration to determine bulb capabilities.
  /// Returns a [BulbType] with feature flags, kelvin range, etc.
  Future<BulbType?> getBulbType() async {
    if (_bulbType != null) return _bulbType;

    try {
      // Get system config for module name
      final sysData = await getSystemConfig();
      if (sysData == null) return null;

      final moduleName = sysData['moduleName'] as String?;
      final fwVersion = sysData['fwVersion'] as String?;
      final typeId = sysData['typeId'] as int?;

      // Get white range
      await getWhiteRange();
      await getExtendedWhiteRange();

      // Get white channels and ratio from drvConf (for older FW < 1.22)
      int? whiteToColorRatio;
      int? whiteChannels;
      if (sysData.containsKey('drvConf')) {
        final drvConf = sysData['drvConf'] as List;
        if (drvConf.length >= 2) {
          whiteToColorRatio = (drvConf[0] as num).toInt();
          whiteChannels = (drvConf[1] as num).toInt();
        }
      }

      // Try to get model config (FW >= 1.22) and override drvConf values
      Map<String, dynamic>? modelConfig;
      try {
        modelConfig = await getModelConfig();
      } catch (e) {
        // Older firmware, use user config
        final userConfigResponse = await getUserConfig();
        final userData = jsonDecode(userConfigResponse) as Map<String, dynamic>;
        modelConfig = userData['bulb_response'] as Map<String, dynamic>?;
      }

      // Override with model config values if available
      whiteChannels = modelConfig?['nowc'] as int? ?? whiteChannels;
      whiteToColorRatio = modelConfig?['wcr'] as int? ?? whiteToColorRatio;

      _bulbType = BulbType.fromData(
        moduleName: moduleName,
        kelvinList: _extendedWhiteRange ?? _whiteRange,
        fwVersion: fwVersion,
        whiteChannels: whiteChannels,
        whiteToColorRatio: whiteToColorRatio,
        fanSpeedRange: null,
        typeId: typeId,
      );

      return _bulbType;
    } catch (e) {
      _log.warning('getBulbType failed: $e');
      return null;
    }
  }

  /// Gets the white color temperature range
  ///
  /// Returns the kelvin range supported by the bulb for white LEDs.
  Future<List<double>?> getWhiteRange() async {
    if (_whiteRange != null) return _whiteRange;

    try {
      final response = await getUserConfig();
      final data = jsonDecode(response) as Map<String, dynamic>;
      if (data.containsKey('bulb_response')) {
        final result = data['bulb_response'] as Map<String, dynamic>;
        if (result.containsKey('whiteRange')) {
          final range = result['whiteRange'] as List;
          _whiteRange = range.map((e) => (e as num).toDouble()).toList();
        }
      }
    } catch (e) {
      _log.warning('getWhiteRange failed: $e');
    }
    return _whiteRange;
  }

  /// Gets the extended white color temperature range
  ///
  /// Returns the extended kelvin range for RGB bulbs (FW >= 1.22).
  /// Falls back to checking user config for older firmware.
  Future<List<double>?> getExtendedWhiteRange() async {
    if (_extendedWhiteRange != null) return _extendedWhiteRange;

    try {
      // Try model config first (FW >= 1.22)
      try {
        final modelConfig = await getModelConfig();
        if (modelConfig != null) {
          if (modelConfig.containsKey('extRange')) {
            final range = modelConfig['extRange'] as List;
            _extendedWhiteRange =
                range.map((e) => (e as num).toDouble()).toList();
            return _extendedWhiteRange;
          }
          if (modelConfig.containsKey('cctRange')) {
            final range = modelConfig['cctRange'] as List;
            _extendedWhiteRange =
                range.map((e) => (e as num).toDouble()).toList();
            return _extendedWhiteRange;
          }
        }
      } catch (e) {
        // Fall through to user config
      }

      // Fall back to user config
      final response = await getUserConfig();
      final data = jsonDecode(response) as Map<String, dynamic>;
      if (data.containsKey('bulb_response')) {
        final result = data['bulb_response'] as Map<String, dynamic>;
        if (result.containsKey('extRange')) {
          final range = result['extRange'] as List;
          _extendedWhiteRange =
              range.map((e) => (e as num).toDouble()).toList();
        }
      }
    } catch (e) {
      _log.warning('getExtendedWhiteRange failed: $e');
    }
    return _extendedWhiteRange;
  }

  /// Gets the list of scenes supported by this bulb type
  ///
  /// Different bulb types support different scenes. This returns the
  /// scene names that are compatible with the detected bulb type.
  Future<List<String>> getSupportedScenes() async {
    final bulbType = await getBulbType();
    if (bulbType == null) {
      // If we can't detect type, return all RGB scenes as fallback
      return scenes.values.toList();
    }

    // Return scenes based on bulb class
    switch (bulbType.bulbType) {
      case BulbClass.rgb:
        return scenes.values.toList();
      case BulbClass.tw:
        return twScenes.map((id) => scenes[id]!).toList();
      case BulbClass.dw:
        return dwScenes.map((id) => scenes[id]!).toList();
      default:
        return [];
    }
  }

  /// Sets the ratio between up and down light (0-100)
  ///
  /// Used for lights with dual-direction capability.
  /// [ratio] must be between 0 and 100.
  Future<void> setRatio(int ratio) async {
    if (ratio < 0 || ratio > 100) {
      throw ArgumentError('Ratio must be between 0 and 100, got $ratio');
    }

    final msg = jsonEncode({
      'method': 'setPilot',
      'params': {'ratio': ratio}
    });
    _log.fine('setRatio request: $msg');

    final (response, _) = await _sendCommand(msg, _deviceIp, _port);
    _updateStateFromResponse(response);
  }

  /// Sets color using RGBW (4 channels: red, green, blue, warm white)
  ///
  /// All values must be in range 0-255.
  Future<void> setRgbw(int r, int g, int b, int w) async {
    final builder = PilotBuilder();
    builder.setRgbw(r, g, b, w);
    await turnOn(builder);
  }

  /// Sets color using RGBWW (5 channels: red, green, blue, cold white, warm white)
  ///
  /// All values must be in range 0-255.
  Future<void> setRgbww(int r, int g, int b, int c, int w) async {
    final builder = PilotBuilder();
    builder.setRgbww(r, g, b, c, w);
    await turnOn(builder);
  }

  /// Sets warm white LED value (0-255)
  Future<void> setWarmWhite(int value) async {
    final builder = PilotBuilder()..warmWhite = value;
    await turnOn(builder);
  }

  /// Sets cold white LED value (0-255)
  Future<void> setColdWhite(int value) async {
    final builder = PilotBuilder()..coldWhite = value;
    await turnOn(builder);
  }

  // ========== Power Monitoring ==========

  /// Gets the current power consumption in watts
  ///
  /// Available on smart plugs and some bulbs with power monitoring.
  /// Returns null if power monitoring is not supported.
  ///
  /// If push updates are active, returns cached value from last syncPilot.
  /// Otherwise queries the bulb with getPower method.
  Future<double?> getPower() async {
    // If we have recent push data, use it
    if (_pushRunning && _state != null) {
      return _state!.power;
    }

    // Check if power monitoring is supported
    if (_powerMonitoring == false) {
      return null;
    }

    try {
      final msg = jsonEncode({'method': 'getPower'});
      _log.fine('getPower request: $msg');

      final (response, _) = await _sendCommand(msg, _deviceIp, _port);
      final data = jsonDecode(response) as Map<String, dynamic>;

      if (data.containsKey('error')) {
        final error = data['error'] as Map<String, dynamic>;
        if (error['code'] == -32601) {
          // Method not found - power monitoring not supported
          _powerMonitoring = false;
          return null;
        }
      }

      if (data.containsKey('result')) {
        final result = data['result'] as Map<String, dynamic>;
        // WiZ protocol uses 'wh' field for power in milliwatts
        final milliWatts = result['wh'] as int?;
        _powerMonitoring = true;
        return milliWatts != null ? milliWatts / 1000.0 : null;
      }
    } catch (e) {
      _log.warning('getPower failed: $e');
    }

    return null;
  }

  // ========== Fan Control ==========

  /// Turns the fan on
  ///
  /// For WiZ ceiling fan controllers.
  /// [mode] - 1 for normal, 2 for breeze mode
  /// [speed] - Fan speed (1 to fanSpeedRange, typically 1-6)
  Future<void> fanTurnOn({int? mode, int? speed}) async {
    await fanSetState(state: 1, mode: mode, speed: speed);
  }

  /// Turns the fan off
  ///
  /// For WiZ ceiling fan controllers.
  Future<void> fanTurnOff() async {
    await fanSetState(state: 0);
  }

  /// Sets the fan state with full control
  ///
  /// For WiZ ceiling fan controllers.
  /// [state] - 0=off, 1=on
  /// [mode] - 1=normal, 2=breeze
  /// [speed] - Fan speed (1 to fanSpeedRange)
  /// [reverse] - 0=normal/summer, 1=reverse/winter
  Future<void> fanSetState({
    int? state,
    int? mode,
    int? speed,
    int? reverse,
  }) async {
    final params = <String, dynamic>{};

    if (state != null) {
      if (state < 0 || state > 1) {
        throw ArgumentError('Fan state must be 0 or 1, got $state');
      }
      params['fanState'] = state;
    }

    if (mode != null) {
      if (mode < 1 || mode > 2) {
        throw ArgumentError('Fan mode must be 1 or 2, got $mode');
      }
      params['fanMode'] = mode;
    }

    if (speed != null) {
      final maxSpeed = _fanSpeedRange ?? 6;
      if (speed < 1 || speed > maxSpeed) {
        throw ArgumentError(
            'Fan speed must be between 1 and $maxSpeed, got $speed');
      }
      params['fanSpeed'] = speed;
    }

    if (reverse != null) {
      if (reverse < 0 || reverse > 1) {
        throw ArgumentError('Fan reverse must be 0 or 1, got $reverse');
      }
      params['fanRevrs'] = reverse;
    }

    final msg = jsonEncode({'method': 'setPilot', 'params': params});
    _log.fine('fanSetState request: $msg');

    final (response, _) = await _sendCommand(msg, _deviceIp, _port);
    _updateStateFromResponse(response);
  }

  /// Toggles the fan on or off based on current state
  ///
  /// First queries the current state, then toggles it.
  /// For WiZ ceiling fan controllers.
  Future<void> fanSwitch() async {
    await updateState();
    if (_state?.fanState == 1) {
      await fanTurnOff();
    } else {
      await fanTurnOn();
    }
  }

  /// Gets the fan speed range
  ///
  /// Returns the maximum fan speed setting for this device.
  /// Typically 6 for most ceiling fans.
  Future<int?> getFanSpeedRange() async {
    if (_fanSpeedRange != null) return _fanSpeedRange;

    try {
      // Try model config first (FW >= 1.22)
      try {
        final modelConfig = await getModelConfig();
        if (modelConfig != null && modelConfig.containsKey('fanSpeed')) {
          _fanSpeedRange = modelConfig['fanSpeed'] as int?;
          return _fanSpeedRange;
        }
      } catch (e) {
        // Fall through to user config
      }

      // Fall back to user config
      final response = await getUserConfig();
      final data = jsonDecode(response) as Map<String, dynamic>;
      if (data.containsKey('bulb_response')) {
        final result = data['bulb_response'] as Map<String, dynamic>;
        if (result.containsKey('fanSpeed')) {
          _fanSpeedRange = result['fanSpeed'] as int?;
        }
      }
    } catch (e) {
      _log.warning('getFanSpeedRange failed: $e');
    }

    return _fanSpeedRange;
  }

  // ========== Push Updates (Real-time State Changes) ==========

  /// Starts receiving push updates from the bulb
  ///
  /// Push updates provide real-time notifications when the bulb state changes
  /// (via physical switch, app, or other control). This avoids constant polling.
  ///
  /// The bulb must be registered to send updates, and registration is renewed
  /// every 20 seconds automatically.
  ///
  /// [callback] - Called when state changes are received from the bulb
  ///
  /// Returns true if push updates started successfully, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// await bulb.startPush((state, ip) {
  ///   print('Bulb state changed: ${state.state ? "ON" : "OFF"}');
  ///   print('Brightness: ${state.brightness}');
  /// });
  /// ```
  Future<bool> startPush(PushCallback callback) async {
    // Ensure we have the MAC address
    final mac = await getMac();
    if (mac == null) {
      _log.warning('Cannot start push: MAC address not available');
      return false;
    }

    _log.info('Enabling push updates for MAC: $mac');
    _pushCallback = callback;

    // Register with push manager
    final pushManager = PushManager();
    _pushCancel = pushManager.register(mac, _onPush);

    // Start the push manager if not already running
    if (!await pushManager.start(_deviceIp)) {
      _log.warning('Failed to start push manager');
      return false;
    }

    // Start sending registration keepalives
    _pushRunning = true;
    _register();

    return true;
  }

  /// Stops receiving push updates
  Future<void> stopPush() async {
    _pushRunning = false;
    _registrationTimer?.cancel();
    _registrationTimer = null;
    _pushCancel?.call();
    _pushCancel = null;
    _pushCallback = null;
    _log.info('Push updates stopped');
  }

  /// Sets the discovery callback for new bulbs
  ///
  /// This callback is triggered when the push manager receives a firstBeat
  /// message from a newly discovered bulb.
  void setDiscoveryCallback(DiscoveryCallback callback) {
    PushManager().setDiscoveryCallback(callback);
  }

  /// Sends registration to bulb and schedules next registration
  void _register() {
    if (!_pushRunning) return;

    // Send registration message
    _sendRegistration();

    // Schedule next registration in 20 seconds
    _registrationTimer?.cancel();
    _registrationTimer = Timer(const Duration(seconds: 20), _register);
  }

  /// Sends the registration message to the bulb
  Future<void> _sendRegistration() async {
    final pushManager = PushManager();
    final registerMsg = pushManager.registerMsg;

    if (registerMsg == null) {
      _log.warning('No registration message available');
      return;
    }

    try {
      final msg = jsonEncode(registerMsg);
      _log.fine('Sending registration to $_deviceIp');
      await _sendCommand(msg, _deviceIp, _port);
    } catch (e) {
      _log.fine('Registration for push updates failed: $e');
      // Non-fatal, will retry in 20 seconds
    }
  }

  /// Handles incoming syncPilot messages
  void _onPush(PilotParser state, String ip) {
    _log.fine('Received syncPilot from $ip');

    // Update cached state
    _state = state;

    // Call user callback
    _pushCallback?.call(state, ip);
  }

  // ========== Internal Helper Methods ==========

  /// Updates internal state from a response if it contains pilot data
  void _updateStateFromResponse(String response) {
    try {
      final data = jsonDecode(response) as Map<String, dynamic>;
      if (data.containsKey('result')) {
        final result = data['result'] as Map<String, dynamic>;
        // Some responses include state info
        if (result.containsKey('state') || result.isNotEmpty) {
          _state = PilotParser(result);
        }
      }
    } catch (e) {
      // Ignore parse errors for state updates
      _log.fine('Could not update state from response: $e');
    }
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
  ///
  /// Note: In the current implementation, sockets are created and closed per
  /// request, so this method is a no-op kept for backward compatibility.
  void close() {
    // No-op: sockets are now created and closed per request
  }
}
