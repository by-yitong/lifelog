import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:appstat_sdk/src/device_info_collector.dart';
import 'package:appstat_sdk/src/event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const uuidPattern = r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('device_id is generated once and persisted', () async {
    final first = await DeviceInfoCollector.collect(channel: 'official');
    final second = await DeviceInfoCollector.collect(channel: 'official');

    expect(RegExp(uuidPattern).hasMatch(first['device_id'] as String), isTrue);
    expect(second['device_id'], first['device_id']);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('appstat.device_id'), first['device_id']);
  });

  test('collects contract device fields', () async {
    final device = await DeviceInfoCollector.collect(channel: 'wandoujia');

    expect(device.keys, containsAll(<String>[
      'device_id',
      'platform',
      'os_version',
      'device_model',
      'app_version',
      'channel',
      'sdk_version',
    ]));
    expect(device['platform'], Platform.isIOS ? 'ios' : Platform.operatingSystem);
    expect(device['os_version'], isA<String>());
    expect(device['device_model'], isA<String>());
    expect(device['app_version'], isA<String>());
    expect(device['channel'], 'wandoujia');
    expect(device['sdk_version'], appstatSdkVersion);
  });

  test('existing device_id in prefs is reused unchanged', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'appstat.device_id': 'fixed-device-id',
    });

    final device = await DeviceInfoCollector.collect(channel: 'official');

    expect(device['device_id'], 'fixed-device-id');
  });
}
