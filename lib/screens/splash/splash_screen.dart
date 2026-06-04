import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../core/auth/auth_service.dart';
import '../../core/storage/token_storage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _total = Duration(milliseconds: 3800);
  static const Duration _holdAfter = Duration(milliseconds: 700);

  // Figma spec: composition is 256.12 × 73.
  // Wordmark 219 + icon 44 with a -7 overlap (negative gap) = 256.
  static const double _wordmarkWidth = 219;
  static const double _wordmarkHeight = 73;
  static const double _iconFinalWidth = 44;
  static const double _iconFinalHeight = _iconFinalWidth * 135 / 100;
  static const double _iconBigWidth = 200;
  static const double _iconWordmarkOverlap = 7;

  static const double _compositionWidth =
      _wordmarkWidth + _iconFinalWidth - _iconWordmarkOverlap;
  static const double _compositionHeight = _wordmarkHeight;

  // Icon's final spot inside the composition (Figma: align-items flex-start,
  // so the icon's top sits at y=0; its left sits 7px before the wordmark
  // ends). Offsets are measured from the composition centre, since the
  // composition itself is centred on the screen.
  static const double _iconLeftInComposition =
      _wordmarkWidth - _iconWordmarkOverlap; // 212
  static const double _iconFinalDx =
      _iconLeftInComposition +
      _iconFinalWidth / 2 -
      _compositionWidth / 2; // +106
  static const double _iconFinalDy =
      _iconFinalHeight / 2 - _compositionHeight / 2; // -6.8

  late final AnimationController _controller;

  late final Animation<double> _iconOpacity;
  late final Animation<double> _iconWidth;
  late final Animation<Offset> _iconOffset;
  late final Animation<double> _wordmarkOpacity;
  late final Animation<double> _sloganOpacity;
  late final Animation<Offset> _sloganOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _total)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          Future.delayed(_holdAfter, () {
            // ignore: discarded_futures
            _goHome();
          });
        }
      })
      ..forward();

    _iconOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.18, curve: Curves.easeOut),
    );

    final shrinkCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.22, 0.55, curve: Curves.easeInOutCubic),
    );

    _iconWidth = Tween<double>(
      begin: _iconBigWidth,
      end: _iconFinalWidth,
    ).animate(shrinkCurve);

    _iconOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(_iconFinalDx, _iconFinalDy),
    ).animate(shrinkCurve);

    _wordmarkOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.75, curve: Curves.easeOut),
    );

    _sloganOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.78, 0.96, curve: Curves.easeOut),
    );
    _sloganOffset =
        Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.78, 0.96, curve: Curves.easeOutCubic),
          ),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goHome() async {
    if (!mounted) return;
    final NavigatorState navigator = Navigator.of(context);
    if (!TokenStorage.instance.hasSession) {
      navigator.pushReplacementNamed('/onboarding');
      return;
    }
    final user = await AuthService.fetchCurrentUser();
    if (!mounted) return;
    navigator.pushReplacementNamed(user != null ? '/home' : '/signin');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
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
              colors: [
                AppPaletteButteryYellow.shade200,
                AppPaletteButteryYellow.shade200.withValues(alpha: 0.55),
                AppPaletteButteryYellow.shade200.withValues(alpha: 0.22),
                AppPaletteButteryYellow.shade200.withValues(alpha: 0.0),
              ],
              stops: const [0.00, 0.07, 0.15, 0.26],
            ),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: _compositionWidth,
                        height: _compositionHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Opacity(
                                opacity: _wordmarkOpacity.value,
                                child: SvgPicture.asset(
                                  AppSvgIcons.mishkatLogo,
                                  width: _wordmarkWidth,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Center(
                              child: Transform.translate(
                                offset: _iconOffset.value,
                                child: Opacity(
                                  opacity: _iconOpacity.value,
                                  child: SvgPicture.asset(
                                    AppSvgIcons.mishkatIcon,
                                    width: _iconWidth.value,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.xxxxxxxxl,
                          left: AppSpacing.xxl,
                          right: AppSpacing.xxl,
                        ),
                        child: FractionalTranslation(
                          translation: _sloganOffset.value,
                          child: Opacity(
                            opacity: _sloganOpacity.value,
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                context.colors.shade400,
                                BlendMode.srcIn,
                              ),
                              child: const Text(
                                'كَمِشْكَاةٍ فِيهَا مِصْبَاحٌ',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppFontFamily.quran,
                                  fontSize: AppFontSizes.md,
                                  color: Colors.black,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
