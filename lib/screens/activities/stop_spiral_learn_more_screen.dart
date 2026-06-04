import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/nav/app_top_nav.dart';
import 'breathing_exercise_screen.dart';

class StopSpiralLearnMoreScreen extends StatelessWidget {
  const StopSpiralLearnMoreScreen({super.key});

  Future<void> _onStart(BuildContext context) async {
    final bool? ready = await showBeforeYouStartDialog(context);
    if (ready != true || !context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const BreathingExerciseScreen(
          exercise: BreathingExercise.stopSpiral,
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
              const AppTopNav(title: 'وقف الدوامة'),
              const SizedBox(height: AppSpacing.md),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        emoji: '⏱',
                        label: 'المدة',
                        value: '1:04',
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _MetricCard(
                        emoji: '🔁',
                        label: 'الوتيرة',
                        value: '4-4-4-4',
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _MetricCard(
                        emoji: '🎯',
                        label: 'المستوى',
                        value: 'متوسط',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _InfoCard(),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.emoji,
    required this.label,
    required this.value,
  });

  final String emoji;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.shade200, width: 0.5),
        boxShadow: AppShadows.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22, height: 1.2)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xxs,
              fontWeight: AppFontWeights.regular,
              color: context.colors.shade400,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xs,
              fontWeight: AppFontWeights.bold,
              color: context.colors.shade600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.shade200, width: 0.5),
        boxShadow: AppShadows.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  AppSvgIcons.activitiesStopSpiral,
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'أوقف الدوامة في لحظات',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.thmanyahHeading(context).copyWith(
                    fontSize: AppFontSizes.md,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'هذا التمرين يساعدك تهدّي جسمك\nوترجع لإيقاعك الطبيعي.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.sm,
                    fontWeight: AppFontWeights.regular,
                    color: context.colors.shade500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _HintCard(),
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
              'قبل ما تبدأ، اجلس براحة وخذ لحظة تهدأ فيها. \n وجهّز نفسك ترجع لتركيزك من جديد.',
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
