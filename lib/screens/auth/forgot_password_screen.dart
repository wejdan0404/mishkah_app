import 'dart:async';

import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/password_reset_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/auth_input.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/nav/app_back_button.dart';
import '../../widgets/otp_input.dart';
import 'success_screen.dart';

/// نسيت كلمة المرور؟ — a single staged screen that mirrors the sign-in screen's
/// styling and reuses [AuthInput], [OtpInput], and [AppButton]. Three steps:
/// enter email → enter the mailed code → set a new password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.service = const PasswordResetService(),
  });

  static const String routeName = '/forgot-password';

  /// Injectable so widget tests can drive the flow with a fake.
  final PasswordResetService service;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Stage { email, otp, password }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const int _resendCooldownSeconds = 60;
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  _Stage _stage = _Stage.email;
  bool _isLoading = false;
  String? _emailError;
  String? _otpError;
  String? _newPasswordError;
  String? _confirmPasswordError;
  String _resetToken = '';
  int _otpAttempt = 0; // bump to reset (clear) the code boxes

  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _email => _emailController.text.trim();

  /// Back affordance: always return to the sign-in screen, regardless of which
  /// stage of the reset flow we're on.
  void _onBack() => Navigator.of(context).maybePop();

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = _resendCooldownSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) timer.cancel();
    });
  }

  // ---- Stage 1: request the code -------------------------------------------

  Future<void> _onSubmitEmail() async {
    if (_isLoading) return;
    final String email = _email;
    final String? error = email.isEmpty
        ? 'هذا الحقل مطلوب'
        : (!_emailRegex.hasMatch(email) ? 'صيغة البريد الإلكتروني غلط' : null);
    setState(() => _emailError = error);
    if (error != null) return;

    setState(() => _isLoading = true);
    try {
      await widget.service.requestOtp(email);
      if (!mounted) return;
      setState(() {
        _stage = _Stage.otp;
        _otpError = null;
        _otpAttempt++;
      });
      _startResendCooldown();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _emailError = e.fieldErrors['email'] ?? e.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () =>
            _emailError = 'فيه مشكلة بالاتصال، تأكد من شبكتك وجرّب مرة ثانية.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onResend() async {
    if (_resendSeconds > 0 || _isLoading) return;
    await _onSubmitEmail();
  }

  // ---- Stage 2: verify the code --------------------------------------------

  Future<void> _onCodeEntered(String code) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _otpError = null;
    });
    try {
      final String token = await widget.service.verifyOtp(
        email: _email,
        code: code,
      );
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      setState(() {
        _resetToken = token;
        _stage = _Stage.password;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _otpError = e.code == 'OTP_INVALID'
            ? 'رمز التحقق غير صحيح'
            : (e.fieldErrors['code'] ?? e.message);
        _otpAttempt++; // clear the boxes for another try
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _otpError = 'فيه مشكلة بالاتصال، تأكد من شبكتك وجرّب مرة ثانية.';
        _otpAttempt++;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---- Stage 3: set the new password ---------------------------------------

  Future<void> _onSubmitPassword() async {
    if (_isLoading) return;
    final String newPw = _newPasswordController.text;
    final String confirmPw = _confirmPasswordController.text;

    String? newError;
    String? confirmError;
    if (newPw.isEmpty) {
      newError = 'دخّل كلمة المرور الجديدة';
    } else if (newPw.length < 10) {
      newError = 'كلمة المرور لازم 10 أحرف على الأقل';
    }
    if (confirmPw != newPw) {
      confirmError = 'كلمة المرور غير متطابقة';
    }
    setState(() {
      _newPasswordError = newError;
      _confirmPasswordError = confirmError;
    });
    if (newError != null || confirmError != null) return;

    setState(() => _isLoading = true);
    try {
      await widget.service.resetPassword(
        email: _email,
        token: _resetToken,
        password: newPw,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SuccessScreen(
            title: 'تم تغيير كلمة المرور بنجاح',
            subtitle: 'سجّل دخولك بكلمة المرور الجديدة.',
            buttonLabel: 'تسجيل الدخول',
            onContinue: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/signin', (_) => false),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'INVALID_CREDENTIALS') {
          // The reset token expired — send them back to re-request a code.
          _otpError = 'انتهت صلاحية الرمز، اطلب رمزاً جديداً.';
          _stage = _Stage.email;
        } else {
          final fields = e.fieldErrors;
          _newPasswordError =
              fields['password'] ?? fields['new_password'] ?? e.message;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _newPasswordError =
            'فيه مشكلة بالاتصال، تأكد من شبكتك وجرّب مرة ثانية.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---- UI -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.shade50,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              // A warm-gold glow painted OVER the scaffold background, fading to a fully
              // transparent version of the SAME gold so it dims into the bg (light or
              // dark) without greying. A near-white fade would read as grey over a dark
              // bg, so the glow stays gold the whole way down and is theme-independent.
              stops: const [0.00, 0.07, 0.15, 0.26],
              colors: [
                AppPaletteButteryYellow.shade200,
                AppPaletteButteryYellow.shade200.withValues(alpha: 0.55),
                AppPaletteButteryYellow.shade200.withValues(alpha: 0.22),
                AppPaletteButteryYellow.shade200.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AppBackButton(onTap: _onBack),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _Header(title: _title, subtitle: _subtitle),
                    const SizedBox(height: AppSpacing.xxxxl),
                    ..._stageBody(),
                    if (_stage == _Stage.email) ...[
                      const SizedBox(height: AppSpacing.xxxxl),
                      _Footer(
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _title {
    switch (_stage) {
      case _Stage.email:
        return 'نسيت كلمة المرور؟';
      case _Stage.otp:
        return 'أدخل رمز التحقق';
      case _Stage.password:
        return 'كلمة مرور جديدة';
    }
  }

  String get _subtitle {
    switch (_stage) {
      case _Stage.email:
        return 'ادخل بريدك الإلكتروني عشان نقدر نساعدك تسترجع حسابك.';
      case _Stage.otp:
        return 'أرسلنا رمز تحقق إلى $_email أدخله لإكمال المتابعة.';
      case _Stage.password:
        return 'ادخل كلمة المرور الجديدة لحسابك.';
    }
  }

  List<Widget> _stageBody() {
    switch (_stage) {
      case _Stage.email:
        return [
          AuthInput(
            hint: 'البريد الإلكتروني',
            iconAsset: AppSvgIcons.mail,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            error: _emailError,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          AppButton(
            label: 'إرسال الرمز',
            expand: true,
            borderRadius: AppRadius.lg,
            isLoading: _isLoading,
            onPressed: _onSubmitEmail,
          ),
        ];
      case _Stage.otp:
        return [
          OtpInput(
            key: ValueKey<int>(_otpAttempt),
            enabled: !_isLoading,
            onCompleted: _onCodeEntered,
          ),
          if (_otpError != null) ...[
            const SizedBox(height: AppSpacing.md),
            _InlineError(message: _otpError!),
          ],
          const SizedBox(height: AppSpacing.sm),
          _ResendRow(seconds: _resendSeconds, onResend: _onResend),
        ];
      case _Stage.password:
        return [
          AuthInput(
            hint: 'كلمة المرور الجديدة',
            iconAsset: AppSvgIcons.password,
            controller: _newPasswordController,
            textInputAction: TextInputAction.next,
            obscureText: true,
            error: _newPasswordError,
          ),
          const SizedBox(height: AppSpacing.lg),
          AuthInput(
            hint: 'تأكيد كلمة المرور',
            iconAsset: AppSvgIcons.password,
            controller: _confirmPasswordController,
            textInputAction: TextInputAction.done,
            obscureText: true,
            error: _confirmPasswordError,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          AppButton(
            label: 'حفظ',
            expand: true,
            borderRadius: AppRadius.lg,
            isLoading: _isLoading,
            onPressed: _onSubmitPassword,
          ),
        ];
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.thmanyahTitle(context),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: AppFontFamily.text,
            fontSize: AppFontSizes.xs,
            fontWeight: AppFontWeights.regular,
            color: context.colors.shade500,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ResendRow extends StatelessWidget {
  const _ResendRow({required this.seconds, required this.onResend});

  final int seconds;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final bool waiting = seconds > 0;
    final String timerLabel =
        '${(seconds ~/ 60)}:${(seconds % 60).toString().padLeft(2, '0')}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ما وصلك الرمز؟',
              style: TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.xs,
                fontWeight: AppFontWeights.regular,
                color: context.colors.shade500,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            GestureDetector(
              onTap: waiting ? null : onResend,
              child: Text(
                'إعادة الإرسال',
                style: TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.xs,
                  fontWeight: AppFontWeights.semibold,
                  color: waiting
                      ? context.colors.shade400
                      : AppPalettePurple.shade100,
                ),
              ),
            ),
          ],
        ),
        if (waiting)
          Text(
            timerLabel,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xs,
              fontWeight: AppFontWeights.regular,
              color: context.colors.shade400,
            ),
          ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline,
          size: 16,
          color: AppDangerColors.shade500,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            message,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xxs,
              fontWeight: AppFontWeights.regular,
              color: AppDangerColors.shade500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'تذكرت كلمة المرور؟',
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xs,
              fontWeight: AppFontWeights.regular,
              color: context.colors.shade500,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          GestureDetector(
            onTap: onPressed,
            child: const Text(
              'تسجيل الدخول',
              style: TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.xs,
                fontWeight: AppFontWeights.semibold,
                color: AppPalettePurple.shade100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
