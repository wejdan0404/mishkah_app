import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../core/activities/activity_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/nav/app_top_nav.dart';

enum BreathPhaseType { inhale, holdFull, exhale, holdEmpty }

class BreathPhase {
  const BreathPhase(this.type, this.seconds);

  final BreathPhaseType type;
  final int seconds;

  String get label => switch (type) {
        BreathPhaseType.inhale => 'شهيق',
        BreathPhaseType.exhale => 'زفير',
        BreathPhaseType.holdFull || BreathPhaseType.holdEmpty => 'احبس',
      };

  String get hint => switch (type) {
        BreathPhaseType.inhale => 'خذ نفس بهدوء',
        BreathPhaseType.exhale => 'أخرج الهواء ببطء',
        BreathPhaseType.holdFull => 'امسك نفسك بلطف',
        BreathPhaseType.holdEmpty => 'اهدأ قبل الشهيق',
      };
}

/// Colour set for the breathing orb. Each exercise carries its own so the
/// circle reads differently per exercise while the rest of the chrome
/// (buttons, modals) stays on the app's purple accent.
class BreathOrbPalette {
  const BreathOrbPalette({
    required this.orb,
    required this.midHalo,
    required this.outerHalo,
    required this.orbPaused,
    required this.midHaloPaused,
    required this.outerHaloPaused,
    required this.hint,
    required this.number,
    required this.orbDark,
    required this.midHaloDark,
    required this.outerHaloDark,
    required this.orbPausedDark,
    required this.midHaloPausedDark,
    required this.outerHaloPausedDark,
  });

  final Color orb;
  final Color midHalo;
  final Color outerHalo;
  final Color orbPaused;
  final Color midHaloPaused;
  final Color outerHaloPaused;
  final Color hint;
  final Color number;

  // Dark-mode counterparts — explicit palette shades so the layered glow
  // reads correctly on a dark background without HSL computation.
  final Color orbDark;
  final Color midHaloDark;
  final Color outerHaloDark;
  final Color orbPausedDark;
  final Color midHaloPausedDark;
  final Color outerHaloPausedDark;

  static const BreathOrbPalette blue = BreathOrbPalette(
    orb: AppInformationColors.shade300,
    midHalo: AppInformationColors.shade100,
    outerHalo: AppInformationColors.shade50,
    orbPaused: AppInformationColors.shade500,
    midHaloPaused: AppInformationColors.shade200,
    outerHaloPaused: AppInformationColors.shade100,
    hint: AppInformationColors.shade400,
    number: AppNeutralColors.white,
    orbDark: AppInformationColors.shade700,
    midHaloDark: AppInformationColors.shade800,
    outerHaloDark: AppInformationColors.shade900,
    orbPausedDark: AppInformationColors.shade800,
    midHaloPausedDark: AppInformationColors.shade900,
    outerHaloPausedDark: AppInformationColors.shade950,
  );

  static const BreathOrbPalette yellow = BreathOrbPalette(
    orb: AppWarningColors.shade300,
    midHalo: AppWarningColors.shade200,
    outerHalo: AppWarningColors.shade100,
    orbPaused: AppWarningColors.shade400,
    midHaloPaused: AppWarningColors.shade300,
    outerHaloPaused: AppWarningColors.shade200,
    hint: AppWarningColors.shade500,
    number: AppNeutralColors.shade700,
    orbDark: AppWarningColors.shade700,
    midHaloDark: AppWarningColors.shade800,
    outerHaloDark: AppWarningColors.shade900,
    orbPausedDark: AppWarningColors.shade800,
    midHaloPausedDark: AppWarningColors.shade900,
    outerHaloPausedDark: AppWarningColors.shade950,
  );

  // AppPalettePurple is INVERTED: shade100 is darkest, shade600 is lightest.
  static const BreathOrbPalette purple = BreathOrbPalette(
    orb: AppPalettePurple.shade200,
    midHalo: AppPalettePurple.shade400,
    outerHalo: AppPalettePurple.shade500,
    orbPaused: AppPalettePurple.shade100,
    midHaloPaused: AppPalettePurple.shade300,
    outerHaloPaused: AppPalettePurple.shade400,
    hint: AppPalettePurple.shade100,
    number: AppNeutralColors.white,
    orbDark: AppPalettePurple.shade100,
    midHaloDark: Color(0xFF292640),
    outerHaloDark: Color(0xFF1F1A33),
    orbPausedDark: AppPalettePurple.shade100,
    midHaloPausedDark: Color(0xFF292640),
    outerHaloPausedDark: Color(0xFF1F1A33),
  );
}

class BreathingExercise {
  const BreathingExercise({
    required this.slug,
    required this.title,
    required this.phases,
    required this.totalRounds,
    required this.cyclesPerRound,
    required this.palette,
  });

  final String slug;
  final String title;
  final List<BreathPhase> phases;
  final int totalRounds;
  final int cyclesPerRound;
  final BreathOrbPalette palette;

  // 4-6 · 2:40 · سهل → 4 displayed rounds × 4 cycles × 10s = 160s = 2:40.
  // 16 internal breathing cycles are grouped into 4 user-facing rounds, so the
  // counter shows "الجولة 1 من 4" (NOT 16).
  static const BreathingExercise breatheCalmly = BreathingExercise(
    slug: ActivitySlugs.breatheCalmly,
    title: 'تنفّس بهدوء',
    phases: [
      BreathPhase(BreathPhaseType.inhale, 4),
      BreathPhase(BreathPhaseType.exhale, 6),
    ],
    totalRounds: 4,
    cyclesPerRound: 4,
    palette: BreathOrbPalette.blue,
  );

  // 4-4-4-4 · 1:04 · متوسط → 4 rounds × 1 cycle × 16s = 64s.
  static const BreathingExercise stopSpiral = BreathingExercise(
    slug: ActivitySlugs.stopSpiral,
    title: 'وقف الدوامة',
    phases: [
      BreathPhase(BreathPhaseType.inhale, 4),
      BreathPhase(BreathPhaseType.holdFull, 4),
      BreathPhase(BreathPhaseType.exhale, 4),
      BreathPhase(BreathPhaseType.holdEmpty, 4),
    ],
    totalRounds: 4,
    cyclesPerRound: 1,
    palette: BreathOrbPalette.blue,
  );

  // 4-2-6 · 0:48 · متوسط → 4 rounds × 1 cycle × 12s = 48s.
  static const BreathingExercise releasePressure = BreathingExercise(
    slug: ActivitySlugs.releasePressure,
    title: 'أطفئ الضغط',
    phases: [
      BreathPhase(BreathPhaseType.inhale, 4),
      BreathPhase(BreathPhaseType.holdFull, 2),
      BreathPhase(BreathPhaseType.exhale, 6),
    ],
    totalRounds: 4,
    cyclesPerRound: 1,
    palette: BreathOrbPalette.yellow,
  );

  // 4-7-8 · 0:57 · متقدم → 3 rounds × 1 cycle × 19s = 57s.
  static const BreathingExercise sleepCalm = BreathingExercise(
    slug: ActivitySlugs.sleepCalm,
    title: 'نام بهدوء',
    phases: [
      BreathPhase(BreathPhaseType.inhale, 4),
      BreathPhase(BreathPhaseType.holdFull, 7),
      BreathPhase(BreathPhaseType.exhale, 8),
    ],
    totalRounds: 3,
    cyclesPerRound: 1,
    palette: BreathOrbPalette.purple,
  );
}

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key, required this.exercise});

  final BreathingExercise exercise;

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _round = 1;
  int _cycle = 1;
  int _phaseIndex = 0;
  bool _isPaused = false;
  bool _isDialogOpen = false;
  bool _recorded = false;

  // Fully-completed DISPLAYED rounds so far (for the summary's "الجولات X من Y").
  int _completedRounds = 0;
  // Active breathing time (excludes paused time) → the summary's "المدة".
  final Stopwatch _stopwatch = Stopwatch();

  BreathPhase get _phase => widget.exercise.phases[_phaseIndex];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _phase.seconds),
    )..addStatusListener(_onStatus);
    _controller.forward(from: 0);
    _stopwatch.start();
    ActivityApi.start(widget.exercise.slug);
  }

  @override
  void dispose() {
    if (!_recorded) {
      ActivityApi.abandon(widget.exercise.slug);
    }
    _controller.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    final BreathingExercise exercise = widget.exercise;
    if (_phaseIndex < exercise.phases.length - 1) {
      setState(() => _phaseIndex++);
      _startPhase();
    } else if (_cycle < exercise.cyclesPerRound) {
      setState(() {
        _cycle++;
        _phaseIndex = 0;
      });
      _startPhase();
    } else if (_round < exercise.totalRounds) {
      setState(() {
        _completedRounds++; // a full displayed round just finished
        _round++;
        _cycle = 1;
        _phaseIndex = 0;
      });
      _startPhase();
    } else {
      _completedRounds++; // the final displayed round just finished
      _onComplete();
    }
  }

  void _startPhase() {
    _controller.duration = Duration(seconds: _phase.seconds);
    _controller.forward(from: 0);
  }

  Future<T?> _openExclusiveDialog<T>(WidgetBuilder builder) async {
    if (_isDialogOpen && mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    _isDialogOpen = true;
    try {
      return await showDialog<T>(
        context: context,
        barrierColor: Colors.black54,
        builder: builder,
      );
    } finally {
      _isDialogOpen = false;
    }
  }

  void _pause() {
    if (_isPaused) return;
    _controller.stop();
    _stopwatch.stop();
    setState(() => _isPaused = true);
  }

  void _resume() {
    if (!_isPaused) return;
    setState(() => _isPaused = false);
    _stopwatch.start();
    _controller.forward();
  }

  Future<void> _onPrimaryButtonTapped() async {
    if (_isPaused) {
      _resume();
      return;
    }
    _pause();
    final _PauseDialogResult? result =
        await _openExclusiveDialog<_PauseDialogResult>(
      (_) => const _PauseExerciseDialog(),
    );
    if (!mounted) return;
    if (result == _PauseDialogResult.end) {
      // Stay paused — the user can resume via the "متابعة" button.
      return;
    }
    _resume();
  }

  Future<void> _onEndExercise() async {
    final bool wasPaused = _isPaused;
    _pause();
    final bool? confirmed = await _openExclusiveDialog<bool>(
      (_) => const _EndExerciseDialog(),
    );
    if (!mounted) return;
    if (confirmed == true) {
      // The session started, so ending counts as a completion: record it once
      // and show the summary with the rounds finished + elapsed time.
      _stopwatch.stop();
      if (!_recorded) {
        _recorded = true;
        ActivityApi.complete(
          widget.exercise.slug,
          result: <String, dynamic>{
            'rounds_completed': _completedRounds,
            'cycles_completed':
                _completedRounds * widget.exercise.cyclesPerRound,
          },
        );
      }
      _showSummary();
      return;
    }
    if (!wasPaused) _resume();
  }

  void _onComplete() {
    _recorded = true;
    _stopwatch.stop();
    ActivityApi.complete(
      widget.exercise.slug,
      result: <String, dynamic>{
        'rounds_completed': widget.exercise.totalRounds,
        'cycles_completed':
            widget.exercise.totalRounds * widget.exercise.cyclesPerRound,
      },
    );
    _showSummary();
  }

  /// Pushes the calm completion summary (replacing the session). "العودة
  /// للأنشطة" pops back to the Balance Station if it's in the stack, else root.
  void _showSummary() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => _BreathingSummaryScreen(
          completedRounds: _completedRounds,
          totalRounds: widget.exercise.totalRounds,
          duration: _formatDuration(_stopwatch.elapsed),
        ),
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final int minutes = d.inMinutes;
    final String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final BreathingExercise exercise = widget.exercise;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _onEndExercise();
        },
        child: Scaffold(
          backgroundColor: context.colors.shade50,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTopNav(title: exercise.title, onBack: _onEndExercise),
                Expanded(
                  child: Column(
                    children: [
                      const Spacer(),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.shade200,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Text(
                            'الجولة $_round من ${exercise.totalRounds}',
                            style: TextStyle(
                              fontFamily: AppFontFamily.text,
                              fontSize: AppFontSizes.xs,
                              fontWeight: AppFontWeights.semibold,
                              color: context.colors.shade600,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxxl),
                      _BreathOrb(
                        animation: _controller,
                        phase: _phase,
                        isPaused: _isPaused,
                        palette: exercise.palette,
                      ),
                      const SizedBox(height: AppSpacing.xxxxl),
                      Text(
                        _phase.label,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.thmanyahHeading(context).copyWith(
                          color: context.colors.shade600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _phase.hint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppFontFamily.text,
                          fontSize: AppFontSizes.xs,
                          fontWeight: AppFontWeights.regular,
                          color: exercise.palette.hint,
                          height: 1.4,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    0,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: _isPaused ? 'متابعة' : 'إيقاف مؤقت',
                          expand: true,
                          onPressed: _onPrimaryButtonTapped,
                          trailing: SvgPicture.asset(
                            _isPaused
                                ? AppSvgIcons.focusPlay
                                : AppSvgIcons.focusPause,
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
                      Expanded(child: _EndButton(onTap: _onEndExercise)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BreathOrb extends StatelessWidget {
  const _BreathOrb({
    required this.animation,
    required this.phase,
    required this.isPaused,
    required this.palette,
  });

  final Animation<double> animation;
  final BreathPhase phase;
  final bool isPaused;
  final BreathOrbPalette palette;

  static const double _stage = 300;
  static const double _haloOuter = 280;
  static const double _haloMid = 210;
  static const double _orbMin = 88;
  static const double _orbMax = 232;

  double _breathTarget(double curved) {
    switch (phase.type) {
      case BreathPhaseType.inhale:
        return curved;
      case BreathPhaseType.exhale:
        return 1 - curved;
      case BreathPhaseType.holdFull:
        return 1;
      case BreathPhaseType.holdEmpty:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final double curved = Curves.easeInOut.transform(animation.value);
        final double breathT = _breathTarget(curved);
        final double diameter = _orbMin + (_orbMax - _orbMin) * breathT;
        final int count =
            (phase.seconds - (animation.value * phase.seconds).floor())
                .clamp(1, phase.seconds);

        final Color orbColor = context.forDark(
          isPaused ? palette.orbPaused : palette.orb,
          isPaused ? palette.orbPausedDark : palette.orbDark,
        );
        final Color midHaloColor = context.forDark(
          isPaused ? palette.midHaloPaused : palette.midHalo,
          isPaused ? palette.midHaloPausedDark : palette.midHaloDark,
        );
        final Color outerHaloColor = context.forDark(
          isPaused ? palette.outerHaloPaused : palette.outerHalo,
          isPaused ? palette.outerHaloPausedDark : palette.outerHaloDark,
        );
        // In dark mode the orb is now deep/dark, so a dark number colour
        // (e.g. yellow palette uses shade700) would be invisible.  Flip it to
        // white.  For palettes that already use white the forDark call is a
        // no-op in both modes.
        final Color numberColor = context.forDark(
          palette.number,
          AppNeutralColors.white,
        );

        return SizedBox(
          width: _stage,
          height: _stage,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _haloCircle(_haloOuter, outerHaloColor),
              _haloCircle(_haloMid, midHaloColor),
              Container(
                width: diameter,
                height: diameter,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: orbColor,
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: 44,
                    fontWeight: AppFontWeights.bold,
                    color: numberColor,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _haloCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _EndButton extends StatelessWidget {
  const _EndButton({required this.onTap});

  final VoidCallback onTap;

  static const double _height = 44;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return SizedBox(
      height: _height,
      child: Material(
        color: context.colors.white,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: AppPalettePurple.shade200, width: 1),
            ),
            child: const Text(
              'إنهاء التمرين',
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
    );
  }
}

enum _PauseDialogResult { resume, end }

class _PauseExerciseDialog extends StatelessWidget {
  const _PauseExerciseDialog();

  static const double _iconSize = 80;

  @override
  Widget build(BuildContext context) {
    return _ConfirmationDialog(
      icon: SvgPicture.asset(
        AppSvgIcons.focusPauseModal,
        width: _iconSize,
        height: _iconSize,
      ),
      title: 'وقّفت التنفّس مؤقتًا',
      description: 'خذ وقتك، وارجع لتنفّسك وقت ما تكون جاهز',
      primaryButton: _DialogPrimaryButton(
        label: 'إيقاف التمرين',
        onTap: () => Navigator.of(context).pop(_PauseDialogResult.end),
      ),
      secondaryButton: _DialogSecondaryButton(
        label: 'متابعة التنفّس',
        onTap: () => Navigator.of(context).pop(_PauseDialogResult.resume),
      ),
    );
  }
}

class _EndExerciseDialog extends StatelessWidget {
  const _EndExerciseDialog();

  static const double _iconSize = 80;

  @override
  Widget build(BuildContext context) {
    return _ConfirmationDialog(
      icon: SvgPicture.asset(
        AppSvgIcons.focusEndSessionModal,
        width: _iconSize,
        height: _iconSize,
      ),
      title: 'تبي تنهي تمرينك؟',
      description: 'لو طلعت الحين يبدأ تقدّمك من جديد،\nوتقدر ترجع له وقت ما تكون جاهز.',
      primaryButton: _DialogPrimaryButton(
        label: 'إنهاء التمرين',
        backgroundColor: AppDangerColors.shade500,
        onTap: () => Navigator.of(context).pop(true),
      ),
      secondaryButton: _DialogSecondaryButton(
        label: 'العودة للتمرين',
        borderColor: context.colors.shade300,
        textColor: context.colors.shade400,
        onTap: () => Navigator.of(context).pop(false),
      ),
    );
  }
}

/// "قبل ما تبدأ" priming popup, shown once before a breathing session starts.
/// Returns true when the user taps "أنا جاهز"; false/null on "رجوع" or dismiss.
/// It only gates navigation — it never starts the timer, skips a phase, or
/// records completion.
Future<bool?> showBeforeYouStartDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => const _BeforeYouStartDialog(),
  );
}

class _BeforeYouStartDialog extends StatelessWidget {
  const _BeforeYouStartDialog();

  static const double _iconSize = 80;

  @override
  Widget build(BuildContext context) {
    return _ConfirmationDialog(
      icon: SvgPicture.asset(
        AppSvgIcons.activitiesTimer,
        width: _iconSize,
        height: _iconSize,
      ),
      title: 'قبل ما تبدأ',
      description: 'خذ وضعية مريحة، وخلّ كتفك يرتاح. نبدأ بهدوء.',
      primaryButton: _DialogPrimaryButton(
        label: 'أنا جاهز',
        onTap: () => Navigator.of(context).pop(true),
      ),
      secondaryButton: _DialogSecondaryButton(
        label: 'رجوع',
        borderColor: context.colors.shade300,
        textColor: context.colors.shade400,
        onTap: () => Navigator.of(context).pop(false),
      ),
    );
  }
}

class _ConfirmationDialog extends StatelessWidget {
  const _ConfirmationDialog({
    required this.icon,
    required this.title,
    required this.description,
    required this.primaryButton,
    required this.secondaryButton,
  });

  final Widget icon;
  final String title;
  final String description;
  final Widget primaryButton;
  final Widget secondaryButton;

  static const double _width = 325;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: _width,
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
                Center(child: icon),
                const SizedBox(height: AppSpacing.xxxl),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.thmanyahHeading(context).copyWith(
                    fontSize: AppFontSizes.sm,
                    color: context.colors.shade600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.xxs,
                    fontWeight: AppFontWeights.regular,
                    color: context.colors.shade500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Row(
                  children: [
                    Expanded(child: primaryButton),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: secondaryButton),
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

class _DialogPrimaryButton extends StatelessWidget {
  const _DialogPrimaryButton({
    required this.label,
    required this.onTap,
    this.backgroundColor = AppPalettePurple.shade200,
  });

  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: backgroundColor,
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
            boxShadow: AppShadows.xs,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xs,
              fontWeight: AppFontWeights.semibold,
              color: AppNeutralColors.white,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogSecondaryButton extends StatelessWidget {
  const _DialogSecondaryButton({
    required this.label,
    required this.onTap,
    this.borderColor = AppPalettePurple.shade200,
    this.textColor = AppPalettePurple.shade200,
  });

  final String label;
  final VoidCallback onTap;
  final Color borderColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: context.colors.white,
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
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xs,
              fontWeight: AppFontWeights.semibold,
              color: textColor,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Calm summary shown when a breathing session completes, or when the user ends
/// it after starting. "العودة للأنشطة" returns to the Balance Station (the area
/// the exercise launched from), falling back to the root if it isn't in stack.
class _BreathingSummaryScreen extends StatelessWidget {
  const _BreathingSummaryScreen({
    required this.completedRounds,
    required this.totalRounds,
    required this.duration,
  });

  final int completedRounds;
  final int totalRounds;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.shade50,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.00, 0.07, 0.15, 0.26],
              colors: [
                AppPaletteButteryYellow.shade200,
                AppPaletteButteryYellow.shade200.withValues(alpha: 0.55),
                AppPaletteButteryYellow.shade200.withValues(alpha: 0.22),
                AppPaletteButteryYellow.shade200.withValues(alpha: 0.0),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xxl,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppSuccessColors.shade400,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 44,
                              color: AppNeutralColors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxxl),
                          Text(
                            'أحسنت',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.thmanyahTitle(context),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'أنهيت تمرين التنفّس بهدوء.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppFontFamily.text,
                              fontSize: AppFontSizes.xs,
                              fontWeight: AppFontWeights.regular,
                              color: context.colors.shade500,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxxl),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _StatBox(
                                label: 'الجولات',
                                value: '$completedRounds من $totalRounds',
                              ),
                              const SizedBox(width: AppSpacing.md),
                              _StatBox(label: 'المدة', value: duration),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppButton(
                    label: 'العودة للأنشطة',
                    expand: true,
                    trailing: SvgPicture.asset(
                      AppSvgIcons.arrowLeft,
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        AppNeutralColors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).popUntil(
                      (route) =>
                          route.settings.name ==
                              ActivityCategoryRoutes.balanceStation ||
                          route.isFirst,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.shade200, width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xxs,
              fontWeight: AppFontWeights.regular,
              color: context.colors.shade500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.sm,
              fontWeight: AppFontWeights.bold,
              color: context.colors.shade700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
