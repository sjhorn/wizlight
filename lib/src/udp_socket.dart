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
 * @file udp_socket.dart
 *
 ***************************************************************************/

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

/// Timeout duration for UDP requests
const int udpRequestTimeout = 2;

/// Maximum buffer size for UDP messages
const int maxLineSize = 4096;

/// UDP socket wrapper for WiZ bulb communication
///
/// Provides UDP datagram socket functionality with broadcast support
/// and automatic timeout handling for WiZ bulb protocol communication.
class UDPSocket {
  static final Logger _log = Logger('UDPSocket');

  RawDatagramSocket? _socket;

  /// Creates a new UDP socket instance
  ///
  /// The socket is lazily initialized on first use.
  UDPSocket();

  /// Initializes the UDP socket with broadcast support
  ///
  /// Returns true if initialization succeeds, false otherwise.
  Future<bool> _initializeUDPSocket() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket!.broadcastEnabled = true;
      _log.fine('UDP socket initialized');
      return true;
    } catch (e) {
      _log.severe('UDP socket creation failed: $e');
      return false;
    }
  }

  /// Sends a UDP command and waits for a response
  ///
  /// [msg] - The message to send (typically JSON)
  /// [targetIp] - The target IP address
  /// [port] - The target port (typically 38899 for WiZ bulbs)
  /// [captureSenderIp] - If true, returns the sender's IP address
  ///
  /// Returns a tuple of (response string, sender IP).
  /// If [captureSenderIp] is false, sender IP will be empty.
  /// Returns empty response on timeout or error.
  Future<(String response, String senderIp)> sendUDPCommand(
    String msg,
    String targetIp,
    int port, {
    bool captureSenderIp = false,
  }) async {
    // Lazy initialization
    if (_socket == null) {
      await _initializeUDPSocket();
    }

    if (_socket == null) {
      _log.severe('Socket not initialized');
      return ('', '');
    }

    _log.fine('sendUDPCommand socket ipAddr $targetIp cmd $msg');

    try {
      final address = InternetAddress(targetIp);
      final data = utf8.encode(msg);

      // Send the command
      final sent = _socket!.send(data, address, port);
      if (sent != data.length) {
        _log.severe('sendto error: sent $sent bytes, expected ${data.length}');
        return ('', '');
      }

      // Wait for response with timeout
      final completer = Completer<(String, String)>();
      StreamSubscription<RawSocketEvent>? subscription;
      Timer? timeoutTimer;

      timeoutTimer = Timer(Duration(seconds: udpRequestTimeout), () {
        _log.severe('Device response timed out');
        if (!completer.isCompleted) {
          completer.complete(('', ''));
        }
        subscription?.cancel();
      });

      subscription = _socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram != null && !completer.isCompleted) {
            final response = utf8.decode(datagram.data);
            final senderIp = captureSenderIp ? datagram.address.address : '';

            _log.fine('sendUDPCommand device response: $response');
            if (captureSenderIp) {
              _log.fine('sendUDPCommand senderIP: $senderIp');
            }

            timeoutTimer?.cancel();
            subscription?.cancel();
            completer.complete((response, senderIp));
          }
        }
      });

      return await completer.future;
    } catch (e) {
      _log.severe('sendUDPCommand error: $e');
      return ('', '');
    }
  }

  /// Closes the UDP socket
  void close() {
    _socket?.close();
    _socket = null;
  }
}
