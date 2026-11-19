import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/core/db/database.dart';
import 'package:lifelog/features/counters/data/counter_repository.dart';

void main() {
  late AppDatabase db;
  late CounterRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CounterRepository(db);
  });

  tearDown(() async => db.close());

  Future<String> seedCounter({int step = 1}) async {
    final id = 'c-$step';
    await repo.createCounter(
      CountersCompanion.insert(
        id: id,
        name: '喝水',
        unit: const Value('杯'),
        stepSize: Value(step),
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    return id;
  }

  test('addEntry 记录 valueAfter 并更新最近使用时间', () async {
    final id = await seedCounter();

    await repo.addEntry(counterId: id, delta: 1);
    await repo.addEntry(counterId: id, delta: 3);

    final entries = await repo.watchEntriesOf(id).first;
    expect(entries.length, 2);
    expect(entries.first.valueAfter, 4); // 新→旧
    expect(await repo.currentValue(id), 4);

    final counter = await (db.select(db.counters)).getSingle();
    expect(counter.lastTouchedAt, isNotNull);
  });

  test('deleteEntry 回退计数，restoreEntry 撤销删除', () async {
    final id = await seedCounter();
    await repo.addEntry(counterId: id, delta: 2);
    await repo.addEntry(counterId: id, delta: 2);
    expect(await repo.currentValue(id), 4);

    final entry = (await repo.watchEntriesOf(id).first).first;
    await repo.deleteEntry(entry);
    expect(await repo.currentValue(id), 2);

    await repo.restoreEntry(entry);
    expect(await repo.currentValue(id), 4);
  });

  test('deleteCounter 连带删除全部记录', () async {
    final id = await seedCounter();
    await repo.addEntry(counterId: id, delta: 5);

    await repo.deleteCounter(id);

    expect(await db.select(db.counters).get(), isEmpty);
    expect(await db.select(db.entries).get(), isEmpty);
  });

  test('createCounter 支持初始值：事务内写入首条记录并标记 isInitial', () async {
    const id = 'c-init';
    await repo.createCounter(
      CountersCompanion.insert(
        id: id,
        name: '看动漫',
        unit: const Value('集'),
        createdAt: DateTime(2026, 1, 1),
      ),
      initialValue: 235,
    );

    expect(await repo.currentValue(id), 235); // 总数包含初始值
    final entries = await repo.watchEntriesOf(id).first;
    expect(entries, hasLength(1));
    expect(entries.single.delta, 235);
    expect(entries.single.valueAfter, 235);
    expect(entries.single.occurredAt, DateTime(2026, 1, 1));
    expect(entries.single.isInitial, isTrue);

    final counter = await (db.select(db.counters)).getSingle();
    expect(counter.lastTouchedAt, DateTime(2026, 1, 1));
  });

  test('watchCounters 按 archived 过滤', () async {
    final id = await seedCounter();
    expect((await repo.watchCounters().first).length, 1);

    await repo.setArchived(id, true);
    expect(await repo.watchCounters().first, isEmpty);
    expect((await repo.watchCounters(archived: true).first).length, 1);
  });
}
