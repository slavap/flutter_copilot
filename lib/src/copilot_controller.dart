import 'dart:async';

import 'package:flutter/widgets.dart';

import 'logging/copilot_event.dart';
import 'copilot_config.dart';
import 'copilot_run_result.dart';
import 'copilot_session.dart';

/// Runs natural-language goals against the current Flutter UI.
///
/// The controller owns the observe-plan-act loop: it captures the screen
/// via the semantics tree, sends it to an LLM, and executes the returned
/// actions. At most one [run] can be active at a time.
///
/// ```dart
/// final controller = CopilotController(CopilotConfig(llm: myLlm));
/// final result = await controller.run('Tap the settings icon');
/// switch (result) {
///   case CopilotCompleted(:final summary): print(summary);
///   case CopilotFailed(:final reason): print('Failed: $reason');
///   case CopilotCancelled(): print('Cancelled');
///   case CopilotMaxStepsExceeded(:final steps): print('Hit $steps steps');
/// }
/// controller.dispose();
/// ```
class CopilotController {
  /// Creates a controller with [config].
  CopilotController(this.config);

  /// Runtime configuration used for new runs.
  final CopilotConfig config;

  final _events = StreamController<CopilotEvent>.broadcast();

  Future<CopilotRunResult>? _activeRun;

  /// Broadcast stream of progress and lifecycle events.
  ///
  /// Emits [CopilotStarted], [CopilotSceneCaptured], [CopilotLlmRequestStarted],
  /// and other lifecycle events while a run is in progress.
  Stream<CopilotEvent> get events => _events.stream;

  /// Looks up the nearest controller provided by [CopilotApp].
  ///
  /// Throws a [StateError] if no [CopilotApp] ancestor exists in the widget
  /// tree. This is typically called from a widget's build method or an
  /// event handler.
  static CopilotController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CopilotScope>();
    if (scope == null) {
      throw StateError(
          'CopilotController.of() called without a CopilotApp ancestor.');
    }
    return scope.controller;
  }

  /// Runs [goal] until completion, failure, or max steps.
  ///
  /// The observe-plan-act loop runs up to [CopilotConfig.maxSteps] times.
  /// Returns a [CopilotRunResult] indicating the outcome. Only one run can
  /// be active at a time; concurrent calls return [CopilotFailed].
  Future<CopilotRunResult> run(String goal) {
    final trimmedGoal = goal.trim();
    if (trimmedGoal.isEmpty) {
      return Future<CopilotRunResult>.value(
          const CopilotFailed('Goal cannot be empty.'));
    }
    if (_activeRun != null) {
      return Future<CopilotRunResult>.value(
          const CopilotFailed('A copilot run is already active.'));
    }
    final session = CopilotSession(
      goal: trimmedGoal,
      config: config,
      emit: _emit,
    );
    final run = session.run();
    _activeRun = run;
    return run.whenComplete(() {
      if (_activeRun == run) {
        _activeRun = null;
      }
    });
  }

  /// Releases event stream resources.
  ///
  /// Must be called when the controller is no longer needed to avoid
  /// stream leaks. Typically called in [State.dispose].
  void dispose() {
    _events.close();
  }

  void _emit(CopilotEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
    config.onEvent?.call(event);
    if (config.debugLogging) {
      debugPrint('[flutter_copilot] ${_describeEvent(event)}');
    }
  }

  String _describeEvent(CopilotEvent event) {
    return switch (event) {
      CopilotStarted(:final goal) => 'started: $goal',
      CopilotSceneCaptured(:final scene) =>
        'captured ${scene.nodes.length} nodes',
      CopilotLlmRequestStarted(:final step) =>
        'llm request started: step $step',
      CopilotLlmRequestSucceeded(:final step) =>
        'llm request succeeded: step $step',
      CopilotLlmRequestFailed(:final step, :final message) =>
        'llm request failed: step $step: $message',
      CopilotActionPlanned(:final action) => 'planned: ${action.runtimeType}',
      CopilotActionExecuted(:final result) =>
        'action ${result.success ? 'succeeded' : 'failed'}: ${result.message}',
      CopilotConfirmationRequested(:final reason) =>
        'confirmation requested: $reason',
      CopilotConfirmationResolved(:final approved) =>
        'confirmation ${approved ? 'approved' : 'denied'}',
      CopilotFinished(:final message) => 'finished: $message',
    };
  }
}

/// Inherited widget that stores the nearest [CopilotController].
///
/// Created by [CopilotApp] and injected into the widget tree. Use
/// [CopilotController.of] to retrieve the controller from descendant widgets.
class CopilotScope extends InheritedWidget {
  /// Provides [controller] to a subtree.
  const CopilotScope({
    required this.controller,
    required super.child,
    super.key,
  });

  /// Controller exposed to descendants via [CopilotController.of].
  final CopilotController controller;

  @override
  bool updateShouldNotify(CopilotScope oldWidget) =>
      controller != oldWidget.controller;
}
