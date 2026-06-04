import 'package:flutter_test/flutter_test.dart';
import 'package:mishkat/models/auth_tokens.dart';

void main() {
  test('AuthTokens.fromJson handles {access, refresh} shape', () {
    final t = AuthTokens.fromJson({
      'access': 'a-token',
      'refresh': 'r-token',
      'expires_in': 3600,
      'refresh_expires_in': 2592000,
    });
    expect(t.access, 'a-token');
    expect(t.refresh, 'r-token');
    expect(t.expiresIn, 3600);
  });

  test('AuthTokens.fromJson handles {access_token, refresh_token} shape', () {
    final t = AuthTokens.fromJson({
      'access_token': 'a',
      'refresh_token': 'r',
    });
    expect(t.access, 'a');
    expect(t.refresh, 'r');
  });
}
