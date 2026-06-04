import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Empty state for any "your tasks" list — the focus task picker and the home
/// remaining-tasks card share this so they read identically.
class EmptyTasksState extends StatelessWidget {
  const EmptyTasksState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(AppSvgIcons.focusEmptyFace, width: 30, height: 30),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'ما عندك مهام حاليًا',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFontFamily.text,
            fontSize: AppFontSizes.xxs,
            fontWeight: AppFontWeights.regular,
            color: context.colors.shade400,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'أضف مهمة وابدأ بخطوة بسيطة.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFontFamily.text,
            fontSize: AppFontSizes.xxs,
            fontWeight: AppFontWeights.regular,
            color: context.colors.shade400,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
