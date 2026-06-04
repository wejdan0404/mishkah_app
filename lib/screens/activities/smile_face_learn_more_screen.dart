import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../constants/app_play_images.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/nav/app_top_nav.dart';
import 'smile_face_game_screen.dart';

class SmileFaceLearnMoreScreen extends StatelessWidget {
  const SmileFaceLearnMoreScreen({super.key});

  static const List<String> _illustrationAssets = [
    AppPlayImages.moodSadness,
    AppPlayImages.moodAnger,
    AppPlayImages.moodFear,
    AppPlayImages.moodAnger,
    AppPlayImages.moodHappy,
    AppPlayImages.moodSadness,
    AppPlayImages.moodDisgust,
    AppPlayImages.moodFear,
    AppPlayImages.moodSurprise,
  ];

  void _onStart(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const SmileFaceGameScreen()),
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
              const AppTopNav(title: 'الوجه المبتسم'),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _Illustration(assets: _illustrationAssets),
                      const SizedBox(height: 36),
                      Text(
                        'اعثر على الوجه المبتسم',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.thmanyahHeading(context).copyWith(
                          fontSize: AppFontSizes.md,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'وسط الزحمة فيه وجه أسعد من الباقي. لاحظه بهدوء!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppFontFamily.title,
                          fontSize: AppFontSizes.sm,
                          fontWeight: AppFontWeights.regular,
                          color: context.colors.shade500,
                          height: 1.5,
                          fontFeatures: const [
                            FontFeature('salt'),
                            FontFeature('swsh'),
                            FontFeature('ss05'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      const _StepsCard(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  0,
                  AppSpacing.xxl,
                  AppSpacing.xl,
                ),
                child: AppButton(
                  label: 'ابدأ اللعب',
                  expand: true,
                  onPressed: () => _onStart(context),
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

class _Illustration extends StatelessWidget {
  const _Illustration({required this.assets});

  final List<String> assets;

  static const double _tileSize = 72;
  static const double _gap = 8;
  static const int _smileIndex = 4; // center of 3x3

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _tileSize * 3 + _gap * 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int r = 0; r < 3; r++) ...[
            if (r != 0) const SizedBox(height: _gap),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int c = 0; c < 3; c++) ...[
                  if (c != 0) const SizedBox(width: _gap),
                  _IllustrationTile(
                    asset: assets[r * 3 + c],
                    isSmile: (r * 3 + c) == _smileIndex,
                    size: _tileSize,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _IllustrationTile extends StatelessWidget {
  const _IllustrationTile({
    required this.asset,
    required this.isSmile,
    required this.size,
  });

  final String asset;
  final bool isSmile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(10);
    if (isSmile) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppPaletteButteryYellow.shade400,
          borderRadius: radius,
          border: Border.all(
            color: AppPaletteButteryYellow.shade100,
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0xF2FFF6D6),
              blurRadius: 15,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Color(0x80FEDD6E),
              blurRadius: 18,
              spreadRadius: 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: radius,
        border: Border.all(color: context.colors.shade200, width: 1),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.white, width: 0.868),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F332959),
            offset: Offset(0, 3.474),
            blurRadius: 12.158,
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Step(number: 1, label: 'شــــوف \nالـشبكة بهـــدوء.'),
          _Step(number: 2, label: 'حـــــدد \nالوجــه المبتسـم.'),
          _Step(number: 3, label: 'ثــلاث  جــولات\nلطيفـــة.'),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.label});

  final int number;
  final String label;

  static const double _badgeSize = 24;
  static const double _frameWidth = 90;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _frameWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _badgeSize,
            height: _badgeSize,
            decoration: const BoxDecoration(
              color: AppPalettePurple.shade300,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.xxs,
                fontWeight: AppFontWeights.bold,
                color: AppNeutralColors.white,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontFamily: AppFontFamily.title,
              fontSize: AppFontSizes.xxs,
              fontWeight: AppFontWeights.bold,
              color: context.colors.shade600,
              fontFeatures: const [
                FontFeature('salt'),
                FontFeature('swsh'),
                FontFeature('ss05'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
