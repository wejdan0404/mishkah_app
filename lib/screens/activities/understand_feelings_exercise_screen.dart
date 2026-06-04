import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../constants/app_play_images.dart';
import '../../core/activities/activity_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/nav/app_top_nav.dart';
import 'understand_feelings_place_screen.dart';
import 'understand_feelings_progress.dart';

class UnderstandFeelingsExerciseScreen extends StatefulWidget {
  const UnderstandFeelingsExerciseScreen({super.key});

  @override
  State<UnderstandFeelingsExerciseScreen> createState() =>
      _UnderstandFeelingsExerciseScreenState();
}

class _MoodOption {
  const _MoodOption({
    required this.id,
    required this.label,
    required this.imageAsset,
  });

  final String id;
  final String label;
  final String imageAsset;
}

class _UnderstandFeelingsExerciseScreenState
    extends State<UnderstandFeelingsExerciseScreen> {
  // Source order matters: in RTL Row, the first item appears on the right.
  // Right → Left visually: سعيد, غاضب, مشمئز, متفاجئ, حزين, خائف.
  static const List<_MoodOption> _moods = [
    _MoodOption(
      id: 'happy',
      label: 'سعيد',
      imageAsset: AppPlayImages.moodHappy,
    ),
    _MoodOption(
      id: 'anger',
      label: 'غاضب',
      imageAsset: AppPlayImages.moodAnger,
    ),
    _MoodOption(
      id: 'disgust',
      label: 'مشمئز',
      imageAsset: AppPlayImages.moodDisgust,
    ),
    _MoodOption(
      id: 'surprise',
      label: 'متفاجئ',
      imageAsset: AppPlayImages.moodSurprise,
    ),
    _MoodOption(
      id: 'sadness',
      label: 'حزين',
      imageAsset: AppPlayImages.moodSadness,
    ),
    _MoodOption(
      id: 'fear',
      label: 'خائف',
      imageAsset: AppPlayImages.moodFear,
    ),
  ];

  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    // Best-effort: open the backend completion lifecycle on flow entry.
    ActivityApi.start(ActivitySlugs.understandFeelings);
  }

  void _selectMood(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onNext() {
    final _MoodOption mood = _moods[_selectedIndex!];
    debugPrint('Next step. Selected mood: ${mood.id}');
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UnderstandFeelingsPlaceScreen(
          moodId: mood.id,
          moodLabel: mood.label,
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
                backButton: _selectedIndex == null
                    ? null
                    : ExerciseCloseButton(
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
                  currentStep: 0,
                  steps: exerciseSteps,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _BodyCard(
                    moods: _moods,
                    selectedIndex: _selectedIndex,
                    onSelect: _selectMood,
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
                  onPressed: _selectedIndex == null ? null : _onNext,
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

class _BodyCard extends StatelessWidget {
  const _BodyCard({
    required this.moods,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_MoodOption> moods;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final _MoodOption? selectedMood =
        selectedIndex == null ? null : moods[selectedIndex!];
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
            'وش أقرب شعور لك؟',
            textAlign: TextAlign.center,
            style: AppTextStyles.thmanyahHeading(context).copyWith(
              fontSize: AppFontSizes.md,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اختر كلمة واحدة قريبة من إحساسك مهما كان.',
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
            child: Center(child: _MoodFace(mood: selectedMood)),
          ),
          const SizedBox(height: 24),
          _MoodSlider(
            moods: moods,
            selectedIndex: selectedIndex,
            onSelect: onSelect,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _MoodFace extends StatelessWidget {
  const _MoodFace({required this.mood});

  final _MoodOption? mood;

  static const double _outerSize = 200;
  static const double _innerSize = 166.667;

  @override
  Widget build(BuildContext context) {
    if (mood != null) {
      return SizedBox(
        width: _outerSize,
        height: _outerSize,
        child: Image.asset(
          mood!.imageAsset,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      );
    }
    return Container(
      width: _outerSize,
      height: _outerSize,
      decoration: BoxDecoration(
        color: context.colors.shade50,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: _innerSize,
        height: _innerSize,
        decoration: BoxDecoration(
          color: context.colors.shade100,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          AppSvgIcons.activitiesEmptyMood,
          width: 86.667,
          height: 86.667,
        ),
      ),
    );
  }
}

class _MoodSlider extends StatelessWidget {
  const _MoodSlider({
    required this.moods,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_MoodOption> moods;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

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
    // centersLtr[0] is the left-most child in render order. In RTL the source
    // order is reversed, so map the LTR index back to the source index.
    final int sourceIndex = moods.length - 1 - closestLtr;
    onSelect(sourceIndex);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Dots fill the entire available width with even spacing — the first
        // dot's center sits half-a-slot from the left edge, and the last from
        // the right edge.
        final int count = moods.length;
        const double slotWidth = _dotSelectedSize;
        final double width = constraints.maxWidth;
        final double step = (width - slotWidth) / (count - 1);
        final List<double> centersLtr = [
          for (int i = 0; i < count; i++) slotWidth / 2 + i * step,
        ];

        // Each label slot is wider than the dot so labels fit without
        // overflowing (which avoids any RTL text rendering quirks).
        const double labelSlot = 60;
        const double dotRowHeight = slotWidth;
        const double gap = 8;
        const double labelHeight = 18;
        final double totalHeight = dotRowHeight + gap + labelHeight;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) => _handleDrag(d.localPosition, centersLtr),
          onHorizontalDragUpdate: (d) =>
              _handleDrag(d.localPosition, centersLtr),
          onTapDown: (d) => _handleDrag(d.localPosition, centersLtr),
          child: SizedBox(
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Track line — sits at the vertical center of the dot row,
                // spanning between the outer dot centers.
                Positioned(
                  left: slotWidth / 2,
                  right: slotWidth / 2,
                  top: (dotRowHeight - _trackHeight) / 2,
                  child: Container(
                    height: _trackHeight,
                    decoration: BoxDecoration(
                      color: context.colors.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                // For each mood, place the dot AND its label at the same x
                // coordinate (= centersLtr[ltrIndex]). Source order moods[0]
                // sits on the right in RTL, so its LTR visual index = last.
                for (int i = 0; i < count; i++) ...[
                  // Dot
                  Positioned(
                    left: centersLtr[count - 1 - i] - slotWidth / 2,
                    top: 0,
                    width: slotWidth,
                    height: dotRowHeight,
                    child: Center(
                      child: _MoodDot(selected: i == selectedIndex),
                    ),
                  ),
                  // Label — wider box centered on the same x as the dot.
                  Positioned(
                    left: centersLtr[count - 1 - i] - labelSlot / 2,
                    top: dotRowHeight + gap,
                    width: labelSlot,
                    child: Text(
                      moods[i].label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontFamily: AppFontFamily.text,
                        fontSize: AppFontSizes.xxs,
                        fontWeight: i == selectedIndex
                            ? AppFontWeights.bold
                            : AppFontWeights.medium,
                        color: i == selectedIndex
                            ? context.colors.shade700
                            : context.colors.shade400,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MoodDot extends StatelessWidget {
  const _MoodDot({required this.selected});

  final bool selected;

  static const double _ringWidth = 3;

  @override
  Widget build(BuildContext context) {
    final double size =
        selected ? _MoodSlider._dotSelectedSize : _MoodSlider._dotSize;
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
