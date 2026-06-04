import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../core/activities/activity_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/nav/app_top_nav.dart';
import 'activate_senses_exercise_screen.dart';
import 'activate_senses_learn_more_screen.dart';
import 'breathe_calmly_learn_more_screen.dart';
import 'breathing_exercise_screen.dart';
import 'mindfulness_info_modal.dart';
import 'release_pressure_learn_more_screen.dart';
import 'sleep_calm_learn_more_screen.dart';
import 'stop_spiral_learn_more_screen.dart';
import 'understand_feelings_exercise_screen.dart';
import 'understand_feelings_learn_more_screen.dart';

enum _BalanceFilter { breathing, mindfulness }

enum _BalanceActivityId {
  breatheCalm,
  releasePressure,
  stopSpiral,
  sleepCalm,
  activateSenses,
  understandFeelings,
}

class _BalanceActivity {
  const _BalanceActivity({
    required this.id,
    required this.title,
    required this.subtitle,
    this.tagLabel,
    this.tagIconAsset,
  });

  final _BalanceActivityId id;
  final String title;
  final String subtitle;
  final String? tagLabel;
  final String? tagIconAsset;
}

class BalanceStationScreen extends StatefulWidget {
  const BalanceStationScreen({super.key});

  @override
  State<BalanceStationScreen> createState() => _BalanceStationScreenState();
}

class _BalanceStationScreenState extends State<BalanceStationScreen> {
  _BalanceFilter _filter = _BalanceFilter.breathing;

  // null = "unknown" (offline/error/before fetch) → show every card.
  Set<String>? _activeSlugs;

  // Backend mood-scored picks (ordered, top first). Empty until loaded / on
  // error — in which case no "مناسب لك الآن" tag is shown.
  List<String> _recommendedOrder = const <String>[];

  @override
  void initState() {
    super.initState();
    ActivityApi.activeSlugs().then((slugs) {
      if (mounted) setState(() => _activeSlugs = slugs);
    }).catchError((_) {
      // offline / error: leave _activeSlugs null so all cards stay visible.
    });
    ActivityApi.recommended().then((slugs) {
      if (mounted) setState(() => _recommendedOrder = slugs);
    });
  }

  bool _isVisible(String slug) =>
      _activeSlugs == null || _activeSlugs!.contains(slug);

  // The single "top fit" slug within [section]: the earliest of its activities
  // to appear in the backend's mood-scored order. null = none matched.
  String? _topFitSlug(List<_BalanceActivity> section) {
    if (_recommendedOrder.isEmpty) return null;
    final Set<String> slugs = section.map((a) => _slugFor(a.id)).toSet();
    for (final String slug in _recommendedOrder) {
      if (slugs.contains(slug)) return slug;
    }
    return null;
  }

  // Maps a balance-station activity to its backend slug.
  String _slugFor(_BalanceActivityId id) {
    switch (id) {
      case _BalanceActivityId.understandFeelings:
        return ActivitySlugs.understandFeelings;
      case _BalanceActivityId.activateSenses:
        return ActivitySlugs.activateSenses;
      case _BalanceActivityId.breatheCalm:
        return ActivitySlugs.breatheCalmly;
      case _BalanceActivityId.releasePressure:
        return ActivitySlugs.releasePressure;
      case _BalanceActivityId.stopSpiral:
        return ActivitySlugs.stopSpiral;
      case _BalanceActivityId.sleepCalm:
        return ActivitySlugs.sleepCalm;
    }
  }

  static const List<_BalanceActivity> _breathingActivities = [
    _BalanceActivity(
      id: _BalanceActivityId.breatheCalm,
      title: 'تنفّس بهدوء 🧘',
      subtitle: 'عندما تشعر بالقلق أو التوتر',
    ),
    _BalanceActivity(
      id: _BalanceActivityId.releasePressure,
      title: 'أطفئ الضغط 🕯',
      subtitle: 'عندما تشعر بالضغط أو التوتر',
    ),
    _BalanceActivity(
      id: _BalanceActivityId.stopSpiral,
      title: 'وقف الدوامة 🌀',
      subtitle: 'عندما يزدحم يومك بالقلق أو التوتر',
    ),
    _BalanceActivity(
      id: _BalanceActivityId.sleepCalm,
      title: 'نام بهدوء 🌙',
      subtitle: 'عندما يطول يومك وتبقى أفكارك مستيقظة',
    ),
  ];

  static const List<_BalanceActivity> _mindfulnessActivities = [
    _BalanceActivity(
      id: _BalanceActivityId.activateSenses,
      title: 'فعّل حواسك 👃',
      subtitle:
          'ركّز على اللي تشوفه وتسمعه وتحسّه عشان تهدّي تشتّت الأفكار.',
      tagLabel: 'تمارين تنظيم الانتباه',
      tagIconAsset: AppSvgIcons.activitiesMindfulness24,
    ),
    _BalanceActivity(
      id: _BalanceActivityId.understandFeelings,
      title: 'افهم شعورك 🧠',
      subtitle:
          'حدد شعورك ولاحظ أثره في جسمك عشان تفهم اللي تمر فيه بهدوء.',
      tagLabel: 'تمارين تنظيم الانتباه',
      tagIconAsset: AppSvgIcons.activitiesMindfulness24,
    ),
  ];

  List<_BalanceActivity> get _activities {
    final List<_BalanceActivity> source = _filter == _BalanceFilter.breathing
        ? _breathingActivities
        : _mindfulnessActivities;
    // Hide cards whose backend Activity an admin has deactivated.
    return source.where((a) => _isVisible(_slugFor(a.id))).toList();
  }

  void _selectFilter(_BalanceFilter filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
  }

  void _onStart(BuildContext context, _BalanceActivity activity) {
    switch (activity.id) {
      case _BalanceActivityId.understandFeelings:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const UnderstandFeelingsExerciseScreen(),
          ),
        );
      case _BalanceActivityId.activateSenses:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ActivateSensesExerciseScreen(),
          ),
        );
      case _BalanceActivityId.breatheCalm:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const BreathingExerciseScreen(
              exercise: BreathingExercise.breatheCalmly,
            ),
          ),
        );
      case _BalanceActivityId.releasePressure:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const BreathingExerciseScreen(
              exercise: BreathingExercise.releasePressure,
            ),
          ),
        );
      case _BalanceActivityId.stopSpiral:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const BreathingExerciseScreen(
              exercise: BreathingExercise.stopSpiral,
            ),
          ),
        );
      case _BalanceActivityId.sleepCalm:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const BreathingExerciseScreen(
              exercise: BreathingExercise.sleepCalm,
            ),
          ),
        );
    }
  }

  void _onLearnMore(BuildContext context, _BalanceActivity activity) {
    switch (activity.id) {
      case _BalanceActivityId.understandFeelings:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const UnderstandFeelingsLearnMoreScreen(),
          ),
        );
      case _BalanceActivityId.activateSenses:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ActivateSensesLearnMoreScreen(),
          ),
        );
      case _BalanceActivityId.breatheCalm:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const BreatheCalmlyLearnMoreScreen(),
          ),
        );
      case _BalanceActivityId.releasePressure:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ReleasePressureLearnMoreScreen(),
          ),
        );
      case _BalanceActivityId.stopSpiral:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const StopSpiralLearnMoreScreen(),
          ),
        );
      case _BalanceActivityId.sleepCalm:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const SleepCalmLearnMoreScreen(),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.shade50,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTopNav(
                title: 'محطة التوازن',
                subtitle: 'تمارين بسيطة تساعدك ترجع لحالتك المعتدلة',
                // Surfaces a يقظة ذهنية info button (styled like the back
                // button, on the left) only while the mindfulness filter is
                // active; tapping it opens the explainer modal.
                trailing: _filter == _BalanceFilter.mindfulness
                    ? MergeSemantics(
                        child: Semantics(
                          button: true,
                          label: 'عن اليقظة الذهنية',
                          child: Material(
                            color: context.colors.white,
                            shape: const CircleBorder(),
                            shadowColor: const Color(0x1A101828),
                            elevation: 1,
                            child: InkWell(
                              onTap: () => showMindfulnessInfoModal(context),
                              customBorder: const CircleBorder(),
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: Center(
                                  child: SvgPicture.asset(
                                    AppSvgIcons.activitiesMindfulnessHead,
                                    width: 16,
                                    height: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _FilterPill(
                        label: 'تنفس',
                        iconAsset: AppSvgIcons.activitiesBreathing24,
                        selected: _filter == _BalanceFilter.breathing,
                        onTap: () => _selectFilter(_BalanceFilter.breathing),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _FilterPill(
                        label: 'يقظة ذهنية',
                        iconAsset: AppSvgIcons.activitiesMindfulness24,
                        selected: _filter == _BalanceFilter.mindfulness,
                        onTap: () => _selectFilter(_BalanceFilter.mindfulness),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
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
                      for (int i = 0; i < _activities.length; i++) ...[
                        if (i != 0) const SizedBox(height: AppSpacing.xl),
                        _ActivityCard(
                          activity: _activities[i],
                          suggested: _slugFor(_activities[i].id) ==
                              _topFitSlug(_activities),
                          onStart: () => _onStart(context, _activities[i]),
                          onLearnMore: () =>
                              _onLearnMore(context, _activities[i]),
                        ),
                      ],
                    ],
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

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.iconAsset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String iconAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.xl);
    final Color borderColor =
        selected ? AppPalettePurple.shade200 : context.colors.shade200;
    return MergeSemantics(
      child: Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
      color: context.colors.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: ExcludeSemantics(child: Ink(
          decoration: BoxDecoration(
            color: context.colors.white,
            borderRadius: radius,
            border: Border.all(color: borderColor, width: 0.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                offset: Offset(0, 1),
                blurRadius: 1,
              ),
              BoxShadow(
                color: Color(0x0A000000),
                offset: Offset(0, 2),
                blurRadius: 15,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(iconAsset, width: 24, height: 24),
                const SizedBox(width: AppSpacing.md),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.xs,
                    fontWeight: selected
                        ? AppFontWeights.bold
                        : AppFontWeights.semibold,
                    color: context.colors.shade600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        )),
      ),
      ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.suggested,
    required this.onStart,
    required this.onLearnMore,
  });

  final _BalanceActivity activity;
  final bool suggested;
  final VoidCallback onStart;
  final VoidCallback onLearnMore;

  static const double _badgeHeight = 30;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets contentPadding = EdgeInsets.fromLTRB(
      AppSpacing.xl,
      suggested ? _badgeHeight + AppSpacing.lg : AppSpacing.xl,
      AppSpacing.xl,
      AppSpacing.xl,
    );

    return Container(
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.shade200, width: 0.5),
        boxShadow: AppShadows.xs,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: contentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  activity.title,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.thmanyahHeading(context).copyWith(
                    fontSize: AppFontSizes.sm,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  activity.subtitle,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.xxs,
                    fontWeight: AppFontWeights.regular,
                    color: context.colors.shade500,
                    height: 1.5,
                  ),
                ),
                if (activity.tagLabel != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _MindfulnessTag(
                      label: activity.tagLabel!,
                      iconAsset: activity.tagIconAsset!,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'ابدأ التمرين',
                        expand: true,
                        onPressed: onStart,
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
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _LearnMoreButton(onPressed: onLearnMore),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (suggested)
            PositionedDirectional(
              top: 0,
              start: 0,
              child: _SuggestionBadge(),
            ),
        ],
      ),
    );
  }
}

class _MindfulnessTag extends StatelessWidget {
  const _MindfulnessTag({required this.label, required this.iconAsset});

  final String label;
  final String iconAsset;

  static const Color _fg = Color(0xFF84CAFF);
  static const Color _bg = Color(0xFFF5FAFF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.forDark(_bg, AppInformationColors.shade950),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: _fg, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconAsset,
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(_fg, BlendMode.srcIn),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xxs,
              fontWeight: AppFontWeights.medium,
              color: _fg,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionBadge extends StatelessWidget {
  const _SuggestionBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 111,
      height: 30,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppPaletteButteryYellow.shade50,
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(16),
          bottomEnd: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            AppSvgIcons.activitiesSuggestionSparkle,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(
              context.colors.white,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'مناسب لك الآن',
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xxs,
              fontWeight: AppFontWeights.semibold,
              color: context.colors.white,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearnMoreButton extends StatelessWidget {
  const _LearnMoreButton({required this.onPressed});

  final VoidCallback onPressed;

  static const double _height = 44;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return MergeSemantics(
      child: Semantics(
      button: true,
      label: 'اعرف المزيد',
      child: SizedBox(
      height: _height,
      child: Material(
        color: context.colors.white,
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: AppPalettePurple.shade200, width: 1),
            ),
            child: const Text(
              'اعرف المزيد',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.sm,
                fontWeight: AppFontWeights.bold,
                color: AppPalettePurple.shade200,
                height: 1.25,
              ),
            ),
          ),
        ),
      ),
      ),
      ),
    );
  }
}
