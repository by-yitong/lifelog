import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:appstat_sdk/src/reporter.dart';

const fakeDevice = <String, Object?>{
  'device_id': 'd-1',
  'platform': 'android',
  'os_version': '14',
  'device_model': 'Pixel 8',
  'app_version': '1.0.0',
  'channel': 'official',
  'sdk_version': '0.1.0',
};

Map<String, Object?> fakeEvent(int index) {
  return <String, Object?>{
    'event_id': 'event-$index',
    'name': 'buy_click',
    'ts': 1737280000000 + index,
    'session_id': 'session-1',
    'params': <String, Object?>{'amount': index},
  };
}

Future<Directory> newTempDir() async {
  return Directory.systemTemp.createTemp('appstat_reporter_test');
}

void main() {
  late Directory cacheDir;

  setUp(() async {
    cacheDir = await newTempDir();
  });

  tearDown(() async {
    if (await cacheDir.exists()) await cacheDir.delete(recursive: true);
  });

  test('flushes when queue reaches batch threshold', () async {
    final requests = <http.Request>[];
    final reporter = Reporter(
      appKey: '0123456789abcdef',
      serverUrl: 'http://server.local',
      client: MockClient((request) async {
        requests.add(request);
        return http.Response(
          '{"code":0,"message":"ok","data":{"accepted":${request.body.length},"dropped":0}}',
          200,
        );
      }),
      cacheDirResolver: () async => cacheDir,
    );
    reporter.setDevice(fakeDevice);

    for (var i = 0; i < 19; i++) {
      reporter.enqueue(fakeEvent(i));
    }
    await Future<void>.delayed(Duration.zero);
    expect(requests, isEmpty);
    expect(reporter.queueLength.value, 19);

    reporter.enqueue(fakeEvent(19));
    await reporter.flush();

    expect(requests, hasLength(1));
    expect(reporter.queueLength.value, 0);
    expect(requests.single.url.path, '/api/v1/collect');
    expect(requests.single.headers['X-App-Key'], '0123456789abcdef');

    final payload = jsonDecode(requests.single.body) as Map<String, Object?>;
    expect(payload['device'], fakeDevice);
    final events = payload['events'] as List<Object?>;
    expect(events, hasLength(20));
    final first = events.first as Map<String, Object?>;
    expect(first.keys, containsAll(<String>['event_id', 'name', 'ts', 'session_id', 'params']));
    expect(reporter.lastReport.value, contains('ok'));
    await reporter.dispose();
  });

  test('failed flush caches events as JSON lines', () async {
    final reporter = Reporter(
      appKey: '0123456789abcdef',
      serverUrl: 'http://server.local',
      client: MockClient((request) async => http.Response('server error', 500)),
      cacheDirResolver: () async => cacheDir,
    );
    reporter.setDevice(fakeDevice);

    for (var i = 0; i < 3; i++) {
      reporter.enqueue(fakeEvent(i));
    }
    await reporter.flush();

    expect(reporter.queueLength.value, 0);
    expect(reporter.lastReport.value, contains('HTTP 500'));

    final file = File('${cacheDir.path}/appstat_pending.jsonl');
    expect(await file.exists(), isTrue);
    final lines = await file.readAsLines();
    expect(lines, hasLength(3));
    final restored = jsonDecode(lines[1]) as Map<String, Object?>;
    expect(restored['event_id'], 'event-1');
    await reporter.dispose();
  });

  test('network exception also caches events', () async {
    final reporter = Reporter(
      appKey: '0123456789abcdef',
      serverUrl: 'http://server.local',
      client: MockClient(
        (request) async => throw http.ClientException('connection refused'),
      ),
      cacheDirResolver: () async => cacheDir,
    );
    reporter.setDevice(fakeDevice);
    reporter.enqueue(fakeEvent(0));
    await reporter.flush();

    final file = File('${cacheDir.path}/appstat_pending.jsonl');
    expect(await file.exists(), isTrue);
    expect(reporter.lastReport.value, contains('flush failed'));
    await reporter.dispose();
  });

  test('cache file drops oldest lines beyond size cap', () async {
    final reporter = Reporter(
      appKey: '0123456789abcdef',
      serverUrl: 'http://server.local',
      client: MockClient((request) async => http.Response('nope', 500)),
      cacheDirResolver: () async => cacheDir,
      maxCacheBytes: 300,
    );
    reporter.setDevice(fakeDevice);

    for (var i = 0; i < 3; i++) {
      reporter.enqueue(fakeEvent(i));
    }
    for (var i = 3; i < 6; i++) {
      reporter.enqueue(fakeEvent(i));
    }
    await reporter.flush();

    final file = File('${cacheDir.path}/appstat_pending.jsonl');
    final lines = await file.readAsLines();
    expect(lines, isNotEmpty);
    expect(lines.first, isNot(contains('event-0')));
    expect(lines.last, contains('event-5'));
    for (final line in lines) {
      expect(line, contains('event-'));
    }
    await reporter.dispose();
  });

  test('cached events are loaded, merged and cleared on next run', () async {
    final file = File('${cacheDir.path}/appstat_pending.jsonl');
    await file.writeAsString(
      '${jsonEncode(fakeEvent(0))}\n'
      'not-json\n'
      '\n'
      '${jsonEncode(fakeEvent(1))}\n',
    );

    final requests = <http.Request>[];
    final reporter = Reporter(
      appKey: '0123456789abcdef',
      serverUrl: 'http://server.local',
      client: MockClient((request) async {
        requests.add(request);
        return http.Response(
          '{"code":0,"message":"ok","data":{"accepted":3,"dropped":0}}',
          200,
        );
      }),
      cacheDirResolver: () async => cacheDir,
    );
    reporter.setDevice(fakeDevice);
    await reporter.loadCachedEvents();
    expect(reporter.queueLength.value, 2);

    reporter.enqueue(fakeEvent(2));
    await reporter.flush();

    final payload = jsonDecode(requests.single.body) as Map<String, Object?>;
    final events = payload['events'] as List<Object?>;
    expect(events, hasLength(3));
    expect((events.first as Map<String, Object?>)['event_id'], 'event-0');
    expect((events.last as Map<String, Object?>)['event_id'], 'event-2');
    expect(reporter.lastReport.value, 'ok: 3 accepted (HTTP 200)');
    expect(await file.exists(), isFalse);
    await reporter.dispose();
  });
}
