import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../theme/app_colors.dart';

/// Circular chevron back button used across screens. Defaults to popping the
/// current route; pass [onTap] to override.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onTap, this.semanticLabel = 'رجوع'});

  final VoidCallback? onTap;

  /// Spoken label for screen readers (VoiceOver/TalkBack). The button is
  /// icon-only, so this is the only thing read aloud.
  final String semanticLabel;

  static const double _size = 32;
  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: Material(
          color: context.colors.white,
          shape: const CircleBorder(),
          shadowColor: const Color(0x1A101828),
          elevation: 1,
          child: InkWell(
            onTap: onTap ?? () => Navigator.of(context).maybePop(),
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: _size,
              height: _size,
              child: Center(
                child: SvgPicture.asset(
                  AppSvgIcons.chevronBack,
                  width: _iconSize,
                  height: _iconSize,
                  colorFilter: ColorFilter.mode(
                    context.colors.shade700,
                    BlendMode.srcIn,
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
