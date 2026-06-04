import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../core/activities/activity_api.dart';
import '../../core/mood/mood_recommendation.dart';
import '../../core/mood/mood_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/cards/app_section_card.dart';
import '../../widgets/nav/app_top_nav.dart';
import '../activities/balance_station_screen.dart';
import '../activities/journaling_space_screen.dart';
import '../activities/play_area_screen.dart';
import '../activities/understand_feelings_exercise_screen.dart';
import 'main_shell.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  // Today's recorded mood slug — drives the single daily recommendation.
  // null = none recorded / not loaded yet → neutral fallback line.
  String? _moodSlug;

  // The shell's active-tab listenable, so we can re-read today's mood every
  // time the Activities tab becomes visible (the tab is kept alive in an
  // IndexedStack, so initState alone would leave the card stale after the user
  // records a mood elsewhere).
  ValueListenable<int>? _activeIndex;

  @override
  void initState() {
    super.initState();
    _refreshMood();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ValueListenable<int>? listenable = MainShell.activeIndexOf(context);
    if (listenable != _activeIndex) {
      _activeIndex?.removeListener(_onTabChanged);
      _activeIndex = listenable;
      _activeIndex?.addListener(_onTabChanged);
    }
  }

  @override
  void dispose() {
    _activeIndex?.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (_activeIndex?.value == MainShell.activitiesIndex) {
      _refreshMood();
    }
  }

  /// Best-effort read of today's mood so "مقترح اليوم" matches how the user
  /// feels. Failures leave the neutral fallback in place.
  void _refreshMood() {
    MoodService.instance.todayMoodInfo().then((info) {
      if (mounted) setState(() => _moodSlug = info.slug);
    });
  }

  /// The approved per-mood daily recommendation line, from the single shared
  /// source of truth ([moodRecommendationFor]). Falls back to the no-mood line
  /// when nothing is recorded today.
  String _suggestionBody() => moodRecommendationFor(_moodSlug).sentence;

  /// Opens the activity matched to today's mood per the shared mapping, reusing
  /// existing routes only. Breathing goes to Balance Station (NOT the session
  /// directly) so the official "قبل ما تبدأ" flow is preserved.
  void _onSuggestionTap() {
    switch (moodRecommendationFor(_moodSlug).target) {
      case MoodTarget.focus:
        MainShell.jumpTo(context, MainShell.focusIndex);
        return;
      case MoodTarget.journey:
      // Journey route is available, so مسترخي resolves to Journey too.
      case MoodTarget.journeyOrFocus:
        MainShell.jumpTo(context, MainShell.journeyIndex);
        return;
      case MoodTarget.games:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(
              name: ActivityCategoryRoutes.playArea,
            ),
            builder: (_) => const PlayAreaScreen(),
          ),
        );
        return;
      case MoodTarget.journal:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const JournalingSpaceScreen(),
          ),
        );
        return;
      case MoodTarget.understandFeelings:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const UnderstandFeelingsExerciseScreen(),
          ),
        );
        return;
      case MoodTarget.breathing:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(
              name: ActivityCategoryRoutes.balanceStation,
            ),
            builder: (_) => const BalanceStationScreen(),
          ),
        );
        return;
      case MoodTarget.ai:
        Navigator.of(context).pushNamed('/smart-companion');
        return;
      case MoodTarget.activitiesDefault:
        MainShell.jumpTo(context, MainShell.activitiesIndex);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppTopNav(
              title: 'الأنشطـة',
              subtitle: 'نشاطات تساعدك ترتب أفكارك وتخفف التفكير الزائد',
              showBackButton: false,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  0,
                  AppSpacing.xxl,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SuggestionCard(
                      title: 'مقترح اليوم ✨',
                      body: _suggestionBody(),
                      onTap: _onSuggestionTap,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ActivityCard(
                      title: 'محطة التوازن 🌀',
                      body: 'استرخ وركّز',
                      tags: const [
                        _ActivityTagData(
                          label: 'تمارين التنفس',
                          iconAsset: AppSvgIcons.activitiesBreathing,
                          scheme: _TagScheme.cyan,
                        ),
                        _ActivityTagData(
                          label: 'تمارين اليقظة',
                          iconAsset: AppSvgIcons.activitiesMindfulness24,
                          scheme: _TagScheme.cyan,
                        ),
                      ],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          settings: const RouteSettings(
                            name: ActivityCategoryRoutes.balanceStation,
                          ),
                          builder: (_) => const BalanceStationScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ActivityCard(
                      title: 'مساحة التدوين 📝',
                      body: 'أفكار، خواطر .. كل ما يزدحم به عقلك دوّنه هنا!',
                      tags: const [
                        _ActivityTagData(
                          label: 'كتابة',
                          iconAsset: AppSvgIcons.activitiesPencil,
                          scheme: _TagScheme.yellow,
                        ),
                      ],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const JournalingSpaceScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ActivityCard(
                      title: 'منطقة اللعب 🎮',
                      body: 'استمتع باللعب!',
                      tags: const [
                        _ActivityTagData(
                          label: 'بطاقات المشاعر',
                          iconAsset: AppSvgIcons.activitiesCards,
                          scheme: _TagScheme.green,
                        ),
                        _ActivityTagData(
                          label: 'الوجه المبتسم',
                          iconAsset: AppSvgIcons.activitiesSmiley,
                          scheme: _TagScheme.green,
                        ),
                      ],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          settings: const RouteSettings(
                            name: ActivityCategoryRoutes.playArea,
                          ),
                          builder: (_) => const PlayAreaScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.title,
    required this.body,
    this.onTap,
  });

  final String title;
  final String body;

  /// Opens the activity section matched to today's mood. Null = not tappable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.xl);
    return Material(
      color: context.colors.purpleSoftBg,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppPalettePurple.shade200, width: 0.5),
            boxShadow: AppShadows.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.right,
                style: AppTextStyles.thmanyahHeading(context).copyWith(
                  fontSize: AppFontSizes.sm,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                body,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.xs,
                  fontWeight: AppFontWeights.regular,
                  color: context.colors.shade600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.title,
    required this.body,
    required this.tags,
    required this.onTap,
  });

  final String title;
  final String body;
  final List<_ActivityTagData> tags;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: AppTextStyles.thmanyahHeading(context).copyWith(
              fontSize: AppFontSizes.sm,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xxs,
              fontWeight: AppFontWeights.regular,
              color: context.colors.shade500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [for (final t in tags) _ActivityTag(data: t)],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Full-width "ابدأ ←" CTA at the bottom of the card (bigger and
          // clearer than the old corner pill). Visual only — the whole card
          // is the button.
          const _CardStartButton(),
        ],
      ),
    );
  }
}

/// The card's call-to-action — a full-width "ابدأ ←" button at the bottom of
/// the card (bigger/clearer than the old corner pill). Visual only — the whole
/// card is the button.
class _CardStartButton extends StatelessWidget {
  const _CardStartButton();

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppPalettePurple.shade200,
        borderRadius: radius,
        boxShadow: AppShadows.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'ابدأ',
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.sm,
              fontWeight: AppFontWeights.bold,
              color: AppNeutralColors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          SvgPicture.asset(
            AppSvgIcons.arrowLeft,
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              AppNeutralColors.white,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}

enum _TagScheme { cyan, yellow, green }

class _ActivityTagData {
  const _ActivityTagData({
    required this.label,
    required this.iconAsset,
    required this.scheme,
  });

  final String label;
  final String iconAsset;
  final _TagScheme scheme;
}

class _ActivityTag extends StatelessWidget {
  const _ActivityTag({required this.data});

  final _ActivityTagData data;

  // Cyan scheme is not provided by tokens; matches icon fill #84CAFF.
  static const Color _cyanBorder = Color(0xFF84CAFF);
  static const Color _cyanBg = Color(0xFFF5FAFF);
  // Dark-mode tag fills: deep shades of the same family so the bright accent
  // fg/border stays legible on the dark card instead of a glaring pastel.
  static const Color _cyanBgDark = AppInformationColors.shade950;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final ({Color bg, Color fg, Color border}) colors = switch (data.scheme) {
      _TagScheme.cyan => (
          bg: dark ? _cyanBgDark : _cyanBg,
          fg: _cyanBorder,
          border: _cyanBorder,
        ),
      _TagScheme.yellow => (
          bg: dark ? AppWarningColors.shade950 : AppPaletteButteryYellow.shade500,
          fg: AppWarningColors.shade300,
          border: AppWarningColors.shade300,
        ),
      _TagScheme.green => (
          bg: dark ? AppSuccessColors.shade950 : AppSuccessColors.shade25,
          fg: AppSuccessColors.shade400,
          border: AppSuccessColors.shade400,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            data.iconAsset,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(colors.fg, BlendMode.srcIn),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            data.label,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xxs,
              fontWeight: AppFontWeights.medium,
              color: colors.fg,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
