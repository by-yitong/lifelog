import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:appstat_sdk/src/event.dart';

void main() {
  const uuidPattern = r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';

  test('serializes to contract JSON', () {
    final event = StatEvent(
      name: 'buy_click',
      params: <String, Object?>{'amount': 6},
      sessionId: 'session-1',
      eventId: 'event-1',
      ts: 1737280000000,
    );

    expect(event.toJson(), <String, Object?>{
      'event_id': 'event-1',
      'name': 'buy_click',
      'ts': 1737280000000,
      'session_id': 'session-1',
      'params': <String, Object?>{'amount': 6},
    });
    expect(jsonEncode(event.toJson()), isA<String>());
  });

  test('generates uuid v4 event_id and millisecond ts by default', () {
    final before = DateTime.now().millisecondsSinceEpoch;
    final event = StatEvent(name: 'app_launch', sessionId: 'session-1');
    final after = DateTime.now().millisecondsSinceEpoch;

    expect(RegExp(uuidPattern).hasMatch(event.eventId), isTrue);
    expect(event.ts, inInclusiveRange(before, after));
  });

  test('round trips through fromJson', () {
    final event = StatEvent(
      name: 'crash',
      params: <String, Object?>{'type': 'flutter', 'exception': 'boom'},
      sessionId: 'session-1',
    );

    final restored = StatEvent.fromJson(event.toJson());

    expect(restored.eventId, event.eventId);
    expect(restored.name, event.name);
    expect(restored.ts, event.ts);
    expect(restored.sessionId, event.sessionId);
    expect(restored.params, event.params);
  });
}
