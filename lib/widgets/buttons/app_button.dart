import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.trailing,
    this.expand = false,
    this.isLoading = false,
    this.borderRadius = AppRadius.lg,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final bool expand;
  final bool isLoading;
  final double borderRadius;

  static const double _height = 44;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(borderRadius);
    final bool nonTappable = onPressed == null || isLoading;
    final bool dimmed = onPressed == null && !isLoading;

    final Color backgroundColor =
        dimmed ? context.colors.shade200 : AppPalettePurple.shade200;
    final Color foregroundColor =
        dimmed ? context.colors.shade400 : AppNeutralColors.white;
    final List<BoxShadow> boxShadow = dimmed ? AppShadows.xs : AppShadows.sm;

    final Widget inner = isLoading
        ? Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [_ButtonDots()],
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.md),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontWeight: AppFontWeights.bold,
                  fontSize: AppFontSizes.sm,
                  color: foregroundColor,
                  height: 1.25,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.md),
                trailing!,
              ],
            ],
          );

    final Widget content = IconTheme.merge(
      data: IconThemeData(color: foregroundColor),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        // The visible label/dots are excluded so the Semantics label below is
        // read once, with the correct enabled/loading state.
        child: ExcludeSemantics(child: inner),
      ),
    );

    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: !nonTappable,
        label: isLoading ? 'جاري التحميل' : label,
        child: SizedBox(
          height: _height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: radius,
              boxShadow: boxShadow,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: radius,
              child: InkWell(
                onTap: nonTappable ? null : onPressed,
                borderRadius: radius,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonDots extends StatefulWidget {
  const _ButtonDots();

  @override
  State<_ButtonDots> createState() => _ButtonDotsState();
}

class _ButtonDotsState extends State<_ButtonDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const double _dotSize = 7;
  static const Duration _cycle = Duration(milliseconds: 1200);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _cycle);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduced = MediaQuery.of(context).disableAnimations;
    if (reduced) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0),
            const SizedBox(width: 4),
            _dot(1),
            const SizedBox(width: 4),
            _dot(2),
          ],
        );
      },
    );
  }

  Widget _dot(int index) {
    final double t = (_controller.value * 3 - index).clamp(0.0, 1.0);
    final double activeness = (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
    final Color color = Color.lerp(
      AppNeutralColors.white.withValues(alpha: 0.4),
      AppNeutralColors.white,
      activeness,
    )!;
    return Container(
      width: _dotSize,
      height: _dotSize,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
