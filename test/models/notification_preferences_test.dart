import 'package:flutter_test/flutter_test.dart';
import 'package:mishkat/models/notification_preferences.dart';

void main() {
  test('NotificationPreferences.fromJson reads documented shape', () {
    final p = NotificationPreferences.fromJson({
      'categories_enabled': ['safety', 'system', 'reminder'],
      'quiet_hours_start': '22:00',
      'quiet_hours_end': '07:00',
      'timezone': 'Asia/Riyadh',
      'in_app_enabled': true,
      'push_enabled': false,
    });
    expect(p.categoriesEnabled, ['safety', 'system', 'reminder']);
    expect(p.quietHoursStart, '22:00');
    expect(p.quietHoursEnd, '07:00');
    expect(p.timezone, 'Asia/Riyadh');
    expect(p.inAppEnabled, true);
    expect(p.pushEnabled, false);
  });

  test('NotificationPreferences.fromJson has safe defaults', () {
    final p = NotificationPreferences.fromJson(const {});
    expect(p.categoriesEnabled, isEmpty);
    expect(p.inAppEnabled, true);
    expect(p.pushEnabled, true);
  });
}
