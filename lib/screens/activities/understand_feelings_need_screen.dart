import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../core/activities/activity_api.dart';
import '../../core/activities/emotion_mood_mapper.dart';
import '../../core/activities/start_activity_store.dart';
import '../../core/tasks/reminder_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/nav/app_top_nav.dart';
import '../auth/success_screen.dart';
import 'breathe_calmly_learn_more_screen.dart';
import 'understand_feelings_progress.dart';

class UnderstandFeelingsNeedScreen extends StatefulWidget {
  const UnderstandFeelingsNeedScreen({
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
  final String moodLabel;

  /// Backend body-location id carried forward from step 2 (e.g. "chest").
  final String bodyLocation;
  final String placeLabel;
  final int intensity;
  final String intensityLabel;

  @override
  State<UnderstandFeelingsNeedScreen> createState() =>
      _UnderstandFeelingsNeedScreenState();
}

class _NeedOption {
  const _NeedOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.popupTitle,
    required this.popupBody,
    required this.popupPrimaryLabel,
    required this.badgeColor,
  });

  final String id;
  final String title;
  final String subtitle;
  final String emoji;

  // Per-option confirmation popup shown when the tile is tapped.
  final String popupTitle;
  final String popupBody;
  final String popupPrimaryLabel;
  final Color badgeColor;
}

class _UnderstandFeelingsNeedScreenState
    extends State<UnderstandFeelingsNeedScreen> {
  static const List<_NeedOption> _options = [
    _NeedOption(
      id: 'breathing',
      title: 'أهدأ شوي',
      subtitle: 'نشاط هادئ يناسب شعورك',
      emoji: '🌬️',
      popupTitle: 'أهدأ شوي',
      popupBody: 'أنت بأمان، وكل شعور سوف يمر.',
      popupPrimaryLabel: 'انتقل للتنفس',
      badgeColor: AppInformationColors.shade100,
    ),
    _NeedOption(
      id: 'break',
      title: 'آخذ بريك',
      subtitle: 'دقيقة بعيد عن الشاشة',
      emoji: '☕',
      popupTitle: 'خذ دقيقة',
      popupBody:
          'ابعد عن الشاشة شوي، خذ نفس، وارجع لما تكون جاهز. ما فيه شيء يستعجلك.',
      popupPrimaryLabel: 'تم',
      badgeColor: AppWarningColors.shade100,
    ),
    _NeedOption(
      id: 'talk',
      title: 'أكلم شخص',
      subtitle: 'شخص تثق فيه قريب منك',
      emoji: '💬',
      popupTitle: 'أكلم شخص',
      popupBody: 'الأهل، صديق مقرّب، معلم، أو مستشار المدرسة.',
      popupPrimaryLabel: 'تم',
      badgeColor: AppSuccessColors.shade100,
    ),
    _NeedOption(
      id: 'continue',
      title: 'أكمل يومي',
      subtitle: 'تكفيني وقفة اليوم',
      emoji: '✨',
      popupTitle: 'أكمل يومي',
      popupBody: 'اليوم ابدأ بخطوة وحدة بس 🤍',
      popupPrimaryLabel: 'تم',
      badgeColor: Color(0xFFE4E1F4),
    ),
  ];

  String? _selectedId;

  /// Tapping a tile selects it and opens its confirmation popup. The popup's
  /// primary button finalises the step (breathing → the breathing exercise,
  /// the rest → the success screen); "العودة" just closes it.
  void _onNeedTap(String id) {
    setState(() => _selectedId = id);
    final _NeedOption option = _options.firstWhere((o) => o.id == id);
    _showPopup(option);
  }

  Future<void> _showPopup(_NeedOption option) async {
    final bool? proceed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _NeedPopup(option: option),
    );
    if (proceed == true && mounted) _finalize(option);
  }

  /// Acts on the chosen need, then returns the success-screen subtitle.
  ///
  /// أهدأ شوي / آخذ بريك map to a concrete activity, which we stash for the
  /// home's "ابدأ نشاطك" card. أكلم شخص / أكمل يومي have no in-app activity, so
  /// they become a gentle "لا تنسى" reminder card on the home (ReminderStore),
  /// not a backend task.
  /// All four are best-effort (fire-and-forget) so a network hiccup never
  /// blocks the success screen.
  String _actOnNeed() {
    switch (_selectedId) {
      case 'breathing':
      case 'break':
        // Act now: surface activities for the mood inferred from this feeling
        // in the home's "ابدأ نشاطك" card (separate from "أنشطة تناسب مزاجك").
        final String? mood = mapEmotionToMood(widget.moodId, widget.intensity);
        if (mood != null) StartActivityStore.instance.setMood(mood);
        return 'نشاطك صار جاهز في الرئيسية، ابدأه وقت ما يناسبك 💜';
      case 'talk':
        // No in-app activity for talking — surface a gentle reminder card on
        // the home (not a backend task).
        ReminderStore.instance.set('لا تنسى تكلّم شخص تثق فيه');
        return 'حطّينا لك تذكير لطيف في الرئيسية، ما يضيع عليك 💜';
      case 'continue':
        ReminderStore.instance.set('خذ لك وقفة لطيفة اليوم');
        return 'حطّينا لك تذكير لطيف في الرئيسية، ما يضيع عليك 💜';
      default:
        return 'فهمت شعورك، وحددت خطوتك الجاية.\nهذي ملاحظة صغيرة تغيّر يومك 💜';
    }
  }

  void _onFinish() {
    final _NeedOption option =
        _options.firstWhere((o) => o.id == _selectedId);
    _finalize(option);
  }

  void _finalize(_NeedOption option) {
    // Best-effort: record the completed exercise with the user's selections.
    ActivityApi.complete(
      ActivitySlugs.understandFeelings,
      result: <String, dynamic>{
        'emotion': widget.moodId,
        'body_location': widget.bodyLocation,
        'intensity': widget.intensity,
        'need': option.id,
      },
    );
    final NavigatorState navigator = Navigator.of(context);
    if (option.id == 'breathing') {
      // "انتقل للتنفس" → open the breathing DETAIL screen (which then shows the
      // "قبل ما تبدأ" popup before the session) instead of jumping straight into
      // the session and bypassing the official flow.
      final String? mood = mapEmotionToMood(widget.moodId, widget.intensity);
      if (mood != null) StartActivityStore.instance.setMood(mood);
      navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const BreatheCalmlyLearnMoreScreen(),
        ),
      );
      return;
    }
    final String subtitle = _actOnNeed();
    navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SuccessScreen(
          title: 'أحسنت',
          subtitle: subtitle,
          buttonLabel: 'العودة للرئيسية',
          onContinue: () => navigator.popUntil((route) => route.isFirst),
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
                  currentStep: 4,
                  steps: exerciseSteps,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _NeedCard(
                    options: _options,
                    selectedId: _selectedId,
                    onSelect: _onNeedTap,
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
                  label: 'اتمام التمرين',
                  expand: true,
                  onPressed: _selectedId == null ? null : _onFinish,
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

class _NeedCard extends StatelessWidget {
  const _NeedCard({
    required this.options,
    required this.selectedId,
    required this.onSelect,
  });

  final List<_NeedOption> options;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
            'وش تحتاج الآن؟',
            textAlign: TextAlign.center,
            style: AppTextStyles.thmanyahHeading(
              context,
            ).copyWith(fontSize: AppFontSizes.md, height: 1.2),
          ),
          const SizedBox(height: 8),
          Text(
            'اختر خطوة صغيرة تناسبك.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.sm,
              fontWeight: AppFontWeights.regular,
              color: context.colors.shade500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          for (int i = 0; i < options.length; i++) ...[
            if (i != 0) const SizedBox(height: 12),
            _NeedOptionTile(
              option: options[i],
              selected: selectedId == options[i].id,
              onTap: () => onSelect(options[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

class _NeedOptionTile extends StatelessWidget {
  const _NeedOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _NeedOption option;
  final bool selected;
  final VoidCallback onTap;

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              // Emoji first → renders on the right in RTL.
              _NeedEmojiBadge(emoji: option.emoji),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.title,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: AppFontFamily.text,
                        fontSize: AppFontSizes.sm,
                        fontWeight: AppFontWeights.semibold,
                        color: context.colors.shade700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: AppFontFamily.text,
                        fontSize: AppFontSizes.xxs,
                        fontWeight: AppFontWeights.regular,
                        color: context.colors.shade500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeedEmojiBadge extends StatelessWidget {
  const _NeedEmojiBadge({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.purpleSoftFill(AppPalettePurple.shade600),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 18, height: 1)),
    );
  }
}

/// Per-need confirmation popup. Pops `true` from the primary action (which
/// finalises the step) and `false`/null from "العودة" (just closes).
class _NeedPopup extends StatelessWidget {
  const _NeedPopup({required this.option});

  final _NeedOption option;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 325,
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            decoration: BoxDecoration(
              color: context.colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              boxShadow: AppShadows.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: option.badgeColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      option.emoji,
                      style: const TextStyle(fontSize: 28, height: 1),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  option.popupTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.thmanyahHeading(context).copyWith(
                    fontSize: AppFontSizes.sm,
                    color: context.colors.shade600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  option.popupBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.xxs,
                    fontWeight: AppFontWeights.regular,
                    color: context.colors.shade500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Row(
                  children: [
                    Expanded(
                      child: _PopupButton(
                        label: option.popupPrimaryLabel,
                        filled: true,
                        onTap: () => Navigator.of(context).pop(true),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _PopupButton(
                        label: 'العودة',
                        filled: false,
                        onTap: () => Navigator.of(context).pop(false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PopupButton extends StatelessWidget {
  const _PopupButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: filled ? AppPalettePurple.shade200 : context.colors.white,
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
            boxShadow: filled ? AppShadows.xs : null,
            border: filled
                ? null
                : Border.all(color: AppPalettePurple.shade200, width: 1),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xs,
              fontWeight: AppFontWeights.semibold,
              color: filled ? AppNeutralColors.white : AppPalettePurple.shade200,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
