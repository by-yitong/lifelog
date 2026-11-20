import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

class SessionTracker {
  SessionTracker({
    required void Function(int seconds) sessionEndHandler,
    DateTime Function()? now,
    String? initialSessionId,
  })  : _onSessionEnd = sessionEndHandler,
        _now = now ?? DateTime.now,
        _sessionId = initialSessionId ?? const Uuid().v4() {
    _resumedAt = _now();
  }

  final DateTime Function() _now;
  final void Function(int seconds) _onSessionEnd;

  String _sessionId;
  bool _inForeground = true;
  late DateTime _resumedAt;

  String get sessionId => _sessionId;

  void handleLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _resumedAt = _now();
        if (!_inForeground) {
          _inForeground = true;
          _sessionId = const Uuid().v4();
        }
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        if (_inForeground) {
          _inForeground = false;
          final duration = _now().difference(_resumedAt).inSeconds;
          _onSessionEnd(duration < 0 ? 0 : duration);
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }
}
