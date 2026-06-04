import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../constants/app_icons.dart';
import '../theme/app_tokens.dart';

/// App-wide loading indicator. Wraps the shared loader Lottie tinted to the
/// brand purple so every waiting state looks the same — pass [size] to fit
/// the slot. For screen-blocking waits use [showAppLoaderOverlay] below.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(
        AppPalettePurple.shade300,
        BlendMode.srcIn,
      ),
      child: Lottie.asset(
        AppLottie.loader,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

OverlayEntry? _currentLoaderOverlay;

/// Shows a screen-wide dim + centered [AppLoader] for blocking async actions
/// (saves, navigations that fetch). Call [hideAppLoaderOverlay] when done.
/// Idempotent: a second call while one is already showing is a no-op.
void showAppLoaderOverlay(BuildContext context) {
  if (_currentLoaderOverlay?.mounted ?? false) return;
  final OverlayState overlay = Overlay.of(context);
  final OverlayEntry entry = OverlayEntry(
    builder: (_) => const _AppLoaderScrim(),
  );
  _currentLoaderOverlay = entry;
  overlay.insert(entry);
}

/// Removes the loader overlay if one is showing. Safe to call repeatedly.
void hideAppLoaderOverlay() {
  if (_currentLoaderOverlay?.mounted ?? false) {
    _currentLoaderOverlay!.remove();
  }
  _currentLoaderOverlay = null;
}

class _AppLoaderScrim extends StatelessWidget {
  const _AppLoaderScrim();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.4),
          child: const Center(child: AppLoader(size: 64)),
        ),
      ),
    );
  }
}
