import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';

class QuickReplyChip extends StatelessWidget {
  const QuickReplyChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: context.purpleSoftFill(AppPalettePurple.shade600),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.xxs,
                fontWeight: AppFontWeights.regular,
                color: context.forDark(
                  AppNeutralColors.shade500,
                  AppPalettePurple.shade600,
                ),
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
