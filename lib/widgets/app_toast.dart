import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

enum AppToastType { success, error }

/// Toast notification matching the Figma "toast" component: a white pill with a
/// colored status icon (green check / red alert) and a right-aligned message.
/// Use [showAppToast] to display it; [AppToast] is the bare visual.
class AppToast extends StatelessWidget {
  const AppToast({
    super.key,
    required this.message,
    this.type = AppToastType.success,
  });

  final String message;
  final AppToastType type;

  // Figma "Neutral-Colors-500" for toast text — kept as the design's exact
  // value (already used elsewhere in the app), not the token shade500.
  static const Color _textColor = Color(0xFF223336);

  bool get _isSuccess => type == AppToastType.success;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.colors.shade200, width: 1),
          boxShadow: AppShadows.md,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Deep shade950 in dark mode, pale shade50 in light mode.
                color: _isSuccess
                    ? context.forDark(
                        AppSuccessColors.shade50,
                        AppSuccessColors.shade950,
                      )
                    : context.forDark(
                        AppDangerColors.shade50,
                        AppDangerColors.shade950,
                      ),
              ),
              child: SvgPicture.asset(
                _isSuccess ? AppSvgIcons.toastSuccess : AppSvgIcons.toastError,
                width: 16,
                height: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: AppFontFamily.text,
                  fontSize: AppFontSizes.sm,
                  fontWeight: AppFontWeights.regular,
                  // The pill bg is white in light / dark-grey in dark mode, so a
                  // fixed dark teal turns unreadable in dark. Keep the design's
                  // teal in light, swap to high-contrast ink (white) in dark.
                  color: context.forDark(_textColor, context.colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Calm prompt shown when a guest (browse-only) tries an action that saves to
/// the account. Keeps the message gentle and Arabic — never a raw 401/backend
/// error.
void showLoginRequiredToast(BuildContext context) {
  showAppToast(
    context,
    'سجّل الدخول لحفظ بياناتك.',
    type: AppToastType.error,
  );
}

OverlayEntry? _currentToast;

/// Shows [AppToast] as a top-anchored overlay that slides + fades in below the
/// status bar, holds for [duration], then animates out. Replaces any toast
/// already on screen so they never stack.
void showAppToast(
  BuildContext context,
  String message, {
  AppToastType type = AppToastType.success,
  Duration duration = const Duration(seconds: 3),
}) {
  final OverlayState overlay = Overlay.of(context);
  if (_currentToast?.mounted ?? false) _currentToast!.remove();

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ToastOverlay(
      message: message,
      type: type,
      duration: duration,
      onDismissed: () {
        if (entry.mounted) entry.remove();
        if (identical(_currentToast, entry)) _currentToast = null;
      },
    ),
  );
  _currentToast = entry;
  overlay.insert(entry);
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final AppToastType type;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.of(context).padding.top + AppSpacing.md;
    return Positioned(
      top: top,
      left: AppSpacing.xl,
      right: AppSpacing.xl,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Align(
              child: Material(
                color: Colors.transparent,
                child: AppToast(message: widget.message, type: widget.type),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
