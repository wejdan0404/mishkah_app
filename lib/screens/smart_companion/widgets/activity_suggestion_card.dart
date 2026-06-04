import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants/app_icons.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../activity_suggestion_registry.dart';

/// Tappable card shown under an assistant message that recommended an in-app
/// activity. Recreates the old `ExerciseGuideCard` look (Material + InkWell,
/// AppRadius.lg, thin border, bold title + subtitle, side play-chevron),
/// painted from the activity's [colors]: a solid token background (no opacity),
/// shade300 border + subtitle, shade400 title + chevron.
class ActivitySuggestionCard extends StatelessWidget {
  const ActivitySuggestionCard({
    super.key,
    required this.colors,
    required this.label,
    required this.description,
    required this.onTap,
    this.ctaLabel,
  });

  /// The activity's card colours (background, border, title, subtitle).
  final ActivityColors colors;

  /// The activity name shown as the card title.
  final String label;

  /// The short line describing the activity, shown under the title.
  final String description;

  final VoidCallback onTap;

  /// When set (e.g. "ابدأ النشاط" in the AI chat), shows a CTA button at the
  /// bottom instead of the side play-chevron. Null keeps the chevron, so other
  /// callers (the home mood-activities sections) are unchanged.
  final String? ctaLabel;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
      button: true,
      label: '$label، $description',
      child: Material(
        // Solid token background in both themes — no transparency, so the
        // dark card tint reads at full strength over the screen background.
        color: context.forDark(
          colors.background,
          colors.backgroundDark,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colors.border, width: 0.5),
            ),
            // Title/description and the (non-tappable) play chevron are visual
            // only; the whole card is one button labelled above.
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: AppFontFamily.text,
                                fontSize: AppFontSizes.xs,
                                fontWeight: AppFontWeights.bold,
                                color: context.forDark(
                                  colors.title,
                                  colors.titleDark,
                                ),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              description,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: AppFontFamily.text,
                                fontSize: AppFontSizes.xxs,
                                fontWeight: AppFontWeights.regular,
                                color: context.forDark(
                                  colors.subtitle,
                                  colors.subtitleDark,
                                ),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (ctaLabel == null) ...[
                        const SizedBox(width: AppSpacing.lg),
                        _PlayButton(
                          color: context.forDark(colors.title, colors.titleDark),
                        ),
                      ],
                    ],
                  ),
                  if (ctaLabel != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _CtaButton(
                      label: ctaLabel!,
                      // Mishkat primary purple — the same action color as every
                      // other "ابدأ" button in the app (activities card, focus
                      // start, save, add-task), so the chat suggestion matches
                      // the rest of the cards instead of a loud per-activity
                      // blue/red.
                      color: AppPalettePurple.shade200,
                    ),
                  ],
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

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'تشغيل التمرين',
      child: SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: SvgPicture.asset(
            AppSvgIcons.playChevron,
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

/// Full-width CTA at the bottom of the chat suggestion card ("ابدأ النشاط ←").
/// Visual only — the whole card is the tappable button labelled above. Filled
/// with the activity's accent so it stays on-theme (no extra/strong colours).
class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xs,
              fontWeight: AppFontWeights.bold,
              color: AppNeutralColors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          SvgPicture.asset(
            AppSvgIcons.arrowLeft,
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              AppNeutralColors.white,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}
