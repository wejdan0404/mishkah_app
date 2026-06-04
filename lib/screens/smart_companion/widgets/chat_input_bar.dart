import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants/app_icons.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/app_loader.dart';
import 'mic_cancel_button.dart';

enum ChatInputMode { idle, listening, loading }

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.mode,
    required this.onStartListening,
    required this.onCancelListening,
    required this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final ChatInputMode mode;
  final VoidCallback onStartListening;
  final VoidCallback onCancelListening;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String>? onChanged;

  String get _placeholder {
    switch (mode) {
      case ChatInputMode.idle:
        return 'اكتب أو اضغط للتحدث';
      case ChatInputMode.listening:
        return 'يستمع لك الحين ..';
      case ChatInputMode.loading:
        return 'يحوّل صوتك ..';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.shade100,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xl)),
        border: Border.fromBorderSide(
          BorderSide(color: context.colors.shade200, width: 0.5),
        ),
      ),
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.lg,
        end: AppSpacing.md,
        top: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _textField(context)),
          const SizedBox(width: AppSpacing.lg),
          _leadingControl(context),
        ],
      ),
    );
  }

  Widget _leadingControl(BuildContext context) {
    switch (mode) {
      case ChatInputMode.listening:
        return MicCancelButton(onTap: onCancelListening);
      case ChatInputMode.loading:
        return const SizedBox(
          width: 44,
          height: 44,
          child: Center(child: AppLoader(size: 32)),
        );
      case ChatInputMode.idle:
        return ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final bool hasText = value.text.trim().isNotEmpty;
            if (hasText) {
              return _ActionButton(
                icon: AppSvgIcons.sendArrow,
                label: 'إرسال',
                iconSize: 18,
                onTap: () => onSubmitted(value.text.trim()),
              );
            }
            return _ActionButton(
              icon: AppSvgIcons.mic,
              label: 'ابدأ التسجيل الصوتي',
              iconSize: 32,
              onTap: onStartListening,
            );
          },
        );
    }
  }

  Widget _textField(BuildContext context) {
    final bool enabled = mode == ChatInputMode.idle;
    return TextField(
      controller: controller,
      enabled: enabled,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      textInputAction: TextInputAction.send,
      onChanged: onChanged,
      onSubmitted: (value) {
        if (value.trim().isEmpty) return;
        onSubmitted(value.trim());
      },
      style: TextStyle(
        fontFamily: AppFontFamily.text,
        fontSize: AppFontSizes.sm,
        fontWeight: AppFontWeights.regular,
        color: context.colors.shade600,
        height: 1.4,
      ),
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: _placeholder,
        hintTextDirection: TextDirection.rtl,
        hintStyle: TextStyle(
          fontFamily: AppFontFamily.text,
          fontSize: AppFontSizes.sm,
          fontWeight: AppFontWeights.regular,
          color: context.colors.shade500,
          height: 1.4,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconSize = 20,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;
  final double iconSize;

  static const double _size = 32;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Material(
            color: AppPalettePurple.shade300,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: _size,
                height: _size,
                child: Center(
                  child: SvgPicture.asset(
                    icon,
                    width: iconSize,
                    height: iconSize,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
