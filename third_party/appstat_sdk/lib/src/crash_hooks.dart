import 'package:flutter/foundation.dart';

class CrashHooks {
  CrashHooks({required this.onCrash});

  final void Function({
    required String type,
    required String exception,
    required String stack,
  }) onCrash;

  bool _installed = false;
  void Function()? _restoreFlutterError;
  void Function()? _restoreDispatcher;

  void handleFlutterError(FlutterErrorDetails details) {
    onCrash(
      type: 'flutter',
      exception: firstLine(details.exception.toString()),
      stack: details.stack?.toString() ?? '',
    );
  }

  bool handleDispatcherError(Object error, StackTrace stackTrace) {
    onCrash(
      type: 'flutter',
      exception: firstLine(error.toString()),
      stack: stackTrace.toString(),
    );
    return false;
  }

  void install() {
    if (_installed) return;
    _installed = true;

    final previousFlutterError = FlutterError.onError;
    FlutterError.onError = (details) {
      handleFlutterError(details);
      if (previousFlutterError == null) {
        FlutterError.presentError(details);
      } else {
        previousFlutterError(details);
      }
    };
    _restoreFlutterError = () => FlutterError.onError = previousFlutterError;

    final previousDispatcherError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
      handleDispatcherError(error, stackTrace);
      return previousDispatcherError?.call(error, stackTrace) ?? false;
    };
    _restoreDispatcher = () => PlatformDispatcher.instance.onError = previousDispatcherError;
  }

  void uninstall() {
    if (!_installed) return;
    _installed = false;
    _restoreFlutterError?.call();
    _restoreDispatcher?.call();
    _restoreFlutterError = null;
    _restoreDispatcher = null;
  }

  static String firstLine(String text) {
    final breakIndex = text.indexOf('\n');
    return breakIndex < 0 ? text : text.substring(0, breakIndex);
  }
}
