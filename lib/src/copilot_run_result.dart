/// Result returned by [CopilotController.run].
///
/// Use pattern matching to handle each outcome:
///
/// ```dart
/// final result = await controller.run('Tap Settings');
/// switch (result) {
///   case CopilotCompleted(:final summary):
///     print('Done: $summary');
///   case CopilotFailed(:final reason):
///     print('Failed: $reason');
///   case CopilotCancelled():
///     print('User denied confirmation');
///   case CopilotMaxStepsExceeded(:final steps):
///     print('Gave up after $steps steps');
/// }
/// ```
sealed class CopilotRunResult {
  /// Creates a run result.
  const CopilotRunResult();
}

/// The goal was completed.
///
/// Contains a human-readable [summary] from the model describing what was
/// accomplished.
class CopilotCompleted extends CopilotRunResult {
  /// Creates a completed result with a human-readable [summary].
  const CopilotCompleted(this.summary);

  /// Summary returned by the model.
  final String summary;
}

/// The run stopped because it could not continue.
///
/// This can happen when the LLM returns an invalid tool call, when an
/// action fails irreversibly, or when the safety policy blocks execution.
class CopilotFailed extends CopilotRunResult {
  /// Creates a failed result with a [reason].
  const CopilotFailed(this.reason);

  /// Reason the run failed.
  final String reason;
}

/// The run was cancelled.
///
/// Occurs when the user denies a confirmation request or when the
/// [CopilotConfirmationCallback] returns `false`.
class CopilotCancelled extends CopilotRunResult {
  /// Creates a cancelled result.
  const CopilotCancelled();
}

/// The run reached the configured maximum step count.
///
/// The model did not call [DoneAction] or [FailAction] within
/// [CopilotConfig.maxSteps] observe-plan-act cycles.
class CopilotMaxStepsExceeded extends CopilotRunResult {
  /// Creates a max-steps result.
  const CopilotMaxStepsExceeded(this.steps);

  /// Number of steps attempted.
  final int steps;
}
