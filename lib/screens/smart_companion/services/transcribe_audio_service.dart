import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/api/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';

class TranscribeException implements Exception {
  TranscribeException(this.message);
  final String message;
  @override
  String toString() => 'TranscribeException: $message';
}

/// Sends a recorded clip to the Mishkat backend (`POST /api/v1/ai/transcribe`)
/// and returns its transcript. Authenticates with the same bearer token as the
/// rest of the API — no separate service to keep alive.
class TranscribeAudioService {
  TranscribeAudioService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static final Uri _endpoint =
      Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.aiTranscribe}');

  Future<String> transcribe(File audioFile) async {
    final request = http.MultipartRequest('POST', _endpoint)
      ..headers['Accept'] = 'application/json'
      ..files.add(await http.MultipartFile.fromPath('file', audioFile.path));

    final String? token = TokenStorage.instance.accessToken;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    final streamed = await _client.send(request);
    final res = await http.Response.fromStream(streamed);

    final Map<String, dynamic> body = _decode(res.bodyBytes);

    if (res.statusCode == 200) {
      final data = body['data'] as Map<String, dynamic>?;
      final String? transcript = data?['transcript'] as String?;
      if (transcript == null || transcript.trim().isEmpty) {
        throw TranscribeException('ما طلع نص من التسجيل، جرّب مرة ثانية.');
      }
      return transcript;
    }

    // The backend returns Arabic, user-facing copy in error.message — surface
    // it directly so the toast matches the server's intent.
    final error = body['error'] as Map<String, dynamic>?;
    final String? message = error?['message'] as String?;
    throw TranscribeException(
      message ?? 'ما قدرت أحوّل التسجيل، جرّب مرة ثانية.',
    );
  }

  Map<String, dynamic> _decode(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
