import 'package:appstat_sdk/appstat_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kEnabled = 'analytics_enabled';

/// 后台「接入设置」页复制的 AppKey。
const kAppStatAppKey = '4b46f6apb58eul0x';

/// 匿名使用统计的统一入口：默认开启，用户可在设置里关闭。
class AppAnalytics {
  AppAnalytics._();

  static bool _enabled = true;

  static Future<void> initFromPrefs(SharedPreferences prefs) async {
    _enabled = prefs.getBool(_kEnabled) ?? true;
    if (_enabled) await _start();
  }

  static Future<bool> loadEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_kEnabled) ?? true;

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, value);
    if (value == _enabled) return;
    _enabled = value;
    if (value) {
      await _start();
    } else {
      await AppStat.disable();
    }
  }

  static void track(String name, [Map<String, Object?>? params]) {
    if (_enabled) AppStat.track(name, params);
  }

  static Future<void> _start() =>
      AppStat.init(appKey: kAppStatAppKey, enablePageView: false);
}
