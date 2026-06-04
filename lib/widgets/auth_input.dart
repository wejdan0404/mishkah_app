import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Rounded, icon-leading text field used across the auth screens (sign in,
/// forgot password). Focus and error states recolor the border + icon. RTL.
///
/// Shared so every auth input looks and behaves identically — do not fork.
class AuthInput extends StatefulWidget {
  const AuthInput({
    required this.hint,
    required this.iconAsset,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.error,
    super.key,
  });

  final String hint;
  final String iconAsset;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final String? error;

  @override
  State<AuthInput> createState() => _AuthInputState();
}

class _AuthInputState extends State<AuthInput> {
  static const double _minHeight = 44;
  static const double _minWidth = 200;
  static const double _iconSize = 20;

  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.error != null;
    final bool focused = _focusNode.hasFocus;

    final Color accentColor = hasError
        ? AppDangerColors.shade500
        : focused
        ? AppPalettePurple.shade300
        : context.colors.shade400;

    final Color textColor = focused
        ? context.colors.shade500
        : context.colors.shade700;

    final Border border = (hasError || focused)
        ? Border.all(color: accentColor, width: 1)
        : Border.all(color: context.colors.shade300, width: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: _minHeight,
            minWidth: _minWidth,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: border,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  widget.iconAsset,
                  width: _iconSize,
                  height: _iconSize,
                  colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: TextField(
                    focusNode: _focusNode,
                    controller: widget.controller,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    obscureText: widget.obscureText,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    cursorColor: AppPalettePurple.shade300,
                    style: TextStyle(
                      fontFamily: AppFontFamily.text,
                      fontSize: AppFontSizes.sm,
                      fontWeight: AppFontWeights.regular,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: TextStyle(
                        fontFamily: AppFontFamily.text,
                        fontSize: AppFontSizes.sm,
                        fontWeight: AppFontWeights.regular,
                        color: context.colors.shade400,
                      ),
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _ErrorMessage(message: widget.error!),
          ),
        ],
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  static const double _iconSize = 16;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: _iconSize,
            color: AppDangerColors.shade500,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: AppFontFamily.text,
                fontSize: AppFontSizes.xxs,
                fontWeight: AppFontWeights.regular,
                color: AppDangerColors.shade500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
