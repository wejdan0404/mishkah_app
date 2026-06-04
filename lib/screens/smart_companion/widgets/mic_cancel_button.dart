import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants/app_icons.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';

class MicCancelButton extends StatelessWidget {
  const MicCancelButton({super.key, required this.onTap, this.size = 32});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'إلغاء التسجيل',
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Material(
            // Light: neutral/700 fill. Dark: reversed → neutral/100 fill.
            color: context.forDark(
              AppNeutralColors.shade700,
              AppNeutralColors.shade100,
            ),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: size,
                height: size,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SvgPicture.asset(
                    AppSvgIcons.closeSmall,
                    colorFilter: ColorFilter.mode(
                      // Light: neutral/100 glyph. Dark: reversed → neutral/700.
                      context.forDark(
                        AppNeutralColors.shade100,
                        AppNeutralColors.shade700,
                      ),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
