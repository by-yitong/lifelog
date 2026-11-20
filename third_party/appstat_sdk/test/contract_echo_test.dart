import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:appstat_sdk/src/event.dart';
import 'package:appstat_sdk/src/reporter.dart';

void main() {
  test('collect payload matches contract over real HTTP echo server', () async {
    final device = <String, Object?>{
      'device_id': '3f6a1c2e-9b4d-4c8a-a1b2-3c4d5e6f7a8b',
      'platform': 'android',
      'os_version': '14',
      'device_model': 'Pixel 8',
      'app_version': '1.0.0',
      'channel': 'official',
      'sdk_version': '0.1.0',
    };

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final capturedBodies = <String>[];
    final serverDone = Completer<void>();
    late StreamSubscription<HttpRequest> subscription;
    subscription = server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      capturedBodies.add(body);
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        '{"code":0,"message":"ok","data":{"accepted":3,"dropped":0}}',
      );
      await request.response.close();
      await subscription.cancel();
      serverDone.complete();
    });

    final cacheDir = await Directory.systemTemp.createTemp('appstat_echo_test');
    final reporter = Reporter(
      appKey: '0123456789abcdef',
      serverUrl: 'http://127.0.0.1:${server.port}',
      client: http.Client(),
      cacheDirResolver: () async => cacheDir,
    );
    reporter.setDevice(device);
    reporter.enqueue(StatEvent(name: 'app_launch', sessionId: 'session-a').toJson());
    reporter.enqueue(
      StatEvent(
        name: 'page_view',
        params: <String, Object?>{'path': '/home'},
        sessionId: 'session-a',
      ).toJson(),
    );
    reporter.enqueue(
      StatEvent(
        name: 'crash',
        params: <String, Object?>{
          'type': 'flutter',
          'exception': 'FormatException: Unexpected character (at character 1)',
          'stack': '#0      main (package:app/main.dart:12:5)',
        },
        sessionId: 'session-a',
      ).toJson(),
    );
    await reporter.flush();
    await serverDone.future.timeout(const Duration(seconds: 30));
    await server.close(force: true);
    await cacheDir.delete(recursive: true);

    expect(capturedBodies, hasLength(1));
    debugPrint('===CAPTURED_REQUEST_BODY_BEGIN===');
    debugPrint(const JsonEncoder.withIndent('  ').convert(jsonDecode(capturedBodies.single)));
    debugPrint('===CAPTURED_REQUEST_BODY_END===');

    final payload = jsonDecode(capturedBodies.single) as Map<String, Object?>;
    expect(payload.keys, <String>['device', 'events']);
    expect(payload['device'], device);
    final events = (payload['events'] as List<Object?>).cast<Map<String, Object?>>();
    expect(events, hasLength(3));
    for (final event in events) {
      expect(event.keys, <String>['event_id', 'name', 'ts', 'session_id', 'params']);
      expect(event['ts'], greaterThan(0));
    }
    expect(events.map((event) => event['name']), <String>['app_launch', 'page_view', 'crash']);
    expect(events[1]['params'], <String, Object?>{'path': '/home'});
    expect((events[2]['params'] as Map<String, Object?>)['type'], 'flutter');
    await reporter.dispose();
  });
}
