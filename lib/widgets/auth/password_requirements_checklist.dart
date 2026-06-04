import 'package:flutter/material.dart';

import '../../core/auth/password_validator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';

/// Live checklist of the signup password rules. Pass the current password
/// string; each rule shows met/unmet via BOTH an icon and a colour (never
/// colour alone) so it stays readable for everyone. Reads its rules from
/// [PasswordValidator] so the list and the submit guard never drift apart.
class PasswordRequirementsChecklist extends StatelessWidget {
  const PasswordRequirementsChecklist({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Text(
            'كلمة المرور يجب أن تحتوي على:',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: AppFontFamily.text,
              fontSize: AppFontSizes.xxs,
              fontWeight: AppFontWeights.medium,
              color: context.colors.shade600,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final PasswordRule rule in PasswordValidator.rules)
          _RuleRow(label: rule.label, met: rule.test(password)),
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final Color color =
        met ? AppSuccessColors.shade500 : context.colors.shade400;
    return MergeSemantics(
      child: Semantics(
        label: '$label، ${met ? 'مكتمل' : 'غير مكتمل'}',
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: 3,
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  met ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 16,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: AppFontFamily.text,
                    fontSize: AppFontSizes.xxs,
                    fontWeight: AppFontWeights.regular,
                    color: color,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
