// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CountersTable extends Counters with TableInfo<$CountersTable, Counter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CountersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 30,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('✨'),
  );
  static const VerificationMeta _colorIndexMeta = const VerificationMeta(
    'colorIndex',
  );
  @override
  late final GeneratedColumn<int> colorIndex = GeneratedColumn<int>(
    'color_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bgImagePathMeta = const VerificationMeta(
    'bgImagePath',
  );
  @override
  late final GeneratedColumn<String> bgImagePath = GeneratedColumn<String>(
    'bg_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('次'),
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _stepSizeMeta = const VerificationMeta(
    'stepSize',
  );
  @override
  late final GeneratedColumn<int> stepSize = GeneratedColumn<int>(
    'step_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _dailyTargetMeta = const VerificationMeta(
    'dailyTarget',
  );
  @override
  late final GeneratedColumn<int> dailyTarget = GeneratedColumn<int>(
    'daily_target',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastTouchedAtMeta = const VerificationMeta(
    'lastTouchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastTouchedAt =
      GeneratedColumn<DateTime>(
        'last_touched_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    emoji,
    colorIndex,
    bgImagePath,
    unit,
    tag,
    stepSize,
    dailyTarget,
    pinned,
    archived,
    lastTouchedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'counters';
  @override
  VerificationContext validateIntegrity(
    Insertable<Counter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    }
    if (data.containsKey('color_index')) {
      context.handle(
        _colorIndexMeta,
        colorIndex.isAcceptableOrUnknown(data['color_index']!, _colorIndexMeta),
      );
    }
    if (data.containsKey('bg_image_path')) {
      context.handle(
        _bgImagePathMeta,
        bgImagePath.isAcceptableOrUnknown(
          data['bg_image_path']!,
          _bgImagePathMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    }
    if (data.containsKey('step_size')) {
      context.handle(
        _stepSizeMeta,
        stepSize.isAcceptableOrUnknown(data['step_size']!, _stepSizeMeta),
      );
    }
    if (data.containsKey('daily_target')) {
      context.handle(
        _dailyTargetMeta,
        dailyTarget.isAcceptableOrUnknown(
          data['daily_target']!,
          _dailyTargetMeta,
        ),
      );
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('last_touched_at')) {
      context.handle(
        _lastTouchedAtMeta,
        lastTouchedAt.isAcceptableOrUnknown(
          data['last_touched_at']!,
          _lastTouchedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Counter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Counter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
      colorIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_index'],
      )!,
      bgImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bg_image_path'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      )!,
      stepSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step_size'],
      )!,
      dailyTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_target'],
      ),
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      lastTouchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_touched_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CountersTable createAlias(String alias) {
    return $CountersTable(attachedDatabase, alias);
  }
}

class Counter extends DataClass implements Insertable<Counter> {
  final String id;
  final String name;
  final String emoji;

  /// 对应 AppColors.cardPalette 的下标。
  final int colorIndex;

  /// 卡片背景图的本地路径（应用私有目录内），null 表示纯色卡片。
  final String? bgImagePath;

  /// 计数单位：次 / 杯 / 集 / 页 …
  final String unit;

  /// 分类标签（如"动漫""生活"），空字符串表示未分类。
  final String tag;

  /// 首页卡片上 + 按钮一次加多少。
  final int stepSize;

  /// 每日目标，null 表示未设置。
  final int? dailyTarget;
  final bool pinned;
  final bool archived;

  /// 最近一次计数时间，用于"最近使用"排序。
  final DateTime? lastTouchedAt;
  final DateTime createdAt;
  const Counter({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorIndex,
    this.bgImagePath,
    required this.unit,
    required this.tag,
    required this.stepSize,
    this.dailyTarget,
    required this.pinned,
    required this.archived,
    this.lastTouchedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['emoji'] = Variable<String>(emoji);
    map['color_index'] = Variable<int>(colorIndex);
    if (!nullToAbsent || bgImagePath != null) {
      map['bg_image_path'] = Variable<String>(bgImagePath);
    }
    map['unit'] = Variable<String>(unit);
    map['tag'] = Variable<String>(tag);
    map['step_size'] = Variable<int>(stepSize);
    if (!nullToAbsent || dailyTarget != null) {
      map['daily_target'] = Variable<int>(dailyTarget);
    }
    map['pinned'] = Variable<bool>(pinned);
    map['archived'] = Variable<bool>(archived);
    if (!nullToAbsent || lastTouchedAt != null) {
      map['last_touched_at'] = Variable<DateTime>(lastTouchedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CountersCompanion toCompanion(bool nullToAbsent) {
    return CountersCompanion(
      id: Value(id),
      name: Value(name),
      emoji: Value(emoji),
      colorIndex: Value(colorIndex),
      bgImagePath: bgImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(bgImagePath),
      unit: Value(unit),
      tag: Value(tag),
      stepSize: Value(stepSize),
      dailyTarget: dailyTarget == null && nullToAbsent
          ? const Value.absent()
          : Value(dailyTarget),
      pinned: Value(pinned),
      archived: Value(archived),
      lastTouchedAt: lastTouchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTouchedAt),
      createdAt: Value(createdAt),
    );
  }

  factory Counter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Counter(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      emoji: serializer.fromJson<String>(json['emoji']),
      colorIndex: serializer.fromJson<int>(json['colorIndex']),
      bgImagePath: serializer.fromJson<String?>(json['bgImagePath']),
      unit: serializer.fromJson<String>(json['unit']),
      tag: serializer.fromJson<String>(json['tag']),
      stepSize: serializer.fromJson<int>(json['stepSize']),
      dailyTarget: serializer.fromJson<int?>(json['dailyTarget']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      archived: serializer.fromJson<bool>(json['archived']),
      lastTouchedAt: serializer.fromJson<DateTime?>(json['lastTouchedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'emoji': serializer.toJson<String>(emoji),
      'colorIndex': serializer.toJson<int>(colorIndex),
      'bgImagePath': serializer.toJson<String?>(bgImagePath),
      'unit': serializer.toJson<String>(unit),
      'tag': serializer.toJson<String>(tag),
      'stepSize': serializer.toJson<int>(stepSize),
      'dailyTarget': serializer.toJson<int?>(dailyTarget),
      'pinned': serializer.toJson<bool>(pinned),
      'archived': serializer.toJson<bool>(archived),
      'lastTouchedAt': serializer.toJson<DateTime?>(lastTouchedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Counter copyWith({
    String? id,
    String? name,
    String? emoji,
    int? colorIndex,
    Value<String?> bgImagePath = const Value.absent(),
    String? unit,
    String? tag,
    int? stepSize,
    Value<int?> dailyTarget = const Value.absent(),
    bool? pinned,
    bool? archived,
    Value<DateTime?> lastTouchedAt = const Value.absent(),
    DateTime? createdAt,
  }) => Counter(
    id: id ?? this.id,
    name: name ?? this.name,
    emoji: emoji ?? this.emoji,
    colorIndex: colorIndex ?? this.colorIndex,
    bgImagePath: bgImagePath.present ? bgImagePath.value : this.bgImagePath,
    unit: unit ?? this.unit,
    tag: tag ?? this.tag,
    stepSize: stepSize ?? this.stepSize,
    dailyTarget: dailyTarget.present ? dailyTarget.value : this.dailyTarget,
    pinned: pinned ?? this.pinned,
    archived: archived ?? this.archived,
    lastTouchedAt: lastTouchedAt.present
        ? lastTouchedAt.value
        : this.lastTouchedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  Counter copyWithCompanion(CountersCompanion data) {
    return Counter(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      colorIndex: data.colorIndex.present
          ? data.colorIndex.value
          : this.colorIndex,
      bgImagePath: data.bgImagePath.present
          ? data.bgImagePath.value
          : this.bgImagePath,
      unit: data.unit.present ? data.unit.value : this.unit,
      tag: data.tag.present ? data.tag.value : this.tag,
      stepSize: data.stepSize.present ? data.stepSize.value : this.stepSize,
      dailyTarget: data.dailyTarget.present
          ? data.dailyTarget.value
          : this.dailyTarget,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      archived: data.archived.present ? data.archived.value : this.archived,
      lastTouchedAt: data.lastTouchedAt.present
          ? data.lastTouchedAt.value
          : this.lastTouchedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Counter(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('bgImagePath: $bgImagePath, ')
          ..write('unit: $unit, ')
          ..write('tag: $tag, ')
          ..write('stepSize: $stepSize, ')
          ..write('dailyTarget: $dailyTarget, ')
          ..write('pinned: $pinned, ')
          ..write('archived: $archived, ')
          ..write('lastTouchedAt: $lastTouchedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    emoji,
    colorIndex,
    bgImagePath,
    unit,
    tag,
    stepSize,
    dailyTarget,
    pinned,
    archived,
    lastTouchedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Counter &&
          other.id == this.id &&
          other.name == this.name &&
          other.emoji == this.emoji &&
          other.colorIndex == this.colorIndex &&
          other.bgImagePath == this.bgImagePath &&
          other.unit == this.unit &&
          other.tag == this.tag &&
          other.stepSize == this.stepSize &&
          other.dailyTarget == this.dailyTarget &&
          other.pinned == this.pinned &&
          other.archived == this.archived &&
          other.lastTouchedAt == this.lastTouchedAt &&
          other.createdAt == this.createdAt);
}

class CountersCompanion extends UpdateCompanion<Counter> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> emoji;
  final Value<int> colorIndex;
  final Value<String?> bgImagePath;
  final Value<String> unit;
  final Value<String> tag;
  final Value<int> stepSize;
  final Value<int?> dailyTarget;
  final Value<bool> pinned;
  final Value<bool> archived;
  final Value<DateTime?> lastTouchedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CountersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.emoji = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.bgImagePath = const Value.absent(),
    this.unit = const Value.absent(),
    this.tag = const Value.absent(),
    this.stepSize = const Value.absent(),
    this.dailyTarget = const Value.absent(),
    this.pinned = const Value.absent(),
    this.archived = const Value.absent(),
    this.lastTouchedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CountersCompanion.insert({
    required String id,
    required String name,
    this.emoji = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.bgImagePath = const Value.absent(),
    this.unit = const Value.absent(),
    this.tag = const Value.absent(),
    this.stepSize = const Value.absent(),
    this.dailyTarget = const Value.absent(),
    this.pinned = const Value.absent(),
    this.archived = const Value.absent(),
    this.lastTouchedAt = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Counter> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? emoji,
    Expression<int>? colorIndex,
    Expression<String>? bgImagePath,
    Expression<String>? unit,
    Expression<String>? tag,
    Expression<int>? stepSize,
    Expression<int>? dailyTarget,
    Expression<bool>? pinned,
    Expression<bool>? archived,
    Expression<DateTime>? lastTouchedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (emoji != null) 'emoji': emoji,
      if (colorIndex != null) 'color_index': colorIndex,
      if (bgImagePath != null) 'bg_image_path': bgImagePath,
      if (unit != null) 'unit': unit,
      if (tag != null) 'tag': tag,
      if (stepSize != null) 'step_size': stepSize,
      if (dailyTarget != null) 'daily_target': dailyTarget,
      if (pinned != null) 'pinned': pinned,
      if (archived != null) 'archived': archived,
      if (lastTouchedAt != null) 'last_touched_at': lastTouchedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CountersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? emoji,
    Value<int>? colorIndex,
    Value<String?>? bgImagePath,
    Value<String>? unit,
    Value<String>? tag,
    Value<int>? stepSize,
    Value<int?>? dailyTarget,
    Value<bool>? pinned,
    Value<bool>? archived,
    Value<DateTime?>? lastTouchedAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CountersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorIndex: colorIndex ?? this.colorIndex,
      bgImagePath: bgImagePath ?? this.bgImagePath,
      unit: unit ?? this.unit,
      tag: tag ?? this.tag,
      stepSize: stepSize ?? this.stepSize,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      pinned: pinned ?? this.pinned,
      archived: archived ?? this.archived,
      lastTouchedAt: lastTouchedAt ?? this.lastTouchedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (colorIndex.present) {
      map['color_index'] = Variable<int>(colorIndex.value);
    }
    if (bgImagePath.present) {
      map['bg_image_path'] = Variable<String>(bgImagePath.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (stepSize.present) {
      map['step_size'] = Variable<int>(stepSize.value);
    }
    if (dailyTarget.present) {
      map['daily_target'] = Variable<int>(dailyTarget.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (lastTouchedAt.present) {
      map['last_touched_at'] = Variable<DateTime>(lastTouchedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CountersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('bgImagePath: $bgImagePath, ')
          ..write('unit: $unit, ')
          ..write('tag: $tag, ')
          ..write('stepSize: $stepSize, ')
          ..write('dailyTarget: $dailyTarget, ')
          ..write('pinned: $pinned, ')
          ..write('archived: $archived, ')
          ..write('lastTouchedAt: $lastTouchedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntriesTable extends Entries with TableInfo<$EntriesTable, Entry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _counterIdMeta = const VerificationMeta(
    'counterId',
  );
  @override
  late final GeneratedColumn<String> counterId = GeneratedColumn<String>(
    'counter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES counters (id)',
    ),
  );
  static const VerificationMeta _deltaMeta = const VerificationMeta('delta');
  @override
  late final GeneratedColumn<int> delta = GeneratedColumn<int>(
    'delta',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueAfterMeta = const VerificationMeta(
    'valueAfter',
  );
  @override
  late final GeneratedColumn<int> valueAfter = GeneratedColumn<int>(
    'value_after',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    counterId,
    delta,
    valueAfter,
    occurredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<Entry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('counter_id')) {
      context.handle(
        _counterIdMeta,
        counterId.isAcceptableOrUnknown(data['counter_id']!, _counterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_counterIdMeta);
    }
    if (data.containsKey('delta')) {
      context.handle(
        _deltaMeta,
        delta.isAcceptableOrUnknown(data['delta']!, _deltaMeta),
      );
    } else if (isInserting) {
      context.missing(_deltaMeta);
    }
    if (data.containsKey('value_after')) {
      context.handle(
        _valueAfterMeta,
        valueAfter.isAcceptableOrUnknown(data['value_after']!, _valueAfterMeta),
      );
    } else if (isInserting) {
      context.missing(_valueAfterMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Entry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      counterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counter_id'],
      )!,
      delta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delta'],
      )!,
      valueAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value_after'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
    );
  }

  @override
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }
}

class Entry extends DataClass implements Insertable<Entry> {
  final String id;
  final String counterId;

  /// 增减量：+step、-1、手动调整时的差值。
  final int delta;

  /// 操作后的累计值，仅用于历史列表展示。
  final int valueAfter;

  /// 动作发生时间。
  final DateTime occurredAt;
  const Entry({
    required this.id,
    required this.counterId,
    required this.delta,
    required this.valueAfter,
    required this.occurredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['counter_id'] = Variable<String>(counterId);
    map['delta'] = Variable<int>(delta);
    map['value_after'] = Variable<int>(valueAfter);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      counterId: Value(counterId),
      delta: Value(delta),
      valueAfter: Value(valueAfter),
      occurredAt: Value(occurredAt),
    );
  }

  factory Entry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entry(
      id: serializer.fromJson<String>(json['id']),
      counterId: serializer.fromJson<String>(json['counterId']),
      delta: serializer.fromJson<int>(json['delta']),
      valueAfter: serializer.fromJson<int>(json['valueAfter']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'counterId': serializer.toJson<String>(counterId),
      'delta': serializer.toJson<int>(delta),
      'valueAfter': serializer.toJson<int>(valueAfter),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
    };
  }

  Entry copyWith({
    String? id,
    String? counterId,
    int? delta,
    int? valueAfter,
    DateTime? occurredAt,
  }) => Entry(
    id: id ?? this.id,
    counterId: counterId ?? this.counterId,
    delta: delta ?? this.delta,
    valueAfter: valueAfter ?? this.valueAfter,
    occurredAt: occurredAt ?? this.occurredAt,
  );
  Entry copyWithCompanion(EntriesCompanion data) {
    return Entry(
      id: data.id.present ? data.id.value : this.id,
      counterId: data.counterId.present ? data.counterId.value : this.counterId,
      delta: data.delta.present ? data.delta.value : this.delta,
      valueAfter: data.valueAfter.present
          ? data.valueAfter.value
          : this.valueAfter,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entry(')
          ..write('id: $id, ')
          ..write('counterId: $counterId, ')
          ..write('delta: $delta, ')
          ..write('valueAfter: $valueAfter, ')
          ..write('occurredAt: $occurredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, counterId, delta, valueAfter, occurredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entry &&
          other.id == this.id &&
          other.counterId == this.counterId &&
          other.delta == this.delta &&
          other.valueAfter == this.valueAfter &&
          other.occurredAt == this.occurredAt);
}

class EntriesCompanion extends UpdateCompanion<Entry> {
  final Value<String> id;
  final Value<String> counterId;
  final Value<int> delta;
  final Value<int> valueAfter;
  final Value<DateTime> occurredAt;
  final Value<int> rowid;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.counterId = const Value.absent(),
    this.delta = const Value.absent(),
    this.valueAfter = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntriesCompanion.insert({
    required String id,
    required String counterId,
    required int delta,
    required int valueAfter,
    required DateTime occurredAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       counterId = Value(counterId),
       delta = Value(delta),
       valueAfter = Value(valueAfter),
       occurredAt = Value(occurredAt);
  static Insertable<Entry> custom({
    Expression<String>? id,
    Expression<String>? counterId,
    Expression<int>? delta,
    Expression<int>? valueAfter,
    Expression<DateTime>? occurredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (counterId != null) 'counter_id': counterId,
      if (delta != null) 'delta': delta,
      if (valueAfter != null) 'value_after': valueAfter,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? counterId,
    Value<int>? delta,
    Value<int>? valueAfter,
    Value<DateTime>? occurredAt,
    Value<int>? rowid,
  }) {
    return EntriesCompanion(
      id: id ?? this.id,
      counterId: counterId ?? this.counterId,
      delta: delta ?? this.delta,
      valueAfter: valueAfter ?? this.valueAfter,
      occurredAt: occurredAt ?? this.occurredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (counterId.present) {
      map['counter_id'] = Variable<String>(counterId.value);
    }
    if (delta.present) {
      map['delta'] = Variable<int>(delta.value);
    }
    if (valueAfter.present) {
      map['value_after'] = Variable<int>(valueAfter.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('counterId: $counterId, ')
          ..write('delta: $delta, ')
          ..write('valueAfter: $valueAfter, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CountersTable counters = $CountersTable(this);
  late final $EntriesTable entries = $EntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [counters, entries];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$CountersTableCreateCompanionBuilder =
    CountersCompanion Function({
      required String id,
      required String name,
      Value<String> emoji,
      Value<int> colorIndex,
      Value<String?> bgImagePath,
      Value<String> unit,
      Value<String> tag,
      Value<int> stepSize,
      Value<int?> dailyTarget,
      Value<bool> pinned,
      Value<bool> archived,
      Value<DateTime?> lastTouchedAt,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CountersTableUpdateCompanionBuilder =
    CountersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> emoji,
      Value<int> colorIndex,
      Value<String?> bgImagePath,
      Value<String> unit,
      Value<String> tag,
      Value<int> stepSize,
      Value<int?> dailyTarget,
      Value<bool> pinned,
      Value<bool> archived,
      Value<DateTime?> lastTouchedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$CountersTableReferences
    extends BaseReferences<_$AppDatabase, $CountersTable, Counter> {
  $$CountersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EntriesTable, List<Entry>> _entriesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.entries,
    aliasName: 'counters__id__entries__counter_id',
  );

  $$EntriesTableProcessedTableManager get entriesRefs {
    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.counterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_entriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CountersTableFilterComposer
    extends Composer<_$AppDatabase, $CountersTable> {
  $$CountersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bgImagePath => $composableBuilder(
    column: $table.bgImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stepSize => $composableBuilder(
    column: $table.stepSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyTarget => $composableBuilder(
    column: $table.dailyTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastTouchedAt => $composableBuilder(
    column: $table.lastTouchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> entriesRefs(
    Expression<bool> Function($$EntriesTableFilterComposer f) f,
  ) {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.counterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CountersTableOrderingComposer
    extends Composer<_$AppDatabase, $CountersTable> {
  $$CountersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bgImagePath => $composableBuilder(
    column: $table.bgImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stepSize => $composableBuilder(
    column: $table.stepSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyTarget => $composableBuilder(
    column: $table.dailyTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastTouchedAt => $composableBuilder(
    column: $table.lastTouchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CountersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CountersTable> {
  $$CountersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bgImagePath => $composableBuilder(
    column: $table.bgImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<int> get stepSize =>
      $composableBuilder(column: $table.stepSize, builder: (column) => column);

  GeneratedColumn<int> get dailyTarget => $composableBuilder(
    column: $table.dailyTarget,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get lastTouchedAt => $composableBuilder(
    column: $table.lastTouchedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> entriesRefs<T extends Object>(
    Expression<T> Function($$EntriesTableAnnotationComposer a) f,
  ) {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.counterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CountersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CountersTable,
          Counter,
          $$CountersTableFilterComposer,
          $$CountersTableOrderingComposer,
          $$CountersTableAnnotationComposer,
          $$CountersTableCreateCompanionBuilder,
          $$CountersTableUpdateCompanionBuilder,
          (Counter, $$CountersTableReferences),
          Counter,
          PrefetchHooks Function({bool entriesRefs})
        > {
  $$CountersTableTableManager(_$AppDatabase db, $CountersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CountersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CountersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CountersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<int> colorIndex = const Value.absent(),
                Value<String?> bgImagePath = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String> tag = const Value.absent(),
                Value<int> stepSize = const Value.absent(),
                Value<int?> dailyTarget = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime?> lastTouchedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CountersCompanion(
                id: id,
                name: name,
                emoji: emoji,
                colorIndex: colorIndex,
                bgImagePath: bgImagePath,
                unit: unit,
                tag: tag,
                stepSize: stepSize,
                dailyTarget: dailyTarget,
                pinned: pinned,
                archived: archived,
                lastTouchedAt: lastTouchedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> emoji = const Value.absent(),
                Value<int> colorIndex = const Value.absent(),
                Value<String?> bgImagePath = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String> tag = const Value.absent(),
                Value<int> stepSize = const Value.absent(),
                Value<int?> dailyTarget = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime?> lastTouchedAt = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CountersCompanion.insert(
                id: id,
                name: name,
                emoji: emoji,
                colorIndex: colorIndex,
                bgImagePath: bgImagePath,
                unit: unit,
                tag: tag,
                stepSize: stepSize,
                dailyTarget: dailyTarget,
                pinned: pinned,
                archived: archived,
                lastTouchedAt: lastTouchedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CountersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (entriesRefs) db.entries],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (entriesRefs)
                    await $_getPrefetchedData<Counter, $CountersTable, Entry>(
                      currentTable: table,
                      referencedTable: $$CountersTableReferences
                          ._entriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CountersTableReferences(db, table, p0).entriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.counterId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CountersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CountersTable,
      Counter,
      $$CountersTableFilterComposer,
      $$CountersTableOrderingComposer,
      $$CountersTableAnnotationComposer,
      $$CountersTableCreateCompanionBuilder,
      $$CountersTableUpdateCompanionBuilder,
      (Counter, $$CountersTableReferences),
      Counter,
      PrefetchHooks Function({bool entriesRefs})
    >;
typedef $$EntriesTableCreateCompanionBuilder =
    EntriesCompanion Function({
      required String id,
      required String counterId,
      required int delta,
      required int valueAfter,
      required DateTime occurredAt,
      Value<int> rowid,
    });
typedef $$EntriesTableUpdateCompanionBuilder =
    EntriesCompanion Function({
      Value<String> id,
      Value<String> counterId,
      Value<int> delta,
      Value<int> valueAfter,
      Value<DateTime> occurredAt,
      Value<int> rowid,
    });

final class $$EntriesTableReferences
    extends BaseReferences<_$AppDatabase, $EntriesTable, Entry> {
  $$EntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CountersTable _counterIdTable(_$AppDatabase db) =>
      db.counters.createAlias('entries__counter_id__counters__id');

  $$CountersTableProcessedTableManager get counterId {
    final $_column = $_itemColumn<String>('counter_id')!;

    final manager = $$CountersTableTableManager(
      $_db,
      $_db.counters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_counterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EntriesTableFilterComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get delta => $composableBuilder(
    column: $table.delta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get valueAfter => $composableBuilder(
    column: $table.valueAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CountersTableFilterComposer get counterId {
    final $$CountersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterId,
      referencedTable: $db.counters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CountersTableFilterComposer(
            $db: $db,
            $table: $db.counters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get delta => $composableBuilder(
    column: $table.delta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get valueAfter => $composableBuilder(
    column: $table.valueAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CountersTableOrderingComposer get counterId {
    final $$CountersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterId,
      referencedTable: $db.counters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CountersTableOrderingComposer(
            $db: $db,
            $table: $db.counters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get delta =>
      $composableBuilder(column: $table.delta, builder: (column) => column);

  GeneratedColumn<int> get valueAfter => $composableBuilder(
    column: $table.valueAfter,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  $$CountersTableAnnotationComposer get counterId {
    final $$CountersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterId,
      referencedTable: $db.counters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CountersTableAnnotationComposer(
            $db: $db,
            $table: $db.counters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntriesTable,
          Entry,
          $$EntriesTableFilterComposer,
          $$EntriesTableOrderingComposer,
          $$EntriesTableAnnotationComposer,
          $$EntriesTableCreateCompanionBuilder,
          $$EntriesTableUpdateCompanionBuilder,
          (Entry, $$EntriesTableReferences),
          Entry,
          PrefetchHooks Function({bool counterId})
        > {
  $$EntriesTableTableManager(_$AppDatabase db, $EntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> counterId = const Value.absent(),
                Value<int> delta = const Value.absent(),
                Value<int> valueAfter = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntriesCompanion(
                id: id,
                counterId: counterId,
                delta: delta,
                valueAfter: valueAfter,
                occurredAt: occurredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String counterId,
                required int delta,
                required int valueAfter,
                required DateTime occurredAt,
                Value<int> rowid = const Value.absent(),
              }) => EntriesCompanion.insert(
                id: id,
                counterId: counterId,
                delta: delta,
                valueAfter: valueAfter,
                occurredAt: occurredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({counterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (counterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.counterId,
                                referencedTable: $$EntriesTableReferences
                                    ._counterIdTable(db),
                                referencedColumn: $$EntriesTableReferences
                                    ._counterIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntriesTable,
      Entry,
      $$EntriesTableFilterComposer,
      $$EntriesTableOrderingComposer,
      $$EntriesTableAnnotationComposer,
      $$EntriesTableCreateCompanionBuilder,
      $$EntriesTableUpdateCompanionBuilder,
      (Entry, $$EntriesTableReferences),
      Entry,
      PrefetchHooks Function({bool counterId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CountersTableTableManager get counters =>
      $$CountersTableTableManager(_db, _db.counters);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
}
