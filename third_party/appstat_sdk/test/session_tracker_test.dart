import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:appstat_sdk/src/session_tracker.dart';

void main() {
  test('reports session_end with foreground duration on hidden', () {
    var now = DateTime(2026, 1, 1, 10);
    final ends = <int>[];
    final tracker = SessionTracker(
      now: () => now,
      initialSessionId: 'session-1',
      sessionEndHandler: ends.add,
    );

    now = now.add(const Duration(seconds: 90));
    tracker.handleLifecycle(AppLifecycleState.hidden);

    expect(ends, <int>[90]);
    expect(tracker.sessionId, 'session-1');
  });

  test('rotates session id on resume without another app_launch event', () {
    var now = DateTime(2026, 1, 1, 10);
    final ends = <int>[];
    final tracker = SessionTracker(
      now: () => now,
      initialSessionId: 'session-1',
      sessionEndHandler: ends.add,
    );

    tracker.handleLifecycle(AppLifecycleState.hidden);
    now = now.add(const Duration(minutes: 5));
    tracker.handleLifecycle(AppLifecycleState.resumed);

    expect(tracker.sessionId, isNot('session-1'));
    expect(RegExp(r'^[0-9a-f\-]{36}$').hasMatch(tracker.sessionId), isTrue);
    expect(ends, hasLength(1));
  });

  test('hidden and paused do not double report', () {
    var now = DateTime(2026, 1, 1, 10);
    final ends = <int>[];
    final tracker = SessionTracker(
      now: () => now,
      initialSessionId: 'session-1',
      sessionEndHandler: ends.add,
    );

    now = now.add(const Duration(seconds: 30));
    tracker.handleLifecycle(AppLifecycleState.hidden);
    tracker.handleLifecycle(AppLifecycleState.paused);
    tracker.handleLifecycle(AppLifecycleState.paused);

    expect(ends, hasLength(1));
  });

  test('second background period starts measuring from resume', () {
    var now = DateTime(2026, 1, 1, 10);
    final ends = <int>[];
    final tracker = SessionTracker(
      now: () => now,
      initialSessionId: 'session-1',
      sessionEndHandler: ends.add,
    );

    now = now.add(const Duration(seconds: 10));
    tracker.handleLifecycle(AppLifecycleState.hidden);
    now = now.add(const Duration(minutes: 5));
    tracker.handleLifecycle(AppLifecycleState.resumed);
    now = now.add(const Duration(seconds: 45));
    tracker.handleLifecycle(AppLifecycleState.hidden);

    expect(ends, <int>[10, 45]);
  });

  test('inactive state does not end the session', () {
    var now = DateTime(2026, 1, 1, 10);
    final ends = <int>[];
    final tracker = SessionTracker(
      now: () => now,
      initialSessionId: 'session-1',
      sessionEndHandler: ends.add,
    );

    now = now.add(const Duration(seconds: 10));
    tracker.handleLifecycle(AppLifecycleState.inactive);

    expect(ends, isEmpty);
  });
}
