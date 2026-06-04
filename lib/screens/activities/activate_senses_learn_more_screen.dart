import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/nav/app_top_nav.dart';
import 'activate_senses_exercise_screen.dart';
import 'understand_feelings_progress.dart';

class ActivateSensesLearnMoreScreen extends StatelessWidget {
  const ActivateSensesLearnMoreScreen({super.key});

  // 3-step preview shown on the learn-more screen. currentStep is -1 so the
  // shared progress card renders every step in its unreached / preview state.
  static const List<ExerciseStep> _sensesSteps = [
    ExerciseStep(number: '01', label: 'ملاحظة'),
    ExerciseStep(number: '02', label: 'إنصات'),
    ExerciseStep(number: '03', label: 'إحساس'),
  ];

  void _onStart(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const ActivateSensesExerciseScreen(),
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
              const AppTopNav(
                title: 'فعل حواسك',
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: ExerciseProgressCard(
                  currentStep: -1,
                  steps: _sensesSteps,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Expanded(child: _InfoSection()),
                      const _HintCard(),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  0,
                  AppSpacing.xxl,
                  AppSpacing.xl,
                ),
                child: AppButton(
                  label: 'ابدأ التمرين',
                  expand: true,
                  onPressed: () => _onStart(context),
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

class _InfoSection extends StatelessWidget {
  const _InfoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _SensesIcon(),
        const SizedBox(height: 24),
        Text(
          '٣ خطوات ترجّعك للحظة',
          textAlign: TextAlign.center,
          style: AppTextStyles.thmanyahHeading(context).copyWith(
            fontSize: AppFontSizes.md,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'تنقل تركيزك من الأفكار للأشياء حولك الحين، عن طريق النظر والسمع وإحساس بسيط في جسمك.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFontFamily.text,
            fontSize: AppFontSizes.sm,
            fontWeight: AppFontWeights.regular,
            color: context.colors.shade500,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        const _DurationPill(label: '1 دقيقة'),
      ],
    );
  }
}

class _SensesIcon extends StatelessWidget {
  const _SensesIcon();

  static const double _size = 96;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: context.forDark(
          AppPaletteButteryYellow.shade300,
          const Color(0xFF332700),
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Text('🧘', style: TextStyle(fontSize: 44)),
    );
  }
}

class _DurationPill extends StatelessWidget {
  const _DurationPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.purpleSoftFill(AppPalettePurple.shade600),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppPalettePurple.shade300, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            AppSvgIcons.activitiesTimer,
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              AppPalettePurple.shade200,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xxs,
              fontWeight: AppFontWeights.medium,
              color: AppPalettePurple.shade200,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.purpleSoftFill(AppPalettePurple.shade600),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalettePurple.shade200, width: 0.5),
        boxShadow: AppShadows.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 16, height: 1.4)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ما تحتاج تجاوب صح، فقط لاحظ. خلك في مكانك، ما تحتاج تغمض عيونك.',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.xs,
                fontWeight: AppFontWeights.regular,
                color: context.colors.shade600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
