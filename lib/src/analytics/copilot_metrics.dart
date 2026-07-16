/// Metrics captured for a single copilot run.
class CopilotMetrics {
  /// Creates copilot metrics.
  const CopilotMetrics({
    required this.goal,
    required this.startTime,
    required this.endTime,
    required this.steps,
    this.totalTokens = 0,
    required this.actionsExecuted,
    required this.succeeded,
    this.failureReason,
  });

  /// User goal for the run.
  final String goal;

  /// When the run started.
  final DateTime startTime;

  /// When the run ended.
  final DateTime endTime;

  /// Number of observe-plan-act cycles completed.
  final int steps;

  /// Total tokens consumed by LLM requests during the run.
  final int totalTokens;

  /// Number of UI actions executed.
  final int actionsExecuted;

  /// Whether the run completed successfully.
  final bool succeeded;

  /// Why the run failed, if it did.
  final String? failureReason;

  /// Elapsed wall-clock time for the run.
  Duration get duration => endTime.difference(startTime);
}
