import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_copilot/flutter_copilot.dart';

void main() {
  group('RetryConfig', () {
    test('has sensible defaults', () {
      const config = RetryConfig();
      expect(config.maxRetries, 3);
      expect(config.baseDelay, const Duration(milliseconds: 500));
      expect(config.maxDelay, const Duration(seconds: 30));
      expect(config.exponentialBackoff, isTrue);
    });
  });

  group('RetryEngine', () {
    test('succeeds on first attempt without retrying', () async {
      var calls = 0;
      final engine = RetryEngine(const RetryConfig(maxRetries: 3));

      final result = await engine.run(() async {
        calls++;
        return 'ok';
      });

      expect(result, 'ok');
      expect(calls, 1);
    });

    test('retries on failure and succeeds on second attempt', () async {
      var calls = 0;
      final engine = RetryEngine(const RetryConfig(
        maxRetries: 3,
        baseDelay: Duration.zero,
        maxDelay: Duration.zero,
      ));

      final result = await engine.run(() async {
        calls++;
        if (calls == 1) {
          throw const LlmException('transient error');
        }
        return 'recovered';
      });

      expect(result, 'recovered');
      expect(calls, 2);
    });

    test('retries up to maxRetries then throws', () async {
      var calls = 0;
      final engine = RetryEngine(const RetryConfig(
        maxRetries: 2,
        baseDelay: Duration.zero,
        maxDelay: Duration.zero,
      ));

      Object? caughtError;
      try {
        await engine.run(() async {
          calls++;
          throw const LlmException('persistent error');
        });
      } catch (e) {
        caughtError = e;
      }
      expect(caughtError, isA<RetryException>());
      expect(
        (caughtError as RetryException).attempts,
        2,
      );
      expect(calls, 2);
    });

    test('does not retry non-retryable errors', () async {
      var calls = 0;
      final engine = RetryEngine(const RetryConfig(maxRetries: 5));

      expect(
        () => engine.run(() async {
          calls++;
          throw StateError('bad state');
        }),
        throwsA(isA<StateError>()),
      );

      expect(calls, 1);
    });

    test('applies exponential backoff delays', () async {
      var calls = 0;
      final engine = RetryEngine(const RetryConfig(
        maxRetries: 4,
        baseDelay: Duration(milliseconds: 100),
        maxDelay: Duration(seconds: 2),
        exponentialBackoff: true,
      ));

      final sw = Stopwatch()..start();
      try {
        await engine.run(() async {
          calls++;
          throw const LlmException('fail');
        });
      } catch (_) {}
      sw.stop();

      // With exponential backoff: 100ms, 200ms, 400ms = 700ms minimum
      // Allow generous tolerance for scheduling overhead
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(600));
      expect(calls, 4);
    });

    test('caps delay at maxDelay', () async {
      final engine = RetryEngine(const RetryConfig(
        maxRetries: 3,
        baseDelay: Duration(seconds: 10),
        maxDelay: Duration(seconds: 1),
        exponentialBackoff: true,
      ));

      final sw = Stopwatch()..start();
      try {
        await engine.run(() async {
          throw const LlmException('fail');
        });
      } catch (_) {}
      sw.stop();

      // With maxDelay capped at 1s: ~1s * 2 retries = ~2s
      expect(sw.elapsedMilliseconds, lessThan(5000));
    });

    test('uses linear delay when exponentialBackoff is false', () async {
      final engine = RetryEngine(const RetryConfig(
        maxRetries: 3,
        baseDelay: Duration(milliseconds: 200),
        maxDelay: Duration(seconds: 10),
        exponentialBackoff: false,
      ));

      final sw = Stopwatch()..start();
      try {
        await engine.run(() async {
          throw const LlmException('fail');
        });
      } catch (_) {}
      sw.stop();

      // Linear: 200ms * 2 retries = 400ms minimum
      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(300));
    });

    test('returns retry count in RetryException', () async {
      final engine = RetryEngine(const RetryConfig(
        maxRetries: 2,
        baseDelay: Duration.zero,
        maxDelay: Duration.zero,
      ));

      expect(
        () => engine.run(() async {
          throw const LlmException('fail');
        }),
        throwsA(
          isA<RetryException>()
              .having((e) => e.attempts, 'attempts', 2)
              .having((e) => e.lastError, 'lastError', isA<LlmException>()),
        ),
      );
    });

    test('retryable defaults to true for LlmException', () {
      const engine = RetryEngine(RetryConfig());
      expect(engine.isRetryable(const LlmException('timeout')), isTrue);
    });

    test('retryable defaults to false for unknown errors', () {
      const engine = RetryEngine(RetryConfig());
      expect(engine.isRetryable(StateError('bad')), isFalse);
    });

    test('accepts custom retryable predicate', () {
      final engine = RetryEngine(
        const RetryConfig(),
        retryable: (e) => e is FormatException,
      );
      expect(engine.isRetryable(const FormatException('bad json')), isTrue);
      expect(engine.isRetryable(const LlmException('timeout')), isFalse);
    });
  });
}
