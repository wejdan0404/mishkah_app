import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import 'app_back_button.dart';

class AppTopNav extends StatelessWidget {
  const AppTopNav({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = true,
    this.onBack,
    this.titleStyle,
    this.trailing,
    this.backButton,
  });

  final String title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBack;
  final TextStyle? titleStyle;
  final Widget? trailing;

  /// Override the default circular back button with a custom widget.
  /// Useful when the back affordance changes appearance/behavior (e.g.
  /// a "save" check button while the user is editing).
  final Widget? backButton;

  @override
  Widget build(BuildContext context) {
    final Widget titleText = Text(
      title,
      textAlign: TextAlign.right,
      style: titleStyle ??
          AppTextStyles.thmanyahDisplay(context).copyWith(color: context.colors.shade700),
    );

    final Widget heading = subtitle == null
        ? titleText
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              titleText,
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.xxs,
                  fontWeight: AppFontWeights.regular,
                  color: context.colors.shade500,
                  height: 1.4,
                ),
              ),
            ],
          );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          if (showBackButton) ...[
            backButton ?? AppBackButton(onTap: onBack),
            const SizedBox(width: AppSpacing.xl),
          ],
          Expanded(child: heading),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.lg),
            trailing!,
          ],
        ],
      ),
    );
  }
}
