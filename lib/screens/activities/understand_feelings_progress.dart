import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../constants/app_icons.dart';
import '../../core/activities/activity_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';

class ExerciseStep {
  const ExerciseStep({required this.number, required this.label});

  final String number;
  final String label;
}

class ExerciseProgressCard extends StatelessWidget {
  const ExerciseProgressCard({
    super.key,
    required this.currentStep,
    required this.steps,
  });

  final int currentStep;
  final List<ExerciseStep> steps;

  static const double _frameWidth = 50;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.purpleSoftFill(AppPalettePurple.shade600),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalettePurple.shade500, width: 0.5),
        boxShadow: AppShadows.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Circles + connecting lines — lines flex to fill the full width.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                if (i != 0)
                  Expanded(
                    child: SizedBox(
                      height: 2,
                      child: ColoredBox(
                        color: currentStep > i - 1
                            ? AppPalettePurple.shade300
                            : AppPalettePurple.shade500,
                      ),
                    ),
                  ),
                SizedBox(
                  width: _frameWidth,
                  child: Center(
                    child: _StepCircle(
                      number: steps[i].number,
                      reached: i <= currentStep,
                      completed: i < currentStep,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < steps.length; i++)
                SizedBox(
                  width: _frameWidth,
                  child: Text(
                    steps[i].label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontFamily: AppFontFamily.title,
                      fontSize: AppFontSizes.xxs,
                      fontWeight: AppFontWeights.bold,
                      color: i <= currentStep
                          ? context.colors.shade700
                          : context.colors.shade400,
                      height: 1.2,
                      fontFeatures: const [
                        FontFeature('salt'),
                        FontFeature('swsh'),
                        FontFeature('ss05'),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.number,
    required this.reached,
    required this.completed,
  });

  final String number;

  /// True for the current step and every step before it — controls the
  /// circle's filled (darker) appearance.
  final bool reached;

  /// True only for steps strictly before the current one — shows a check
  /// mark in place of the number.
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: reached
            ? AppPalettePurple.shade300
            : AppPalettePurple.shade500,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: AppPalettePurple.shade500,
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: completed
          ? Icon(
              Icons.check_rounded,
              size: 16,
              color: context.forDark(
                AppNeutralColors.white,
                AppNeutralColors.shade700,
              ),
            )
          : Text(
              number,
              style: TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.xxs,
                fontWeight: AppFontWeights.bold,
                color: context.forDark(
                  AppNeutralColors.white,
                  AppNeutralColors.shade700,
                ),
                height: 1,
              ),
            ),
    );
  }
}

const List<ExerciseStep> exerciseSteps = [
  ExerciseStep(number: '01', label: 'شعورك'),
  ExerciseStep(number: '02', label: 'مكانه'),
  ExerciseStep(number: '03', label: 'شدته'),
  ExerciseStep(number: '04', label: 'الملخص'),
  ExerciseStep(number: '05', label: 'احتياجك'),
];

/// Circular X button used as the leading action in the exercise's top nav
/// once the user has committed to the flow. Tapping it opens a confirmation
/// modal asking whether they want to abandon the exercise.
class ExerciseCloseButton extends StatelessWidget {
  const ExerciseCloseButton({super.key, required this.onTap});

  final VoidCallback onTap;

  static const double _size = 32;
  static const double _iconSize = 14;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.white,
      shape: const CircleBorder(),
      shadowColor: const Color(0x1A101828),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: _size,
          height: _size,
          child: Center(
            child: SvgPicture.asset(
              AppSvgIcons.closeSmall,
              width: _iconSize,
              height: _iconSize,
              colorFilter: ColorFilter.mode(
                context.colors.shade600,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Whether the in-progress flow being exited is an exercise (محطة التوازن) or
/// a game (منطقة اللعب). Only the activity noun changes — every exit modal
/// keeps the same wording, layout, and button styling.
enum ExitActivityKind {
  exercise('التمرين', 'للتمرين', 'تمرينك'),
  game('اللعبة', 'للعبة', 'لعبتك');

  const ExitActivityKind(this.noun, this.returnTo, this.possessive);

  /// Noun used after "تنهي" / "إنهاء" (التمرين / اللعبة).
  final String noun;

  /// Suffix used after "العودة" (للتمرين / للعبة).
  final String returnTo;

  /// Possessive form used in the dialog title (تمرينك / لعبتك).
  final String possessive;
}

/// Shows a centered confirmation modal asking the user if they want to leave
/// the in-progress exercise. Styled to match the focus-session "end session"
/// modal so the destructive flow looks the same across the app.
Future<void> showExitExerciseDialog(
  BuildContext context, {
  String? abandonSlug,
  String? popToRouteName,
  ExitActivityKind kind = ExitActivityKind.exercise,
}) {
  final NavigatorState navigator = Navigator.of(context);
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return _ExitConfirmationDialog(
        kind: kind,
        onExit: () {
          // Best-effort: mark the in-progress completion abandoned. The slug
          // identifies which exercise flow is being exited (the dialog itself
          // is shared across exercises).
          if (abandonSlug != null) {
            ActivityApi.abandon(abandonSlug);
          }
          Navigator.of(dialogContext).pop();
          // Pop back to the activity's own category hub (e.g. the balance
          // station or play area) when known; otherwise fall back to root.
          navigator.popUntil(
            (route) =>
                (popToRouteName != null &&
                    route.settings.name == popToRouteName) ||
                route.isFirst,
          );
        },
        onContinue: () => Navigator.of(dialogContext).pop(),
      );
    },
  );
}

class _ExitConfirmationDialog extends StatelessWidget {
  const _ExitConfirmationDialog({
    required this.kind,
    required this.onExit,
    required this.onContinue,
  });

  final ExitActivityKind kind;
  final VoidCallback onExit;
  final VoidCallback onContinue;

  static const double _width = 325;
  static const double _iconSize = 80;

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
                Center(
                  child: SvgPicture.asset(
                    AppSvgIcons.focusEndSessionModal,
                    width: _iconSize,
                    height: _iconSize,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Text(
                  'تبي تنهي ${kind.possessive}؟',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.thmanyahHeading(context).copyWith(
                    fontSize: AppFontSizes.sm,
                    color: context.colors.shade600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'لو طلعت الحين يبدأ تقدّمك من جديد،\nوتقدر ترجع له وقت ما تكون جاهز.',
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
                    Expanded(
                      child: _ExitDialogPrimaryButton(
                        label: 'إنهاء ${kind.noun}',
                        onTap: onExit,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _ExitDialogSecondaryButton(
                        label: 'العودة ${kind.returnTo}',
                        onTap: onContinue,
                      ),
                    ),
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

class _ExitDialogPrimaryButton extends StatelessWidget {
  const _ExitDialogPrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: AppDangerColors.shade500,
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

class _ExitDialogSecondaryButton extends StatelessWidget {
  const _ExitDialogSecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

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
            border: Border.all(color: context.colors.shade300, width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xs,
              fontWeight: AppFontWeights.semibold,
              color: context.colors.shade400,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Light-yellow tip toast used across the "understand your feelings"
/// exercise to surface a short hint to the user.
class ExerciseInfoToast extends StatelessWidget {
  const ExerciseInfoToast({super.key, required this.text, this.minHeight});

  final String text;

  /// When set, the toast keeps this minimum height and vertically centres its
  /// text, so phrases of different lengths all render in a same-sized box
  /// instead of the box growing/shrinking per phrase. Null = hug the text
  /// (unchanged behaviour for other screens).
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          minHeight == null ? null : BoxConstraints(minHeight: minHeight!),
      alignment: minHeight == null ? null : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppPalettePurple.shade300,
          width: 0.5,
        ),
        boxShadow: AppShadows.xs,
      ),
      child: Text(
        '💡 $text',
        textAlign: TextAlign.right,
        style: TextStyle(
          fontFamily: AppFontFamily.text,
          fontSize: AppFontSizes.xs,
          fontWeight: AppFontWeights.regular,
          color: context.colors.shade600,
          height: 1.5,
        ),
      ),
    );
  }
}
