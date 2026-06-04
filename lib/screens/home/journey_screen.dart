import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../core/auth/auth_service.dart';
import '../../core/focus/focus_intent_bus.dart';
import '../../core/journey/journey_service.dart';
import '../../core/mood/mood_catalog.dart';
import '../../core/mood/mood_palette.dart';
import '../../core/mood/mood_service.dart';
import '../../models/journey_snapshot.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_loader.dart';
import '../../widgets/cards/app_section_card.dart';
import '../../widgets/nav/app_top_nav.dart';
import 'main_shell.dart';

const double _kBadgeSize = 24.0;
const double _kMonthBadgeSize = 28.0;
const double _kMoodChartAreaHeight = 260;

enum _Mood {
  excited,
  happy,
  relaxed,
  calm,
  bored,
  sad,
  upset,
  tense,
  neutral,
}

class _Tiffany {
  static const Color shade100 = Color(0xFFB9ECE6);
  static const Color shade300 = Color(0xFF81D8D0);
}

extension _MoodStyle on _Mood {
  /// Admin-managed colours from the catalogue's color_seed (keyed by the enum
  /// name == mood slug), falling back to the bundled palette until it loads.
  MoodColors? get _palette {
    final String? seed = MoodCatalog.instance.colorSeedFor(name);
    return seed == null ? null : MoodPalette.forSeed(seed);
  }

  Color get bg => _palette?.bg ?? _bgFallback;

  Color get _bgFallback {
    switch (this) {
      case _Mood.excited:
        return AppPaletteButteryYellow.shade400;
      case _Mood.happy:
        return AppSuccessColors.shade100;
      case _Mood.relaxed:
        return _Tiffany.shade100;
      case _Mood.calm:
        return AppInformationColors.shade50;
      case _Mood.bored:
        return AppWarningColors.shade200;
      case _Mood.sad:
        return AppInformationColors.shade300;
      case _Mood.upset:
        return AppDangerColors.shade100;
      case _Mood.tense:
        return AppPalettePurple.shade500;
      case _Mood.neutral:
        return AppNeutralColors.shade200;
    }
  }

  Color get ring => _palette?.ring ?? _ringFallback;

  Color get _ringFallback {
    switch (this) {
      case _Mood.excited:
        return AppPaletteButteryYellow.shade100;
      case _Mood.happy:
        return AppSuccessColors.shade300;
      case _Mood.relaxed:
        return _Tiffany.shade300;
      case _Mood.calm:
        return AppInformationColors.shade300;
      case _Mood.bored:
        return AppWarningColors.shade400;
      case _Mood.sad:
        return AppInformationColors.shade500;
      case _Mood.upset:
        return AppDangerColors.shade300;
      case _Mood.tense:
        return AppPalettePurple.shade300;
      case _Mood.neutral:
        return AppNeutralColors.shade400;
    }
  }

  Color get bar => _palette?.bar ?? _barFallback;

  Color get _barFallback {
    switch (this) {
      case _Mood.excited:
        return AppPaletteButteryYellow.shade300;
      case _Mood.happy:
        return AppSuccessColors.shade200;
      case _Mood.relaxed:
        return _Tiffany.shade300;
      case _Mood.calm:
        return AppInformationColors.shade200;
      case _Mood.bored:
        return AppWarningColors.shade300;
      case _Mood.sad:
        return AppInformationColors.shade400;
      case _Mood.upset:
        return AppDangerColors.shade200;
      case _Mood.tense:
        return AppPalettePurple.shade500;
      case _Mood.neutral:
        return AppNeutralColors.shade300;
    }
  }

  /// Admin-managed emoji/label — resolve from the live catalogue (GET /moods)
  /// keyed by the enum name (== mood slug), falling back to the bundled value.
  String get emoji => MoodCatalog.instance.emojiFor(name) ?? _emojiFallback;

  String get _emojiFallback {
    switch (this) {
      case _Mood.excited:
        return '🤩';
      case _Mood.happy:
        return '😊';
      case _Mood.relaxed:
        return '😎';
      case _Mood.calm:
        return '😌';
      case _Mood.bored:
        return '😫';
      case _Mood.sad:
        return '😢';
      case _Mood.upset:
        return '😞';
      case _Mood.tense:
        return '😰';
      case _Mood.neutral:
        return '😐';
    }
  }

  String get label => MoodCatalog.instance.labelFor(name) ?? _labelFallback;

  String get _labelFallback {
    switch (this) {
      case _Mood.excited:
        return 'متحمس';
      case _Mood.happy:
        return 'سعيد';
      case _Mood.relaxed:
        return 'مسترخي';
      case _Mood.calm:
        return 'هادئ';
      case _Mood.bored:
        return 'ملول';
      case _Mood.sad:
        return 'حزين';
      case _Mood.upset:
        return 'منزعج';
      case _Mood.tense:
        return 'متوتر';
      case _Mood.neutral:
        return 'محايد';
    }
  }
}

/// Resolve a backend slug to a local `_Mood`. Unknown slugs map to neutral so
/// a new admin-managed mood doesn't crash the journey chart while the client
/// catches up.
_Mood? _moodFromSlug(String? slug) {
  switch (slug) {
    case 'excited':
      return _Mood.excited;
    case 'happy':
      return _Mood.happy;
    case 'relaxed':
      return _Mood.relaxed;
    case 'calm':
      return _Mood.calm;
    case 'bored':
      return _Mood.bored;
    case 'sad':
      return _Mood.sad;
    case 'upset':
      return _Mood.upset;
    case 'tense':
      return _Mood.tense;
    case 'neutral':
      return _Mood.neutral;
    default:
      return null;
  }
}

/// Arabic weekday name from an ISO-8601 date string (YYYY-MM-DD). Falls back
/// to the day-of-month if parsing fails.
String _arabicWeekdayFromIso(String iso) {
  final DateTime? dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  const Map<int, String> names = {
    DateTime.sunday: 'الأحد',
    DateTime.monday: 'الإثنين',
    DateTime.tuesday: 'الثلاثاء',
    DateTime.wednesday: 'الأربعاء',
    DateTime.thursday: 'الخميس',
    DateTime.friday: 'الجمعة',
    DateTime.saturday: 'السبت',
  };
  return names[dt.weekday] ?? '';
}

enum _JourneyRange { week, month }

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  _JourneyRange _range = _JourneyRange.week;

  @override
  void initState() {
    super.initState();
    // Kick a refresh once the screen mounts. JourneyService is a singleton
    // ChangeNotifier — concurrent refreshes (mood check-in, tab switch,
    // pull-to-refresh) collapse onto the same in-flight request, and the
    // AnimatedBuilder below rebuilds whenever the service notifies.
    // Deferred to post-frame: refresh() notifies synchronously, and this
    // screen now sits inside a LoadingOverlay that listens to JourneyService —
    // notifying mid-build would trip a "setState during build" assertion.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) JourneyService.instance.refresh();
    });
    // Live mood catalogue (emoji/label) for the trend badges; rebuild once it
    // lands so the chart shows admin-managed emojis.
    MoodCatalog.instance.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  /// Called by JourneyTabRefresher when the user lands on the رحلتي tab.
  /// Hooked from MainShell so the snapshot stays fresh without forcing a
  /// pull-to-refresh after every home-screen check-in.
  void refreshFromTab() {
    JourneyService.instance.refresh();
  }

  Future<void> _onPullRefresh() => JourneyService.instance.refresh();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: JourneyService.instance,
          builder: (context, _) {
            final JourneySnapshot? snapshot = JourneyService.instance.latest;
            // Show the full-card spinner only while the FIRST fetch is
            // in-flight. Once we have any snapshot, subsequent refreshes
            // happen in the background and the chart keeps rendering its
            // current data so the screen never blanks out.
            final bool firstLoad =
                JourneyService.instance.loading && snapshot == null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppTopNav(title: 'رحلتي', showBackButton: false),
                const SizedBox(height: AppSpacing.xxxl),
                Expanded(
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Pull-to-refresh that renders the brand AppLoader while
                      // refreshing (Cupertino control is the only native sliver
                      // that lets us swap in a custom indicator). No dim scrim —
                      // the chart stays visible behind the loader.
                      CupertinoSliverRefreshControl(
                        onRefresh: _onPullRefresh,
                        builder: (
                          context,
                          mode,
                          pulledExtent,
                          triggerExtent,
                          indicatorExtent,
                        ) {
                          final double opacity = mode ==
                                  RefreshIndicatorMode.inactive
                              ? 0
                              : (pulledExtent / triggerExtent).clamp(0.0, 1.0);
                          return Center(
                            child: Opacity(
                              opacity: opacity,
                              child: const AppLoader(size: 32),
                            ),
                          );
                        },
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xxl,
                          0,
                          AppSpacing.xxl,
                          AppSpacing.xl,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _StatsRow(stats: snapshot?.stats),
                              const SizedBox(height: AppSpacing.lg),
                              _MoodTrendsCard(
                                range: _range,
                                snapshot: snapshot,
                                loading: firstLoad,
                                onRangeChanged: (r) =>
                                    setState(() => _range = r),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _BalanceCard(range: _range, snapshot: snapshot),
                              const SizedBox(height: AppSpacing.xxl),
                              Text(
                                'ملامح رحلتي',
                                textAlign: TextAlign.right,
                                style: AppTextStyles.thmanyahHeading(context)
                                    .copyWith(fontSize: AppFontSizes.sm),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _HighlightsList(
                                highlights: snapshot?.highlights,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({this.stats});

  final JourneyStats? stats;

  @override
  Widget build(BuildContext context) {
    final s = stats;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            emoji: '🔥',
            emojiBg: context.forDark(
              AppPaletteButteryYellow.shade300,
              const Color(0xFF332700),
            ),
            value: (s?.currentStreak ?? 0).toString(),
            label: 'أيامك النشطة',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            emoji: '🧠',
            emojiBg: context.purpleSoftFill(AppPalettePurple.shade500),
            value: (s?.focusSessions30d ?? 0).toString(),
            label: 'جلسات تركيز',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            emoji: '🧩',
            emojiBg: context.forDark(
              AppInformationColors.shade50,
              AppInformationColors.shade950,
            ),
            value: (s?.activities30d ?? 0).toString(),
            label: 'أنشطة',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.emoji,
    required this.emojiBg,
    required this.value,
    required this.label,
  });

  final String emoji;
  final Color emojiBg;
  final String value;
  final String label;

  static const double _emojiCircleSize = 28;
  static const double _emojiGlyphSize = 17;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.shade200, width: 0.5),
        boxShadow: AppShadows.xs,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _emojiCircleSize,
              height: _emojiCircleSize,
              decoration: BoxDecoration(color: emojiBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: SizedBox(
                width: _emojiGlyphSize,
                height: _emojiGlyphSize,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    emoji,
                    textAlign: TextAlign.center,
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                    style: const TextStyle(
                      fontSize: 64,
                      height: 1.0,
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: Text(
                value,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.md,
                  fontWeight: AppFontWeights.bold,
                  color: context.colors.shade600,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              width: double.infinity,
              child: Text(
                label,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: AppFontFamily.title,
                  fontSize: AppFontSizes.xs,
                  fontWeight: AppFontWeights.medium,
                  color: context.colors.shade600,
                  height: 1.2,
                  fontFeatures: AppFontFamily.titleFeatures,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodTrendsCard extends StatelessWidget {
  const _MoodTrendsCard({
    required this.range,
    required this.onRangeChanged,
    required this.snapshot,
    required this.loading,
  });

  final _JourneyRange range;
  final ValueChanged<_JourneyRange> onRangeChanged;
  final JourneySnapshot? snapshot;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bool isMonth = range == _JourneyRange.month;
    return AppSectionCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'اتجاه مزاجك!',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.thmanyahHeading(context).copyWith(
                    fontSize: AppFontSizes.sm,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _TogglePill(
                label: 'الأسبوع',
                selected: range == _JourneyRange.week,
                onTap: () => onRangeChanged(_JourneyRange.week),
              ),
              const SizedBox(width: AppSpacing.xs),
              _TogglePill(
                label: 'الشهر',
                selected: range == _JourneyRange.month,
                onTap: () => onRangeChanged(_JourneyRange.month),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: _kMoodChartAreaHeight,
            child: isMonth
                ? const _MonthSection()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _WeekMoodChart(
                        weekly: snapshot?.weeklyTrend,
                        loading: loading,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double _pillWidth = 72;

  @override
  Widget build(BuildContext context) {
    final Color border = selected
        ? AppPalettePurple.shade300
        : context.colors.shade200;
    final Color textColor = selected
        ? AppPalettePurple.shade100
        : context.colors.shade500;
    final FontWeight weight = selected
        ? AppFontWeights.semibold
        : AppFontWeights.regular;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: _pillWidth,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: context.colors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: border, width: 0.5),
            boxShadow: AppShadows.elevation1,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            softWrap: false,
            maxLines: 1,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xs,
              fontWeight: weight,
              color: textColor,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekDay {
  const _WeekDay({required this.label, required this.mood, this.calm});
  final String label;
  final _Mood? mood;
  final int? calm;

  /// Tower height is driven by the day's calmness (calm_score 0–100), not the
  /// mood tier — the bar shows how calm the day was. Days with no check-in
  /// (`calm` null) collapse to a sliver: `0.05` keeps the bar visible above the
  /// min clamp (8px) in `_DayBar` while staying well below any real day.
  double get fraction => calm != null ? (calm! / 100.0) : 0.05;
}

class _WeekMoodChart extends StatelessWidget {
  const _WeekMoodChart({required this.weekly, required this.loading});

  final JourneyWeeklyTrend? weekly;
  final bool loading;

  static const double _chartHeight = 220;
  static const double _barWidth = 20;

  /// Build the 7-day series from the API response. Days the user didn't
  /// check in on come back with a null slug — we render those as `neutral`
  /// with `mood: null` so the bar collapses to the minimum height while the
  /// weekday label still appears beneath it.
  List<_WeekDay> _buildDays() {
    final w = weekly;
    if (w == null || w.days.isEmpty) {
      return const [];
    }
    return [
      for (final p in w.days)
        _WeekDay(
          label: _arabicWeekdayFromIso(p.date),
          mood: _moodFromSlug(p.slug),
          calm: p.calm,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final days = _buildDays();
    if (days.isEmpty) {
      return _EmptyWeekChart(loading: loading, height: _chartHeight);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _chartHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _DashedGridPainter(
                    topReserved: _kBadgeSize + 2,
                    color: context.colors.shade200,
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final d in days)
                      Expanded(
                        child: _DayBar(
                          day: d,
                          chartHeight: _chartHeight,
                          barWidth: _barWidth,
                          badgeSize: _kBadgeSize,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final d in days)
              Expanded(
                child: Text(
                  d.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.xxs,
                    fontWeight: AppFontWeights.medium,
                    color: context.colors.shade400,
                    height: 1.0,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Empty-state placeholder for the weekly mood chart.
///
/// Shows the same 7-day grid the loaded chart uses — dashed baseline,
/// 7 short neutral bars at the same baseline as a real bar's minimum
/// height, weekday labels, and a friendly Arabic prompt overlaid in the
/// middle. The visual scaffold tells the user "this is where your week
/// will show up" without leaving the card empty.
class _EmptyWeekChart extends StatelessWidget {
  const _EmptyWeekChart({required this.loading, required this.height});

  final bool loading;
  final double height;

  static const double _barWidth = 20;
  static const double _placeholderBarHeight = 14;
  static const List<String> _weekdayLabels = [
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _DashedGridPainter(
                    topReserved: _kBadgeSize + 2,
                    color: context.colors.shade200,
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < _weekdayLabels.length; i++)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: _barWidth,
                              height: _placeholderBarHeight,
                              decoration: BoxDecoration(
                                color: context.colors.shade100,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppRadius.sm),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: loading
                      ? const AppLoader(size: 32)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '✨',
                              style: TextStyle(fontSize: 28, height: 1.0),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'لا توجد حالات مزاجية مسجّلة هذا الأسبوع',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.thmanyahHeading(context).copyWith(
                                fontSize: AppFontSizes.xs,
                                color: context.colors.shade600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'سجّل مزاجك من الصفحة الرئيسية لتبدأ متابعة رحلتك المزاجية.',
                              textAlign: TextAlign.center,
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
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final l in _weekdayLabels)
              Expanded(
                child: Text(
                  l,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.xxs,
                    fontWeight: AppFontWeights.medium,
                    color: context.colors.shade400,
                    height: 1.0,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DashedGridPainter extends CustomPainter {
  const _DashedGridPainter({required this.topReserved, required this.color});

  final double topReserved;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const double dash = 2, gap = 3;

    final double baseline = size.height - 0.5;
    final double maxBarHeight = size.height - topReserved;
    const int moodLevels = 9;
    final List<double> ys = [
      baseline,
      for (int i = 1; i <= moodLevels; i++)
        size.height - maxBarHeight * i / moodLevels,
    ];

    for (final y in ys) {
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
        x += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedGridPainter oldDelegate) =>
      oldDelegate.topReserved != topReserved || oldDelegate.color != color;
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.day,
    required this.chartHeight,
    required this.barWidth,
    required this.badgeSize,
  });

  final _WeekDay day;
  final double chartHeight;
  final double barWidth;
  final double badgeSize;

  @override
  Widget build(BuildContext context) {
    final double maxBarHeight = chartHeight - badgeSize - 2;
    final double barHeight = (maxBarHeight * day.fraction).clamp(
      8.0,
      maxBarHeight,
    );
    final _Mood? mood = day.mood;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mood != null)
          _MoodBadge(mood: mood, size: badgeSize)
        else
          SizedBox(height: badgeSize),
        const SizedBox(height: AppSpacing.xxs),
        Container(
          width: barWidth,
          height: barHeight,
          decoration: BoxDecoration(
            // No check-in for the day: render a soft neutral sliver so the
            // gap is visible without implying a mood.
            color: mood != null ? mood.bar : context.colors.shade100,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sm),
            ),
          ),
        ),
      ],
    );
  }
}

class _MoodBadge extends StatelessWidget {
  const _MoodBadge({required this.mood, this.size = _kBadgeSize});

  final _Mood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    final double emojiBoxSize = size * 0.6;
    return Semantics(
      label: mood.label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: mood.bg,
          shape: BoxShape.circle,
          border: Border.all(color: mood.ring, width: 0.858),
          boxShadow: AppShadows.xs,
        ),
        alignment: Alignment.center,
        child: SizedBox(
          width: emojiBoxSize,
          height: emojiBoxSize,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(
              mood.emoji,
              textAlign: TextAlign.center,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
              style: const TextStyle(
                fontSize: 64,
                height: 1.0,
                leadingDistribution: TextLeadingDistribution.even,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthSection extends StatefulWidget {
  const _MonthSection();

  @override
  State<_MonthSection> createState() => _MonthSectionState();
}

class _MonthSectionState extends State<_MonthSection> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  // Per-month moods, fetched from /mood/calendar for whichever month is shown
  // (the journey snapshot only carries the current month). day-of-month → slug.
  Map<int, String> _slugs = const <int, String>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    setState(() => _loading = true);
    final Map<int, String> slugs =
        await MoodService.instance.monthCalendar(_selectedMonth);
    if (!mounted) return;
    setState(() {
      _slugs = slugs;
      _loading = false;
    });
  }

  static const Map<int, String> _arabicMonths = <int, String>{
    1: 'يناير',
    2: 'فبراير',
    3: 'مارس',
    4: 'أبريل',
    5: 'مايو',
    6: 'يونيو',
    7: 'يوليو',
    8: 'أغسطس',
    9: 'سبتمبر',
    10: 'أكتوبر',
    11: 'نوفمبر',
    12: 'ديسمبر',
  };

  String get _label =>
      '${_arabicMonths[_selectedMonth.month]} ${_selectedMonth.year}';

  /// First day of the month the user registered in — the picker can't go
  /// earlier than this (no months/years before the account existed). Null
  /// when the registration date isn't known yet, in which case the picker
  /// falls back to its default lower bound.
  DateTime? get _registeredMonth {
    final String? iso = AuthService.currentUser?.createdAt;
    if (iso == null) return null;
    final DateTime? dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    return DateTime(dt.year, dt.month);
  }

  Future<void> _pickMonth() async {
    DateTime temp = _selectedMonth;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return Container(
          height: 280,
          color: context.colors.white,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: context.colors.shade200,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        onPressed: () => Navigator.pop(sheetContext),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            fontFamily: AppFontFamily.text,
                            fontSize: AppFontSizes.xs,
                            color: context.colors.shade500,
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        onPressed: () {
                          setState(() => _selectedMonth = temp);
                          Navigator.pop(sheetContext);
                          _loadMonth();
                        },
                        child: const Text(
                          'تم',
                          style: TextStyle(
                            fontFamily: AppFontFamily.text,
                            fontSize: AppFontSizes.xs,
                            fontWeight: AppFontWeights.semibold,
                            color: AppPalettePurple.shade200,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.monthYear,
                    initialDateTime: _selectedMonth,
                    minimumDate: _registeredMonth,
                    minimumYear: _registeredMonth?.year ?? 2020,
                    maximumYear: 2035,
                    onDateTimeChanged: (DateTime newDate) {
                      temp = newDate;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _pickMonth,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: AppIconSize.sm,
                          color: context.colors.shade500,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          _label,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: AppFontFamily.text,
                            fontSize: AppFontSizes.xs,
                            fontWeight: AppFontWeights.medium,
                            color: context.colors.shade500,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Expanded(
          child: _MonthMoodGrid(
            selectedMonth: _selectedMonth,
            slugs: _slugs,
            loading: _loading,
          ),
        ),
      ],
    );
  }
}

class _MonthMoodGrid extends StatelessWidget {
  const _MonthMoodGrid({
    required this.selectedMonth,
    required this.slugs,
    this.loading = false,
  });

  final DateTime selectedMonth;

  /// day-of-month → mood slug for the selected month (from /mood/calendar).
  final Map<int, String> slugs;
  final bool loading;

  static const List<String> _dayLabels = [
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  static int _columnForWeekday(int weekday) => weekday % 7;

  @override
  Widget build(BuildContext context) {
    // A month later than the current one hasn't happened yet — show a gentle
    // "come back" state instead of an empty grid.
    final DateTime now = DateTime.now();
    final bool isFuture = selectedMonth.year > now.year ||
        (selectedMonth.year == now.year && selectedMonth.month > now.month);
    if (isFuture) {
      return const Center(child: _FutureMonthState());
    }

    // Only show the spinner on the very first load (no data yet); on month
    // switches we keep the previous grid until the new month arrives.
    if (loading && slugs.isEmpty) {
      return const Center(child: AppLoader(size: 32));
    }

    final int year = selectedMonth.year;
    final int month = selectedMonth.month;
    final int daysInMonth = DateTime(year, month + 1, 0).day;
    final int startCol = _columnForWeekday(DateTime(year, month, 1).weekday);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final l in _dayLabels)
              Expanded(
                child: Text(
                  l,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.xxs,
                    fontWeight: AppFontWeights.medium,
                    color: context.colors.shade400,
                    height: 1.0,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (int r = 0; r < 6; r++) ...[
          Row(
            children: [
              for (int c = 0; c < 7; c++)
                Expanded(
                  child: Center(
                    child: _MonthCell(
                      cellIndex: r * 7 + c,
                      startCol: startCol,
                      daysInMonth: daysInMonth,
                      slugs: slugs,
                    ),
                  ),
                ),
            ],
          ),
          if (r != 5) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.cellIndex,
    required this.startCol,
    required this.daysInMonth,
    required this.slugs,
  });

  final int cellIndex;
  final int startCol;
  final int daysInMonth;
  final Map<int, String> slugs;

  @override
  Widget build(BuildContext context) {
    final int dayNum = cellIndex - startCol + 1;
    final bool inMonth = dayNum >= 1 && dayNum <= daysInMonth;
    if (!inMonth) {
      return const SizedBox(width: _kMonthBadgeSize, height: _kMonthBadgeSize);
    }
    final _Mood? mood = _moodFromSlug(slugs[dayNum]);
    if (mood == null) {
      // Day inside the month but no check-in: empty placeholder dot so the
      // calendar grid keeps its rhythm without implying a mood.
      return Container(
        width: _kMonthBadgeSize,
        height: _kMonthBadgeSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: context.colors.shade200, width: 0.6),
        ),
      );
    }
    return _MoodBadge(mood: mood, size: _kMonthBadgeSize);
  }
}

/// Shown when the user browses to a month that hasn't arrived yet. Mirrors the
/// "اختر مهمة لجلستك" empty state (same face icon) with a warm "stay with us"
/// message rather than a blank calendar.
class _FutureMonthState extends StatelessWidget {
  const _FutureMonthState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            AppSvgIcons.focusEmptyFace,
            width: 32,
            height: 32,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'ما وصلنا لهذا التاريخ بعد',
            textAlign: TextAlign.center,
            style: AppTextStyles.thmanyahHeading(context).copyWith(
              fontSize: AppFontSizes.xs,
              color: context.colors.shade600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'خلّك معنا وسجّل مزاجك يوم بيوم.',
            textAlign: TextAlign.center,
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
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.range, required this.snapshot});

  final _JourneyRange range;
  final JourneySnapshot? snapshot;

  /// "تحسن بنسبة 12%" / "تراجع بنسبة 8%" / "بداية رحلتك". Delta is null when
  /// the previous-period window had no entries (cold start), and we surface
  /// that gracefully rather than printing 0%.
  String _deltaLabel(int? delta) {
    if (delta == null) return 'بداية رحلتك';
    if (delta == 0) return 'مستقر هذي الفترة';
    final magnitude = delta.abs();
    return delta > 0 ? 'تحسن بنسبة $magnitude%' : 'تراجع بنسبة $magnitude%';
  }

  @override
  Widget build(BuildContext context) {
    final bool isMonth = range == _JourneyRange.month;
    final String title = isMonth ? 'توازنك هذا الشهر' : 'توازنك هذا الأسبوع';
    final int balancePct = isMonth
        ? (snapshot?.monthlyGrid.balancePct ?? 0)
        : (snapshot?.weeklyTrend.balancePct ?? 0);
    final int? deltaPct = isMonth
        ? snapshot?.monthlyGrid.deltaPct
        : snapshot?.weeklyTrend.deltaPct;

    return AppSectionCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.thmanyahHeading(context).copyWith(
                    fontSize: AppFontSizes.sm,
                  ),
                ),
              ),
              Text(
                _deltaLabel(deltaPct),
                style: TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.xs,
                  fontWeight: AppFontWeights.regular,
                  color: context.colors.shade500,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _BalanceBar(progress: balancePct / 100.0),
        ],
      ),
    );
  }
}

class _BalanceBar extends StatelessWidget {
  const _BalanceBar({required this.progress});

  final double progress;
  static const double _height = 16;

  static const List<Color> _gradientColors = [
    AppPalettePurple.shade500,
    AppPalettePurple.shade400,
    AppPalettePurple.shade300,
    AppPalettePurple.shade200,
  ];

  Color get _percentColor {
    final double t = progress.clamp(0.0, 1.0);
    final double scaled = t * (_gradientColors.length - 1);
    final int idx = scaled.floor().clamp(0, _gradientColors.length - 2);
    final double frac = scaled - idx;
    return Color.lerp(_gradientColors[idx], _gradientColors[idx + 1], frac)!;
  }

  @override
  Widget build(BuildContext context) {
    final double clamped = progress.clamp(0.0, 1.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double fullWidth = constraints.maxWidth;
              return Container(
                height: _height,
                decoration: BoxDecoration(
                  color: context.colors.shade100,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SizedBox(
                    width: fullWidth * clamped,
                    height: _height,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: OverflowBox(
                        maxWidth: fullWidth,
                        minWidth: fullWidth,
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          width: fullWidth,
                          height: _height,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: AlignmentDirectional.centerStart,
                              end: AlignmentDirectional.centerEnd,
                              colors: _gradientColors,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '${(progress * 100).round()}%',
          style: TextStyle(
            fontFamily: AppFontFamily.text,
            fontSize: AppFontSizes.xs,
            fontWeight: AppFontWeights.bold,
            color: _percentColor,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _HighlightsList extends StatelessWidget {
  const _HighlightsList({this.highlights});

  final List<JourneyHighlight>? highlights;

  @override
  Widget build(BuildContext context) {
    final list = highlights ?? const <JourneyHighlight>[];
    if (list.isEmpty) {
      // Empty server response is rare (cold-start returns onboarding cards),
      // but render a minimal placeholder so the section never collapses.
      return const _HighlightRow(
        chip: 'ابدأ',
        title: 'سجّل أول حالة مزاجية لك في تطبيق مشكاة',
        emoji: '🌱',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < list.length; i++) ...[
          if (i != 0) const SizedBox(height: AppSpacing.md),
          _HighlightRow(
            chip: list[i].chip,
            title: list[i].title,
            emoji: list[i].emoji,
            onTap: _onTapFor(context, list[i].kind),
          ),
        ],
      ],
    );
  }

  VoidCallback? _onTapFor(BuildContext context, String kind) {
    if (kind.startsWith('onboarding_activity')) {
      return () => MainShell.jumpTo(context, MainShell.activitiesIndex);
    }
    if (kind.startsWith('onboarding_focus')) {
      return () {
        FocusIntentBus.instance.requestStart(openPicker: false);
        MainShell.jumpTo(context, MainShell.focusIndex);
      };
    }
    if (kind.startsWith('onboarding_checkin')) {
      return () => MainShell.jumpTo(context, MainShell.homeIndex);
    }
    return null; // peak_time / active_weekday / top_activity are informational
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({
    required this.chip,
    required this.title,
    required this.emoji,
    this.onTap,
  });

  final String chip;
  final String title;
  final String emoji;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget card = AppSectionCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AvatarCircle(emoji: emoji),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: AppFontFamily.title,
                fontSize: AppFontSizes.sm,
                fontWeight: AppFontWeights.medium,
                color: context.colors.shade600,
                height: 1.2,
                fontFeatures: AppFontFamily.titleFeatures,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _ChipTag(label: chip),
        ],
      ),
    );
    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.emoji});

  final String emoji;

  static const double _circleSize = 28;
  static const double _emojiSize = 17;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _circleSize,
      height: _circleSize,
      decoration: BoxDecoration(
        color: context.purpleSoftFill(AppPalettePurple.shade500),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 0),
            blurRadius: 6,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: _emojiSize,
        height: _emojiSize,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            emoji,
            textAlign: TextAlign.center,
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
            style: const TextStyle(
              fontSize: 64,
              height: 1.0,
              leadingDistribution: TextLeadingDistribution.even,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipTag extends StatelessWidget {
  const _ChipTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.purpleSoftFill(AppPalettePurple.shade600),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppPalettePurple.shade200, width: 0.5),
      ),
      child: Text(
        label,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          fontFamily: AppFontFamily.text,
          fontSize: AppFontSizes.xs,
          fontWeight: AppFontWeights.medium,
          color: AppPalettePurple.shade200,
          height: 1.2,
        ),
      ),
    );
  }
}
