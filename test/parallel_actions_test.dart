import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_copilot/flutter_copilot.dart';

void main() {
  testWidgets('executes independent type_text actions in parallel',
      (tester) async {
    final executed = <CopilotAction>[];

    final session = CopilotSession(
      goal: 'Fill two fields',
      config: CopilotConfig(
        llm: _BatchTypeTextAdapter(),
        settleDelay: Duration.zero,
      ),
      emit: (_) {},
      capture: _TwoNodeCapture(),
      executor: _RecordingExecutor(executed),
    );

    final result = await session.run();

    expect(result, isA<CopilotCompleted>());
    expect(executed, hasLength(2));
    expect(executed[0], isA<TypeTextAction>());
    expect(executed[1], isA<TypeTextAction>());
  });

  testWidgets('executes independent tap actions in parallel', (tester) async {
    final executed = <CopilotAction>[];

    final session = CopilotSession(
      goal: 'Tap two buttons',
      config: CopilotConfig(
        llm: _BatchTapAdapter(),
        settleDelay: Duration.zero,
      ),
      emit: (_) {},
      capture: _TwoButtonCapture(),
      executor: _RecordingExecutor(executed),
    );

    final result = await session.run();

    expect(result, isA<CopilotCompleted>());
    expect(executed, hasLength(2));
    expect(executed[0], isA<TapAction>());
    expect(executed[1], isA<TapAction>());
  });

  testWidgets('executes mixed independent and dependent actions correctly',
      (tester) async {
    final executed = <String>[];

    final session = CopilotSession(
      goal: 'Type then scroll',
      config: CopilotConfig(
        llm: _MixedActionsAdapter(),
        settleDelay: Duration.zero,
      ),
      emit: (_) {},
      capture: _TwoNodeCapture(),
      executor: _OrderingExecutor(executed),
    );

    final result = await session.run();

    expect(result, isA<CopilotCompleted>());
    expect(executed, contains('type_text'));
    expect(executed, contains('scroll'));
  });
}

class _TwoNodeCapture extends SceneCapture {
  @override
  SceneGraph capture() {
    return SceneGraph(
      nodes: const <SceneNode>[
        SceneNode(
          id: 'n1',
          semanticsId: 1,
          rect: Rect.fromLTWH(0, 0, 120, 48),
          label: 'First field',
          actions: <SceneAction>{SceneAction.tap},
        ),
        SceneNode(
          id: 'n2',
          semanticsId: 2,
          rect: Rect.fromLTWH(0, 60, 120, 48),
          label: 'Second field',
          actions: <SceneAction>{SceneAction.tap},
        ),
      ],
      idToSemanticsId: const <String, int>{'n1': 1, 'n2': 2},
    );
  }
}

class _TwoButtonCapture extends SceneCapture {
  @override
  SceneGraph capture() {
    return SceneGraph(
      nodes: const <SceneNode>[
        SceneNode(
          id: 'btn1',
          semanticsId: 1,
          rect: Rect.fromLTWH(0, 0, 120, 48),
          label: 'Button A',
          actions: <SceneAction>{SceneAction.tap},
        ),
        SceneNode(
          id: 'btn2',
          semanticsId: 2,
          rect: Rect.fromLTWH(0, 60, 120, 48),
          label: 'Button B',
          actions: <SceneAction>{SceneAction.tap},
        ),
      ],
      idToSemanticsId: const <String, int>{'btn1': 1, 'btn2': 2},
    );
  }
}

class _BatchTypeTextAdapter implements LlmAdapter {
  var _done = false;

  @override
  Future<LlmResponse> complete({
    required List<LlmMessage> messages,
    required List<LlmTool> tools,
  }) async {
    if (_done) {
      return const LlmResponse(
        toolCall: LlmToolCall(
          id: 'done',
          name: 'done',
          arguments: <String, Object?>{'summary': 'Finished.'},
        ),
      );
    }
    _done = true;
    return const LlmResponse(
      toolCalls: <LlmToolCall>[
        LlmToolCall(
          id: 'c1',
          name: 'type_text',
          arguments: <String, Object?>{'id': 'n1', 'text': 'Hello'},
        ),
        LlmToolCall(
          id: 'c2',
          name: 'type_text',
          arguments: <String, Object?>{'id': 'n2', 'text': 'World'},
        ),
      ],
    );
  }
}

class _BatchTapAdapter implements LlmAdapter {
  var _done = false;

  @override
  Future<LlmResponse> complete({
    required List<LlmMessage> messages,
    required List<LlmTool> tools,
  }) async {
    if (_done) {
      return const LlmResponse(
        toolCall: LlmToolCall(
          id: 'done',
          name: 'done',
          arguments: <String, Object?>{'summary': 'Finished.'},
        ),
      );
    }
    _done = true;
    return const LlmResponse(
      toolCalls: <LlmToolCall>[
        LlmToolCall(
          id: 'c1',
          name: 'tap',
          arguments: <String, Object?>{'id': 'btn1'},
        ),
        LlmToolCall(
          id: 'c2',
          name: 'tap',
          arguments: <String, Object?>{'id': 'btn2'},
        ),
      ],
    );
  }
}

class _MixedActionsAdapter implements LlmAdapter {
  var _step = 0;

  @override
  Future<LlmResponse> complete({
    required List<LlmMessage> messages,
    required List<LlmTool> tools,
  }) async {
    _step++;
    switch (_step) {
      case 1:
        return const LlmResponse(
          toolCalls: <LlmToolCall>[
            LlmToolCall(
              id: 'c1',
              name: 'type_text',
              arguments: <String, Object?>{'id': 'n1', 'text': 'Hello'},
            ),
            LlmToolCall(
              id: 'c2',
              name: 'scroll',
              arguments: <String, Object?>{
                'id': 'n1',
                'direction': 'down',
              },
            ),
          ],
        );
      default:
        return const LlmResponse(
          toolCall: LlmToolCall(
            id: 'done',
            name: 'done',
            arguments: <String, Object?>{'summary': 'Finished.'},
          ),
        );
    }
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

class _OrderingExecutor extends ActionExecutor {
  _OrderingExecutor(this.log);
  final List<String> log;

  @override
  Future<ActionResult> execute(
      CopilotAction action, SceneGraph latestScene) async {
    log.add(action.name);
    return ActionResult.success('ok');
  }
}
