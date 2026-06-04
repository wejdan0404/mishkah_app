import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../constants/app_play_images.dart';
import '../../core/activities/activity_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/activities/game_feedback_message.dart';
import '../../widgets/nav/app_top_nav.dart';
import '../auth/success_screen.dart';
import 'understand_feelings_progress.dart';

class EmotionCardsGameScreen extends StatefulWidget {
  const EmotionCardsGameScreen({super.key});

  @override
  State<EmotionCardsGameScreen> createState() => _EmotionCardsGameScreenState();
}

class _Mood {
  const _Mood({
    required this.id,
    required this.imageAsset,
    required this.color,
    this.fillColor,
    this.fillColorDark,
    this.softPurpleFill = false,
  });

  final String id;
  final String imageAsset;
  final Color color;

  /// Literal background fill for this mood's face-up card (light mode). Null
  /// when [softPurpleFill] is true (the fill is resolved at build time via
  /// [AppColorsContext.purpleSoftFill] so it adapts to dark mode).
  final Color? fillColor;

  /// Deep variant of [fillColor] used in dark mode so the pale tint doesn't
  /// glare. Defaults to [fillColor] when null.
  final Color? fillColorDark;

  /// When true, the fill is the theme-aware soft purple (light lavender in
  /// light mode, deep purple in dark mode) rather than a literal [fillColor].
  final bool softPurpleFill;
}

class _Card {
  _Card({required this.mood});

  final _Mood mood;
  bool isRevealed = false;
  bool isMatched = false;
}

class _EmotionCardsGameScreenState extends State<EmotionCardsGameScreen> {
  static const int _pairCount = 6;
  static const Duration _flipBackDelay = Duration(milliseconds: 900);

  static const List<_Mood> _moods = [
    _Mood(
      id: 'anger',
      imageAsset: AppPlayImages.moodAnger,
      color: Color(0xFFF97066),
      fillColor: AppDangerColors.shade25,
      fillColorDark: AppDangerColors.shade950,
    ),
    _Mood(
      id: 'fear',
      imageAsset: AppPlayImages.moodFear,
      color: Color(0xFFB0A6DF),
      softPurpleFill: true,
    ),
    _Mood(
      id: 'sadness',
      imageAsset: AppPlayImages.moodSadness,
      color: Color(0xFF53B1FD),
      fillColor: AppInformationColors.shade25,
      fillColorDark: AppInformationColors.shade950,
    ),
    _Mood(
      id: 'disgust',
      imageAsset: AppPlayImages.moodDisgust,
      color: Color(0xFF47CD89),
      fillColor: AppSuccessColors.shade25,
      fillColorDark: AppSuccessColors.shade950,
    ),
    _Mood(
      id: 'surprise',
      imageAsset: AppPlayImages.moodSurprise,
      color: Color(0xFFF79009),
      fillColor: AppWarningColors.shade25,
      fillColorDark: AppWarningColors.shade950,
    ),
    _Mood(
      id: 'happy',
      imageAsset: AppPlayImages.moodHappy,
      color: Color(0xFFFEC84B),
      fillColor: AppWarningColors.shade25,
      fillColorDark: AppWarningColors.shade950,
    ),
  ];

  late List<_Card> _cards;
  int? _firstIndex;
  int? _secondIndex;
  bool _isLocked = false;
  int _matchedPairs = 0;
  Timer? _flipBackTimer;

  // Gentle inline feedback for the latest pair (match = correct, mismatch =
  // incorrect). Neutral hides the slot.
  GameFeedbackKind _feedbackKind = GameFeedbackKind.neutral;
  String _feedbackText = '';

  /// True once a win has been recorded, so dispose() doesn't also abandon.
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    _cards = _buildDeck();
    // Best-effort: open the backend completion lifecycle on game entry.
    ActivityApi.start(ActivitySlugs.emotionCards);
  }

  @override
  void dispose() {
    _flipBackTimer?.cancel();
    if (!_recorded) {
      // Left before winning — mark the completion abandoned.
      ActivityApi.abandon(ActivitySlugs.emotionCards);
    }
    super.dispose();
  }

  List<_Card> _buildDeck() {
    final List<_Card> deck = [
      for (final m in _moods) ...[_Card(mood: m), _Card(mood: m)],
    ];
    deck.shuffle(math.Random());
    return deck;
  }

  void _onTapCard(int index) {
    if (_isLocked) return;
    final _Card card = _cards[index];
    if (card.isRevealed || card.isMatched) return;

    setState(() {
      card.isRevealed = true;
      if (_firstIndex == null) {
        _firstIndex = index;
        // Starting a fresh pair — clear the previous turn's feedback.
        _feedbackKind = GameFeedbackKind.neutral;
        _feedbackText = '';
      } else {
        _secondIndex = index;
        _isLocked = true;
      }
    });

    if (_firstIndex != null && _secondIndex != null) {
      _resolveTurn();
    }
  }

  void _resolveTurn() {
    final _Card first = _cards[_firstIndex!];
    final _Card second = _cards[_secondIndex!];

    if (first.mood.id == second.mood.id) {
      setState(() {
        first.isMatched = true;
        second.isMatched = true;
        _matchedPairs += 1;
        _firstIndex = null;
        _secondIndex = null;
        _isLocked = false;
        _feedbackKind = GameFeedbackKind.correct;
        _feedbackText = GameFeedbackMessage.randomFor(GameFeedbackKind.correct);
      });
      if (_matchedPairs == _pairCount) {
        _recorded = true;
        // Best-effort: record the completed game with its matched-pair count.
        ActivityApi.complete(
          ActivitySlugs.emotionCards,
          result: <String, dynamic>{'matched_pairs': _matchedPairs},
        );
        Timer(const Duration(milliseconds: 600), _showWinScreen);
      }
    } else {
      setState(() {
        _feedbackKind = GameFeedbackKind.incorrect;
        _feedbackText =
            GameFeedbackMessage.randomFor(GameFeedbackKind.incorrect);
      });
      _flipBackTimer = Timer(_flipBackDelay, () {
        if (!mounted) return;
        setState(() {
          first.isRevealed = false;
          second.isRevealed = false;
          _firstIndex = null;
          _secondIndex = null;
          _isLocked = false;
        });
      });
    }
  }

  void _showWinScreen() {
    if (!mounted) return;
    final NavigatorState navigator = Navigator.of(context);
    navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SuccessScreen(
          title: 'أحسنت',
          subtitle: 'اكتملت أزواج المشاعر،\nومنحت نفسك لحظة ممتعة وهادئة 💜',
          buttonLabel: 'لعبة إضافية',
          secondaryButtonLabel: 'العودة للأنشطة',
          onContinue: () => navigator.pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const EmotionCardsGameScreen(),
            ),
          ),
          onSecondary: () => navigator.popUntil((route) => route.isFirst),
        ),
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
              AppTopNav(
                title: 'بطاقات المشاعر',
                onBack: () => showExitExerciseDialog(
                  context,
                  abandonSlug: ActivitySlugs.emotionCards,
                  popToRouteName: ActivityCategoryRoutes.playArea,
                  kind: ExitActivityKind.game,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'اقلب البطاقات وطابق الشعور',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: AppFontFamily.text,
                          fontSize: AppFontSizes.sm,
                          fontWeight: AppFontWeights.regular,
                          color: context.colors.shade500,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    _MatchCounter(matched: _matchedPairs, total: _pairCount),
                  ],
                ),
              ),
              // Fixed-height slot so the grid never shifts when feedback
              // appears/disappears.
              SizedBox(
                height: 44,
                child: Center(
                  child: _feedbackKind == GameFeedbackKind.neutral
                      ? const SizedBox.shrink()
                      : GameFeedbackMessage(
                          kind: _feedbackKind,
                          message: _feedbackText,
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.xl,
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                  ),
                  child: _CardsGrid(
                    cards: _cards,
                    onTap: _onTapCard,
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

class _MatchCounter extends StatelessWidget {
  const _MatchCounter({required this.matched, required this.total});

  final int matched;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$matched من $total أزواج',
        style: TextStyle(
          fontFamily: AppFontFamily.text,
          fontSize: AppFontSizes.xs,
          fontWeight: AppFontWeights.semibold,
          color: context.colors.shade600,
          height: 1.2,
        ),
      ),
    );
  }
}

class _CardsGrid extends StatelessWidget {
  const _CardsGrid({required this.cards, required this.onTap});

  final List<_Card> cards;
  final ValueChanged<int> onTap;

  static const int _columns = 3;

  @override
  Widget build(BuildContext context) {
    final int rows = (cards.length / _columns).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int r = 0; r < rows; r++) ...[
          if (r != 0) const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                for (int c = 0; c < _columns; c++) ...[
                  if (c != 0) const SizedBox(width: 16),
                  Expanded(
                    child: _MemoryCard(
                      card: cards[r * _columns + c],
                      onTap: () => onTap(r * _columns + c),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.card, required this.onTap});

  final _Card card;
  final VoidCallback onTap;

  static const double _radius = 14;

  @override
  Widget build(BuildContext context) {
    final bool faceUp = card.isRevealed || card.isMatched;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: faceUp
              ? _FaceUp(key: const ValueKey('up'), card: card)
              : const _FaceDown(key: ValueKey('down')),
        ),
      ),
    );
  }
}

class _FaceDown extends StatelessWidget {
  const _FaceDown({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_MemoryCard._radius),
        border: Border.all(
          color: AppPaletteButteryYellow.shade100,
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // Exact splash treatment: ONE warm gold dimming via alpha to fully
          // transparent — never mixing in an opaque dark stop, so there is no
          // seam. The card sits on the shade50 scaffold, so the transparent
          // tail reveals that same dark surface. Long fade (~60%) for a soft,
          // enlarged glow that eases into the background.
          stops: const [0.0, 0.06, 0.22, 0.60],
          colors: [
            AppPaletteButteryYellow.shade200,
            AppPaletteButteryYellow.shade200.withValues(alpha: 0.6),
            AppPaletteButteryYellow.shade200.withValues(alpha: 0.18),
            AppPaletteButteryYellow.shade200.withValues(alpha: 0.0),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        AppSvgIcons.mishkatIcon,
        width: 48,
        height: 48,
      ),
    );
  }
}

class _FaceUp extends StatelessWidget {
  const _FaceUp({super.key, required this.card});

  final _Card card;

  @override
  Widget build(BuildContext context) {
    final Color fill = card.mood.softPurpleFill
        ? context.purpleSoftFill(AppPalettePurple.shade600)
        : context.forDark(
            card.mood.fillColor!,
            card.mood.fillColorDark ?? card.mood.fillColor!,
          );
    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(_MemoryCard._radius),
        border: Border.all(color: card.mood.color, width: 1.5),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      child: Image.asset(
        card.mood.imageAsset,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}
