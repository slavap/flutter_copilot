import '../llm/openai_llm_adapter.dart';
import 'retry_config.dart';

/// Wraps an operation with retry logic for transient failures.
class RetryEngine {
  /// Creates a retry engine with the given [config].
  const RetryEngine(
    this.config, {
    bool Function(Exception)? retryable,
  }) : _retryable = retryable;

  /// Retry configuration.
  final RetryConfig config;

  final bool Function(Exception)? _retryable;

  /// Whether [error] should be retried.
  bool isRetryable(Object error) {
    final custom = _retryable;
    if (custom != null) {
      return custom(error as Exception);
    }
    return error is LlmException;
  }

  /// Executes [operation], retrying on transient failures.
  Future<T> run<T>(Future<T> Function() operation) async {
    var lastError = Exception('no attempts made');

    for (var attempt = 0; attempt < config.maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        if (!isRetryable(lastError)) {
          rethrow;
        }
        if (attempt < config.maxRetries - 1) {
          await Future<void>.delayed(_delayForAttempt(attempt));
        }
      }
    }

    throw RetryException(
      attempts: config.maxRetries,
      lastError: lastError,
    );
  }

  Duration _delayForAttempt(int attempt) {
    final base = config.baseDelay;
    if (!config.exponentialBackoff) {
      final delay = base * (attempt + 1);
      return delay > config.maxDelay ? config.maxDelay : delay;
    }
    final delay = base * (1 << attempt);
    return delay > config.maxDelay ? config.maxDelay : delay;
  }
}

/// Thrown when all retry attempts are exhausted.
class RetryException implements Exception {
  /// Creates a retry exception.
  const RetryException({
    required this.attempts,
    required this.lastError,
  });

  /// Total number of attempts made.
  final int attempts;

  /// The error from the last failed attempt.
  final Exception lastError;

  @override
  String toString() =>
      'RetryException: all $attempts attempts failed. Last error: $lastError';
}
