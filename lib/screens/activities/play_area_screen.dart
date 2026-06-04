import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../constants/app_play_images.dart';
import '../../core/activities/activity_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/buttons/app_button.dart';
import '../../widgets/nav/app_top_nav.dart';
import 'emotion_cards_game_screen.dart';
import 'emotion_cards_learn_more_screen.dart';
import 'smile_face_game_screen.dart';
import 'smile_face_learn_more_screen.dart';

enum _TagScheme { purple, yellow }

enum _GameId { smile, emotionCards }

class _PlayTag {
  const _PlayTag({
    required this.label,
    required this.iconAsset,
    required this.scheme,
  });

  final String label;
  final String iconAsset;
  final _TagScheme scheme;
}

class _PlayGame {
  const _PlayGame({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.imageBg,
    required this.tags,
  });

  final _GameId id;
  final String title;
  final String subtitle;
  final String imageAsset;
  final Color imageBg;
  final List<_PlayTag> tags;
}

class PlayAreaScreen extends StatefulWidget {
  const PlayAreaScreen({super.key});

  @override
  State<PlayAreaScreen> createState() => _PlayAreaScreenState();
}

class _PlayAreaScreenState extends State<PlayAreaScreen> {
  // null = "unknown" (offline/error/before fetch) → show every card.
  Set<String>? _activeSlugs;

  @override
  void initState() {
    super.initState();
    ActivityApi.activeSlugs().then((slugs) {
      if (mounted) setState(() => _activeSlugs = slugs);
    }).catchError((_) {
      // offline / error: leave _activeSlugs null so all cards stay visible.
    });
  }

  bool _isVisible(String slug) =>
      _activeSlugs == null || _activeSlugs!.contains(slug);

  // Maps a game to its backend slug.
  String _slugFor(_GameId id) {
    switch (id) {
      case _GameId.emotionCards:
        return ActivitySlugs.emotionCards;
      case _GameId.smile:
        return ActivitySlugs.smileFace;
    }
  }

  static const List<_PlayGame> _games = [
    _PlayGame(
      id: _GameId.smile,
      title: 'الوجه المبتسم',
      subtitle: 'أعثر الوجه المبتسم بين الزحمة',
      imageAsset: AppPlayImages.smileCharacter,
      imageBg: Color(0xFFFFF0BD),
      tags: [
        _PlayTag(
          label: 'دقيقة',
          iconAsset: AppSvgIcons.activitiesTimer,
          scheme: _TagScheme.purple,
        ),
        _PlayTag(
          label: 'تركز',
          iconAsset: AppSvgIcons.focusSparkle,
          scheme: _TagScheme.yellow,
        ),
      ],
    ),
    _PlayGame(
      id: _GameId.emotionCards,
      title: 'بطاقات المشاعر',
      subtitle: 'طابق الشعور مع لونه، وتعرّف عليه بهدوء',
      imageAsset: AppPlayImages.emotionCards,
      imageBg: Color(0xFFFFE4E6),
      tags: [
        _PlayTag(
          label: '1-2 دقيقة',
          iconAsset: AppSvgIcons.activitiesTimer,
          scheme: _TagScheme.purple,
        ),
        _PlayTag(
          label: 'مشاعر',
          iconAsset: AppSvgIcons.activitiesEmotions,
          scheme: _TagScheme.yellow,
        ),
      ],
    ),
  ];

  void _onStart(BuildContext context, _PlayGame game) {
    switch (game.id) {
      case _GameId.emotionCards:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const EmotionCardsGameScreen(),
          ),
        );
      case _GameId.smile:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const SmileFaceGameScreen(),
          ),
        );
    }
  }

  void _onLearnMore(BuildContext context, _PlayGame game) {
    switch (game.id) {
      case _GameId.emotionCards:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const EmotionCardsLearnMoreScreen(),
          ),
        );
      case _GameId.smile:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const SmileFaceLearnMoreScreen(),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hide games whose backend Activity an admin has deactivated.
    final List<_PlayGame> games =
        _games.where((g) => _isVisible(_slugFor(g.id))).toList();
    return Scaffold(
      backgroundColor: context.colors.shade50,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppTopNav(
                title: 'منطقة اللعب',
                subtitle: 'ألعاب قصيرة تساعدك تهدّي وتركّز',
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
                      for (int i = 0; i < games.length; i++) ...[
                        if (i != 0) const SizedBox(height: AppSpacing.xl),
                        _GameCard(
                          game: games[i],
                          onStart: () => _onStart(context, games[i]),
                          onLearnMore: () => _onLearnMore(context, games[i]),
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

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.game,
    required this.onStart,
    required this.onLearnMore,
  });

  final _PlayGame game;
  final VoidCallback onStart;
  final VoidCallback onLearnMore;

  static const double _illustrationSize = 80;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.colors.shade200, width: 0.5),
        boxShadow: AppShadows.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: _illustrationSize,
                height: _illustrationSize,
                decoration: BoxDecoration(
                  // Keep the light pastel illustration bg in both themes — the
                  // illustration is drawn for the pastel and reads fine on it.
                  color: game.imageBg,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Center(
                  child: Image.asset(
                    game.imageAsset,
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      game.title,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.thmanyahHeading(context).copyWith(
                        fontSize: AppFontSizes.sm,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      game.subtitle,
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
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final t in game.tags) _PlayTagChip(tag: t),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'ابدأ اللعب',
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
    return SizedBox(
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
    );
  }
}

class _PlayTagChip extends StatelessWidget {
  const _PlayTagChip({required this.tag});

  final _PlayTag tag;

  static const Color _yellowFg = Color(0xFFFEC84B);
  static const Color _yellowBg = Color(0xFFFFFAEB);
  static const Color _purpleFg = Color(0xFF8F89C9);
  static const Color _purpleBg = Color(0xFFF5F4FB);

  @override
  Widget build(BuildContext context) {
    final ({Color bg, Color fg}) colors = switch (tag.scheme) {
      _TagScheme.purple => (
          bg: context.purpleSoftFill(_purpleBg),
          fg: _purpleFg,
        ),
      _TagScheme.yellow => (
          bg: context.forDark(_yellowBg, AppWarningColors.shade950),
          fg: _yellowFg,
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
        border: Border.all(color: colors.fg, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            tag.iconAsset,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(colors.fg, BlendMode.srcIn),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            tag.label,
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
