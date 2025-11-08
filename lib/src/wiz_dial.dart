// WiZ Smart Dial device representation
// See LICENSE file for licensing details.

import 'dial_event.dart';
import 'dial_manager.dart';

/// Represents a WiZ Smart Dial Switch device
///
/// The WiZ Smart Dial is an accessory device (not a bulb) that sends
/// UDP broadcast events when its controls are used:
/// - Rotary dial (clockwise/counter-clockwise with tactile clicks)
/// - Dial button (short/long press)
/// - Two scene buttons (short/long press)
///
/// Example:
/// ```dart
/// final dial = WizDial(mac: '9877d583fec5');
/// await dial.startListening((event) {
///   switch (event.type) {
///     case DialEventType.rotationClockwise:
///       print('Dial turned right');
///       break;
///     case DialEventType.dialShortPress:
///       print('Dial button pressed');
///       break;
///   }
/// });
/// ```
class WizDial {
  /// The MAC address of this dial (e.g., '9877d583fec5')
  final String mac;

  /// Optional friendly name for this dial
  String? name;

  /// The dial manager instance
  final DialManager _manager = DialManager();

  /// The last event received from this dial
  DialEvent? lastEvent;

  /// Whether we're currently listening for events
  bool get isListening => _manager.getSubscribedDials().contains(mac);

  WizDial({
    required this.mac,
    this.name,
  });

  /// Start listening for events from this dial
  ///
  /// The callback will be invoked whenever an event is received.
  /// The DialManager will be started automatically if not already running.
  ///
  /// Returns true if listening started successfully, false otherwise.
  Future<bool> startListening(DialEventCallback callback) async {
    // Start the manager if not already running
    if (!_manager.isRunning) {
      final started = await _manager.start();
      if (!started) {
        return false;
      }
    }

    // Subscribe to events from this dial
    _manager.subscribe(mac, (event) {
      lastEvent = event;
      callback(event);
    });

    return true;
  }

  /// Stop listening for events from this dial
  void stopListening() {
    _manager.unsubscribe(mac);
  }

  @override
  String toString() {
    return 'WizDial(mac: $mac${name != null ? ', name: $name' : ''})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WizDial && other.mac == mac;
  }

  @override
  int get hashCode => mac.hashCode;
}
