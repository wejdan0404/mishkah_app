import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mishkat/core/api/api_exception.dart';
import 'package:mishkat/core/auth/password_reset_service.dart';
import 'package:mishkat/screens/auth/forgot_password_screen.dart';
import 'package:mishkat/screens/auth/success_screen.dart';
import 'package:mishkat/widgets/otp_input.dart';

/// Records calls and returns/throws on cue so we can drive the staged flow
/// without hitting the network.
class _FakeResetService implements PasswordResetService {
  String? requestedEmail;
  String? verifiedCode;
  bool resetCalled = false;
  Object? verifyError;

  @override
  Future<void> requestOtp(String email) async {
    requestedEmail = email;
  }

  @override
  Future<String> verifyOtp({required String email, required String code}) async {
    verifiedCode = code;
    if (verifyError != null) throw verifyError!;
    return 'reset-token-123';
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    resetCalled = true;
  }
}

void main() {
  Future<void> pumpScreen(WidgetTester tester, _FakeResetService service) {
    return tester.pumpWidget(
      MaterialApp(
        routes: {'/signin': (_) => const Scaffold(body: Text('signin'))},
        home: ForgotPasswordScreen(service: service),
      ),
    );
  }

  Future<void> enterCode(WidgetTester tester, String code) async {
    final boxes = find.byType(TextField);
    for (int i = 0; i < 4; i++) {
      await tester.enterText(boxes.at(i), code[i]);
    }
    await tester.pump();
    await tester.pump();
  }

  testWidgets('walks email → otp → password → success', (tester) async {
    final service = _FakeResetService();
    await pumpScreen(tester, service);

    // Stage 1 — email.
    await tester.enterText(find.byType(TextField), 'user@example.com');
    await tester.tap(find.text('إرسال الرمز'));
    await tester.pump();
    await tester.pump();

    expect(service.requestedEmail, 'user@example.com');
    expect(find.byType(OtpInput), findsOneWidget);

    // Stage 2 — code.
    await enterCode(tester, '1234');
    expect(service.verifiedCode, '1234');
    expect(find.text('كلمة مرور جديدة'), findsOneWidget);

    // Stage 3 — new password.
    final pwFields = find.byType(TextField);
    await tester.enterText(pwFields.at(0), 'BrandNew1234');
    await tester.enterText(pwFields.at(1), 'BrandNew1234');
    await tester.tap(find.text('حفظ'));
    await tester.pump();
    await tester.pump();

    expect(service.resetCalled, isTrue);
    expect(find.byType(SuccessScreen), findsOneWidget);
  });

  testWidgets('shows an inline error and stays on the code step for a bad OTP',
      (tester) async {
    final service = _FakeResetService()
      ..verifyError = const ApiException(
        statusCode: 422,
        code: 'OTP_INVALID',
        message: 'bad',
      );
    await pumpScreen(tester, service);

    await tester.enterText(find.byType(TextField), 'user@example.com');
    await tester.tap(find.text('إرسال الرمز'));
    await tester.pump();
    await tester.pump();

    await enterCode(tester, '9999');

    expect(find.text('رمز التحقق غير صحيح'), findsOneWidget);
    // Still on the OTP step — no password fields yet.
    expect(find.text('كلمة مرور جديدة'), findsNothing);
  });

  testWidgets('requires a non-empty email before requesting a code',
      (tester) async {
    final service = _FakeResetService();
    await pumpScreen(tester, service);

    await tester.tap(find.text('إرسال الرمز'));
    await tester.pump();

    expect(find.text('هذا الحقل مطلوب'), findsOneWidget);
    expect(service.requestedEmail, isNull);
  });
}
