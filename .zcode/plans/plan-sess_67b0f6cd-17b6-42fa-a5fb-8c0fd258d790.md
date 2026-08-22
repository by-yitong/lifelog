# 「数一数」— 生活计数 App 设计与实现方案

一个记录"某件事做了多少次"的 Flutter App（看动漫多少集、喝水多少次、扫地多少次）。全新项目，目录 `/home/admins/projects/lifelog` 为空，Flutter 3.44.2 可用，目标平台仅 Android。

## 一、功能设计（完整版）

**核心概念**：计数器（Counter）= 一件被重复记录的事；每次 +1 产生一条带时间戳的记录（Entry）。

| 功能 | 说明 |
|---|---|
| 计数器管理 | 创建/编辑/删除/归档/置顶；名称、emoji 图标、8 色卡片色、单位（次/杯/集/页/自定义）、步长（+1/+2/+5）、每日目标（可选） |
| 快速计数 | 首页卡片直接 +1：数字弹跳动画 + 触感反馈；-1 在详情页，带 Undo |
| 历史记录 | 每次操作记录时间戳、增减量、操作后数值；按日分组展示；滑动删除单条（计数回退 + Undo） |
| 统计 | 今日/本周/本月/累计计数、连续天数 🔥（streak）、近 7/30/90 天趋势柱状图 |
| 目标 | 每日目标 → 卡片上显示今日进度环，首页顶部显示今日总完成数 |
| 首页组织 | 2 列卡片网格、置顶优先、搜索、排序（最近使用/名称/创建时间） |
| 设置 | 主题（跟随系统/浅色/深色）、默认排序、导出 CSV/JSON（系统分享）、关于 |
| 空状态 | 首次启动提供快捷创建建议（"喝水💧""看动漫📺""扫地🧹"）一键建好 |

不做（记为后续版本）：多设备同步、补记过去日期、导入恢复、桌面/宽屏适配。

## 二、UI / UX 设计（hallmark 纪律适配到 Flutter）

hallmark 面向 Web CSS，这里把它的核心纪律落进 Flutter 主题体系：**playful genre（Hum 方向）**——温暖人本、大数字即主角。

- **设计 token 层**（`core/theme/`，等价于 hallmark 的 tokens.css）：
  - 色板：以 OKLCH 设计再转 sRGB。浅色 = 暖白纸底（~oklch 97% 低饱和暖）+ 墨色文字 + 蜜橘/珊瑚主强调；深色 = 暖炭底 + 同色相提亮。8 个卡片色（珊瑚/蜜橘/青柠/薄荷/天蓝/薰衣草/玫粉/暖灰）。
  - 字体：数字用圆润展示字体（Baloo 2，仅拉丁数字、体积小，随 assets 打包，离线可用；下载失败则回退系统字体）；中文走系统 Noto Sans CJK。数字大而醒目，正文克制。
  - 4pt 间距刻度、统一圆角、动效时长/曲线常量。
- **动效纪律**（只动 transform/opacity，尊重系统"减弱动态效果"）：数字 +1 弹跳（scale 1→1.15→1，~200ms）、卡片按压 0.98、进度环平滑填充、列表错峰入场；成功反馈用"静默+触感"，不弹庆祝弹窗。
- **组件完整状态**：每个可交互组件覆盖默认/按压/禁用/加载/空/错误态；删除类操作一律 Undo snackbar 而非确认弹窗（仅清空数据类操作才二次确认）。
- **反 AI 味**：不用默认蓝紫渐变、不堆 emoji、文案真实（不虚构统计）、留白与层级靠字号/字重/颜色而非卡片套卡片。

### 页面结构

1. **首页**：顶部日期问候 + 今日总计数摘要 → 卡片网格（emoji、名称、大号数字+单位、目标进度环、右下角 +1 圆钮）。点卡片进详情，点 +1 快速计数，长按弹出置顶/编辑/归档/删除菜单。滚动出现搜索与排序。空状态带建议 chips。
2. **新建/编辑**：底部抽屉——名称、emoji 分类网格（生活/学习/娱乐/健康）、8 色选色、单位选择、步长、每日目标（可空）、保存。
3. **详情页**：大数字 + 步进按钮（+step / −1）+ 手动调整；统计行（今日/本周/本月/累计/连续🔥）；fl_chart 趋势柱状图（7/30/90 天切换）；按日分组历史列表，滑动删除 + Undo。
4. **设置页**：主题切换、默认排序、导出 CSV/JSON（share_plus 分享）、关于。

## 三、技术方案

- **依赖**：`flutter_riverpod`（状态）、`drift` + `drift_flutter` + `sqlite3_flutter_libs`（本地 SQLite，响应式 watch 流）、`fl_chart`（图表）、`share_plus`（导出）、`shared_preferences`（设置项）、`uuid`、`intl`（中文日期格式）。
- **数据模型**：
  - `counters` 表：id(uuid)、name、emoji、colorIndex、unit、stepSize、dailyTarget?、pinned、archived、sortOrder、createdAt
  - `entries` 表：id、counterId(外键)、delta、valueAfter（操作后累计值，便于回溯与删除回退）、occurredAt、createdAt
- **架构**：`core/`（theme、db、utils）+ `features/`（counters、counter_edit、counter_detail、settings，各含 data/logic/presentation）+ `shared/widgets/`。Repository 用 drift 的 `watch()` 流直接驱动 Riverpod，数据变 UI 即变。
- **App 标识**：项目名 `lifelog`，应用显示名「数一数」（可随时改）。

## 四、实现步骤

1. 脚手架：`flutter create`（org `dev.lifelog`）+ 添加依赖 + drift build_runner 配置 + 打包展示字体
2. 主题 token 层：色板/字体/间距/动效常量 + 浅色与深色 ThemeData（含中文本地化 Material 组件文案）
3. 数据层：drift 表定义 + 生成 + CounterRepository（含 streak/统计计算的工具函数与单测）
4. 首页：卡片网格 + 快速计数动效 + 空状态 + 搜索/排序 + 长按菜单 + 置顶
5. 新建/编辑抽屉：emoji 网格、选色、单位/步长/目标表单与校验
6. 详情页：统计行、趋势图、历史分组列表、滑动删除 + Undo、手动调整
7. 设置页：主题切换（持久化）、导出 CSV/JSON
8. 收尾：repository 单测 + 关键 widget 测试；Android 模拟器构建运行，逐页截图走查打磨（对照 hallmark 反 slop 清单自查）

## 五、验证方式

用 android-emulator 工具链构建、安装、启动，逐屏截图检查视觉与交互（空状态→创建→快速计数→详情统计→删除 Undo→深色模式），`flutter analyze` 与 `flutter test` 全绿后交付。