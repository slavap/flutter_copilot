import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_copilot/flutter_copilot.dart';

void main() {
  group('CustomAction', () {
    test('wraps an UnknownAction', () {
      final unknown = CopilotAction.fromToolCall(
        'my_custom_tool',
        const <String, Object?>{'key': 'value'},
      );
      expect(unknown, isA<UnknownAction>());

      final custom = CustomAction.fromUnknown(unknown as UnknownAction);
      expect(custom.name, 'my_custom_tool');
      expect(custom.args, {'key': 'value'});
    });

    test('constructs with name and args', () {
      const action = CustomAction(
        name: 'tool_name',
        args: <String, Object?>{'a': 1},
      );
      expect(action.name, 'tool_name');
      expect(action.args, {'a': 1});
    });
  });

  group('CopilotConfig.customActions', () {
    test('defaults to empty map', () {
      final config = CopilotConfig(
        llm: FakeLlmAdapter(const []),
      );
      expect(config.customActions, isEmpty);
    });

    test('accepts custom action handlers', () {
      final handler = _FakeHandler();
      final config = CopilotConfig(
        llm: FakeLlmAdapter(const []),
        customActions: {'my_tool': handler},
      );
      expect(config.customActions, contains('my_tool'));
      expect(config.customActions['my_tool'], same(handler));
    });
  });

  testWidgets('session routes UnknownAction to custom handler', (tester) async {
    final executed = <CustomAction>[];
    final handler = _RecordingHandler(executed);

    final session = CopilotSession(
      goal: 'Run custom tool',
      config: CopilotConfig(
        llm: FakeLlmAdapter(
          <LlmToolCall>[
            const LlmToolCall(
              id: 'c1',
              name: 'my_custom_tool',
              arguments: <String, Object?>{'foo': 'bar'},
            ),
            const LlmToolCall(
              id: 'c2',
              name: 'done',
              arguments: <String, Object?>{'summary': 'Done.'},
            ),
          ],
        ),
        settleDelay: Duration.zero,
        customActions: {'my_custom_tool': handler},
      ),
      emit: (_) {},
      capture: _FakeCapture(),
      executor: _FakeExecutor(),
    );

    final result = await session.run();

    expect(result, isA<CopilotCompleted>());
    expect(executed, hasLength(1));
    expect(executed.first.name, 'my_custom_tool');
    expect(executed.first.args, {'foo': 'bar'});
  });

  testWidgets('session falls back to executor when no handler registered',
      (tester) async {
    final executedActions = <CopilotAction>[];

    final session = CopilotSession(
      goal: 'Run unregistered tool',
      config: CopilotConfig(
        llm: FakeLlmAdapter(
          <LlmToolCall>[
            const LlmToolCall(
              id: 'c1',
              name: 'unknown_tool',
              arguments: <String, Object?>{},
            ),
          ],
        ),
        settleDelay: Duration.zero,
        customActions: const <String, CustomActionHandler>{},
      ),
      emit: (_) {},
      capture: _FakeCapture(),
      executor: _RecordingExecutor(executedActions),
    );

    final result = await session.run();

    expect(result, isA<CopilotCompleted>());
    expect(executedActions, hasLength(1));
    expect(executedActions.first, isA<UnknownAction>());
  });

  testWidgets('session continues after successful custom action', (tester) async {
    final session = CopilotSession(
      goal: 'Custom then done',
      config: CopilotConfig(
        llm: FakeLlmAdapter(
          <LlmToolCall>[
            const LlmToolCall(
              id: 'c1',
              name: 'custom_a',
              arguments: <String, Object?>{'x': 1},
            ),
            const LlmToolCall(
              id: 'c2',
              name: 'custom_b',
              arguments: <String, Object?>{'y': 2},
            ),
            const LlmToolCall(
              id: 'c3',
              name: 'done',
              arguments: <String, Object?>{'summary': 'All done.'},
            ),
          ],
        ),
        settleDelay: Duration.zero,
        customActions: {
          'custom_a': _FakeHandler(),
          'custom_b': _FakeHandler(),
        },
      ),
      emit: (_) {},
      capture: _FakeCapture(),
      executor: _FakeExecutor(),
    );

    final result = await session.run();

    expect(result, isA<CopilotCompleted>());
  });

  testWidgets('session stops on non-recoverable custom action failure',
      (tester) async {
    final session = CopilotSession(
      goal: 'Fail custom',
      config: CopilotConfig(
        llm: FakeLlmAdapter(
          <LlmToolCall>[
            const LlmToolCall(
              id: 'c1',
              name: 'failing_tool',
              arguments: <String, Object?>{},
            ),
          ],
        ),
        settleDelay: Duration.zero,
        customActions: {
          'failing_tool': _FailingHandler(),
        },
      ),
      emit: (_) {},
      capture: _FakeCapture(),
      executor: _FakeExecutor(),
    );

    final result = await session.run();

    expect(result, isA<CopilotFailed>());
    expect((result as CopilotFailed).reason, 'custom handler failure');
  });
}

class _FakeHandler implements CustomActionHandler {
  @override
  Future<ActionResult> execute(CustomAction action) async {
    return ActionResult.success('ok');
  }
}

class _RecordingHandler implements CustomActionHandler {
  _RecordingHandler(this.actions);

  final List<CustomAction> actions;

  @override
  Future<ActionResult> execute(CustomAction action) async {
    actions.add(action);
    return ActionResult.success('ok');
  }
}

class _FailingHandler implements CustomActionHandler {
  @override
  Future<ActionResult> execute(CustomAction action) async {
    return ActionResult.failure('custom handler failure', recoverable: false);
  }
}

class _FakeCapture extends SceneCapture {
  @override
  SceneGraph capture() {
    return SceneGraph(
      nodes: const <SceneNode>[
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

class _RecordingExecutor extends ActionExecutor {
  _RecordingExecutor(this.actions);

  final List<CopilotAction> actions;

  @override
  Future<ActionResult> execute(
      CopilotAction action, SceneGraph latestScene) async {
    actions.add(action);
    return ActionResult.success('ok');
  }
}
