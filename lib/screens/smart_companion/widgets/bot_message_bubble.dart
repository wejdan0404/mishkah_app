import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import 'ai_avatar.dart';

class BotMessageBubble extends StatelessWidget {
  const BotMessageBubble({
    super.key,
    required this.text,
    this.showAvatar = true,
  });

  final String text;
  final bool showAvatar;

  static const double _avatarSize = 44.936;

  @override
  Widget build(BuildContext context) {
    final Widget bubble = Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.shade100,
        borderRadius: const BorderRadiusDirectional.only(
          topStart: Radius.circular(AppRadius.lg),
          topEnd: Radius.circular(AppRadius.sm),
          bottomStart: Radius.circular(AppRadius.lg),
          bottomEnd: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontFamily: AppFontFamily.text,
          fontSize: AppFontSizes.sm,
          fontWeight: AppFontWeights.regular,
          color: context.colors.shade500,
          height: 1.5,
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: bubble),
        const SizedBox(width: AppSpacing.md),
        if (showAvatar)
          const AiAvatar(size: _avatarSize)
        else
          const SizedBox(width: _avatarSize),
      ],
    );
  }
}
