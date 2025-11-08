// Dart port of pywizlight exceptions
// See LICENSE file for licensing details.

/// Base exception for all WizLight errors
///
/// All WizLight-specific exceptions extend this base class.
class WizLightException implements Exception {
  /// The error message
  final String message;

  /// Creates a WizLight exception with the given message
  const WizLightException(this.message);

  @override
  String toString() => 'WizLightException: $message';
}

/// Exception raised when a connection error occurs
///
/// This includes network errors, socket errors, and other
/// connection-related failures when communicating with a WiZ bulb.
class WizLightConnectionError extends WizLightException {
  /// Creates a connection error with the given message
  const WizLightConnectionError(super.message);

  @override
  String toString() => 'WizLightConnectionError: $message';
}

/// Exception raised when a connection times out
///
/// This occurs when a bulb does not respond within the expected
/// timeout period after multiple retry attempts.
class WizLightTimeoutError extends WizLightException {
  /// Creates a timeout error with the given message
  const WizLightTimeoutError(super.message);

  @override
  String toString() => 'WizLightTimeoutError: $message';
}

/// Exception raised when a bulb method is not found or supported
///
/// This typically happens when calling a method that is not available
/// on older bulb firmware versions, or when a feature is not supported
/// by a particular bulb model.
class WizLightMethodNotFound extends WizLightException {
  /// Creates a method not found error with the given message
  const WizLightMethodNotFound(super.message);

  @override
  String toString() => 'WizLightMethodNotFound: $message';
}

/// Exception raised when a bulb type is not recognized
///
/// This occurs when the library encounters a bulb model or configuration
/// that is not in the known bulb type database.
class WizLightNotKnownBulb extends WizLightException {
  /// Creates a not known bulb error with the given message
  const WizLightNotKnownBulb(super.message);

  @override
  String toString() => 'WizLightNotKnownBulb: $message';
}
