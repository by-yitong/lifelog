# 数一数 · lifelog

记录一件事情做了多少次。

一款极简的 Flutter 计数器应用：卡片式计数、液态玻璃标签栏、趋势图与热力图统计。所有数据只保存在手机本地，无账号、无联网上报。

<p>
  <a href="https://github.com/by-yitong/lifelog/releases/latest"><img alt="最新版本" src="https://img.shields.io/github/v/release/by-yitong/lifelog?label=%E7%89%88%E6%9C%AC"></a>
  <img alt="平台" src="https://img.shields.io/badge/%E5%B9%B3%E5%8F%B0-Android-green">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.44-blue">
</p>

## 功能

**计数**
- 卡片式首页：+1 弹跳动效、随机马卡龙配色、自定义背景图
- 置顶 / 归档 / 搜索 / 长按编辑删除
- 自定义步长与单位（次 / 杯 / 集 / 页…）、每日目标

**浏览**
- 分类 Tab：底部液态玻璃标签栏，滑动胶囊指示器
- 固定 Tab 排序：新建分类自动排最后，设置里可拖动调整
- 上滑收起顶栏底栏、下滑立刻展开的沉浸式列表
- 左右滑动翻页切换分类

**统计**
- 全局统计页：总览卡片 / 月历 / 某天时间线 / 近半年热力图 / 计数器排行
- 详情页：趋势图（柱状 / 折线可切换）、月度热力图
- 历史记录支持修改数量与时间，删除可撤销

**数据**
- 备份数据：导出完整 JSON
- 从备份导入：合并导入（按编号去重）或覆盖导入
- 导出 CSV 用表格软件查看

**其他**
- 应用内更新：自动检查 GitHub Releases，下载 APK 直接安装
- 记一笔 SnackBar 可撤销；双击返回退出
- 深浅色主题跟随系统

## 下载安装

到 [Releases](https://github.com/by-yitong/lifelog/releases) 页面下载对应架构的 APK：

| 文件 | 适用设备 |
|---|---|
| `app-arm64-v8a-release.apk` | 近年主流手机（推荐） |
| `app-armeabi-v7a-release.apk` | 较旧设备 |
| `app-x86_64-release.apk` | 模拟器 / x86 设备 |

安装后如需升级，可直接在 App 内「设置 → 检查更新」，无需重新下载 APK。

> 首次通过浏览器下载安装时，系统会要求允许「安装未知应用」，按提示授权即可。

## 从源码构建

```bash
git clone https://github.com/by-yitong/lifelog.git
cd lifelog
flutter pub get
flutter test                # 跑单元测试
flutter build apk --release --split-per-abi
```

产物位于 `build/app/outputs/flutter-apk/`。要求 Flutter ≥ 3.44（Dart ≥ 3.12）。

## 技术栈

| | |
|---|---|
| 框架 | Flutter / Dart |
| 状态管理 | Riverpod |
| 数据库 | drift（SQLite），本地存储，不上传 |
| 图表 | fl_chart |
| 字体 | Baloo 2 |

```
lib/
├── core/          # 主题令牌、数据库、工具（含应用内更新）
├── features/
│   ├── counters/      # 首页：卡片网格、标签栏、排序
│   ├── counter_detail/# 详情：趋势图、热力图、历史
│   ├── counter_edit/  # 新建 / 编辑计数器
│   ├── stats/         # 全局统计页
│   └── settings/      # 设置：主题、排序、备份导入
└── shared/widgets/    # 液态玻璃标签栏等通用组件
```

## 发新版本

1. 修改 `pubspec.yaml` 中的 `version`（如 `1.2.0+3`）
2. 提交代码并打 tag：
   ```bash
   git tag -a v1.2.0 && git push origin main --tags
   ```
3. `gh release create v1.2.0 <apk 文件>` 上传三个 ABI 的 APK

老用户会在 App 内收到更新提示（比对 Release 的 tag 与本机版本号）。

## 隐私

所有计数数据仅保存在设备本地数据库中。唯一的网络请求是「检查更新」时访问 GitHub Releases API。
