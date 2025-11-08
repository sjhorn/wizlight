// Dart port of pywizlight push_manager
// See LICENSE file for licensing details.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:logging/logging.dart';

import 'pilot_parser.dart';

/// Port for responding to bulbs
const int respondPort = 38899;

/// Port for listening to push updates from bulbs (default: 38900)
/// Can be overridden in tests by setting PushManager.testListenPort to 0 for any available port
int listenPort = 38900;

/// Callback type for push state updates
typedef PushCallback = void Function(PilotParser state, String ip);

/// Callback type for bulb discovery
typedef DiscoveryCallback = void Function(String ip, String? mac);

/// Manages push updates from WiZ bulbs
///
/// The PushManager is a singleton that listens for syncPilot messages
/// from bulbs on port 38900. Bulbs must be registered to receive updates,
/// and registration must be renewed every 20 seconds.
///
/// This enables real-time state change notifications without polling.
class PushManager {
  static final Logger _log = Logger('PushManager');
  static PushManager? _instance;

  /// Test-only: Override the listen port (set to 0 for any available port)
  /// Must be set before the PushManager singleton is created
  static int? testListenPort;

  /// Test-only: Override the source IP (useful for testing with localhost)
  /// Must be set before calling start()
  static String? testSourceIp;

  /// Test-only: Reset the singleton instance (useful for testing)
  static void resetForTesting() {
    _instance?._subscription?.cancel();
    _instance?._socket?.close();
    _instance = null;
    testListenPort = null;
    testSourceIp = null;
  }

  /// Gets the singleton instance
  factory PushManager() {
    _instance ??= PushManager._internal();
    return _instance!;
  }

  PushManager._internal();

  RawDatagramSocket? _socket;
  StreamSubscription<RawSocketEvent>? _subscription;
  bool _pushRunning = false;
  String? _failReason;
  Map<String, dynamic>? _registerMsg;

  /// Subscriptions keyed by MAC address
  final Map<String, PushCallback> _subscriptions = {};

  /// Discovery callback for new bulbs
  DiscoveryCallback? _discoveryCallback;

  /// Lock for start/stop operations
  final _lock = Completer<void>()..complete();

  /// Whether push updates are currently running
  bool get isRunning => _pushRunning;

  /// Reason for failure to start push updates
  String? get failReason => _failReason;

  /// Diagnostics information
  Map<String, dynamic> get diagnostics => {
        'running': _pushRunning,
        'failReason': _failReason,
        'subscriptions': _subscriptions.length,
      };

  /// Registration message sent to bulbs
  Map<String, dynamic>? get registerMsg => _registerMsg;

  /// Sets the discovery callback
  ///
  /// Called when a bulb sends a firstBeat message (new device discovered).
  void setDiscoveryCallback(DiscoveryCallback? callback) {
    _discoveryCallback = callback;
  }

  /// Starts listening for push updates
  ///
  /// Creates a UDP listener on port 38900 to receive syncPilot messages.
  /// Returns true if successful, false if port is in use or other error.
  ///
  /// [targetIp] is used to determine the source IP to include in registration.
  Future<bool> start(String targetIp) async {
    // Wait for any previous operation to complete
    await _lock.future;
    final completer = Completer<void>();
    _lock.future.then((_) => completer.future);

    try {
      if (_pushRunning) {
        return true;
      }

      // Determine source IP that can reach the target
      final sourceIp = await _getSourceIp(targetIp);
      if (sourceIp == null) {
        _failReason = 'Could not determine source IP';
        _log.warning('Could not determine source IP, falling back to polling');
        return false;
      }

      // Try to bind to the listen port
      try {
        final port = testListenPort ?? listenPort;
        _socket =
            await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
        final actualPort = _socket!.port;
        _log.info('Push manager listening on port $actualPort');
      } catch (e) {
        final port = testListenPort ?? listenPort;
        _failReason = 'Port $port is in use: $e';
        _log.warning(
            'Port $port is in use: $e, cannot listen for push updates, falling back to polling');
        return false;
      }

      // Create registration message
      _registerMsg = {
        'params': {
          'phoneIp': sourceIp,
          'register': true,
          'phoneMac': _generateMac(),
        },
        'method': 'registration',
      };

      // Start listening for messages
      _subscription = _socket!.listen(_onSocketEvent);
      _pushRunning = true;
      _failReason = null;

      _log.info('Push manager started successfully');
      return true;
    } finally {
      completer.complete();
    }
  }

  /// Stops push updates if there are no subscriptions
  Future<void> stopIfNoSubs() async {
    await _lock.future;
    final completer = Completer<void>();
    _lock.future.then((_) => completer.future);

    try {
      if (!_pushRunning || _subscriptions.isNotEmpty) {
        return;
      }

      _pushRunning = false;
      _discoveryCallback = null;
      await _subscription?.cancel();
      _subscription = null;
      _socket?.close();
      _socket = null;
      _log.info('Push manager stopped');
    } finally {
      completer.complete();
    }
  }

  /// Registers a callback for a bulb's MAC address
  ///
  /// Returns a function that can be called to cancel the subscription.
  void Function() register(String mac, PushCallback callback) {
    _subscriptions[mac] = callback;
    _log.fine('Registered subscription for MAC: $mac');

    return () {
      _subscriptions.remove(mac);
      _log.fine('Unregistered subscription for MAC: $mac');
      stopIfNoSubs();
    };
  }

  /// Handles socket events (incoming messages)
  void _onSocketEvent(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final datagram = _socket!.receive();
      if (datagram != null) {
        _onPush(datagram.data, datagram.address.address, datagram.port);
      }
    }
  }

  /// Handles incoming push messages
  void _onPush(List<int> data, String ip, int port) {
    _log.fine('PUSH << from $ip:$port');

    // Ignore test messages from the app
    if (data.length == 4 &&
        data[0] == 't'.codeUnitAt(0) &&
        data[1] == 'e'.codeUnitAt(0) &&
        data[2] == 's'.codeUnitAt(0) &&
        data[3] == 't'.codeUnitAt(0)) {
      return;
    }

    try {
      final message = utf8.decode(data);
      _log.fine('PUSH message: $message');

      final resp = jsonDecode(message) as Map<String, dynamic>;
      final method = resp['method'] as String?;
      final params = resp['params'] as Map<String, dynamic>?;
      final mac = params?['mac'] as String?;

      // Handle firstBeat (discovery)
      if (method == 'firstBeat' && _discoveryCallback != null) {
        _log.info('Discovered new bulb at $ip with MAC: $mac');
        _discoveryCallback!(ip, mac);
      }

      // Handle syncPilot (state update)
      if (method == 'syncPilot' &&
          mac != null &&
          _subscriptions.containsKey(mac)) {
        _log.fine('syncPilot for MAC: $mac');
        if (params != null) {
          final state = PilotParser(params);
          _subscriptions[mac]!(state, ip);
        }
      }
    } catch (e) {
      _log.warning('Failed to process push message from $ip: $e');
    }
  }

  /// Gets the source IP that can reach the target IP
  Future<String?> _getSourceIp(String targetIp) async {
    // For testing, allow overriding the source IP
    if (testSourceIp != null) {
      _log.fine('Using test source IP: $testSourceIp');
      return testSourceIp;
    }

    try {
      // Get all network interfaces
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );

      // Find the interface that can reach the target
      // Prefer interfaces on the same subnet as the target
      final targetParts = targetIp.split('.');
      if (targetParts.length != 4) {
        return null;
      }
      final targetSubnet = '${targetParts[0]}.${targetParts[1]}.${targetParts[2]}';

      // First try to find an interface on the same subnet
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final addrParts = addr.address.split('.');
          if (addrParts.length == 4) {
            final addrSubnet = '${addrParts[0]}.${addrParts[1]}.${addrParts[2]}';
            if (addrSubnet == targetSubnet) {
              _log.fine('Source IP for $targetIp: ${addr.address} (same subnet)');
              return addr.address;
            }
          }
        }
      }

      // Fallback: use the first non-loopback IPv4 address
      for (final interface in interfaces) {
        if (interface.addresses.isNotEmpty) {
          final addr = interface.addresses.first.address;
          _log.fine('Source IP for $targetIp: $addr (fallback)');
          return addr;
        }
      }

      _log.warning('Could not determine source IP for $targetIp');
      return null;
    } catch (e) {
      _log.warning('Could not auto-detect source IP for $targetIp: $e');
      return null;
    }
  }

  /// Generates a random MAC address
  String _generateMac() {
    final random = Random();
    final mac = List.generate(
      12,
      (_) => random.nextInt(16).toRadixString(16),
    ).join('');
    return mac;
  }
}
