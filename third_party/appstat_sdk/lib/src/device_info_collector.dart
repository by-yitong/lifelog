import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'event.dart';

class DeviceInfoCollector {
  DeviceInfoCollector._();

  static const String _deviceIdKey = 'appstat.device_id';

  static Future<Map<String, Object?>> collect({required String channel}) async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(_deviceIdKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    var osVersion = Platform.operatingSystemVersion;
    var deviceModel = 'unknown';
    try {
      final (nativeOsVersion, nativeDeviceModel) = await _nativeDeviceInfo();
      osVersion = nativeOsVersion;
      deviceModel = nativeDeviceModel;
    } on Exception {
      osVersion = Platform.operatingSystemVersion;
      deviceModel = 'unknown';
    }

    var appVersion = 'unknown';
    try {
      appVersion = (await PackageInfo.fromPlatform()).version;
    } on Exception {
      appVersion = 'unknown';
    }

    return <String, Object?>{
      'device_id': deviceId,
      'platform': Platform.isIOS ? 'ios' : Platform.operatingSystem,
      'os_version': osVersion,
      'device_model': deviceModel,
      'app_version': appVersion,
      'channel': channel,
      'sdk_version': appstatSdkVersion,
    };
  }

  static Future<(String, String)> _nativeDeviceInfo() async {
    if (Platform.isAndroid) {
      final android = await DeviceInfoPlugin().androidInfo;
      return (android.version.release, android.model);
    }
    if (Platform.isIOS) {
      final ios = await DeviceInfoPlugin().iosInfo;
      return (ios.systemVersion, ios.model);
    }
    return (Platform.operatingSystemVersion, 'unknown');
  }
}
