import 'copilot_metrics.dart';

/// Pre-computed summary statistics over recorded [CopilotMetrics].
class MetricsSummary {
  /// Creates a metrics summary.
  const MetricsSummary({
    required this.totalRuns,
    required this.successRate,
    required this.averageSteps,
    required this.averageDuration,
    required this.averageTokens,
    required this.averageActionsExecuted,
  });

  /// Total number of recorded runs.
  final int totalRuns;

  /// Fraction of runs that succeeded (0.0–1.0).
  final double successRate;

  /// Average number of steps across all runs.
  final double averageSteps;

  /// Average wall-clock duration across all runs.
  final Duration averageDuration;

  /// Average token usage across all runs.
  final double averageTokens;

  /// Average number of actions executed across all runs.
  final double averageActionsExecuted;
}

/// Stores [CopilotMetrics] history and computes summaries.
class MetricsCollector {
  final List<CopilotMetrics> _history = [];

  /// All recorded metrics in insertion order.
  List<CopilotMetrics> get history =>
      List<CopilotMetrics>.unmodifiable(_history);

  /// Records a completed run's metrics.
  void record(CopilotMetrics metrics) {
    _history.add(metrics);
  }

  /// Pre-computed summary over all recorded metrics.
  MetricsSummary get summary {
    if (_history.isEmpty) {
      return const MetricsSummary(
        totalRuns: 0,
        successRate: 0.0,
        averageSteps: 0.0,
        averageDuration: Duration.zero,
        averageTokens: 0.0,
        averageActionsExecuted: 0.0,
      );
    }

    final total = _history.length;
    final succeededCount =
        _history.where((m) => m.succeeded).length;
    final totalSteps = _history.fold<int>(0, (sum, m) => sum + m.steps);
    final totalTokens =
        _history.fold<int>(0, (sum, m) => sum + m.totalTokens);
    final totalActions =
        _history.fold<int>(0, (sum, m) => sum + m.actionsExecuted);
    final totalDurationMs =
        _history.fold<int>(0, (sum, m) => sum + m.duration.inMilliseconds);

    return MetricsSummary(
      totalRuns: total,
      successRate: succeededCount / total,
      averageSteps: totalSteps / total,
      averageDuration: Duration(milliseconds: (totalDurationMs / total).round()),
      averageTokens: totalTokens / total,
      averageActionsExecuted: totalActions / total,
    );
  }

  /// Clears all recorded metrics.
  void reset() {
    _history.clear();
  }
}
