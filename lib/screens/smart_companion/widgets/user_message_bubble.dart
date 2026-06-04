import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';

class UserMessageBubble extends StatelessWidget {
  const UserMessageBubble({super.key, required this.text});

  final String text;

  static const double _mirroredAvatarSpace = 44.936;

  @override
  Widget build(BuildContext context) {
    final Widget bubble = Container(
      padding: const EdgeInsets.all(9.428),
      decoration: BoxDecoration(
        color: context.purpleSoftFill(AppPalettePurple.shade600),
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(3.771),
          topEnd: Radius.circular(11.314),
          bottomStart: Radius.circular(11.314),
          bottomEnd: Radius.circular(11.314),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontFamily: AppFontFamily.text,
          fontSize: AppFontSizes.sm,
          fontWeight: AppFontWeights.regular,
          color: context.forDark(
            AppNeutralColors.shade500,
            AppPalettePurple.shade600,
          ),
          height: 1.5,
        ),
      ),
    );

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: bubble,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        const SizedBox(width: _mirroredAvatarSpace),
      ],
    );
  }
}
