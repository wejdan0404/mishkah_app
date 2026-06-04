import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// A row of fixed-count single-digit boxes with auto-advance focus. Calls
/// [onCompleted] with the joined code once every box is filled.
///
/// Shared between the email-change flow in تعديل الملف الشخصي and the
/// نسيت كلمة المرور flow so both inputs look and behave identically.
class OtpInput extends StatefulWidget {
  const OtpInput({
    required this.onCompleted,
    this.enabled = true,
    super.key,
  });

  final ValueChanged<String> onCompleted;
  final bool enabled;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  static const int _length = 4;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers =
        List<TextEditingController>.generate(_length, (_) => TextEditingController());
    _nodes = List<FocusNode>.generate(_length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final TextEditingController c in _controllers) {
      c.dispose();
    }
    for (final FocusNode n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < _length - 1) {
      _nodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    final String code = _controllers.map((TextEditingController c) => c.text).join();
    if (code.length == _length) {
      _nodes[index].unfocus();
      widget.onCompleted(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          for (int i = 0; i < _length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.md),
            Expanded(child: _box(context, i)),
          ],
        ],
      ),
    );
  }

  Widget _box(BuildContext context, int index) {
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    return SizedBox(
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _nodes[index],
        enabled: widget.enabled,
        autofocus: index == 0,
        onChanged: (String v) => _onChanged(index, v),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(
          fontFamily: AppFontFamily.text,
          fontSize: AppFontSizes.md,
          fontWeight: AppFontWeights.medium,
          color: context.colors.shade700,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: context.colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(
              color: context.colors.shade300,
              width: 0.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: const BorderSide(
              color: AppPalettePurple.shade300,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
