import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../core/api/error_toast.dart';
import '../../core/focus/focus_service.dart';
import '../../core/focus/focus_session_api.dart';
import '../../core/journey/journey_service.dart';
import '../../core/tasks/task_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/nav/app_top_nav.dart';
import '../auth/success_screen.dart';

class FocusSessionScreen extends StatefulWidget {
  const FocusSessionScreen({
    super.key,
    this.taskId,
    required this.task,
    required this.durationMinutes,
  });

  static const String routeName = '/focus-session';

  final String? taskId; // null when the user picked "بدون مهمة"
  final String task; // label shown in the UI; '' when no task
  final int durationMinutes;

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen>
    with WidgetsBindingObserver {
  late final int _totalSeconds;
  late int _remainingSeconds;
  Timer? _ticker;
  String? _sessionId;
  bool _starting = true;
  bool _terminating = false;
  String? _startError;
  bool _isPaused = false;
  bool _isDialogOpen = false;

  /// Shows a dialog while guaranteeing only one is on screen at a time — a
  /// second trigger (e.g. system back while the pause dialog is open) closes
  /// the first instead of stacking.
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

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.durationMinutes * 60;
    _remainingSeconds = _totalSeconds;
    WidgetsBinding.instance.addObserver(this);
    _startSession();
  }

  Future<void> _startSession() async {
    try {
      final id = await FocusSessionApi.start(
        plannedDurationSeconds: _totalSeconds,
        taskId: widget.taskId,
      );
      if (!mounted) return;
      setState(() {
        _sessionId = id;
        _starting = false;
      });
      _startTicker();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _startError = 'ما قدرنا نبدأ الجلسة، جرّب مرة ثانية.';
      });
      // Show an error toast so the user gets explicit feedback, then pop
      // after a short delay so they read it.
      showApiErrorToast(
        context,
        e,
        fallback: 'ما قدرنا نبدأ الجلسة، جرّب مرة ثانية.',
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).maybePop();
      });
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) _remainingSeconds--;
      });
      if (_remainingSeconds == 0) {
        _ticker?.cancel();
        _ticker = null;
        _onSessionComplete();
      }
    });
  }

  Future<void> _onSessionComplete() async {
    if (_terminating) return;
    _terminating = true;
    final id = _sessionId;
    if (id != null) {
      try {
        await FocusSessionApi.complete(id);
      } catch (_) {
        // Best-effort — the success screen still shows so the user gets
        // their reward. A stale `active` row will be reaped by the
        // server-side cleanup job (out of scope here).
      }
    }
    // Optimistically refresh dependent caches.
    FocusService.instance.refresh();
    JourneyService.instance.refresh();
    if (widget.taskId != null && widget.taskId!.isNotEmpty) {
      // ignore: discarded_futures
      TaskService.instance.complete(widget.taskId!);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (sheetContext) => SuccessScreen(
          title: 'أحسنت',
          subtitle: 'أنهيت جلسة تركيز بنجاح  استمر .. أنت تبني عادة جميلة 💜',
          buttonLabel: 'العودة للتركيز',
          onContinue: () => Navigator.of(sheetContext).maybePop(),
        ),
      ),
    );
  }

  Future<void> _abandonIfRunning() async {
    if (_terminating) return;
    _terminating = true;
    _ticker?.cancel();
    _ticker = null;
    final id = _sessionId;
    if (id != null) {
      // Fire-and-forget: the user is leaving; we don't surface failures.
      // ignore: discarded_futures
      FocusSessionApi.abandon(id);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _abandonIfRunning();
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _abandonIfRunning();
    super.dispose();
  }

  double get _progress =>
      _totalSeconds == 0 ? 0 : 1 - (_remainingSeconds / _totalSeconds);

  String get _formattedTime {
    final int minutes = _remainingSeconds ~/ 60;
    final int seconds = _remainingSeconds % 60;
    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  void _pauseTimer() {
    if (_ticker == null) return;
    _ticker?.cancel();
    _ticker = null;
    setState(() => _isPaused = true);
  }

  void _resumeTimer() {
    if (_ticker != null) return;
    setState(() => _isPaused = false);
    _startTicker();
  }

  Future<void> _onPrimaryButtonTapped() async {
    if (_isPaused) {
      _resumeTimer();
      return;
    }
    _pauseTimer();
    final _PauseDialogResult? result =
        await _openExclusiveDialog<_PauseDialogResult>(
          (_) => const _PauseSessionDialog(),
        );
    if (!mounted) return;
    if (result == _PauseDialogResult.end) {
      // Stay in paused mode — UI updates via _isPaused flag.
      return;
    }
    _resumeTimer();
  }

  Future<void> _onEndSessionTapped() async {
    final bool wasPaused = _isPaused;
    _pauseTimer();
    final bool? confirmed = await _openExclusiveDialog<bool>(
      (_) => const _EndSessionDialog(),
    );
    if (!mounted) return;
    if (confirmed == true) {
      await _abandonIfRunning();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    if (!wasPaused) _resumeTimer();
  }

  @override
  Widget build(BuildContext context) {
    // The focus session is an immersive, intentionally-dark purple experience;
    // keep it identical in light and dark mode by pinning it to the light theme
    // so themed surfaces inside don't flip.
    return Theme(
      data: AppTheme.light,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final navigator = Navigator.of(context);
            await _abandonIfRunning();
            if (!mounted) return;
            navigator.maybePop();
          },
          child: Scaffold(
            body: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _isPaused
                      ? const [
                          AppPalettePurple.shade100,
                          AppPalettePurple.shade100,
                        ]
                      : const [
                          AppPalettePurple.shade200,
                          AppPalettePurple.shade300,
                        ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    AppTopNav(
                      title: 'جلسـة تركيز',
                      titleStyle: AppTextStyles.thmanyahDisplay(
                        context,
                      ).copyWith(color: AppNeutralColors.white),
                      onBack: _onEndSessionTapped,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xxl,
                          0,
                          AppSpacing.xxl,
                          AppSpacing.xxl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _BodyCard(
                                task: widget.task,
                                formattedTime: _formattedTime,
                                progress: _progress,
                                starting: _starting,
                                startError: _startError,
                                isPaused: _isPaused,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            _ActionButtons(
                              isPaused: _isPaused,
                              onPrimary: _onPrimaryButtonTapped,
                              onEndSession: _onEndSessionTapped,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BodyCard extends StatelessWidget {
  const _BodyCard({
    required this.task,
    required this.formattedTime,
    required this.progress,
    required this.starting,
    required this.startError,
    required this.isPaused,
  });

  final String task;
  final String formattedTime;
  final double progress;
  final bool starting;
  final String? startError;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      decoration: BoxDecoration(
        color: context.colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppPalettePurple.shade200, width: 0.5),
      ),
      child: startError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Text(
                  startError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.sm,
                    color: AppNeutralColors.white,
                    height: 1.4,
                  ),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GoalRow(task: task),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TimerSection(
                          formattedTime: starting ? '...' : formattedTime,
                          progress: progress,
                          isPaused: isPaused,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _MotivationalText(
                          text: isPaused
                              ? 'خذ نفس .. وارجع وقت ما تكون جاهز'
                              : 'ركّز الآن .. خطوة بسيطة تكفي',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.task});

  final String task;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppNeutralColors.white.withValues(alpha: 0.05),
            border: Border.all(color: AppNeutralColors.white, width: 0.5),
          ),
          child: const Text('📌', style: TextStyle(fontSize: 16, height: 1.0)),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              color: AppNeutralColors.white.withValues(alpha: 0.05),
              border: Border.all(color: AppNeutralColors.white, width: 0.5),
            ),
            child: Text(
              task,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.sm,
                fontWeight: AppFontWeights.medium,
                color: AppNeutralColors.white,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimerSection extends StatelessWidget {
  const _TimerSection({
    required this.formattedTime,
    required this.progress,
    required this.isPaused,
  });

  final String formattedTime;
  final double progress;
  final bool isPaused;

  static const double _outerSize = 210;
  static const double _ringSize = 195;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: _outerSize,
        height: _outerSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: _outerSize,
              height: _outerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.white,
              ),
            ),
            SizedBox(
              width: _ringSize,
              height: _ringSize,
              child: CustomPaint(painter: _RingPainter(progress: progress)),
            ),
            // One combined, non-live label so a screen reader reads
            // "وقت التركيز، المتبقّي MM:SS" only when focused — not on every
            // per-second tick.
            Semantics(
              label:
                  '${isPaused ? 'إيقاف مؤقت' : 'وقت التركيز'}، المتبقّي $formattedTime',
              child: ExcludeSemantics(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formattedTime,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFontFamily.text,
                      fontSize: AppFontSizes.xl,
                      fontWeight: AppFontWeights.regular,
                      color: context.colors.shade700,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isPaused ? 'إيقاف مؤقت' : 'وقت التركيز',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFontFamily.text,
                      fontSize: AppFontSizes.xs,
                      fontWeight: AppFontWeights.regular,
                      color: context.colors.shade400,
                      height: 1.0,
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

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  static const double _strokeWidth = 14;

  static const List<Color> _gradientColors = [
    AppPalettePurple.shade400,
    AppPalettePurple.shade300,
    AppPalettePurple.shade200,
    AppPalettePurple.shade100,
    AppPalettePurple.shade400,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - _strokeWidth / 2;
    final Rect ringRect = Rect.fromCircle(center: center, radius: radius);

    final Paint track = Paint()
      ..color = AppNeutralColors.shade200
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, track);

    if (progress > 0) {
      final double sweep = progress.clamp(0.0, 1.0) * math.pi * 2;
      final Paint arcPaint = Paint()
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: math.pi * 2,
          colors: _gradientColors,
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(ringRect)
        ..strokeWidth = _strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(ringRect, -math.pi / 2, sweep, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

class _MotivationalText extends StatelessWidget {
  const _MotivationalText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: AppFontFamily.text,
        fontSize: AppFontSizes.xxs,
        fontWeight: AppFontWeights.medium,
        color: AppNeutralColors.white,
        height: 1.2,
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isPaused,
    required this.onPrimary,
    required this.onEndSession,
  });

  final bool isPaused;
  final VoidCallback onPrimary;
  final VoidCallback onEndSession;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PrimaryWhiteButton(
            label: isPaused ? 'متابعة' : 'إيقاف مؤقت',
            icon: isPaused ? const _PlayIcon() : const _PauseIcon(),
            onTap: onPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SecondaryWhiteButton(
            label: 'إنهاء الجلسة',
            onTap: onEndSession,
          ),
        ),
      ],
    );
  }
}

class _PlayIcon extends StatelessWidget {
  const _PlayIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(AppSvgIcons.focusPlay, width: 24, height: 24);
  }
}

class _PauseIcon extends StatelessWidget {
  const _PauseIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(AppSvgIcons.focusPause, width: 24, height: 24);
  }
}

class _PrimaryWhiteButton extends StatelessWidget {
  const _PrimaryWhiteButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: label,
        child: SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: radius,
          boxShadow: AppShadows.sm,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: ExcludeSemantics(
                child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: AppFontFamily.text,
                      fontSize: AppFontSizes.sm,
                      fontWeight: AppFontWeights.bold,
                      color: AppPalettePurple.shade200,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  icon,
                ],
              ),
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

class _SecondaryWhiteButton extends StatelessWidget {
  const _SecondaryWhiteButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: label,
        child: SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: AppNeutralColors.white, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: Center(
                child: ExcludeSemantics(
                  child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.sm,
                    fontWeight: AppFontWeights.bold,
                    color: AppNeutralColors.white,
                    height: 1.2,
                  ),
                ),
                ),
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

enum _PauseDialogResult { resume, end }

class _PauseSessionDialog extends StatelessWidget {
  const _PauseSessionDialog();

  static const double _iconSize = 80;

  @override
  Widget build(BuildContext context) {
    return _ConfirmationDialog(
      icon: SvgPicture.asset(
        AppSvgIcons.focusPauseModal,
        width: _iconSize,
        height: _iconSize,
      ),
      title: 'وقّفت الجلسة مؤقتًا',
      description:
          'وقتك محفوظ والجلسة بانتظارك،\n'
          'خذ نفس وارجع وقت ما تكون جاهز.',
      primaryButton: _DialogPrimaryButton(
        label: 'إيقاف الجلسة',
        onTap: () => Navigator.of(context).pop(_PauseDialogResult.end),
      ),
      secondaryButton: _DialogSecondaryButton(
        label: 'متابعة الجلسة',
        onTap: () => Navigator.of(context).pop(_PauseDialogResult.resume),
      ),
    );
  }
}

class _EndSessionDialog extends StatelessWidget {
  const _EndSessionDialog();

  static const double _iconSize = 80;

  @override
  Widget build(BuildContext context) {
    return _ConfirmationDialog(
      icon: SvgPicture.asset(
        AppSvgIcons.focusEndSessionModal,
        width: _iconSize,
        height: _iconSize,
      ),
      title: 'تبي تنهي جلستك؟',
      description:
          'لو أنهيت الحين ما تنحسب جلستك،\n'
          'وتقدر تبدأ من جديد وقت ما تجهز.',
      primaryButton: _DialogPrimaryButton(
        label: 'إنهاء الجلسة',
        backgroundColor: AppDangerColors.shade500,
        onTap: () => Navigator.of(context).pop(true),
      ),
      secondaryButton: _DialogSecondaryButton(
        label: 'العودة للجلسة',
        borderColor: AppNeutralColors.shade300,
        textColor: AppNeutralColors.shade400,
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
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: label,
        child: Material(
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
          child: ExcludeSemantics(
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
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: label,
        child: Material(
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
          child: ExcludeSemantics(
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
      ),
    ),
      ),
    );
  }
}
