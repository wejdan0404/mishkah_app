import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';

class ChatDayLabel extends StatelessWidget {
  const ChatDayLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppFontFamily.text,
          fontSize: AppFontSizes.xxs,
          fontWeight: AppFontWeights.regular,
          color: context.colors.shade400,
          height: 1.4,
        ),
      ),
    );
  }
}
