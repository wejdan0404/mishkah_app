import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import 'app_section_card.dart';

class FocusCard extends StatelessWidget {
  const FocusCard({
    super.key,
    required this.onStart,
    this.onRemindLater,
    this.primaryLabel = 'ابدأ الآن',
    this.primaryIconAsset,
    this.heading = '🎯 خذ لحظة للتركيز',
  });

  final VoidCallback onStart;
  final VoidCallback? onRemindLater;
  final String primaryLabel;
  final String? primaryIconAsset;
  final String heading;

  @override
  Widget build(BuildContext context) {
    final Widget primaryPill = _PrimaryPill(
      label: primaryLabel,
      onTap: onStart,
      leadingIconAsset: primaryIconAsset,
      showArrow: primaryIconAsset == null,
    );

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Heading(heading),
          const SizedBox(height: AppSpacing.md),
          const _Caption('يساعدك تقلل التشتت وترجع تركيزك بخطوات بسيطة.'),
          const SizedBox(height: AppSpacing.xl),
          if (onRemindLater != null)
            Row(
              children: [
                Expanded(child: primaryPill),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SecondaryPill(
                    label: 'ذكّرني لاحقًا',
                    onTap: onRemindLater!,
                  ),
                ),
              ],
            )
          else
            primaryPill,
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: AppTextStyles.thmanyahHeading(context).copyWith(fontSize: AppFontSizes.sm),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: TextStyle(
        fontFamily: AppFontFamily.text,
        fontSize: AppFontSizes.xxs,
        fontWeight: AppFontWeights.regular,
        color: context.colors.shade500,
        height: 1.4,
      ),
    );
  }
}

class _PillArrow extends StatelessWidget {
  const _PillArrow({required this.color});

  final Color color;

  static const double _size = 16;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AppSvgIcons.arrowLeft,
      width: _size,
      height: _size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

class _PrimaryPill extends StatelessWidget {
  const _PrimaryPill({
    required this.label,
    required this.onTap,
    this.showArrow = false,
    this.leadingIconAsset,
  });

  final String label;
  final VoidCallback onTap;
  final bool showArrow;
  final String? leadingIconAsset;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: AppPalettePurple.shade200,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIconAsset != null) ...[
                SvgPicture.asset(
                  leadingIconAsset!,
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                    AppNeutralColors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.xs,
                  fontWeight: AppFontWeights.semibold,
                  color: AppNeutralColors.white,
                  height: 1.2,
                ),
              ),
              if (showArrow) ...[
                const SizedBox(width: AppSpacing.xs),
                const _PillArrow(color: AppNeutralColors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryPill extends StatelessWidget {
  const _SecondaryPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

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
            border: Border.all(color: AppPalettePurple.shade200, width: 1),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xs,
              fontWeight: AppFontWeights.semibold,
              color: AppPalettePurple.shade200,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
