import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../core/activities/activity_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/nav/app_top_nav.dart';
import 'understand_feelings_intensity_screen.dart';
import 'understand_feelings_progress.dart';

class UnderstandFeelingsPlaceScreen extends StatefulWidget {
  const UnderstandFeelingsPlaceScreen({
    super.key,
    required this.moodId,
    required this.moodLabel,
  });

  /// The backend emotion id picked in step 1 (e.g. "anger") — carried forward
  /// so the final step can record it.
  final String moodId;

  /// The mood the user picked in step 1 — carried forward so the summary
  /// step can show it.
  final String moodLabel;

  @override
  State<UnderstandFeelingsPlaceScreen> createState() =>
      _UnderstandFeelingsPlaceScreenState();
}

enum _BodyPart { head, throat, shoulders, chest, belly, hands, unsure }

class _PlaceOption {
  const _PlaceOption({
    required this.part,
    required this.label,
    required this.emoji,
    this.info,
  });

  final _BodyPart part;
  final String label;
  final String emoji;
  final String? info;
}

class _UnderstandFeelingsPlaceScreenState
    extends State<UnderstandFeelingsPlaceScreen> {
  static const List<_PlaceOption> _options = [
    _PlaceOption(
      part: _BodyPart.head,
      label: 'الرأس',
      emoji: '🧠',
      info: 'لما تحس بصداع، ثقل، تشويش، أو تفكير زائد.',
    ),
    _PlaceOption(
      part: _BodyPart.throat,
      label: 'الحلق',
      emoji: '🌬️',
      info: 'لما تحس بغصّة، ضيق، أو صعوبة في الكلام.',
    ),
    _PlaceOption(
      part: _BodyPart.shoulders,
      label: 'الكتفين',
      emoji: '💪',
      info: 'لما تحس بتشنج أو شد في الكتفين.',
    ),
    _PlaceOption(
      part: _BodyPart.chest,
      label: 'الصدر',
      emoji: '❤️',
      info: 'لما تحس بضيق، ثقل، سرعة نبض، أو انقباض في الصدر.',
    ),
    _PlaceOption(
      part: _BodyPart.belly,
      label: 'البطن',
      emoji: '🌀',
      info: 'لما تحس بمغص، تقلص، رفرفة، أو شعور بعدم الارتياح في البطن.',
    ),
    _PlaceOption(
      part: _BodyPart.hands,
      label: 'اليدين',
      emoji: '✋',
      info: 'لما تحس برجفة، خدر، أو توتر في اليدين.',
    ),
    _PlaceOption(
      part: _BodyPart.unsure,
      label: 'ما أدري',
      emoji: '🤷',
      info: 'مو لازم تعرفه مباشرة، مجرد ملاحظتك لنفسك خطوة جميلة.',
    ),
  ];

  _BodyPart? _selected;
  String? _toastText;
  Timer? _toastTimer;

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _select(_BodyPart part) {
    setState(() {
      _selected = part;
    });
  }

  void _showInfo(_PlaceOption option) {
    final String? info = option.info;
    if (info == null) return;
    _toastTimer?.cancel();
    setState(() {
      _toastText = info;
    });
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _toastText = null;
      });
    });
  }

  void _onNext() {
    final _PlaceOption selectedOption =
        _options.firstWhere((o) => o.part == _selected);
    debugPrint('Next step. Selected place: ${selectedOption.label}');
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UnderstandFeelingsIntensityScreen(
          moodId: widget.moodId,
          moodLabel: widget.moodLabel,
          bodyLocation: selectedOption.part.name,
          placeLabel: selectedOption.label,
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
                  currentStep: 1,
                  steps: exerciseSteps,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _BodyCard(
                    options: _options,
                    selected: _selected,
                    onSelect: _select,
                    onInfo: _showInfo,
                    toastText: _toastText,
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
                  onPressed: _selected == null ? null : _onNext,
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
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.onInfo,
    required this.toastText,
  });

  final List<_PlaceOption> options;
  final _BodyPart? selected;
  final ValueChanged<_BodyPart> onSelect;
  final ValueChanged<_PlaceOption> onInfo;
  final String? toastText;

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
                  'وين تحس أثره في جسمك؟',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.thmanyahHeading(context).copyWith(
                    fontSize: AppFontSizes.md,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اختر أقرب مكان يظهر فيه الشعور.',
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Options on the right (first child = right in RTL).
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < options.length; i++) ...[
                              if (i != 0) const SizedBox(height: 8),
                              _PlaceOptionButton(
                                option: options[i],
                                selected: selected == options[i].part,
                                onTap: () => onSelect(options[i].part),
                                onInfoTap: () => onInfo(options[i]),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Body diagram on the left.
                        _BodyDiagram(highlight: selected),
                      ],
                    ),
                  ),
                ),
                // Reserve clearance for the bottom toast (fixed-height box).
                const SizedBox(height: 108),
              ],
            ),
          ),
          // Toast pinned with 24px breathing room from the card's outer
          // right / left / bottom edges, without shifting any other
          // elements when it shows/hides.
          PositionedDirectional(
            start: 24,
            end: 24,
            bottom: 24,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: toastText == null
                  ? const SizedBox(key: ValueKey('toast-empty'))
                  : Padding(
                      key: const ValueKey('toast-visible'),
                      padding: const EdgeInsets.only(top: 8),
                      child: ExerciseInfoToast(text: toastText!, minHeight: 76),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceOptionButton extends StatelessWidget {
  const _PlaceOptionButton({
    required this.option,
    required this.selected,
    required this.onTap,
    required this.onInfoTap,
  });

  final _PlaceOption option;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(12);
    return Material(
      color: context.colors.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: 173,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? AppPalettePurple.shade200
                  : context.colors.shade300,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.label,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.xs,
                    fontWeight: selected
                        ? AppFontWeights.bold
                        : AppFontWeights.medium,
                    color: selected
                        ? context.colors.shade700
                        : context.colors.shade500,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                option.emoji,
                style: const TextStyle(fontSize: 16, height: 1),
              ),
              if (selected) ...[
                const SizedBox(width: 4),
                _InfoBadge(onTap: onInfoTap),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.onTap});

  final VoidCallback onTap;

  static const String _lightbulbSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 15 15" fill="none">
  <path d="M7.5 0.78125C10.3477 0.78125 12.6562 3.08978 12.6562 5.9375C12.6562 7.52987 11.934 8.95432 10.8008 9.89941C10.2286 10.3766 9.84375 10.9577 9.84375 11.5625V12.8125C9.84375 13.5892 9.21415 14.2188 8.4375 14.2188H6.5625C5.78585 14.2188 5.15625 13.5892 5.15625 12.8125V11.5625C5.15625 10.9577 4.77138 10.3766 4.19922 9.89941C3.066 8.95432 2.34375 7.52987 2.34375 5.9375C2.34375 3.08978 4.65228 0.78125 7.5 0.78125ZM6.09375 12.8125C6.09375 13.0714 6.30362 13.2812 6.5625 13.2812H8.4375C8.69638 13.2812 8.90625 13.0714 8.90625 12.8125V12.0312H6.09375V12.8125ZM7.5 1.71875C5.17005 1.71875 3.28125 3.60755 3.28125 5.9375C3.28125 7.23999 3.87112 8.4041 4.7998 9.17871C5.35959 9.64557 5.89188 10.2992 6.04785 11.0938H8.95215C9.10812 10.2992 9.64041 9.64557 10.2002 9.17871C11.1289 8.4041 11.7188 7.23999 11.7188 5.9375C11.7188 3.60755 9.82995 1.71875 7.5 1.71875ZM7.50098 8.125C7.84604 8.12513 8.12598 8.4049 8.12598 8.75C8.12598 9.0951 7.84604 9.37487 7.50098 9.375H7.49512C7.14994 9.375 6.87012 9.09518 6.87012 8.75C6.87012 8.40482 7.14994 8.125 7.49512 8.125H7.50098ZM7.5 3.28125C8.40991 3.28125 9.21856 3.9664 9.21875 4.89551C9.21875 5.22559 9.1129 5.53148 8.93555 5.78418C8.82617 5.94 8.69843 6.08809 8.58203 6.2207C8.56062 6.24509 8.54014 6.26958 8.51953 6.29297C8.42295 6.40255 8.3343 6.502 8.25293 6.60449C8.04934 6.86098 7.96875 7.03875 7.96875 7.1875C7.96875 7.44638 7.75888 7.65625 7.5 7.65625C7.24112 7.65625 7.03125 7.44638 7.03125 7.1875C7.03125 6.7036 7.28963 6.31092 7.51855 6.02246C7.61648 5.89909 7.72432 5.77695 7.82129 5.66699C7.8406 5.64509 7.85959 5.62343 7.87793 5.60254C7.99356 5.47081 8.09067 5.35615 8.16797 5.24609C8.24125 5.14169 8.28125 5.0216 8.28125 4.89551C8.28105 4.55923 7.97055 4.21875 7.5 4.21875C7.08225 4.21875 6.71875 4.61212 6.71875 5C6.71875 5.25888 6.50888 5.46875 6.25 5.46875C5.99112 5.46875 5.78125 5.25888 5.78125 5C5.78125 4.12223 6.53704 3.28125 7.5 3.28125Z" fill="#999999"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 23,
        height: 23,
        decoration: BoxDecoration(
          color: context.colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A101828),
              offset: Offset(0, 4),
              blurRadius: 8,
              spreadRadius: -2,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: SvgPicture.string(
          _lightbulbSvg,
          width: 15,
          height: 15,
        ),
      ),
    );
  }
}

class _BodyDiagram extends StatelessWidget {
  const _BodyDiagram({required this.highlight});

  final _BodyPart? highlight;

  static const Color _bodyColor = Color(0x4D9D8FCE); // 30% opacity
  static const Color _highlightColor = Color(0xFF9D8FCE);

  static const double _width = 120;
  // Matches the bottom of the legs so the figure sits inside the box
  // without empty space, which makes Row.crossAxisAlignment.center actually
  // line up the figure's mid-line with the options column's mid-line.
  static const double _height = 293;

  // Vertical positions (top edges).
  static const double _headTop = 0;
  static const double _headSize = 46;
  static const double _bodyTop = 56;
  static const double _bodyHeight = 140;
  static const double _bodyWidth = 70;
  static const double _armTop = 66;
  static const double _armHeight = 110;
  static const double _armWidth = 20;
  static const double _legsTop = 198;
  static const double _legHeight = 95;
  static const double _legWidth = 20;

  @override
  Widget build(BuildContext context) {
    const double centerX = _width / 2;
    // Lighten the silhouette in dark mode so it reads on the dark scaffold.
    final Color bodyColor =
        context.forDark(_bodyColor, const Color(0x999D8FCE));
    return SizedBox(
      width: _width,
      height: _height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Head.
          Positioned(
            top: _headTop,
            left: centerX - _headSize / 2,
            width: _headSize,
            height: _headSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bodyColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Body / torso.
          Positioned(
            top: _bodyTop,
            left: centerX - _bodyWidth / 2,
            width: _bodyWidth,
            height: _bodyHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bodyColor,
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          // Right arm.
          Positioned(
            top: _armTop,
            left: centerX - _bodyWidth / 2 - _armWidth - 4,
            width: _armWidth,
            height: _armHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bodyColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Left arm.
          Positioned(
            top: _armTop,
            left: centerX + _bodyWidth / 2 + 4,
            width: _armWidth,
            height: _armHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bodyColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Right leg.
          Positioned(
            top: _legsTop,
            left: centerX - 13 - _legWidth,
            width: _legWidth,
            height: _legHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bodyColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Left leg.
          Positioned(
            top: _legsTop,
            left: centerX + 13,
            width: _legWidth,
            height: _legHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bodyColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Highlight overlay based on selected part.
          ..._highlights(context, centerX),
        ],
      ),
    );
  }

  List<Widget> _highlights(BuildContext context, double centerX) {
    switch (highlight) {
      case _BodyPart.head:
        return _doubleRing(cx: centerX, cy: _headTop + _headSize / 2);
      case _BodyPart.throat:
        return _doubleRing(
          cx: centerX,
          cy: _headSize + 8,
          innerSize: 36,
          outerSize: 50,
        );
      case _BodyPart.shoulders:
        // Wider stadium-shaped rings to wrap both shoulders.
        return _doubleStadium(
          cx: centerX,
          cy: _bodyTop + 18,
          innerWidth: 110,
          innerHeight: 38,
          outerWidth: 124,
          outerHeight: 52,
        );
      case _BodyPart.chest:
        return _doubleRing(cx: centerX, cy: _bodyTop + 50);
      case _BodyPart.belly:
        return _doubleRing(cx: centerX, cy: _bodyTop + _bodyHeight - 50);
      case _BodyPart.hands:
        // One double-ring on each hand (bottom of each arm).
        final double handY = _armTop + _armHeight - 8;
        final double rightHandX =
            centerX - _bodyWidth / 2 - _armWidth / 2 - 4;
        final double leftHandX = centerX + _bodyWidth / 2 + _armWidth / 2 + 4;
        return [
          ..._doubleRing(
            cx: rightHandX,
            cy: handY,
            innerSize: 36,
            outerSize: 48,
          ),
          ..._doubleRing(
            cx: leftHandX,
            cy: handY,
            innerSize: 36,
            outerSize: 48,
          ),
        ];
      case _BodyPart.unsure:
        // Thought cloud next to the head: main "?" bubble with two small
        // trailing puffs that point down-right toward the head.
        return [
          // Smaller puff closest to the head.
          Positioned(
            top: 14,
            left: centerX - 36,
            child: _cloudPuff(context, size: 6),
          ),
          // Middle puff between the main bubble and the small puff.
          Positioned(
            top: 4,
            left: centerX - 44,
            child: _cloudPuff(context, size: 10),
          ),
          // Main "?" bubble.
          Positioned(
            top: -8,
            left: centerX - 64,
            child: Container(
              width: 28,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.purpleSoftFill(AppPalettePurple.shade600),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: AppPalettePurple.shade400,
                  width: 1,
                ),
              ),
              child: const Text(
                '?',
                style: TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: 14,
                  fontWeight: AppFontWeights.bold,
                  color: AppPalettePurple.shade200,
                  height: 1,
                ),
              ),
            ),
          ),
        ];
      case null:
        return const [];
    }
  }

  // Small filled circle used as a trailing puff under the "?" thought
  // bubble — same purple-600 fill / purple-400 border as the bubble itself.
  Widget _cloudPuff(BuildContext context, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.purpleSoftFill(AppPalettePurple.shade600),
        shape: BoxShape.circle,
        border: Border.all(color: AppPalettePurple.shade400, width: 1),
      ),
    );
  }

  // Two concentric circle rings: a large faint outer ring and a smaller
  // thick inner ring, both centered at (cx, cy).
  List<Widget> _doubleRing({
    required double cx,
    required double cy,
    double innerSize = 70,
    double outerSize = 82,
  }) {
    return [
      Positioned(
        left: cx - outerSize / 2,
        top: cy - outerSize / 2,
        width: outerSize,
        height: outerSize,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _highlightColor.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
        ),
      ),
      Positioned(
        left: cx - innerSize / 2,
        top: cy - innerSize / 2,
        width: innerSize,
        height: innerSize,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _highlightColor, width: 3),
          ),
        ),
      ),
    ];
  }

  // Two concentric stadium (rounded-rect) rings for the shoulders highlight.
  List<Widget> _doubleStadium({
    required double cx,
    required double cy,
    required double innerWidth,
    required double innerHeight,
    required double outerWidth,
    required double outerHeight,
  }) {
    return [
      Positioned(
        left: cx - outerWidth / 2,
        top: cy - outerHeight / 2,
        width: outerWidth,
        height: outerHeight,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(outerHeight / 2),
            border: Border.all(
              color: _highlightColor.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
        ),
      ),
      Positioned(
        left: cx - innerWidth / 2,
        top: cy - innerHeight / 2,
        width: innerWidth,
        height: innerHeight,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(innerHeight / 2),
            border: Border.all(color: _highlightColor, width: 3),
          ),
        ),
      ),
    ];
  }
}
