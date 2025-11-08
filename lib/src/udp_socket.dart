// Dart port of wizlightcpp - https://github.com/srisham/wizlightcpp
// See LICENSE file for licensing details.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

import 'exceptions.dart';

// Progressive backoff config - matches pywizlight
// ===============================================================
// We send datagrams at 0, 0.75, 2.25, 5.25, 8.25, 11.25 seconds
// We wait up to 13s total for the last response before declaring failure
// ================================================================

/// Total timeout for UDP requests in seconds
const int defaultTimeout = 13;

/// Maximum number of UDP datagrams to send
const int defaultMaxSendDatagrams = 6;

/// Initial send interval in seconds
const double defaultFirstSendInterval = 0.75;

/// Maximum backoff multiplier in seconds
const int defaultMaxBackoff = 3;

/// Test-only: Override default timeout for faster test execution
/// Set to a positive value to reduce timeout during testing (e.g., 3 seconds)
/// Set to null to use production defaults
int? testTimeout;

/// Test-only: Override retry count for faster test execution
/// Set to a positive value to reduce retries during testing (e.g., 3 attempts)
/// Set to null to use production defaults
int? testMaxSendDatagrams;

/// Maximum buffer size for UDP messages
const int maxLineSize = 4096;

/// UDP socket wrapper for WiZ bulb communication
///
/// Provides robust UDP datagram socket functionality with:
/// - Progressive backoff retry logic
/// - Configurable timeout and retry parameters
/// - Typed exception handling
/// - Broadcast support for device discovery
///
/// The retry logic sends the same message multiple times with exponential
/// backoff until a response is received or the maximum attempts is reached.
class UDPSocket {
  static final Logger _log = Logger('UDPSocket');

  /// Total timeout in seconds before giving up
  final int timeout;

  /// Maximum number of datagrams to send
  final int maxSendDatagrams;

  /// Initial interval between sends in seconds
  final double firstSendInterval;

  /// Maximum backoff interval in seconds
  final int maxBackoff;

  /// Creates a new UDP socket instance with configurable retry parameters
  ///
  /// [timeout] - Total timeout in seconds (default: 13, or testTimeout if set)
  /// [maxSendDatagrams] - Maximum retry attempts (default: 6, or testMaxSendDatagrams if set)
  /// [firstSendInterval] - Initial retry delay in seconds (default: 0.75)
  /// [maxBackoff] - Maximum backoff multiplier (default: 3)
  UDPSocket({
    int? timeout,
    int? maxSendDatagrams,
    this.firstSendInterval = defaultFirstSendInterval,
    this.maxBackoff = defaultMaxBackoff,
  })  : timeout = timeout ?? testTimeout ?? defaultTimeout,
        maxSendDatagrams = maxSendDatagrams ?? testMaxSendDatagrams ?? defaultMaxSendDatagrams;

  /// Sends a UDP command with progressive backoff retry
  ///
  /// Sends the message multiple times with increasing delays until a response
  /// is received or the timeout is reached. This provides much better reliability
  /// than a single-shot UDP send, especially for distant bulbs or busy networks.
  ///
  /// [msg] - The message to send (typically JSON)
  /// [targetIp] - The target IP address
  /// [port] - The target port (typically 38899 for WiZ bulbs)
  /// [captureSenderIp] - If true, returns the sender's IP address
  ///
  /// Returns a tuple of (response string, sender IP).
  /// If [captureSenderIp] is false, sender IP will be empty.
  ///
  /// Throws [WizLightTimeoutError] if no response is received within timeout.
  /// Throws [WizLightConnectionError] if a network error occurs.
  Future<(String response, String senderIp)> sendUDPCommand(
    String msg,
    String targetIp,
    int port, {
    bool captureSenderIp = false,
  }) async {
    _log.fine('sendUDPCommand to $targetIp:$port - $msg');

    RawDatagramSocket? socket;

    try {
      // Create socket with broadcast support
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final address = InternetAddress(targetIp);
      final data = utf8.encode(msg);

      // Set up response handling
      final completer = Completer<(String, String)>();
      StreamSubscription<RawSocketEvent>? subscription;
      Timer? overallTimeout;
      bool responseReceived = false;

      // Overall timeout to prevent hanging forever
      overallTimeout = Timer(Duration(seconds: timeout), () {
        if (!completer.isCompleted) {
          _log.warning(
              'UDP request to $targetIp timed out after $timeout seconds');
          completer.completeError(WizLightTimeoutError(
              'The request to $targetIp timed out after $maxSendDatagrams attempts'));
        }
        subscription?.cancel();
        socket?.close();
      });

      // Listen for responses
      subscription = socket.listen((event) {
        if (event == RawSocketEvent.read && !responseReceived) {
          final datagram = socket?.receive();
          if (datagram != null && !completer.isCompleted) {
            final response = utf8.decode(datagram.data);
            final senderIp = captureSenderIp ? datagram.address.address : '';

            _log.fine('Received response from ${datagram.address.address}');
            _log.fine('Response: $response');

            responseReceived = true;
            overallTimeout?.cancel();
            subscription?.cancel();
            socket?.close();
            completer.complete((response, senderIp));
          }
        }
      });

      // Progressive backoff retry logic
      await _sendWithRetry(
        socket: socket,
        data: data,
        address: address,
        port: port,
        targetIp: targetIp,
        completer: completer,
      );

      return await completer.future;
    } on WizLightException {
      // Re-throw our own exceptions
      socket?.close();
      rethrow;
    } catch (e) {
      socket?.close();
      _log.severe('UDP command error: $e');
      throw WizLightConnectionError('Network error: $e');
    }
  }

  /// Sends UDP datagrams with progressive backoff
  ///
  /// Implements the retry logic: sends at 0s, 0.75s, 2.25s, 5.25s, 8.25s, 11.25s
  Future<void> _sendWithRetry({
    required RawDatagramSocket socket,
    required List<int> data,
    required InternetAddress address,
    required int port,
    required String targetIp,
    required Completer<(String, String)> completer,
  }) async {
    double sendWait = firstSendInterval;
    double totalWaited = 0.0;

    for (int send = 0; send < maxSendDatagrams; send++) {
      if (completer.isCompleted) {
        return;
      }

      final attempt = send + 1;
      _log.fine('>> Sending to $targetIp (attempt $attempt/$maxSendDatagrams, '
          'backoff: ${totalWaited.toStringAsFixed(2)}s)');

      // Send the datagram
      final sent = socket.send(data, address, port);
      if (sent != data.length) {
        _log.warning(
            'Sent only $sent of ${data.length} bytes on attempt $attempt');
      }

      // Don't wait after the last send
      if (send < maxSendDatagrams - 1 && !completer.isCompleted) {
        await Future.delayed(Duration(
          milliseconds: (sendWait * 1000).round(),
        ));
        totalWaited += sendWait;

        // Progressive backoff: double the wait time, but cap at maxBackoff
        sendWait = (sendWait * 2).clamp(0, maxBackoff.toDouble());
      }
    }
  }

  /// Sends a UDP command with a shorter timeout (for setPilot commands)
  ///
  /// Uses fewer retries to avoid flickering when setting light state.
  /// This is useful for commands where you want faster failure rather than
  /// multiple retries that might cause visual artifacts.
  Future<(String response, String senderIp)> sendUDPCommandFast(
    String msg,
    String targetIp,
    int port, {
    bool captureSenderIp = false,
  }) async {
    // Create a temporary socket with reduced retries
    final fastSocket = UDPSocket(
      timeout: 5,
      maxSendDatagrams: 3,
      firstSendInterval: 0.5,
      maxBackoff: 2,
    );

    return await fastSocket.sendUDPCommand(
      msg,
      targetIp,
      port,
      captureSenderIp: captureSenderIp,
    );
  }
}
