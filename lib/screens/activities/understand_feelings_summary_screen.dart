import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../core/activities/activity_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/nav/app_top_nav.dart';
import 'understand_feelings_need_screen.dart';
import 'understand_feelings_progress.dart';

class UnderstandFeelingsSummaryScreen extends StatelessWidget {
  const UnderstandFeelingsSummaryScreen({
    super.key,
    required this.moodId,
    required this.moodLabel,
    required this.bodyLocation,
    required this.placeLabel,
    required this.intensity,
    required this.intensityLabel,
  });

  /// Backend emotion id carried forward from step 1 (e.g. "anger").
  final String moodId;

  /// The mood the user picked in step 1 (e.g. "غاضب").
  final String moodLabel;

  /// Backend body-location id carried forward from step 2 (e.g. "chest").
  final String bodyLocation;

  /// The body part the user picked in step 2 (e.g. "الصدر").
  final String placeLabel;

  /// Intensity number 1–5 from step 3.
  final int intensity;

  /// Intensity descriptor (e.g. "متوسط") from step 3.
  final String intensityLabel;

  void _onNext(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UnderstandFeelingsNeedScreen(
          moodId: moodId,
          moodLabel: moodLabel,
          bodyLocation: bodyLocation,
          placeLabel: placeLabel,
          intensity: intensity,
          intensityLabel: intensityLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.shade50,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTopNav(
                title: 'افهم شعورك',
                backButton: ExerciseCloseButton(
                  onTap: () => showExitExerciseDialog(
                    context,
                    abandonSlug: ActivitySlugs.understandFeelings,
                    popToRouteName: ActivityCategoryRoutes.balanceStation,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: ExerciseProgressCard(
                  currentStep: 3,
                  steps: exerciseSteps,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SummaryCard(
                    moodLabel: moodLabel,
                    placeLabel: placeLabel,
                    intensity: intensity,
                    intensityLabel: intensityLabel,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                  AppSpacing.xl,
                ),
                child: AppButton(
                  label: 'التالي',
                  expand: true,
                  onPressed: () => _onNext(context),
                  trailing: SvgPicture.asset(
                    AppSvgIcons.arrowLeft,
                    width: 16,
                    height: 16,
                    colorFilter: const ColorFilter.mode(
                      AppNeutralColors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.moodLabel,
    required this.placeLabel,
    required this.intensity,
    required this.intensityLabel,
  });

  final String moodLabel;
  final String placeLabel;
  final int intensity;
  final String intensityLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.shade200, width: 0.5),
        boxShadow: AppShadows.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Text(
            'لاحظت شعورك ✨',
            textAlign: TextAlign.center,
            style: AppTextStyles.thmanyahHeading(context).copyWith(
              fontSize: AppFontSizes.md,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'مجرد ملاحظتك للشعور تساعدك تفهم اللي يصير داخلك بدل ما يسيطر عليك.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.sm,
              fontWeight: AppFontWeights.regular,
              color: context.colors.shade500,
              height: 1.5,
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: context.colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.colors.shade200,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SummaryRow(
                      label: 'الشعور:',
                      value: moodLabel,
                    ),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      label: 'يظهر في:',
                      value: placeLabel,
                    ),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      label: 'القوة:',
                      value: '$intensity من 5 — $intensityLabel',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFontFamily.text,
            fontSize: AppFontSizes.xs,
            fontWeight: AppFontWeights.regular,
            color: context.colors.shade500,
            height: 1.2,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _SummaryPill(text: value),
          ),
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.text});

  final String text;

  // Fixed width so the three answer pills are always the same size,
  // regardless of how long each value is.
  static const double _width = 150;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppPalettePurple.shade300, width: 1),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: AppFontFamily.text,
          fontSize: AppFontSizes.xs,
          fontWeight: AppFontWeights.medium,
          color: context.colors.shade700,
          height: 1.2,
        ),
      ),
    );
  }
}
