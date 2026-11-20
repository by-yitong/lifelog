import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appstat_sdk/src/native_crash_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final received = <Map<String, String>>[];

  setUp(() {
    received.clear();
    NativeCrashChannel.onCrash = ({
      required String type,
      required String exception,
      required String stack,
    }) {
      received.add(<String, String>{'type': type, 'exception': exception, 'stack': stack});
    };
    NativeCrashChannel.ensureListening();
  });

  tearDown(NativeCrashChannel.resetForTest);

  test('nativeCrash message is dispatched to onCrash', () async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      'appstat_sdk',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('nativeCrash', <String, String>{
          'type': 'android-java',
          'exception': 'java.lang.RuntimeException: boom',
          'stack': 'at com.appstat.Main.main(Main.kt:1)',
        }),
      ),
      (data) {},
    );

    expect(received, hasLength(1));
    expect(received.single['type'], 'android-java');
    expect(received.single['exception'], 'java.lang.RuntimeException: boom');
    expect(received.single['stack'], contains('Main.kt'));
  });

  test('ios-nsException messages pass through with their own type', () async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      'appstat_sdk',
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('nativeCrash', <String, String>{
          'type': 'ios-nsException',
          'exception': 'NSRangeException: index out of bounds',
          'stack': '0 frame',
        }),
      ),
      (data) {},
    );

    expect(received.single['type'], 'ios-nsException');
  });

  test('non crash messages are ignored', () async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      'appstat_sdk',
      const StandardMethodCodec().encodeMethodCall(const MethodCall('otherMethod')),
      (data) {},
    );

    expect(received, isEmpty);
  });
}
