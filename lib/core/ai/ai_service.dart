import 'dart:async';
import 'dart:convert';

import '../../models/ai_message.dart';
import '../../models/ai_thread.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

class AiService {
  AiService._();
  static final AiService instance = AiService._();

  Future<AiThread> createThread({String? title}) async {
    final data = await ApiClient.instance.post(
      ApiEndpoints.aiThreads,
      body: {'title': ?title},
    ) as Map<String, dynamic>;
    return AiThread.fromJson(data);
  }

  Future<List<AiThread>> listThreads() async {
    final data = await ApiClient.instance.get(ApiEndpoints.aiThreads);
    final list = data is List ? data : <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(AiThread.fromJson)
        .toList();
  }

  Future<List<AiMessage>> listMessages(String threadId) async {
    final data = await ApiClient.instance.get(ApiEndpoints.aiMessages(threadId));
    final list = data is List ? data : <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(AiMessage.fromJson)
        .toList();
  }

  Future<void> deleteThread(String threadId) async {
    await ApiClient.instance.delete(ApiEndpoints.aiThread(threadId));
  }

  /// Send a message and yield streaming events (delta/complete/error/received).
  /// The stream completes when the server emits `message.complete` or the
  /// connection ends. Errors bubble up via [AiStreamError] events rather than
  /// being thrown, so the caller can surface them in the UI uniformly.
  Stream<AiStreamEvent> sendMessage({
    required String threadId,
    required String content,
  }) async* {
    final res = await ApiClient.instance.postStream(
      ApiEndpoints.aiMessages(threadId),
      body: {'content': content},
    );
    if (res.statusCode != 200) {
      final body = await res.stream.bytesToString();
      yield AiStreamError(_extractErrorMessage(body, res.statusCode));
      return;
    }
    yield* parseSseStream(res.stream);
  }

  String _extractErrorMessage(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>?;
      final err = decoded?['error'] as Map<String, dynamic>?;
      final msg = err?['message'] as String?;
      if (msg != null && msg.isNotEmpty) return msg;
    } catch (_) {}
    return 'ما قدرنا نستلم الرد ($statusCode).';
  }
}

/// Parses an SSE byte stream into a stream of [AiStreamEvent]s.
/// Exported for testing.
Stream<AiStreamEvent> parseSseStream(Stream<List<int>> bytes) async* {
  final buffer = StringBuffer();

  await for (final chunk in bytes.transform(utf8.decoder)) {
    buffer.write(chunk);
    final str = buffer.toString();
    final boundary = _lastEventBoundary(str);
    if (boundary < 0) continue;
    final complete = str.substring(0, boundary);
    final remainder = str.substring(boundary);
    buffer
      ..clear()
      ..write(remainder);

    for (final block in complete.split(RegExp(r'\r\n\r\n|\n\n'))) {
      if (block.trim().isEmpty) continue;
      final event = _parseBlock(block);
      if (event != null) yield event;
    }
  }

  // Flush any trailing block without a terminator.
  final trailing = buffer.toString();
  if (trailing.trim().isNotEmpty) {
    final event = _parseBlock(trailing);
    if (event != null) yield event;
  }
}

int _lastEventBoundary(String s) {
  final idxLF = s.lastIndexOf('\n\n');
  final idxCRLF = s.lastIndexOf('\r\n\r\n');
  if (idxCRLF >= 0 && idxCRLF >= idxLF) return idxCRLF + 4;
  if (idxLF >= 0) return idxLF + 2;
  return -1;
}

AiStreamEvent? _parseBlock(String block) {
  String? eventName;
  String? dataJson;
  for (final line in block.split(RegExp(r'\r?\n'))) {
    if (line.startsWith('event:')) {
      eventName = line.substring(6).trim();
    } else if (line.startsWith('data:')) {
      final part = line.substring(5).trim();
      dataJson = dataJson == null ? part : '$dataJson\n$part';
    }
  }
  if (eventName == null) return null;
  return _decodeEvent(eventName, dataJson);
}

AiStreamEvent _decodeEvent(String name, String? dataJson) {
  Map<String, dynamic> data;
  try {
    data = dataJson == null
        ? const <String, dynamic>{}
        : (jsonDecode(dataJson) as Map<String, dynamic>);
  } catch (_) {
    data = const <String, dynamic>{};
  }
  switch (name) {
    case 'message.received':
      return AiStreamMessageReceived(
        id: (data['id'] as String?) ?? '',
        isFlagged: data['is_flagged'] as bool? ?? false,
      );
    case 'message.delta':
      return AiStreamDelta((data['text'] as String?) ?? '');
    case 'message.complete':
      final suggested = data['suggested_activity'] as Map<String, dynamic>?;
      return AiStreamComplete(
        threadId: (data['thread_id'] as String?) ?? '',
        suggestedActivitySlug: suggested?['slug'] as String?,
        suggestedActivityName: suggested?['name'] as String?,
      );
    case 'message.error':
      return AiStreamError((data['message'] as String?) ?? 'ما قدرنا نستلم الرد، جرّب مرة ثانية.');
    default:
      // Unknown event — yield empty delta to keep callers moving.
      return const AiStreamDelta('');
  }
}
