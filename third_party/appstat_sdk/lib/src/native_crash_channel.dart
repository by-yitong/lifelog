import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeCrashChannel {
  NativeCrashChannel._();

  static const MethodChannel _channel = MethodChannel('appstat_sdk');

  static void Function({
    required String type,
    required String exception,
    required String stack,
  })? onCrash;

  static bool _listening = false;

  static void ensureListening() {
    if (_listening) return;
    _listening = true;
    _channel.setMethodCallHandler(handlePlatformCall);
  }

  @visibleForTesting
  static Future<dynamic> handlePlatformCall(MethodCall call) async {
    if (call.method != 'nativeCrash') return null;
    final arguments = call.arguments;
    if (arguments is! Map) return null;
    onCrash?.call(
      type: arguments['type']?.toString() ?? 'other',
      exception: arguments['exception']?.toString() ?? '',
      stack: arguments['stack']?.toString() ?? '',
    );
    return null;
  }

  static void resetForTest() {
    _channel.setMethodCallHandler(null);
    _listening = false;
  }
}
