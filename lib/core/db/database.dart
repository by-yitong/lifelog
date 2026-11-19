import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'database.g.dart';

// 时间戳以文本（毫秒精度）存储，见 build.yaml 的
// store_date_time_values_as_text —— 避免同一秒内的记录排序抖动。
@DriftDatabase(tables: [Counters, Entries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 供测试注入内存数据库。
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // v2：新增 tag 列。
          if (from < 2) await m.addColumn(counters, counters.tag);
          // v3：新增 bgImagePath 列（卡片背景图）。
          if (from < 3) await m.addColumn(counters, counters.bgImagePath);
          // v4：新增 isInitial 列，并给 v4 之前创建的"初始值"记录补标记
          //（它们是建计数器时写入的首条记录：正增量、delta==valueAfter、
          //  发生时间与计数器创建时间几乎相同）。
          if (from < 4) {
            await m.addColumn(entries, entries.isInitial);
            final allCounters = await select(counters).get();
            for (final c in allCounters) {
              final first = await (select(entries)
                    ..where((e) => e.counterId.equals(c.id))
                    ..orderBy([(e) => OrderingTerm.asc(e.rowId)])
                    ..limit(1))
                  .getSingleOrNull();
              if (first == null) continue;
              if (first.delta > 0 &&
                  first.delta == first.valueAfter &&
                  first.occurredAt
                          .difference(c.createdAt)
                          .abs() <
                      const Duration(seconds: 10)) {
                await (update(entries)
                      ..where((e) => e.id.equals(first.id)))
                    .write(EntriesCompanion(isInitial: const Value(true)));
              }
            }
          }
        },
      );

  static QueryExecutor _openConnection() => driftDatabase(name: 'lifelog');
}
