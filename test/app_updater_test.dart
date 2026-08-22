import 'package:flutter_test/flutter_test.dart';
import 'package:lifelog/core/update/app_updater.dart';

void main() {
  group('isVersionNewer 版本比较', () {
    test('更高版本返回 true', () {
      expect(isVersionNewer('v1.1.0', '1.0.0'), isTrue);
      expect(isVersionNewer('1.2.3', '1.2.2'), isTrue);
    });
    test('相同或更旧返回 false', () {
      expect(isVersionNewer('v1.0.0', '1.0.0'), isFalse);
      expect(isVersionNewer('1.0.0', '1.0.1'), isFalse);
      expect(isVersionNewer('0.9.9', '1.0.0'), isFalse);
    });
    test('段数不同补零比较', () {
      expect(isVersionNewer('v1.1', '1.0.9'), isTrue);
      expect(isVersionNewer('v2', '1.9.9'), isTrue);
      expect(isVersionNewer('v1.0', '1.0.0'), isFalse);
    });
    test('忽略构建号与预发布后缀', () {
      expect(isVersionNewer('1.1.0+5', '1.0.0'), isTrue);
      expect(isVersionNewer('1.0.0-beta', '1.0.0'), isFalse);
    });
  });

  group('pickApkAsset 按 ABI 选包', () {
    const assets = {
      'app-arm64-v8a-release.apk': 'https://x/arm64',
      'app-armeabi-v7a-release.apk': 'https://x/v7a',
      'app-x86_64-release.apk': 'https://x/x86',
    };

    test('arm64 设备优先 arm64 包', () {
      expect(
        pickApkAsset(assets, ['arm64-v8a', 'armeabi-v7a']),
        'https://x/arm64',
      );
    });

    test('只有 v7a 的老设备拿 v7a 包', () {
      expect(pickApkAsset(assets, ['armeabi-v7a']), 'https://x/v7a');
    });

    test('模拟器拿 x86_64 包（arm 模拟也优先真 arm 包）', () {
      expect(pickApkAsset(assets, ['x86_64', 'x86']), 'https://x/x86');
      expect(
        pickApkAsset(assets, ['x86_64', 'arm64-v8a']),
        'https://x/arm64',
      );
    });

    test('没有匹配资产返回 null', () {
      expect(pickApkAsset(const {}, ['arm64-v8a']), isNull);
      expect(
        pickApkAsset({
          'app-arm64-v8a-debug.apk': 'https://x/debug',
        }, ['arm64-v8a']),
        isNull,
      );
    });
  });
}
