// Async lock for serializing asynchronous operations
// See LICENSE file for licensing details.

import 'dart:async';

/// A simple async lock for serializing asynchronous operations
///
/// This ensures that async operations execute sequentially, preventing
/// race conditions and request/response mismatches in concurrent scenarios.
///
/// Example usage:
/// ```dart
/// final lock = AsyncLock();
///
/// Future<String> doWork() async {
///   return await lock.synchronized(() async {
///     // Critical section - only one caller at a time
///     await someAsyncOperation();
///     return 'done';
///   });
/// }
/// ```
class AsyncLock {
  Future<void>? _last;

  /// Executes a function exclusively, ensuring only one runs at a time
  ///
  /// If another operation is in progress, this will wait for it to complete
  /// before starting. All operations are serialized in FIFO order.
  ///
  /// [fn] - The async function to execute exclusively
  ///
  /// Returns the result of the function.
  Future<T> synchronized<T>(Future<T> Function() fn) async {
    final previous = _last;
    final completer = Completer<void>();
    _last = completer.future;

    try {
      // Wait for previous operation to complete
      if (previous != null) {
        await previous;
      }

      // Execute the function
      return await fn();
    } finally {
      // Signal that this operation is complete
      completer.complete();
    }
  }

  /// Whether a lock operation is currently in progress
  bool get isLocked => _last != null;
}
