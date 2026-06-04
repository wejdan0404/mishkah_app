import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import 'understand_feelings_progress.dart' show ExerciseCloseButton;

/// "ايش يعني يقظة ذهنية؟" explainer — opened from the يقظة ذهنية icon in the
/// محطة التوازن header. A short definition plus one wrong / one right example
/// of how to notice a feeling, and a closing note.
Future<void> showMindfulnessInfoModal(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 29.632),
      backgroundColor: context.colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.41)),
      child: const Directionality(
        textDirection: TextDirection.rtl,
        child: _MindfulnessInfoContent(),
      ),
    ),
  );
}

class _MindfulnessInfoContent extends StatelessWidget {
  const _MindfulnessInfoContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top-left close (physical left, RTL-safe), like the activities sheets.
          Align(
            alignment: Alignment.centerLeft,
            child: ExerciseCloseButton(
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: SvgPicture.asset(
              AppSvgIcons.activitiesMindfulnessModal,
              width: 68,
              height: 68,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'ايش يعني يقظة ذهنية؟',
            textAlign: TextAlign.center,
            style: AppTextStyles.thmanyahHeading(context).copyWith(
              fontSize: 20.41,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'هي إنك تنتبه للي يصير الآن: حولك، في جسمك، وفي مشاعرك، بدون ما تحكم على نفسك.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xs,
              fontWeight: AppFontWeights.regular,
              color: context.colors.shade500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _ExampleCard(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'هذي المساحة الصغيرة بينك وبين الشعور، هي اللي تفرق.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xxs,
              fontWeight: AppFontWeights.regular,
              color: AppNeutralColors.shade400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppPalettePurple.shade500,
        borderRadius: BorderRadius.circular(10.205),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'مثال',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: AppFontFamily.title,
              fontSize: AppFontSizes.xs,
              fontWeight: AppFontWeights.bold,
              color: AppPalettePurple.shade100,
              fontFeatures: AppFontFamily.titleFeatures,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8.504),
          const _ExampleRow(
            iconAsset: AppSvgIcons.activitiesExampleWrong,
            text: '"أنا متوتر وخلاص"',
            correct: false,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _ExampleRow(
            iconAsset: AppSvgIcons.activitiesExampleCorrect,
            text: '"ألاحظ أني متوتر الآن"',
            correct: true,
          ),
        ],
      ),
    );
  }
}

class _ExampleRow extends StatelessWidget {
  const _ExampleRow({
    required this.iconAsset,
    required this.text,
    required this.correct,
  });

  final String iconAsset;
  final String text;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(10.205),
        border: correct
            ? Border.all(color: AppPalettePurple.shade200, width: 0.85)
            : null,
      ),
      child: Row(
        children: [
          SvgPicture.asset(iconAsset, width: 16, height: 16),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.xxs,
                fontWeight: AppFontWeights.medium,
                color: correct
                    ? AppPalettePurple.shade200
                    : context.colors.shade500,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
