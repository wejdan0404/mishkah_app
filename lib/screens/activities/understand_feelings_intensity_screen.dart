import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../core/activities/activity_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/nav/app_top_nav.dart';
import 'understand_feelings_progress.dart';
import 'understand_feelings_summary_screen.dart';

class UnderstandFeelingsIntensityScreen extends StatefulWidget {
  const UnderstandFeelingsIntensityScreen({
    super.key,
    required this.moodId,
    required this.moodLabel,
    required this.bodyLocation,
    required this.placeLabel,
  });

  /// Backend emotion id carried forward from step 1 (e.g. "anger").
  final String moodId;

  /// Carried forward from step 1 (e.g. "غاضب").
  final String moodLabel;

  /// Backend body-location id carried forward from step 2 (e.g. "chest").
  final String bodyLocation;

  /// Carried forward from step 2 (e.g. "الصدر").
  final String placeLabel;

  @override
  State<UnderstandFeelingsIntensityScreen> createState() =>
      _UnderstandFeelingsIntensityScreenState();
}

class _UnderstandFeelingsIntensityScreenState
    extends State<UnderstandFeelingsIntensityScreen> {
  static const List<String> _levelLabels = [
    'خفيف', // 1
    'محسوس', // 2
    'متوسط', // 3
    'واضح', // 4
    'قوي', // 5
  ];

  int _intensity = 1; // 1..5

  void _select(int value) {
    if (value < 1 || value > 5 || value == _intensity) return;
    setState(() {
      _intensity = value;
    });
  }

  void _onNext() {
    debugPrint('Next step. Selected intensity: $_intensity');
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UnderstandFeelingsSummaryScreen(
          moodId: widget.moodId,
          moodLabel: widget.moodLabel,
          bodyLocation: widget.bodyLocation,
          placeLabel: widget.placeLabel,
          intensity: _intensity,
          intensityLabel: _levelLabels[_intensity - 1],
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
                  currentStep: 2,
                  steps: exerciseSteps,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _IntensityCard(
                    intensity: _intensity,
                    levelLabel: _levelLabels[_intensity - 1],
                    onSelect: _select,
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
                  onPressed: _onNext,
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

class _IntensityCard extends StatelessWidget {
  const _IntensityCard({
    required this.intensity,
    required this.levelLabel,
    required this.onSelect,
  });

  final int intensity;
  final String levelLabel;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.shade200, width: 0.5),
        boxShadow: AppShadows.xs,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  'قد إيش الشعور قوي؟',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.thmanyahHeading(context).copyWith(
                    fontSize: AppFontSizes.md,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اختر شدّة الشعور اللي تحسّه.',
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Fixed-size slot for the (now constant-size) circle so
                      // the surrounding layout stays perfectly still.
                      SizedBox(
                        width: _IntensityCircle._maxSize,
                        height: _IntensityCircle._maxSize,
                        child: Center(
                          child: _IntensityCircle(intensity: intensity),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        levelLabel,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.thmanyahHeading(context).copyWith(
                          fontSize: AppFontSizes.sm,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _IntensitySlider(
                        intensity: intensity,
                        onSelect: onSelect,
                      ),
                    ],
                  ),
                ),
                // Reserve space so the slider/labels never sit on top of the
                // tip toast that's anchored at the bottom of the card.
                const SizedBox(height: 80),
              ],
            ),
          ),
          // Permanent tip toast with 24px breathing room from the card's
          // outer right / left / bottom edges.
          const PositionedDirectional(
            start: 24,
            end: 24,
            bottom: 24,
            child: ExerciseInfoToast(
              text: '1 يعني خفيف، 5 يعني قوي. اختر اللي قريب من شعورك.',
            ),
          ),
        ],
      ),
    );
  }
}

class _IntensityCircle extends StatelessWidget {
  const _IntensityCircle({required this.intensity});

  final int intensity;

  // Fixed size for ALL levels — the circle never grows with intensity, so a
  // high level never feels alarming. Intensity reads through subtle cues
  // (a gentle fill deepening + soft glow) instead of size.
  static const double _size = 120;
  static const double _maxSize = _size;

  @override
  Widget build(BuildContext context) {
    final double t = (intensity - 1) / 4.0; // 0 (خفيف) .. 1 (قوي)
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.purpleSoftFill(AppPalettePurple.shade500),
        // Soft glow that strengthens gently with intensity — calm, not loud.
        boxShadow: [
          BoxShadow(
            color: AppPalettePurple.shade300.withValues(alpha: 0.10 + 0.18 * t),
            blurRadius: 14 + 16 * t,
            spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: _size,
        height: _size,
        // A faint purple wash, deeper toward the centre as intensity rises;
        // fully transparent at the lightest level.
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            radius: 0.85,
            colors: [
              AppPalettePurple.shade300.withValues(alpha: 0.05 + 0.28 * t),
              AppPalettePurple.shade300.withValues(alpha: 0.0),
            ],
          ),
        ),
        alignment: Alignment.center,
        // One fixed font size for every level so the figure never scales.
        child: Text(
          '$intensity',
          style: const TextStyle(
            fontFamily: AppFontFamily.title,
            fontSize: 40,
            fontWeight: AppFontWeights.bold,
            color: AppPalettePurple.shade200,
            height: 1,
            fontFeatures: AppFontFamily.titleFeatures,
          ),
        ),
      ),
    );
  }
}

class _IntensitySlider extends StatelessWidget {
  const _IntensitySlider({required this.intensity, required this.onSelect});

  final int intensity;
  final ValueChanged<int> onSelect;

  static const int _count = 5;
  static const double _slotWidth = 22;
  static const double _trackHeight = 8;
  static const double _dotSize = 14;
  static const double _dotSelectedSize = 22;

  void _handleDrag(Offset localPosition, List<double> centersLtr) {
    if (centersLtr.isEmpty) return;
    double closestDist = double.infinity;
    int closestLtr = 0;
    for (int i = 0; i < centersLtr.length; i++) {
      final double d = (centersLtr[i] - localPosition.dx).abs();
      if (d < closestDist) {
        closestDist = d;
        closestLtr = i;
      }
    }
    // centersLtr[0] is the leftmost dot in render order. In RTL the source
    // order goes right→left, so the rightmost dot (intensity 1, خفيف) maps
    // to LTR index = count-1, and the leftmost (intensity 5, قوي) to 0.
    final int level = _count - closestLtr;
    onSelect(level);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double step = (width - _slotWidth) / (_count - 1);
        final List<double> centersLtr = [
          for (int i = 0; i < _count; i++) _slotWidth / 2 + i * step,
        ];

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) => _handleDrag(d.localPosition, centersLtr),
          onHorizontalDragUpdate: (d) =>
              _handleDrag(d.localPosition, centersLtr),
          onTapDown: (d) => _handleDrag(d.localPosition, centersLtr),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _dotSelectedSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: _trackHeight,
                      margin: const EdgeInsets.symmetric(
                        horizontal: _slotWidth / 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // In RTL Row, source[0] is the rightmost dot
                        // (= intensity 1 = خفيف). Each subsequent index
                        // moves left and represents the next stronger level.
                        for (int i = 0; i < _count; i++)
                          SizedBox(
                            width: _slotWidth,
                            child: Center(
                              child: _IntensityDot(
                                selected: (i + 1) == intensity,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Endpoint labels: right = خفيف (level 1), left = قوي (level 5).
              // In an RTL Row, source[0] is on the right.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'خفيف',
                    style: TextStyle(
                      fontFamily: AppFontFamily.text,
                      fontSize: AppFontSizes.xxs,
                      fontWeight: intensity == 1
                          ? AppFontWeights.bold
                          : AppFontWeights.medium,
                      color: intensity == 1
                          ? context.colors.shade700
                          : context.colors.shade400,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    'قوي',
                    style: TextStyle(
                      fontFamily: AppFontFamily.text,
                      fontSize: AppFontSizes.xxs,
                      fontWeight: intensity == 5
                          ? AppFontWeights.bold
                          : AppFontWeights.medium,
                      color: intensity == 5
                          ? context.colors.shade700
                          : context.colors.shade400,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IntensityDot extends StatelessWidget {
  const _IntensityDot({required this.selected});

  final bool selected;

  static const double _ringWidth = 3;

  @override
  Widget build(BuildContext context) {
    final double size = selected
        ? _IntensitySlider._dotSelectedSize
        : _IntensitySlider._dotSize;
    final Color ringColor = selected
        ? AppPalettePurple.shade300
        : AppPalettePurple.shade500;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppNeutralColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: _ringWidth),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F1729),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
    );
  }
}
