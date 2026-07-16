/// Configuration for the retry engine.
class RetryConfig {
  /// Creates a retry configuration.
  const RetryConfig({
    this.maxRetries = 3,
    this.baseDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 30),
    this.exponentialBackoff = true,
  });

  /// Maximum number of retry attempts before giving up.
  final int maxRetries;

  /// Initial delay before the first retry.
  final Duration baseDelay;

  /// Maximum delay between retries.
  final Duration maxDelay;

  /// Whether to use exponential backoff (true) or linear backoff (false).
  final bool exponentialBackoff;
}
