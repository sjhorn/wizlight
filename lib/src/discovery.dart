// Dart port of pywizlight discovery module
// See LICENSE file for licensing details.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

/// Port for WiZ bulb communication
const int port = 38899;

/// Default wait time for discovery in seconds
const int defaultWaitTime = 5;

// Note: The IP and address we give the bulb does not matter because
// we have register set to false which is telling the bulb to remove
// the registration
const _registerMessage = {
  'method': 'registration',
  'params': {
    'phoneMac': 'AAAAAAAAAAAA',
    'register': false,
    'phoneIp': '1.2.3.4',
    'id': '1',
  },
};

/// Represents a discovered WiZ bulb
class DiscoveredBulb {
  /// The IP address of the bulb
  final String ip;

  /// The MAC address of the bulb
  final String mac;

  /// Creates a discovered bulb entry
  const DiscoveredBulb(this.ip, this.mac);

  @override
  String toString() => 'DiscoveredBulb(ip: $ip, mac: $mac)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredBulb &&
          runtimeType == other.runtimeType &&
          ip == other.ip &&
          mac == other.mac;

  @override
  int get hashCode => ip.hashCode ^ mac.hashCode;

  /// Converts to a map for JSON serialization
  Map<String, String> toMap() => {'ip': ip, 'mac': mac};
}

/// Registry for collecting discovered bulbs
class BulbRegistry {
  static final Logger _log = Logger('BulbRegistry');
  final Map<String, DiscoveredBulb> _bulbs = {};

  /// Registers a discovered bulb (keyed by MAC to avoid duplicates)
  void register(DiscoveredBulb bulb) {
    _bulbs[bulb.mac] = bulb;
    _log.fine('Registered bulb at ${bulb.ip} with MAC ${bulb.mac}');
  }

  /// Returns all discovered bulbs
  List<DiscoveredBulb> get bulbs => _bulbs.values.toList();

  /// Returns the number of discovered bulbs
  int get count => _bulbs.length;
}

/// Discovers WiZ bulbs on the network
///
/// Sends UDP broadcast messages and collects responses for the specified
/// wait time. This matches the behavior of pywizlight's discovery.
///
/// [broadcastAddress] - The broadcast address to use (e.g., '192.168.1.255')
/// [waitTime] - How long to wait for responses (default: 5 seconds)
///
/// Returns a list of discovered bulbs with their IP and MAC addresses.
Future<List<DiscoveredBulb>> discoverBulbs({
  String broadcastAddress = '255.255.255.255',
  Duration waitTime = const Duration(seconds: defaultWaitTime),
}) async {
  final log = Logger('Discovery');
  final registry = BulbRegistry();

  RawDatagramSocket? socket;
  StreamSubscription<RawSocketEvent>? subscription;
  Timer? broadcastTimer;

  try {
    // Create socket with broadcast enabled
    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;

    final address = InternetAddress(broadcastAddress);
    final message = utf8.encode(jsonEncode(_registerMessage));

    log.info('Starting discovery on $broadcastAddress for ${waitTime.inSeconds}s');

    // Send initial broadcast immediately
    socket.send(message, address, port);

    // Send broadcasts repeatedly every 1 second (like Python does)
    broadcastTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (socket != null) {
        socket.send(message, address, port);
        log.fine('Sent broadcast to $broadcastAddress');
      }
    });

    // Listen for all responses
    subscription = socket.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = socket!.receive();
        if (datagram != null) {
          try {
            final response = utf8.decode(datagram.data);
            log.fine('Received response from ${datagram.address.address}: $response');

            final data = jsonDecode(response) as Map<String, dynamic>;
            final result = data['result'] as Map<String, dynamic>?;
            final mac = result?['mac'] as String?;

            if (mac != null) {
              final bulb = DiscoveredBulb(datagram.address.address, mac);
              registry.register(bulb);
              log.info('Discovered bulb at ${bulb.ip} with MAC ${bulb.mac}');
            }
          } catch (e) {
            log.warning('Failed to parse response from ${datagram.address.address}: $e');
          }
        }
      }
    });

    // Wait for the specified time to collect all responses
    await Future.delayed(waitTime);

    log.info('Discovery complete. Found ${registry.count} bulb(s)');
    return registry.bulbs;
  } catch (e) {
    log.severe('Discovery failed: $e');
    rethrow;
  } finally {
    // Clean up resources
    broadcastTimer?.cancel();
    await subscription?.cancel();
    socket?.close();
  }
}
