import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/database.dart';

/// 计数器与记录的数据访问。数值 = 该计数器全部 Entry.delta 之和。
class CounterRepository {
  final AppDatabase _db;

  CounterRepository(this._db);

  static const _uuid = Uuid();

  Stream<List<Counter>> watchCounters({bool archived = false}) {
    return (_db.select(_db.counters)
          ..where((c) => c.archived.equals(archived)))
        .watch();
  }

  Stream<List<Entry>> watchAllEntries() => _db.select(_db.entries).watch();

  Stream<List<Entry>> watchEntriesOf(String counterId) {
    return (_db.select(_db.entries)
          ..where((e) => e.counterId.equals(counterId))
          ..orderBy([
            (e) => OrderingTerm.desc(e.occurredAt),
            (e) => OrderingTerm.desc(e.rowId),
          ]))
        .watch();
  }

  Future<void> createCounter(CountersCompanion c) =>
      _db.into(_db.counters).insert(c);

  Future<void> updateCounter(CountersCompanion c) =>
      (_db.update(_db.counters)..where((x) => x.id.equals(c.id.value)))
          .write(c);

  Future<void> setPinned(String id, bool pinned) =>
      (_db.update(_db.counters)..where((c) => c.id.equals(id)))
          .write(CountersCompanion(pinned: Value(pinned)));

  Future<void> setArchived(String id, bool archived) =>
      (_db.update(_db.counters)..where((c) => c.id.equals(id)))
          .write(CountersCompanion(archived: Value(archived)));

  /// 删除计数器及其全部记录（不可撤销，调用方需先确认）。
  Future<void> deleteCounter(String id) {
    return _db.transaction(() async {
      await (_db.delete(_db.entries)..where((e) => e.counterId.equals(id)))
          .go();
      await (_db.delete(_db.counters)..where((c) => c.id.equals(id))).go();
    });
  }

  Future<int> currentValue(String counterId) async {
    final sum = _db.entries.delta.sum();
    final query = _db.selectOnly(_db.entries)
      ..addColumns([sum])
      ..where(_db.entries.counterId.equals(counterId));
    final row = await query.getSingle();
    return row.read(sum) ?? 0;
  }

  /// 记一次计数（+step / -1 / 手动调整的差值），并更新最近使用时间。
  /// 返回写入的记录，调用方可用它做精确"撤销"。
  Future<Entry> addEntry({
    required String counterId,
    required int delta,
    DateTime? at,
  }) {
    final now = DateTime.now();
    return _db.transaction(() async {
      final current = await currentValue(counterId);
      final entry = Entry(
        id: _uuid.v4(),
        counterId: counterId,
        delta: delta,
        valueAfter: current + delta,
        occurredAt: at ?? now,
      );
      await _db.into(_db.entries).insert(entry);
      await (_db.update(_db.counters)..where((c) => c.id.equals(counterId)))
          .write(CountersCompanion(lastTouchedAt: Value(at ?? now)));
      return entry;
    });
  }

  /// 删除单条记录（计数随之回退）。
  Future<void> deleteEntry(Entry entry) =>
      (_db.delete(_db.entries)..where((e) => e.id.equals(entry.id))).go();

  /// 编辑一条记录（数量 / 时间）：按"删旧插新"实现，
  /// 总数恒等于全部 delta 之和，天然正确；不改动最近使用时间。
  Future<void> updateEntry(
    Entry entry, {
    int? delta,
    DateTime? occurredAt,
  }) async {
    final newDelta = delta ?? entry.delta;
    final newAt = occurredAt ?? entry.occurredAt;
    await _db.transaction(() async {
      await (_db.delete(_db.entries)..where((e) => e.id.equals(entry.id)))
          .go();
      final current = await currentValue(entry.counterId);
      await _db.into(_db.entries).insert(
            EntriesCompanion.insert(
              id: _uuid.v4(),
              counterId: entry.counterId,
              delta: newDelta,
              valueAfter: current + newDelta,
              occurredAt: newAt,
            ),
          );
    });
  }

  /// 撤销删除：原样写回记录。
  Future<void> restoreEntry(Entry entry) =>
      _db.into(_db.entries).insert(entry, mode: InsertMode.insertOrReplace);
}
