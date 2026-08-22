import 'package:drift/drift.dart';

/// 一件被重复记录的事（如"喝水""看动漫"）。
/// 当前数值不落库，恒等于该计数器所有 Entry.delta 之和。
class Counters extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 30)();
  TextColumn get emoji => text().withDefault(const Constant('✨'))();

  /// 对应 AppColors.cardPalette 的下标。
  IntColumn get colorIndex => integer().withDefault(const Constant(0))();

  /// 卡片背景图的本地路径（应用私有目录内），null 表示纯色卡片。
  TextColumn get bgImagePath => text().nullable()();

  /// 计数单位：次 / 杯 / 集 / 页 …
  TextColumn get unit => text().withDefault(const Constant('次'))();

  /// 分类标签（如"动漫""生活"），空字符串表示未分类。
  TextColumn get tag => text().withDefault(const Constant(''))();

  /// 首页卡片上 + 按钮一次加多少。
  IntColumn get stepSize => integer().withDefault(const Constant(1))();

  /// 每日目标，null 表示未设置。
  IntColumn get dailyTarget => integer().nullable()();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  /// 最近一次计数时间，用于"最近使用"排序。
  DateTimeColumn get lastTouchedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 一次计数动作。删除记录即回退计数。
class Entries extends Table {
  TextColumn get id => text()();
  TextColumn get counterId => text().references(Counters, #id)();

  /// 增减量：+step、-1、手动调整时的差值。
  IntColumn get delta => integer()();

  /// 操作后的累计值，仅用于历史列表展示。
  IntColumn get valueAfter => integer()();

  /// 动作发生时间。
  DateTimeColumn get occurredAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
