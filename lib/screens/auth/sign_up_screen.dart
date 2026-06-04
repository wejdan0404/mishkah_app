import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_error_mapper.dart';
import '../../core/auth/auth_service.dart';
import '../../core/auth/password_validator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/auth/password_requirements_checklist.dart';
import '../../widgets/buttons/app_button.dart';
import 'success_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_isLoading) return;

    final nameError = _nameController.text.isEmpty ? 'هذا الحقل مطلوب' : null;
    final emailError = _emailController.text.isEmpty ? 'هذا الحقل مطلوب' : null;
    final passwordError = _passwordController.text.isEmpty
        ? 'هذا الحقل مطلوب'
        : (!PasswordValidator.isValid(_passwordController.text)
              ? 'شروط كلمة المرور غير مكتملة'
              : null);
    final confirmPasswordError = _confirmPasswordController.text.isEmpty
        ? 'هذا الحقل مطلوب'
        : (_confirmPasswordController.text != _passwordController.text
              ? 'كلمة المرور ما تتطابق'
              : null);

    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
    });

    if (nameError != null ||
        emailError != null ||
        passwordError != null ||
        confirmPasswordError != null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const SuccessScreen(
            title: 'تـم إنشـاء حسابـك بنجـاح',
            subtitle: 'ابدأ مع مِشْكَاة وعزز صحتك النفسية.',
            buttonLabel: 'ابدأ الآن',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.isValidation) {
          final f = e.fieldErrors;
          _emailError = _arabicFieldError(f['email']);
          _passwordError = _arabicFieldError(f['password']);
          _nameError = _arabicFieldError(f['name']);
        } else if (e.isRateLimited) {
          _emailError = 'محاولات كثيرة، نعيد المحاولة بعد شوي.';
        } else {
          // Never surface the raw backend message — map by code/status.
          _emailError = mapAuthError(e);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () =>
            _emailError = 'فيه مشكلة بالاتصال، نتأكد من الشبكة ونعيد المحاولة؟',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _arabicFieldError(String? serverMsg) {
    if (serverMsg == null) return null;
    final m = serverMsg.toLowerCase();
    if (m.contains('already been taken')) return 'البريد الإلكتروني مستخدم.';
    if (m.contains('must be at least') && m.contains('character')) {
      return 'كلمة المرور قصيرة، لازم 8 أحرف على الأقل.';
    }
    if (m.contains('confirmation does not match')) {
      return 'كلمة المرور ما تتطابق.';
    }
    // Unknown server text may be English — show a safe Arabic message instead
    // of leaking the raw backend string.
    return 'بعض البيانات غير صحيحة، نعيد المحاولة؟';
  }

  Future<void> _onGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.signInWithGoogle();
      if (user == null) return; // user cancelled the Google picker
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const SuccessScreen(
            title: 'تـم إنشـاء حسابـك بنجـاح',
            subtitle: 'ابدأ مع مِشْكَاة وعزز صحتك النفسية.',
            buttonLabel: 'ابدأ الآن',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppToast(context, mapAuthError(e), type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSignIn() {
    Navigator.of(context).pushReplacementNamed('/signin');
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
                    _AuthInput(
                      hint: 'الاسم الثنائي',
                      iconAsset: AppSvgIcons.user,
                      controller: _nameController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      error: _nameError,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _AuthInput(
                      hint: 'البريد الإلكتروني',
                      iconAsset: AppSvgIcons.mail,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      error: _emailError,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _AuthInput(
                      hint: 'كلمة المرور',
                      iconAsset: AppSvgIcons.password,
                      controller: _passwordController,
                      textInputAction: TextInputAction.next,
                      obscureText: true,
                      error: _passwordError,
                    ),
                    // Live password requirements — appears once the user starts
                    // typing and updates as each rule is met.
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _passwordController,
                      builder: (context, value, _) {
                        if (value.text.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: PasswordRequirementsChecklist(
                            password: value.text,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _AuthInput(
                      hint: 'تأكيد كلمة المرور',
                      iconAsset: AppSvgIcons.password,
                      controller: _confirmPasswordController,
                      textInputAction: TextInputAction.done,
                      obscureText: true,
                      error: _confirmPasswordError,
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    AppButton(
                      label: 'إنشاء حساب',
                      expand: true,
                      borderRadius: AppRadius.lg,
                      isLoading: _isLoading,
                      onPressed: _onSubmit,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _OrDivider(),
                    const SizedBox(height: AppSpacing.xl),
                    Center(child: _GoogleButton(onPressed: _onGoogle)),
                    const SizedBox(height: AppSpacing.xxxxl),
                    _Footer(onPressed: _onSignIn),
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
          'إنشــاء حســاب',
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.thmanyahTitle(context),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'عبّي بياناتك وأنشئ حسابك في مِشْكَاة.',
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

class _AuthInput extends StatefulWidget {
  const _AuthInput({
    required this.hint,
    required this.iconAsset,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.error,
  });

  final String hint;
  final String iconAsset;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final String? error;

  @override
  State<_AuthInput> createState() => _AuthInputState();
}

class _AuthInputState extends State<_AuthInput> {
  static const double _minHeight = 44;
  static const double _minWidth = 200;
  static const double _iconSize = 20;

  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.error != null;
    final bool focused = _focusNode.hasFocus;

    final Color accentColor = hasError
        ? AppDangerColors.shade500
        : focused
        ? AppPalettePurple.shade300
        : context.colors.shade400;

    final Color textColor = focused
        ? context.colors.shade500
        : context.colors.shade700;

    final Border border = (hasError || focused)
        ? Border.all(color: accentColor, width: 1)
        : Border.all(color: context.colors.shade300, width: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: _minHeight,
            minWidth: _minWidth,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: border,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  widget.iconAsset,
                  width: _iconSize,
                  height: _iconSize,
                  colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: TextField(
                    focusNode: _focusNode,
                    controller: widget.controller,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    obscureText: widget.obscureText,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    cursorColor: AppPalettePurple.shade300,
                    style: TextStyle(
                      fontFamily: AppFontFamily.text,
                      fontSize: AppFontSizes.sm,
                      fontWeight: AppFontWeights.regular,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: TextStyle(
                        fontFamily: AppFontFamily.text,
                        fontSize: AppFontSizes.sm,
                        fontWeight: AppFontWeights.regular,
                        color: context.colors.shade400,
                      ),
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _ErrorMessage(message: widget.error!),
          ),
        ],
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  static const double _iconSize = 16;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: _iconSize,
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
      ),
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
                  'إنشاء حساب باستخدام',
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
            'عندك حساب؟',
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
