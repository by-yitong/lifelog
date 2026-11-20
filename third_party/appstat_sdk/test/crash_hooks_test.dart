import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appstat_sdk/src/crash_hooks.dart';

void main() {
  final crashes = <Map<String, String>>[];

  setUp(() => crashes.clear());

  void recordCrash({
    required String type,
    required String exception,
    required String stack,
  }) {
    crashes.add(<String, String>{'type': type, 'exception': exception, 'stack': stack});
  }

  test('flutter error is captured with first line exception and full stack', () {
    final hooks = CrashHooks(onCrash: recordCrash);

    hooks.handleFlutterError(
      FlutterErrorDetails(
        exception: FormatException('bad input\nwhile parsing'),
        stack: StackTrace.current,
      ),
    );

    expect(crashes, hasLength(1));
    expect(crashes.single['type'], 'flutter');
    expect(crashes.single['exception'], contains('bad input'));
    expect(crashes.single['exception'], isNot(contains('while parsing')));
    expect(crashes.single['stack'], isNotEmpty);
  });

  test('installing keeps existing FlutterError handler in the chain', () {
    final hooks = CrashHooks(onCrash: recordCrash);
    var originalCalled = 0;
    void originalHandler(FlutterErrorDetails details) => originalCalled++;
    FlutterError.onError = originalHandler;

    hooks.install();
    FlutterError.onError!(FlutterErrorDetails(exception: StateError('x')));
    hooks.uninstall();

    expect(originalCalled, 1);
    expect(crashes.single['exception'], contains('x'));
    expect(identical(originalHandler, FlutterError.onError), isTrue);
    FlutterError.onError = null;
  });

  test('installing with no prior handler falls back to presentError', () {
    final hooks = CrashHooks(onCrash: recordCrash);
    var presented = 0;
    final realPresentError = FlutterError.presentError;
    FlutterError.presentError = (details) => presented++;
    FlutterError.onError = null;

    hooks.install();
    FlutterError.onError!(FlutterErrorDetails(exception: StateError('y')));
    hooks.uninstall();
    FlutterError.presentError = realPresentError;

    expect(presented, 1);
    expect(crashes.single['exception'], contains('y'));
  });

  test('dispatcher error is captured and delegates to previous handler', () {
    final hooks = CrashHooks(onCrash: recordCrash);
    var previousCalled = 0;
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      previousCalled++;
      return true;
    };

    hooks.install();
    final handled = PlatformDispatcher.instance.onError!(StateError('boom'), StackTrace.empty);
    hooks.uninstall();

    expect(handled, isTrue);
    expect(previousCalled, 1);
    expect(crashes.single['type'], 'flutter');
    expect(crashes.single['exception'], contains('boom'));
    expect(PlatformDispatcher.instance.onError, isNotNull);
    PlatformDispatcher.instance.onError = null;
  });

  test('dispatcher error with no previous handler returns false', () {
    final hooks = CrashHooks(onCrash: recordCrash);
    PlatformDispatcher.instance.onError = null;

    hooks.install();
    final handled = PlatformDispatcher.instance.onError!(StateError('z'), StackTrace.empty);
    hooks.uninstall();

    expect(handled, isFalse);
    expect(crashes.single['exception'], contains('z'));
  });

  test('firstLine splits at first newline', () {
    expect(CrashHooks.firstLine('a\nb\nc'), 'a');
    expect(CrashHooks.firstLine('single'), 'single');
  });
}
