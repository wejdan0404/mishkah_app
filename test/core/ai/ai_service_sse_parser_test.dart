import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mishkat/core/ai/ai_service.dart';
import 'package:mishkat/models/ai_message.dart';

void main() {
  Stream<List<int>> bytesFromString(String s) async* {
    yield utf8.encode(s);
  }

  test('parses a complete SSE stream', () async {
    const raw = 'event: message.received\n'
        'data: {"id":"m1","is_flagged":false}\n'
        '\n'
        'event: message.delta\n'
        'data: {"text":"مرحبا"}\n'
        '\n'
        'event: message.delta\n'
        'data: {"text":" بك"}\n'
        '\n'
        'event: message.complete\n'
        'data: {"thread_id":"t1"}\n'
        '\n';
    final events = await parseSseStream(bytesFromString(raw)).toList();
    expect(events, hasLength(4));
    expect(events[0], isA<AiStreamMessageReceived>());
    expect((events[1] as AiStreamDelta).text, 'مرحبا');
    expect((events[2] as AiStreamDelta).text, ' بك');
    expect((events[3] as AiStreamComplete).threadId, 't1');
  });

  test('tolerates chunk splits across lines and partial JSON', () async {
    Stream<List<int>> chunks() async* {
      yield utf8.encode('event: message.delta\n');
      yield utf8.encode('data: {"text":"part1"}\n\n');
      yield utf8.encode('event: message.del');
      yield utf8.encode(
          'ta\ndata: {"text":"part2"}\n\nevent: message.complete\ndata: {"thread_id":"t9"}\n\n');
    }
    final events = await parseSseStream(chunks()).toList();
    expect(
      events.whereType<AiStreamDelta>().map((e) => e.text).toList(),
      ['part1', 'part2'],
    );
    expect(events.last, isA<AiStreamComplete>());
  });

  test('emits error event for message.error', () async {
    const raw = 'event: message.error\n'
        'data: {"message":"بطئ المزود"}\n'
        '\n';
    final events = await parseSseStream(bytesFromString(raw)).toList();
    expect(events, hasLength(1));
    expect((events.single as AiStreamError).message, 'بطئ المزود');
  });
}
