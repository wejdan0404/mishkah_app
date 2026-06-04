import 'package:flutter_test/flutter_test.dart';
import 'package:mishkat/core/api/api_exception.dart';

void main() {
  group('ApiException.fromBody', () {
    test('parses standard error envelope', () {
      final exc = ApiException.fromBody(
        statusCode: 422,
        body:
            '{"error":{"code":"VALIDATION_FAILED","message":"Validation failed.","details":{"errors":{"email":["taken"]}}}}',
      );
      expect(exc.statusCode, 422);
      expect(exc.code, 'VALIDATION_FAILED');
      expect(exc.message, 'Validation failed.');
      expect(exc.details, isNotNull);
      expect((exc.details!['errors'] as Map)['email'], ['taken']);
    });

    test('falls back when body is not valid envelope', () {
      final exc = ApiException.fromBody(statusCode: 500, body: 'oops');
      expect(exc.statusCode, 500);
      expect(exc.code, 'UNKNOWN');
      expect(exc.message, isNotEmpty);
    });

    test('fieldErrors returns flat map for validation', () {
      const exc = ApiException(
        statusCode: 422,
        code: 'VALIDATION_FAILED',
        message: 'x',
        details: {
          'errors': {
            'email': ['taken'],
            'password': ['too short', 'no uppercase'],
          },
        },
      );
      expect(exc.fieldErrors, {
        'email': 'taken',
        'password': 'too short',
      });
    });
  });
}
