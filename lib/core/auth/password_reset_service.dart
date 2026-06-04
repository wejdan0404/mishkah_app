import '../api/api_client.dart';
import '../api/api_endpoints.dart';

/// Drives the email-OTP forgot-password flow against the backend:
///   1. [requestOtp] — POST the email; the server mails a 4-digit code
///      (always succeeds, even for unknown emails, to avoid enumeration).
///   2. [verifyOtp] — POST email + code; returns a single-use reset token.
///   3. [resetPassword] — POST email + token + new password.
///
/// An instance class (not all-static) so screens can inject a fake in tests.
/// Throws [ApiException] on failure — callers map `OTP_INVALID` / validation
/// codes to inline messages.
class PasswordResetService {
  const PasswordResetService();

  Future<void> requestOtp(String email) async {
    await ApiClient.instance.post(
      ApiEndpoints.forgotPassword,
      auth: false,
      body: {'email': email.trim()},
    );
  }

  /// Returns the single-use reset token on success.
  Future<String> verifyOtp({required String email, required String code}) async {
    final data = await ApiClient.instance.post(
      ApiEndpoints.verifyResetOtp,
      auth: false,
      body: {'email': email.trim(), 'code': code},
    ) as Map<String, dynamic>;
    return data['reset_token'] as String;
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    await ApiClient.instance.post(
      ApiEndpoints.resetPassword,
      auth: false,
      body: {
        'email': email.trim(),
        'token': token,
        'password': password,
        'password_confirmation': password,
      },
    );
  }
}
