import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_error_mapper.dart';
import '../../core/auth/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/auth_input.dart';
import '../../widgets/buttons/app_button.dart';
import 'forgot_password_screen.dart';

/// Returns [s] only when it actually contains Arabic text, otherwise null —
/// so a stray English server-validation string never reaches the UI.
String? _arabicOrNull(String? s) {
  if (s == null || s.trim().isEmpty) return null;
  return RegExp('[؀-ۿ]').hasMatch(s) ? s : null;
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_isLoading) return;

    final emailError = _emailController.text.isEmpty ? 'هذا الحقل مطلوب' : null;
    final passwordError = _passwordController.text.isEmpty
        ? 'هذا الحقل مطلوب'
        : null;

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });

    if (emailError != null || passwordError != null) return;

    await _attemptLogin(restore: false);
  }

  Future<void> _attemptLogin({required bool restore}) async {
    setState(() => _isLoading = true);
    bool needsRestoreConfirm = false;
    try {
      await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        restore: restore,
      );
      if (!mounted) return;
      _onAuthSuccess();
      return;
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'ACCOUNT_PENDING_DELETE' && !restore) {
        needsRestoreConfirm = true; // ask first, then retry with restore=true
      } else {
        setState(() {
          if (e.statusCode == 401 || e.code == 'INVALID_CREDENTIALS') {
            // Anti-enumeration: a single ambiguous message (wrong email OR
            // wrong password both land here). Show it under BOTH fields so it's
            // visible whichever one the user is looking at.
            const credentialsError = 'البريد الإلكتروني أو كلمة المرور غلط';
            _emailError = credentialsError;
            _passwordError = credentialsError;
          } else if (e.isRateLimited) {
            _passwordError = 'محاولات كثيرة، نعيد المحاولة بعد شوي.';
          } else if (e.isValidation) {
            final fields = e.fieldErrors;
            // Field-level server text may be English; only trust it if it's
            // already Arabic, otherwise fall back to the mapped message.
            _emailError = _arabicOrNull(fields['email']);
            _passwordError = _arabicOrNull(fields['password']) ?? mapAuthError(e);
          } else {
            // Never surface the raw backend message — map by code/status.
            _passwordError = mapAuthError(e);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _passwordError =
              'فيه مشكلة بالاتصال، نتأكد من الشبكة ونعيد المحاولة؟',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (needsRestoreConfirm && mounted) {
      final bool? confirmed = await _confirmRestore();
      if (confirmed == true && mounted) {
        await _attemptLogin(restore: true);
      }
    }
  }

  void _onAuthSuccess() {
    showAppToast(context, 'تـم تسجيل دخولك بنجـاح', type: AppToastType.success);
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }

  /// Confirmation shown when sign-in hits ACCOUNT_PENDING_DELETE — restoring
  /// cancels the pending deletion and signs the user back in.
  Future<bool?> _confirmRestore() {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _RestoreAccountDialog(),
    );
  }

  void _onForgotPassword() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
  }

  Future<void> _onGoogle() async {
    if (_isLoading) return;
    await _attemptGoogle(restore: false);
  }

  Future<void> _attemptGoogle({required bool restore}) async {
    setState(() => _isLoading = true);
    bool needsRestoreConfirm = false;
    try {
      final user = await AuthService.signInWithGoogle(restore: restore);
      if (user == null) return; // user cancelled the Google picker
      if (!mounted) return;
      _onAuthSuccess();
      return;
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'ACCOUNT_PENDING_DELETE' && !restore) {
        needsRestoreConfirm = true;
      } else {
        showAppToast(context, mapAuthError(e), type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (needsRestoreConfirm && mounted) {
      final bool? confirmed = await _confirmRestore();
      if (confirmed == true && mounted) {
        await _attemptGoogle(restore: true);
      }
    }
  }

  void _onCreateAccount() {
    Navigator.of(context).pushReplacementNamed('/signup');
  }

  /// Enter the app in local guest browse mode (no token, no backend login).
  /// Reads are best-effort (empty/default state); actions that SAVE to the
  /// account are gated in their screens with a calm "سجّل الدخول لحفظ بياناتك."
  /// prompt. Same destination as a real sign-in so the shell behaves identically.
  void _onGuest() {
    AuthService.enterGuestMode();
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
  }

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
                    const SizedBox(height: AppSpacing.xxxxxxxl),
                    const _TitleBlock(),
                    const SizedBox(height: AppSpacing.xxxxl),
                    AuthInput(
                      hint: 'البريد الإلكتروني',
                      iconAsset: AppSvgIcons.mail,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      error: _emailError,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AuthInput(
                      hint: 'كلمة المرور',
                      iconAsset: AppSvgIcons.password,
                      controller: _passwordController,
                      textInputAction: TextInputAction.done,
                      obscureText: true,
                      error: _passwordError,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: GestureDetector(
                        onTap: _onForgotPassword,
                        child: const Text(
                          'نسيت كلمة المرور؟',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: AppFontFamily.text,
                            fontSize: AppFontSizes.xxs,
                            fontWeight: AppFontWeights.medium,
                            color: AppInformationColors.shade500,
                            decoration: TextDecoration.underline,
                            decorationColor: AppInformationColors.shade500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    AppButton(
                      label: 'تسجيل الدخول',
                      expand: true,
                      borderRadius: AppRadius.lg,
                      isLoading: _isLoading,
                      onPressed: _onSubmit,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _OrDivider(),
                    const SizedBox(height: AppSpacing.xl),
                    Center(child: _GoogleButton(onPressed: _onGoogle)),
                    const SizedBox(height: AppSpacing.lg),
                    _GuestButton(onPressed: _onGuest),
                    const SizedBox(height: AppSpacing.xxxxl),
                    _Footer(onPressed: _onCreateAccount),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'تسجيـل الدخـول',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.thmanyahTitle(context),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'أهلًا بعودتك! دخّل بياناتك وسجّل دخولك في مِشْكَاة.',
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

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Divider(color: context.colors.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'أو',
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xs,
              fontWeight: AppFontWeights.regular,
              color: context.colors.shade500,
            ),
          ),
        ),
        Expanded(child: Divider(color: context.colors.shade300)),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});

  final VoidCallback onPressed;

  static const double _height = 40;
  static const double _logoSize = 18;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.full);
    return SizedBox(
      height: _height,
      child: Material(
        color: context.colors.shade200,
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'تسجيل الدخول باستخدام',
                  style: TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.xs,
                    fontWeight: AppFontWeights.medium,
                    color: context.colors.shade700,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                SvgPicture.asset(
                  AppSvgIcons.google,
                  width: _logoSize,
                  height: _logoSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Calm outlined "تجربة كضيف" button (same outlined-pill style as the app's
/// other secondary actions). UI-only for now — see [_SignInScreenState._onGuest].
class _GuestButton extends StatelessWidget {
  const _GuestButton({required this.onPressed});

  final VoidCallback onPressed;

  static const double _height = 44;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.full);
    return Semantics(
      button: true,
      label: 'تجربة التطبيق كضيف',
      child: SizedBox(
        height: _height,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: AppPalettePurple.shade200, width: 1),
              ),
              child: const Text(
                'تجربة كضيف',
                style: TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.xs,
                  fontWeight: AppFontWeights.semibold,
                  color: AppPalettePurple.shade200,
                  height: 1.25,
                ),
              ),
            ),
          ),
        ),
      ),
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
            'ما عندك حساب؟',
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
              'إنشاء حساب',
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

class _RestoreAccountDialog extends StatelessWidget {
  const _RestoreAccountDialog();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 325,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            decoration: BoxDecoration(
              color: context.colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              boxShadow: AppShadows.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'هذا الحساب محذوف',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.thmanyahHeading(context).copyWith(
                    fontSize: AppFontSizes.sm,
                    color: context.colors.shade600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'تسجيل الدخول الآن راح يلغي الحذف ويسترجع حسابك. تبي تكمل؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.xxs,
                    fontWeight: AppFontWeights.regular,
                    color: context.colors.shade500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                AppButton(
                  label: 'نعم، استرجع حسابي',
                  expand: true,
                  borderRadius: AppRadius.lg,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: AppSpacing.md),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Text(
                      'إلغاء',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFontFamily.text,
                        fontSize: AppFontSizes.xs,
                        fontWeight: AppFontWeights.semibold,
                        color: context.colors.shade500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
