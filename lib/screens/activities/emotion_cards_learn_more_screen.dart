import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../constants/app_play_images.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/nav/app_top_nav.dart';
import 'emotion_cards_game_screen.dart';

class EmotionCardsLearnMoreScreen extends StatelessWidget {
  const EmotionCardsLearnMoreScreen({super.key});

  static const List<_MoodEntry> _moods = [
    _MoodEntry(
      label: 'مشمئز',
      imageAsset: AppPlayImages.moodDisgust,
      color: Color(0xFF47CD89),
    ),
    _MoodEntry(
      label: 'متفاجئ',
      imageAsset: AppPlayImages.moodSurprise,
      color: Color(0xFFF79009),
    ),
    _MoodEntry(
      label: 'خائف',
      imageAsset: AppPlayImages.moodFear,
      color: Color(0xFFB0A6DF),
    ),
    _MoodEntry(
      label: 'غاضب',
      imageAsset: AppPlayImages.moodAnger,
      color: Color(0xFFF97066),
    ),
    _MoodEntry(
      label: 'سعيد',
      imageAsset: AppPlayImages.moodHappy,
      color: Color(0xFFFEC84B),
    ),
    _MoodEntry(
      label: 'حزين',
      imageAsset: AppPlayImages.moodSadness,
      color: Color(0xFF53B1FD),
    ),
  ];

  void _onStart(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const EmotionCardsGameScreen(),
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
              const AppTopNav(title: 'بطاقات المشاعر'),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const _IntroBlock(),
                      const SizedBox(height: 40),
                      const _MoodGrid(moods: _moods),
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

class _IntroBlock extends StatelessWidget {
  const _IntroBlock();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 342,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TiltedCardsRow(),
          const SizedBox(height: 36),
          Text(
            'طابق كل شعور بلونه',
            textAlign: TextAlign.center,
            style: AppTextStyles.thmanyahHeading(context).copyWith(
              fontSize: AppFontSizes.md,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'كل شعور له لون ورمز يساعدك تتعرّف عليه، اقلب البطاقات وطابق الشعور مع لونه بهدوء',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.sm,
              fontWeight: AppFontWeights.regular,
              color: context.colors.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TiltedCardsRow extends StatelessWidget {
  const _TiltedCardsRow();

  static const double _frameWidth = 252.679;
  static const double _frameHeight = 131.829;
  static const double _cardWidth = 67.958;
  static const double _cardHeight = 97.859;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: _frameWidth,
        height: _frameHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 12,
              top: 18,
              child: Transform.rotate(
                angle: -16 * math.pi / 180,
                child: const _MiniCard(
                  borderColor: AppDangerColors.shade500,
                  shadowColor: AppDangerColors.shade100,
                  imageAsset: AppPlayImages.moodAnger,
                  width: _cardWidth,
                  height: _cardHeight,
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 18,
              child: Transform.rotate(
                angle: 16 * math.pi / 180,
                child: const _MiniCard(
                  borderColor: AppInformationColors.shade400,
                  shadowColor: AppInformationColors.shade100,
                  imageAsset: AppPlayImages.moodSadness,
                  width: _cardWidth,
                  height: _cardHeight,
                ),
              ),
            ),
            const _MiniCard(
              borderColor: AppPalettePurple.shade200,
              shadowColor: AppPalettePurple.shade500,
              imageAsset: AppPlayImages.moodFear,
              width: _cardWidth,
              height: _cardHeight,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.borderColor,
    required this.shadowColor,
    required this.imageAsset,
    required this.width,
    required this.height,
  });

  final Color borderColor;
  final Color shadowColor;
  final String imageAsset;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(10.873),
        border: Border.all(color: borderColor, width: 1.903),
        boxShadow: [
          BoxShadow(
            // Softened: an opaque coloured shadow with a wide spread glows too
            // hard on the dark surface, so dim it and tighten the spread.
            color: shadowColor.withValues(alpha: 0.5),
            offset: const Offset(0, 4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Image.asset(
        imageAsset,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _MoodEntry {
  const _MoodEntry({
    required this.label,
    required this.imageAsset,
    required this.color,
  });

  final String label;
  final String imageAsset;
  final Color color;
}

class _MoodGrid extends StatelessWidget {
  const _MoodGrid({required this.moods});

  final List<_MoodEntry> moods;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = [];
    for (int i = 0; i < moods.length; i += 2) {
      if (i != 0) rows.add(const SizedBox(height: 7));
      rows.add(
        Row(
          children: [
            Expanded(child: _MoodPill(mood: moods[i])),
            const SizedBox(width: 7),
            if (i + 1 < moods.length)
              Expanded(child: _MoodPill(mood: moods[i + 1]))
            else
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );
    }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }
}

class _MoodPill extends StatelessWidget {
  const _MoodPill({required this.mood});

  final _MoodEntry mood;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: mood.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            mood.label,
            style: const TextStyle(
              fontFamily: AppFontFamily.title,
              fontSize: AppFontSizes.xxs,
              fontWeight: AppFontWeights.bold,
              color: AppNeutralColors.white,
              height: 1.2,
              fontFeatures: AppFontFamily.titleFeatures,
            ),
          ),
          _EmojiCircle(imageAsset: mood.imageAsset),
        ],
      ),
    );
  }
}

class _EmojiCircle extends StatelessWidget {
  const _EmojiCircle({required this.imageAsset});

  final String imageAsset;

  static const double _size = 32.642;
  static const double _imageSize = 27.979;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        // Sits on the saturated mood pill, so it stays literal white in both
        // themes (like light mode) — a theme-resolved white would turn dark
        // and read as a hole on the coloured pill.
        color: AppNeutralColors.white.withValues(alpha: 0.83),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFFFFFFF),
            blurRadius: 3.731,
            spreadRadius: 0,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Image.asset(
        imageAsset,
        width: _imageSize,
        height: _imageSize,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}
