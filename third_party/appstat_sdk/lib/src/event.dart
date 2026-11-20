import 'package:uuid/uuid.dart';

const String appstatSdkVersion = '0.1.0';

class StatEvent {
  StatEvent({
    required this.name,
    this.params = const <String, Object?>{},
    required this.sessionId,
    String? eventId,
    int? ts,
  })  : eventId = eventId ?? const Uuid().v4(),
        ts = ts ?? DateTime.now().millisecondsSinceEpoch;

  final String eventId;
  final String name;
  final int ts;
  final String sessionId;
  final Map<String, Object?> params;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'event_id': eventId,
      'name': name,
      'ts': ts,
      'session_id': sessionId,
      'params': params,
    };
  }

  static StatEvent fromJson(Map<String, Object?> json) {
    return StatEvent(
      eventId: json['event_id'] as String?,
      name: json['name'] as String,
      ts: json['ts'] as int?,
      sessionId: json['session_id'] as String? ?? '',
      params: Map<String, Object?>.from(json['params'] as Map? ?? <String, Object?>{}),
    );
  }
}
