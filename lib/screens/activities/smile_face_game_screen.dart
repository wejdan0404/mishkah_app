import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../constants/app_play_images.dart';
import '../../core/activities/activity_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/activities/game_feedback_message.dart';
import '../../widgets/nav/app_top_nav.dart';
import '../auth/success_screen.dart';
import 'understand_feelings_progress.dart';

class SmileFaceGameScreen extends StatefulWidget {
  const SmileFaceGameScreen({super.key});

  @override
  State<SmileFaceGameScreen> createState() => _SmileFaceGameScreenState();
}

class _SmileFaceGameScreenState extends State<SmileFaceGameScreen> {
  static const int _totalRounds = 3;
  static const int _cardsPerRound = 12;

  static const List<String> _distractorAssets = [
    AppPlayImages.moodAnger,
    AppPlayImages.moodFear,
    AppPlayImages.moodSadness,
    AppPlayImages.moodDisgust,
    AppPlayImages.moodSurprise,
  ];

  static const String _smileAsset = AppPlayImages.moodHappy;

  int _completedRounds = 0;
  late List<_SmileCard> _cards;
  bool _isLocked = false;
  final math.Random _rng = math.Random();

  // Gentle inline feedback (correct = found the smile, incorrect = a distractor
  // tap). Neutral hides the slot.
  GameFeedbackKind _feedbackKind = GameFeedbackKind.neutral;
  String _feedbackText = '';

  /// True once a win has been recorded, so dispose() doesn't also abandon.
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    _cards = _buildRound();
    // Best-effort: open the backend completion lifecycle on game entry.
    ActivityApi.start(ActivitySlugs.smileFace);
  }

  @override
  void dispose() {
    if (!_recorded) {
      // Left before completing all rounds — mark the completion abandoned.
      ActivityApi.abandon(ActivitySlugs.smileFace);
    }
    super.dispose();
  }

  List<_SmileCard> _buildRound() {
    final List<_SmileCard> cards = [
      _SmileCard(imageAsset: _smileAsset, isSmile: true),
      for (int i = 0; i < _cardsPerRound - 1; i++)
        _SmileCard(
          imageAsset: _distractorAssets[_rng.nextInt(_distractorAssets.length)],
          isSmile: false,
        ),
    ];
    cards.shuffle(_rng);
    return cards;
  }

  static const Duration _transitionDuration = Duration(milliseconds: 500);

  void _onTapCard(int index) {
    if (_isLocked) return;
    final _SmileCard card = _cards[index];
    if (!card.isSmile) {
      // Wrong pick — a gentle nudge, no lock and no penalty so the user can
      // simply try again.
      setState(() {
        _feedbackKind = GameFeedbackKind.incorrect;
        _feedbackText =
            GameFeedbackMessage.randomFor(GameFeedbackKind.incorrect);
      });
      return;
    }

    _isLocked = true;
    final int next = _completedRounds + 1;
    if (next >= _totalRounds) {
      _recorded = true;
      // Best-effort: record the completed game with its rounds count. `next`
      // is the true number of rounds finished (the field isn't bumped on the
      // winning tap before the success screen is shown).
      ActivityApi.complete(
        ActivitySlugs.smileFace,
        result: <String, dynamic>{'rounds_completed': next},
      );
      _showWinScreen();
      return;
    }

    setState(() {
      _completedRounds = next;
      _cards = _buildRound();
      _feedbackKind = GameFeedbackKind.correct;
      _feedbackText = GameFeedbackMessage.randomFor(GameFeedbackKind.correct);
    });

    Future<void>.delayed(_transitionDuration, () {
      if (!mounted) return;
      setState(() {
        _isLocked = false;
      });
    });
  }

  void _showWinScreen() {
    final NavigatorState navigator = Navigator.of(context);
    navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SuccessScreen(
          title: 'أحسنت',
          subtitle:
              'وجدت كل الوجوه المبتسمة،\nوأعدت تركيزك بهدوء وثبات 💜',
          buttonLabel: 'لعبة إضافية',
          secondaryButtonLabel: 'العودة للأنشطة',
          onContinue: () => navigator.pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => const SmileFaceGameScreen(),
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
                title: 'الوجه المبتسم',
                onBack: () => showExitExerciseDialog(
                  context,
                  abandonSlug: ActivitySlugs.smileFace,
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
                        'لاحظ الوجه المبتسم بين الزحمة',
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
                    _RoundCounter(
                      current: _completedRounds,
                      total: _totalRounds,
                    ),
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
                  child: AnimatedSwitcher(
                    duration: _transitionDuration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.94,
                            end: 1.0,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _SmileGrid(
                      key: ValueKey<int>(_completedRounds),
                      cards: _cards,
                      onTap: _onTapCard,
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

class _SmileCard {
  _SmileCard({required this.imageAsset, required this.isSmile});

  final String imageAsset;
  final bool isSmile;
}

class _RoundCounter extends StatelessWidget {
  const _RoundCounter({required this.current, required this.total});

  final int current;
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
        '$current من $total جولات',
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

class _SmileGrid extends StatelessWidget {
  const _SmileGrid({
    super.key,
    required this.cards,
    required this.onTap,
  });

  final List<_SmileCard> cards;
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
                    child: _SmileTile(
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

class _SmileTile extends StatelessWidget {
  const _SmileTile({required this.card, required this.onTap});

  final _SmileCard card;
  final VoidCallback onTap;

  static const double _radius = 14;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(_radius);
    return Material(
      color: context.colors.white,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: context.colors.shade200, width: 1),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            card.imageAsset,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
