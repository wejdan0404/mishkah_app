import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.child,
    this.borderColor,
    this.padding,
    this.onTap,
    this.borderRadius,
    this.boxShadow,
    this.borderWidth,
    this.color,
    this.semanticLabel,
  });

  final Widget child;
  final Color? borderColor;

  /// Optional spoken label when the card is tappable. When null the card's
  /// own text content is read aloud instead.
  final String? semanticLabel;

  /// Surface fill. Defaults to the themed card surface ([AppColors.white]).
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? borderRadius;

  /// Drop shadow override. Defaults to [AppShadows.xs] when null.
  final List<BoxShadow>? boxShadow;

  /// Border stroke width. Defaults to 0.5 when null.
  final double? borderWidth;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius =
        BorderRadius.circular(borderRadius ?? AppRadius.xl);

    final Widget card = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: color ?? context.colors.white,
        borderRadius: radius,
        border: Border.all(
          color: borderColor ?? context.colors.shade200,
          width: borderWidth ?? 0.5,
        ),
        boxShadow: boxShadow ?? AppShadows.xs,
      ),
      child: child,
    );

    if (onTap == null) return card;

    // When an explicit label is given, hide the child text so it isn't read
    // twice; otherwise let MergeSemantics fold the card's own text into the
    // single button node.
    final Widget tappableChild =
        semanticLabel == null ? card : ExcludeSemantics(child: card);

    return MergeSemantics(
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: tappableChild,
          ),
        ),
      ),
    );
  }
}
