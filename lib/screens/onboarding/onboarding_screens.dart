import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../constants/app_icons.dart';
import '../../constants/app_play_images.dart';
import '../../core/permissions/permission_flow.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/cards/app_section_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const double _objectStackWidth = 186;
  static const double _objectStackHeight = 170;
  static const double _mainCardWidth = 150;
  static const double _mainCardHeight = 170;
  static const double _mainCardIconSize = 76;
  static const double _rightBadgeTop = 63;
  static const double _rightBadgeRight = -5;
  static const double _leftBadgeTop = 118;
  static const double _leftBadgeLeft = -8;
  static const double _textBlockHeight = 220;
  static const double _ctaButtonHeight = 48;
  static const Size _skipButtonMinSize = Size(48, 44);

  /// Step that swaps the logo card for the live mood-logging preview.
  static const int _moodPreviewIndex = 1;

  /// Step that swaps the logo card for the static "فعّل حواسك" activity card.
  static const int _activityPreviewIndex = 2;

  /// Step that swaps the logo for the "متحمس" mood image (🤖/🗣️ badges).
  static const int _companionPreviewIndex = 3;
  // Sized so the visible character is at least as large as the step-1 logo
  // card (150×170); the PNG carries transparent margins, so it runs bigger.
  static const double _companionVisualWidth = 250;
  static const double _companionVisualHeight = 235;
  static const double _companionImageHeight = 230;
  static const double _companionBadgeInset = 12;

  /// Edge insets for the two mood-preview badges: 🤩 from the top-right, 🤔
  /// from the bottom-left.
  static const double _moodBadgeTopInset = 40;
  static const double _moodBadgeBottomInset = 75;

  /// Activity step badges: equal inset, 🧩 top-left and 🌬 bottom-right.
  static const double _activityBadgeInset = 28;

  /// Final mic step: lavender orb sized so its core ≈ the logo card, ringed by
  /// soft halos. Badges 🗣️ top-right / 🎙️ bottom-left.
  static const double _voiceOrbWidth = 230;
  static const double _voiceBadgeInset = 24;

  late final AnimationController _objectController;
  late final AnimationController _textController;

  late final Animation<double> _mainObjectOpacity;
  late final Animation<Offset> _mainObjectSlide;

  late final Animation<double> _rightBadgeOpacity;
  late final Animation<Offset> _rightBadgeSlide;

  late final Animation<double> _leftBadgeOpacity;
  late final Animation<Offset> _leftBadgeSlide;

  int _currentTextIndex = 0;

  /// On the final step the CTA primes mic access first; once the user has gone
  /// through the system prompt it flips to the "ابدأ الآن" enter-app action.
  bool _micRequested = false;

  static const List<OnboardingTextData> _texts = [
    OnboardingTextData(
      emoji: '👋',
      title: 'مرحبًـا بـك في مِشْكَـاة 👋',
      description:
          'مِشْكَاة تعني المكان اللي يطلع منه النور، وهنا مساحتك ترتّب أفكارك وتهدّي بالك.',
    ),
    OnboardingTextData(
      emoji: '🫧',
      title: 'تعـرّف على شعـورك بسهولـة!',
      description: 'تسجيل سريع لمشاعرك يساعدك تفهم نفسك وتتابع تغيّر مزاجك.',
    ),
    OnboardingTextData(
      emoji: '🧩',
      title: 'خطواتـك نحـو التـوازن!',
      description:
          'تمارين تنفّس، وألعاب خفيفة تساعدك تخفف التوتر وترجّع تركيزك.',
    ),
    OnboardingTextData(
      emoji: '🤖',
      title: 'مرافقـك يدعمـك!',
      description: 'يسمعك، يرتّب أفكارك، ويعطيك خطوات عملية تساعدك طوال اليوم.',
    ),
    OnboardingTextData(
      emoji: '🎙️',
      title: 'صوتك يسهّل وصولك!',
      description:
          'اسمح بالوصول للميكروفون عشان تعبّر بصوتك بسهولة، ومرافقك يساعدك بطريقة أريح وتدعم إمكانية الوصول.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _objectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _mainObjectOpacity = CurvedAnimation(
      parent: _objectController,
      curve: const Interval(0.00, 0.45, curve: Curves.easeOut),
    );

    _mainObjectSlide =
        Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _objectController,
            curve: const Interval(0.00, 0.45, curve: Curves.easeOutCubic),
          ),
        );

    _rightBadgeOpacity = CurvedAnimation(
      parent: _objectController,
      curve: const Interval(0.40, 0.75, curve: Curves.easeOut),
    );

    _rightBadgeSlide =
        Tween<Offset>(begin: const Offset(0.3, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _objectController,
            curve: const Interval(0.40, 0.75, curve: Curves.easeOutBack),
          ),
        );

    _leftBadgeOpacity = CurvedAnimation(
      parent: _objectController,
      curve: const Interval(0.65, 1.00, curve: Curves.easeOut),
    );

    _leftBadgeSlide =
        Tween<Offset>(
          begin: const Offset(-0.3, 0.15),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _objectController,
            curve: const Interval(0.65, 1.00, curve: Curves.easeOutBack),
          ),
        );

    _objectController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _objectController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If the user enabled the mic from system Settings and came back, reflect
    // it so the CTA reads "ابدأ الآن" instead of asking again.
    if (state == AppLifecycleState.resumed && !_micRequested) {
      Permission.microphone.status.then((s) {
        if (mounted && s.isGranted) setState(() => _micRequested = true);
      });
    }
  }

  Future<void> _nextText() async {
    if (_currentTextIndex < _texts.length - 1) {
      setState(() => _currentTextIndex += 1);
      // Replay the visual + badges entrance animation on every step, not just
      // the first one.
      _objectController.forward(from: 0);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/signin');
  }

  void _goToSignIn() {
    Navigator.of(context).pushReplacementNamed('/signin');
  }

  /// CTA label for the current step: "التالي" mid-flow, then on the final step
  /// "السماح بالوصول" until the mic prompt is handled, after which "ابدأ الآن".
  String get _ctaLabel {
    if (_currentTextIndex < _texts.length - 1) return 'التالي';
    return _micRequested ? 'ابدأ الآن' : 'السماح بالوصول';
  }

  void _onCtaPressed() {
    if (_currentTextIndex < _texts.length - 1) {
      _nextText();
      return;
    }
    if (_micRequested) {
      _goToSignIn();
    } else {
      _onRequestMicAccess();
    }
  }

  /// Final-step CTA: runs the shared mic permission flow, then flips the CTA
  /// to "ابدأ الآن" regardless of the outcome (the user has now been asked).
  Future<void> _onRequestMicAccess() async {
    if (!mounted) return;
    await runPermissionFlow(
      readStatus: () => Permission.microphone.status,
      request: () => Permission.microphone.request(),
      openSettings: openAppSettings,
      // No app dialogs for the mic: go straight to the OS prompt on first ask,
      // and straight to Settings if already denied (iOS won't re-prompt).
    );
    if (!mounted) return;
    setState(() => _micRequested = true);
  }

  /// Wraps a preview [card] with two floating badges on opposite diagonal
  /// corners, reusing the logo step's entrance animations. The top badge sits
  /// on the right when [topOnRight] is true (bottom badge takes the other
  /// side); flip it to swap the diagonal.
  Widget _buildBadgedPreview({
    required double width,
    required Widget card,
    required String topEmoji,
    required String bottomEmoji,
    required bool topOnRight,
    required double topInset,
    required double bottomInset,
  }) {
    return SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SlideTransition(
            position: _mainObjectSlide,
            child: FadeTransition(opacity: _mainObjectOpacity, child: card),
          ),
          _previewBadge(emoji: topEmoji, onRight: topOnRight, top: topInset),
          _previewBadge(
            emoji: bottomEmoji,
            onRight: !topOnRight,
            bottom: bottomInset,
          ),
        ],
      ),
    );
  }

  /// A single floating badge. Side picks the overhang edge and the matching
  /// entrance animation; pass exactly one of [top]/[bottom].
  Widget _previewBadge({
    required String emoji,
    required bool onRight,
    double? top,
    double? bottom,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: onRight ? null : -10,
      right: onRight ? -10 : null,
      child: SlideTransition(
        position: onRight ? _rightBadgeSlide : _leftBadgeSlide,
        child: FadeTransition(
          opacity: onRight ? _rightBadgeOpacity : _leftBadgeOpacity,
          child: _MiniBadge(emoji: emoji),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentText = _texts[_currentTextIndex];
    final double moodCardWidth =
        MediaQuery.sizeOf(context).width - AppSpacing.xxxxxl * 2;

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
              // A warm-gold glow painted OVER the scaffold background, fading to a fully
              // transparent version of the SAME gold so it dims into the bg (light or
              // dark) without greying. A near-white fade would read as grey over a dark
              // bg, so the glow stays gold the whole way down and is theme-independent.
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
              padding: const EdgeInsets.only(
                top: AppSpacing.lg,
                left: AppSpacing.xxl,
                right: AppSpacing.xxl,
                bottom: AppSpacing.xxl,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/signin');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: _skipButtonMinSize,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'تخطي',
                        semanticsLabel: 'تخطي المقدمة',
                        style: const TextStyle(
                          fontFamily: AppFontFamily.text,
                          fontSize: AppFontSizes.xs,
                          // Skip sits over the light-gold glow at the top, so a
                          // light neutral washes out. The dark brand purple
                          // reads clearly on the gold and stays on-brand.
                          fontWeight: AppFontWeights.semibold,
                          color: AppPalettePurple.shade100,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  if (_currentTextIndex == _moodPreviewIndex)
                    _buildBadgedPreview(
                      width: moodCardWidth,
                      card: _MoodPreviewCard(width: moodCardWidth),
                      topEmoji: '🤩',
                      bottomEmoji: '🤔',
                      topOnRight: true,
                      topInset: _moodBadgeTopInset,
                      bottomInset: _moodBadgeBottomInset,
                    )
                  else if (_currentTextIndex == _activityPreviewIndex)
                    _buildBadgedPreview(
                      width: moodCardWidth,
                      card: _ActivityPreviewCard(width: moodCardWidth),
                      topEmoji: '🧩',
                      bottomEmoji: '🌬',
                      topOnRight: false,
                      topInset: _activityBadgeInset,
                      bottomInset: _activityBadgeInset,
                    )
                  else if (_currentTextIndex == _companionPreviewIndex)
                    _buildBadgedPreview(
                      width: _companionVisualWidth,
                      card: SizedBox(
                        width: _companionVisualWidth,
                        height: _companionVisualHeight,
                        child: Center(
                          child: Image.asset(
                            AppPlayImages.smileCharacter,
                            height: _companionImageHeight,
                            fit: BoxFit.contain,
                            semanticLabel: 'شعار المرافق الذكي',
                          ),
                        ),
                      ),
                      topEmoji: '🤖',
                      bottomEmoji: '🗣️',
                      topOnRight: true,
                      topInset: _companionBadgeInset,
                      bottomInset: _companionBadgeInset,
                    )
                  else if (_currentTextIndex == _texts.length - 1)
                    _buildBadgedPreview(
                      width: _voiceOrbWidth,
                      card: _VoiceAccessOrb(width: _voiceOrbWidth),
                      topEmoji: '🗣️',
                      bottomEmoji: '🎙️',
                      topOnRight: true,
                      topInset: _voiceBadgeInset,
                      bottomInset: _voiceBadgeInset,
                    )
                  else
                    SizedBox(
                      width: _objectStackWidth,
                      height: _objectStackHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          SlideTransition(
                            position: _mainObjectSlide,
                            child: FadeTransition(
                              opacity: _mainObjectOpacity,
                              child: Container(
                                width: _mainCardWidth,
                                height: _mainCardHeight,
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.xxxl,
                                  AppSpacing.xl,
                                  AppSpacing.xxxl,
                                  AppSpacing.xxl,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppPaletteButteryYellow.shade50,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(AppRadius.full),
                                    topRight: Radius.circular(AppRadius.full),
                                    bottomLeft: Radius.circular(
                                      AppRadius.xxxxxxxxxl,
                                    ),
                                    bottomRight: Radius.circular(
                                      AppRadius.xxxxxxxxxl,
                                    ),
                                  ),
                                  boxShadow: AppShadows.colorful,
                                ),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: SvgPicture.asset(
                                    AppSvgIcons.mishkatIcon,
                                    width: _mainCardIconSize,
                                    height: _mainCardIconSize,
                                    colorFilter: const ColorFilter.mode(
                                      AppNeutralColors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            top: _rightBadgeTop,
                            right: _rightBadgeRight,
                            child: SlideTransition(
                              position: _rightBadgeSlide,
                              child: FadeTransition(
                                opacity: _rightBadgeOpacity,
                                child: const _MiniBadge(emoji: '🔥'),
                              ),
                            ),
                          ),

                          Positioned(
                            top: _leftBadgeTop,
                            left: _leftBadgeLeft,
                            child: SlideTransition(
                              position: _leftBadgeSlide,
                              child: FadeTransition(
                                opacity: _leftBadgeOpacity,
                                child: const _MiniBadge(emoji: '🧱'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(flex: 3),

                  SizedBox(
                    width: double.infinity,
                    height: _textBlockHeight,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: AlignmentDirectional.topStart,
                          children: <Widget>[
                            ...previousChildren,
                            ?currentChild,
                          ],
                        );
                      },
                      transitionBuilder: (child, animation) {
                        final isIncoming =
                            child.key == ValueKey(_currentTextIndex);

                        final beginOffset = isIncoming
                            ? const Offset(0, 0.35)
                            : const Offset(0, -0.35);

                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: beginOffset,
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _OnboardingContent(
                        key: ValueKey(_currentTextIndex),
                        current: currentText,
                        next: _currentTextIndex < _texts.length - 1
                            ? _texts[_currentTextIndex + 1]
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxxl),

                  SizedBox(
                    width: double.infinity,
                    height: _ctaButtonHeight,
                    child: AppButton(
                      label: _ctaLabel,
                      expand: true,
                      borderRadius: AppRadius.lg,
                      onPressed: _onCtaPressed,
                      trailing: SvgPicture.asset(
                        AppSvgIcons.arrowLeft,
                        width: AppIconSize.md,
                        height: AppIconSize.md,
                      ),
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

class OnboardingTextData {
  final String emoji;
  final String title;
  final String description;

  const OnboardingTextData({
    required this.emoji,
    required this.title,
    required this.description,
  });
}

/// Final-step visual: a calm lavender orb ringed by two soft neutral halos.
/// The core and halos pulse with an irregular, speech-like envelope so the orb
/// reads as someone actively talking. The solid core sits at a fixed fraction
/// of [width] so the orb scales with the screen.
class _VoiceAccessOrb extends StatefulWidget {
  final double width;

  const _VoiceAccessOrb({required this.width});

  @override
  State<_VoiceAccessOrb> createState() => _VoiceAccessOrbState();
}

class _VoiceAccessOrbState extends State<_VoiceAccessOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.of(context).disableAnimations;
    if (_reduced) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Irregular 0..1 envelope from three out-of-phase sines — busier and less
  /// metronomic than a single wave, so the pulse feels like live speech.
  double _envelope(double t) {
    final double tau = t * 2 * math.pi;
    final double v =
        math.sin(tau * 2.0) * 0.5 +
        math.sin(tau * 3.3 + 1.0) * 0.3 +
        math.sin(tau * 5.7 + 2.0) * 0.2;
    return ((v + 1.0) / 2.0).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.width;
    final double core = width * 0.65;
    final double innerRing = width * 0.80;
    final double outerRing = width * 0.95;

    Widget ring(double size, Color color, {List<BoxShadow>? shadow}) =>
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
            boxShadow: shadow,
          ),
        );

    final Widget coreOrb = Container(
      width: core,
      height: core,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppPalettePurple.shade300,
      ),
    );

    return SizedBox(
      width: width,
      height: width,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double env = _reduced ? 0 : _envelope(_controller.value);
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.scale(
                scale: 1.0 + env * 0.05,
                child: ring(outerRing, context.colors.shade200),
              ),
              Transform.scale(
                scale: 1.0 + env * 0.08,
                child: ring(innerRing, context.colors.shade300),
              ),
              Transform.scale(scale: 1.0 + env * 0.12, child: coreOrb),
            ],
          );
        },
      ),
    );
  }
}

const List<String> _emojiFontFallback = [
  'Apple Color Emoji',
  'Segoe UI Emoji',
  'Noto Color Emoji',
];

class _OnboardingContent extends StatelessWidget {
  final OnboardingTextData current;
  final OnboardingTextData? next;

  const _OnboardingContent({
    super.key,
    required this.current,
    required this.next,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActiveBlock(data: current),
        if (next != null) ...[
          const SizedBox(height: AppSpacing.xxxl),
          _TeaserBlock(data: next!),
        ],
      ],
    );
  }
}

class _ActiveBlock extends StatelessWidget {
  final OnboardingTextData data;

  const _ActiveBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _EmojiCircle(
            emoji: data.emoji,
            backgroundColor: AppPaletteButteryYellow.shade400,
            size: AppSpacing.xxxxxl,
            emojiSize: AppFontSizes.lg,
            boxShadow: AppShadows.colorful,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          data.title,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: AppTextStyles.thmanyahTitle(context),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          data.description,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: AppFontFamily.text,
            fontSize: AppFontSizes.sm,
            height: 1.65,
            fontWeight: AppFontWeights.regular,
            color: context.colors.shade500,
          ),
        ),
      ],
    );
  }
}

class _TeaserBlock extends StatelessWidget {
  final OnboardingTextData data;

  const _TeaserBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          textDirection: TextDirection.rtl,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _EmojiCircle(
              emoji: data.emoji,
              backgroundColor: context.colors.shade100,
            ),
            const SizedBox(width: AppSpacing.xl),
            Flexible(
              child: Text(
                data.title,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.thmanyahHeading(context).copyWith(
                  // Darkened from the pale shade300 (#E5E5E5) that washed out on
                  // white: a readable secondary grey, still softer than the
                  // active title. Dark mode keeps a legible light grey.
                  color: context.forDark(
                    const Color(0xFF6B7280),
                    context.colors.shade500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiCircle extends StatelessWidget {
  final String emoji;
  final Color backgroundColor;
  final double size;
  final double emojiSize;
  final List<BoxShadow> boxShadow;

  const _EmojiCircle({
    required this.emoji,
    required this.backgroundColor,
    this.size = AppSpacing.xxxxl,
    this.emojiSize = AppFontSizes.sm,
    this.boxShadow = AppShadows.xs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: boxShadow,
      ),
      child: Center(
        child: SizedBox(
          width: emojiSize,
          height: emojiSize,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(
              emoji,
              style: const TextStyle(
                fontFamily: 'Apple Color Emoji',
                fontFamilyFallback: _emojiFontFallback,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String emoji;

  const _MiniBadge({required this.emoji});

  static const double _height = 30;
  static const double _width = 40;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _width,
      height: _height,
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppPaletteButteryYellow.shade200, width: 1.5),
        boxShadow: AppShadows.colorful,
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(
            fontSize: AppFontSizes.sm,
            fontFamily: 'Apple Color Emoji',
            fontFamilyFallback: _emojiFontFallback,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mood-logging preview (step "تعرّف على شعورك بسهولة")
//
// A static, display-only mirror of the home mood-picker bottom sheet: the mood
// circle + the curved "axis" carousel, without the cloud header or confirm
// button. The selected state is fixed on "متحمس". Visual constants are copied
// here intentionally so the onboarding has no dependency on home_screen.dart.
// ---------------------------------------------------------------------------

// Selected mood is the third in the catalogue ("مسترخي"/relaxed). Its colours
// are the home `_Tiffany` mood values, copied verbatim so the card matches the
// bottom sheet exactly.
const Color _kSelectedRing = Color(0xFF81D8D0); // _Tiffany.shade300
const Color _kSelectedBg = Color(0xFFB9ECE6); // _Tiffany.shade100
const String _kSelectedEmoji = '😎';
const String _kSelectedLabel = 'مسترخي';

// Neutral fill/stroke shared by every non-selected mood on the curve.
const Color _kSideFill = Color(0xFFFFF0BD);
const Color _kSideStroke = Color(0xFFF2D680);

/// The concentric-ring mood graphic (two translucent rings + emoji), matching
/// the home `_MoodCard`. Reused by the mood card and the companion step.
class _MoodCircle extends StatelessWidget {
  const _MoodCircle({required this.ringColor, required this.emoji});

  final Color ringColor;
  final String emoji;

  static const double _outer = 150;
  static const double _inner = 125;
  static const double _emojiSize = 80;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: _outer,
          height: _outer,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ringColor.withValues(alpha: 0.2),
          ),
        ),
        Container(
          width: _inner,
          height: _inner,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ringColor.withValues(alpha: 0.3),
          ),
        ),
        _PreviewEmoji(emoji: emoji, size: _emojiSize),
      ],
    );
  }
}

class _MoodPreviewCard extends StatelessWidget {
  const _MoodPreviewCard({required this.width});

  final double width;

  // Mirrors the home `_MoodCard` circle exactly.
  static const double _circlePanelHeight = 150;

  // Matches the gap between the home `_MoodCard` and its carousel.
  static const double _circleToAxisGap = 28;

  // Extra breathing room top/bottom: AppSpacing.xxl (20) + 16.
  static const double _cardVerticalPadding = AppSpacing.xxl + 16;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppSectionCard(
        boxShadow: AppShadows.colorful,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: _cardVerticalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _circlePanelHeight,
              child: const Center(
                child: _MoodCircle(
                  ringColor: _kSelectedRing,
                  emoji: _kSelectedEmoji,
                ),
              ),
            ),
            const SizedBox(height: _circleToAxisGap),
            const _MoodPreviewCarousel(),
          ],
        ),
      ),
    );
  }
}

class _MoodPreviewCarousel extends StatelessWidget {
  const _MoodPreviewCarousel();

  // All values copied verbatim from the home mood carousel so the curve, the
  // gap to the selected mood, and the spacing between moods match the app.
  static const double _height = 105;
  static const double _curveStartY = 105;
  static const double _curveControlY = 5;
  static const double _viewportFraction = 0.22;
  static const double _labelTopY = 68;

  // "relaxed" centred (catalogue index 2), so "excited" and "happy" sit before
  // it (right, positions +2 and +1) while "calm" and "bored" follow it (left,
  // positions -1 and -2). Neighbour emojis are flavour only — every non-centre
  // circle uses the shared neutral styling.
  static const List<_PreviewMoodItem> _items = [
    _PreviewMoodItem(position: -2, emoji: '😫', size: 30), // bored
    _PreviewMoodItem(position: -1, emoji: '😌', size: 44), // calm
    _PreviewMoodItem(position: 0, emoji: _kSelectedEmoji, size: 60), // relaxed
    _PreviewMoodItem(position: 1, emoji: '😊', size: 44), // happy
    _PreviewMoodItem(position: 2, emoji: '🤩', size: 30), // excited
  ];

  static double _bezierY(double t) {
    final double s = 1 - t;
    return _curveStartY * (s * s * s + t * t * t) + 3 * _curveControlY * s * t;
  }

  Widget _buildItem(_PreviewMoodItem item, double width, double step) {
    final double size = item.size;
    final double t = (0.5 + item.position * _viewportFraction).clamp(0.0, 1.0);
    final double top = _bezierY(t) - size / 2;
    final double left = width / 2 + item.position * step - size / 2;

    return Positioned(
      left: left,
      top: top,
      child: item.position == 0
          ? _centerCircle(item)
          : _sideCircle(item, item.position.abs()),
    );
  }

  Widget _centerCircle(_PreviewMoodItem item) {
    return Container(
      width: item.size,
      height: item.size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _kSelectedBg,
        shape: BoxShape.circle,
        border: Border.all(color: _kSelectedRing, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: _kSelectedRing.withValues(alpha: 0.35),
            blurRadius: 15,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _PreviewEmoji(emoji: item.emoji, size: item.size * 0.6),
    );
  }

  Widget _sideCircle(_PreviewMoodItem item, int distance) {
    final bool isNeighbor = distance == 1;
    final double bgOpacity = isNeighbor ? 0.874 : 0.414;
    final double strokeOpacity = isNeighbor ? 0.70 : 0.40;
    final double strokeWidth = isNeighbor ? 1.25 : 1.0;

    return SizedBox(
      width: item.size,
      height: item.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: bgOpacity,
            child: Container(
              width: item.size,
              height: item.size,
              decoration: BoxDecoration(
                color: _kSideFill,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _kSideStroke.withValues(alpha: strokeOpacity),
                  width: strokeWidth,
                ),
              ),
            ),
          ),
          _PreviewEmoji(emoji: item.emoji, size: item.size * 0.6),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double step = width * _viewportFraction;
        return SizedBox(
          height: _height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _PreviewArcPainter()),
              ),
              for (final item in _items) _buildItem(item, width, step),
              Positioned(
                top: _labelTopY,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Text(
                    _kSelectedLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFontFamily.text,
                      fontSize: AppFontSizes.xxs,
                      fontWeight: AppFontWeights.semibold,
                      color: context.colors.shade500,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PreviewMoodItem {
  const _PreviewMoodItem({
    required this.position,
    required this.emoji,
    required this.size,
  });

  /// Signed slot relative to the centred mood (0 = selected, negative = right).
  final int position;
  final String emoji;
  final double size;
}

class _PreviewArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x008B7FD8),
          Color(0x598B7FD8),
          Color(0x8C8B7FD8),
          Color(0x598B7FD8),
          Color(0x008B7FD8),
        ],
        stops: [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path()
      ..moveTo(0, _MoodPreviewCarousel._curveStartY)
      ..cubicTo(
        size.width / 3,
        _MoodPreviewCarousel._curveControlY,
        size.width * 2 / 3,
        _MoodPreviewCarousel._curveControlY,
        size.width,
        _MoodPreviewCarousel._curveStartY,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PreviewEmoji extends StatelessWidget {
  const _PreviewEmoji({required this.emoji, required this.size});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
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
            fontFamily: 'Apple Color Emoji',
            fontFamilyFallback: _emojiFontFallback,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity preview (step "خطواتك نحو التوازن")
//
// A static, non-interactive copy of the "فعّل حواسك" card from the balance
// station. Wrapped in IgnorePointer so its buttons render but never respond.
// Content + styling copied verbatim from `balance_station_screen.dart`.
// ---------------------------------------------------------------------------

class _ActivityPreviewCard extends StatelessWidget {
  const _ActivityPreviewCard({required this.width});

  final double width;

  static const String _title = 'فعّل حواسك 👃';
  static const String _subtitle =
      'ركّز على اللي تشوفه وتسمعه وتحسّه عشان تهدّي تشتّت الأفكار.';
  static const String _tagLabel = 'تمارين تنظيم الانتباه';
  static const double _badgeHeight = 30;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: width,
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: context.colors.shade200, width: 0.5),
            boxShadow: AppShadows.colorful,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  _badgeHeight + AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _title,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.thmanyahHeading(
                        context,
                      ).copyWith(fontSize: AppFontSizes.sm),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _subtitle,
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
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _ActivityMindfulnessTag(label: _tagLabel),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'ابدأ التمرين',
                            expand: true,
                            onPressed: () {},
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
                        const Expanded(child: _ActivityLearnMoreButton()),
                      ],
                    ),
                  ],
                ),
              ),
              const PositionedDirectional(
                top: 0,
                start: 0,
                child: _ActivitySuggestionBadge(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityMindfulnessTag extends StatelessWidget {
  const _ActivityMindfulnessTag({required this.label});

  final String label;

  // Same blue as the in-app card. Light mode keeps the app's pale-blue chip;
  // dark mode swaps the bg for a deep navy so the chip harmonises with the
  // dark card instead of glaring as a bright light-blue pill.
  static const Color _fg = AppInformationColors.shade300; // 0xFF84CAFF
  static const Color _bgLight = AppInformationColors.shade25; // 0xFFF5FAFF
  static const Color _bgDark = AppInformationColors.shade950; // 0xFF102A56

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.forDark(_bgLight, _bgDark),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: _fg, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            AppSvgIcons.activitiesMindfulness24,
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

class _ActivitySuggestionBadge extends StatelessWidget {
  const _ActivitySuggestionBadge();

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

class _ActivityLearnMoreButton extends StatelessWidget {
  const _ActivityLearnMoreButton();

  static const double _height = 44;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
    );
  }
}
