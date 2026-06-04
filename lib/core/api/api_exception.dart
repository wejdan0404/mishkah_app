import 'dart:convert';

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details,
  });

  final int statusCode;
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  factory ApiException.fromBody({
    required int statusCode,
    required String body,
  }) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final err = decoded['error'];
        if (err is Map<String, dynamic>) {
          return ApiException(
            statusCode: statusCode,
            code: (err['code'] as String?) ?? 'UNKNOWN',
            message: (err['message'] as String?) ?? 'Unknown error',
            details: (err['details'] as Map?)?.cast<String, dynamic>(),
          );
        }
      }
    } catch (_) {
      // fall through
    }
    return ApiException(
      statusCode: statusCode,
      code: 'UNKNOWN',
      message: 'Unexpected response ($statusCode).',
    );
  }

  /// For 422 VALIDATION_FAILED: returns {field: firstMessage} or {}.
  Map<String, String> get fieldErrors {
    final errors = details?['errors'];
    if (errors is! Map) return const {};
    final out = <String, String>{};
    errors.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        out[key.toString()] = value.first.toString();
      } else if (value is String) {
        out[key.toString()] = value;
      }
    });
    return out;
  }

  bool get isUnauthenticated => statusCode == 401 || code == 'UNAUTHENTICATED';
  bool get isConsentRequired => code == 'CONSENT_REQUIRED';
  bool get isValidation => code == 'VALIDATION_FAILED';
  bool get isRateLimited =>
      code == 'RATE_LIMITED' || code == 'AI_USAGE_EXCEEDED';

  @override
  String toString() => 'ApiException($statusCode $code: $message)';
}
