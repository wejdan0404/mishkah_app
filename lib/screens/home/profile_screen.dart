import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../constants/app_icons.dart';
import '../../constants/permission_copy.dart';
import '../../core/auth/auth_service.dart';
import '../../core/notifications/push_service.dart';
import '../../core/permissions/permission_flow.dart';
import '../../core/theme/theme_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/buttons/ai_floating_button.dart';
import '../../widgets/cards/app_section_card.dart';
import '../../widgets/nav/app_top_nav.dart';
import 'main_shell.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  bool _darkMode = ThemeController.instance.isDark;
  bool _notifications = false;
  bool _isLoggingOut = false;
  bool _permissionLoaded = false;
  bool _togglingNotifications = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPermissionStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-read the real OS permission when returning from the system Settings
    // page, so the toggle mirrors whatever the user changed there.
    if (state == AppLifecycleState.resumed) {
      _loadPermissionStatus();
    }
  }

  /// Mirror the real OS notification permission onto the toggle.
  Future<void> _loadPermissionStatus() async {
    final PermissionStatus status = await Permission.notification.status;
    if (!mounted) return;
    setState(() {
      _notifications = status.isGranted;
      _permissionLoaded = true;
    });
  }

  Future<void> _onLogout() async {
    if (_isLoggingOut) return;
    final NavigatorState navigator = Navigator.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _LogoutConfirmationDialog(),
    );
    if (!mounted) return;
    if (confirmed != true) return;

    setState(() => _isLoggingOut = true);
    // AuthService.logout() is best-effort: it swallows server errors and
    // always clears local tokens, so we never need to branch on the result.
    await AuthService.logout();
    if (!mounted) return;
    navigator.pushNamedAndRemoveUntil('/signin', (_) => false);
  }

  void _onOpenAi() {
    Navigator.of(context).pushNamed('/smart-companion');
  }

  Future<void> _onNotificationsChanged(bool v) async {
    if (_togglingNotifications || !_permissionLoaded) return;
    if (v) {
      await _enableNotifications();
    } else {
      await _disableNotifications();
    }
  }

  /// Turn notifications ON via the shared Apple-standard flow, then mirror the
  /// real OS result onto the toggle and register the push token if granted.
  Future<void> _enableNotifications() async {
    setState(() => _togglingNotifications = true);
    final bool granted = await runPermissionFlow(
      readStatus: () => Permission.notification.status,
      request: () => Permission.notification.request(),
      openSettings: openAppSettings,
      // From "حسابي" the user opts in deliberately, so show the branded
      // app-styled rationale (icon + app colors) instead of a system alert. If
      // notifications are already denied, iOS won't re-prompt — open Settings
      // directly (showDeniedDialog left null).
      showPrimingDialog: () async {
        final bool? confirmed = await showDialog<bool>(
          context: context,
          barrierColor: Colors.black54,
          builder: (_) => const _EnableNotificationsDialog(),
        );
        return confirmed ?? false;
      },
    );
    if (!mounted) return;
    setState(() {
      _notifications = granted;
      _togglingNotifications = false;
    });
    if (granted) {
      unawaited(PushService.instance.registerIfPossible());
    }
    // If the user went to Settings, didChangeAppLifecycleState re-reads the
    // real state when they return.
  }

  /// Turn notifications OFF. An app can't revoke its own OS permission, so we
  /// route the user to the system Settings where the real switch lives.
  Future<void> _disableNotifications() async {
    final bool? goToSettings = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _DisableNotificationsDialog(),
    );
    if (!mounted || goToSettings != true) return;
    await openAppSettings();
    // Leave the toggle as-is; didChangeAppLifecycleState re-reads on return.
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppTopNav(title: 'حسابي', showBackButton: false),
                const SizedBox(height: AppSpacing.xxxl),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      0,
                      AppSpacing.xxl,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileHeaderCard(
                          name: AuthService.currentUser?.name ?? '',
                          onTap: () async {
                            await Navigator.of(
                              context,
                            ).pushNamed('/edit-profile');
                            if (!mounted) return;
                            setState(() {}); // refresh after edit-profile saves
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SettingsCard(
                          items: [
                            _SettingsRow.toggle(
                              iconAsset: AppSvgIcons.profileDarkMode,
                              label: 'المظهـر الليـلي',
                              value: _darkMode,
                              onChanged: (v) {
                                ThemeController.instance.setDarkMode(v);
                                setState(() => _darkMode = v);
                              },
                            ),
                            _SettingsRow.toggle(
                              iconAsset: AppSvgIcons.profileNotification,
                              label: 'الإشعـارات',
                              value: _notifications,
                              onChanged: _onNotificationsChanged,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SettingsCard(
                          items: [
                            _SettingsRow.action(
                              iconAsset: AppSvgIcons.profileFaq,
                              label: 'الأسئلـة الشائعـة',
                              onTap: () =>
                                  Navigator.of(context).pushNamed('/faq'),
                            ),
                            _SettingsRow.action(
                              iconAsset: AppSvgIcons.profileReport,
                              label: 'الإبـلاغ عن مشكلـة',
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed('/report-problem'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SettingsCard(
                          items: [
                            _SettingsRow.action(
                              iconAsset: AppSvgIcons.mishkatIcon,
                              label: 'عـن مِشْكَاة',
                              onTap: () =>
                                  Navigator.of(context).pushNamed('/about'),
                              tintIcon: true,
                            ),
                            _SettingsRow.action(
                              iconAsset: AppSvgIcons.profileTerms,
                              label: 'شـروط الإستخـدام',
                              onTap: () =>
                                  Navigator.of(context).pushNamed('/terms'),
                            ),
                            _SettingsRow.action(
                              iconAsset: AppSvgIcons.profilePrivacy,
                              label: 'بنـود الخصوصيـة',
                              onTap: () =>
                                  Navigator.of(context).pushNamed('/privacy'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _LogoutButton(onTap: _onLogout),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: AiFloatingButton(
                onTap: _onOpenAi,
                activeTab: MainShell.activeIndexOf(context),
                tabIndex: MainShell.accountIndex,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  static const double _avatarSize = 32;
  static const double _avatarIconSize = 24;
  static const double _chevronSize = 20;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          Container(
            width: _avatarSize,
            height: _avatarSize,
            decoration: const BoxDecoration(
              color: AppPalettePurple.shade400,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              AppSvgIcons.profileUserSolid,
              width: _avatarIconSize,
              height: _avatarIconSize,
              colorFilter: ColorFilter.mode(
                context.colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Text(
              name,
              textAlign: TextAlign.right,
              style: AppTextStyles.thmanyahHeading(context).copyWith(
                color: context.colors.shade700,
                fontSize: AppFontSizes.md,
                fontWeight: AppFontWeights.semibold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          SvgPicture.asset(
            AppSvgIcons.profileChevron,
            width: _chevronSize,
            height: _chevronSize,
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.items});

  final List<_SettingsRow> items;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];
    for (int i = 0; i < items.length; i++) {
      children.add(items[i]);
      if (i != items.length - 1) {
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: _SettingsDivider(),
          ),
        );
      }
    }
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 0.5, color: context.colors.divider);
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow._({
    required this.iconAsset,
    required this.label,
    required this.trailing,
    this.onTap,
    this.tintIcon = false,
  });

  factory _SettingsRow.toggle({
    required String iconAsset,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _SettingsRow._(
      iconAsset: iconAsset,
      label: label,
      trailing: _ProfileSwitch(value: value, onChanged: onChanged),
    );
  }

  factory _SettingsRow.action({
    required String iconAsset,
    required String label,
    required VoidCallback onTap,
    bool tintIcon = false,
  }) {
    return _SettingsRow._(
      iconAsset: iconAsset,
      label: label,
      trailing: SvgPicture.asset(
        AppSvgIcons.profileChevron,
        width: 20,
        height: 20,
      ),
      onTap: onTap,
      tintIcon: tintIcon,
    );
  }

  final String iconAsset;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool tintIcon;

  @override
  Widget build(BuildContext context) {
    final Widget icon = SvgPicture.asset(
      iconAsset,
      width: 20,
      height: 20,
      colorFilter: tintIcon
          ? const ColorFilter.mode(AppPalettePurple.shade200, BlendMode.srcIn)
          : null,
    );

    final Widget row = Row(
      children: [
        Expanded(
          child: Row(
            children: [
              icon,
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.thmanyahCaption(context).copyWith(
                    color: context.colors.shade700,
                    fontSize: AppFontSizes.sm,
                    fontWeight: AppFontWeights.semibold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        trailing,
      ],
    );

    // Toggle rows: merge the label text with the switch so the screen reader
    // reads one node, e.g. "المظهـر الليـلي، زر تبديل، مفعّل".
    if (onTap == null) return MergeSemantics(child: row);

    // Action rows: one button whose name is the label; the leading icon and
    // trailing chevron are decorative SVGs that carry no semantics.
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: row,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSwitch extends StatelessWidget {
  const _ProfileSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  static const double _width = 33;
  static const double _height = 20;
  static const double _knobSize = 17;
  static const double _padding = 1.5;
  static const Duration _duration = Duration(milliseconds: 280);
  static const Curve _curve = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    final Color trackColor = value
        ? AppSuccessColors.shade400
        : context.colors.shade200;

    return Semantics(
      button: true,
      toggled: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: _duration,
          curve: _curve,
          width: _width,
          height: _height,
          padding: const EdgeInsets.all(_padding),
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: AnimatedAlign(
            duration: _duration,
            curve: _curve,
            alignment: value
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: Container(
              width: _knobSize,
              height: _knobSize,
              decoration: const BoxDecoration(
                color: AppNeutralColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A101828),
                    offset: Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

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
          Transform.rotate(
            angle: 1.5707963267948966, // pi / 2, clockwise 90deg
            child: SvgPicture.asset(
              AppSvgIcons.profileLogout,
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
          ),
          const SizedBox(width: AppSpacing.lg),
          Text(
            'تسجيـل الخـروج',
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

class _LogoutConfirmationDialog extends StatelessWidget {
  const _LogoutConfirmationDialog();

  static const double _iconSize = 80;

  @override
  Widget build(BuildContext context) {
    return _ConfirmationDialog(
      icon: SvgPicture.asset(
        AppSvgIcons.profileLogoutModal,
        width: _iconSize,
        height: _iconSize,
      ),
      title: 'تبي تسجّل خروجك؟',
      description: 'تقدر ترجع لحسابك أي وقت،\nوبياناتك محفوظة ما تروح.',
      primaryButton: _DialogPrimaryButton(
        label: 'تسجيل الخروج',
        backgroundColor: AppDangerColors.shade500,
        onTap: () => Navigator.of(context).pop(true),
      ),
      secondaryButton: _DialogSecondaryButton(
        label: 'إلغاء',
        borderColor: context.colors.shade300,
        textColor: context.colors.shade700,
        onTap: () => Navigator.of(context).pop(false),
      ),
    );
  }
}

class _EnableNotificationsDialog extends StatelessWidget {
  const _EnableNotificationsDialog();

  static const double _bellSize = 80;

  @override
  Widget build(BuildContext context) {
    return _ConfirmationDialog(
      icon: SvgPicture.asset(
        AppSvgIcons.profileEnableNotifications,
        width: _bellSize,
        height: _bellSize,
      ),
      title: PermissionCopy.notificationsTitle,
      description: PermissionCopy.notificationsPrimingBody,
      primaryButton: _DialogPrimaryButton(
        label: PermissionCopy.enableNotificationsLabel,
        onTap: () => Navigator.of(context).pop(true),
      ),
      secondaryButton: _DialogSecondaryButton(
        label: PermissionCopy.laterLabel,
        onTap: () => Navigator.of(context).pop(false),
      ),
    );
  }
}

class _DisableNotificationsDialog extends StatelessWidget {
  const _DisableNotificationsDialog();

  static const double _bellSize = 80;

  @override
  Widget build(BuildContext context) {
    return _ConfirmationDialog(
      icon: SvgPicture.asset(
        AppSvgIcons.profileEnableNotifications,
        width: _bellSize,
        height: _bellSize,
      ),
      title: PermissionCopy.notificationsDisableTitle,
      description: PermissionCopy.notificationsDisableBody,
      primaryButton: _DialogPrimaryButton(
        label: PermissionCopy.openSettingsLabel,
        onTap: () => Navigator.of(context).pop(true),
      ),
      secondaryButton: _DialogSecondaryButton(
        label: PermissionCopy.cancelLabel,
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
    required this.primaryButton,
    required this.secondaryButton,
  });

  final Widget icon;
  final String title;
  final String description;
  final Widget primaryButton;
  final Widget secondaryButton;

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
                    Expanded(child: primaryButton),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: secondaryButton),
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

class _DialogPrimaryButton extends StatelessWidget {
  const _DialogPrimaryButton({
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

class _DialogSecondaryButton extends StatelessWidget {
  const _DialogSecondaryButton({
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
