import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_copilot/flutter_copilot.dart';

void main() {
  test('in-memory store adds and retrieves', () async {
    final store = InMemoryStore();
    await store.add(MemoryEntry(
      goal: 'open settings',
      result: 'done',
      timestamp: DateTime.now(),
    ));

    final recent = await store.getRecent();
    expect(recent, hasLength(1));
    expect(recent.first.goal, 'open settings');
  });

  test('getRecent returns newest first', () async {
    final store = InMemoryStore();
    await store.add(MemoryEntry(
      goal: 'first',
      result: 'done',
      timestamp: DateTime(2026, 1, 1),
    ));
    await store.add(MemoryEntry(
      goal: 'second',
      result: 'done',
      timestamp: DateTime(2026, 1, 2),
    ));

    final recent = await store.getRecent(limit: 1);
    expect(recent.first.goal, 'second');
  });

  test('clear removes all entries', () async {
    final store = InMemoryStore();
    await store.add(MemoryEntry(
      goal: 'test',
      result: 'done',
      timestamp: DateTime.now(),
    ));
    await store.clear();

    final recent = await store.getRecent();
    expect(recent, isEmpty);
  });
}
