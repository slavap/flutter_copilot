import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_copilot/flutter_copilot.dart';

void main() {
  group('CopilotMetrics', () {
    test('records basic run data', () {
      final start = DateTime(2025);
      final end = DateTime(2025, 1, 1, 0, 0, 5);

      final metrics = CopilotMetrics(
        goal: 'Open settings',
        startTime: start,
        endTime: end,
        steps: 3,
        actionsExecuted: 5,
        succeeded: true,
        totalTokens: 1200,
      );

      expect(metrics.goal, 'Open settings');
      expect(metrics.startTime, start);
      expect(metrics.endTime, end);
      expect(metrics.steps, 3);
      expect(metrics.actionsExecuted, 5);
      expect(metrics.succeeded, isTrue);
      expect(metrics.totalTokens, 1200);
      expect(metrics.failureReason, isNull);
    });

    test('records failure reason when failed', () {
      final metrics = CopilotMetrics(
        goal: 'Delete everything',
        startTime: DateTime(2025),
        endTime: DateTime(2025),
        steps: 1,
        actionsExecuted: 0,
        succeeded: false,
        failureReason: 'LLM request failed',
      );

      expect(metrics.succeeded, isFalse);
      expect(metrics.failureReason, 'LLM request failed');
    });

    test('duration computes elapsed time', () {
      final metrics = CopilotMetrics(
        goal: 'Test',
        startTime: DateTime(2025),
        endTime: DateTime(2025, 1, 1, 0, 0, 10),
        steps: 2,
        actionsExecuted: 2,
        succeeded: true,
      );

      expect(metrics.duration, const Duration(seconds: 10));
    });
  });

  group('MetricsCollector', () {
    test('starts with empty history', () {
      final collector = MetricsCollector();
      expect(collector.history, isEmpty);
    });

    test('records metrics', () {
      final collector = MetricsCollector();
      final metrics = _makeMetrics(goal: 'G1', succeeded: true);

      collector.record(metrics);

      expect(collector.history, hasLength(1));
      expect(collector.history.first, metrics);
    });

    test('summary is empty when no metrics recorded', () {
      final collector = MetricsCollector();
      final summary = collector.summary;

      expect(summary.totalRuns, 0);
      expect(summary.successRate, 0.0);
      expect(summary.averageSteps, 0.0);
      expect(summary.averageDuration, Duration.zero);
      expect(summary.averageTokens, 0.0);
      expect(summary.averageActionsExecuted, 0.0);
    });

    test('summary computes correct aggregates', () {
      final collector = MetricsCollector();

      collector.record(_makeMetrics(
        goal: 'G1',
        succeeded: true,
        steps: 2,
        actionsExecuted: 3,
        totalTokens: 100,
        duration: const Duration(seconds: 5),
      ));
      collector.record(_makeMetrics(
        goal: 'G2',
        succeeded: false,
        steps: 4,
        actionsExecuted: 6,
        totalTokens: 200,
        duration: const Duration(seconds: 10),
      ));
      collector.record(_makeMetrics(
        goal: 'G3',
        succeeded: true,
        steps: 3,
        actionsExecuted: 5,
        totalTokens: 150,
        duration: const Duration(seconds: 8),
      ));

      final summary = collector.summary;

      expect(summary.totalRuns, 3);
      expect(summary.successRate, closeTo(2 / 3, 0.001));
      expect(summary.averageSteps, closeTo(3.0, 0.001));
      expect(summary.averageTokens, closeTo(150.0, 0.001));
      expect(summary.averageActionsExecuted, closeTo(4.667, 0.01));
      expect(summary.averageDuration, const Duration(seconds: 7, milliseconds: 667));
    });

    test('summary with only failures', () {
      final collector = MetricsCollector();

      collector.record(_makeMetrics(
        goal: 'F1',
        succeeded: false,
        steps: 1,
        actionsExecuted: 0,
      ));
      collector.record(_makeMetrics(
        goal: 'F2',
        succeeded: false,
        steps: 2,
        actionsExecuted: 1,
      ));

      final summary = collector.summary;

      expect(summary.totalRuns, 2);
      expect(summary.successRate, 0.0);
    });

    test('summary with only successes', () {
      final collector = MetricsCollector();

      collector.record(_makeMetrics(
        goal: 'S1',
        succeeded: true,
        steps: 1,
        actionsExecuted: 2,
      ));

      final summary = collector.summary;

      expect(summary.totalRuns, 1);
      expect(summary.successRate, 1.0);
    });

    test('reset clears history', () {
      final collector = MetricsCollector();
      collector.record(_makeMetrics(goal: 'G1', succeeded: true));

      collector.reset();

      expect(collector.history, isEmpty);
      expect(collector.summary.totalRuns, 0);
    });
  });

  group('CopilotSession integration', () {
    testWidgets('records metrics when collector is provided', (tester) async {
      final collector = MetricsCollector();
      final session = CopilotSession(
        goal: 'Open settings',
        config: CopilotConfig(
          llm: FakeLlmAdapter(
            <LlmToolCall>[
              const LlmToolCall(
                id: 'c1',
                name: 'tap',
                arguments: <String, Object?>{'id': 'n1'},
              ),
              const LlmToolCall(
                id: 'c2',
                name: 'done',
                arguments: <String, Object?>{'summary': 'Settings opened.'},
              ),
            ],
          ),
          settleDelay: Duration.zero,
          metricsCollector: collector,
        ),
        emit: (_) {},
        capture: _FakeCapture(),
        executor: _FakeExecutor(),
      );

      final result = await session.run();

      expect(result, isA<CopilotCompleted>());
      expect(collector.history, hasLength(1));

      final metrics = collector.history.first;
      expect(metrics.goal, 'Open settings');
      expect(metrics.succeeded, isTrue);
      expect(metrics.steps, greaterThanOrEqualTo(1));
      expect(metrics.actionsExecuted, greaterThanOrEqualTo(1));
      expect(metrics.endTime.isAfter(metrics.startTime), isTrue);
    });

    testWidgets('records failure metrics on error', (tester) async {
      final collector = MetricsCollector();
      final session = CopilotSession(
        goal: 'Fail',
        config: CopilotConfig(
          llm: FakeLlmAdapter(
            <LlmToolCall>[
              const LlmToolCall(
                id: 'c1',
                name: 'done',
                arguments: <String, Object?>{'summary': 'Done.'},
              ),
            ],
          ),
          settleDelay: Duration.zero,
          metricsCollector: collector,
        ),
        emit: (_) {},
        capture: _FakeCapture(),
        executor: _FakeExecutor(),
      );

      await session.run();

      expect(collector.history, hasLength(1));
      final metrics = collector.history.first;
      expect(metrics.succeeded, isTrue);
    });

    testWidgets('records failure when LLM throws', (tester) async {
      final collector = MetricsCollector();
      final session = CopilotSession(
        goal: 'Error',
        config: CopilotConfig(
          llm: _ThrowingLlmAdapter(),
          settleDelay: Duration.zero,
          metricsCollector: collector,
        ),
        emit: (_) {},
        capture: _FakeCapture(),
        executor: _FakeExecutor(),
      );

      await session.run();

      expect(collector.history, hasLength(1));
      final metrics = collector.history.first;
      expect(metrics.succeeded, isFalse);
      expect(metrics.failureReason, isNotNull);
    });

    testWidgets('works fine without metrics collector', (tester) async {
      final session = CopilotSession(
        goal: 'Open settings',
        config: CopilotConfig(
          llm: FakeLlmAdapter(
            <LlmToolCall>[
              const LlmToolCall(
                id: 'c1',
                name: 'done',
                arguments: <String, Object?>{'summary': 'Done.'},
              ),
            ],
          ),
          settleDelay: Duration.zero,
        ),
        emit: (_) {},
        capture: _FakeCapture(),
        executor: _FakeExecutor(),
      );

      final result = await session.run();

      expect(result, isA<CopilotCompleted>());
    });

    testWidgets('records metrics on max steps exceeded', (tester) async {
      final collector = MetricsCollector();
      final session = CopilotSession(
        goal: 'Endless',
        config: CopilotConfig(
          llm: _LoopingLlmAdapter(),
          maxSteps: 2,
          settleDelay: Duration.zero,
          metricsCollector: collector,
        ),
        emit: (_) {},
        capture: _FakeCapture(),
        executor: _FakeExecutor(),
      );

      final result = await session.run();

      expect(result, isA<CopilotMaxStepsExceeded>());
      expect(collector.history, hasLength(1));
      final metrics = collector.history.first;
      expect(metrics.succeeded, isFalse);
      expect(metrics.steps, 2);
    });
  });
}

CopilotMetrics _makeMetrics({
  required String goal,
  required bool succeeded,
  int steps = 1,
  int actionsExecuted = 1,
  int totalTokens = 0,
  Duration duration = const Duration(seconds: 1),
  String? failureReason,
}) {
  final start = DateTime(2025);
  return CopilotMetrics(
    goal: goal,
    startTime: start,
    endTime: start.add(duration),
    steps: steps,
    actionsExecuted: actionsExecuted,
    totalTokens: totalTokens,
    succeeded: succeeded,
    failureReason: failureReason,
  );
}

class _FakeCapture extends SceneCapture {
  @override
  SceneGraph capture() {
    return SceneGraph(
      nodes: <SceneNode>[
        SceneNode(
          id: 'n1',
          semanticsId: 1,
          rect: Rect.fromLTWH(0, 0, 120, 48),
          label: 'Settings',
          actions: <SceneAction>{SceneAction.tap},
        ),
      ],
      idToSemanticsId: const <String, int>{'n1': 1},
    );
  }
}

class _FakeExecutor extends ActionExecutor {
  @override
  Future<ActionResult> execute(
      CopilotAction action, SceneGraph latestScene) async {
    return ActionResult.success('ok');
  }
}

class _ThrowingLlmAdapter implements LlmAdapter {
  @override
  Future<LlmResponse> complete({
    required List<LlmMessage> messages,
    required List<LlmTool> tools,
  }) async {
    throw const LlmException('network unavailable');
  }
}

class _LoopingLlmAdapter implements LlmAdapter {
  @override
  Future<LlmResponse> complete({
    required List<LlmMessage> messages,
    required List<LlmTool> tools,
  }) async {
    return const LlmResponse(
      toolCall: LlmToolCall(
        id: 'c1',
        name: 'tap',
        arguments: <String, Object?>{'id': 'n1'},
      ),
    );
  }
}
