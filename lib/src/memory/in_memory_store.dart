import 'memory_entry.dart';
import 'memory_store.dart';

/// An in-memory implementation of [MemoryStore].
class InMemoryStore implements MemoryStore {
  final List<MemoryEntry> _entries = [];

  @override
  Future<void> add(MemoryEntry entry) async => _entries.add(entry);

  @override
  Future<List<MemoryEntry>> getRecent({int limit = 5}) async {
    final sorted = List<MemoryEntry>.from(_entries)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(limit).toList();
  }

  @override
  Future<void> clear() async => _entries.clear();
}
