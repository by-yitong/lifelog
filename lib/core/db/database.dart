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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // v2：新增 tag 列。
          if (from < 2) await m.addColumn(counters, counters.tag);
          // v3：新增 bgImagePath 列（卡片背景图）。
          if (from < 3) await m.addColumn(counters, counters.bgImagePath);
        },
      );

  static QueryExecutor _openConnection() => driftDatabase(name: 'lifelog');
}
