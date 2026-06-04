/// A single password requirement: an Arabic label plus the predicate that
/// decides whether the current password satisfies it.
class PasswordRule {
  const PasswordRule({required this.label, required this.test});

  final String label;
  final bool Function(String password) test;
}

/// Shared password rules for the signup flow. Pure logic (no UI) so the live
/// checklist widget and the submit guard read from one source instead of
/// duplicating the RegExps.
class PasswordValidator {
  PasswordValidator._();

  static final List<PasswordRule> rules = <PasswordRule>[
    PasswordRule(
      label: '8 أحرف على الأقل',
      test: (p) => p.length >= 8,
    ),
    PasswordRule(
      label: 'حرف كبير واحد على الأقل',
      test: (p) => RegExp(r'[A-Z]').hasMatch(p),
    ),
    PasswordRule(
      label: 'حرف صغير واحد على الأقل',
      test: (p) => RegExp(r'[a-z]').hasMatch(p),
    ),
    PasswordRule(
      label: 'رقم واحد على الأقل',
      test: (p) => RegExp(r'[0-9]').hasMatch(p),
    ),
    PasswordRule(
      label: 'رمز خاص واحد على الأقل',
      test: (p) => RegExp(r'''[!@#\$%^&*(),.?":{}|<>]''').hasMatch(p),
    ),
  ];

  /// True only when every rule passes.
  static bool isValid(String password) =>
      rules.every((rule) => rule.test(password));
}
