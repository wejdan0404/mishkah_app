import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_service.dart';
import '../../models/user.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_loader.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_section_card.dart';
import '../../widgets/nav/app_top_nav.dart';
import '../../widgets/otp_input.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  static const String routeName = '/edit-profile';

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  String _initialName = '';
  String _initialEmail = '';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _requestingOtp = false;
  String? _loadError;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  String? _emailError;
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _passwordSuccess;
  bool _hasChanges = false;

  // Email changes go through a separate verify flow (not the save button), so
  // the 4-digit code input expands inline once the user taps "verify".
  bool _showEmailVerify = false;
  bool _verifyingCode = false; // loader while the entered code is checked
  bool _emailVerified = false; // green "تم التحقق" state, ready to save
  String? _otpError; // red error under the code boxes
  int _otpAttempt = 0; // bump to reset (clear) the code boxes

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_recomputeHasChanges);
    _emailController.addListener(_onEmailChanged);
    _currentPasswordController.addListener(_recomputeHasChanges);
    _newPasswordController.addListener(_recomputeHasChanges);
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final User? user =
          AuthService.currentUser ?? await AuthService.fetchCurrentUser();
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _loadError = 'ما قدرنا نحمّل بياناتك، سجّل دخولك من جديد.';
        });
        return;
      }
      setState(() {
        _initialName = user.name;
        _initialEmail = user.email;
        _nameController.text = user.name;
        _emailController.text = user.email;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.message;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _recomputeHasChanges() {
    // Email is excluded — it's saved via its own verify flow, not this button.
    final bool changed =
        _nameController.text != _initialName ||
        _currentPasswordController.text.isNotEmpty ||
        _newPasswordController.text.isNotEmpty;
    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  void _onEmailChanged() {
    // Any edit to the email invalidates a prior verify step — start over.
    _showEmailVerify = false;
    _emailVerified = false;
    _verifyingCode = false;
    _otpError = null;
    setState(() {});
  }

  /// Request an OTP to the NEW email, then expand the code boxes. Surfaces a
  /// field error (e.g. the address is already taken) under the email input.
  Future<void> _onRequestEmailOtp() async {
    if (_requestingOtp) return; // guard against a double-tap → two OTP emails
    final String email = _emailController.text.trim();
    setState(() {
      _requestingOtp = true;
      _emailError = null;
      _otpError = null;
    });
    try {
      await AuthService.requestEmailChangeOtp(email);
      if (!mounted) return;
      setState(() {
        _showEmailVerify = true;
        _otpAttempt++;
      });
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
      if (mounted) setState(() => _requestingOtp = false);
    }
  }

  Future<void> _onCodeEntered(String code) async {
    setState(() {
      _verifyingCode = true;
      _otpError = null;
    });
    try {
      // Verifying the code applies the email change server-side and marks the
      // address verified; we reflect that locally on success.
      await AuthService.verifyEmailChangeOtp(
        newEmail: _emailController.text.trim(),
        code: code,
      );
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      setState(() {
        _verifyingCode = false;
        _showEmailVerify = false;
        _emailVerified = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _verifyingCode = false;
        _otpError = e.code == 'OTP_INVALID' ? 'رمز التحقق غير صحيح' : e.message;
        _otpAttempt++;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifyingCode = false;
        _otpError = 'فيه مشكلة بالاتصال، تأكد من شبكتك وجرّب مرة ثانية.';
        _otpAttempt++;
      });
    }
  }

  Widget _buildEmailSection() {
    final String emailText = _emailController.text.trim();
    final bool emailChanged =
        emailText.isNotEmpty && emailText != _initialEmail;
    final bool emailValidFormat = _emailRegex.hasMatch(emailText);
    final bool showFieldError =
        _emailError != null || (emailChanged && !emailValidFormat);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Field(
          label: 'البريد الإلكتروني',
          error: _emailError,
          child: _EditInput(
            controller: _emailController,
            iconAsset: AppSvgIcons.mail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            hasError: showFieldError,
          ),
        ),
        if (_emailError == null && emailChanged) ...[
          if (!emailValidFormat) ...[
            const SizedBox(height: AppSpacing.xs),
            const _InlineError(message: 'صيغة البريد الإلكتروني غلط'),
          ] else if (_emailVerified) ...[
            const SizedBox(height: AppSpacing.xs),
            const _EmailVerifiedBadge(),
          ] else if (!_showEmailVerify) ...[
            const SizedBox(height: AppSpacing.xs),
            _EmailVerifyLink(onTap: _onRequestEmailOtp),
          ] else ...[
            const SizedBox(height: AppSpacing.xxxl),
            _Field(
              label: 'أدخل رمز التحقق',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OtpInput(
                    key: ValueKey<int>(_otpAttempt),
                    enabled: !_verifyingCode,
                    onCompleted: _onCodeEntered,
                  ),
                  if (_verifyingCode) ...[
                    const SizedBox(height: AppSpacing.md),
                    const Center(child: AppLoader(size: 32)),
                  ] else if (_otpError != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _InlineError(message: _otpError!),
                  ],
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _onSave() async {
    if (_isSaving) return;
    final String currentPw = _currentPasswordController.text;
    final String newPw = _newPasswordController.text;
    final bool wantsPasswordChange = currentPw.isNotEmpty || newPw.isNotEmpty;

    // Email is not part of this save — it has its own verify flow.
    String? currentPwError;
    String? newPwError;

    // Password rules — only enforced if either field has content. Both must
    // be set, the new password is 8+ chars, and it can't match the current
    // one (mirrors the backend ChangePasswordRequest so we don't ping the
    // server to learn the same thing).
    if (wantsPasswordChange) {
      if (currentPw.isEmpty) {
        currentPwError = 'دخّل كلمة المرور الحالية';
      }
      if (newPw.isEmpty) {
        newPwError = 'دخّل كلمة المرور الجديدة';
      } else if (newPw.length < 8) {
        newPwError = 'كلمة المرور الجديدة لازم 8 أحرف على الأقل';
      } else if (newPw == currentPw) {
        newPwError = 'كلمة المرور الجديدة لازم تكون مختلفة عن الحالية';
      }
    }

    setState(() {
      _emailError = null;
      _currentPasswordError = currentPwError;
      _newPasswordError = newPwError;
      _passwordSuccess = null;
    });

    if (currentPwError != null || newPwError != null) {
      return;
    }

    final NavigatorState navigator = Navigator.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _SaveChangesDialog(),
    );
    if (!mounted) return;
    if (confirmed != true) return;

    setState(() => _isSaving = true);
    final bool emailVerifiedChange = _emailVerified;
    try {
      final String name = _nameController.text.trim();
      final bool nameChanged = name != _initialName;
      if (nameChanged) {
        await AuthService.updateProfile(name: name);
      }

      if (wantsPasswordChange) {
        await AuthService.changePassword(
          currentPassword: currentPw,
          newPassword: newPw,
        );
        if (!mounted) return;
        // Server kept this token alive; just clear local state so the form
        // doesn't keep the user's plaintext password sitting in memory.
        _currentPasswordController.clear();
        _newPasswordController.clear();
        setState(() {
          _passwordSuccess = 'تم تغيير كلمة المرور بنجاح';
        });
      }

      if (emailVerifiedChange) {
        // The email was already applied server-side when the OTP was verified;
        // sync local state so the field shows it as the current address.
        _initialEmail = _emailController.text.trim();
      }

      if (!mounted) return;
      setState(() => _emailVerified = false);
      if (wantsPasswordChange) {
        showAppToast(context, 'تم تغيير كلمة المرور بنجاح');
      } else if (nameChanged || emailVerifiedChange) {
        showAppToast(context, 'تم حفظ المعلومات');
      }
      navigator.maybePop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.isValidation) {
          final f = e.fieldErrors;
          if (f.containsKey('current_password')) {
            _currentPasswordError = f['current_password'];
          }
          if (f.containsKey('new_password')) {
            _newPasswordError = f['new_password'];
          }
          if (f.containsKey('name') || f.containsKey('email')) {
            _emailError = f['name'] ?? f['email'];
          }
          if (_currentPasswordError == null &&
              _newPasswordError == null &&
              _emailError == null) {
            _emailError = e.message;
          }
        } else {
          _emailError = e.message;
        }
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _onDeleteAccount() async {
    final NavigatorState navigator = Navigator.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (!mounted) return;
    if (confirmed != true) return;

    try {
      await AuthService.deleteAccount();
      if (!mounted) return;
      navigator.pushNamedAndRemoveUntil('/signin', (_) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        e.code == 'CONFLICT' ? 'طلب الحذف مقدّم من قبل.' : e.message,
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.shade50,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppTopNav(title: 'تعديل الملف الشخصي'),
              const SizedBox(height: AppSpacing.xxxl),
              Expanded(
                child: _isLoading
                    ? const Center(child: AppLoader())
                    : _loadError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Text(
                            _loadError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: AppFontFamily.text,
                              fontSize: AppFontSizes.sm,
                              color: AppDangerColors.shade500,
                            ),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xxl,
                          0,
                          AppSpacing.xxl,
                          AppSpacing.xl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Field(
                              label: 'الاسم الثنائي',
                              child: _EditInput(
                                controller: _nameController,
                                iconAsset: AppSvgIcons.user,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxxl),
                            _buildEmailSection(),
                            const SizedBox(height: AppSpacing.xxxl),
                            _Field(
                              label: 'كلمة المرور الحالية',
                              error: _currentPasswordError,
                              child: _EditInput(
                                controller: _currentPasswordController,
                                iconAsset: AppSvgIcons.password,
                                textInputAction: TextInputAction.next,
                                obscureText: true,
                                placeholder: '********',
                                hasError: _currentPasswordError != null,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxxl),
                            _Field(
                              label: 'كلمة المرور الجديدة',
                              error: _newPasswordError,
                              child: _EditInput(
                                controller: _newPasswordController,
                                iconAsset: AppSvgIcons.password,
                                textInputAction: TextInputAction.done,
                                obscureText: true,
                                placeholder: '********',
                                hasError: _newPasswordError != null,
                              ),
                            ),
                            if (_passwordSuccess != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              _InlineSuccess(message: _passwordSuccess!),
                            ],
                            const SizedBox(height: AppSpacing.xxxl),
                            _DeleteAccountButton(onTap: _onDeleteAccount),
                          ],
                        ),
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.md,
                    AppSpacing.xxl,
                    AppSpacing.md,
                  ),
                  child: AppButton(
                    label: 'حفظ التعديلات',
                    expand: true,
                    isLoading: _isSaving,
                    onPressed: (_hasChanges || _emailVerified) && !_isSaving
                        ? _onSave
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child, this.error});

  final String label;
  final Widget child;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.right,
          style: AppTextStyles.thmanyahHeading(context).copyWith(
            fontSize: AppFontSizes.xs,
            color: context.colors.shade700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        child,
        if (error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          _InlineError(message: error!),
        ],
      ],
    );
  }
}

class _InlineSuccess extends StatelessWidget {
  const _InlineSuccess({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppSuccessColors.shade500,
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
                color: AppSuccessColors.shade500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
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
      ),
    );
  }
}

class _EditInput extends StatefulWidget {
  const _EditInput({
    required this.controller,
    required this.iconAsset,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.placeholder,
    this.hasError = false,
  });

  final TextEditingController controller;
  final String iconAsset;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final String? placeholder;
  final bool hasError;

  @override
  State<_EditInput> createState() => _EditInputState();
}

class _EditInputState extends State<_EditInput> {
  static const double _minHeight = 44;
  static const double _iconSize = 20;
  static const double _pencilSize = 16;

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

  void _handleFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final bool focused = _focusNode.hasFocus;
    final Color textColor = focused
        ? context.colors.shade500
        : context.colors.shade700;

    final Border border = widget.hasError
        ? Border.all(color: AppDangerColors.shade500, width: 1)
        : focused
        ? Border.all(color: AppPalettePurple.shade300, width: 1)
        : Border.all(color: context.colors.shade300, width: 0.5);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minHeight),
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
              colorFilter: const ColorFilter.mode(
                AppPalettePurple.shade200,
                BlendMode.srcIn,
              ),
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
                  hintText: widget.placeholder,
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
            const SizedBox(width: AppSpacing.xs),
            SvgPicture.asset(
              AppSvgIcons.profileEditPencil,
              width: _pencilSize,
              height: _pencilSize,
              colorFilter: focused
                  ? ColorFilter.mode(textColor, BlendMode.srcIn)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton({required this.onTap});

  final VoidCallback onTap;

  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      onTap: onTap,
      borderColor: AppDangerColors.shade400,
      color: context.forDark(context.colors.white, AppDangerColors.shade950),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SvgPicture.asset(
            AppSvgIcons.profileDeleteAccount,
            width: _iconSize,
            height: _iconSize,
            colorFilter: ColorFilter.mode(
              context.forDark(
                AppDangerColors.shade400,
                AppDangerColors.shade100,
              ),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Text(
            'حذف الحساب',
            style: AppTextStyles.thmanyahCaption(context).copyWith(
              color: context.forDark(
                AppDangerColors.shade500,
                AppDangerColors.shade25,
              ),
              fontSize: AppFontSizes.sm,
              fontWeight: AppFontWeights.semibold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveChangesDialog extends StatelessWidget {
  const _SaveChangesDialog();

  static const double _iconSize = 64;

  @override
  Widget build(BuildContext context) {
    return _ConfirmationDialog(
      icon: SvgPicture.asset(
        AppSvgIcons.profileEditModal,
        width: _iconSize,
        height: _iconSize,
      ),
      title: 'تبي تحفظ تعديلاتك؟',
      description: 'تعديلاتك بتنحفظ على طول،\nوتقدر تعدّلها وقت ما تبي.',
      primary: _DialogPrimary(
        label: 'حفظ',
        onTap: () => Navigator.of(context).pop(true),
      ),
      secondary: _DialogSecondary(
        label: 'إلغاء',
        onTap: () => Navigator.of(context).pop(false),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatelessWidget {
  const _DeleteAccountDialog();

  static const double _iconSize = 64;

  @override
  Widget build(BuildContext context) {
    return _ConfirmationDialog(
      icon: SvgPicture.asset(
        AppSvgIcons.profileDeleteModal,
        width: _iconSize,
        height: _iconSize,
      ),
      title: 'تبي تحذف حسابك؟',
      description: 'بياناتك بتنحذف نهائيًا وما ترجع،\nخذ وقتك زين قبل ما تأكد.',
      primary: _DialogPrimary(
        label: 'حذف الحساب',
        backgroundColor: AppDangerColors.shade500,
        onTap: () => Navigator.of(context).pop(true),
      ),
      secondary: _DialogSecondary(
        label: 'إلغاء',
        borderColor: context.colors.shade300,
        textColor: context.colors.shade700,
        onTap: () => Navigator.of(context).pop(false),
      ),
    );
  }
}

class _ConfirmationDialog extends StatelessWidget {
  const _ConfirmationDialog({
    required this.icon,
    required this.title,
    required this.description,
    required this.primary,
    required this.secondary,
  });

  final Widget icon;
  final String title;
  final String description;
  final Widget primary;
  final Widget secondary;

  static const double _width = 325;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: _width,
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
                Center(child: icon),
                const SizedBox(height: AppSpacing.xxxl),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.thmanyahHeading(context).copyWith(
                    fontSize: AppFontSizes.sm,
                    color: context.colors.shade600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.xxs,
                    fontWeight: AppFontWeights.regular,
                    color: context.colors.shade500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Row(
                  children: [
                    Expanded(child: primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: secondary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogPrimary extends StatelessWidget {
  const _DialogPrimary({
    required this.label,
    required this.onTap,
    this.backgroundColor = AppPalettePurple.shade200,
  });

  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: backgroundColor,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: AppShadows.xs,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xs,
              fontWeight: AppFontWeights.semibold,
              color: AppNeutralColors.white,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogSecondary extends StatelessWidget {
  const _DialogSecondary({
    required this.label,
    required this.onTap,
    this.borderColor = AppPalettePurple.shade200,
    this.textColor = AppPalettePurple.shade200,
  });

  final String label;
  final VoidCallback onTap;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: context.colors.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xs,
              fontWeight: AppFontWeights.semibold,
              color: textColor,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Blue, tappable "verify your new email" affordance shown under the email
/// field once the user changes it. Tapping it reveals the [_OtpInput].
class _EmailVerifyLink extends StatelessWidget {
  const _EmailVerifyLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                AppSvgIcons.verify,
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  AppInformationColors.shade500,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Text(
                'تحقق',
                style: TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.xxs,
                  fontWeight: AppFontWeights.medium,
                  color: AppInformationColors.shade500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Non-tappable green "تم التحقق" badge shown once the new email is verified.
class _EmailVerifiedBadge extends StatelessWidget {
  const _EmailVerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              AppSvgIcons.verify,
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(
                AppSuccessColors.shade400,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Text(
              'تم التحقق',
              style: TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.xxs,
                fontWeight: AppFontWeights.medium,
                color: AppSuccessColors.shade400,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
