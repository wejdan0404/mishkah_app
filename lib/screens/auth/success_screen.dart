import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

import '../../constants/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/buttons/app_button.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    this.onContinue,
    this.secondaryButtonLabel,
    this.onSecondary,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback? onContinue;
  final String? secondaryButtonLabel;
  final VoidCallback? onSecondary;

  static const String _animationAsset = 'assets/animations/success_check.json';
  static const double _badgeSize = 400;

  static const List<String> _greenLayerNames = [
    'Shape Layer 1',
    'Shape Layer 2',
    'Shape Layer 3',
    'Shape Layer 4',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.shade50,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              // A warm-gold glow painted OVER the scaffold background, fading to a fully
              // transparent version of the SAME gold so it dims into the bg (light or
              // dark) without greying. A near-white fade would read as grey over a dark
              // bg, so the glow stays gold the whole way down and is theme-independent.
              stops: const [0.00, 0.07, 0.15, 0.26],
              colors: [
                AppPaletteButteryYellow.shade200,
                AppPaletteButteryYellow.shade200.withValues(alpha: 0.55),
                AppPaletteButteryYellow.shade200.withValues(alpha: 0.22),
                AppPaletteButteryYellow.shade200.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xxl,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: _badgeSize,
                            height: _badgeSize,
                            child: Lottie.asset(
                              _animationAsset,
                              fit: BoxFit.contain,
                              repeat: false,
                              delegates: LottieDelegates(
                                values: [
                                  for (final layer in _greenLayerNames)
                                    ValueDelegate.color([
                                      'check',
                                      layer,
                                      '**',
                                    ], value: AppSuccessColors.shade400),
                                ],
                              ),
                            ),
                          ),
                          //const SizedBox(height: AppSpacing.xxxl),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.thmanyahTitle(context),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppFontFamily.text,
                              fontSize: AppFontSizes.xs,
                              fontWeight: AppFontWeights.regular,
                              color: context.colors.shade500,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final Widget primary = AppButton(
                        label: buttonLabel,
                        expand: true,
                        trailing: SvgPicture.asset(
                          AppSvgIcons.arrowLeft,
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            AppNeutralColors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        onPressed:
                            onContinue ??
                            () => Navigator.of(
                              context,
                            ).pushNamedAndRemoveUntil('/home', (_) => false),
                      );
                      if (secondaryButtonLabel == null) return primary;
                      return Row(
                        children: [
                          Expanded(child: primary),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _OutlinedSecondaryButton(
                              label: secondaryButtonLabel!,
                              onPressed:
                                  onSecondary ??
                                  () => Navigator.of(context).maybePop(),
                            ),
                          ),
                        ],
                      );
                    },
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

class _OutlinedSecondaryButton extends StatelessWidget {
  const _OutlinedSecondaryButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  static const double _height = 44;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return SizedBox(
      height: _height,
      child: Material(
        color: context.colors.white,
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: AppPalettePurple.shade200, width: 1),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.sm,
                fontWeight: AppFontWeights.bold,
                color: AppPalettePurple.shade200,
                height: 1.25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
