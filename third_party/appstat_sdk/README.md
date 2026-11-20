# appstat_sdk

AppStat 统计平台 Flutter 接入 SDK。支持 Android 与 iOS。

## 接入

### 1. 加依赖

```yaml
dependencies:
  appstat_sdk:
    path: /path/to/appstat_sdk   # 本地路径或 git 仓库地址
```

### 2. 初始化并挂页面采集

```dart
import 'package:appstat_sdk/appstat_sdk.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStat.init(appKey: '你的16位AppKey');
  runApp(const MyApp());
}

MaterialApp(
  navigatorObservers: [AppStatObserver()],
  ...
)
```

appKey 在后台「接入设置」页复制。服务端地址已默认内置 `http://stat.phpcurl.cn`,自建平台可传 `serverUrl` 覆盖。

### 3. 自定义事件

```dart
AppStat.track('buy_click', {'amount': 6, 'scene': '商城'});
AppStat.flush();   // 可选:不等自动批量,立即上报
```

## 参数说明

| 参数 | 说明 |
|---|---|
| `appKey` | 必填,后台建 App 时生成 |
| `serverUrl` | 上报地址,默认 `http://stat.phpcurl.cn` |
| `channel` | 渠道标识,后台「渠道分析」按它分组,默认 `official` |
| `enablePageView` | 是否自动采集页面路径,默认开 |
| `enableCrash` | 是否采集崩溃,默认开 |

## 自动采集内容

- `app_launch`:每次冷启动上报一次
- `session_end`:App 退到后台时上报本次前台使用时长(秒),后台「概览」的平均使用时长来自它
- `page_view`:路由切换时上报,params 为 `{"path": "路由名"}`;路由名建议给页面 route 设置 `settings.name`
- `crash`:Flutter 框架异常、未捕获 Dart 异常、Android Java 崩溃、iOS NSException,统一上报堆栈,后台「崩溃分析」按异常指纹聚合

## 上报机制

- 内存队列满 20 条或每 30 秒自动批量上报一次;`AppStat.flush()` 可手动触发
- 上报失败写入本地缓存文件(上限 2MB),下次启动自动合并重传
- 设备标识 `device_id` 首次启动生成并持久化,用于新增/活跃/留存统计,不采集任何个人信息

## 调试

- `AppStat.queueLength`:当前待上报条数
- `AppStat.lastReport`:最近一次上报结果文本
- 完整可运行示例见 `example/`(填入自己的 appKey 后 `flutter run`)
