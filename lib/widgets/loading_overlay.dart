import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_loader.dart';

/// Full-screen first-load veil.
///
/// While [loading] is true, lays a faint translucent scrim with a centered
/// [AppLoader] over [child]; the content stays faintly visible behind it. The
/// scrim swallows taps so the user can't poke half-loaded content — wrap only
/// the screen *body*, leaving shared chrome (bottom nav, a back button) outside
/// the veil so navigation keeps working during the wait.
///
/// This is a pure presentational widget: the caller decides when [loading]
/// flips. Service-driven screens wrap it in an `AnimatedBuilder` on the
/// relevant `ChangeNotifier`; screens that own a local `_isLoading` just pass
/// it and rebuild via `setState`. Screens with no async data never wrap it (or
/// pass loading:false), so the veil never shows for them — e.g. حسابي.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.loading,
    required this.child,
  });

  final bool loading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (loading)
          Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: context.colors.shade50.withValues(alpha: 0.7),
                child: const Center(child: AppLoader(size: 56)),
              ),
            ),
          ),
      ],
    );
  }
}
