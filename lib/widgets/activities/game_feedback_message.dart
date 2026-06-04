import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// The three feedback states a game interaction can report.
enum GameFeedbackKind { correct, incorrect, neutral }

/// Short, warm, calm feedback shown near a game's interaction area.
///
/// State is conveyed through BOTH an icon and text (never colour alone), the
/// tone is non-competitive, and it never uses failure language — a wrong move
/// is framed as "try again", in line with Mishkat's emotionally-safe voice.
class GameFeedbackMessage extends StatelessWidget {
  const GameFeedbackMessage({
    super.key,
    required this.kind,
    required this.message,
  });

  final GameFeedbackKind kind;
  final String message;

  /// Warm confirmations for a correct move.
  static const List<String> correctMessages = <String>[
    'صح! جبتها',
    'تمام! اختيارك صحيح',
    'أحسنت، كذا مضبوط',
    'رائع! نكمّل',
  ];

  /// Gentle, non-judgmental nudges for a wrong move.
  static const List<String> incorrectMessages = <String>[
    'قريبة! نجرّب مرة ثانية',
    'مو مشكلة، نجرّب من جديد',
    'محاولة حلوة، نعيدها بهدوء؟',
    'ما ضبطت للحين، بس قريبة',
  ];

  /// Pick a random message for [kind] so callers don't duplicate the copy.
  /// Returns an empty string for [GameFeedbackKind.neutral].
  static String randomFor(GameFeedbackKind kind) {
    switch (kind) {
      case GameFeedbackKind.correct:
        return correctMessages[Random().nextInt(correctMessages.length)];
      case GameFeedbackKind.incorrect:
        return incorrectMessages[Random().nextInt(incorrectMessages.length)];
      case GameFeedbackKind.neutral:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool correct = kind == GameFeedbackKind.correct;
    final Color accent =
        correct ? AppSuccessColors.shade600 : AppPalettePurple.shade300;
    final IconData icon =
        correct ? Icons.check_circle_rounded : Icons.refresh_rounded;

    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(child: Icon(icon, size: 18, color: accent)),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.xs,
                  fontWeight: AppFontWeights.semibold,
                  color: accent,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
