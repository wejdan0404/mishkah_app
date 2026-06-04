import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

/// Themed text styles. Each is a method taking [BuildContext] so the text
/// color resolves from the active theme (`context.colors`) and therefore flips
/// between light and dark. Call as `AppTextStyles.thmanyahDisplay(context)`.
///
/// Light-mode colors are identical to the previous constants, so migrating a
/// call site (`AppTextStyles.thmanyahDisplay` → `AppTextStyles.thmanyahDisplay(context)`)
/// leaves light mode pixel-identical and only adds dark-mode support. A call
/// site that needs a non-neutral color (brand/danger) keeps its own
/// `.copyWith(color: ...)` override, which still wins.
class AppTextStyles {
  const AppTextStyles._();

  // OpenType features for Thmanyah Serif. Single source of truth lives in
  // AppFontFamily.titleFeatures so inline TextStyles can share it.
  static const List<FontFeature> _thmanyahFeatures = AppFontFamily.titleFeatures;

  static TextStyle thmanyahDisplay(BuildContext context) => TextStyle(
    fontFamily: AppFontFamily.title,
    fontSize: AppFontSizes.lg,
    fontWeight: AppFontWeights.bold,
    color: context.colors.shade700,
    height: 1.2,
    letterSpacing: 0,
    fontFeatures: _thmanyahFeatures,
  );

  static TextStyle thmanyahTitle(BuildContext context) => TextStyle(
    fontFamily: AppFontFamily.title,
    fontSize: AppFontSizes.lg,
    fontWeight: AppFontWeights.bold,
    color: context.colors.shade700,
    height: 1.35,
    letterSpacing: 0,
    fontFeatures: _thmanyahFeatures,
  );

  static TextStyle thmanyahHeading(BuildContext context) => TextStyle(
    fontFamily: AppFontFamily.title,
    fontSize: AppFontSizes.md,
    fontWeight: AppFontWeights.bold,
    color: context.colors.shade700,
    height: 1.35,
    letterSpacing: 0,
    fontFeatures: _thmanyahFeatures,
  );

  static TextStyle thmanyahBody(BuildContext context) => TextStyle(
    fontFamily: AppFontFamily.title,
    fontSize: AppFontSizes.sm,
    fontWeight: AppFontWeights.regular,
    color: context.colors.shade600,
    height: 1.5,
    letterSpacing: 0,
    fontFeatures: _thmanyahFeatures,
  );

  static TextStyle thmanyahCaption(BuildContext context) => TextStyle(
    fontFamily: AppFontFamily.title,
    fontSize: AppFontSizes.xs,
    fontWeight: AppFontWeights.regular,
    color: context.colors.shade500,
    height: 1.4,
    letterSpacing: 0,
    fontFeatures: _thmanyahFeatures,
  );
}
