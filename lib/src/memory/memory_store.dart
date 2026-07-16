import 'memory_entry.dart';

/// Interface for storing and retrieving copilot run memories.
abstract class MemoryStore {
  /// Adds a memory entry.
  Future<void> add(MemoryEntry entry);

  /// Returns up to [limit] most recent entries (newest first).
  Future<List<MemoryEntry>> getRecent({int limit = 5});

  /// Removes all stored entries.
  Future<void> clear();
}
