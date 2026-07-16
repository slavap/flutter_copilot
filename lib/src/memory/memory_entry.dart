/// A single memory record from a completed copilot run.
class MemoryEntry {
  /// Creates a memory entry.
  const MemoryEntry({
    required this.goal,
    required this.result,
    required this.timestamp,
  });

  /// The user goal for the run.
  final String goal;

  /// Summary or reason returned by the run.
  final String result;

  /// When this memory was recorded.
  final DateTime timestamp;
}
