class NotificationPreferences {
  const NotificationPreferences({
    required this.categoriesEnabled,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.timezone,
    required this.inAppEnabled,
    required this.pushEnabled,
  });

  final List<String> categoriesEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final String? timezone;
  final bool inAppEnabled;
  final bool pushEnabled;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    final raw = (json['categories_enabled'] as List?) ?? const <dynamic>[];
    return NotificationPreferences(
      categoriesEnabled: raw.whereType<String>().toList(),
      quietHoursStart: json['quiet_hours_start'] as String?,
      quietHoursEnd: json['quiet_hours_end'] as String?,
      timezone: json['timezone'] as String?,
      inAppEnabled: json['in_app_enabled'] as bool? ?? true,
      pushEnabled: json['push_enabled'] as bool? ?? true,
    );
  }

  NotificationPreferences copyWith({bool? pushEnabled, bool? inAppEnabled}) =>
      NotificationPreferences(
        categoriesEnabled: categoriesEnabled,
        quietHoursStart: quietHoursStart,
        quietHoursEnd: quietHoursEnd,
        timezone: timezone,
        inAppEnabled: inAppEnabled ?? this.inAppEnabled,
        pushEnabled: pushEnabled ?? this.pushEnabled,
      );
}
