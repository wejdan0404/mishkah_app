import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../core/activities/activity_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/nav/app_top_nav.dart';
import '../auth/success_screen.dart';
import 'understand_feelings_progress.dart';

class ActivateSensesExerciseScreen extends StatefulWidget {
  const ActivateSensesExerciseScreen({super.key, this.step = 0});

  /// Which of the 3 senses stages this screen represents (0..2).
  final int step;

  @override
  State<ActivateSensesExerciseScreen> createState() =>
      _ActivateSensesExerciseScreenState();
}

class _ActivateSensesExerciseScreenState
    extends State<ActivateSensesExerciseScreen> {
  static const List<ExerciseStep> _stepsLabels = [
    ExerciseStep(number: '01', label: 'ملاحظة'),
    ExerciseStep(number: '02', label: 'إنصات'),
    ExerciseStep(number: '03', label: 'إحساس'),
  ];

  static const List<_StageData> _stages = [
    _StageData(
      iconEmoji: '👀',
      title: 'لاحظ ٣ أشياء تشوفها',
      infoText: 'انظر حولك واختر ٣ أشياء واضحة، وقُلها بصوت مسموع.',
      examples: [
        _ExampleItem(emoji: '💡', text: 'ضوء قريب منك'),
        _ExampleItem(emoji: '🎨', text: 'لون تشوفه الآن'),
        _ExampleItem(emoji: '🔷', text: 'شكل أو خط واضح'),
      ],
      footerText: 'لما تخلّص الثلاث، اضغط التالي',
      buttonLabel: 'التالي',
    ),
    _StageData(
      iconEmoji: '👂',
      title: 'لاحظ صوتين تسمعهم',
      infoText: 'اسمع بهدوء، وقُل الصوتين بصوت مسموع',
      examples: [
        _ExampleItem(emoji: '🎵', text: 'صوت قريب منك (مكيف، خطوات ..)'),
        _ExampleItem(emoji: '🌬', text: 'صوت بعيد (سيارة، طير ..)'),
      ],
      footerText: 'حق الصمت يحسب.',
      buttonLabel: 'التالي',
    ),
    _StageData(
      iconEmoji: '✋',
      title: 'لاحظ إحساس واحد في جسمك',
      infoText: 'استشعر إحساس بسيط تلاحظه الآن، وقُله بصوت مسموع',
      examples: [
        _ExampleItem(emoji: '📱', text: 'يدك ماسكة الجوال'),
        _ExampleItem(emoji: '🪑', text: 'ظهرك على الكرسي'),
        _ExampleItem(emoji: '👟', text: 'قدمك على الأرض'),
      ],
      footerText: 'أي إحساس صغير يكفي.',
      buttonLabel: 'إنهاء التمرين',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Best-effort: open the completion lifecycle once, at the first stage,
    // so re-entering deeper stages (step+1) doesn't start it again.
    if (widget.step == 0) {
      ActivityApi.start(ActivitySlugs.activateSenses);
    }
  }

  void _onNext(BuildContext context) {
    if (widget.step < _stages.length - 1) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ActivateSensesExerciseScreen(step: widget.step + 1),
        ),
      );
      return;
    }
    // Last stage — record completion, then show the success screen.
    ActivityApi.complete(
      ActivitySlugs.activateSenses,
      result: const <String, dynamic>{'stages_completed': 3},
    );
    final NavigatorState navigator = Navigator.of(context);
    navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SuccessScreen(
          title: 'أحسنت',
          subtitle:
              'رجعت لحواسك خطوة خطوة.\nهذي طريقة لطيفة تعود لها وقت تشتت تركيزك 💜',
          buttonLabel: 'العودة للأنشطة',
          onContinue: () => navigator.popUntil((route) => route.isFirst),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _StageData stage = _stages[widget.step];
    return Scaffold(
      backgroundColor: context.colors.shade50,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTopNav(
                title: 'فعل حواسك',
                backButton: ExerciseCloseButton(
                  onTap: () => showExitExerciseDialog(
                    context,
                    abandonSlug: ActivitySlugs.activateSenses,
                    popToRouteName: ActivityCategoryRoutes.balanceStation,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ExerciseProgressCard(
                  currentStep: widget.step,
                  steps: _stepsLabels,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _StageCard(stage: stage),
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
                  label: stage.buttonLabel,
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

class _StageData {
  const _StageData({
    required this.iconEmoji,
    required this.title,
    required this.infoText,
    required this.examples,
    required this.footerText,
    required this.buttonLabel,
  });

  final String iconEmoji;
  final String title;
  final String infoText;
  final List<_ExampleItem> examples;
  final String footerText;
  final String buttonLabel;
}

class _ExampleItem {
  const _ExampleItem({required this.emoji, required this.text});

  final String emoji;
  final String text;
}

class _StageCard extends StatelessWidget {
  const _StageCard({required this.stage});

  final _StageData stage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.shade200, width: 0.5),
        boxShadow: AppShadows.xs,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _StageIcon(emoji: stage.iconEmoji)),
          const SizedBox(height: 16),
          Text(
            stage.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.thmanyahHeading(context).copyWith(
              fontSize: AppFontSizes.md,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _StageInfoToast(text: stage.infoText),
          const SizedBox(height: 32),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'أمثلة',
              style: TextStyle(
                fontFamily: AppFontFamily.title,
                fontSize: AppFontSizes.xs,
                fontWeight: AppFontWeights.bold,
                color: context.colors.shade600,
                height: 1.2,
                fontFeatures: AppFontFamily.titleFeatures,
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < stage.examples.length; i++) ...[
            if (i != 0) const SizedBox(height: 8),
            _ExampleTile(item: stage.examples[i]),
          ],
          const SizedBox(height: 32),
          Center(
            child: Text(
              stage.footerText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.xxs,
                fontWeight: AppFontWeights.regular,
                color: context.colors.shade500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageIcon extends StatelessWidget {
  const _StageIcon({required this.emoji});

  final String emoji;

  static const double _size = 72;

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
      child: Text(emoji, style: const TextStyle(fontSize: 36)),
    );
  }
}

class _StageInfoToast extends StatelessWidget {
  const _StageInfoToast({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.purpleSoftFill(AppPalettePurple.shade600),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalettePurple.shade300, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji first → renders on the right in RTL.
          const Text('🗣', style: TextStyle(fontSize: 16, height: 1.4)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
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

class _ExampleTile extends StatelessWidget {
  const _ExampleTile({required this.item});

  final _ExampleItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.colors.shade200, width: 1),
      ),
      child: Row(
        children: [
          // Emoji first → renders on the right in RTL.
          Text(item.emoji, style: const TextStyle(fontSize: 16, height: 1)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.text,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.xs,
                fontWeight: AppFontWeights.medium,
                color: context.colors.shade600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
