// WiZ Smart Dial event manager
// See LICENSE file for licensing details.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

import 'dial_event.dart';

/// Port for listening to Smart Dial events (same as bulb respond port)
const int dialPort = 38899;

/// Debounce duration for button press events in milliseconds
///
/// Button presses (dial button and scene buttons) are debounced to prevent
/// duplicate events from hardware bouncing. Rotation events are not debounced
/// to preserve fast rotation responsiveness.
const int buttonDebounceDurationMs = 400;

/// Callback type for dial events
typedef DialEventCallback = void Function(DialEvent event);

/// Manages events from WiZ Smart Dial devices
///
/// The DialManager is a singleton that listens for syncAccEvt messages
/// from Smart Dial switches on port 38899. Unlike bulbs, dials broadcast
/// their events without requiring registration.
///
/// This enables real-time event notifications for dial rotations and
/// button presses.
///
/// Example:
/// ```dart
/// final manager = DialManager();
/// await manager.start();
///
/// manager.subscribe('9877d583fec5', (event) {
///   print('Dial event: ${event.type}');
/// });
/// ```
class DialManager {
  static final Logger _log = Logger('DialManager');
  static DialManager? _instance;

  /// Test-only: Override the listen port (set to 0 for any available port)
  /// Must be set before the DialManager singleton is created
  static int? testListenPort;

  /// Test-only: Reset the singleton instance (useful for testing)
  static void resetForTesting() {
    _instance?._subscription?.cancel();
    _instance?._socket?.close();
    _instance = null;
    testListenPort = null;
  }

  /// Gets the singleton instance
  factory DialManager() {
    _instance ??= DialManager._internal();
    return _instance!;
  }

  DialManager._internal();

  RawDatagramSocket? _socket;
  StreamSubscription<RawSocketEvent>? _subscription;
  bool _running = false;
  String? _failReason;

  /// Event subscriptions keyed by MAC address
  final Map<String, DialEventCallback> _subscriptions = {};

  /// Global event callback for all dials
  DialEventCallback? _globalCallback;

  /// Last event timestamp for debouncing, keyed by "mac:eventType"
  /// Only tracks button press events (not rotation)
  final Map<String, DateTime> _lastEventTime = {};

  /// Whether the manager is currently running
  bool get isRunning => _running;

  /// Reason for failure to start
  String? get failReason => _failReason;

  /// Port the socket is currently listening on
  int? get port => _socket?.port;

  /// Start listening for dial events
  ///
  /// Returns true if started successfully, false otherwise.
  /// Check [failReason] for the reason if false is returned.
  Future<bool> start() async {
    if (_running) {
      _log.info('DialManager already running');
      return true;
    }

    try {
      final port = testListenPort ?? dialPort;
      _log.info('Starting DialManager on port $port');

      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      _socket!.broadcastEnabled = true;

      _log.info('DialManager listening on port ${_socket!.port}');

      _subscription = _socket!.listen(
        _handleDatagram,
        onError: (error) {
          _log.severe('Error in DialManager socket: $error');
          _failReason = error.toString();
        },
        onDone: () {
          _log.info('DialManager socket closed');
          _running = false;
        },
      );

      _running = true;
      _failReason = null;
      return true;
    } catch (e) {
      _log.severe('Failed to start DialManager: $e');
      _failReason = e.toString();
      return false;
    }
  }

  /// Stop listening for dial events
  Future<void> stop() async {
    if (!_running) {
      return;
    }

    _log.info('Stopping DialManager');

    await _subscription?.cancel();
    _subscription = null;

    _socket?.close();
    _socket = null;

    _running = false;
  }

  /// Subscribe to events from a specific dial (by MAC address)
  ///
  /// The callback will be invoked whenever an event is received from the
  /// dial with the given MAC address.
  ///
  /// Example:
  /// ```dart
  /// manager.subscribe('9877d583fec5', (event) {
  ///   if (event.type == DialEventType.rotationClockwise) {
  ///     print('Dial turned clockwise');
  ///   }
  /// });
  /// ```
  void subscribe(String mac, DialEventCallback callback) {
    _log.info('Subscribing to dial $mac');
    _subscriptions[mac] = callback;
  }

  /// Unsubscribe from events from a specific dial
  void unsubscribe(String mac) {
    _log.info('Unsubscribing from dial $mac');
    _subscriptions.remove(mac);
  }

  /// Set a global callback for all dial events
  ///
  /// This callback will be invoked for every event from any dial,
  /// in addition to any dial-specific subscriptions.
  ///
  /// Useful for logging or monitoring all dial activity.
  void setGlobalCallback(DialEventCallback? callback) {
    _globalCallback = callback;
  }

  /// Get list of all subscribed dial MAC addresses
  List<String> getSubscribedDials() {
    return _subscriptions.keys.toList();
  }

  /// Check if a button event should be debounced (filtered out)
  bool _shouldDebounceEvent(DialEvent event) {
    // Only debounce button presses, not rotation events
    if (event.type == DialEventType.rotationClockwise ||
        event.type == DialEventType.rotationCounterClockwise) {
      return false;
    }

    final key = '${event.mac}:${event.type}';
    final now = DateTime.now();
    final lastTime = _lastEventTime[key];

    if (lastTime != null) {
      final elapsed = now.difference(lastTime).inMilliseconds;
      if (elapsed < buttonDebounceDurationMs) {
        _log.fine(
            'Debouncing event ${event.type} (${elapsed}ms since last event)');
        return true;
      }
    }

    _lastEventTime[key] = now;
    return false;
  }

  void _handleDatagram(RawSocketEvent event) {
    if (event != RawSocketEvent.read) {
      return;
    }

    final datagram = _socket?.receive();
    if (datagram == null) {
      return;
    }

    try {
      final message = utf8.decode(datagram.data);
      final json = jsonDecode(message) as Map<String, dynamic>;

      // Only process syncAccEvt messages
      if (json['method'] != 'syncAccEvt') {
        return;
      }

      final dialEvent = DialEvent.fromJson(json);
      if (dialEvent == null) {
        _log.warning('Failed to parse dial event: $message');
        return;
      }

      // Apply debouncing for button press events
      if (_shouldDebounceEvent(dialEvent)) {
        return;
      }

      _log.fine('Received dial event: $dialEvent');

      // Call global callback if set
      _globalCallback?.call(dialEvent);

      // Call dial-specific callback if subscribed
      final callback = _subscriptions[dialEvent.mac];
      callback?.call(dialEvent);
    } catch (e) {
      _log.warning('Error processing dial event: $e');
    }
  }
}
